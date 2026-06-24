%% CALIBRATION SETENV — v10 ARz, 2 scenarios + NZ/fastdebug
% Source: parametros_cobb_douglas_formal_informal_peru.md
%
% Formal:  Cespedes, Aquije, Sanchez & Vera-Tudela (2014, BCRP REE-28)
%          alpha_K=0.636, alpha_L=0.364 (CRS, firm-level SUNAT)
% Informal: Gobel, Grimm & Lay (2013, BCRP WP 2013-001)
%          ENAHO 2002-2006 microempresas urbanas
%
% SCENARIOS:
%   A) NO informal capital: alpha_I=0, beta_I=0.696 (legacy DRS)
%   B) CRS Gobel: alpha_I=0.163, beta_I=0.837 (Pi_I=0)
%   C) DRS Gobel: alpha_I=0.118, beta_I=0.605 (Pi_I>0)
% Activar con: setenv('HA_IE_SCENARIO', 'CRS_Gobel') antes de este script.

%% ─── SCENARIO SELECTOR ──────────────────────────────────────────
scenario = lower(strtrim(getenv('HA_IE_SCENARIO')));
if isempty(scenario), scenario = 'legacy_drs'; end

switch scenario
    case {'legacy_drs', 'a'}
        alpha_I_val = '0.0';
        beta_I_val  = '0.696';
        label = 'LEGACY DRS: alpha_I=0, beta_I=0.696 (no informal capital)';
    case {'crs_gobel', 'b'}
        alpha_I_val = '0.163';
        beta_I_val  = '0.837';
        label = 'CRS Gobel: alpha_I=0.163, beta_I=0.837 (Pi_I=0)';
    case {'drs_gobel', 'c'}
        alpha_I_val = '0.118';
        beta_I_val  = '0.605';
        label = 'DRS Gobel: alpha_I=0.118, beta_I=0.605 (Pi_I>0)';
    otherwise
        error('Unknown scenario: %s. Use: legacy_drs, crs_gobel, drs_gobel', scenario);
end
fprintf('=== SCENARIO: %s ===\n', label);

%% ─── EXECUTION ──────────────────────────────────────────────────
setenv('HA_IE_EQ_MODE',          '2');
setenv('HA_IE_FAST_DEBUG',       'false');  % full production
setenv('HA_IE_RUN_TAG',          ['v10_' scenario]);
setenv('HA_IE_VERBOSE',          '1');
setenv('HA_IE_PROFILE',          'true');

%% ─── GRID ───────────────────────────────────────────────────────
setenv('HA_IE_I',                '500');
setenv('HA_IE_AMIN',             '-0.10');
setenv('HA_IE_AMAX',             '20');

%% ─── PREFERENCES (HOUSEHOLD) ────────────────────────────────────
% ga=2, rho=0.05 (hardcoded)
setenv('HA_IE_PSI_F',            '175');
setenv('HA_IE_PSI_I',            '50');
setenv('HA_IE_THETA',            '1.0');
setenv('HA_IE_NU_I',             '0.030');

%% ─── CES CONSUMPTION ────────────────────────────────────────────
setenv('HA_IE_SIGMA_C',          '5');
setenv('HA_IE_OMEGA_C',          '0.58');

%% ─── FORMAL FIRM (Cespedes et al. 2014) ─────────────────────────
% al=0.636, d=0.10 (Castillo-Rojas), A_F=1 (hardcoded)

%% ─── INFORMAL FIRM (Gobel et al. 2013) ──────────────────────────
setenv('HA_IE_A_I',              '0.305');      % calibrar → T5
setenv('HA_IE_ALPHA_I',          alpha_I_val);
setenv('HA_IE_BETA_I',           beta_I_val);

%% ─── PRODUCTIVITY (Hong 2022, ENAHO) ────────────────────────────
setenv('HA_IE_Z_PROCESS',        'ou');
setenv('HA_IE_Z_N',              '7');          % baseline; increase for convergence
setenv('HA_IE_Z_RHO',            '0.8600132622');  % Hong (2022): quarterly 0.963^4
setenv('HA_IE_Z_SD',             '0.5417411732');   % Hong (2022): 0.146/sqrt(1-0.963^2)
setenv('HA_IE_Z_WIDTH',          '2.44948974278');

%% ─── BARRIERS ───────────────────────────────────────────────────
setenv('HA_IE_KAPPA_Z1',         '0.080');
setenv('HA_IE_KAPPA_Z_SHAPE',    '2.0');

%% ─── DEBT PREMIUM ───────────────────────────────────────────────
setenv('HA_IE_DEBT_PREM_CHI',    '0.02');
setenv('HA_IE_DEBT_PREM_ETA',    '1.25');
setenv('HA_IE_DEBT_PREM_REBATE', '0');

%% ─── PROFIT RULE ────────────────────────────────────────────────
if strcmp(scenario, 'crs_gobel')
    % CRS → Pi_I=0 → profit rule irrelevant but keep lump for safety
    setenv('HA_IE_INFORMAL_PROFIT_RULE', 'lump');
else
    setenv('HA_IE_INFORMAL_PROFIT_RULE', 'hours');
end

fprintf('Scenario %s ready. Run: >> run_model_main\n', scenario);
