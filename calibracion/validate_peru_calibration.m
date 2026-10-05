% validate_peru_calibration.m
% Verifica la corrida de cierre contra los targets que aparecen en el documento.
% No resuelve nuevamente el modelo. Para una replica completa, ejecutar antes:
%   run('lean/scripts/matlab/reproducir_cierre.m')

this_file = mfilename('fullpath');
repo_root = fileparts(fileparts(this_file));

results_file = strtrim(getenv('HA_IE_VALIDATION_RESULTS'));
if isempty(results_file)
    results_file = fullfile(repo_root, 'outputs', 'stationary', ...
        'test_AI098_cierre', 'results_test_AI098_cierre.mat');
end
if ~isfile(results_file)
    error(['No se encontro la corrida de cierre: %s\n' ...
        'Ejecute reproducir_cierre.m o defina HA_IE_VALIDATION_RESULTS.'], ...
        results_file);
end

s = load(results_file);
required = {'T4_model','T5_nom','T_kappa_z_model','Tgasto_tipo', ...
    'T6_model','w_F_star','w_I_star','tau','r_star','Gini_a','Gini_c'};
for i = 1:numel(required)
    if ~isfield(s, required{i})
        error('Falta %s en %s.', required{i}, results_file);
    end
end

names = {'T4 horas informales'; 'T5 PBI informal'; ...
    'Tkz gap formalidad'; 'Tgasto formal/informal'; ...
    'T6 gap Q1-Q5'; 'T1 salario neto'};
model = [s.T4_model; s.T5_nom; s.T_kappa_z_model; s.Tgasto_tipo; ...
    s.T6_model; (1-s.tau)*s.w_F_star/s.w_I_star];
data = [0.509; 0.190; 0.386; 1.913; 0.530; 2.300];
role = {'target'; 'target'; 'target'; 'validacion'; 'diagnostico'; 'validacion'};
gap = model - data;

fprintf('\nValidacion de la calibracion de Peru\n');
fprintf('Archivo: %s\n\n', results_file);
fprintf('%-28s %10s %10s %11s %s\n', 'Momento', 'Modelo', 'Dato', 'Brecha', 'Uso');
for i = 1:numel(names)
    fprintf('%-28s %10.4f %10.4f %+11.4f %s\n', ...
        names{i}, model(i), data(i), gap(i), role{i});
end

primary_ok = all(abs(gap(1:3)) <= 0.01);
fprintf('\nr*=%.6f, Gini activos=%.4f, Gini consumo=%.4f\n', ...
    s.r_star, s.Gini_a, s.Gini_c);
fprintf('Criterio targets primarios (brecha absoluta <= 1 pp): %s\n', ...
    string(primary_ok));

assert(primary_ok, ...
    'Al menos un target primario se aleja mas de 1 punto porcentual.');

