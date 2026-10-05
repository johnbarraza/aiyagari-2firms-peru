% validate_mexico_screening.m
% Contraste preliminar del equilibrio peruano con agregados oficiales de Mexico.
% No es una calibracion mexicana. T4 requiere reconstruir horas con la ENOE.

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

s = load(results_file, 'T4_model', 'T5_nom');
if ~isfield(s, 'T4_model') || ~isfield(s, 'T5_nom')
    error('La corrida no contiene T4_model y T5_nom.');
end

% INEGI, Medicion de la Economia Informal 2024, publicacion preliminar.
mexico_informal_workers = 0.544;
mexico_informal_gdp = 0.254;

fprintf('\nTamiz preliminar para Mexico 2024\n');
fprintf('Archivo del modelo: %s\n\n', results_file);
fprintf('%-31s %10s %10s %11s\n', ...
    'Magnitud', 'Modelo', 'Mexico', 'Brecha');
fprintf('%-31s %10.4f %10.4f %+11.4f\n', ...
    'Trabajo informal (*)', s.T4_model, mexico_informal_workers, ...
    s.T4_model - mexico_informal_workers);
fprintf('%-31s %10.4f %10.4f %+11.4f\n', ...
    'PBI informal', s.T5_nom, mexico_informal_gdp, ...
    s.T5_nom - mexico_informal_gdp);
fprintf(['\n(*) El modelo mide horas y el dato publicado mide personas. ' ...
    'La brecha no es un error de T4.\n']);
fprintf(['El contraste de PBI es conceptualmente cercano a T5. ' ...
    'La corrida peruana subpredice Mexico en %.2f puntos porcentuales.\n'], ...
    100 * (mexico_informal_gdp - s.T5_nom));

