% setup_mexico_nz24.m
% Verificacion del candidato seleccionado despues del cribado mexicano.

run(fullfile(fileparts(mfilename('fullpath')), 'setup_mexico.m'));

setenv('HA_IE_RUN_TAG',          'mexico_2024_nz24');
setenv('HA_IE_DEBUG_I',          '120');
setenv('HA_IE_Z_N',              '24');

% Parametros internos seleccionados en el cribado.
setenv('HA_IE_A_I',              '0.50');
setenv('HA_IE_PSI_I',            '55');
setenv('HA_IE_KAPPA_Z1',         '0.42');
setenv('HA_IE_NU_I',             '0.90');

% Bracket y tolerancias de verificacion.
setenv('HA_IE_R_LO',             '-0.04');
setenv('HA_IE_R_HI',             '0.04');
setenv('HA_IE_MAX_ITER_T',       '6');
setenv('HA_IE_MAX_ITER_WI',      '4');
setenv('HA_IE_MAX_ITER_PI',      '12');
setenv('HA_IE_TOL_T',            '0.001');
setenv('HA_IE_TOL_WI',           '0.001');
setenv('HA_IE_TOL_PI',           '0.003');
setenv('HA_IE_MAX_BISECT_R',     '10');
setenv('HA_IE_TOL_R',            '0.002');

fprintf('setup_mexico_nz24: verificacion Nz=24 cargada.\n');
