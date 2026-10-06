% validate_mexico_calibration.m
% Evalua el candidato numericamente valido del cribado mexicano.

this_file = mfilename('fullpath');
repo_root = fileparts(fileparts(this_file));
results_file = strtrim(getenv('HA_IE_MEXICO_RESULTS'));
if isempty(results_file)
    tag = 'mexico_2024_screen04';
    results_file = fullfile(repo_root, 'outputs', 'stationary', tag, ...
        ['results_' tag '.mat']);
end
if ~isfile(results_file)
    error('No se encontro la corrida mexicana: %s', results_file);
end

s = load(results_file);
[~, ix] = min(abs(s.ge_history.r_grid - s.r_star));
excess_k = s.ge_history.excess_K_r(ix);
targets = [0.5070729242, 0.254, 0.5670826708];
model = [s.T4_model, s.T5_nom, s.T_kappa_z_model];
names = {'T4 horas informales', 'T5 PBI informal', 'Tkz gap educativo'};

fprintf('\nValidacion del candidato mexicano\n');
fprintf('Archivo  %s\n\n', results_file);
fprintf('%-24s %9s %9s %9s\n', 'Momento', 'Modelo', 'Dato', 'Brecha');
for j = 1:numel(names)
    fprintf('%-24s %9.4f %9.4f %+9.4f\n', ...
        names{j}, model(j), targets(j), model(j) - targets(j));
end
fprintf('\nExceso de capital  %+.4e\n', excess_k);
fprintf('Exceso del bien informal  %+.4e\n', s.goods_I_err);
fprintf('Ratio salarial bruto reservado  %.4f frente a %.4f en ENOE\n', ...
    s.w_F_star / s.w_I_star, 1.4367860062);

numerical_ok = abs(excess_k) <= 0.02 && abs(s.goods_I_err) <= 0.02;
fit_ok = all(abs(model - targets) <= [0.03, 0.03, 0.05]);
fprintf('Cierre numerico  %s\n', string(numerical_ok));
fprintf('Ajuste conjunto  %s\n', string(fit_ok));
if numerical_ok && ~fit_ok
    fprintf(['Resultado  equilibrio valido, pero la especificacion no ajusta ' ...
        'simultaneamente los tres momentos mexicanos.\n']);
end
