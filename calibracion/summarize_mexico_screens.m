% summarize_mexico_screens.m
% Resume las corridas de cribado y separa ajuste de validez numerica.

this_file = mfilename('fullpath');
repo_root = fileparts(fileparts(this_file));
tags = {'mexico_2024_screen01', 'mexico_2024_screen03', ...
        'mexico_2024_screen04', 'mexico_2024_screen05', ...
        'mexico_2024_screen06', 'mexico_2024_screen07', ...
        'mexico_2024_screen08'};

fprintf('\nCribado mexicano\n');
fprintf('%-23s %7s %7s %7s %9s %9s %8s\n', ...
    'Corrida', 'T4', 'T5', 'Tkz', 'exc. K', 'exc. bien', 'Estado');

for it = 1:numel(tags)
    tag = tags{it};
    file = fullfile(repo_root, 'outputs', 'stationary', tag, ...
        ['results_' tag '.mat']);
    if ~isfile(file), continue; end
    s = load(file, 'r_star', 'T4_model', 'T5_nom', 'T_kappa_z_model', ...
        'goods_I_err', 'ge_history');
    [~, ix] = min(abs(s.ge_history.r_grid - s.r_star));
    excess_k = s.ge_history.excess_K_r(ix);
    valid = abs(excess_k) <= 0.02 && abs(s.goods_I_err) <= 0.02;
    if valid, state = 'cierra'; else, state = 'explora'; end
    fprintf('%-23s %7.3f %7.3f %7.3f %+9.3f %+9.3f %8s\n', ...
        tag, s.T4_model, s.T5_nom, s.T_kappa_z_model, ...
        excess_k, s.goods_I_err, state);
end

fprintf('\nTargets ENOE e INEGI  %.3f  %.3f  %.3f\n', ...
    0.5070729242, 0.254, 0.5670826708);
fprintf(['Una corrida de exploracion no cuenta como calibracion aunque sus ' ...
    'momentos esten cerca.\n']);
