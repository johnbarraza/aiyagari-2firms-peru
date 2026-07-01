% setup_calibration.m — Defaults para model_main (replication package)
%
% Llamado automáticamente por model_main si corres standalone.
% Para OVERRIDE de cualquier parámetro: setenv() ANTES de llamar model_main.
%
% Escenario activo: DRS Göbel + Hong (2022) z-process
% Último run: hong_nz14_DRS_om055 (p_I=1.14 ✗ — calibración en progreso)

%% MODO
setenv('HA_IE_EQ_MODE',          '2');        % 2 = equilibrio general
setenv('HA_IE_FAST_DEBUG',       'true');     % true = ~16 min (Nz=14). false = ~4h (I=500)
setenv('HA_IE_RUN_TAG',          'v10_drs_gobel');
setenv('HA_IE_VERBOSE',          '1');
setenv('HA_IE_PROFILE',          'false');

%% GRILLA
setenv('HA_IE_I',                '200');      % puntos riqueza (fast debug). Full: 500
setenv('HA_IE_AMIN',             '-1');
setenv('HA_IE_AMAX',             '20');

%% PREFERENCIAS
setenv('HA_IE_PSI_F',            '180');      % desutilidad formal
setenv('HA_IE_PSI_I',            '50');       % desutilidad informal
setenv('HA_IE_THETA',            '1.0');
setenv('HA_IE_NU_I',             '0.40');     % exponente z informal (ventaja comparativa)

%% CONSUMO CES
setenv('HA_IE_SIGMA_C',          '5.0');      % elasticidad sustitución F/I
setenv('HA_IE_OMEGA_C',          '0.60');     % peso bien formal (0.55→p_I>1; 0.65→T5 bajo)

%% FIRMA FORMAL
setenv('HA_IE_A_F',              '1.0');

%% FIRMA INFORMAL (DRS Göbel et al. 2013 — NO TOCAR alpha_I/beta_I)
setenv('HA_IE_A_I',              '0.99');
setenv('HA_IE_ALPHA_I',          '0.118');    % capital share informal
setenv('HA_IE_BETA_I',           '0.605');    % retornos escala labor (Göbel 2013)

%% PROCESO z — Hong (2022, JIE) — NO TOCAR
setenv('HA_IE_Z_PROCESS',        'ou');
setenv('HA_IE_Z_N',              '40');       % Nz=40 final; Nz=7/14/24/30 solo para tradeoff velocidad-precision
setenv('HA_IE_Z_RHO',            '0.8600132622');  % 0.963^4 (trimestral → anual)
setenv('HA_IE_Z_SD',             '0.5417411732');  % 0.146/sqrt(1-0.963^2)
setenv('HA_IE_Z_MU',             '0.0');
setenv('HA_IE_Z_WIDTH',          '2.449');
setenv('HA_IE_Z_DT',             '1.0');

%% BARRERA ACCESO FORMAL
setenv('HA_IE_KAPPA_Z1',         '0.110');    % barrera z_bajo (target Tkz=0.386)
setenv('HA_IE_KAPPA_Z_SHAPE',    '2.0');      % curvatura (1=lineal, 2=convexa)

%% PRIMA DE DEUDA
setenv('HA_IE_DEBT_PREM_CHI',    '0.02');
setenv('HA_IE_DEBT_PREM_ETA',    '1.0');
setenv('HA_IE_DEBT_PREM_REBATE', 'false');

%% REGLA REPARTO BENEFICIOS INFORMAL
setenv('HA_IE_INFORMAL_PROFIT_RULE', 'hours');  % 'hours' o 'lump'

%% TARGETS (referencia — no calibran el modelo, solo para comparar en output)
setenv('HA_IE_T4_DATA',          '0.557');    % L_I/(L_F+L_I) — INEI CS 2024
setenv('HA_IE_T5_DATA',          '0.190');    % p_I*Y_I/Y_total — INEI CS 2024
setenv('HA_IE_TKZ_DATA',         '0.386');    % gap formalidad z_alto-z_bajo — EPEN 2025
setenv('HA_IE_TGASTO_TIPO_DATA', '1.913');    % gasto F-dom/I-dom — ENAHO 2015-2019

%% BISECCIÓN r
setenv('HA_IE_R_LO',             '-0.04');
setenv('HA_IE_R_HI',             '0.15');

%% TOLERANCIAS
setenv('HA_IE_TOL_T',            '1e-5');
setenv('HA_IE_TOL_WI',           '1e-5');
setenv('HA_IE_TOL_PI',           '1e-5');
setenv('HA_IE_TOL_R',            '1e-4');
setenv('HA_IE_MAX_ITER_T',       '30');
setenv('HA_IE_MAX_ITER_WI',      '40');
setenv('HA_IE_MAX_ITER_PI',      '50');
setenv('HA_IE_MAX_BISECT_R',     '30');

%% ZERO-DRIFT
setenv('HA_IE_ZDRIFT_NPTS',      '80');
setenv('HA_IE_ZDRIFT_METHOD',    '');
setenv('HA_IE_ZDRIFT_REUSE',     '');

fprintf('=== setup_calibration cargado (DRS Göbel + Hong 2022) ===\n');
fprintf('Parámetros activos: omega_C=%.2f, A_I=%.2f, nu_I=%.2f, Nz=%s\n', ...
    str2double(getenv('HA_IE_OMEGA_C')), ...
    str2double(getenv('HA_IE_A_I')), ...
    str2double(getenv('HA_IE_NU_I')), ...
    getenv('HA_IE_Z_N'));
