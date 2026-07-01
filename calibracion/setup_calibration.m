% setup_calibration.m
% Helper opcional para fijar explicitamente la especificacion final del paper.
%
% No es necesario correr este archivo para la replica base: model_main.m ya
% contiene estos mismos valores como defaults. Este script solo existe para
% usuarios que quieran dejar visible la configuracion mediante variables HA_IE_*.

%% Modo y salida
setenv('HA_IE_EQ_MODE',          '2');
setenv('HA_IE_FAST_DEBUG',       '1');
setenv('HA_IE_VERBOSE',          '0');

%% Grillas
setenv('HA_IE_AMIN',             '-1.0');
setenv('HA_IE_AMAX',             '20');
setenv('HA_IE_Z_PROCESS',        'ou');
setenv('HA_IE_Z_N',              '40');
setenv('HA_IE_Z_RHO',            '0.861');
setenv('HA_IE_Z_SD',             '0.544');
setenv('HA_IE_Z_WIDTH',          '2.5');
setenv('HA_IE_Z_MU',             '0.0');
setenv('HA_IE_Z_DT',             '1.0');
setenv('HA_IE_ZDRIFT_NPTS',      '25');

%% Preferencias y consumo
setenv('HA_IE_PSI_F',            '55');
setenv('HA_IE_PSI_I',            '34');
setenv('HA_IE_THETA',            '1.0');
setenv('HA_IE_NU_I',             '0.6');
setenv('HA_IE_SIGMA_C',          '5');
setenv('HA_IE_OMEGA_C',          '0.56');
setenv('HA_IE_TAU_C',            '0');

%% Firmas y barrera formal
setenv('HA_IE_A_F',              '1.0');
setenv('HA_IE_A_I',              '0.98');
setenv('HA_IE_ALPHA_I',          '0.220');
setenv('HA_IE_BETA_I',           '0.619');
setenv('HA_IE_KAPPA_Z1',         '0.40');
setenv('HA_IE_KAPPA_Z_SHAPE',    '1.0');

%% Prima de deuda y reparto de beneficios
setenv('HA_IE_DEBT_PREM_CHI',    '0.02');
setenv('HA_IE_DEBT_PREM_ETA',    '1.0');
setenv('HA_IE_DEBT_PREM_REBATE', '0');
setenv('HA_IE_INFORMAL_PROFIT_RULE', 'hours');

%% Targets reportados
setenv('HA_IE_T4_DATA',          '0.557');
setenv('HA_IE_T5_DATA',          '0.190');
setenv('HA_IE_TKZ_DATA',         '0.386');
setenv('HA_IE_TGASTO_TIPO_DATA', '1.913');

fprintf('setup_calibration: parametros finales cargados (Nz=40, regla hours).\n');
