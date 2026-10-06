% setup_mexico.m
% Configuracion separada para calibrar Mexico. No modifica los defaults de Peru.
%
% Fuentes externas principales:
% Leal-Ordonez (2014): alpha_K=0.33, retornos informales=0.76,
% depreciacion=0.05 y beta discreto=0.94.
% Alvarez y Ruane (2019): cuna regulatoria formal=0.35.
% Auclert et al. (2024): persistencia anual=0.78 y sd log ingreso neto=0.84.
% Leyva y Urrutia: elasticidad Frisch=3.27 para Mexico.
%
% Targets internos:
% T4 y Tkz se construyen con ENOE 2024-I mediante
% scripts/data/mexico/build_enoe_moments.py. T5 proviene de INEGI MEI 2024.

setenv('HA_IE_EQ_MODE',          '2');
setenv('HA_IE_FAST_DEBUG',       '1');
setenv('HA_IE_VERBOSE',          '0');
setenv('HA_IE_PROFILE',          '0');
setenv('HA_IE_RUN_TAG',          'mexico_2024_calib01');

% Grillas y proceso de productividad
setenv('HA_IE_I',                '120');
setenv('HA_IE_DEBUG_I',          '120');
setenv('HA_IE_AMIN',             '-1.0');
setenv('HA_IE_AMAX',             '20');
setenv('HA_IE_Z_PROCESS',        'ou');
setenv('HA_IE_Z_N',              '24');
setenv('HA_IE_Z_RHO',            '0.78');
setenv('HA_IE_Z_SD',             '0.84');
setenv('HA_IE_Z_WIDTH',          'auto');
setenv('HA_IE_Z_MU',             '0.0');
setenv('HA_IE_Z_DT',             '1.0');
setenv('HA_IE_ZDRIFT_NPTS',      '25');

% Hogares
setenv('HA_IE_GA',               '2.0');
setenv('HA_IE_RHO',              '0.0618754');
setenv('HA_IE_FRISCH',           '3.27');
setenv('HA_IE_PSI_F',            '40');
setenv('HA_IE_PSI_I',            '40');
setenv('HA_IE_THETA',            '1.0');
setenv('HA_IE_NU_I',             '0.6');
setenv('HA_IE_SIGMA_C',          '5');
setenv('HA_IE_OMEGA_C',          '0.56');
setenv('HA_IE_TAU_C',            '0');

% Firmas e instituciones
setenv('HA_IE_A_F',              '1.0');
setenv('HA_IE_AL',               '0.33');
setenv('HA_IE_DELTA',            '0.05');
setenv('HA_IE_TAU',              '0.35');
setenv('HA_IE_A_I',              '1.0');
setenv('HA_IE_ALPHA_I',          '0.33');
setenv('HA_IE_BETA_I',           '0.43');
setenv('HA_IE_KAPPA_Z1',         '0.42');
setenv('HA_IE_KAPPA_Z_SHAPE',    '1.0');

% Prima de deuda y beneficios
setenv('HA_IE_DEBT_PREM_CHI',    '0.02');
setenv('HA_IE_DEBT_PREM_ETA',    '1.0');
setenv('HA_IE_DEBT_PREM_REBATE', '0');
setenv('HA_IE_INFORMAL_PROFIT_RULE', 'hours');

% Momentos mexicanos
setenv('HA_IE_T4_DATA',          '0.507073');
setenv('HA_IE_T5_DATA',          '0.254000');
setenv('HA_IE_TKZ_DATA',         '0.567083');

fprintf('setup_mexico: configuracion Mexico 2024 cargada.\n');
