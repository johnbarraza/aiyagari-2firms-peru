%% test_companero_vs_replication.m
% Verifica si parámetros del compañero (ou_prima_calib_try3)
% reproducen resultados con model_main.m del replication_package.
%
% Corre 3 variantes (amin=-0.002 en todas, no tocar por ahora):
%   A) Réplica exacta del compañero
%   B) Subir kappa_z1: 0.01 → 0.11 (cerrar Tkz)
%   C) Capital informal DRS Göbel + benchmark psi + theta=1.0
%
% Tiempo: ~16 min c/u fast debug (Nz=14). Total ~50 min.

HA_IE_REPLICATION_LOADED = true;
BASE_DIR = fileparts(mfilename('fullpath'));
if isempty(BASE_DIR), BASE_DIR = pwd; end
cd(BASE_DIR);

%% ═══════════════════════════════════════════════════════════════
%% CORRIDA A: Réplica exacta del compañero
%% ═══════════════════════════════════════════════════════════════
fprintf('>>> A: Réplica compañero (alpha_I=0, kappa_z1=0.01)\n');

setenv('HA_IE_RUN_TAG',   'test_A_replica');
setenv('HA_IE_OUTPUT_DIR', fullfile(BASE_DIR, 'outputs', 'stationary'));
setenv('HA_IE_FAST_DEBUG', '1');
setenv('HA_IE_EQ_MODE',    '2');
setenv('HA_IE_VERBOSE',    '1');
setenv('HA_IE_R_HI',       '0.15');

% z-process Hong
setenv('HA_IE_Z_PROCESS', 'ou');
setenv('HA_IE_Z_N',       '14');
setenv('HA_IE_Z_RHO',     '0.861');
setenv('HA_IE_Z_SD',      '0.544');
setenv('HA_IE_Z_WIDTH',   '2.5');

% Compañero
setenv('HA_IE_PSI_F',     '100');
setenv('HA_IE_PSI_I',     '75');
setenv('HA_IE_A_I',       '0.5');
setenv('HA_IE_ALPHA_I',   '0.0');
setenv('HA_IE_BETA_I',    '0.60');
setenv('HA_IE_THETA',     '0.55');
setenv('HA_IE_NU_I',      '0.6');
setenv('HA_IE_OMEGA_C',   '0.55');
setenv('HA_IE_SIGMA_C',   '5');
setenv('HA_IE_KAPPA_Z1',        '0.01');
setenv('HA_IE_KAPPA_Z_SHAPE',   '2.0');
setenv('HA_IE_DEBT_PREM_CHI',    '0.02');
setenv('HA_IE_DEBT_PREM_ETA',    '1.25');
setenv('HA_IE_DEBT_PREM_REBATE', '0');
setenv('HA_IE_AMIN',       '-0.002');
setenv('HA_IE_INFORMAL_PROFIT_RULE', 'hours');

model_main

%% ═══════════════════════════════════════════════════════════════
%% CORRIDA B: Subir kappa_z1 (mismo resto)
%% ═══════════════════════════════════════════════════════════════
fprintf('\n>>> B: kappa_z1 0.01 → 0.11\n');

setenv('HA_IE_RUN_TAG',   'test_B_kappa110');
setenv('HA_IE_KAPPA_Z1',  '0.110');
% Resto heredado de A

model_main

%% ═══════════════════════════════════════════════════════════════
%% CORRIDA C: Capital informal DRS Göbel
%% ═══════════════════════════════════════════════════════════════
fprintf('\n>>> C: DRS Göbel K informal + benchmark psi/theta\n');

setenv('HA_IE_RUN_TAG',   'test_C_DRS_Gobel');
setenv('HA_IE_ALPHA_I',   '0.118');
setenv('HA_IE_BETA_I',    '0.605');
setenv('HA_IE_A_I',       '0.99');
setenv('HA_IE_PSI_F',     '180');
setenv('HA_IE_PSI_I',     '50');
setenv('HA_IE_THETA',     '1.0');
setenv('HA_IE_OMEGA_C',   '0.57');
setenv('HA_IE_KAPPA_Z1',  '0.110');
% amin, z, nu_I, sigma_C heredados

model_main

fprintf('\n=== 3 corridas completadas. outputs/stationary/test_* ===\n');
