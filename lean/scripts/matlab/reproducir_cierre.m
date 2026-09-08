% Reproduccion de test_AI098_cierre con el ajuste de walras_err aplicado.
% El entorno se reconstruye desde run_metadata.txt [env] MAS los parametros que
% ese bloque NO registra y que solo estan dentro del results_*.mat: rho = 0.073.
% Ubicar la raiz del paquete relativa a este script:
%   <repo>/lean/scripts/matlab/reproducir_cierre.m  ->  <repo>
this_file = mfilename('fullpath');
repo_root = fileparts(fileparts(fileparts(fileparts(this_file))));
cd(repo_root);
fprintf('raiz del paquete: %s\n', repo_root);

setenv('HA_IE_RUN_TAG',              'verif_walras_20260907');
setenv('HA_IE_FAST_DEBUG',           'true');
setenv('HA_IE_VERBOSE',              '0');
setenv('HA_IE_EQ_MODE',              '2');

% --- no registrado en [env] del metadata; recuperado del results_*.mat ---
setenv('HA_IE_RHO',                  '0.073');

% --- registrado en [env] ---
setenv('HA_IE_AMIN',                 '-1.0');
setenv('HA_IE_R_LO',                 '-0.04');
setenv('HA_IE_R_HI',                 '0.20');
setenv('HA_IE_ZDRIFT_NPTS',          '25');
setenv('HA_IE_Z_N',                  '40');
setenv('HA_IE_Z_RHO',                '0.861');
setenv('HA_IE_Z_SD',                 '0.544');
setenv('HA_IE_Z_WIDTH',              '2.5');
setenv('HA_IE_A_I',                  '0.98');
setenv('HA_IE_ALPHA_I',              '0.220');
setenv('HA_IE_BETA_I',               '0.619');
setenv('HA_IE_THETA',                '1.0');
setenv('HA_IE_NU_I',                 '0.6');
setenv('HA_IE_PSI_F',                '55');
setenv('HA_IE_PSI_I',                '34');
setenv('HA_IE_OMEGA_C',              '0.56');
setenv('HA_IE_SIGMA_C',              '5');
setenv('HA_IE_KAPPA_Z1',             '0.40');
setenv('HA_IE_KAPPA_Z_SHAPE',        '1.0');
setenv('HA_IE_DEBT_PREM_CHI',        '0.02');
setenv('HA_IE_DEBT_PREM_ETA',        '1.0');
setenv('HA_IE_DEBT_PREM_REBATE',     '0');
setenv('HA_IE_INFORMAL_PROFIT_RULE', 'hours');

fprintf('=== reproduccion test_AI098_cierre + fix walras_err ===\n');
fprintf('objetivo: r*=0.066040  K*=5.138390  p_I*=0.928115\n');
fprintf('          T4=0.517110 T5=0.187958 Tkz=0.377518 T6=0.044079\n');
fprintf('          walras_err debe pasar de 6.07e-04 a 4.71e-04\n\n');

model_main
