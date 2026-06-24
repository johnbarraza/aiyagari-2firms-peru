
%%
%% model_main.m — 2-FIRM HACT MODEL (FORMAL/INFORMAL) v10 ARz + Debt Premium
%  Original name: aiyagari_2firms_v10_R2_precio_endogeno_ARz_debtprem.m
%
% USAGE:
%   >> model_main                    % run with current defaults
%   >> run_replication               % run full replication pipeline
%   >> calibracion/setup_calibration % load documented setenv values
%   >> calibracion/escenarios        % choose scenario A/B/C
%
% MODES:
%   FAST_DEBUG_RUN = false  — full production run (~4 hours depedning guess value, I=500)
%   FAST_DEBUG_RUN = true   — quick numerical check (~7 min, I=200)
%   Override via env:  setenv('HA_IE_FAST_DEBUG','true')
%
% OUTPUT FILES:
%   results_<RUN_TAG>.mat  — full equilibrium results for plotting
%   calib_<RUN_TAG>.mat    — calibration parameter summary
%   Default RUN_TAG = 'v10_latest'. Override: setenv('HA_IE_RUN_TAG','myrun')
%
% CORE CONVENTIONS:
%   1. Formal good is numeraire: p_F = 1.
%   2. Informal good price p_I is endogenous and clears Y_I = C_I.
%   3. Informal household income (depends on Pi_I distribution rule):
%      lump:  w_I*theta*z^nu_I*ell_I + Pi_I          (Pi_I igual para todos)
%      hours: (w_I + Pi_I/L_I)*theta*z^nu_I*ell_I    (ingreso mixto: PMgL + renta/hora)
%      Set via HA_IE_INFORMAL_PROFIT_RULE. Default: hours.
%   4. Fiscal rebate: T = tau*w_F*L_F (separate from profit distribution).
%   5. Debt premium: spread_b(z)*max(-a,0), calibrated by HA_IE_DEBT_PREM_*.
%   6. Utility: CES over (c_F, c_I) with explicit corner checks.

% Parámetros via setenv() ANTES de correr. Defaults hardcodeados en Sección 1.
% Ningún archivo externo se carga — setenv() del usuario siempre tiene prioridad.

% Add package subdirs to path (ploteo/, calibracion/ aux functions)
script_dir_local = fileparts(mfilename('fullpath'));
if ~isempty(script_dir_local)
    addpath(script_dir_local);
    addpath(fullfile(script_dir_local, 'ploteo'));
    addpath(fullfile(script_dir_local, 'calibracion'));
end

clearvars; clc; close all;
tic;

global p_I omega_C eta_C sigma_C nu_I Frisch_F Frisch_I
global debt_spread_aa debt_spread_z debt_prem_chi debt_prem_eta debt_prem_rebate
global HA_IE_VERBOSE HA_IE_PROFILE HA_IE_TIMINGS

% =========================================================================
% 0. EQUILIBRIUM MODE SELECTOR
% =========================================================================

EQUILIBRIUM_MODE = 2;  % 1 = Partial (S(r) curve), 2 = General (find r*)

env_eq_mode = str2double(getenv('HA_IE_EQ_MODE')); % _Env
if isfinite(env_eq_mode) && any(env_eq_mode == [1, 2])
    EQUILIBRIUM_MODE = env_eq_mode;
elseif isfinite(env_eq_mode) && env_eq_mode == 3
    error('EQUILIBRIUM_MODE=3 was removed from v10. Use mode 2 with HA_IE_* environment overrides.');
end

% IGNORAR.RUN_TAG: tag appended to output filenames so runs don't overwrite each other.
%   Default: timestamp automatico 'v10_YYYYMMDD_HHMMSS'
%   Benchmark fijo: setenv('HA_IE_RUN_TAG','final')  -> results_final.mat
%   Siempre sobreescribir: setenv('HA_IE_RUN_TAG','latest') -> results_latest.mat
RUN_TAG = strtrim(getenv('HA_IE_RUN_TAG'));
if isempty(RUN_TAG)
    RUN_TAG = ['v10_' datestr(now, 'yyyymmdd_HHMMSS')];
end
script_file  = [mfilename('fullpath') '.m'];
script_dir   = fileparts(script_file);
if ~isempty(script_dir) && exist(script_dir, 'dir')
    addpath(script_dir);
    % Also add ploteo/ for auxiliary functions (zero_drift, ces_split)
    ploteo_dir = fullfile(script_dir, 'ploteo');
    if exist(ploteo_dir, 'dir'), addpath(ploteo_dir); end
    % And calibracion/ for setup scripts
    calib_dir = fullfile(script_dir, 'calibracion');
    if exist(calib_dir, 'dir'), addpath(calib_dir); end
end
safe_RUN_TAG = regexprep(RUN_TAG, '[^\w\-.]', '_');
mat_output_root = strtrim(getenv('HA_IE_OUTPUT_DIR'));
if isempty(mat_output_root)
    mat_output_root = fullfile(script_dir, 'outputs', 'stationary');
end
mat_output_dir = fullfile(mat_output_root, safe_RUN_TAG);
if ~exist(mat_output_dir, 'dir')
    mkdir(mat_output_dir);
end
results_file = fullfile(mat_output_dir, ['results_' safe_RUN_TAG '.mat']);
calib_file   = fullfile(mat_output_dir, ['calib_'   safe_RUN_TAG '.mat']);
metadata_file = fullfile(mat_output_dir, 'run_metadata.txt');
fprintf('RUN_TAG=%s\n', RUN_TAG);
fprintf('RUN output dir=%s\n', mat_output_dir);

% Runtime diagnostics for the ARz experimental copy.
HA_IE_VERBOSE = str2double(getenv('HA_IE_VERBOSE'));
if ~isfinite(HA_IE_VERBOSE), HA_IE_VERBOSE = 1; end
HA_IE_VERBOSE = max(0, min(2, round(HA_IE_VERBOSE)));

profile_env = lower(strtrim(getenv('HA_IE_PROFILE')));
if any(strcmp(profile_env, {'0','false','no','off'}))
    HA_IE_PROFILE = false;
else
    HA_IE_PROFILE = true;
end
HA_IE_TIMINGS = struct();

% =========================================================================
% 1. PARAMETERS
% =========================================================================

% Household
ga     = 2;       % CRRA risk aversion coefficient γ
rho    = 0.05;    % subjective discount rate ρ
Frisch = 0.38;     % Frisch elasticity of labor supply φ
Frisch_F = Frisch;
Frisch_I = Frisch;

% Quick mode: smaller grid + looser tolerances for numerical checks only.
FAST_DEBUG_RUN = true;  % true = quick check (~5 min), false = full run (~5 h)

env_fast_debug = lower(strtrim(getenv('HA_IE_FAST_DEBUG'))); % _Env
if any(strcmp(env_fast_debug, {'1','true','yes','on'}))
    FAST_DEBUG_RUN = true;
elseif any(strcmp(env_fast_debug, {'0','false','no','off'}))
    FAST_DEBUG_RUN = false;
end

% Formal/informal consumption CES block
%   sigma_C: elasticidad de sustitucion entre bienes formal/informal.
%   omega_C: peso CES del bien formal. Mueve demanda relativa, p_I y T5 nominal.
%   kappa(a) queda desactivado; kappa_z1 disciplina el gap formal por z.
%   omega_C se fija, se disciplina con un target de gasto/consumo, o se usa
%   como prior para no sobreidentificar los targets primarios.
p_I     = 1.0;             % initial guess only; equilibrium solves p_I endogenously
sigma_C = 5.0;             % substitution elasticity between c_F and c_I

env_sigma_C = str2double(getenv('HA_IE_SIGMA_C')); % _Env
if isfinite(env_sigma_C) && env_sigma_C > 0, sigma_C = env_sigma_C; end

eta_C   = 1 - 1/sigma_C;   % CES curvature
omega_C = 0.57;            % benchmark calib_nz20...om057 — bajar rompe p_I<1

env_omega_C = str2double(getenv('HA_IE_OMEGA_C')); % _Env
if isfinite(env_omega_C) && env_omega_C > 0 && env_omega_C < 1, omega_C = env_omega_C; end

% Two-Firm
% psi_F, psi_I: pesos de desutilidad del trabajo (parametros del hogar, NO de la firma)
%   Con H_bar=Inf:  nivel de psi determina horas totales; ratio determina split F/I
%   Con H_bar=1:    nivel de psi debe ser BAJO para que el tope binde (psi ~ 20-50)
%                   ratio psi_F/psi_I ≈ 1.57 para split T4=0.556 (FOC KKT con phi=0.5)
psi_F = 180.0;   % benchmark calib_nz20_AI099_b060_k110_psi180_om057 → T4≈0.562
psi_I = 50.0;     % benchmark calib_nz20_AI099_b060_k110_psi180_om057 → T4≈0.562
theta = 1.0;      % informal productivity attenuation factor θ ∈ (0,1]
nu_I  = 0.60;     % ventaja comparativa formal: benchmark usa 0.60

env_psi_F = str2double(getenv('HA_IE_PSI_F')); % _Env
env_psi_I = str2double(getenv('HA_IE_PSI_I')); % _Env
env_theta = str2double(getenv('HA_IE_THETA'));  % _Env
env_nu_I  = str2double(getenv('HA_IE_NU_I'));   % _Env
if isfinite(env_psi_F) && env_psi_F > 0, psi_F = env_psi_F; end
if isfinite(env_psi_I) && env_psi_I > 0, psi_I = env_psi_I; end
if isfinite(env_theta) && env_theta > 0, theta = env_theta; end
if isfinite(env_nu_I)  && env_nu_I  > 0, nu_I  = env_nu_I;  end

% Prima de deuda exogena por productividad (proxy financiero):
%   costo adicional = spread_b(z) * max(-a,0), solo cuando el hogar pide prestado.
%   spread_b(z) = chi_b * low_weight(z)^eta_b, mayor para z bajo.
%   Interpretacion: proxy reducido de menor inclusion financiera, menor colateral
%   y mayor riesgo crediticio de hogares de baja productividad. chi_b=0.02 se
%   inspira en la prima de 2 pp de Galindo et al. (2024); eta_b es curvatura
%   funcional y debe tratarse como supuesto/robustez, no como target T6.
%   No hay default endogeno ni probabilidad de impago; el spread introduce
%   esa friccion de forma reducida usando z como proxy observable. La forma
%   funcional es eleccion nuestra para imponer spread>=0, decreciente en z,
%   maximo chi_b en z_min y cero en z_max.
debt_prem_chi    = 0.02;
debt_prem_eta    = 1.0;     % curvatura spread(z): benchmark usa 1.0
debt_prem_rebate = false;

env_debt_chi = str2double(getenv('HA_IE_DEBT_PREM_CHI'));      % _Env
env_debt_eta = str2double(getenv('HA_IE_DEBT_PREM_ETA'));      % _Env
env_debt_rebate = lower(strtrim(getenv('HA_IE_DEBT_PREM_REBATE')));
if isfinite(env_debt_chi) && env_debt_chi >= 0, debt_prem_chi = env_debt_chi; end
if isfinite(env_debt_eta) && env_debt_eta >= 0, debt_prem_eta = env_debt_eta; end
if any(strcmp(env_debt_rebate, {'1','true','yes','on'}))
    debt_prem_rebate = true;
elseif any(strcmp(env_debt_rebate, {'0','false','no','off'}))
    debt_prem_rebate = false;
end

% Productivity states
% z_low, z_high: ENAHO Panel 2018-2022, Mincer en asalariados formales.
%   Corte en percentil 64 de residuos (pi_low=0.64 = sin secundaria completa).
%   Normalizacion E[z]=1. Script: enaho_z_lambda_productivity.do
%   Output: enaho_z_states_from_mincer_2018_2022.csv
% la2 (high->low): ENAHO Panel bienal 2018-19 vs 2021-22, solo formales.
%   Formula: lambda = -log(P_stay) / interval_years, intervalo=3 años.
%   Script: enaho_z_lambda_bienal.do → la2_bienal = 0.1645
%   pi_low implicito del panel = 0.678 (discrepa 3.8pp de target 0.64).
% la1 (low->high): condicion estacionaria forzada pi_low=0.64 (consistente con edu).
%   la1 = la2 * 0.36/0.64. Metodo de Galindo (2024): estima la2, deriva la1.
% Robustez: Floden-Linde (2001) la1+la2 ≈ 0.105 (cota inferior, EEUU/Suecia).
% ARz robustness variant:
% The z nodes are numerical discretization points of a latent AR(1), not
% additional economic groups. sd_logz_ar is the stationary standard deviation
% of log(z), not the innovation standard deviation.
%
% Default implementation follows the continuous-time HACT/OU idea:
%   x_t = log z_t follows an OU process with stationary sd sd_logz_ar.
%   eta_z_ar = -log(rho_z_ar)/dt maps annual AR(1) persistence to CT.
%   The finite-difference generator Qz_ar is tridiagonal sparse, so the
%   productivity transition block scales as O(Nz), not O(Nz^2).
%
% Baseline data calibration:
%   Hong (2022), Peru ENAHO 2004-2016. The reported persistent income
%   component has quarterly rho=0.963 and innovation sd=0.146. We map it
%   to the annual OU counterpart: rho_z_ar=0.963^4 and
%   sd_logz_ar=0.146/sqrt(1-0.963^2). The transitory shock sd=0.443 is
%   not part of the persistent productivity state.
%   rho_z_ar   = annual AR(1) persistence of residual log productivity.
%   sd_logz_ar = stationary standard deviation of residual log productivity.
%
% Set HA_IE_Z_PROCESS='rouwenhorst' to recover the dense discrete Markov
% approximation used in earlier ARz drafts.
Nz_ar      = 20;   % benchmark calib_nz20: Nz=7 NO converge (bracket r)
rho_z_ar   = 0.8600132622;
sd_logz_ar = 0.5417411732;
% Baseline thesis specification: keep Hong values above. Use HA_IE_Z_RHO
% and HA_IE_Z_SD only for explicit robustness runs.
width_z_ar = NaN;
mu_logz_ar = 0.0;
dt_z_ar    = 1.0;
z_process_ar = lower(strtrim(getenv('HA_IE_Z_PROCESS')));
if isempty(z_process_ar), z_process_ar = 'ou'; end

env_z_n     = str2double(getenv('HA_IE_Z_N'));      % _Env
env_z_rho   = str2double(getenv('HA_IE_Z_RHO'));    % _Env
env_z_sd    = str2double(getenv('HA_IE_Z_SD'));     % _Env
env_z_width = str2double(getenv('HA_IE_Z_WIDTH'));  % _Env
env_z_mu    = str2double(getenv('HA_IE_Z_MU'));     % _Env
env_z_dt    = str2double(getenv('HA_IE_Z_DT'));     % _Env
if isfinite(env_z_n) && env_z_n >= 2, Nz_ar = round(env_z_n); end
if isfinite(env_z_rho) && env_z_rho > 0 && env_z_rho < 0.9999, rho_z_ar = env_z_rho; end
if isfinite(env_z_sd) && env_z_sd > 0, sd_logz_ar = env_z_sd; end
if isfinite(env_z_width) && env_z_width > 0, width_z_ar = env_z_width; end
if isfinite(env_z_mu), mu_logz_ar = env_z_mu; end
if isfinite(env_z_dt) && env_z_dt > 0, dt_z_ar = env_z_dt; end
if ~isfinite(width_z_ar), width_z_ar = sqrt(Nz_ar - 1); end

eta_z_ar = -log(rho_z_ar) / dt_z_ar;
switch z_process_ar
    case {'ou','ct','continuous','continuous_time'}
        [logz_nodes, Qz_ar, pi_z_ar, z_ou_diag] = ou_ar1_generator_grid( ...
            Nz_ar, rho_z_ar, sd_logz_ar, width_z_ar, mu_logz_ar, dt_z_ar);
        Pz_annual = sparse([]);
        qz_scale_ar = eta_z_ar;
        z_process_ar = 'ou';
    case {'rouwenhorst','dt','discrete'}
        [logz_nodes, Pz_annual] = rouwenhorst_ar1_grid(Nz_ar, rho_z_ar, sd_logz_ar, width_z_ar, mu_logz_ar);
        pi_z_ar = stationary_dist_markov(Pz_annual);
        % Annual Rouwenhorst P has first-order persistence rho_z_ar. The HJB uses a
        % continuous-time generator, so scale (P-I) to match exp(Q)'s annual
        % first-order persistence: exp(scale*(rho-1)) = rho.
        qz_scale_ar = -log(rho_z_ar) / max(1 - rho_z_ar, 1e-12);
        Qz_ar = sparse(qz_scale_ar * (Pz_annual - eye(Nz_ar)));
        z_ou_diag = struct('eta', eta_z_ar, 'dx', NaN, 'diffusion_term', NaN, ...
            'max_abs_row_sum', max(abs(sum(Qz_ar, 2))), ...
            'nnz_Q', nnz(Qz_ar), 'density_Q', nnz(Qz_ar)/numel(Qz_ar));
        z_process_ar = 'rouwenhorst';
    otherwise
        error('HA_IE_Z_PROCESS debe ser ou o rouwenhorst.');
end

z_raw = exp(logz_nodes);
z = z_raw / max(sum(pi_z_ar .* z_raw), 1e-12);  % normalize E[z]=1
z_ave = sum(pi_z_ar .* z);
la = [];
la1 = NaN;
la2 = NaN;
z1 = z(1);
z2 = z(end);
% Pr(z_low)  = la2/(la1+la2) = 0.640   (sin secundaria completa, Peru)
%  Pr(z_high) = la1/(la1+la2) = 0.360   (secundaria completa+, Peru)
%  E[z] = 0.640*0.591 + 0.360*1.728 = 1.000  (normalizado)

% ---- Targets calibracion Peru ----
% INEI Cuenta Satelite 2024: el sector informal aporta 55.7% del empleo
% y 19.0% del PBI nominal. El modelo mapea ell_I al sector informal
% productivo, no a la informalidad laboral amplia dentro de firmas formales.
%
% Targets primarios actuales: T4, T5, Tkz y Tgasto_tipo. T6 queda como chequeo externo.
% Instrumentos/canales disponibles:
%   psi_F/psi_I  -> mueve principalmente T4 (asignacion horas F/I).
%   A_I          -> mueve productividad/output informal y T5.
%   kappa_z1     -> mueve gap formalidad z2-z1 (Tkz).
%   sorting z/a   -> mueve gasto total de hogares formal-dominantes vs informales.
%   omega_C      -> mueve composicion CES c_F/(p_I*c_I); no es target ENAHO directo.
% kappa(a) se desactiva para evitar endogeneidad de activos en la barrera.
T4_data    = 0.557;   % share de HORAS informales, INEI Cuenta Satelite 2024
                      % Mod.500, def. sector informal Cuenta Satelite (emplpsec==1), pond. fac500a,
                      % filtro ocu500==1, horas ocupacion principal i513t/p513t (100% pobladas).
                      % Pre-COVID = mismo regimen que gasto/z 2015-2019 y T6 2017 (T6 es T4 por quintil).
                      % Por anio intensivo: 2016=.498/2017=.506/2018=.516. Extensivo 2017=0.566 (=INEI CS publicado).
T5_data    = 0.190;   % PBI informal nominal / PBI total, INEI Cuenta Satelite 2024
Tgasto_tipo_data = 1.913; % ENAHO 2015-2019: E[gasto|ellF>ellI]/E[gasto|ellI>=ellF], dominant_hours
TgFI_data  = Tgasto_tipo_data; % alias legado para scripts antiguos; no usar como canasta CES
TgFI_canasta_data = NaN; % sin target ENAHO directo para c_F/(p_I*c_I)
env_T4_data = str2double(getenv('HA_IE_T4_DATA')); % _Env
env_T5_data = str2double(getenv('HA_IE_T5_DATA')); % _Env
env_Tgasto_tipo_data = str2double(getenv('HA_IE_TGASTO_TIPO_DATA')); % _Env
if isfinite(env_T4_data) && env_T4_data > 0 && env_T4_data < 1, T4_data = env_T4_data; end
if isfinite(env_T5_data) && env_T5_data > 0 && env_T5_data < 1, T5_data = env_T5_data; end
if isfinite(env_Tgasto_tipo_data) && env_Tgasto_tipo_data > 0
    Tgasto_tipo_data = env_Tgasto_tipo_data;
    TgFI_data = Tgasto_tipo_data;
end
T6_data    = 0.530;   % INEI-ENAHO 2017, gap Q1-Q5 informalidad
T6_Q1_data = 0.971;   % INEI-ENAHO 2017, share informal Q1 (pobres)
T6_Q5_data = 0.441;   % INEI-ENAHO 2017, share informal Q5 (ricos)
env_T6_data = str2double(getenv('HA_IE_T6_DATA')); % _Env
env_T6_Q1_data = str2double(getenv('HA_IE_T6_Q1_DATA')); % _Env
env_T6_Q5_data = str2double(getenv('HA_IE_T6_Q5_DATA')); % _Env
if isfinite(env_T6_data) && env_T6_data >= 0 && env_T6_data <= 1, T6_data = env_T6_data; end
if isfinite(env_T6_Q1_data) && env_T6_Q1_data >= 0 && env_T6_Q1_data <= 1, T6_Q1_data = env_T6_Q1_data; end
if isfinite(env_T6_Q5_data) && env_T6_Q5_data >= 0 && env_T6_Q5_data <= 1, T6_Q5_data = env_T6_Q5_data; end
T1_ref     = 2.30;    % BCR, ratio salarial bruto w_F/(w_I*theta) — solo referencia

% Formal Firm: Y_F = A_F * K^al * L_F^(1-al)
%   Cespedes, Aquije, Sanchez & Vera-Tudela (2014, BCRP REE-28):
%   alpha=0.636 (capital), 1-alpha=0.364 (labor), CRS, firm-level SUNAT 2002-2011.
A_F = 1;       % PTF formal (normalizacion)
al  = 0.636;   % capital share (Cespedes et al. 2014)
d   = 0.10;    % depreciation, Castillo & Rojas (BCRP REE-28)
env_A_F= str2double(getenv('HA_IE_A_F')); % _Env, MIT/common aggregate shocks
if isfinite(env_A_F) && env_A_F> 0
    A_F= env_A_F;
