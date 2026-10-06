% setup_mexico_screen.m
% Corrida economica para explorar parametros. La configuracion seleccionada
% debe verificarse despues con setup_mexico.m y una grilla mas fina.

run(fullfile(fileparts(mfilename('fullpath')), 'setup_mexico.m'));

setenv('HA_IE_RUN_TAG',          'mexico_2024_screen04');
setenv('HA_IE_DEBUG_I',          '60');
setenv('HA_IE_Z_N',              '12');
setenv('HA_IE_MAX_ITER_T',       '4');
setenv('HA_IE_MAX_ITER_WI',      '3');
setenv('HA_IE_MAX_ITER_PI',      '10');
setenv('HA_IE_TOL_T',            '0.003');
setenv('HA_IE_TOL_WI',           '0.003');
setenv('HA_IE_TOL_PI',           '0.01');
setenv('HA_IE_MAX_BISECT_R',     '6');
setenv('HA_IE_TOL_R',            '0.01');
setenv('HA_IE_R_LO',             '0.02');
setenv('HA_IE_R_HI',             '0.045');

% Candidato con cierre de mercados seleccionado en el cribado.
setenv('HA_IE_A_I',              '0.65');
setenv('HA_IE_PSI_I',            '40');
setenv('HA_IE_KAPPA_Z1',         '0.15');
setenv('HA_IE_NU_I',             '0.60');

fprintf('setup_mexico_screen: tolerancias de exploracion cargadas.\n');