end

% Informal Firm: Y_I = A_I * K_I^alpha_I * L_I^beta_I
%   K_I rented at user cost r+d. alpha_I=0 recovers labor-only legacy.
%   w_I = beta_I * A_I * K_I^alpha_I * L_I^(beta_I - 1)  (endogenous PMgL)
%   Pi_I = (1 - alpha_I - beta_I)*p_I*Y_I when alpha_I+beta_I<1 (DRS profits).
%   When alpha_I+beta_I=1 (CRS), Pi_I=0 (Euler exhaustion, no profit to distribute).
%
%   PARAMETER SOURCES (Peru-validated):
%     Gobel, Grimm & Lay (2013, BCRP WP 2013-001): ENAHO 2002-2006 microempresas
%       Original DRS: alpha_I=0.118, beta_I=0.605 (sum=0.723)
%       Normalized CRS: alpha_I=0.163, beta_I=0.837 (sum=1)
%     Cespedes, Aquije, Sanchez & Vera-Tudela (2014, BCRP REE-28):
%       Formal: alpha=0.636, 1-alpha=0.364 (CRS, firm-level SUNAT)
%
%   SCENARIOS (set via HA_IE_ALPHA_I / HA_IE_BETA_I):
%     A) Sin capital informal: alpha_I=0, beta_I=0.696 (legacy DRS, calibrar A_I→T5)
%     B) CRS Gobel:          alpha_I=0.163, beta_I=0.837 (Pi_I=0, distribucion lump-sum)
%     C) DRS Gobel original: alpha_I=0.118, beta_I=0.605 (Pi_I>0, hours rule funciona)
A_I    = 0.99;   % benchmark calib_nz20_AI099: PTF informal (T5 tension → 0.13 vs 0.19)
alpha_I = 0.0;   % informal capital share (0 = legacy sin K informal)
beta_I = 0.696;  % informal labor share / DRS exponent

env_A_I = str2double(getenv('HA_IE_A_I'));       % _Env
env_alpha_I = str2double(getenv('HA_IE_ALPHA_I')); % _Env
env_beta_I = str2double(getenv('HA_IE_BETA_I')); % _Env
if isfinite(env_A_I) && env_A_I > 0
    A_I = env_A_I;
end
if isfinite(env_alpha_I) && env_alpha_I >= 0
    alpha_I = env_alpha_I;
end
if isfinite(env_beta_I) && env_beta_I > 0
    beta_I = env_beta_I;
end
if alpha_I < 0 || beta_I <= 0 || alpha_I + beta_I > 1
    error('Informal technology requires alpha_I >= 0, beta_I > 0, and alpha_I + beta_I <= 1.');
end

% q: oportunidad informal idiosincratica (estado Markoviano, independiente de z). FALTA DISCUTIR. ESTA DESACTIVADO
%   ingreso informal = w_I * theta * z^nu_I * q * ell_I
%   q in {q_low, q_high}, transiciones asimétricas lambda_q_up / lambda_q_down
%   masa(qH) = lambda_q_up / (lambda_q_up + lambda_q_down)
%   Tipos: (z1,qL), (z1,qH), (z2,qL), (z2,qH)   — neutralizable con q_low=q_high=1
USE_Q        = 0;     % 0 = 2 tipos z, 1 = 4 tipos (z x q)
q_low        = 0.5;   % oportunidad informal baja,
q_high       = 2.0;   % oportunidad informal alta, mayor red de contacto, etc
lambda_q_up  = 0.5;   % tasa transicion qL→qH (default simetrico)
lambda_q_down = 0.5;  % tasa transicion qH→qL

env_use_q     = str2double(getenv('HA_IE_USE_Q'));          % _Env
env_q_low     = str2double(getenv('HA_IE_Q_LOW'));          % _Env
env_q_high    = str2double(getenv('HA_IE_Q_HIGH'));         % _Env
env_lam_q     = str2double(getenv('HA_IE_LAMBDA_Q'));       % _Env — pone ambos igual
env_lam_q_up  = str2double(getenv('HA_IE_LAMBDA_Q_UP'));    % _Env — solo qL→qH
env_lam_q_down= str2double(getenv('HA_IE_LAMBDA_Q_DOWN'));  % _Env — solo qH→qL
if isfinite(env_use_q),                                     USE_Q        = round(env_use_q);   end
if isfinite(env_q_low)    && env_q_low    > 0,              q_low        = env_q_low;           end
if isfinite(env_q_high)   && env_q_high   > 0,              q_high       = env_q_high;          end
if isfinite(env_lam_q)    && env_lam_q    > 0
    lambda_q_up   = env_lam_q;   % HA_IE_LAMBDA_Q pone los dos iguales
    lambda_q_down = env_lam_q;
end
if isfinite(env_lam_q_up)   && env_lam_q_up   > 0, lambda_q_up   = env_lam_q_up;   end
if isfinite(env_lam_q_down) && env_lam_q_down > 0, lambda_q_down = env_lam_q_down; end
% masa(qH) en distribucion ergodica: pi_L*lambda_up = pi_H*lambda_down
mass_qH_ergodic = lambda_q_up / (lambda_q_up + lambda_q_down);
mean_q_ergodic = (1 - mass_qH_ergodic) * q_low + mass_qH_ergodic * q_high;

% ARz variant: keep the state space focused on productivity only.
% Combining AR(1) z with q should be a separate robustness exercise.
if USE_Q ~= 0
    warning('ARz variant forces USE_Q=0. Ignoring HA_IE_USE_Q for this file.');
end
USE_Q = 0;



% kappa_F(a): especificacion LEGACY desactivada en el modelo principal.
%   Motivo: a es endogeno; la barrera principal debe depender solo de z.
%   Se mantienen nombres legacy para compatibilidad con outputs antiguos.
kappa_min   = 0.0;   % costo minimo universal
kappa_extra = 0.0;   % costo adicional por ser pobre
gamma_k     = 5.0;   % pendiente de transicion en riqueza
a_bar_k     = 0.0;   % umbral de riqueza

env_kappa_min   = str2double(getenv('HA_IE_KAPPA_MIN'));   % _Env
env_kappa_extra = str2double(getenv('HA_IE_KAPPA_EXTRA')); % _Env
env_gamma_k     = str2double(getenv('HA_IE_KAPPA_GAMMA')); % _Env
env_a_bar_k     = str2double(getenv('HA_IE_KAPPA_ABAR'));  % _Env
if isfinite(env_kappa_min)   && env_kappa_min   >= 0, kappa_min   = env_kappa_min;   end
if isfinite(env_kappa_extra) && env_kappa_extra >= 0, kappa_extra = env_kappa_extra; end
if isfinite(env_gamma_k)     && env_gamma_k     >  0, gamma_k     = env_gamma_k;     end
if isfinite(env_a_bar_k),                              a_bar_k     = env_a_bar_k;     end
% Auditoria kappa(z): impedir que overrides legacy reactiven kappa(a).
kappa_min   = 0.0;
kappa_extra = 0.0;

% kappa_F(z): costo adicional por baja productividad (barrera de acceso formal por tipo z)
%   kappa_z1 > 0: barrera para z_bajo (proxy: sin nivel/primaria, EPEN 2023)
%   kappa_z2 = 0: normalizado — z_alto sin barrera adicional
%   Target: T_kappa_z = E[lF/(lF+lI)|z2] - E[lF/(lF+lI)|z1] = 0.386
%   (EPEN 2025, grupos amplios: sin secundaria vs secundaria+).
%   Fuente: Meghir, Narita & Robin (2015, AER) — tasa llegada ofertas formales cae con z
%   La forma funcional es eleccion nuestra: no negativa, decreciente en z,
%   maximo kappa_z1 en z_min, cero/normalizada en z_max y suavizada por
%   kappa_z_shape. kappa_z1 se calibra a Tkz; la forma no es un costo
%   observado directamente sino una barrera reducida de acceso formal.
kappa_z1 = 0.110; % benchmark calib_nz20...k110 → Tkz≈0.373
kappa_z2 = 0.0;   % normalizado a 0
kappa_z_shape = 1.0; % benchmark: lineal

env_kappa_z1 = str2double(getenv('HA_IE_KAPPA_Z1'));  % _Env
env_kappa_z_shape = str2double(getenv('HA_IE_KAPPA_Z_SHAPE')); % _Env
if isfinite(env_kappa_z1) && env_kappa_z1 >= 0, kappa_z1 = env_kappa_z1; end
if isfinite(env_kappa_z_shape) && env_kappa_z_shape > 0, kappa_z_shape = env_kappa_z_shape; end

% --- Structural solver parameters ---
tau        = 0.18;   % Tax rate on formal labor income
H_bar      = 1.0;    % Time endowment: ell_F + ell_I <= H_bar (dotacion normalizada)
                     % KKT: constraint may or may not bind per agent.
                     % H_bar=1 estandar (Galindo 2024 BCRP, Restrepo-Echavarria).
tol_T      = 1e-5;   % Convergence tolerance for T inner loop
max_iter_T = 30;     % Max iterations for T convergence loop
tol_wI      = 1e-5;   % convergence tolerance for informal wage fixed point
max_iter_wI = 40;     % max iterations for informal wage/profit loop
tol_pI      = 1e-5;   % informal-good market clearing tolerance
max_iter_pI = 50;     % max iterations for p_I bisection
pI_grid_init    = [0.25, 0.75, 1.0, 1.5, 3.0];
pI_expand_factor = 2.0;
max_pI_expand    = 4;

env_pI_grid = strtrim(getenv('HA_IE_PI_GRID')); % _Env
if ~isempty(env_pI_grid)
    parsed_pI_grid = sscanf(strrep(env_pI_grid, ',', ' '), '%f')';
    if ~isempty(parsed_pI_grid) && all(isfinite(parsed_pI_grid)) && all(parsed_pI_grid > 0)
        pI_grid_init = sort(unique(parsed_pI_grid));
    end
end
env_max_iter_T  = str2double(getenv('HA_IE_MAX_ITER_T'));  % _Env
env_max_iter_wI = str2double(getenv('HA_IE_MAX_ITER_WI')); % _Env
env_max_iter_pI = str2double(getenv('HA_IE_MAX_ITER_PI')); % _Env
env_tol_T  = str2double(getenv('HA_IE_TOL_T'));            % _Env
env_tol_wI = str2double(getenv('HA_IE_TOL_WI'));           % _Env
env_tol_pI = str2double(getenv('HA_IE_TOL_PI'));           % _Env
if isfinite(env_max_iter_T) && env_max_iter_T >= 1, max_iter_T = round(env_max_iter_T); end
if isfinite(env_max_iter_wI) && env_max_iter_wI >= 1, max_iter_wI = round(env_max_iter_wI); end
if isfinite(env_max_iter_pI) && env_max_iter_pI >= 1, max_iter_pI = round(env_max_iter_pI); end
if isfinite(env_tol_T) && env_tol_T > 0, tol_T = env_tol_T; end
if isfinite(env_tol_wI) && env_tol_wI > 0, tol_wI = env_tol_wI; end
if isfinite(env_tol_pI) && env_tol_pI > 0, tol_pI = env_tol_pI; end

% Regla de reparto de beneficios informales
% lump: Pi_I va a todos como transferencia separada
% hours: Pi_I se incorpora al salario informal por hora eficiente trabajada (default)
informal_profit_rule = lower(strtrim(getenv('HA_IE_INFORMAL_PROFIT_RULE'))); % _Env
if isempty(informal_profit_rule), informal_profit_rule = 'hours'; end
if ~ismember(informal_profit_rule, {'lump','hours'})
    error('HA_IE_INFORMAL_PROFIT_RULE debe ser lump u hours');
end

% Numerical safeguards for structural R2 loop.
L_I_floor_wI = 1e-4;      % floor only for wage/profit updates when L_I is tiny
damp_wI_log  = 0.10;      % log damping on w_I updates
damp_piI     = 0.10;      % level damping on Pi_I_share updates
damp_T       = 0.15;      % level damping on T updates


% Initial guess for omega_I (producto medio informal) warm start
% omega_I = A_I * K_I^alpha_I * L_I^(beta_I-1); guess L_I_guess ≈ 0.5
% Note: omega_I > w_I always (avg product > marginal product with DRS)
L_I_guess       = 0.5;
[~, ~, w_I_init, Pi_I_share_init] = informal_firm_outcomes_v10( ...
    L_I_guess, 0.02, p_I, A_I, alpha_I, beta_I, d, L_I_floor_wI);

% =========================================================================
% 2. GRIDS
% =========================================================================

I    = 500;
amin = -1.0;    % benchmark usa -1 (mas negativo para que spread deuda muerda)
amax = 20;

env_I    = str2double(getenv('HA_IE_I'));    % _Env
env_amin = str2double(getenv('HA_IE_AMIN')); % _Env
env_amax = str2double(getenv('HA_IE_AMAX')); % _Env
if isfinite(env_I) && env_I >= 50, I = round(env_I); end
if isfinite(env_amin), amin = env_amin; end
if isfinite(env_amax) && env_amax > amin, amax = env_amax; end

a    = linspace(amin, amax, I)';
da   = (amax - amin)/(I - 1);

aa = [a, a];
zz = ones(I,1)*z;

maxit = 100;
crit  = 10^(-6);
Delta = 1000;

if FAST_DEBUG_RUN
    I = 200;
    env_debug_I = str2double(getenv('HA_IE_DEBUG_I')); % _Env
    if isfinite(env_debug_I) && env_debug_I >= 50, I = round(env_debug_I); end
    a = linspace(amin, amax, I)';
    da = (amax - amin)/(I - 1);
    aa = [a, a];
    zz = ones(I,1)*z;
    maxit = 40;
    crit = 1e-5;
    tol_T = 1e-4;
    max_iter_T = 8;
    tol_wI = 1e-4;
    max_iter_wI = 5;
    tol_pI = 1e-4;
    max_iter_pI = 20;
    if isfinite(env_max_iter_T) && env_max_iter_T >= 1, max_iter_T = round(env_max_iter_T); end
    if isfinite(env_max_iter_wI) && env_max_iter_wI >= 1, max_iter_wI = round(env_max_iter_wI); end
    if isfinite(env_max_iter_pI) && env_max_iter_pI >= 1, max_iter_pI = round(env_max_iter_pI); end
    % Zero-drift grid pequeno en debug: 25 pts vs 80 en produccion (~3x mas rapido)
    if isempty(getenv('HA_IE_ZDRIFT_NPTS'))
        setenv('HA_IE_ZDRIFT_NPTS', '25');
    end
    if isfinite(env_tol_T) && env_tol_T > 0, tol_T = env_tol_T; end
    if isfinite(env_tol_wI) && env_tol_wI > 0, tol_wI = env_tol_wI; end
    if isfinite(env_tol_pI) && env_tol_pI > 0, tol_pI = env_tol_pI; end
    fprintf('=== FAST DEBUG RUN ACTIVE ===\n');
    fprintf('I=%d, maxit=%d, max_iter_T=%d, max_iter_wI=%d, max_iter_pI=%d\n\n', ...
        I, maxit, max_iter_T, max_iter_wI, max_iter_pI);
end

% Ns preliminar para el print (se redefine en el bloque de estados)
Ns = length(z);

% kappa_F vector on asset grid (legacy, disabled in main specification)
% Globals so inner solver functions can access without signature changes.
global kappa_F_vec kappa_F_aa
kappa_F_vec = zeros(I,1);
kappa_F_aa  = zeros(I, Ns);
% kappa(z) component: z-dependent barrier (kappa_z1 for z_min, 0 for z_max)
kappa_z_vec = zeros(1, Ns);  % 1 x Ns, actualizado despues de z/Ns final

fprintf('=== PARAMETER OVERRIDES / RUN CONFIG ===\n');
if EQUILIBRIUM_MODE == 1
    mode_label = 'Modo 1: equilibrio parcial (S(r), p_I endogeno)';
elseif EQUILIBRIUM_MODE == 2
    mode_label = 'Modo 2: equilibrio general (r*, p_I endogeno)';
else
    mode_label = sprintf('Modo desconocido: %d', EQUILIBRIUM_MODE);
end
if FAST_DEBUG_RUN
    run_label = 'FAST DEBUG: SI (grilla/iteraciones reducidas)';
else
    run_label = 'FAST DEBUG: NO (corrida completa)';
end
fprintf('Run mode: %s\n', mode_label);
fprintf('Run speed: %s\n', run_label);
fprintf('MODE=%d, FAST_DEBUG_RUN=%d, I=%d, amin=%.4f, amax=%.4f\n', ...
    EQUILIBRIUM_MODE, FAST_DEBUG_RUN, I, amin, amax);
fprintf('theta=%.4f, A_I=%.5f, alpha_I=%.4f, beta_I=%.4f, alpha+beta=%.4f, psi_F=%.4f, psi_I=%.4f\n', ...
    theta, A_I, alpha_I, beta_I, alpha_I + beta_I, psi_F, psi_I);
fprintf('nu_I=%.4f  (informal usa z^nu_I; nu_I<1 atenúa productividad alta en informal)\n', nu_I);
fprintf('Z_PROCESS=%s: Nz=%d, rho_z=%.3f, eta_z=%.4f, sd_logz=%.3f, E[z]=%.4f, z_range=[%.3f, %.3f], nnz(Qz)=%d\n', ...
    z_process_ar, Nz_ar, rho_z_ar, eta_z_ar, sd_logz_ar, z_ave, min(z), max(z), nnz(Qz_ar));
fprintf('kappa_z1=%.4f, kappa_z2=%.4f, shape=%.2f; kappa(a) legacy desactivado (min=%.4f, extra=%.4f)\n', ...
    kappa_z1, kappa_z2, kappa_z_shape, kappa_min, kappa_extra);
fprintf('debt_prem: chi=%.5f, eta=%.3f, rebate=%d; costo=spread_b(z)*max(-a,0) solo si a<0\n', ...
    debt_prem_chi, debt_prem_eta, debt_prem_rebate);
fprintf('USE_Q=%d, q=[%.2f, %.2f], lq_up=%.3f, lq_down=%.3f, masa(qH)=%.3f, E[q]=%.3f, Ns=%d tipos\n', ...
    USE_Q, q_low, q_high, lambda_q_up, lambda_q_down, mass_qH_ergodic, mean_q_ergodic, Ns);
fprintf('pI_grid_init=[%s], tol_T=%.1e, tol_wI=%.1e, tol_pI=%.1e\n', ...
    num2str(pI_grid_init), tol_T, tol_wI, tol_pI);
fprintf('max_iter_T=%d, max_iter_wI=%d, max_iter_pI=%d\n', ...
    max_iter_T, max_iter_wI, max_iter_pI);
fprintf('informal_profit_rule=%s  (lump=Pi_I como transferencia; hours=Pi_I proporcional a horas)\n\n', ...
    informal_profit_rule);

% Expansion espacio de estados: si USE_Q=1 → 4 tipos (z x q), USE_Q=0 → 2 tipos z
global qq_informal
if USE_Q
    % Tipos: 1=(z1,qL), 2=(z1,qH), 3=(z2,qL), 4=(z2,qH)
    z     = [z(1), z(1), z(2), z(2)];         % productividad formal por tipo
    q_inf = [q_low, q_high, q_low, q_high];   % multiplicador informal por tipo
    Ns    = 4;
    lz  = la(1);           % tasa transicion z (simetrica)
    lqu = lambda_q_up;     % qL → qH
    lqd = lambda_q_down;   % qH → qL
    % Q4: transiciones independientes de z y q
    %     filas: tipo origen, columnas: tipo destino
    %     (z1,qL) (z1,qH) (z2,qL) (z2,qH)
    Q4 = [-lz-lqu,  lqu,    lz,     0;
            lqd,  -lz-lqd,   0,    lz;
            lz,     0,   -lz-lqu,  lqu;
             0,    lz,     lqd,  -lz-lqd];
    Aswitch = kron(Q4, speye(I));
    fprintf('USE_Q=1: 4 tipos (z x q), q=[%.2f, %.2f], lq_up=%.3f, lq_down=%.3f, masa(qH)=%.3f, E[q]=%.3f\n', ...
        q_low, q_high, lambda_q_up, lambda_q_down, mass_qH_ergodic, mean_q_ergodic);
else
    q_inf = ones(1, length(z));
    Ns    = length(z);
    Aswitch = kron(Qz_ar, speye(I));
end
zz           = ones(I,1) * z;                 % I x Ns
aa           = repmat(a, 1, Ns);              % I x Ns
qq_informal  = ones(I,1) * q_inf;             % I x Ns (q=1 si USE_Q=0)
kappa_F_aa   = zeros(I, Ns);                  % I x Ns - especificacion principal solo kappa(z)
% kappa(z): barrera suavemente decreciente en productividad.
% kappa_z1 applies at z_min and kappa_z2 at z_max; intermediate AR nodes use
% a curved interpolation. shape=1 is linear; shape>1 concentrates the barrier
% closer to the lowest-z nodes.
kappa_z_vec  = zeros(1, Ns);
for jz = 1:Ns
    if max(z) > min(z)
        low_weight = (max(z) - z(jz)) / (max(z) - min(z));
        low_weight = max(0, min(1, low_weight))^kappa_z_shape;
        kappa_z_vec(jz) = kappa_z2 + (kappa_z1 - kappa_z2) * low_weight;
    else
        kappa_z_vec(jz) = kappa_z1;
    end
end
kappa_F_aa   = ones(I,1)*kappa_z_vec;         % solo kappa(z); no suma kappa(a)
if max(z) > min(z)
    debt_low_weight = (max(z) - z(:)') ./ max(max(z) - min(z), 1e-12);
    debt_low_weight = max(0, min(1, debt_low_weight));
else
    debt_low_weight = zeros(1, Ns);
end
debt_spread_z  = debt_prem_chi * debt_low_weight.^debt_prem_eta;
debt_spread_aa = ones(I,1) * debt_spread_z;
idx_zmin_debt = find(z == min(z), 1, 'first');
idx_zmax_debt = find(z == max(z), 1, 'last');
fprintf('kappa_z: z_min=%.2f -> kappa_z=%.4f, z_max=%.2f -> kappa_z=%.4f, shape=%.2f\n', ...
    min(z), kappa_z1, max(z), kappa_z2, kappa_z_shape);
fprintf('debt_spread_z: z_min=%.2f -> %.5f, z_max=%.2f -> %.5f, max=%.5f\n', ...
    min(z), debt_spread_z(idx_zmin_debt), max(z), debt_spread_z(idx_zmax_debt), max(debt_spread_z));

% =========================================================================
% 3. EQUILIBRIUM SOLVER
% =========================================================================

if EQUILIBRIUM_MODE == 1
    % =====================================================================
    % PARTIAL EQUILIBRIUM: Compute S(r) with endogenous p_I clearing
    % =====================================================================

    Ir   = 60;
    rmin = -0.0499;
    rmax = 0.049;
    r_grid = linspace(rmin, rmax, Ir);

    fprintf('=== PARTIAL EQUILIBRIUM MODE (v10 R2) ===\n');
    fprintf('tau=%.2f, alpha_I=%.2f, beta_I=%.2f\n', tau, alpha_I, beta_I);
    fprintf('Computing S(r) with endogenous p_I...\n\n');

    r        = r_grid(1);
    KD_init  = (al*A_F/(r + d))^(1/(1 - al))*z_ave;
    w_F_init = (1 - al)*A_F*(KD_init/z_ave)^al;
    v0 = zeros(I, Ns);
    for s = 1:Ns
        inc_s = (1-tau)*w_F_init*z(s) + w_I_init*theta*(z(s)^nu_I)*q_inf(s) + max(r,0.01)*a + Pi_I_share_init;
        v0(:,s) = max(inc_s, 1e-6).^(1-ga)/(1-ga)/rho;
    end

    T_current   = 0;
    wI_current  = w_I_init;
    PiI_current = Pi_I_share_init;
    pI_current  = p_I;

    for ir = 1:Ir
        r = r_grid(ir);
        [S(ir), KD(ir), w_F_r(ir), L_F(ir), L_I(ir), V, g, c, ell_F, ell_I, ...
            T_eq_r(ir), w_I_eq_r(ir), Pi_I_eq_r(ir), p_I_eq_r(ir), Y_I_eq_r(ir), ...
            C_I_eq_r(ir), C_F_eq_r(ir), v0] = ...
            solve_price_clearing_v10(r, pI_current, v0, T_current, wI_current, PiI_current, ...
            a, z, la, ga, rho, Frisch, psi_F, psi_I, theta, A_F, al, d, A_I, alpha_I, beta_I, ...
            z_ave, I, da, aa, zz, maxit, crit, Delta, Aswitch, tau, H_bar, tol_T, ...
            max_iter_T, tol_wI, max_iter_wI, tol_pI, max_iter_pI, pI_grid_init, ...
            pI_expand_factor, max_pI_expand, L_I_floor_wI, damp_wI_log, damp_piI, damp_T);

        T_current   = T_eq_r(ir);
        wI_current  = w_I_eq_r(ir);
        PiI_current = Pi_I_eq_r(ir);
        pI_current  = p_I_eq_r(ir);

        V_r(:,:,ir)     = V;
        g_r(:,:,ir)     = g;
        c_r(:,:,ir)     = c;
        ell_F_r(:,:,ir) = ell_F;
        ell_I_r(:,:,ir) = ell_I;

        if mod(ir, 10) == 0
            fprintf('ir=%d/%d, r=%.4f, p_I=%.4f, S=%.4f, KD=%.4f, Y_I=%.4f, C_I=%.4f\n', ...
                ir, Ir, r, p_I_eq_r(ir), S(ir), KD(ir), Y_I_eq_r(ir), C_I_eq_r(ir));
        end
    end

elseif EQUILIBRIUM_MODE == 2
    % =====================================================================
    % GENERAL EQUILIBRIUM: Find r* with endogenous p_I clearing
    % =====================================================================

    fprintf('=== GENERAL EQUILIBRIUM MODE (v10 R2 estructural) ===\n');
    fprintf('tau=%.2f, alpha_I=%.2f, beta_I=%.2f\n\n', tau, alpha_I, beta_I);

    r_guess     = 0.02;
    KD_init     = (al*A_F/(r_guess + d))^(1/(1 - al))*z_ave;
    w_F_init    = (1 - al)*A_F*(KD_init/z_ave)^al;
    v0 = zeros(I, Ns);
    for s = 1:Ns
        inc_s = (1-tau)*w_F_init*z(s) + w_I_init*theta*(z(s)^nu_I)*q_inf(s) ...
            + max(r_guess,0.01)*a - debt_spread_aa(:,s).*max(-a,0) + Pi_I_share_init;
        v0(:,s) = max(inc_s, 1e-6).^(1-ga)/(1-ga)/rho;
    end

    [r_star, K_star, S_star, w_F_star, L_F_star, L_I_star, V, g, c, ell_F, ell_I, ...
        T_star, w_I_star, Pi_I_share_star, p_I_star, Y_I, C_I_agg, C_F_agg, v0, ge_history] = ...
        run_ge_v10(v0, p_I, w_I_init, Pi_I_share_init, a, z, la, ga, rho, Frisch, ...
        psi_F, psi_I, theta, A_F, al, d, A_I, alpha_I, beta_I, z_ave, I, da, aa, zz, ...
        maxit, crit, Delta, Aswitch, tau, H_bar, tol_T, max_iter_T, tol_wI, ...
        max_iter_wI, tol_pI, max_iter_pI, pI_grid_init, pI_expand_factor, ...
        max_pI_expand, L_I_floor_wI, damp_wI_log, damp_piI, damp_T);

    p_I = p_I_star;
    r_grid = ge_history.r_grid;
    S = ge_history.S;
    KD = ge_history.KD;
    w_F_r = ge_history.w_F_r;
    L_F = ge_history.L_F;
    L_I = ge_history.L_I;
    T_eq_r = ge_history.T_eq_r;
    w_I_eq_r = ge_history.w_I_eq_r;
    Pi_I_eq_r = ge_history.Pi_I_eq_r;
    p_I_eq_r = ge_history.p_I_eq_r;
    Y_I_eq_r = ge_history.Y_I_eq_r;
    C_I_eq_r = ge_history.C_I_eq_r;
    C_F_eq_r = ge_history.C_F_eq_r;
    omega_I_eq_r = ge_history.omega_I_eq_r;
    excess_K_r = ge_history.excess_K_r;
    goods_I_err_r = ge_history.goods_I_err_r;
    profit_I_star = Pi_I_share_star;
    K_F_star = (al*A_F/(r_star + d))^(1/(1 - al)) * L_F_star;
    [K_I_star, ~, w_I_marg_check, ~, omega_I_star] = informal_firm_outcomes_v10( ...
        L_I_star, r_star, p_I_star, A_I, alpha_I, beta_I, d, L_I_floor_wI);
    Y_F = A_F* K_F_star^al * L_F_star^(1-al);
    C_agg = C_F_agg + p_I_star * C_I_agg;
    tax_rev = tau * w_F_star * L_F_star;
    KappaCost   = da * sum(sum(kappa_F_aa .* ell_F .* g));
    debt_balance_aa = max(-aa, 0);
    debt_indicator_aa = double(aa < 0);
    mass_z = da * sum(g, 1);
    mass_debt = da * sum(sum(g .* debt_indicator_aa));
    mass_amin = da * sum(g(1,:));
    DebtPremPayments = da * sum(sum(g .* debt_spread_aa .* debt_balance_aa));
    avg_debt_spread_paid = DebtPremPayments / max(da * sum(sum(g .* debt_balance_aa)), 1e-12);
    mass_debt_by_z = da * sum(g .* debt_indicator_aa, 1) ./ max(mass_z, 1e-12);
    mass_amin_by_z = da * g(1,:) ./ max(mass_z, 1e-12);
    mean_assets_by_z = da * sum(g .* aa, 1) ./ max(mass_z, 1e-12);
    mean_cons_by_z = da * sum(g .* c, 1) ./ max(mass_z, 1e-12);
    walras_err  = abs(Y_F - C_F_agg - d*K_star - KappaCost);
    goods_I_err = C_I_agg - Y_I;
    labor_clear = da * sum(sum(g .* (ell_F + ell_I)));
    pmgl_check = abs(w_I_star - w_I_marg_check);

    T_eq       = T_star;

    % GDP nominal shares (para display y calibracion)
    T5_nom = p_I_star * Y_I / (Y_F + p_I_star * Y_I);

end

total_elapsed = toc;
ha_profile_print(total_elapsed);

% =========================================================================
% 4. DISPLAY RESULTS
% =========================================================================

fprintf('\n========================================\n');
if EQUILIBRIUM_MODE == 1
    fprintf('PARTIAL EQUILIBRIUM RESULTS (v10 R2)\n');
    fprintf('tau=%.2f, alpha_I=%.2f, beta_I=%.2f\n', tau, alpha_I, beta_I);
    fprintf('S(r) computed for %d values of r\n', Ir);
    fprintf('r range: [%.4f, %.4f]\n', rmin, rmax);
else
    fprintf('GENERAL EQUILIBRIUM RESULTS (v10 R2 estructural)\n');
    fprintf('tau=%.2f, alpha_I=%.2f, beta_I=%.2f, alpha+beta=%.2f\n', tau, alpha_I, beta_I, alpha_I + beta_I);
    fprintf('--- Precios ---\n');
    fprintf('Tasa de interes:           r*        = %.6f\n', r_star);
    fprintf('Precio bien informal:      p_I*      = %.6f\n', p_I_star);
    fprintf('Capital total:             K*        = %.4f\n', K_star);
    fprintf('Capital formal:            K_F*      = %.4f\n', K_F_star);
    fprintf('Capital informal:          K_I*      = %.4f\n', K_I_star);
    fprintf('Salario formal bruto:      w_F*      = %.4f\n', w_F_star);
    fprintf('Salario formal neto:       (1-t)w_F* = %.4f\n', (1-tau)*w_F_star);
    fprintf('Salario marginal inform.:  w_I*      = %.4f\n', w_I_star);
    fprintf('Prod. media informal:      p_I*Y_I/L_I = %.4f  [diag]\n', omega_I_star);
    fprintf('--- Labor ---\n');
    E_ellF = da * sum(sum(g .* ell_F));
    E_ellI = da * sum(sum(g .* ell_I));
    [c_F_disp, c_I_disp, exp_disp] = ces_split_from_Ceff_v10(c);
    E_cF_disp        = da * sum(sum(g .* c_F_disp));
    E_cI_disp        = da * sum(sum(g .* c_I_disp));
    E_exp_disp       = da * sum(sum(g .* exp_disp));
    share_exp_I_disp = da * sum(sum(g .* (p_I*c_I_disp))) / max(E_exp_disp, 1e-12);
    fprintf('Trabajo formal eficiente:  L_F*      = %.4f\n', L_F_star);
    fprintf('Trabajo informal eficiente:L_I*      = %.4f\n', L_I_star);
    fprintf('Horas formales E[ell_F]:   %.4f\n', E_ellF);
    fprintf('Horas informales E[ell_I]: %.4f  (referencia en nivel; target T4 usa ratio)\n', E_ellI);
    fprintf('Horas totales E[ell_F+lI]: %.6f\n', E_ellF+E_ellI);
    % --- Gini riqueza y gasto/consumo ---
    g_marg_a   = sum(g, 2) * da;                      % densidad marginal en a (I x 1)
    mean_a_mod = sum(a .* g_marg_a);                  % riqueza media
    cum_pop_a  = cumsum(g_marg_a);                     % CDF poblacion
    lorenz_a   = cumsum(a .* g_marg_a) / max(mean_a_mod, 1e-12);  % curva Lorenz
    Gini_a     = 1 - 2 * trapz([0; cum_pop_a], [0; lorenz_a]);  % area bajo Lorenz

    % Concentracion de gasto si se ordena por riqueza (no es Gini estandar ENAHO).
    exp_flat   = sum(g .* exp_disp, 2) ./ max(g_marg_a, 1e-12);   % consumo medio en a
    mean_c_mod = sum(exp_flat .* g_marg_a);
    lorenz_c_by_a = cumsum(exp_flat .* g_marg_a) / max(mean_c_mod, 1e-12);
    Gini_c_by_a = 1 - 2 * trapz([0; cum_pop_a], [0; lorenz_c_by_a]);

    % Lorenz/Gini estandar de gasto: ordena hogares por gasto total.
    exp_vec = exp_disp(:);
    w_vec = g(:) * da;
    ok_exp = isfinite(exp_vec) & isfinite(w_vec) & w_vec > 0;
    [exp_sorted, idx_exp] = sort(exp_vec(ok_exp), 'ascend');
    w_sorted = w_vec(ok_exp);
    w_sorted = w_sorted(idx_exp);
    cum_pop_c = cumsum(w_sorted) / max(sum(w_sorted), 1e-12);
    mean_exp_mod = sum(exp_sorted .* w_sorted) / max(sum(w_sorted), 1e-12);
    lorenz_c = cumsum(exp_sorted .* w_sorted) / max(sum(exp_sorted .* w_sorted), 1e-12);
    Gini_c = 1 - 2 * trapz([0; cum_pop_c], [0; lorenz_c]);

    fprintf('--- Desigualdad (validacion, no targets) ---\n');
    fprintf('Gini riqueza modelo:       %.4f  (activos netos del modelo; ref externa por definir)\n', Gini_a);
    fprintf('Gini gasto    modelo:      %.4f  (Lorenz ordenada por gasto; ref ENAHO gasto/ingreso)\n', Gini_c);
    fprintf('Conc. gasto por riqueza:   %.4f  (ordenado por a; NO Gini estandar)\n', Gini_c_by_a);
    fprintf('Riqueza media E[a]:        %.4f\n', mean_a_mod);

    fprintf('--- Consumo ---\n');
    fprintf('Consumo formal E[c_F]:     %.4f\n', E_cF_disp);
    fprintf('Consumo informal E[c_I]:   %.4f\n', E_cI_disp);
    fprintf('Gasto total E[c_F+p_Ic_I]: %.4f\n', E_exp_disp);
    fprintf('Share gasto informal:      %.4f\n', share_exp_I_disp);
    fprintf('--- Produccion ---\n');
    fprintf('Output formal (real):      Y_F         = %.4f\n', Y_F);
    fprintf('Output informal (real):    Y_I         = %.4f\n', Y_I);
    fprintf('GDP nominal formal:        p_F*Y_F     = %.4f  (p_F=1 numerario)\n', Y_F);
    fprintf('GDP nominal informal:      p_I*Y_I     = %.4f\n', p_I_star * Y_I);
    fprintf('GDP nominal total:         Y_F+p_I*Y_I = %.4f\n', Y_F + p_I_star * Y_I);
    fprintf('Share informal (real):     Y_I/(Y_F+Y_I)         = %.4f\n', Y_I/(Y_F+Y_I));
    fprintf('Share informal (nominal):  p_I*Y_I/(Y_F+p_I*Y_I) = %.4f  [T5 target]\n', T5_nom);
    fprintf('--- Gobierno ---\n');
    fprintf('Impuesto recaudado:        tau*wF*LF = %.4f\n', tax_rev);
    fprintf('Transferencia fiscal:      T         = %.4f  (incluye prima si rebate=1)\n', T_star);
    fprintf('Beneficios informales:     Pi_I      = %.4f  (= Pi_I_share)\n', profit_I_star);
    fprintf('--- Prima deuda z ---\n');
    fprintf('chi=%.5f, eta=%.3f, rebate=%d, max spread=%.5f\n', ...
        debt_prem_chi, debt_prem_eta, debt_prem_rebate, max(debt_spread_z));
    fprintf('Pagos prima deuda:         %.6f  | spread promedio sobre deuda: %.5f\n', ...
        DebtPremPayments, avg_debt_spread_paid);
    fprintf('Masa con deuda a<0:        %.4f  | masa en amin: %.4f\n', mass_debt, mass_amin);
    fprintf('Masa deuda por z:          [%s]\n', num2str(mass_debt_by_z, ' %.4f'));
    fprintf('--- Market Clearing ---\n');
    fprintf('Bien informal C_I-Y_I:     %.2e\n', goods_I_err);
    fprintf('Walras formal residual:    %.2e\n', walras_err);
    fprintf('Labor clearing E[lF+lI]:   %.6f\n', labor_clear);
    fprintf('PMgL check:                %.2e\n', pmgl_check);
    % T6: sorting por riqueza — brecha de informalidad Q1 vs Q5.
    % Modelo intensivo: el target principal usa share de horas informales
    % por quintil. El headcount Pr(ell_I > ell_F) queda como diagnostico.
    % T6_data Peru (INEI/ENAHO 2017): Q1=97.1%, Q5=44.1% -> T6=0.530
    ratio_inf_aa = ell_I ./ max(ell_F + ell_I, 1e-12);
    g_tot_w      = sum(g, 2);   % marginal riqueza — suma sobre todos los Ns tipos
    cdf_w        = cumsum(g_tot_w) * da;
    idx_q20      = max(find(cdf_w <= 0.20, 1, 'last'), 1);
    idx_q80      = min(find(cdf_w >= 0.80, 1), I);
    if isempty(idx_q20), idx_q20 = 1;   end
    if isempty(idx_q80), idx_q80 = I;   end
    mass_Q1 = da * sum(sum(g(1:idx_q20, :)));
    mass_Q5 = da * sum(sum(g(idx_q80:end, :)));

    % T4 extensivo: fraccion de agentes con ell_I > ell_F (diagnostico).
    ext_inf_aa = double(ell_I > ell_F);   % 1 si "principalmente informal"
    T4_ext = da * sum(sum(g .* ext_inf_aa));
    T4_model = E_ellI / max(E_ellF + E_ellI, 1e-12);

    if mass_Q1 > 1e-10
        E_ellF_Q1 = da * sum(sum(g(1:idx_q20, :) .* ell_F(1:idx_q20, :))) / mass_Q1;
        E_ellI_Q1 = da * sum(sum(g(1:idx_q20, :) .* ell_I(1:idx_q20, :))) / mass_Q1;
        T6_Q1 = E_ellI_Q1 / max(E_ellF_Q1 + E_ellI_Q1, 1e-12);
        T6_Q1_avg_ratio = da * sum(sum(g(1:idx_q20, :) .* ratio_inf_aa(1:idx_q20, :))) / mass_Q1;
        T6_Q1_ext = da * sum(sum(g(1:idx_q20, :) .* ext_inf_aa(1:idx_q20, :))) / mass_Q1;
    else
        T6_Q1 = NaN;
        T6_Q1_avg_ratio = NaN;
        T6_Q1_ext = NaN;
    end
    if mass_Q5 > 1e-10
        E_ellF_Q5 = da * sum(sum(g(idx_q80:end, :) .* ell_F(idx_q80:end, :))) / mass_Q5;
        E_ellI_Q5 = da * sum(sum(g(idx_q80:end, :) .* ell_I(idx_q80:end, :))) / mass_Q5;
        T6_Q5 = E_ellI_Q5 / max(E_ellF_Q5 + E_ellI_Q5, 1e-12);
        T6_Q5_avg_ratio = da * sum(sum(g(idx_q80:end, :) .* ratio_inf_aa(idx_q80:end, :))) / mass_Q5;
        T6_Q5_ext = da * sum(sum(g(idx_q80:end, :) .* ext_inf_aa(idx_q80:end, :))) / mass_Q5;
    else
        T6_Q5 = NaN;
        T6_Q5_avg_ratio = NaN;
        T6_Q5_ext = NaN;
    end
    T6_model = T6_Q1 - T6_Q5;
    T6_model_avg_ratio = T6_Q1_avg_ratio - T6_Q5_avg_ratio;
    T6_model_ext = T6_Q1_ext - T6_Q5_ext;

    % T6c: T6 con quintiles de GASTO (contraparte correcta de INEI Cuadro 7.5).
    % INEI ordena hogares por gasto per capita, no por activos.
    % Aqui se ordena por exp_disp = c_F + p_I*c_I (gasto total del hogar en el modelo).
    exp_vec_all  = exp_disp(:);
    g_vec_all    = g(:) * da;
    ellF_vec_all = ell_F(:);
    ellI_vec_all = ell_I(:);
    extI_vec_all = ext_inf_aa(:);
    ok_c = isfinite(exp_vec_all) & isfinite(g_vec_all) & g_vec_all > 0;
    [~, idx_csort]  = sort(exp_vec_all(ok_c), 'ascend');
    g_cs    = g_vec_all(ok_c);    g_cs    = g_cs(idx_csort);
    ellF_cs = ellF_vec_all(ok_c); ellF_cs = ellF_cs(idx_csort);
    ellI_cs = ellI_vec_all(ok_c); ellI_cs = ellI_cs(idx_csort);
    extI_cs = extI_vec_all(ok_c); extI_cs = extI_cs(idx_csort);
    cdf_cs  = cumsum(g_cs) / max(sum(g_cs), 1e-12);
    idx_cq20 = max(find(cdf_cs <= 0.20, 1, 'last'), 1);
    idx_cq80 = min(find(cdf_cs >= 0.80, 1),  length(g_cs));
    if isempty(idx_cq20), idx_cq20 = 1; end
    if isempty(idx_cq80), idx_cq80 = length(g_cs); end
    mass_cQ1 = sum(g_cs(1:idx_cq20));
    mass_cQ5 = sum(g_cs(idx_cq80:end));
    if mass_cQ1 > 1e-10
        E_ellF_cQ1 = sum(g_cs(1:idx_cq20) .* ellF_cs(1:idx_cq20)) / mass_cQ1;
        E_ellI_cQ1 = sum(g_cs(1:idx_cq20) .* ellI_cs(1:idx_cq20)) / mass_cQ1;
        T6c_Q1     = E_ellI_cQ1 / max(E_ellF_cQ1 + E_ellI_cQ1, 1e-12);
        T6c_Q1_ext = sum(g_cs(1:idx_cq20) .* extI_cs(1:idx_cq20)) / mass_cQ1;
    else
        T6c_Q1 = NaN; T6c_Q1_ext = NaN;
    end
    if mass_cQ5 > 1e-10
        E_ellF_cQ5 = sum(g_cs(idx_cq80:end) .* ellF_cs(idx_cq80:end)) / mass_cQ5;
        E_ellI_cQ5 = sum(g_cs(idx_cq80:end) .* ellI_cs(idx_cq80:end)) / mass_cQ5;
        T6c_Q5     = E_ellI_cQ5 / max(E_ellF_cQ5 + E_ellI_cQ5, 1e-12);
        T6c_Q5_ext = sum(g_cs(idx_cq80:end) .* extI_cs(idx_cq80:end)) / mass_cQ5;
    else
        T6c_Q5 = NaN; T6c_Q5_ext = NaN;
    end
    T6c_model     = T6c_Q1 - T6c_Q5;
    T6c_model_ext = T6c_Q1_ext - T6c_Q5_ext;

    % Tgasto_tipo: gasto total de hogares formal-dominantes vs informal-dominantes.
    % "Formal" = ell_F > ell_I (margen intensivo). Contraparte ENAHO:
    % dominant_hours ~1.91; head_main/docx ~1.96-2.10.
    formal_mask_fi   = double(ell_F > ell_I);
    informal_mask_fi = 1 - formal_mask_fi;
    mass_fi_F = da * sum(sum(g .* formal_mask_fi));
    mass_fi_I = da * sum(sum(g .* informal_mask_fi));
    if mass_fi_F > 1e-10 && mass_fi_I > 1e-10
        E_gasto_fi_F  = da * sum(sum(g .* exp_disp .* formal_mask_fi))   / mass_fi_F;
        E_gasto_fi_I  = da * sum(sum(g .* exp_disp .* informal_mask_fi)) / mass_fi_I;
        ratio_gasto_FI = E_gasto_fi_F / max(E_gasto_fi_I, 1e-12);
        SD_gasto_fi_F  = sqrt(da * sum(sum(g .* formal_mask_fi   .* (exp_disp - E_gasto_fi_F).^2)) / mass_fi_F);
        SD_gasto_fi_I  = sqrt(da * sum(sum(g .* informal_mask_fi .* (exp_disp - E_gasto_fi_I).^2)) / mass_fi_I);
    else
        E_gasto_fi_F = NaN; E_gasto_fi_I = NaN;
        ratio_gasto_FI = NaN; SD_gasto_fi_F = NaN; SD_gasto_fi_I = NaN;
    end
    Tgasto_tipo = ratio_gasto_FI;

    % TgFI_canasta: composicion de canasta F/I inducida por el CES.
    %   TgFI = c_F_agregado / (p_I * c_I_agregado) = [omega_C/(1-omega_C)]^sigma_C * p_I^(sigma_C-1)
    %   Por CES homotetico este ratio es identico para todos los agentes.
    %   No usar el 2.10 ENAHO como target de esta medida: ese dato clasifica hogares,
    %   no gasto por tipo de bien formal/informal.
    c_F_agg = da * sum(sum(g .* c_F_disp));
    c_I_agg = da * sum(sum(g .* c_I_disp));
    TgFI_composicion = c_F_agg / max(p_I * c_I_agg, 1e-12);
    TgFI_canasta = TgFI_composicion;

    % T_kappa_z: gap tasa formalidad z_alto - z_bajo (margen intensivo)
    % Contraparte modelo de: tasa formal secundaria+ - tasa formal sin secundaria.
    % Target: 0.386 (EPEN 2025 broad).
    idx_zmin = (z == min(z));
    idx_zmax = (z == max(z));
    form_rate_z1 = sum(sum(g(:,idx_zmin) .* ell_F(:,idx_zmin))) / ...
                   max(sum(sum(g(:,idx_zmin) .* (ell_F(:,idx_zmin)+ell_I(:,idx_zmin)))), 1e-12);
    form_rate_z2 = sum(sum(g(:,idx_zmax) .* ell_F(:,idx_zmax))) / ...
                   max(sum(sum(g(:,idx_zmax) .* (ell_F(:,idx_zmax)+ell_I(:,idx_zmax)))), 1e-12);
    T_kappa_z_model = form_rate_z2 - form_rate_z1;
    % Tkz: grupos AMPLIOS consistentes con pi_low=0.64 (sin secundaria vs secundaria+).
    % EPEN 2025 edu4 grupos combinados: hrs_formal_low=0.189, hrs_formal_high=0.575.
    % Script calculo: epen_kappa_moments_edu4_2025.csv.
    % Referencia grupos extremos (EPEN 2025): 0.573 (primaria vs universitaria+).
    T_kappa_z_data  = 0.386;   % EPEN 2025, grupos amplios: sin secundaria vs secundaria+ (broad)
    env_T_kappa_z_data = str2double(getenv('HA_IE_TKZ_DATA')); % _Env
    if isfinite(env_T_kappa_z_data) && env_T_kappa_z_data >= 0 && env_T_kappa_z_data <= 1
        T_kappa_z_data = env_T_kappa_z_data;
    end

    % T5 nominal: p_I*Y_I / (Y_F + p_I*Y_I)
    % Contraparte correcta del dato Cuenta Satelite (PBI nominal en precios corrientes)
    T5_nom = p_I_star * Y_I / (Y_F + p_I_star * Y_I);

    fprintf('--- Calibracion Targets (modelo | dato Peru) ---\n');
    fprintf('  [PRIMARIOS - 4 targets]\n');
    fprintf('  T4  E[lI]/(E[lF+lI])  sector informal: %.4f | %.3f  (Cuenta Sat.2024)  instr: psi_F/psi_I\n', T4_model, T4_data);
    fprintf('  T5  pI*Y_I/(Y_F+pI*Y_I) PIB nominal:   %.4f | %.3f  (Cuenta Sat.2024)  instr: A_I\n', T5_nom, T5_data);
    fprintf('  Tkz gap formal z2-z1 (int.):            %.4f | %.3f  (EPEN 2025 broad)   instr: kappa_z1\n', T_kappa_z_model, T_kappa_z_data);
    fprintf('       form_rate z_min=%.2f:              %.4f\n', min(z), form_rate_z1);
    fprintf('       form_rate z_max=%.2f:              %.4f\n', max(z), form_rate_z2);
    fprintf('  Tgasto_tipo E[gasto|lF>lI]/E[gasto|lI>=lF]: %.4f | %.3f  (ENAHO dominant_hours) instr: sorting\n', Tgasto_tipo, Tgasto_tipo_data);
    fprintf('  TgFI_canasta c_F/(p_I*c_I):             %.4f | n/a   (diagnostico CES; sin target ENAHO directo)\n', TgFI_canasta);
    fprintf('  [CANALES DISPONIBLES - 5]\n');
    fprintf('       psi_F/psi_I -> T4; A_I -> T5; kappa_z1 -> Tkz; sorting -> Tgasto_tipo; T6 queda como chequeo\n');
    % T1 household: usa w_I_star como PMgL (lump) o como ingreso mixto (hours)
    % En modo hours, w_I_star es el PMgL de la firma; el hogar percibe w_I_household_star
    if strcmp(informal_profit_rule, 'hours')
        w_I_household_star = w_I_star + profit_I_star / max(L_I_star, 1e-12);
        Pi_lump_star = 0;
    else
        w_I_household_star = w_I_star;
        Pi_lump_star = profit_I_star;
    end

    fprintf('  [MODO INGRESO INFORMAL]\n');
    fprintf('       informal_profit_rule=%s; w_I_marg=%.5f; w_I_hh=%.5f; Pi_lump=%.5f\n', ...
        informal_profit_rule, w_I_star, w_I_household_star, Pi_lump_star);
    fprintf('       w_F bruto=%.5f; w_F neto=(1-tau)w_F=%.5f; L_F*=%.5f; L_I*=%.5f\n', ...
        w_F_star, (1-tau)*w_F_star, L_F_star, L_I_star);

    fprintf('  [REFERENCIA — no calibrada]\n');
    fprintf('  T1  marginal  w_F/(w_I_marg*theta):     %.4f | ~%.2f  (BCR) [rule=%s]\n', w_F_star/(w_I_star*theta), T1_ref, informal_profit_rule);
    fprintf('  T1  household w_F/(w_I_hh*theta):       %.4f | ~%.2f  (ingreso mixto observado)\n', w_F_star/(w_I_household_star*theta), T1_ref);
    fprintf('  T1  (1-tau)*w_F/(w_I_hh*theta) neto:   %.4f\n', (1-tau)*w_F_star/(w_I_household_star*theta));
    fprintf('  T5  Y_I/(Y_F+Y_I) real:                 %.4f\n', Y_I/(Y_F+Y_I));
    fprintf('  [AUXILIARES — diagnostico]\n');
    fprintf('  T4  extensivo frac(lI>lF):              %.4f\n', T4_ext);
    fprintf('  T6  gap Q1-Q5 horas inf.:               %.4f | %.3f  (INEI-ENAHO 2017; chequeo)\n', T6_model, T6_data);
    fprintf('       Q1 share horas informales:         %.4f | %.3f\n', T6_Q1, T6_Q1_data);
    fprintf('       Q5 share horas informales:         %.4f | %.3f\n', T6_Q5, T6_Q5_data);
    fprintf('  T6  ratio medio lI/lTot Q1-Q5:          %.4f\n', T6_model_avg_ratio);
    fprintf('  T6  extensivo headcount Q1-Q5:          %.4f | %.3f  (INEI 2017)\n', T6_model_ext, T6_data);
    fprintf('       Q1 (pobres) informal ext.:         %.4f | %.3f\n', T6_Q1_ext, T6_Q1_data);
    fprintf('       Q5 (ricos)  informal ext.:         %.4f | %.3f\n', T6_Q5_ext, T6_Q5_data);
    fprintf('  [T6c — quintiles de GASTO (contraparte correcta INEI Cuadro 7.5)]\n');
    fprintf('  T6c gap Q1-Q5 horas inf. (x gasto):    %.4f | %.3f  (INEI-ENAHO 2017)\n', T6c_model, T6_data);
    fprintf('       Q1 share horas informales (c):    %.4f | %.3f\n', T6c_Q1, T6_Q1_data);
    fprintf('       Q5 share horas informales (c):    %.4f | %.3f\n', T6c_Q5, T6_Q5_data);
    fprintf('  T6c extensivo headcount Q1-Q5 (x c):  %.4f\n', T6c_model_ext);
    fprintf('  [Gasto formal/informal - ENAHO 2015-2019]\n');
    fprintf('  Tgasto_tipo total por tipo (modelo|dato):      %.4f | %.3f\n', Tgasto_tipo, Tgasto_tipo_data);
    fprintf('       dato alternativo head_main/docx:          ~1.96 a ~2.10\n');
    fprintf('  TgFI_canasta c_F/(p_I*c_I) (modelo|dato):      %.4f | n/a\n', TgFI_canasta);
    fprintf('  E[gasto | lF>lI] (formal):                    %.4f\n', E_gasto_fi_F);
    fprintf('  E[gasto | lI>lF] (informal):                  %.4f\n', E_gasto_fi_I);
    fprintf('  SD gasto formal:                              %.4f\n', SD_gasto_fi_F);
    fprintf('  SD gasto informal:                            %.4f\n', SD_gasto_fi_I);
    fprintf('C_F agregado:                          %.4f\n', C_F_agg);
    fprintf('C_I agregado:                          %.4f\n', C_I_agg);
    fprintf('--- Parametros Usados ---\n');
    fprintf('Archivo MATLAB ejecutado: %s\n', script_file);
    fprintf('Carpeta .mat: %s\n', mat_output_dir);
    fprintf('results_file=%s\n', results_file);
    fprintf('calib_file=%s\n', calib_file);
    fprintf('A_F=%.4f, A_I=%.5f, alpha_I=%.2f, beta_I=%.2f, theta=%.4f, nu_I=%.4f\n', A_F, A_I, alpha_I, beta_I, theta, nu_I);
    fprintf('psi_F=%.4f, psi_I=%.4f, tau=%.2f, H_bar=%.2f\n', psi_F, psi_I, tau, H_bar);
    fprintf('kappa_z1=%.4f, kappa_z2=%.4f, shape=%.2f; kappa(a) legacy desactivado (min=%.4f, extra=%.4f)\n', ...
        kappa_z1, kappa_z2, kappa_z_shape, kappa_min, kappa_extra);
    fprintf('debt_prem_chi=%.5f, debt_prem_eta=%.3f, debt_prem_rebate=%d, max_spread=%.5f\n', ...
        debt_prem_chi, debt_prem_eta, debt_prem_rebate, max(debt_spread_z));
    fprintf('informal_profit_rule=%s, w_I_marginal=%.5f, w_I_household=%.5f, Pi_lump=%.5f\n', ...
        informal_profit_rule, w_I_star, w_I_household_star, Pi_lump_star);
    fprintf('w_F_bruto=%.5f, w_F_neto=%.5f, L_F*=%.5f, L_I*=%.5f\n', ...
        w_F_star, (1-tau)*w_F_star, L_F_star, L_I_star);
    if USE_Q
        fprintf('USE_Q=1: q=[%.3f, %.3f], lq_up=%.3f, lq_down=%.3f, masa(qH)=%.3f, E[q]=%.3f, Ns=%d tipos\n', ...
            q_low, q_high, lambda_q_up, lambda_q_down, mass_qH_ergodic, mean_q_ergodic, Ns);
    else
        fprintf('USE_Q=0: AR(1) z discretizado con %d nodos, sin heterogeneidad q\n', Ns);
    end
    fprintf('p_I*=%.4f, omega_C=%.2f, sigma_C=%.2f,  amin=%.4f\n',  p_I_star, omega_C, sigma_C, amin);
end
fprintf('========================================\n\n');

% =========================================================================
% 4b. HETEROGENEITY DIAGNOSTICS (es SOLO UN Print para ver distribuciones, datos)
%     Diagnose cross-z heterogeneity
% =========================================================================

if EQUILIBRIUM_MODE == 2
    % Conditional masses
    mass_z1 = da * sum(g(:,1));
    mass_z2 = da * sum(g(:,end));

    % Conditional moments by z-state
    mean_a_z1    = da * sum(a .* g(:,1)) / mass_z1;
    mean_a_z2    = da * sum(a .* g(:,end)) / mass_z2;
    mean_c_z1    = da * sum(c(:,1) .* g(:,1)) / mass_z1;
    mean_c_z2    = da * sum(c(:,end) .* g(:,end)) / mass_z2;
    mean_ellF_z1 = da * sum(ell_F(:,1) .* g(:,1)) / mass_z1;
    mean_ellF_z2 = da * sum(ell_F(:,end) .* g(:,end)) / mass_z2;
    mean_ellI_z1 = da * sum(ell_I(:,1) .* g(:,1)) / mass_z1;
    mean_ellI_z2 = da * sum(ell_I(:,end) .* g(:,end)) / mass_z2;

    std_ellF_z1 = sqrt(da * sum(((ell_F(:,1) - mean_ellF_z1).^2) .* g(:,1)) / mass_z1);
    std_ellF_z2 = sqrt(da * sum(((ell_F(:,end) - mean_ellF_z2).^2) .* g(:,end)) / mass_z2);
    std_ellI_z1 = sqrt(da * sum(((ell_I(:,1) - mean_ellI_z1).^2) .* g(:,1)) / mass_z1);
    std_ellI_z2 = sqrt(da * sum(((ell_I(:,end) - mean_ellI_z2).^2) .* g(:,end)) / mass_z2);

    range_ellF_z1 = [min(ell_F(:,1)), max(ell_F(:,1))];
    range_ellF_z2 = [min(ell_F(:,end)), max(ell_F(:,end))];
    range_ellI_z1 = [min(ell_I(:,1)), max(ell_I(:,1))];
    range_ellI_z2 = [min(ell_I(:,end)), max(ell_I(:,end))];

    cdf_z1  = cumsum(g(:,1)) * da / mass_z1;
    cdf_z2  = cumsum(g(:,end)) * da / mass_z2;
    med_a_z1 = a(find(cdf_z1 >= 0.50, 1));
    med_a_z2 = a(find(cdf_z2 >= 0.50, 1));

    dV_diag = max(c.^(-ga), 1e-12);
    rhs_gap = ((1-tau) * w_F_star - w_I_star * theta);
    RHS_diag = dV_diag .* (ones(I,1) * z) .* rhs_gap;
    mean_rhs_z1 = da * sum(RHS_diag(:,1) .* g(:,1)) / mass_z1;
    mean_rhs_z2 = da * sum(RHS_diag(:,end) .* g(:,end)) / mass_z2;

    ellF_rhs0   = (psi_I/psi_F)^Frisch / (1 + (psi_I/psi_F)^Frisch);
    max_gap_ellF = max(abs(ell_F(:,1) - ell_F(:,end)));
    max_gap_ellI = max(abs(ell_I(:,1) - ell_I(:,end)));
    omega_w_ratio = omega_I_star / w_I_star;

    zdiag = struct( ...
        'z_process_ar', z_process_ar, 'Nz_ar', Nz_ar, ...
        'rho_z_ar', rho_z_ar, 'eta_z_ar', eta_z_ar, ...
        'sd_logz_ar', sd_logz_ar, 'width_z_ar', width_z_ar, ...
        'mu_logz_ar', mu_logz_ar, 'dt_z_ar', dt_z_ar, ...
        'nnz_Qz_ar', nnz(Qz_ar), 'z_ou_diag', z_ou_diag, ...
        'mass_z1', mass_z1, 'mass_z2', mass_z2, ...
        'mean_a_z1', mean_a_z1, 'mean_a_z2', mean_a_z2, ...
        'median_a_z1', med_a_z1, 'median_a_z2', med_a_z2, ...
        'mean_c_z1', mean_c_z1, 'mean_c_z2', mean_c_z2, ...
        'mean_ellF_z1', mean_ellF_z1, 'mean_ellF_z2', mean_ellF_z2, ...
        'mean_ellI_z1', mean_ellI_z1, 'mean_ellI_z2', mean_ellI_z2, ...
        'std_ellF_z1', std_ellF_z1, 'std_ellF_z2', std_ellF_z2, ...
        'std_ellI_z1', std_ellI_z1, 'std_ellI_z2', std_ellI_z2, ...
        'range_ellF_z1', range_ellF_z1, 'range_ellF_z2', range_ellF_z2, ...
        'range_ellI_z1', range_ellI_z1, 'range_ellI_z2', range_ellI_z2, ...
        'max_gap_ellF', max_gap_ellF, 'max_gap_ellI', max_gap_ellI, ...
        'mean_rhs_z1', mean_rhs_z1, 'mean_rhs_z2', mean_rhs_z2, ...
        'rhs_gap', rhs_gap, 'ellF_rhs0', ellF_rhs0, ...
        'omega_w_ratio', omega_w_ratio);

    repo_root = fileparts(fileparts(fileparts(fileparts(script_dir))));
    run_config = struct();
    run_config.created_at = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    run_config.script = mfilename;
    run_config.script_file = script_file;
    run_config.run_tag = RUN_TAG;
    run_config.safe_run_tag = safe_RUN_TAG;
    run_config.output_dir = mat_output_dir;
    run_config.results_file = results_file;
    run_config.calib_file = calib_file;
    run_config.metadata_file = metadata_file;
    run_config.mode = EQUILIBRIUM_MODE;
    run_config.fast_debug = FAST_DEBUG_RUN;
    run_config.verbose = HA_IE_VERBOSE;
    run_config.profile_enabled = HA_IE_PROFILE;
    run_config.total_elapsed = toc;
    run_config.zdrift_method = getenv('HA_IE_ZDRIFT_METHOD');
    run_config.zdrift_reuse = getenv('HA_IE_ZDRIFT_REUSE');
    run_config.zdrift_npts = getenv('HA_IE_ZDRIFT_NPTS');
    run_config.env = ha_collect_env();
    run_config.profile = HA_IE_TIMINGS;
    run_config.sources = struct( ...
        'ou_inputs_script', fullfile(repo_root, 'data', 'enaho', 'scripts', 'enaho_ou_calibration_inputs.do'), ...
        'ou_inputs_csv', fullfile(repo_root, 'data', 'enaho', 'output', 'enaho_ou_calibration_inputs.csv'), ...
        'ou_setenv_commands', fullfile(repo_root, 'data', 'enaho', 'output', 'enaho_ou_setenv_commands.m'), ...
        'kappa_targets', fullfile(repo_root, 'data', 'enaho', 'output', 'epen_kappa_moments_edu4_2025.csv'), ...
        'gasto_targets', fullfile(repo_root, 'data', 'enaho', 'output', 'enaho_model_consistent_gasto_targets_2015_2019.csv'));
    run_config.core = struct( ...
        'EQUILIBRIUM_MODE', EQUILIBRIUM_MODE, 'FAST_DEBUG_RUN', FAST_DEBUG_RUN, ...
        'I', I, 'amin', amin, 'amax', amax, 'maxit', maxit, 'crit', crit, ...
        'max_iter_T', max_iter_T, 'max_iter_wI', max_iter_wI, 'max_iter_pI', max_iter_pI, ...
        'tol_T', tol_T, 'tol_wI', tol_wI, 'tol_pI', tol_pI, ...
        'z_process_ar', z_process_ar, 'Nz_ar', Nz_ar, 'rho_z_ar', rho_z_ar, ...
        'sd_logz_ar', sd_logz_ar, 'eta_z_ar', eta_z_ar, 'dt_z_ar', dt_z_ar, ...
        'width_z_ar', width_z_ar, 'mu_logz_ar', mu_logz_ar, ...
        'A_F', A_F, 'A_I', A_I, 'alpha_I', alpha_I, 'beta_I', beta_I, 'theta', theta, ...
        'nu_I', nu_I, 'psi_F', psi_F, 'psi_I', psi_I, ...
        'omega_C', omega_C, 'sigma_C', sigma_C, ...
        'kappa_z1', kappa_z1, 'kappa_z2', kappa_z2, 'kappa_z_shape', kappa_z_shape, ...
        'debt_prem_chi', debt_prem_chi, 'debt_prem_eta', debt_prem_eta, ...
        'debt_prem_rebate', debt_prem_rebate, 'max_debt_spread', max(debt_spread_z), ...
        'informal_profit_rule', informal_profit_rule);

    fprintf('========================================\n');
    fprintf('HETEROGENEITY DIAGNOSTICS (z types)\n');
    fprintf('========================================\n');
    fprintf('  Wealth mean/median by z:  z1 = %.4f / %.4f,  z2 = %.4f / %.4f\n', ...
        mean_a_z1, med_a_z1, mean_a_z2, med_a_z2);
    fprintf('  Consumption mean by z:    z1 = %.4f, z2 = %.4f\n', mean_c_z1, mean_c_z2);
    fprintf('  Mean ell_F by z:          z1 = %.6f, z2 = %.6f\n', mean_ellF_z1, mean_ellF_z2);
    fprintf('  Max |ell_F(z1)-ell_F(z2)| = %.2e\n', max_gap_ellF);
    fprintf('  RHS_FOC mean by z:        z1 = %.4f, z2 = %.4f\n', mean_rhs_z1, mean_rhs_z2);
    fprintf('  ell_F when RHS=0:         %.6f  (anchor set by psi_F/psi_I)\n', ellF_rhs0);
    fprintf('  omega_I / w_I:            %.6f\n\n', omega_w_ratio);

% =========================================================================
% 4c. CALIBRATION SUMMARY
%     Estrategia: targets primarios T4, T5, Tkz y Tgasto_tipo; T6 queda como chequeo.
%       Instrumentos → Targets:
%         psi_F/psi_I  → T4 = E[ell_I]/(E[ell_F]+E[ell_I]) = 0.557  (Cuenta Sat. 2024, empleo sector informal)
%         A_I          → T5 = p_I*Y_I/(Y_F+p_I*Y_I)        = 0.190  (Cuenta Sat. 2024)
%         kappa_z1     -> Tkz = gap formalidad z2-z1         = 0.386  (EPEN 2025 broad)
%         sorting      -> Tgasto_tipo = E[gasto|lF>lI]/E[gasto|lI>=lF]
%         omega_C      -> demanda relativa CES y p_I; TgFI_canasta es diagnostico
%       kappa(a) esta desactivado para evitar endogeneidad de activos.
%       Referencia (no calibrada):
%         T1 = w_F/(w_I*theta)  [ratio salarial bruto, BCR ~2.30]
% =========================================================================

    % Duplicate calibration console block disabled; the detailed
    % "Calibracion Targets" block above is the single run summary.

    % Current moments
    % T4 target en ratio de horas; E[ell_I] absoluto queda como referencia
    E_ellF_curr     = da * sum(sum(g .* ell_F));
    E_ellI_curr     = da * sum(sum(g .* ell_I));
    T4_ratio_curr   = E_ellI_curr / (E_ellF_curr + E_ellI_curr);
    SI_eff_curr     = L_I_star / (L_F_star + L_I_star);  % share eficiencia (NO usar para T4)
    % Objetos salariales e ingreso total
    T1_wage_net             = (1-tau)*w_F_star / (w_I_star*theta);
    T1_wage_gross           = w_F_star / (w_I_star*theta);
    T1_income_gross_omega   = w_F_star / (omega_I_star*theta);
    T5_real                 = Y_I / (Y_F + Y_I);
    T5_nom                  = p_I_star * Y_I / (Y_F + p_I_star * Y_I);
    ptf_gap                 = A_F/ A_I;   % brecha PTF formal/informal

    if false
    fprintf('\nMomentos actuales vs targets Peru (modelo | dato):\n');
    fprintf('  *** TARGETS PRIMARIOS (3) ***\n');
    fprintf('  T4  E[lI]/(E[lF+lI])  sector inf.:    %.4f | %.3f  (Cuenta Sat.2024)  instr: psi_F/psi_I\n', T4_ratio_curr, T4_data);
    fprintf('  T5  pI*Y_I/(Y_F+pI*Y_I) PIB nominal:  %.4f | %.3f  (Cuenta Sat.2024)  instr: A_I\n', T5_nom, T5_data);
    fprintf('  T6  gap Q1-Q5 horas inf.:              %.4f | %.3f  (INEI-ENAHO 2017)  monitoreo; kappa(a) desactivado\n', T6_model, T6_data);
    fprintf('       Q1 share horas informales:        %.4f | %.3f\n', T6_Q1, T6_Q1_data);
    fprintf('       Q5 share horas informales:        %.4f | %.3f\n', T6_Q5, T6_Q5_data);
    fprintf('  *** CANALES/INSTRUMENTOS DISPONIBLES (4) ***\n');
    fprintf('  psi_F/psi_I -> T4; A_I -> T5; kappa_z1 -> Tkz; omega_C -> demanda/p_I/T5 nominal; T6 chequeo\n');
    fprintf('  Identificacion: con 4 canales y 3 targets, fijar omega_C o agregar un target adicional.\n');
    fprintf('  *** REFERENCIAS (no calibradas) ***\n');
    fprintf('  T1  w_F/(w_I*theta) ratio salarial:   %.4f | ~%.2f  (BCR)\n', T1_wage_gross, T1_ref);
    fprintf('  T1  (1-tau)*w_F/(w_I*theta) neto:     %.4f\n', T1_wage_net);
    fprintf('  T5  Y_I/(Y_F+Y_I) real:               %.4f\n', T5_real);
    fprintf('  T4  L_I/(L_F+L_I) eficiencia:         %.4f   (NO target)\n', SI_eff_curr);
    fprintf('  E[ell_I] absoluto:                     %.4f\n', E_ellI_curr);
    fprintf('  *** PARAMETROS ***\n');
    fprintf('  A_F=%.4f, A_I=%.5f, alpha_I=%.4f, beta_I=%.4f, brecha PTF=%.2f, nu_I=%.4f, kappa_z1=%.4f, kappa_z_shape=%.2f, kappa_extra_legacy=%.4f\n', ...
        A_F, A_I, alpha_I, beta_I, ptf_gap, nu_I, kappa_z1, kappa_z_shape, kappa_extra);
    end

    % Save calibration summary
    calib = struct('script_file', script_file, 'results_file', results_file, 'calib_file', calib_file, ...
        'metadata_file', metadata_file, 'mat_output_dir', mat_output_dir, ...
        'run_tag', RUN_TAG, 'safe_run_tag', safe_RUN_TAG, ...
        'A_I', A_I, 'alpha_I', alpha_I, 'beta_I', beta_I, 'theta', theta, ...
        'psi_F', psi_F, 'psi_I', psi_I, 'A_F', A_F, 'nu_I', nu_I, ...
        'la1', la1, 'la2', la2, 'tau', tau, 'al', al, ...
        'r_star', r_star, 'K_star', K_star, 'K_F_star', K_F_star, 'K_I_star', K_I_star, ...
        'w_F_star', w_F_star, 'w_I_star', w_I_star, ...
        'omega_I_star', omega_I_star, 'T_star', T_star, ...
        'T1_wage_net', T1_wage_net, 'T1_wage_gross', T1_wage_gross, ...
        'T1_income_gross_using_omega', T1_income_gross_omega, ...
        'T4_ratio', T4_ratio_curr, 'T4_hours', E_ellI_curr, ...
        'T4_eff', SI_eff_curr, 'T5_real', T5_real, 'T5_nom', T5_nom, ...
        'T6_model', T6_model, 'T6_Q1', T6_Q1, 'T6_Q5', T6_Q5, ...
        'TgFI_data', TgFI_data, 'Tgasto_tipo_data', Tgasto_tipo_data, 'TgFI_canasta_data', TgFI_canasta_data, ...
        'Tgasto_tipo', Tgasto_tipo, 'TgFI_canasta', TgFI_canasta, ...
        'TgFI_composicion', TgFI_composicion, 'ratio_gasto_FI', ratio_gasto_FI, ...
        'E_gasto_fi_F', E_gasto_fi_F, 'E_gasto_fi_I', E_gasto_fi_I, ...
        'SD_gasto_fi_F', SD_gasto_fi_F, 'SD_gasto_fi_I', SD_gasto_fi_I, ...
        'kappa_extra', kappa_extra, 'gamma_k', gamma_k, 'a_bar_k', a_bar_k, ...
        'kappa_z1', kappa_z1, 'kappa_z2', kappa_z2, 'kappa_z_shape', kappa_z_shape, ...
        'form_rate_z1', form_rate_z1, 'form_rate_z2', form_rate_z2, ...
        'T_kappa_z_model', T_kappa_z_model, 'T_kappa_z_data', T_kappa_z_data, ...
        'debt_prem_chi', debt_prem_chi, 'debt_prem_eta', debt_prem_eta, ...
        'debt_prem_rebate', debt_prem_rebate, 'debt_spread_z', debt_spread_z, ...
        'DebtPremPayments', DebtPremPayments, 'avg_debt_spread_paid', avg_debt_spread_paid, ...
        'mass_debt', mass_debt, 'mass_amin', mass_amin, ...
        'mass_debt_by_z', mass_debt_by_z, 'mass_amin_by_z', mass_amin_by_z, ...
        'mean_assets_by_z', mean_assets_by_z, 'mean_cons_by_z', mean_cons_by_z, ...
        'ptf_gap', ptf_gap, 'p_I', p_I, 'omega_C', omega_C, ...
        'eta_C', eta_C, 'sigma_C', sigma_C, 'zdiag', zdiag, ...
        'Nz_ar', Nz_ar, 'rho_z_ar', rho_z_ar, 'sd_logz_ar', sd_logz_ar, ...
        'eta_z_ar', eta_z_ar, 'dt_z_ar', dt_z_ar, 'mu_logz_ar', mu_logz_ar, ...
        'qz_scale_ar', qz_scale_ar, 'width_z_ar', width_z_ar, ...
        'z_process_ar', z_process_ar, 'z_ou_diag', z_ou_diag, ...
        'z_nodes', z, 'logz_nodes', logz_nodes, 'pi_z_ar', pi_z_ar, ...
        'profile_enabled', HA_IE_PROFILE, 'profile', HA_IE_TIMINGS, ...
        'zdrift_method', getenv('HA_IE_ZDRIFT_METHOD'));
    calib.run_config = run_config;
    save(calib_file, 'calib', 'zdiag', 'run_config', 'HA_IE_TIMINGS');
    ha_write_run_metadata(metadata_file, run_config, calib);
    fprintf('Calibration saved to %s\n\n', calib_file);
end

% =========================================================================
% 5. SAVE COMPLETO PARA GRAFICAR (cargable en plot_ou_process_distributions.m)
% =========================================================================

if EQUILIBRIUM_MODE == 2
    try
        save(results_file, ...
            'a', 'da', 'I', 'Ns', 'g', 'c', 'ell_F', 'ell_I', 'V', ...
            'z', 'zz', 'aa', 'qq_informal', 'kappa_F_aa', 'USE_Q', 'q_inf', ...
            'debt_prem_chi', 'debt_prem_eta', 'debt_prem_rebate', ...
            'debt_spread_z', 'debt_spread_aa', 'debt_balance_aa', 'debt_indicator_aa', ...
            'script_file', 'mat_output_dir', 'results_file', 'calib_file', 'metadata_file', 'run_config', ...
            'Nz_ar', 'rho_z_ar', 'sd_logz_ar', 'eta_z_ar', 'dt_z_ar', 'mu_logz_ar', ...
            'qz_scale_ar', 'width_z_ar', 'z_process_ar', 'z_ou_diag', ...
            'logz_nodes', 'Pz_annual', 'pi_z_ar', 'Qz_ar', ...
            'w_F_star', 'w_I_star', 'omega_I_star', 'T_eq', 'profit_I_star', 'p_I_star', ...
            'r_star', 'K_star', 'K_F_star', 'K_I_star', 'Y_F', 'Y_I', 'L_F_star', 'L_I_star', ...
            'ge_history', 'r_grid', 'S', 'KD', 'w_F_r', 'L_F', 'L_I', ...
            'T_eq_r', 'w_I_eq_r', 'Pi_I_eq_r', 'p_I_eq_r', 'Y_I_eq_r', ...
            'C_I_eq_r', 'C_F_eq_r', 'omega_I_eq_r', 'excess_K_r', 'goods_I_err_r', ...
            'E_ellF', 'E_ellI', 'labor_clear', 'walras_err', 'goods_I_err', 'pmgl_check', ...
            'C_I_agg', 'C_F_agg', 'T_star', ...
            'A_F', 'A_I', 'alpha_I', 'beta_I', 'theta', 'nu_I', 'psi_F', 'psi_I', 'tau', 'H_bar', 'al', 'd', 'rho', 'Frisch', ...
            'kappa_min', 'kappa_extra', 'gamma_k', 'a_bar_k', 'kappa_z1', 'kappa_z2', 'kappa_z_shape', 'T_kappa_z_model', 'T_kappa_z_data', ...
            'q_low', 'q_high', 'lambda_q_up', 'lambda_q_down', ...
            'mass_qH_ergodic', 'mean_q_ergodic', ...
            'p_I', 'omega_C', 'eta_C', 'sigma_C', 'EQUILIBRIUM_MODE', 'amin', 'amax', 'tax_rev', ...
            'zdiag', 'mass_z1', 'mass_z2', 'mean_a_z1', 'mean_a_z2', 'med_a_z1', 'med_a_z2', ...
            'mean_c_z1', 'mean_c_z2', 'mean_ellF_z1', 'mean_ellF_z2', ...
            'mean_ellI_z1', 'mean_ellI_z2', 'mean_rhs_z1', 'mean_rhs_z2', ...
            'ellF_rhs0', 'max_gap_ellF', 'max_gap_ellI', 'ext_inf_aa', ...
            'T4_model', 'T4_ext', ...
            'T6_Q1', 'T6_Q5', 'T6_model', ...
            'T6_Q1_avg_ratio', 'T6_Q5_avg_ratio', 'T6_model_avg_ratio', ...
            'T6_Q1_ext', 'T6_Q5_ext', 'T6_model_ext', 'T5_nom', ...
            'Tgasto_tipo', 'TgFI_canasta', 'Tgasto_tipo_data', 'TgFI_canasta_data', ...
            'ratio_gasto_FI', 'TgFI_composicion', 'E_gasto_fi_F', 'E_gasto_fi_I', ...
            'SD_gasto_fi_F', 'SD_gasto_fi_I', ...
            'DebtPremPayments', 'avg_debt_spread_paid', 'mass_debt', 'mass_amin', ...
            'mass_debt_by_z', 'mass_amin_by_z', 'mean_assets_by_z', 'mean_cons_by_z', ...
            'Gini_a', 'Gini_c', 'Gini_c_by_a', 'mean_a_mod', 'mean_exp_mod', ...
            'lorenz_a', 'lorenz_c', 'lorenz_c_by_a', 'cum_pop_a', 'cum_pop_c', 'g_marg_a', ...
            'T4_data', 'T5_data', 'TgFI_data', 'T6_data', 'T6_Q1_data', 'T6_Q5_data', 'T1_ref', ...
            'informal_profit_rule', 'w_I_household_star', 'Pi_lump_star', ...
            'HA_IE_TIMINGS');
        fprintf('Resultados guardados en %s\n', results_file);
        fprintf('Figuras OU/trampa: >> plot_ou_process_distributions(''%s'')\n\n', results_file);
    catch ME_save
        fprintf('WARN: no se pudo guardar results_v10_latest.mat: %s\n', ME_save.message);
    end
end

% =========================================================================
% 6. PLOTS — separado en plot_ou_process_distributions.m
% =========================================================================
% Uso: >> plot_ou_process_distributions
% O:   >> plot_ou_process_distributions('mi_run.mat')


% =========================================================================
% LOCAL FUNCTION: run_ge_v10
%   General equilibrium in (r, p_I) with R2 active.
% =========================================================================

% -------------------------------------------------------------------------
% run_ge_v10 — EQUILIBRIO GENERAL: biseccion en r
% -------------------------------------------------------------------------
% Bisecta r en [-0.04, 0.0499] hasta S(r) = KD(r) (mercado de activos).
% Entradas clave: v0_init (guess V), precios iniciales p_I_init/w_I_init/Pi_I_init,
%   grids a/z/la, parametros del hogar (ga, rho, Frisch, psi_F, psi_I, theta),
%   parametros firma formal (A_F, al, d), firma informal (A_I, alpha_I, beta_I),
%   tolerancias y limites de iteracion para todos los loops internos.
% Salidas: r_star, K_star, w_F_star, w_I_out, p_I_out, L_F_star, L_I_star,
%   distribucion g(I x Ns), politicas V/c/ell_F/ell_I, agregados C_I/C_F.
function [r_star, K_star, S_star, w_F_star, L_F_star, L_I_star, V, g, c, ell_F, ell_I, ...
          T_out, w_I_out, Pi_I_share_out, p_I_out, Y_I_out, C_I_agg_out, C_F_agg_out, v0_out, ge_history] = ...
    run_ge_v10(v0_init, p_I_init, w_I_init, Pi_I_init, a, z, la, ga, rho, Frisch, ...
               psi_F, psi_I, theta, A_F, al, d, A_I, alpha_I, beta_I, z_ave, I, da, aa, zz, ...
               maxit, crit, Delta, Aswitch, tau, H_bar, tol_T, max_iter_T, tol_wI, ...
               max_iter_wI, tol_pI, max_iter_pI, pI_grid_init, pI_expand_factor, ...
               max_pI_expand, L_I_floor_wI, damp_wI_log, damp_piI, damp_T)

r_low  = -0.04;
r_high =  0.0499;
env_r_lo = str2double(getenv('HA_IE_R_LO')); % _Env
env_r_hi = str2double(getenv('HA_IE_R_HI')); % _Env
if isfinite(env_r_lo) && isfinite(env_r_hi) && env_r_lo < env_r_hi
    r_low  = env_r_lo;
    r_high = env_r_hi;
end
tol_r = 1e-5;
max_bisect = 60;
env_tol_r = str2double(getenv('HA_IE_TOL_R'));
env_max_bisect = str2double(getenv('HA_IE_MAX_BISECT_R'));
if isfinite(env_tol_r) && env_tol_r > 0, tol_r = env_tol_r; end
if isfinite(env_max_bisect) && env_max_bisect >= 1, max_bisect = round(env_max_bisect); end
fprintf('GE bisect r en [%.4f, %.4f], tol=%.1e, max_iter=%d\n', r_low, r_high, tol_r, max_bisect);

v0_mid = v0_init;
T_mid = 0;
w_I_mid = w_I_init;
Pi_I_mid = Pi_I_init;
p_I_mid = p_I_init;
ge_history = init_ge_history_v10();

[S_low, KD_low, wF_low, LF_low, LI_low, ~, ~, ~, ~, ~, T_low, wI_low, Pi_low, pI_low, YI_low, CI_low, CF_low, v0_low] = ...
    solve_price_clearing_v10(r_low, p_I_mid, v0_mid, T_mid, w_I_mid, Pi_I_mid, ...
    a, z, la, ga, rho, Frisch, psi_F, psi_I, theta, A_F, al, d, A_I, alpha_I, beta_I, ...
    z_ave, I, da, aa, zz, maxit, crit, Delta, Aswitch, tau, H_bar, tol_T, max_iter_T, ...
    tol_wI, max_iter_wI, tol_pI, max_iter_pI, pI_grid_init, pI_expand_factor, ...
    max_pI_expand, L_I_floor_wI, damp_wI_log, damp_piI, damp_T);
excess_low = S_low - KD_low;
ge_history = append_ge_history_v10(ge_history, r_low, S_low, KD_low, wF_low, LF_low, LI_low, ...
    T_low, wI_low, Pi_low, pI_low, YI_low, CI_low, CF_low);

[S_high, KD_high, wF_high, LF_high, LI_high, ~, ~, ~, ~, ~, T_high, wI_high, Pi_high, pI_high, YI_high, CI_high, CF_high, v0_high] = ...
    solve_price_clearing_v10(r_high, pI_low, v0_low, T_low, wI_low, Pi_low, ...
    a, z, la, ga, rho, Frisch, psi_F, psi_I, theta, A_F, al, d, A_I, alpha_I, beta_I, ...
    z_ave, I, da, aa, zz, maxit, crit, Delta, Aswitch, tau, H_bar, tol_T, max_iter_T, ...
    tol_wI, max_iter_wI, tol_pI, max_iter_pI, pI_grid_init, pI_expand_factor, ...
    max_pI_expand, L_I_floor_wI, damp_wI_log, damp_piI, damp_T);
excess_high = S_high - KD_high;
ge_history = append_ge_history_v10(ge_history, r_high, S_high, KD_high, wF_high, LF_high, LI_high, ...
    T_high, wI_high, Pi_high, pI_high, YI_high, CI_high, CF_high);

fprintf('GE bracket check: excess(r_low)=%.6f, excess(r_high)=%.6f\n', excess_low, excess_high);
if ~isfinite(excess_low) || ~isfinite(excess_high) || excess_low * excess_high > 0
    error('run_ge_v10 invalid bracket in r: excess has same sign at endpoints.');
end

v0_mid = v0_high;
T_mid = T_high;
w_I_mid = wI_high;
Pi_I_mid = Pi_high;
p_I_mid = pI_high;

for iter = 1:max_bisect
    r = bracket_preserving_step(r_low, excess_low, r_high, excess_high);
    [S_mid, KD_mid, w_F_mid, L_F_mid, L_I_mid, V, g, c, ell_F, ell_I, ...
        T_tmp, wI_tmp, Pi_tmp, pI_tmp, YI_tmp, CI_tmp, CF_tmp, v0_tmp] = ...
        solve_price_clearing_v10(r, p_I_mid, v0_mid, T_mid, w_I_mid, Pi_I_mid, ...
        a, z, la, ga, rho, Frisch, psi_F, psi_I, theta, A_F, al, d, A_I, alpha_I, beta_I, ...
        z_ave, I, da, aa, zz, maxit, crit, Delta, Aswitch, tau, H_bar, tol_T, ...
        max_iter_T, tol_wI, max_iter_wI, tol_pI, max_iter_pI, pI_grid_init, ...
        pI_expand_factor, max_pI_expand, L_I_floor_wI, damp_wI_log, damp_piI, damp_T);

    excess_mid = S_mid - KD_mid;
    ge_history = append_ge_history_v10(ge_history, r, S_mid, KD_mid, w_F_mid, L_F_mid, L_I_mid, ...
        T_tmp, wI_tmp, Pi_tmp, pI_tmp, YI_tmp, CI_tmp, CF_tmp);
    fprintf('GE iter %2d: r=%.6f, p_I=%.6f, S=%.4f, KD=%.4f, excK=%.6f, excI=%.3e\n', ...
        iter, r, pI_tmp, S_mid, KD_mid, excess_mid, CI_tmp - YI_tmp);

    if abs(excess_mid) < tol_r || (r_high - r_low) < tol_r
        break;
    end

    if excess_low * excess_mid <= 0
        r_high = r;
        excess_high = excess_mid;
    else
        r_low = r;
        excess_low = excess_mid;
    end

    v0_mid = v0_tmp;
    T_mid = T_tmp;
    w_I_mid = wI_tmp;
    Pi_I_mid = Pi_tmp;
    p_I_mid = pI_tmp;
end

r_star = r;
K_star = KD_mid;
S_star = S_mid;
w_F_star = w_F_mid;
L_F_star = L_F_mid;
L_I_star = L_I_mid;
T_out = T_tmp;
w_I_out = wI_tmp;
Pi_I_share_out = Pi_tmp;
p_I_out = pI_tmp;
Y_I_out = YI_tmp;
C_I_agg_out = CI_tmp;
C_F_agg_out = CF_tmp;
v0_out = v0_tmp;
ge_history = sort_ge_history_v10(ge_history);
end


function ge_history = init_ge_history_v10()
empty = [];
ge_history = struct( ...
    'r_grid', empty, 'S', empty, 'KD', empty, 'w_F_r', empty, ...
    'L_F', empty, 'L_I', empty, 'T_eq_r', empty, 'w_I_eq_r', empty, ...
    'Pi_I_eq_r', empty, 'p_I_eq_r', empty, 'Y_I_eq_r', empty, ...
    'C_I_eq_r', empty, 'C_F_eq_r', empty, 'omega_I_eq_r', empty, ...
    'excess_K_r', empty, 'goods_I_err_r', empty);
end


function ge_history = append_ge_history_v10(ge_history, r_val, S_val, KD_val, wF_val, LF_val, LI_val, ...
    T_val, wI_val, Pi_val, pI_val, YI_val, CI_val, CF_val)
ge_history.r_grid(end+1,1) = r_val;
ge_history.S(end+1,1) = S_val;
ge_history.KD(end+1,1) = KD_val;
ge_history.w_F_r(end+1,1) = wF_val;
ge_history.L_F(end+1,1) = LF_val;
ge_history.L_I(end+1,1) = LI_val;
ge_history.T_eq_r(end+1,1) = T_val;
ge_history.w_I_eq_r(end+1,1) = wI_val;
ge_history.Pi_I_eq_r(end+1,1) = Pi_val;
ge_history.p_I_eq_r(end+1,1) = pI_val;
ge_history.Y_I_eq_r(end+1,1) = YI_val;
ge_history.C_I_eq_r(end+1,1) = CI_val;
ge_history.C_F_eq_r(end+1,1) = CF_val;
ge_history.omega_I_eq_r(end+1,1) = pI_val * YI_val / max(LI_val, 1e-12);
ge_history.excess_K_r(end+1,1) = S_val - KD_val;
ge_history.goods_I_err_r(end+1,1) = CI_val - YI_val;
end


function ge_history = sort_ge_history_v10(ge_history)
[r_sorted, order] = sort(ge_history.r_grid(:));
fields = fieldnames(ge_history);
for jf = 1:numel(fields)
    vals = ge_history.(fields{jf});
    if numel(vals) == numel(order)
        ge_history.(fields{jf}) = vals(order);
    end
end
ge_history.r_grid = r_sorted;
end


% =========================================================================
% LOCAL FUNCTION: solve_price_clearing_v10
%   For fixed r, solve p_I so that C_I_agg = Y_I.
% =========================================================================

% -------------------------------------------------------------------------
% solve_price_clearing_v10 — MERCADO BIEN INFORMAL: biseccion en p_I
% -------------------------------------------------------------------------
% Dado r fijo, bisecta p_I hasta vaciamiento C_I(p_I) = Y_I(p_I).
% Entradas: r (tasa dada por run_ge), p_I_init (guess precio informal),
%   v0_init/T_init/w_I_init/Pi_I_init (warm starts), todos los params del hogar/firmas.
%   pI_grid_init: grid inicial de prueba para encontrar el bracket.
% Salidas: igual que solve_given_prices_v10 mas p_I_out (precio equilibrio).
% Logica: evalua grid → detecta bracket sign-change → biseccion hasta tol_pI.
function [S, KD, w_F, L_F, L_I, V, g, c, ell_F, ell_I, T_out, w_I_out, Pi_I_share_out, ...
          p_I_out, Y_I_out, C_I_agg_out, C_F_agg_out, v0_out] = ...
    solve_price_clearing_v10(r, p_I_init, v0_init, T_init, w_I_init, Pi_I_init, ...
    a, z, la, ga, rho, Frisch, psi_F, psi_I, theta, A_F, al, d, A_I, alpha_I, beta_I, ...
    z_ave, I, da, aa, zz, maxit, crit, Delta, Aswitch, tau, H_bar, tol_T, max_iter_T, ...
    tol_wI, max_iter_wI, tol_pI, max_iter_pI, pI_grid_init, pI_expand_factor, ...
    max_pI_expand, L_I_floor_wI, damp_wI_log, damp_piI, damp_T)

base_grid = sort(unique([pI_grid_init(:); max(p_I_init, 1e-4)]))';
best_abs = Inf;
best_res = struct();
bracket_found = false;

for expand_iter = 0:max_pI_expand
    if expand_iter == 0
        p_grid = base_grid;
    else
        p_grid = sort(unique([base_grid, base_grid(1)/(pI_expand_factor^expand_iter), base_grid(end)*(pI_expand_factor^expand_iter)]));
        p_grid = max(p_grid, 1e-4);
    end

    exc = nan(size(p_grid));
    res = cell(size(p_grid));
    for ip = 1:numel(p_grid)
        [S_t, KD_t, w_F_t, L_F_t, L_I_t, V_t, g_t, c_t, ell_F_t, ell_I_t, T_t, wI_t, Pi_t, ...
            YI_t, CI_t, CF_t, v0_t] = ...
            solve_given_prices_v10(r, p_grid(ip), v0_init, T_init, w_I_init, Pi_I_init, ...
            a, z, la, ga, rho, Frisch, psi_F, psi_I, theta, A_F, al, d, A_I, alpha_I, beta_I, ...
            z_ave, I, da, aa, zz, maxit, crit, Delta, Aswitch, tau, H_bar, tol_T, ...
            max_iter_T, tol_wI, max_iter_wI, L_I_floor_wI, damp_wI_log, damp_piI, damp_T);

        exc(ip) = CI_t - YI_t;
        res{ip} = struct('S', S_t, 'KD', KD_t, 'w_F', w_F_t, 'L_F', L_F_t, 'L_I', L_I_t, ...
            'V', V_t, 'g', g_t, 'c', c_t, 'ell_F', ell_F_t, 'ell_I', ell_I_t, 'T', T_t, ...
            'w_I', wI_t, 'Pi', Pi_t, 'Y_I', YI_t, 'C_I', CI_t, 'C_F', CF_t, 'v0', v0_t, 'p_I', p_grid(ip));

        if abs(exc(ip)) < best_abs
            best_abs = abs(exc(ip));
            best_res = res{ip};
        end

        % Early stop: bracket between (ip-1, ip) — no need to evaluate further points.
        if ip > 1 && isfinite(exc(ip-1)) && isfinite(exc(ip)) && exc(ip-1)*exc(ip) <= 0
            p_low    = p_grid(ip-1);
            p_high   = p_grid(ip);
            exc_low  = exc(ip-1);
            exc_high = exc(ip);
            bracket_found = true;
            break;
        end
    end

    if bracket_found
        break;
    end
end

if ~bracket_found
    error('No p_I bracket found for r=%.6f. Best |C_I-Y_I|=%.3e at p_I=%.6f', r, best_abs, best_res.p_I);
end

mid_res = best_res;
for iter = 1:max_iter_pI
    p_mid = bracket_preserving_step(p_low, exc_low, p_high, exc_high);
    [S_t, KD_t, w_F_t, L_F_t, L_I_t, V_t, g_t, c_t, ell_F_t, ell_I_t, T_t, wI_t, Pi_t, ...
        YI_t, CI_t, CF_t, v0_t] = ...
        solve_given_prices_v10(r, p_mid, mid_res.v0, mid_res.T, mid_res.w_I, mid_res.Pi, ...
        a, z, la, ga, rho, Frisch, psi_F, psi_I, theta, A_F, al, d, A_I, alpha_I, beta_I, ...
        z_ave, I, da, aa, zz, maxit, crit, Delta, Aswitch, tau, H_bar, tol_T, ...
        max_iter_T, tol_wI, max_iter_wI, L_I_floor_wI, damp_wI_log, damp_piI, damp_T);

    exc_mid = CI_t - YI_t;
    mid_res = struct('S', S_t, 'KD', KD_t, 'w_F', w_F_t, 'L_F', L_F_t, 'L_I', L_I_t, ...
        'V', V_t, 'g', g_t, 'c', c_t, 'ell_F', ell_F_t, 'ell_I', ell_I_t, 'T', T_t, ...
        'w_I', wI_t, 'Pi', Pi_t, 'Y_I', YI_t, 'C_I', CI_t, 'C_F', CF_t, 'v0', v0_t, 'p_I', p_mid);

    fprintf('  [p_I iter %2d] p_I=%.6f, C_I=%.6f, Y_I=%.6f, exc=%.3e, w_I=%.6f, Pi_I=%.6f\n', ...
        iter, p_mid, CI_t, YI_t, exc_mid, wI_t, Pi_t);

    if abs(exc_mid) < tol_pI || (p_high - p_low) < tol_pI
        break;
    end

    if exc_low * exc_mid <= 0
        p_high = p_mid;
        exc_high = exc_mid;
    else
        p_low = p_mid;
        exc_low = exc_mid;
    end
end

if max(mid_res.C_I, mid_res.Y_I) < 1e-4
    fprintf('  [p_I note] inactive-good equilibrium: C_I and Y_I are both near zero at the clearing price.\n');
end

S = mid_res.S;
KD = mid_res.KD;
w_F = mid_res.w_F;
L_F = mid_res.L_F;
L_I = mid_res.L_I;
V = mid_res.V;
g = mid_res.g;
c = mid_res.c;
ell_F = mid_res.ell_F;
ell_I = mid_res.ell_I;
T_out = mid_res.T;
w_I_out = mid_res.w_I;
Pi_I_share_out = mid_res.Pi;
p_I_out = mid_res.p_I;
Y_I_out = mid_res.Y_I;
C_I_agg_out = mid_res.C_I;
C_F_agg_out = mid_res.C_F;
v0_out = mid_res.v0;
end


% =========================================================================
% LOCAL FUNCTION: bracket_preserving_step
%   Safeguarded secant step with midpoint fallback.
% =========================================================================

% Paso de biseccion con Illinois/secante que preserva el bracket [x_low, x_high].
function x_try = bracket_preserving_step(x_low, f_low, x_high, f_high)

x_mid = 0.5 * (x_low + x_high);
width = x_high - x_low;

if ~isfinite(f_low) || ~isfinite(f_high) || width <= 0
    x_try = x_mid;
    return;
end

den = (f_high - f_low);
if abs(den) < 1e-14
    x_try = x_mid;
    return;
end

x_sec = x_high - f_high * (x_high - x_low) / den;
guard = 0.10 * width;
x_left = x_low + guard;
x_right = x_high - guard;

if ~isfinite(x_sec) || x_sec <= x_left || x_sec >= x_right
    x_try = x_mid;
else
    x_try = x_sec;
end

end


% =========================================================================
% LOCAL FUNCTION: solve_given_prices_v10
%   Fixed-point solver for fixed (r, p_I) with R2 active.
% =========================================================================

% -------------------------------------------------------------------------
% solve_given_prices_v10 — HACT SOLVER: dados (r, p_I), resuelve modelo hogar
% -------------------------------------------------------------------------
% Entradas clave: r, p_I_candidate (precios fijos desde loops externos),
%   v0 (guess funcion de valor I x Ns), T_init/w_I_init/Pi_I_init (warm starts),
%   grids (a, z, la, aa, zz), params hogar/firma, tolerancias.
% Salidas: S (ahorro agregado), KD (demanda capital), w_F, L_F, L_I,
%   V (funcion de valor I x Ns), g (distribucion I x Ns),
%   c/ell_F/ell_I (politicas), T_out, w_I_out, Pi_I_out, Y_I, C_I, C_F.
%
% Estructura de loops anidados:
%   it_wI: punto fijo w_I = PMgL informal, Pi_I = (1-alpha_I-beta_I)*p_I*Y_I
%     it_T: punto fijo T = tau*w_F*L_F (balance fiscal del gobierno)
%       Precalcula dV en bordes amin/amax (zero-drift, una vez por it_wI)
%       Precalcula c0/ell0 en toda la grilla (zero-drift, I0 del upwind)
%       n: HJB iteracion implicita — upwind scheme, matriz A sparse, B\b
%     KFE: resuelve A'g=0 con A del HJB convergido → g(a,z)
function [S, KD, w_F, L_F, L_I, V, g, c, ell_F, ell_I, T_out, w_I_out, Pi_I_share_out, ...
          Y_I_out, C_I_agg_out, C_F_agg_out, v0_out] = ...
    solve_given_prices_v10(r, p_I_candidate, v0, T_init, w_I_init, Pi_I_init, ...
    a, z, la, ga, rho, Frisch, psi_F, psi_I, theta, A_F, al, d, A_I, alpha_I, beta_I, ...
    z_ave, I, da, aa, zz, maxit, crit, Delta, Aswitch, tau, H_bar, tol_T, max_iter_T, ...
    tol_wI, max_iter_wI, L_I_floor_wI, damp_wI_log, damp_piI, damp_T)

global p_I kappa_F_vec kappa_F_aa qq_informal nu_I
global debt_spread_aa debt_spread_z debt_prem_rebate
t_sgp = tic;
p_I = p_I_candidate;

k_ratio = (al*A_F/(r + d))^(1/(1-al));
w_F = (1-al)*A_F*(k_ratio)^al;

amin = a(1);
amax = a(end);
Ns   = size(qq_informal, 2);   % 2 o 4 segun USE_Q
v = v0;
T = T_init;
w_I = max(w_I_init, 1e-8);
Pi_I_share = max(Pi_I_init, 0);
K_I = 0;

% Regla de beneficios informales (hours=default, lump=transferencia separada)
profit_rule_sgp = lower(strtrim(getenv('HA_IE_INFORMAL_PROFIT_RULE')));
if isempty(profit_rule_sgp), profit_rule_sgp = 'hours'; end
% Inicializar L_I_prev desde el FOC legacy cuando alpha_I=0.
%   w_I_init = p_I*beta_I*A_I*L_I^(beta_I-1)  →  L_I = (p_I*beta_I*A_I/w_I)^(1/(1-beta_I))
if strcmp(profit_rule_sgp, 'hours') && alpha_I == 0 && w_I > 1e-8 && beta_I > 0 && beta_I < 1
    L_I_prev = (p_I * beta_I * A_I / w_I)^(1 / (1 - beta_I));
    L_I_prev = max(L_I_floor_wI, min(L_I_prev, 10.0));
else
    L_I_prev = 0.5;
end

dVf = zeros(I, Ns);
dVb = zeros(I, Ns);

for it_wI = 1:max_iter_wI
    % Salario/Pi que percibe el hogar segun la regla de reparto
    if strcmp(profit_rule_sgp, 'hours')
        % Ingreso mixto: w_I_marginal + Pi_I/L_I.
        w_I_hh  = w_I + Pi_I_share / max(L_I_prev, L_I_floor_wI);
        Pi_lump = 0;
    else
        w_I_hh  = w_I;       % PMgL del hogar = PMgL de la firma
        Pi_lump = Pi_I_share; % beneficio lump-sum separado
    end

    fprintf('  [wI iter %2d] p_I=%.6f, w_I_hh=%.6f, Pi_lump=%.6f, T=%.6f\n', ...
        it_wI, p_I, w_I_hh, Pi_lump, T);
    dV_min = zeros(1, Ns);
    dVf_upper = zeros(1, Ns);
    c0_prev = [];

    % Condiciones de borde HJB: dV en amin y amax donde adot=0 (calculado una vez por it_wI)
    % kappa_F_aa(1,j) y kappa_F_aa(end,j) contienen solo kappa(z) para estado j
    for j = 1:Ns
        params_lo = [amin, z(j), w_F, w_I_hh, theta, r, ga, Frisch, psi_F, psi_I, tau, T, Pi_lump, H_bar, kappa_F_aa(1,j), qq_informal(1,j), debt_spread_z(j)];
        zI_j = z(j)^nu_I;
        dV_guess = max(((1-tau)*w_F*z(j)*0.5 - kappa_F_aa(1,j)*0.5 + w_I_hh*theta*zI_j*qq_informal(1,j)*0.5 ...
            + r*amin - debt_spread_z(j)*max(-amin,0) + T + Pi_lump), 1e-6)^(-ga);
        dV_min(j) = solve_dV_zero_drift_v10(params_lo, dV_guess);

        params_up = [amax, z(j), w_F, w_I_hh, theta, r, ga, Frisch, psi_F, psi_I, tau, T, Pi_lump, H_bar, kappa_F_aa(end,j), qq_informal(end,j), debt_spread_z(j)];
        dV_guess = max(((1-tau)*w_F*z(j)*0.5 - kappa_F_aa(end,j)*0.5 + w_I_hh*theta*zI_j*qq_informal(end,j)*0.5 ...
            + r*amax - debt_spread_z(j)*max(-amax,0) + T + Pi_lump), 1e-6)^(-ga);
        dVf_upper(j) = solve_dV_zero_drift_v10(params_up, dV_guess);
    end

    % Loop T: itera balance fiscal T = tau*w_F*L_F hasta convergencia
    for it_T = 1:max_iter_T
        fprintf('    [T iter %2d] T=%.6f, w_I_hh=%.6f, Pi_lump=%.6f\n', ...
            it_T, T, w_I_hh, Pi_lump);
        c0 = zeros(I, Ns);
        cF0 = zeros(I, Ns);
        cI0 = zeros(I, Ns);
        dV0 = zeros(I, Ns);

        t_zdrift_grid = tic;
        [dV0, cF0, cI0, c0, zd_stats] = zero_drift_solver( ...
            a, z, w_F, w_I_hh, theta, r, ga, Frisch, psi_F, psi_I, tau, T, ...
            Pi_lump, H_bar, kappa_F_aa, qq_informal, c0_prev, @solve_dV_zero_drift_v10, debt_spread_aa);
        ha_profile_add('zero_drift_grid', toc(t_zdrift_grid));
        ha_profile_add_count('zero_drift_compute');
        ha_profile_add_value('zero_drift_fallback_points', zd_stats.fallback_count);
        if isfinite(zd_stats.max_abs_resid)
            ha_profile_add_max('zero_drift_max_resid', zd_stats.max_abs_resid);
        end

        % Punto de referencia I0: consumo y labor en zero-drift (fallback upwind)
        [ell_F0, ell_I0] = compute_labor_kkt_v10(dV0, z, w_F, w_I_hh, theta, psi_F, psi_I, Frisch, tau, H_bar);

        % -----------------------------------------------------------------
        % HJB — iteracion implicita upwind (Moll 2015 HACT)
        %   B*V_new = u + V_old/Delta,  B = (1/Delta + rho)*I - A
        %   repite hasta max|Vchange| < crit
        % -----------------------------------------------------------------
        t_hjb = tic;
        for n = 1:maxit
            V = v;
            dVf(1:I-1,:) = (V(2:I,:) - V(1:I-1,:))/da;
            dVb(2:I,:)   = (V(2:I,:) - V(1:I-1,:))/da;
            dVf(I,:) = dVf_upper;
            dVb(1,:) = dV_min;

            dVf_pos = max(dVf, 1e-10);
            dVb_pos = max(dVb, 1e-10);

            [cFf, cIf, cf, expf] = ces_consumption_from_dV_v10(dVf_pos, ga);
            [cFb, cIb, cb, expb] = ces_consumption_from_dV_v10(dVb_pos, ga);

            [ell_Ff, ell_If] = compute_labor_kkt_v10(dVf_pos, z, w_F, w_I_hh, theta, psi_F, psi_I, Frisch, tau, H_bar);
            [ell_Fb, ell_Ib] = compute_labor_kkt_v10(dVb_pos, z, w_F, w_I_hh, theta, psi_F, psi_I, Frisch, tau, H_bar);

            zz_I = zz.^nu_I;
            ssf = (1-tau)*w_F*zz.*ell_Ff - kappa_F_aa.*ell_Ff + w_I_hh*theta*zz_I.*qq_informal.*ell_If ...
                + r*aa - debt_spread_aa.*max(-aa,0) + T + Pi_lump - expf;
            ssb = (1-tau)*w_F*zz.*ell_Fb - kappa_F_aa.*ell_Fb + w_I_hh*theta*zz_I.*qq_informal.*ell_Ib ...
                + r*aa - debt_spread_aa.*max(-aa,0) + T + Pi_lump - expb;

            ssb(1,:) = 0;
            ssf(I,:) = 0;

            If = ssf > 0;
            Ib = ssb < 0 & ~If;
            I0 = ~(If | Ib);

            c_F   = cFf.*If    + cFb.*Ib    + cF0.*I0;
            c_I   = cIf.*If    + cIb.*Ib    + cI0.*I0;
            c     = cf.*If     + cb.*Ib     + c0.*I0;
            ell_F = ell_Ff.*If + ell_Fb.*Ib + ell_F0.*I0;
            ell_I = ell_If.*If + ell_Ib.*Ib + ell_I0.*I0;

            u = c.^(1-ga)/(1-ga) ...
                - psi_F*ell_F.^(1+1/Frisch)/(1+1/Frisch) ...
                - psi_I*ell_I.^(1+1/Frisch)/(1+1/Frisch);

            ss_Upwind = ssf.*If + ssb.*Ib;
            X = -min(ss_Upwind,0)/da;
            Y = -max(ss_Upwind,0)/da + min(ss_Upwind,0)/da;
            Z =  max(ss_Upwind,0)/da;

            % Build block-diagonal transition matrix (works for any Ns)
            NsI = Ns * I;
            A_blocks = sparse(NsI, NsI);
            for js = 1:Ns
                A_js = spdiags(Y(:,js),0,I,I) ...
                     + spdiags([X(2:I,js);0],-1,I,I) ...
                     + spdiags([0;Z(1:I-1,js)],1,I,I);
                A_blocks((js-1)*I+1:js*I, (js-1)*I+1:js*I) = A_js;
            end
            A = A_blocks + Aswitch;
            row_sums = full(sum(A, 2));
            row_err = max(abs(row_sums));
            if row_err > 1e-8
                warning('v10:rowSum', ...
                    'A matrix row-sum error = %.2e (>1e-8). Check drift terms ssf/ssb or Aswitch construction.', row_err);
            end
            A = A - spdiags(row_sums, 0, NsI, NsI);

            B = (1/Delta + rho)*speye(NsI) - A;
            u_stacked = reshape(u, NsI, 1);
            V_stacked = reshape(V, NsI, 1);
            b = u_stacked + V_stacked/Delta;
            t_hjb_solve = tic;
            V_stacked = B\b;
            ha_profile_add('hjb_sparse_solve', toc(t_hjb_solve));
            V = reshape(V_stacked, I, Ns);

            Vchange = V - v;
            v = V;
            if max(max(abs(Vchange))) < crit
                break;
            end
        end
        ha_profile_add('hjb_total', toc(t_hjb));
        fprintf('      [HJB] n=%d, Vchange=%.3e\n', n, max(max(abs(Vchange))));

        % -----------------------------------------------------------------
        % KFE (Fokker-Planck) — distribucion estacionaria A'g = 0
        %   Usa la matriz A del HJB convergido. Normaliza: sum(g)*da = 1.
        % -----------------------------------------------------------------
        t_kfe = tic;
        gg = solve_kfe_stationary_v10(A, da, I, Ns);
        g  = reshape(gg, I, Ns);
        ha_profile_add('kfe_total', toc(t_kfe));

        mass_z_min = sum(g(:,1)) * da;
        mass_z_max = sum(g(:,end)) * da;
        mass_amin = sum(g(1,:)) * da;
        g_sum_check = sum(g(:)) * da;
        C_I_current = da * sum(sum(g .* c_I));
        C_F_current = da * sum(sum(g .* c_F));

        L_F = da * sum(sum(g .* zz .* ell_F));
        T_new = tau * w_F * L_F;
        DebtPremPayments_loop = da * sum(sum(g .* debt_spread_aa .* max(-aa,0)));
        if debt_prem_rebate
            T_new = T_new + DebtPremPayments_loop;
        end
        L_I_diag = da * sum(sum(g .* (theta*(zz.^nu_I)) .* qq_informal .* ell_I));
        [K_I_diag, Y_I_diag] = informal_firm_outcomes_v10( ...
            L_I_diag, r, p_I, A_I, alpha_I, beta_I, d, L_I_floor_wI);

        fprintf('  [A diag] row_err=%.3e\n', row_err);
        fprintf('  [drift diag] ssf[min,max]=[%.3e, %.3e], ssb[min,max]=[%.3e, %.3e]\n', ...
            min(ssf(:)), max(ssf(:)), min(ssb(:)), max(ssb(:)));
        fprintf('  [KFE diag] mass_z_edges=[%.6f, %.6f], mass_amin=%.6f, g_sum=%.6f\n', ...
            mass_z_min, mass_z_max, mass_amin, g_sum_check);
        fprintf('  [eq diag] p_I=%.6f, L_I=%.6e, K_I=%.6e, Y_I=%.6e, C_I=%.6e, C_F=%.6e\n', ...
            p_I, L_I_diag, K_I_diag, Y_I_diag, C_I_current, C_F_current);

        if abs(T_new - T) < tol_T
            c0_prev = c0;
            T = T_new;
            break;
        end

        T = (1-damp_T)*T + damp_T*T_new;
        c0_prev = c0;
    end

    L_I = da * sum(sum(g .* (theta*(zz.^nu_I)) .* qq_informal .* ell_I));
    [K_I, Y_I, w_I_new, Pi_I_new] = informal_firm_outcomes_v10( ...
        L_I, r, p_I, A_I, alpha_I, beta_I, d, L_I_floor_wI);

    if abs(w_I_new - w_I) < tol_wI && abs(Pi_I_new - Pi_I_share) < tol_wI
        w_I = w_I_new;
        Pi_I_share = Pi_I_new;
        L_I_prev = L_I;
        break;
    end

    w_I = exp((1-damp_wI_log)*log(max(w_I, 1e-10)) + damp_wI_log*log(max(w_I_new, 1e-10)));
    Pi_I_share = (1-damp_piI)*Pi_I_share + damp_piI*Pi_I_new;
    L_I_prev = L_I;   % actualiza para siguiente iteracion (usado en modo hours)
end

% Retorno informal final percibido por hogares
if strcmp(profit_rule_sgp, 'hours')
    w_I_household = w_I + Pi_I_share / max(L_I_prev, L_I_floor_wI);
else
    w_I_household = w_I;
end

% Diagnostico contable: verifica cierre de la firma informal.
inf_income_bill = da * sum(sum(g .* w_I_household .* theta .* (zz.^nu_I) .* qq_informal .* ell_I));
if strcmp(profit_rule_sgp, 'hours')
    informal_labor_profit_bill = inf_income_bill;
else
    informal_labor_profit_bill = inf_income_bill + Pi_I_share;
end
informal_capital_bill = (r + d) * K_I;
informal_firm_closure = informal_labor_profit_bill + informal_capital_bill;
fprintf('  [profit rule=%s] w_I_marg=%.6f, w_I_hh=%.6f, Pi_I=%.6f, L_I=%.6f\n', ...
    profit_rule_sgp, w_I, w_I_household, Pi_I_share, L_I);
fprintf('  [contabilidad] labor+profit=%.6f, capital_bill=%.6f, cierre_firma_I=%.6f, p_I*Y_I=%.6f, diff=%.2e\n', ...
    informal_labor_profit_bill, informal_capital_bill, informal_firm_closure, p_I*Y_I, abs(informal_firm_closure - p_I*Y_I));

C_I_agg_out = da * sum(sum(g .* c_I));
C_F_agg_out = da * sum(sum(g .* c_F));
S = da * sum(sum(g .* repmat(a, 1, Ns)));
KD = k_ratio * L_F + K_I;
T_out = T;
w_I_out = w_I;
Pi_I_share_out = Pi_I_share;
Y_I_out = Y_I;
v0_out = V;
ha_profile_add('solve_given_prices', toc(t_sgp));
end


% =========================================================================
% LOCAL FUNCTION: informal_firm_outcomes_v10
%   Informal firm static block. alpha_I=0 is the exact legacy technology.
% =========================================================================
function [K_I, Y_I, w_I_marg, Pi_I, omega_I] = informal_firm_outcomes_v10( ...
    L_I, r, p_I, A_I, alpha_I, beta_I, d, L_I_floor)

L_prod = max(L_I, 0);
L_eff = max(L_prod, L_I_floor);

if alpha_I == 0
    K_I = 0;
    Y_I = A_I * L_prod^beta_I;
    omega_I = p_I * A_I * L_eff^(beta_I - 1);
    w_I_marg = beta_I * omega_I;
    Pi_I = (1 - beta_I) * p_I * Y_I;
    return;
end

user_cost = r + d;
if user_cost <= 0
    error('Informal capital requires r + d > 0. Got r+d=%.6g.', user_cost);
end

K_I = (p_I * alpha_I * A_I * L_eff^beta_I / user_cost)^(1 / (1 - alpha_I));
Y_I = A_I * K_I^alpha_I * L_prod^beta_I;
omega_I = p_I * A_I * K_I^alpha_I * L_eff^(beta_I - 1);
w_I_marg = beta_I * omega_I;
Pi_I = (1 - alpha_I - beta_I) * p_I * Y_I;
end


% =========================================================================
% LOCAL FUNCTION: solve_kfe_stationary_v10
%   Robust stationary-distribution solver for A' g = 0 with mass 1.
% =========================================================================

% -------------------------------------------------------------------------
% solve_kfe_stationary_v10 — KFE (Fokker-Planck): distribucion estacionaria
% -------------------------------------------------------------------------
% Resuelve A'*g = 0 sujeto a sum(g)*da = 1 (masa total = 1).
% Entradas: A (matriz de transicion sparse NsI x NsI del HJB convergido),
%   da (paso del grid), I (puntos de riqueza), Ns (numero de tipos z o z*q).
% Salida: gg (vector columna NsI x 1) — reshape a (I x Ns) para obtener g(a,z).
% Metodo: sustituye fila 1 de A' por condicion de normalizacion; resuelve sistema lineal.
function gg = solve_kfe_stationary_v10(A, da, I, Ns)

if nargin < 4, Ns = 2; end   % backward compatible
N_total = Ns * I;

AT = A';
b_kfe = zeros(N_total,1);
b_kfe(1) = 1;
AT_fix = AT;
AT_fix(1,:) = 0;
AT_fix(1,1) = 1;

gg = [];
warn_state = warning('off', 'MATLAB:singularMatrix');
warn_state2 = warning('off', 'MATLAB:nearlySingularMatrix');
cleanup = onCleanup(@() warning(warn_state));
cleanup2 = onCleanup(@() warning(warn_state2));

try
    gg_try = AT_fix\b_kfe;
    g_sum_try = sum(gg_try) * da;
    if all(isfinite(gg_try)) && isfinite(g_sum_try) && g_sum_try > 0
        gg = gg_try / g_sum_try;
    end
catch
end

if isempty(gg) || any(~isfinite(gg))
    A_aug = [AT; da * ones(1, N_total)];
    b_aug = [zeros(N_total,1); 1];
    try
        gg = lsqminnorm(A_aug, b_aug);
    catch
        gg = pinv(full(A_aug)) * b_aug;
    end
end

gg = max(real(gg), 0);
g_sum = sum(gg) * da;
if ~isfinite(g_sum) || g_sum <= 0
    gg = ones(N_total,1) / (N_total*da);
else
    gg = gg / g_sum;
end

end


% =========================================================================
% LOCAL FUNCTION: compute_labor_kkt_v10
% =========================================================================

% -------------------------------------------------------------------------
% compute_labor_kkt_v10 — KKT LABOR: horas optimas (ell_F, ell_I)
% -------------------------------------------------------------------------
% Entradas: dV (I x Ns, derivada V' del HJB), z (1 x Ns tipos),
%   w_F, w_I, theta (precios y atenuacion informal), psi_F/psi_I (desutilidad),
%   Frisch (elasticidad), tau (impuesto formal), H_bar (dotacion tiempo).
%   nu_I global: elasticidad de productividad individual en informal.
%   Usa globals: kappa_F_aa (I x Ns, costo acceso formal), qq_informal (I x Ns, multiplicador q).
% Salidas: ell_F, ell_I (I x Ns cada una).
% Logica: FOC libre → ell_F_unc = (dV*w_F_neto/psi_F)^Frisch, igual para ell_I.
%   Si ell_F_unc + ell_I_unc <= H_bar: interior, usa FOCs directamente.
%   Si binde: biseccion en ell_F dentro de [0, H_bar] con ell_I = H_bar - ell_F.
function [ell_F, ell_I] = compute_labor_kkt_v10(dV, z, w_F, w_I, theta, psi_F, psi_I, Frisch, tau, H_bar)

global kappa_F_aa qq_informal nu_I
I  = size(dV, 1);
Ns = size(dV, 2);
zz = ones(I,1) * z;

% effective formal wage net of access cost: (1-tau)*w_F*z - kappa_F(a)
eff_wF_zz = (1-tau)*w_F*zz - kappa_F_aa;

% informal wage: w_I*theta*z^nu_I*q  (qq_informal=1 when USE_Q=0)
wI_inf_zz = w_I * theta * (zz.^nu_I) .* qq_informal;

ell_F_unc = max(dV .* eff_wF_zz / psi_F, 0).^Frisch;
ell_I_unc = max(dV .* wI_inf_zz  / psi_I, 0).^Frisch;

ell_F = ell_F_unc;
ell_I = ell_I_unc;

if ~isfinite(H_bar)
    return;
end

binding = (ell_F_unc + ell_I_unc) > H_bar;
if ~any(binding(:))
    return;
end

g_lo = -psi_I * H_bar^(1/Frisch);
g_hi =  psi_F * H_bar^(1/Frisch);

for j = 1:Ns
    bind_j = binding(:,j);
    if ~any(bind_j), continue; end

    RHS_b = dV(bind_j, j) .* (eff_wF_zz(bind_j,j) - wI_inf_zz(bind_j,j));
    lF_sol = zeros(sum(bind_j), 1);
    lF_sol(RHS_b >= g_hi) = H_bar;

    interior = (RHS_b > g_lo) & (RHS_b < g_hi);
    if any(interior)
        RHS_int = RHS_b(interior);
        lo = zeros(sum(interior), 1);
        hi = H_bar * ones(sum(interior), 1);
        for kb = 1:60
            mid = 0.5 * (lo + hi);
            fm = psi_F*mid.^(1/Frisch) - psi_I*(H_bar-mid).^(1/Frisch) - RHS_int;
            lo(fm < 0) = mid(fm < 0);
            hi(fm >= 0) = mid(fm >= 0);
        end
        lF_sol(interior) = 0.5 * (lo + hi);
    end

    ell_F(bind_j, j) = lF_sol;
    ell_I(bind_j, j) = H_bar - lF_sol;
end
end


% =========================================================================
% LOCAL FUNCTION: ces_consumption_from_dV_v10
% =========================================================================

% -------------------------------------------------------------------------
% ces_consumption_from_dV_v10 — CONSUMO CES OPTIMO desde V'
% -------------------------------------------------------------------------
% Entradas: dV (I x Ns, derivada V'), ga (CRRA coeficiente γ).
%   Globals: p_I (precio bien informal), omega_C (peso CES), eta_C, sigma_C.
% Salidas: cF (consumo formal I x Ns), cI (consumo informal I x Ns),
%   Ceff (agregado CES = Kappa*cI), exp_cons (gasto = cF + p_I*cI).
% Derivacion: u'(Ceff) = M/Ceff^ga = dV → Ceff = (M/dV)^(1/ga).
%   xi = (omega_C*p_I/(1-omega_C))^sigma_C  (ratio demanda optimo cF/cI)
%   Kappa = (omega_C*xi^eta_C + (1-omega_C))^(1/eta_C)  (deflactor CES)
function [cF, cI, Ceff, exp_cons] = ces_consumption_from_dV_v10(dV, ga)
global p_I omega_C eta_C sigma_C

dV = max(real(dV), 1e-12);

xi = (omega_C*p_I / max(1-omega_C, 1e-12)).^sigma_C;
Kappa = (omega_C*xi.^eta_C + (1-omega_C)).^(1/eta_C);
M = omega_C * xi.^(eta_C-1) * Kappa.^(1-eta_C);

Ceff = (M ./ dV).^(1/ga);
cI = Ceff ./ Kappa;
cF = xi .* cI;
exp_cons = cF + p_I .* cI;

if abs(eta_C) > 1e-10
    A_F = omega_C.^(1/eta_C);
    A_Ionly = max(1-omega_C, 1e-12).^(1/eta_C);

    cF_only = (A_F.^(1-ga) ./ dV).^(1/ga);
    C_Fonly = A_F .* cF_only;
    exp_Fonly = cF_only;

    cI_only = (A_Ionly.^(1-ga) ./ max(dV * p_I, 1e-12)).^(1/ga);
    C_Ionly = A_Ionly .* cI_only;
    exp_Ionly = p_I .* cI_only;

    obj_int = Ceff.^(1-ga)/(1-ga) - dV .* exp_cons;
    obj_Fonly = C_Fonly.^(1-ga)/(1-ga) - dV .* exp_Fonly;
    obj_Ionly = C_Ionly.^(1-ga)/(1-ga) - dV .* exp_Ionly;

    use_F = obj_Fonly > obj_int & obj_Fonly >= obj_Ionly;
    use_I = obj_Ionly > obj_int & obj_Ionly > obj_Fonly;

    cF(use_F) = cF_only(use_F);
    cI(use_F) = 0;
    Ceff(use_F) = C_Fonly(use_F);
    exp_cons(use_F) = exp_Fonly(use_F);

    cF(use_I) = 0;
    cI(use_I) = cI_only(use_I);
    Ceff(use_I) = C_Ionly(use_I);
    exp_cons(use_I) = exp_Ionly(use_I);
end

cF = max(real(cF), 0);
cI = max(real(cI), 0);
Ceff = max(real(Ceff), 1e-12);
exp_cons = max(real(exp_cons), 1e-12);
end


% =========================================================================
% LOCAL FUNCTION: lab_solve_v10_dV
% =========================================================================

% -------------------------------------------------------------------------
% lab_solve_v10_dV — RESIDUO ZERO-DRIFT (escalar, para fzero)
% -------------------------------------------------------------------------
% Entradas: dV (escalar, candidato derivada V'), params (vector 17 elementos):
%   [a_i, z_j, w_F, w_I, theta, r, ga, Frisch, psi_F, psi_I, tau, T,
%    Pi_I_share, H_bar, kappa_F(a_i), q_s, spread_b(z_j)]
% Salida: residuo = adot(dV) = ingreso - gasto_total evaluado con labor KKT.
%   adot = ingreso laboral + r*a - spread_b*max(-a,0) + T + Pi_I - exp_cons
% fzero encuentra dV* tal que adot=0 (condicion de borde para upwind scheme).
function residuo = lab_solve_v10_dV(dV, params)
global nu_I
dV = max(real(dV), 1e-12);

a_i   = params(1);
z_j   = params(2);
w_F   = params(3);
w_I   = params(4);
theta = params(5);
r     = params(6);
ga    = params(7);
Frisch = params(8);
psi_F = params(9);
psi_I = params(10);
tau   = params(11);
T     = params(12);
Pi_I_share = params(13);
H_bar      = params(14);
kappa_F_ai = params(15);   % kappa_F(a_i)
q_s        = params(16);   % multiplicador informal del tipo (q=1 si USE_Q=0)
spread_b_j = 0;
if numel(params) >= 17
    spread_b_j = params(17);
end

eff_wF_j   = (1-tau)*w_F*z_j - kappa_F_ai;
wI_inf_j   = w_I * theta * (z_j^nu_I) * q_s;       % salario informal efectivo del tipo

ell_F_unc = max(dV * eff_wF_j  / psi_F, 0)^Frisch;
ell_I_unc = max(dV * wI_inf_j  / psi_I, 0)^Frisch;

if ~isfinite(H_bar) || (ell_F_unc + ell_I_unc <= H_bar)
    ell_F = ell_F_unc;
    ell_I = ell_I_unc;
else
    RHS = dV * (eff_wF_j - wI_inf_j);
    g_lo = -psi_I * H_bar^(1/Frisch);
    g_hi = psi_F * H_bar^(1/Frisch);

    if RHS <= g_lo
        ell_F = 0;
        ell_I = H_bar;
    elseif RHS >= g_hi
        ell_F = H_bar;
        ell_I = 0;
    else
        lo = 0;
        hi = H_bar;
        for kb = 1:60
            mid = 0.5 * (lo + hi);
            fm = psi_F*mid^(1/Frisch) - psi_I*(H_bar-mid)^(1/Frisch) - RHS;
            if fm < 0, lo = mid; else, hi = mid; end
        end
        ell_F = 0.5 * (lo + hi);
        ell_I = H_bar - ell_F;
    end
end

[~, ~, ~, exp_cons] = ces_consumption_from_dV_v10(dV, ga);
residuo = eff_wF_j*ell_F + wI_inf_j*ell_I + r*a_i ...
    - spread_b_j*max(-a_i,0) + T + Pi_I_share - exp_cons;
end


% =========================================================================
% LOCAL FUNCTION: solve_dV_zero_drift_v10
% =========================================================================

% -------------------------------------------------------------------------
% solve_dV_zero_drift_v10 — CONDICION DE BORDE HJB
% -------------------------------------------------------------------------
% Entradas: params (vector 17 elementos, mismo formato que lab_solve_v10_dV),
%   dV_guess (escalar, punto de partida para la busqueda).
% Salida: dV_sol (escalar) — el dV* que satisface adot=0 en el borde.
% Metodo: evalua lab_solve_v10_dV en un grid logaritmico de dV para
%   encontrar bracket de signo, luego fzero refina hasta precision ~1e-10.
%   Llamada UNA vez por tipo j antes de entrar al loop HJB (linea boundary precompute).
function dV_sol = solve_dV_zero_drift_v10(params, dV_guess)
dV_floor = 1e-12;
if isempty(dV_guess) || ~isscalar(dV_guess) || ~isfinite(dV_guess)
    dV_guess = dV_floor;
else
    dV_guess = max(real(dV_guess), dV_floor);
end

f = @(x) lab_solve_v10_dV(x, params);
x0 = log(dV_guess);
% Grid size: 25 pts en debug (FAST_DEBUG usa I pequeno), 80 en produccion
% Rango estrecho si dV_guess es confiable (iteraciones subsiguientes de T)
persistent zdrift_npts zdrift_range
if isempty(zdrift_npts)
    env_npts = str2double(getenv('HA_IE_ZDRIFT_NPTS'));
    zdrift_npts  = 80;   % produccion
    zdrift_range = 18;
    if isfinite(env_npts) && env_npts >= 10
        zdrift_npts  = round(env_npts);
        zdrift_range = 12;
    end
end
grid_x = linspace(x0 - zdrift_range, x0 + zdrift_range, zdrift_npts);
vals = arrayfun(@(x) f(exp(x)), grid_x);

finite = isfinite(vals);
grid_x = grid_x(finite);
vals = vals(finite);

if isempty(vals)
    dV_sol = dV_guess;
    return;
end

[~, idx_best] = min(abs(vals));
x_best = grid_x(idx_best);

for k = 1:(numel(vals)-1)
    if vals(k) == 0
        dV_sol = exp(grid_x(k));
        return;
    end
    if vals(k) * vals(k+1) < 0
        try
            x_root = fzero(@(x) f(exp(x)), [grid_x(k), grid_x(k+1)]);
            dV_sol = max(exp(x_root), dV_floor);
            return;
        catch
        end
    end
end

try
    x_min = fminbnd(@(x) abs(f(exp(x))), max(min(grid_x), x_best-4), min(max(grid_x), x_best+4), ...
        optimset('Display','off','TolX',1e-8));
    dV_sol = max(exp(x_min), dV_floor);
catch
    dV_sol = max(exp(x_best), dV_floor);
end
end


% =========================================================================
% LOCAL FUNCTION: ces_split_from_Ceff_v10
%   Recovers c_F, c_I, and expenditure from stored C_eff policies.
% =========================================================================
% -------------------------------------------------------------------------
% ces_split_from_Ceff_v10 — SPLIT CES POST-HOC (solo para plots)
% -------------------------------------------------------------------------
% Entrada: Ceff (I x Ns, agregado CES guardado en results_v10_latest.mat).
%   Globals: p_I, omega_C, eta_C, sigma_C (cargados desde el .mat por plot_ou_process_distributions).
% Salidas: cF (consumo formal), cI (consumo informal), exp_cons = cF + p_I*cI.
% NO afecta en el solver; se llama solo desde los scripts de graficos.
function [cF, cI, exp_cons] = ces_split_from_Ceff_v10(Ceff)
global p_I omega_C eta_C sigma_C

Ceff = max(real(Ceff), 1e-12);
xi = (omega_C*p_I / max(1-omega_C, 1e-12)).^sigma_C;
Kappa = (omega_C*xi.^eta_C + (1-omega_C)).^(1/eta_C);
cI = Ceff ./ Kappa;
cF = xi .* cI;
exp_cons = cF + p_I .* cI;
end

% =========================================================================
% LOCAL FUNCTION: ha_collect_env
% =========================================================================
function env = ha_collect_env()
keys = { ...
    'HA_IE_RUN_TAG', 'HA_IE_OUTPUT_DIR', 'HA_IE_FAST_DEBUG', ...
    'HA_IE_VERBOSE', 'HA_IE_PROFILE', 'HA_IE_EQ_MODE', ...
    'HA_IE_DEBUG_I', 'HA_IE_I', 'HA_IE_AMIN', 'HA_IE_AMAX', ...
    'HA_IE_R_LO', 'HA_IE_R_HI', 'HA_IE_TOL_R', 'HA_IE_MAX_BISECT_R', ...
    'HA_IE_MAX_ITER_T', 'HA_IE_MAX_ITER_WI', 'HA_IE_MAX_ITER_PI', ...
    'HA_IE_TOL_T', 'HA_IE_TOL_WI', 'HA_IE_TOL_PI', 'HA_IE_PI_GRID', ...
    'HA_IE_Z_PROCESS', 'HA_IE_Z_N', 'HA_IE_Z_RHO', 'HA_IE_Z_SD', ...
    'HA_IE_Z_WIDTH', 'HA_IE_Z_MU', 'HA_IE_Z_DT', ...
    'HA_IE_ZDRIFT_METHOD', 'HA_IE_ZDRIFT_NPTS', 'HA_IE_ZDRIFT_REUSE', ...
    'HA_IE_ZDRIFT_FAST_ITERS', 'HA_IE_ZDRIFT_FAST_TOL', 'HA_IE_ZDRIFT_FAST_MAXSTEP', ...
    'HA_IE_A_F', 'HA_IE_A_I', 'HA_IE_ALPHA_I', 'HA_IE_BETA_I', ...
    'HA_IE_THETA', 'HA_IE_NU_I', 'HA_IE_PSI_F', 'HA_IE_PSI_I', ...
    'HA_IE_OMEGA_C', 'HA_IE_SIGMA_C', ...
    'HA_IE_KAPPA_Z1', 'HA_IE_KAPPA_Z_SHAPE', ...
    'HA_IE_T4_DATA', 'HA_IE_T5_DATA', 'HA_IE_TKZ_DATA', 'HA_IE_TGASTO_TIPO_DATA', ...
    'HA_IE_T6_DATA', 'HA_IE_T6_Q1_DATA', 'HA_IE_T6_Q5_DATA', ...
    'HA_IE_DEBT_PREM_CHI', 'HA_IE_DEBT_PREM_ETA', 'HA_IE_DEBT_PREM_REBATE', ...
    'HA_IE_INFORMAL_PROFIT_RULE'};

env = struct();
for k = 1:numel(keys)
    field = matlab.lang.makeValidName(keys{k});
    env.(field) = getenv(keys{k});
end
end

% =========================================================================
% LOCAL FUNCTION: ha_write_run_metadata
% =========================================================================
function ha_write_run_metadata(metadata_file, run_config, calib)
try
    fid = fopen(metadata_file, 'w');
    if fid < 0
        warning('Could not open run metadata file: %s', metadata_file);
        return;
    end
    cleanup = onCleanup(@() fclose(fid));

    fprintf(fid, 'HA-IE v10 ARz OU debt-premium run metadata\n');
    fprintf(fid, 'created_at=%s\n', ha_meta_str(run_config.created_at));
    fprintf(fid, 'script=%s\n', ha_meta_str(run_config.script));
    fprintf(fid, 'script_file=%s\n', ha_meta_str(run_config.script_file));
    fprintf(fid, 'run_tag=%s\n', ha_meta_str(run_config.run_tag));
    fprintf(fid, 'safe_run_tag=%s\n', ha_meta_str(run_config.safe_run_tag));
    fprintf(fid, 'output_dir=%s\n', ha_meta_str(run_config.output_dir));
    fprintf(fid, 'results_file=%s\n', ha_meta_str(run_config.results_file));
    fprintf(fid, 'calib_file=%s\n', ha_meta_str(run_config.calib_file));
    fprintf(fid, 'metadata_file=%s\n', ha_meta_str(run_config.metadata_file));
    fprintf(fid, 'mode=%s\n', ha_meta_str(run_config.mode));
    fprintf(fid, 'fast_debug=%s\n', ha_meta_str(run_config.fast_debug));
    fprintf(fid, 'verbose=%s\n', ha_meta_str(run_config.verbose));
    fprintf(fid, 'profile_enabled=%s\n', ha_meta_str(run_config.profile_enabled));
    fprintf(fid, 'total_elapsed=%.6f\n', run_config.total_elapsed);
    fprintf(fid, 'zdrift_method=%s\n', ha_meta_str(run_config.zdrift_method));
    fprintf(fid, 'zdrift_reuse=%s\n', ha_meta_str(run_config.zdrift_reuse));
    fprintf(fid, 'zdrift_npts=%s\n', ha_meta_str(run_config.zdrift_npts));

    fprintf(fid, '\n[sources]\n');
    source_fields = fieldnames(run_config.sources);
    for k = 1:numel(source_fields)
        fprintf(fid, '%s=%s\n', source_fields{k}, ha_meta_str(run_config.sources.(source_fields{k})));
    end

    fprintf(fid, '\n[core]\n');
    core_fields = fieldnames(run_config.core);
    for k = 1:numel(core_fields)
        fprintf(fid, '%s=%s\n', core_fields{k}, ha_meta_str(run_config.core.(core_fields{k})));
    end

    if nargin >= 3 && isstruct(calib)
        fprintf(fid, '\n[moments]\n');
        moment_fields = {'r_star', 'K_star', 'p_I', 'T4_ratio', 'T5_nom', ...
            'T_kappa_z_model', 'T_kappa_z_data', 'form_rate_z1', 'form_rate_z2', ...
            'Tgasto_tipo', 'Tgasto_tipo_data', 'TgFI_canasta', 'TgFI_canasta_data', ...
            'TgFI_composicion', 'ratio_gasto_FI', 'TgFI_data', 'T6_model', 'DebtPremPayments', ...
            'avg_debt_spread_paid', 'mass_debt', 'mass_amin', 'T1_wage_net', ...
            'T1_wage_gross', 'ptf_gap'};
        for k = 1:numel(moment_fields)
            if isfield(calib, moment_fields{k})
                fprintf(fid, '%s=%s\n', moment_fields{k}, ha_meta_str(calib.(moment_fields{k})));
            end
        end
    end

    fprintf(fid, '\n[env]\n');
    env_fields = fieldnames(run_config.env);
    for k = 1:numel(env_fields)
        fprintf(fid, '%s=%s\n', env_fields{k}, ha_meta_str(run_config.env.(env_fields{k})));
    end

    if isfield(run_config, 'profile') && isstruct(run_config.profile)
        fprintf(fid, '\n[profile]\n');
        prof_fields = fieldnames(run_config.profile);
        for k = 1:numel(prof_fields)
            rec = run_config.profile.(prof_fields{k});
            if isfield(rec, 'time')
                fprintf(fid, '%s.total_seconds=%.6f\n', prof_fields{k}, rec.time);
                fprintf(fid, '%s.count=%d\n', prof_fields{k}, rec.count);
            elseif isfield(rec, 'value')
                fprintf(fid, '%s.value=%.12g\n', prof_fields{k}, rec.value);
                fprintf(fid, '%s.count=%d\n', prof_fields{k}, rec.count);
            elseif isfield(rec, 'count')
                fprintf(fid, '%s.count=%d\n', prof_fields{k}, rec.count);
            end
        end
    end
catch ME
    warning('Could not write run metadata file: %s', ME.message);
end
end

% =========================================================================
% LOCAL FUNCTION: ha_meta_str
% =========================================================================
function s = ha_meta_str(x)
if ischar(x)
    s = x;
elseif isstring(x)
    s = char(x);
elseif islogical(x)
    if isscalar(x)
        if x
            s = 'true';
        else
            s = 'false';
        end
    else
        s = mat2str(x);
    end
elseif isnumeric(x)
    if isscalar(x)
        s = sprintf('%.12g', x);
    else
        s = mat2str(x, 12);
    end
else
    s = '<unsupported>';
end
end

function [x, P] = rouwenhorst_ar1_grid(N, rho_z, sd_uncond, width_mult, mu_uncond)
% Discretize a stationary AR(1) for log productivity.
% x is a row vector of log-z nodes; P is a row-stochastic annual transition.
if nargin < 5 || ~isfinite(mu_uncond)
    mu_uncond = 0;
end
if N < 2
    error('rouwenhorst_ar1_grid requires N >= 2');
end
p = (1 + rho_z) / 2;
q = p;
P = [p, 1-p; 1-q, q];
for n = 3:N
    P_old = P;
    P = zeros(n, n);
    P(1:n-1, 1:n-1) = P(1:n-1, 1:n-1) + p * P_old;
    P(1:n-1, 2:n)   = P(1:n-1, 2:n)   + (1-p) * P_old;
    P(2:n, 1:n-1)   = P(2:n, 1:n-1)   + (1-q) * P_old;
    P(2:n, 2:n)     = P(2:n, 2:n)     + q * P_old;
    P(2:n-1, :) = P(2:n-1, :) / 2;
end
P = P ./ sum(P, 2);
xmax = width_mult * sd_uncond;
x = linspace(mu_uncond - xmax, mu_uncond + xmax, N);
end

function [x, Q, pi, diag_info] = ou_ar1_generator_grid(N, rho_z, sd_uncond, width_mult, mu_uncond, dt)
% Continuous-time counterpart of a stationary AR(1) for log productivity.
%
% x follows an OU process:
%   dx = eta*(mu - x) dt + sqrt(2*eta)*sd_uncond dW
% so the stationary distribution is approximately N(mu, sd_uncond^2) and
% exp(-eta*dt)=rho_z. The generator is discretized using Moll/Achdou-style
% upwinding for the drift and central differences for diffusion. Q is
% tridiagonal sparse, giving O(N) storage and transition operations.
if N < 2
    error('ou_ar1_generator_grid requires N >= 2');
end
if nargin < 6 || ~isfinite(dt) || dt <= 0
    dt = 1;
end
if nargin < 5 || ~isfinite(mu_uncond)
    mu_uncond = 0;
end
if rho_z <= 0 || rho_z >= 1
    error('rho_z must be in (0,1) for OU mapping eta=-log(rho_z)/dt.');
end

eta = -log(rho_z) / dt;
xmax = width_mult * sd_uncond;
x = linspace(mu_uncond - xmax, mu_uncond + xmax, N);
dx = x(2) - x(1);
dx2 = dx^2;

mu = eta * (mu_uncond - x);
variance_coeff = 2 * eta * sd_uncond^2;
diff_half = variance_coeff / (2 * dx2);

% Same band formulas as the Moll diffusion code:
% chi lower, yy center, zeta upper. At boundaries the missing outward band
% is folded into the center diagonal, imposing reflecting/no-outflow edges.
chi = -min(mu, 0) / dx + diff_half;
yy = min(mu, 0) / dx - max(mu, 0) / dx - 2 * diff_half;
zeta = max(mu, 0) / dx + diff_half;

lower = zeros(N, 1);
center = yy(:);
upper = zeros(N, 1);

if N > 1
    % spdiags stores offset -1 at rows 2:N using lower(1:N-1), and
    % offset +1 at rows 1:N-1 using upper(2:N).
    lower(1:N-1) = chi(2:N);
    upper(2:N) = zeta(1:N-1);
end
center(1) = center(1) + chi(1);
center(N) = center(N) + zeta(N);

Q = spdiags([lower, center, upper], [-1, 0, 1], N, N);

row_sums = full(sum(Q, 2));
if max(abs(row_sums)) > 1e-10
    Q = Q - spdiags(row_sums, 0, N, N);
end

pi = stationary_dist_generator(Q);
diag_info = struct('eta', eta, 'dx', dx, ...
    'variance_coeff', variance_coeff, 'diffusion_term', variance_coeff/2, ...
    'max_abs_row_sum', max(abs(full(sum(Q, 2)))), ...
    'nnz_Q', nnz(Q), 'density_Q', nnz(Q)/numel(Q), ...
    'min_offdiag', min(nonzeros(Q - spdiags(diag(Q), 0, N, N))));
end

function pi = stationary_dist_markov(P)
% Stationary row distribution for a row-stochastic transition matrix.
N = size(P, 1);
A = [P' - eye(N); ones(1, N)];
b = [zeros(N, 1); 1];
pi_col = A \ b;
pi_col = max(real(pi_col), 0);
pi = (pi_col / max(sum(pi_col), 1e-12))';
end

function pi = stationary_dist_generator(Q)
% Stationary row distribution for a continuous-time generator Q.
N = size(Q, 1);
A = [Q'; ones(1, N)];
b = [zeros(N, 1); 1];
pi_col = A \ b;
pi_col = max(real(pi_col), 0);
pi = (pi_col / max(sum(pi_col), 1e-12))';
end

% =========================================================================
% LOCAL FUNCTION: ha_profile_add
% =========================================================================
function ha_profile_add(label, elapsed)
global HA_IE_PROFILE HA_IE_TIMINGS
if isempty(HA_IE_PROFILE) || ~HA_IE_PROFILE || ~isfinite(elapsed)
    return;
end
field = matlab.lang.makeValidName(label);
if isempty(HA_IE_TIMINGS) || ~isstruct(HA_IE_TIMINGS)
    HA_IE_TIMINGS = struct();
end
if ~isfield(HA_IE_TIMINGS, field)
    HA_IE_TIMINGS.(field) = struct('kind', 'time', 'time', 0, 'count', 0);
end
HA_IE_TIMINGS.(field).time = HA_IE_TIMINGS.(field).time + elapsed;
HA_IE_TIMINGS.(field).count = HA_IE_TIMINGS.(field).count + 1;
end

% =========================================================================
% LOCAL FUNCTION: ha_profile_add_count
% =========================================================================
function ha_profile_add_count(label)
global HA_IE_PROFILE HA_IE_TIMINGS
if isempty(HA_IE_PROFILE) || ~HA_IE_PROFILE
    return;
end
field = matlab.lang.makeValidName(label);
if isempty(HA_IE_TIMINGS) || ~isstruct(HA_IE_TIMINGS)
    HA_IE_TIMINGS = struct();
end
if ~isfield(HA_IE_TIMINGS, field)
    HA_IE_TIMINGS.(field) = struct('kind', 'count', 'count', 0);
end
HA_IE_TIMINGS.(field).count = HA_IE_TIMINGS.(field).count + 1;
end

% =========================================================================
% LOCAL FUNCTION: ha_profile_add_value
% =========================================================================
function ha_profile_add_value(label, value)
global HA_IE_PROFILE HA_IE_TIMINGS
if isempty(HA_IE_PROFILE) || ~HA_IE_PROFILE || ~isfinite(value)
    return;
end
field = matlab.lang.makeValidName(label);
if isempty(HA_IE_TIMINGS) || ~isstruct(HA_IE_TIMINGS)
    HA_IE_TIMINGS = struct();
end
if ~isfield(HA_IE_TIMINGS, field)
    HA_IE_TIMINGS.(field) = struct('kind', 'value', 'value', 0, 'count', 0);
end
HA_IE_TIMINGS.(field).value = HA_IE_TIMINGS.(field).value + value;
HA_IE_TIMINGS.(field).count = HA_IE_TIMINGS.(field).count + 1;
end

% =========================================================================
% LOCAL FUNCTION: ha_profile_add_max
% =========================================================================
function ha_profile_add_max(label, value)
global HA_IE_PROFILE HA_IE_TIMINGS
if isempty(HA_IE_PROFILE) || ~HA_IE_PROFILE || ~isfinite(value)
    return;
end
field = matlab.lang.makeValidName(label);
if isempty(HA_IE_TIMINGS) || ~isstruct(HA_IE_TIMINGS)
    HA_IE_TIMINGS = struct();
end
if ~isfield(HA_IE_TIMINGS, field)
    HA_IE_TIMINGS.(field) = struct('kind', 'max', 'value', -Inf, 'count', 0);
end
HA_IE_TIMINGS.(field).value = max(HA_IE_TIMINGS.(field).value, value);
HA_IE_TIMINGS.(field).count = HA_IE_TIMINGS.(field).count + 1;
end

% =========================================================================
% LOCAL FUNCTION: ha_profile_print
% =========================================================================
function ha_profile_print(total_elapsed)
global HA_IE_PROFILE HA_IE_TIMINGS
if isempty(HA_IE_PROFILE) || ~HA_IE_PROFILE
    fprintf('Elapsed time is %.3f seconds.\n', total_elapsed);
    return;
end
fprintf('\n========================================\n');
fprintf('LIGHTWEIGHT PROFILE SUMMARY\n');
fprintf('========================================\n');
fprintf('Total elapsed: %.3f seconds\n', total_elapsed);
if isempty(HA_IE_TIMINGS) || ~isstruct(HA_IE_TIMINGS)
    fprintf('No profiled blocks recorded.\n');
    return;
end
fields = fieldnames(HA_IE_TIMINGS);
times = zeros(numel(fields), 1);
for k = 1:numel(fields)
    rec = HA_IE_TIMINGS.(fields{k});
    if isfield(rec, 'time')
        times(k) = rec.time;
    else
        times(k) = -1;
    end
end
[~, order] = sort(times, 'descend');
for kk = 1:numel(order)
    k = order(kk);
    rec = HA_IE_TIMINGS.(fields{k});
    kind = 'time';
    if isfield(rec, 'kind'), kind = rec.kind; end
    switch kind
        case 'time'
            fprintf('%-28s total=%9.3f s  count=%6d  mean=%9.4f s\n', ...
                fields{k}, rec.time, rec.count, rec.time/max(rec.count,1));
        case 'count'
            fprintf('%-28s count=%6d\n', fields{k}, rec.count);
        case 'value'
            fprintf('%-28s total=%9.3f  count=%6d  mean=%9.4f\n', ...
                fields{k}, rec.value, rec.count, rec.value/max(rec.count,1));
        case 'max'
            fprintf('%-28s max=%9.3e  count=%6d\n', fields{k}, rec.value, rec.count);
    end
end
fprintf('========================================\n\n');
end
