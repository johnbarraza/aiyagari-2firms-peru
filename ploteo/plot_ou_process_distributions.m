% ============================================================
% DISABLED — plots migrados a Python.
% Usar: python ploteo/plot_ou_results.py --mat-file <ruta>.mat
% Este archivo se conserva como referencia pero NO debe ejecutarse.
% ============================================================
function plot_ou_process_distributions(mat_file)
%PLOT_OU_PROCESS_DISTRIBUTIONS Clean OU-specific plots for ARz/debt-prem runs.
%
% Usage:
%   plot_ou_process_distributions
%   plot_ou_process_distributions('mat_outputs/.../results_run.mat')
%
% This plot intentionally avoids legacy (z,q) labels. For OU runs, the
% state is (a,z); q is not an active heterogeneity dimension. It generates:
%   1) OU process, wealth and consumption distributions.
%   2) Trap diagnostics for poverty/informality mechanisms.

if nargin < 1 || isempty(mat_file)
    mat_file = default_results_file();
end
if ~exist(mat_file, 'file')
    error('No se encontro %s', mat_file);
end

script_dir = fileparts(mfilename('fullpath'));
old_dir = pwd;
cleanup_obj = onCleanup(@() cd(old_dir));
cd(script_dir);

global p_I omega_C eta_C sigma_C
load(mat_file);

if exist('USE_Q', 'var') && USE_Q ~= 0
    warning('El archivo tiene USE_Q=%g. Este grafico esta disenado para OU puro (USE_Q=0).', USE_Q);
end

required_vars = {'a','z','g','c','da','p_I','omega_C','eta_C','sigma_C'};
for kv = 1:numel(required_vars)
    if ~exist(required_vars{kv}, 'var')
        error('Falta variable requerida en el .mat: %s', required_vars{kv});
    end
end

z = z(:)';
a = a(:);
[I, Ns] = size(g);
if numel(a) ~= I || numel(z) ~= Ns
    error('Dimensiones inconsistentes: a=%d, z=%d, g=%dx%d', numel(a), numel(z), I, Ns);
end

if ~exist('aa', 'var'), aa = a * ones(1, Ns); end
if ~exist('zz', 'var'), zz = ones(I,1) * z; end
if ~exist('pi_z_ar', 'var') || isempty(pi_z_ar)
    pi_z_ar = da * sum(g, 1);
    pi_z_ar = pi_z_ar / max(sum(pi_z_ar), 1e-12);
else
    pi_z_ar = pi_z_ar(:)' / max(sum(pi_z_ar), 1e-12);
end
mass_z_model = da * sum(g, 1);
mass_z_model = mass_z_model / max(sum(mass_z_model), 1e-12);

[c_F, c_I, exp_cons] = ces_split_from_Ceff_v10(c);
weights_all = g(:) * da;

low_idx = 1;
mid_idx = max(1, round((Ns + 1) / 2));
high_idx = Ns;
idx_show = unique([low_idx mid_idx high_idx], 'stable');
z_colors = [0.77 0.18 0.14; 0.35 0.35 0.35; 0.05 0.43 0.65];
if numel(idx_show) == 2
    z_colors = z_colors([1 3], :);
elseif numel(idx_show) == 1
    z_colors = z_colors(2, :);
end

g_marg_a = sum(g, 2);
wealth_pdf_all = g_marg_a / max(sum(g_marg_a) * da, 1e-12);
[x_ceff, pdf_ceff] = weighted_pdf_local(c(:), weights_all, 60);
[x_exp, pdf_exp] = weighted_pdf_local(exp_cons(:), weights_all, 60);

mean_a_by_z = zeros(1, Ns);
mean_exp_by_z = zeros(1, Ns);
mass_debt_by_z_plot = zeros(1, Ns);
form_share_by_z = zeros(1, Ns);
for j = 1:Ns
    mass_j = da * sum(g(:,j));
    mean_a_by_z(j) = da * sum(g(:,j) .* a) / max(mass_j, 1e-12);
    mean_exp_by_z(j) = da * sum(g(:,j) .* exp_cons(:,j)) / max(mass_j, 1e-12);
    mass_debt_by_z_plot(j) = da * sum(g(:,j) .* (a < 0)) / max(mass_j, 1e-12);
    if exist('ell_F', 'var') && exist('ell_I', 'var')
        ellF_j = da * sum(g(:,j) .* ell_F(:,j)) / max(mass_j, 1e-12);
        ellI_j = da * sum(g(:,j) .* ell_I(:,j)) / max(mass_j, 1e-12);
        form_share_by_z(j) = ellF_j / max(ellF_j + ellI_j, 1e-12);
    else
        form_share_by_z(j) = NaN;
    end
end

if ~exist('debt_spread_z', 'var') || isempty(debt_spread_z)
    debt_spread_z = zeros(1, Ns);
else
    debt_spread_z = debt_spread_z(:)';
end
if ~exist('debt_spread_aa', 'var') || isempty(debt_spread_aa)
    debt_spread_aa = zeros(I, Ns);
end

ctx = struct();
ctx_names = {'ell_F','ell_I','kappa_F_aa','qq_informal','w_F_star','w_F', ...
    'w_I_household_star','w_I_star','w_I','theta','nu_I','r_star','r_eq','r', ...
    'tau','T_eq','T_star','T','Pi_lump_star','profit_I_star','informal_profit_rule', ...
    'K_star','L_F_star','L_I_star','p_I_star','Y_F','Y_I','T4_model','T4_data', ...
    'T5_nom','T5_data','T_kappa_z_model','T_kappa_z_data','ratio_gasto_FI', ...
    'TgFI_data','Gini_a','Gini_c','Gini_c_by_a','lorenz_a','lorenz_c', ...
    'cum_pop_a','cum_pop_c','omega_C','sigma_C','rho_z_ar','sd_logz_ar', ...
    'debt_prem_chi','debt_prem_eta','debt_prem_rebate','H_bar','Frisch','psi_F','psi_I','ga', ...
    'A_I','alpha_I','beta_I','A_F','theta','nu_I','kappa_z1','kappa_z2','kappa_z_shape', ...
    'amin','amax','I','Ns','maxit','crit', ...
    'pi_z_ar','K_F_star','K_I_star','C_F_agg','C_I_agg','E_ellF','E_ellI', ...
    'ge_history','r_grid','S','KD','w_F_r','L_F','L_I','T_eq_r','w_I_eq_r', ...
    'Pi_I_eq_r','p_I_eq_r','Y_I_eq_r','C_I_eq_r','C_F_eq_r','omega_I_eq_r', ...
    'excess_K_r','goods_I_err_r','run_config','metadata_file','mat_output_dir', ...
    'results_file','calib_file','script_file','z_ou_diag','zdiag'};
for kctx = 1:numel(ctx_names)
    if exist(ctx_names{kctx}, 'var')
        ctx.(ctx_names{kctx}) = eval(ctx_names{kctx});
    end
end

[~, mat_tag, ~] = fileparts(mat_file);
run_ts  = datestr(now, 'HHMMss');
out_dir = fullfile(script_dir, sprintf('plots_ou_%s_%s', mat_tag, run_ts));
if ~exist(out_dir, 'dir'), mkdir(out_dir); end

fid_src = fopen(fullfile(out_dir, 'run_source.txt'), 'w');
if fid_src >= 0
    fprintf(fid_src, 'mat_file: %s\n', mat_file);
    fprintf(fid_src, 'generado: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
    fclose(fid_src);
end
latest_dir = fullfile(script_dir, 'output_graphs_ou_debtprem');
if ~exist(latest_dir, 'dir'), mkdir(latest_dir); end
fid_latest = fopen(fullfile(latest_dir, 'run_source.txt'), 'w');
if fid_latest >= 0
    fprintf(fid_latest, 'mat_file: %s\n', mat_file);
    fprintf(fid_latest, 'plot_output_dir: %s\n', out_dir);
    fprintf(fid_latest, 'generado: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
    fclose(fid_latest);
end

context_file = fullfile(out_dir, sprintf('run_context_%s.txt', mat_tag));
write_plot_context(context_file, mat_file, mat_tag, out_dir, ctx);
audit_file = fullfile(out_dir, sprintf('graph_audit_%s.txt', mat_tag));
write_graph_audit(audit_file, mat_tag);

moll_dir = make_moll_style_ou_figures(mat_file, mat_tag, out_dir, a, z, aa, zz, g, da, ...
    c, c_F, c_I, exp_cons, debt_spread_aa, debt_spread_z, pi_z_ar, mass_z_model, ...
    mean_a_by_z, mean_exp_by_z, mass_debt_by_z_plot, form_share_by_z, ell_F, ell_I, ctx);
fprintf('Moll-style OU figures saved to:\n  %s\n', moll_dir);
fprintf('Run context saved:\n  %s\n', context_file);
fprintf('Graph audit saved:\n  %s\n', audit_file);
return;

fig = figure('Color', 'white', 'Position', [60 60 1500 980]);
tiledlayout(fig, 3, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
bar(1:Ns, [pi_z_ar(:), mass_z_model(:)], 'grouped');
set(gca, 'XTick', 1:Ns, 'XTickLabel', z_tick_labels(z), 'TickLabelInterpreter', 'none');
xlabel('Estado OU z', 'Interpreter', 'none');
ylabel('Masa', 'Interpreter', 'none');
title(sprintf('Proceso OU discretizado: rho=%.3f, sd(log z)=%.3f', getv('rho_z_ar'), getv('sd_logz_ar')), ...
    'Interpreter', 'none');
legend({'Masa ergodica OU', 'Masa estacionaria modelo'}, 'Location', 'best', 'Interpreter', 'none');
grid on;

nexttile;
yyaxis left;
plot(z, mean_a_by_z, '-o', 'LineWidth', 2.0, 'MarkerSize', 5);
ylabel('Activos medios E[a|z]', 'Interpreter', 'none');
yyaxis right;
plot(z, debt_spread_z, '--s', 'LineWidth', 2.0, 'MarkerSize', 5);
ylabel('Prima deuda spread_b(z)', 'Interpreter', 'none');
xlabel('Productividad z', 'Interpreter', 'none');
title('OU y friccion financiera: z bajo enfrenta mayor prima', 'Interpreter', 'none');
grid on;

nexttile;
plot(a, wealth_pdf_all, '-', 'Color', [0.20 0.20 0.20], 'LineWidth', 2.2, 'DisplayName', 'Total');
hold on;
for kk = 1:numel(idx_show)
    j = idx_show(kk);
    mass_j = da * sum(g(:,j));
    pdf_j = g(:,j) / max(mass_j * da, 1e-12);
    plot(a, pdf_j, 'LineWidth', 1.8, 'Color', z_colors(kk,:), ...
        'DisplayName', sprintf('z=%.2f', z(j)));
end
xline(0, ':', 'Color', [0.35 0.35 0.35], 'HandleVisibility', 'off');
xlim([min(a), max(a)]);
xlabel('Riqueza neta a', 'Interpreter', 'none');
ylabel('Densidad', 'Interpreter', 'none');
title('Distribucion estacionaria de riqueza g(a)', 'Interpreter', 'none');
legend('Location', 'best', 'Interpreter', 'none');
grid on;

nexttile;
plot(x_ceff, pdf_ceff, '-', 'Color', [0.05 0.43 0.65], 'LineWidth', 2.2, ...
    'DisplayName', 'Consumo efectivo C');
hold on;
plot(x_exp, pdf_exp, '--', 'Color', [0.82 0.32 0.12], 'LineWidth', 2.2, ...
    'DisplayName', 'Gasto c_F + p_I c_I');
xlabel('Consumo / gasto', 'Interpreter', 'none');
ylabel('Densidad ponderada', 'Interpreter', 'none');
title('Distribucion de consumo y gasto', 'Interpreter', 'none');
legend('Location', 'best', 'Interpreter', 'none');
grid on;

nexttile;
plot(z, mean_exp_by_z, '-o', 'LineWidth', 2.0, 'DisplayName', 'Gasto medio');
hold on;
plot(z, mass_debt_by_z_plot, '--s', 'LineWidth', 2.0, 'DisplayName', 'Pr(a<0 | z)');
if any(isfinite(form_share_by_z))
    plot(z, form_share_by_z, ':^', 'LineWidth', 2.0, 'DisplayName', 'Share formal');
end
xlabel('Productividad z', 'Interpreter', 'none');
ylabel('Momento condicional', 'Interpreter', 'none');
title('Momentos condicionales por estado OU', 'Interpreter', 'none');
legend('Location', 'best', 'Interpreter', 'none');
grid on;

nexttile;
if exist('Qz_ar', 'var') && ~isempty(Qz_ar)
    imagesc(full(Qz_ar));
    axis tight;
    cb = colorbar;
    cb.Label.String = 'Intensidad Q_z';
    set(gca, 'XTick', 1:Ns, 'XTickLabel', z_tick_labels(z), ...
        'YTick', 1:Ns, 'YTickLabel', z_tick_labels(z), ...
        'TickLabelInterpreter', 'none');
    xlabel('z destino', 'Interpreter', 'none');
    ylabel('z origen', 'Interpreter', 'none');
    title('Generador continuo del OU discretizado', 'Interpreter', 'none');
else
    text(0.1, 0.55, 'Qz_ar no guardado en este .mat', 'FontSize', 13, 'Interpreter', 'none');
    axis off;
end

sgtitle(sprintf('Modelo OU sin q: proceso exogeno, riqueza y consumo | %s', mat_tag), ...
    'Interpreter', 'none', 'FontWeight', 'bold');

png_file = fullfile(out_dir, sprintf('ou_process_distributions_%s.png', mat_tag));
save_png_local(fig, png_file, 300);

summary_file = fullfile(out_dir, sprintf('ou_process_distributions_%s.txt', mat_tag));
fid = fopen(summary_file, 'w');
if fid >= 0
    fprintf(fid, 'OU process and stationary distributions\n');
    fprintf(fid, 'mat_file=%s\n', mat_file);
    fprintf(fid, 'USE_Q=%g\n', getv('USE_Q'));
    fprintf(fid, 'rho_z_ar=%.10f\n', getv('rho_z_ar'));
    fprintf(fid, 'sd_logz_ar=%.10f\n', getv('sd_logz_ar'));
    fprintf(fid, 'debt_prem_chi=%.10f\n', getv('debt_prem_chi'));
    fprintf(fid, 'debt_prem_eta=%.10f\n', getv('debt_prem_eta'));
    fprintf(fid, 'z pi_ou mass_model mean_a mean_exp mass_debt form_share debt_spread\n');
    for j = 1:Ns
        fprintf(fid, '%.10f %.10f %.10f %.10f %.10f %.10f %.10f %.10f\n', ...
            z(j), pi_z_ar(j), mass_z_model(j), mean_a_by_z(j), mean_exp_by_z(j), ...
            mass_debt_by_z_plot(j), form_share_by_z(j), debt_spread_z(j));
    end
    fclose(fid);
end

fprintf('OU plots saved:\n  %s\n  %s\n', png_file, summary_file);

include_files = make_include_ou_mechanism_figure(mat_file, mat_tag, out_dir, z, pi_z_ar, ...
    mass_z_model, mean_a_by_z, mean_exp_by_z, mass_debt_by_z_plot, ...
    form_share_by_z, debt_spread_z, ctx);
fprintf('Include-ready OU mechanism figure saved:\n  %s\n  %s\n', include_files.png, include_files.txt);

trap_files = make_trap_diagnostics(mat_file, mat_tag, out_dir, a, z, aa, zz, g, da, ...
    c, c_F, c_I, exp_cons, debt_spread_aa, debt_spread_z, ctx);
fprintf('Trap diagnostics saved:\n  %s\n  %s\n', trap_files.png, trap_files.txt);

policy_files = make_policy_equilibrium_validation(mat_file, mat_tag, out_dir, a, z, aa, zz, g, da, ...
    c, c_F, c_I, exp_cons, debt_spread_z, ctx);
fprintf('Policy/equilibrium validation saved:\n  %s\n  %s\n', policy_files.png, policy_files.txt);

effect_files = make_income_substitution_diagnostics(mat_file, mat_tag, out_dir, a, z, aa, zz, g, da, ...
    c, c_F, c_I, exp_cons, debt_spread_z, ctx);
fprintf('Income/substitution diagnostics saved:\n  %s\n  %s\n', effect_files.png, effect_files.txt);

surface_file = make_ou_surfaces(mat_tag, out_dir, a, z, g, c, c_F, c_I, exp_cons, ctx);
fprintf('OU 3D surfaces saved:\n  %s\n', surface_file);

separate_dir = make_separate_ou_figures(mat_file, mat_tag, out_dir, a, z, aa, zz, g, da, ...
    c, c_F, c_I, exp_cons, debt_spread_aa, debt_spread_z, ctx);
fprintf('Separate OU figures saved to:\n  %s\n', separate_dir);
fprintf('Run context saved:\n  %s\n', context_file);
fprintf('Graph audit saved:\n  %s\n', audit_file);

% --- THESIS-READY FIGURES FOR JURY ---
thesis_files = make_thesis_targets_validation(mat_tag, out_dir, ctx);
fprintf('Thesis targets validation saved:\n  %s\n', thesis_files.png);

thesis_gdp = make_thesis_gdp_accounting(mat_tag, out_dir, ctx);
fprintf('Thesis GDP accounting saved:\n  %s\n', thesis_gdp.png);

thesis_summary = make_thesis_mechanism_summary(mat_tag, out_dir, a, z, g, da, ...
    c, c_F, c_I, exp_cons, ell_F, ell_I, debt_spread_z, ctx);
fprintf('Thesis mechanism summary saved:\n  %s\n', thesis_summary.png);

thesis_tabla1 = make_thesis_tabla1_riqueza_labor(mat_tag, out_dir, a, z, aa, zz, g, da, ...
    ell_F, ell_I, ctx);
fprintf('Thesis Tabla 1 (riqueza y labor por cuartil) saved:\n  %s\n', thesis_tabla1.png);

thesis_income_q = make_income_decomposition_by_quintile(mat_tag, out_dir, a, z, aa, zz, g, da, ...
    exp_cons, debt_spread_aa, ctx);
fprintf('Thesis income decomposition by quintile saved:\n  %s\n', thesis_income_q.png);
end

function moll_dir = make_moll_style_ou_figures(mat_file, mat_tag, out_dir, a, z, aa, zz, g, da, ...
    c, c_F, c_I, exp_cons, debt_spread_aa, debt_spread_z, pi_z_ar, mass_z_model, ...
    mean_a_by_z, mean_exp_by_z, mass_debt_by_z, form_share_by_z, ell_F, ell_I, ctx)
% Figuras para tesis inspiradas en los graficos de Moll:
% fondo blanco, Times, lineas azul/rojo, ejes simples, leyendas matematicas
% y caption inferior tipo "Figura: ...".

moll_dir = fullfile(out_dir, ['moll_style_' mat_tag]);
if ~exist(moll_dir, 'dir'), mkdir(moll_dir); end

fid = fopen(fullfile(moll_dir, 'STYLE_NOTES.txt'), 'w');
if fid >= 0
    fprintf(fid, 'Figuras OU estilo Moll\n');
    fprintf(fid, 'source_mat=%s\n', mat_file);
    fprintf(fid, 'regla=maximo_dos_paneles_por_imagen\n');
    fprintf(fid, 'paleta=azul solido para z bajo / rojo discontinuo para z alto, siguiendo MOLL_GRAPHS.\n');
    fprintf(fid, 'nota_z=las policy functions sobre riqueza muestran los estados extremos z bajo y z alto; las figuras por productividad usan todos los nodos Nz.\n');
    fprintf(fid, 'informalidad=margen intensivo de horas, ell_I/(ell_F+ell_I), no margen extensivo de trabajadores informales.\n');
    fprintf(fid, 'rho_z_ar=%.10f\n', read_scalar_from_context(ctx, {'rho_z_ar'}, NaN));
    fprintf(fid, 'sd_logz_ar=%.10f\n', read_scalar_from_context(ctx, {'sd_logz_ar'}, NaN));
    fclose(fid);
end

blue = [0.00 0.00 1.00];
red = [1.00 0.00 0.00];
green = [0.00 0.45 0.00];
black = [0.00 0.00 0.00];
gray = [0.45 0.45 0.45];

Ns = numel(z);
j_low = 1;
j_high = Ns;
z_low_label = sprintf('z_mín=%.2f', z(j_low));
z_high_label = sprintf('z_máx=%.2f', z(j_high));
p_I_val = read_scalar_from_context(ctx, {'p_I_star','p_I'}, NaN);
if ~isfinite(p_I_val), p_I_val = 1; end
informal_share_by_z = 1 - form_share_by_z;
idx_legend_z = unique([j_low, j_high], 'stable');

zoom_lo = max(min(a), weighted_quantile(a, max(sum(g,2),0) * da, 0.01));
zoom_hi = min(max(a), weighted_quantile(a, max(sum(g,2),0) * da, 0.99));
if ~isfinite(zoom_lo) || ~isfinite(zoom_hi) || zoom_hi <= zoom_lo
    zoom_lo = min(a);
    zoom_hi = max(a);
end

adot = compute_adot_for_plot(a, aa, zz, exp_cons, debt_spread_aa, ctx);
mass_low = da * sum(g(:, j_low));
mass_high = da * sum(g(:, j_high));
pdf_low = g(:, j_low) / max(mass_low * da, 1e-12);
pdf_high = g(:, j_high) / max(mass_high * da, 1e-12);

mean_cF_by_z = zeros(1, Ns);
mean_pIcI_by_z = zeros(1, Ns);
share_cF_by_z = zeros(1, Ns);
share_pIcI_by_z = zeros(1, Ns);
mean_ellF_by_z = zeros(1, Ns);
mean_ellI_by_z = zeros(1, Ns);
mean_ellTot_by_z = zeros(1, Ns);
gini_C_by_z = zeros(1, Ns);
gini_exp_by_z = zeros(1, Ns);
for j = 1:Ns
    mass_j = da * sum(g(:, j));
    wj = g(:, j) * da;
    mean_cF_by_z(j) = da * sum(g(:, j) .* c_F(:, j)) / max(mass_j, 1e-12);
    mean_pIcI_by_z(j) = da * sum(g(:, j) .* (p_I_val * c_I(:, j))) / max(mass_j, 1e-12);
    denom_j = max(mean_cF_by_z(j) + mean_pIcI_by_z(j), 1e-12);
    share_cF_by_z(j) = mean_cF_by_z(j) / denom_j;
    share_pIcI_by_z(j) = mean_pIcI_by_z(j) / denom_j;
    mean_ellF_by_z(j) = da * sum(g(:, j) .* ell_F(:, j)) / max(mass_j, 1e-12);
    mean_ellI_by_z(j) = da * sum(g(:, j) .* ell_I(:, j)) / max(mass_j, 1e-12);
    mean_ellTot_by_z(j) = mean_ellF_by_z(j) + mean_ellI_by_z(j);
    gini_C_by_z(j) = weighted_gini_positive(c(:, j), wj);
    gini_exp_by_z(j) = weighted_gini_positive(exp_cons(:, j), wj);
end

% 1. Savings policy and wealth distribution, close to Moll Figure 2.
fig = moll_figure([75 75 760 560]);
hold on;
for jj = 1:numel(idx_legend_z)
    j = idx_legend_z(jj);
    [col_j, style_j, lw_j] = moll_z_line_style(j, Ns, z(j));
    name_j = sprintf('s_%d(a)', jj);
    plot(a, adot(:, j), style_j, 'Color', col_j, 'LineWidth', lw_j, ...
        'DisplayName', name_j);
end
yline(0, '--', 'Color', black, 'LineWidth', 0.8, 'HandleVisibility', 'off');
xline(0, '--', 'Color', black, 'LineWidth', 0.8, 'HandleVisibility', 'off');
xlim([zoom_lo, zoom_hi]);
xlabel('Riqueza, a');
ylabel('Ahorro, s_j(a)');
legend('Location', 'northeast', 'Interpreter', 'tex');
moll_axis(gca);
moll_caption(fig, 'Figura: politica de ahorro por productividad');
save_png_local(fig, fullfile(moll_dir, 'moll_savings_policy.png'), 300);

fig = moll_figure([78 78 760 560]);
hold on;
for jj = 1:numel(idx_legend_z)
    j = idx_legend_z(jj);
    [col_j, style_j, lw_j] = moll_z_line_style(j, Ns, z(j));
    name_j = sprintf('g_%d(a)', jj);
    mass_j = da * sum(g(:, j));
    pdf_j = g(:, j) / max(mass_j * da, 1e-12);
    plot(a, pdf_j, style_j, 'Color', col_j, 'LineWidth', lw_j, ...
        'DisplayName', name_j);
end
xline(0, '--', 'Color', black, 'LineWidth', 0.8, 'HandleVisibility', 'off');
xlim([zoom_lo, zoom_hi]);
xlabel('Riqueza, a');
ylabel('Densidades, g_j(a)');
legend('Location', 'northeast', 'Interpreter', 'tex');
moll_axis(gca);
moll_caption(fig, 'Figura: distribucion de riqueza por productividad');
save_png_local(fig, fullfile(moll_dir, 'moll_wealth_distribution_by_z.png'), 300);

% 2. Consumption policy.
fig = moll_figure([90 90 1180 520]);
tiledlayout(fig, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile;
hold on;
for jj = 1:numel(idx_legend_z)
    j = idx_legend_z(jj);
    [col_j, style_j, lw_j] = moll_z_line_style(j, Ns, z(j));
    if j == j_low
        name_j = sprintf('c(a,z_{min}=%.2f)', z(j));
    elseif j == j_high
        name_j = sprintf('c(a,z_{max}=%.2f)', z(j));
    else
        name_j = sprintf('c(a,z=%.2f)', z(j));
    end
    plot(a, c(:, j), style_j, 'Color', col_j, 'LineWidth', lw_j, ...
        'DisplayName', name_j);
end
xlim([zoom_lo, zoom_hi]);
xlabel('Riqueza, a');
ylabel('Consumo efectivo CES, c(a)', 'Interpreter', 'tex');
legend('Location', 'northwest', 'Interpreter', 'tex');
moll_axis(gca);

nexttile;
hold on;
for jj = 1:numel(idx_legend_z)
    j = idx_legend_z(jj);
    [col_j, style_j, lw_j] = moll_z_line_style(j, Ns, z(j));
    if j == j_low
        name_j = sprintf('e(a,z_{min}=%.2f)', z(j));
    elseif j == j_high
        name_j = sprintf('e(a,z_{max}=%.2f)', z(j));
    else
        name_j = sprintf('e(a,z=%.2f)', z(j));
    end
    plot(a, exp_cons(:, j), style_j, 'Color', col_j, 'LineWidth', lw_j, ...
        'DisplayName', name_j);
end
xlim([zoom_lo, zoom_hi]);
xlabel('Riqueza, a');
ylabel('Gasto monetario, e(a) = c_F + p_I c_I', 'Interpreter', 'tex');
legend('Location', 'northwest', 'Interpreter', 'tex');
moll_axis(gca);
moll_caption(fig, 'Figura: consumo efectivo CES (izq) y gasto monetario c_F+p_I c_I (der) por riqueza');
save_png_local(fig, fullfile(moll_dir, 'moll_consumption_policy.png'), 300);

% 2b. Moll-style policy cuts: consumption and total labor supply by wealth.
fig = moll_figure([95 95 1180 520]);
tiledlayout(fig, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile;
hold on;
for jj = 1:numel(idx_legend_z)
    j = idx_legend_z(jj);
    [col_j, style_j, lw_j] = moll_z_line_style(j, Ns, z(j));
    name_j = sprintf('c_%d(a)', jj);
    plot(a, c(:, j), style_j, 'Color', col_j, 'LineWidth', lw_j, ...
        'DisplayName', name_j);
end
xlim([zoom_lo, zoom_hi]);
xlabel('Riqueza, a');
ylabel('Consumo efectivo');
moll_axis(gca);
legend('Location', 'northwest', 'Interpreter', 'tex');

nexttile;
hold on;
for jj = 1:numel(idx_legend_z)
    j = idx_legend_z(jj);
    [col_j, style_j, lw_j] = moll_z_line_style(j, Ns, z(j));
    if j == j_low
        name_j = sprintf('l(a,z bajo=%.2f)', z(j));
    elseif j == j_high
        name_j = sprintf('l(a,z alto=%.2f)', z(j));
    else
        name_j = sprintf('l(a,z=%.2f)', z(j));
    end
    plot(a, ell_F(:, j) + ell_I(:, j), style_j, 'Color', col_j, ...
        'LineWidth', lw_j, 'DisplayName', name_j);
end
xlim([zoom_lo, zoom_hi]);
xlabel('Riqueza, a');
ylabel('Oferta laboral total');
moll_axis(gca);
legend('Location', 'best', 'Interpreter', 'tex');
moll_caption(fig, 'Figura: funciones de politica de consumo y oferta laboral');
save_png_local(fig, fullfile(moll_dir, 'moll_consumption_labor_policy_by_wealth.png'), 300);

% 3. Labor policy cuts: low, middle and high OU nodes.
fig = moll_figure([105 105 1180 520]);
tiledlayout(fig, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile;
hold on;
for jj = 1:numel(idx_legend_z)
    j = idx_legend_z(jj);
    [col_j, style_j, lw_j, name_j] = moll_z_line_style(j, Ns, z(j));
    plot(a, ell_F(:, j), style_j, 'Color', col_j, 'LineWidth', lw_j, ...
        'DisplayName', name_j);
end
xlim([zoom_lo, zoom_hi]);
xlabel('Riqueza, a');
ylabel('Horas formales elegidas');
moll_axis(gca);
legend('Location', 'best');

nexttile;
hold on;
for jj = 1:numel(idx_legend_z)
    j = idx_legend_z(jj);
    [col_j, style_j, lw_j, name_j] = moll_z_line_style(j, Ns, z(j));
    plot(a, ell_I(:, j), style_j, 'Color', col_j, 'LineWidth', lw_j, ...
        'DisplayName', name_j);
end
xlim([zoom_lo, zoom_hi]);
xlabel('Riqueza, a');
ylabel('Horas informales elegidas');
moll_axis(gca);
legend('Location', 'best');
moll_caption(fig, 'Politicas laborales por riqueza: z bajo, medio y alto');
save_png_local(fig, fullfile(moll_dir, 'moll_labor_policy_by_wealth.png'), 300);

% 3c. Total labor supply by wealth and average labor by productivity.
fig = moll_figure([108 108 1180 520]);
tiledlayout(fig, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile;
hold on;
for jj = 1:numel(idx_legend_z)
    j = idx_legend_z(jj);
    [col_j, style_j, lw_j, name_j] = moll_z_line_style(j, Ns, z(j));
    plot(a, ell_F(:, j) + ell_I(:, j), style_j, 'Color', col_j, ...
        'LineWidth', lw_j, 'DisplayName', name_j);
end
xlim([zoom_lo, zoom_hi]);
xlabel('Riqueza, a');
ylabel('Horas totales elegidas');
moll_axis(gca);
legend('Location', 'best');

nexttile;
plot(z, mean_ellTot_by_z, '-', 'Color', black, 'LineWidth', 1.8, ...
    'Marker', 'o', 'MarkerSize', 5, 'DisplayName', 'Horas totales');
hold on;
plot(z, mean_ellF_by_z, '-', 'Color', blue, 'LineWidth', 1.8, ...
    'Marker', 'o', 'MarkerSize', 5, 'DisplayName', 'Horas formales');
plot(z, mean_ellI_by_z, '--', 'Color', red, 'LineWidth', 1.8, ...
    'Marker', 's', 'MarkerSize', 5, 'DisplayName', 'Horas informales');
xlabel('Productividad, z');
ylabel('Horas promedio por estado z');
moll_axis(gca);
legend('Location', 'best');
moll_caption(fig, 'Oferta laboral total y composicion por productividad');
save_png_local(fig, fullfile(moll_dir, 'moll_labor_supply_by_productivity.png'), 300);

% 4. OU stationary masses. KFE and OU masses should match in stationary equilibrium.
fig = moll_figure([110 110 760 560]);
x = 1:Ns;
b = bar(x, pi_z_ar(:), 0.58);
b.FaceColor = blue;
b.EdgeColor = blue;
hold on;
plot(x, mass_z_model(:), 's', 'Color', red, 'MarkerFaceColor', 'white', ...
    'LineWidth', 1.8, 'MarkerSize', 6, 'DisplayName', 'Masa KFE del modelo');
set(gca, 'XTick', x, 'XTickLabel', z_tick_labels(z), 'TickLabelInterpreter', 'none');
xlabel('Estado de productividad, z');
ylabel('Masa');
max_mass_gap = max(abs(pi_z_ar(:) - mass_z_model(:)));
legend({'Masa invariante OU', 'Masa KFE del modelo'}, 'Location', 'northeast');
text(0.02, 0.94, sprintf('rho=%.3f, sd(log z)=%.3f', ...
    read_scalar_from_context(ctx, {'rho_z_ar'}, NaN), ...
    read_scalar_from_context(ctx, {'sd_logz_ar'}, NaN)), ...
    'Units', 'normalized', 'FontName', 'Times New Roman', 'FontSize', 11, ...
    'Interpreter', 'none', 'VerticalAlignment', 'top');
text(0.02, 0.88, sprintf('max |masa_KFE - masa_OU| = %.1e', max_mass_gap), ...
    'Units', 'normalized', 'FontName', 'Times New Roman', 'FontSize', 11, ...
    'Interpreter', 'none', 'VerticalAlignment', 'top');
moll_axis(gca);
moll_caption(fig, 'Masa estacionaria del proceso Ornstein-Uhlenbeck');
save_png_local(fig, fullfile(moll_dir, 'moll_ou_stationary_masses.png'), 300);

% 5. Conditional moments by productivity.
fig = moll_figure([120 120 1180 520]);
tiledlayout(fig, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile;
plot(z, mean_a_by_z, '-o', 'Color', blue, 'LineWidth', 2.0, 'MarkerSize', 5);
xlabel('Productividad, z');
ylabel('Activos promedio');
moll_axis(gca);

nexttile;
plot(z, mean_exp_by_z, '--s', 'Color', red, 'LineWidth', 2.0, 'MarkerSize', 5);
xlabel('Productividad, z');
ylabel('Gasto promedio');
moll_axis(gca);
moll_caption(fig, 'Activos y gasto promedio por productividad');
save_png_local(fig, fullfile(moll_dir, 'moll_conditional_moments_by_z.png'), 300);

% 5b. Intensive-margin informality by productivity.
fig = moll_figure([123 123 760 560]);
plot(z, informal_share_by_z, '-', 'Color', red, 'LineWidth', 2.0, ...
    'Marker', 's', 'MarkerSize', 5, 'DisplayName', 'Horas informales / horas totales');
hold on;
plot(z, form_share_by_z, '-', 'Color', blue, 'LineWidth', 2.0, ...
    'Marker', 'o', 'MarkerSize', 5, 'DisplayName', 'Horas formales / horas totales');
ylim([0 1]);
xlabel('Productividad, z');
ylabel('Participacion de horas');
legend('Location', 'best');
moll_axis(gca);
moll_caption(fig, 'Figura: informalidad y formalidad en margen intensivo por productividad');
save_png_local(fig, fullfile(moll_dir, 'moll_informality_by_z.png'), 300);

mean_a_debt_by_z = NaN(1, Ns);
for jz = 1:Ns
    mask_neg = (a < 0);
    w_neg_j = g(mask_neg, jz) * da;
    w_neg_tot = sum(w_neg_j);
    if w_neg_tot > 1e-12
        mean_a_debt_by_z(jz) = sum(a(mask_neg) .* w_neg_j) / w_neg_tot;
    end
end

fig = moll_figure([124 124 1100 500]);
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile;
plot(z, mass_debt_by_z, '--s', 'Color', red, 'LineWidth', 2.0, 'MarkerSize', 5);
ylim([0, min(1, max(0.05, 1.15 * max(mass_debt_by_z(:))))]);
xlabel('Productividad, z');
ylabel('Pr(a<0|z)');
title('Fracción en deuda por z', 'Interpreter', 'none');
moll_axis(gca);
nexttile;
plot(z, mean_a_debt_by_z, '--s', 'Color', blue, 'LineWidth', 2.0, 'MarkerSize', 5);
xlabel('Productividad, z');
ylabel('E[a | a<0, z]');
title('Deuda media condicional por z', 'Interpreter', 'none');
moll_axis(gca);
moll_caption(fig, 'Figura: endeudamiento por productividad — fracción y media condicional');
save_png_local(fig, fullfile(moll_dir, 'moll_debt_probability_by_z.png'), 300);

% 6. Consumption distributions.
w_all = g(:) * da;
[xCpdf, pdfC] = weighted_pdf_local(c(:), w_all, 70);
[xEpdf, pdfE] = weighted_pdf_local(exp_cons(:), w_all, 70);
fig = moll_figure([130 130 760 560]);
plot(xCpdf, pdfC, '-', 'Color', blue, 'LineWidth', 2.0, 'DisplayName', 'Consumo efectivo C');
hold on;
plot(xEpdf, pdfE, '--', 'Color', red, 'LineWidth', 2.0, 'DisplayName', 'Gasto');
xlabel('Consumo / gasto');
ylabel('Densidad');
legend('Location', 'northeast');
moll_axis(gca);
moll_caption(fig, 'Distribucion estacionaria de consumo y gasto');
save_png_local(fig, fullfile(moll_dir, 'moll_consumption_distribution.png'), 300);

% 7. Formal vs informal consumption components.
[xF, pdfF] = weighted_pdf_local(c_F(:), w_all, 70);
[xI, pdfI] = weighted_pdf_local(p_I_val * c_I(:), w_all, 70);
fig = moll_figure([140 140 760 560]);
plot(xF, pdfF, '-', 'Color', blue, 'LineWidth', 2.0, 'DisplayName', 'c_F');
hold on;
plot(xI, pdfI, '--', 'Color', red, 'LineWidth', 2.0, 'DisplayName', 'p_I c_I');
xlabel('Gasto por componente');
ylabel('Densidad');
legend('Location', 'northeast');
moll_axis(gca);
moll_caption(fig, 'Distribucion de componentes de consumo formal e informal');
save_png_local(fig, fullfile(moll_dir, 'moll_consumption_components_distribution.png'), 300);

% 7b. Formal/informal consumption components by productivity.
fig = moll_figure([145 145 1180 520]);
tiledlayout(fig, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile;
plot(z, mean_cF_by_z, '-', 'Color', blue, 'LineWidth', 2.0, ...
    'Marker', 'o', 'MarkerSize', 5, 'DisplayName', 'Consumo formal');
hold on;
plot(z, mean_pIcI_by_z, '--', 'Color', red, 'LineWidth', 2.0, ...
    'Marker', 's', 'MarkerSize', 5, 'DisplayName', 'Gasto informal');
xlabel('Productividad, z');
ylabel('Media condicional por z');
legend('Location', 'northwest');
moll_axis(gca);

nexttile;
plot(z, share_cF_by_z, '-', 'Color', blue, 'LineWidth', 2.0, ...
    'Marker', 'o', 'MarkerSize', 5, 'DisplayName', 'Participacion formal');
hold on;
plot(z, share_pIcI_by_z, '--', 'Color', red, 'LineWidth', 2.0, ...
    'Marker', 's', 'MarkerSize', 5, 'DisplayName', 'Participacion informal');
ylim([0 1]);
xlabel('Productividad, z');
ylabel('Participacion en el gasto total');
legend('Location', 'best');
moll_axis(gca);
moll_caption(fig, 'Consumo formal e informal por productividad');
save_png_local(fig, fullfile(moll_dir, 'moll_consumption_components_by_z.png'), 300);

% 7c. Debt premium and inequality gradients by productivity.
fig = moll_figure([148 148 1180 520]);
tiledlayout(fig, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile;
plot(z, 100 * debt_spread_z, '--s', 'Color', red, 'LineWidth', 2.0, ...
    'MarkerSize', 5, 'DisplayName', 'Prima de deuda');
xlabel('Productividad, z');
ylabel('Prima sobre deuda, p.p.');
legend('Location', 'best');
moll_axis(gca);

nexttile;
plot(z, gini_C_by_z, '-', 'Color', blue, 'LineWidth', 2.0, ...
    'Marker', 'o', 'MarkerSize', 5, 'DisplayName', 'Gini consumo efectivo');
hold on;
plot(z, gini_exp_by_z, '--', 'Color', red, 'LineWidth', 2.0, ...
    'Marker', 's', 'MarkerSize', 5, 'DisplayName', 'Gini gasto');
ylim([0, max(0.05, 1.15 * max([gini_C_by_z(:); gini_exp_by_z(:)]))]);
xlabel('Productividad, z');
ylabel('Desigualdad dentro de cada z');
legend('Location', 'best');
moll_axis(gca);
moll_caption(fig, 'Prima de deuda y gradiente de desigualdad por productividad');
save_png_local(fig, fullfile(moll_dir, 'moll_debt_premium_inequality_by_z.png'), 300);

% 8. Lorenz/Gini curves. Recompute if the solver did not store them.
[pop_a, lorenz_a_plot, gini_a_plot] = lorenz_from_context_or_data(ctx, ...
    'cum_pop_a', 'lorenz_a', 'Gini_a', aa(:), w_all, false);
[pop_c, lorenz_c_plot, gini_c_plot] = lorenz_from_context_or_data(ctx, ...
    'cum_pop_c', 'lorenz_c', 'Gini_c', exp_cons(:), w_all, true);
if ~isempty(pop_a) || ~isempty(pop_c)
    fig = moll_figure([150 150 900 560]);
    plot([0 1], [0 1], ':', 'Color', gray, 'LineWidth', 1.2, 'DisplayName', 'Linea de 45 grados');
    hold on;
    if ~isempty(pop_a)
        plot([0; pop_a(:)], [0; lorenz_a_plot(:)], '-', 'Color', blue, 'LineWidth', 2.0, ...
            'DisplayName', sprintf('Riqueza neta, Gini=%.3f', gini_a_plot));
    end
    if ~isempty(pop_c)
        plot([0; pop_c(:)], [0; lorenz_c_plot(:)], '--', 'Color', red, 'LineWidth', 2.0, ...
            'DisplayName', sprintf('Gasto, Gini=%.3f', gini_c_plot));
    end
    xlabel('Poblacion acumulada');
    ylabel('Participacion acumulada');
    xlim([0 1]);
    ylim([0 1]);
    legend('Location', 'northwest');
    moll_axis(gca);
    moll_caption(fig, 'Curvas de Lorenz y coeficientes de Gini');
    save_png_local(fig, fullfile(moll_dir, 'moll_lorenz_curves.png'), 300);

    fid_lorenz = fopen(fullfile(moll_dir, 'moll_lorenz_curves.txt'), 'w');
    if fid_lorenz >= 0
        fprintf(fid_lorenz, 'Lorenz/Gini model output\n');
        fprintf(fid_lorenz, 'source_mat=%s\n', mat_file);
        fprintf(fid_lorenz, 'Gini_wealth_net_assets=%.10f\n', gini_a_plot);
        fprintf(fid_lorenz, 'Gini_expenditure=%.10f\n', gini_c_plot);
        fprintf(fid_lorenz, 'note_wealth=wealth uses net assets a; if a includes debt, the Lorenz curve can go below zero.\n');
        fprintf(fid_lorenz, 'note_expenditure=expenditure is c_F + p_I*c_I and is the cleaner object for inequality comparison.\n');
        fclose(fid_lorenz);
    end
end

% 9. Equilibrium curves if the .mat contains them.
r_grid = read_matrix_from_context(ctx, 'r_grid', []);
S = read_matrix_from_context(ctx, 'S', []);
KD = read_matrix_from_context(ctx, 'KD', []);
if ~isempty(r_grid) && ~isempty(S) && ~isempty(KD)
    rr = r_grid(:);
    fig = moll_figure([160 160 760 560]);
    plot(rr, S(:), '-', 'Color', blue, 'LineWidth', 2.0, 'DisplayName', 'Oferta de activos');
    hold on;
    plot(rr, KD(:), '--', 'Color', red, 'LineWidth', 2.0, 'DisplayName', 'Demanda de capital');
    xlabel('Tasa de interes, r');
    ylabel('Nivel agregado: S(r) y K^D(r)');
    legend('Location', 'best');
    moll_axis(gca);
    moll_caption(fig, 'Equilibrio estacionario en el mercado de activos');
    save_png_local(fig, fullfile(moll_dir, 'moll_equilibrium_asset_market.png'), 300);
end

close all;
end

function files = make_include_ou_mechanism_figure(mat_file, mat_tag, out_dir, z, pi_z_ar, ...
    mass_z_model, mean_a_by_z, mean_exp_by_z, mass_debt_by_z, form_share_by_z, ...
    debt_spread_z, ctx)
% Compact figure meant for slides/thesis: one page, mechanism first.

Ns = numel(z);
T4_data = read_scalar_from_context(ctx, {'T4_data'}, NaN);
Tkz_data = read_scalar_from_context(ctx, {'T_kappa_z_data'}, NaN);
rho_z = read_scalar_from_context(ctx, {'rho_z_ar'}, NaN);
sd_z = read_scalar_from_context(ctx, {'sd_logz_ar'}, NaN);
chi = read_scalar_from_context(ctx, {'debt_prem_chi'}, NaN);
eta = read_scalar_from_context(ctx, {'debt_prem_eta'}, NaN);
amin_val = read_scalar_from_context(ctx, {'amin'}, NaN);

fig = figure('Color','white','Position',[70 70 1450 900]);
tiledlayout(fig, 2, 2, 'TileSpacing','compact', 'Padding','compact');

nexttile;
bar(1:Ns, [pi_z_ar(:), mass_z_model(:)], 'grouped');
set(gca, 'XTick', 1:Ns, 'XTickLabel', z_tick_labels(z), 'TickLabelInterpreter','none');
xlabel('Estado de productividad z', 'Interpreter','none');
ylabel('Masa', 'Interpreter','none');
title(sprintf('Proceso OU discretizado: rho=%.3f, sd(log z)=%.3f', rho_z, sd_z), ...
    'Interpreter','none');
legend({'Ergodica OU','Estacionaria modelo'}, 'Location','best', 'Interpreter','none');
grid on;

nexttile;
yyaxis left;
plot(z, debt_spread_z, '-o', 'LineWidth', 2.2, 'MarkerSize', 5, ...
    'DisplayName','spread_b(z)');
ylabel('Prima anual sobre deuda', 'Interpreter','none');
yyaxis right;
plot(z, mass_debt_by_z, '--s', 'LineWidth', 2.2, 'MarkerSize', 5, ...
    'DisplayName','Pr(a<0 | z)');
ylabel('Pr(a<0 | z)', 'Interpreter','none');
xlabel('Productividad z', 'Interpreter','none');
title(sprintf('Prima de deuda por z: chi=%.3f, eta=%.2f, amin=%.2f', chi, eta, amin_val), ...
    'Interpreter','none');
grid on;

nexttile;
plot(z, form_share_by_z, '-o', 'Color', [0.05 0.43 0.65], ...
    'LineWidth', 2.2, 'MarkerSize', 5, 'DisplayName','Share formal por z');
hold on;
if isfinite(T4_data)
    yline(1 - T4_data, '--', 'Color', [0.45 0.45 0.45], ...
        'LineWidth', 1.2, 'DisplayName','Share formal agregado target');
end
if all(isfinite(form_share_by_z([1 end]))) && isfinite(Tkz_data)
    text(z(1), max(0.02, form_share_by_z(1)), ...
        sprintf(' gap zmax-zmin=%.3f | target=%.3f', form_share_by_z(end)-form_share_by_z(1), Tkz_data), ...
        'FontSize', 9, 'Interpreter','none', 'VerticalAlignment','bottom');
end
xlabel('Productividad z', 'Interpreter','none');
ylabel('Horas formales / horas trabajadas', 'Interpreter','none');
title('Sorting sectorial: productividad alta trabaja mas formal', 'Interpreter','none');
ylim([0 1]);
legend('Location','best', 'Interpreter','none');
grid on;

nexttile;
yyaxis left;
plot(z, mean_a_by_z, '-o', 'LineWidth', 2.2, 'MarkerSize', 5, ...
    'DisplayName','E[a | z]');
ylabel('Activos medios E[a | z]', 'Interpreter','none');
yyaxis right;
plot(z, mean_exp_by_z, '--s', 'LineWidth', 2.2, 'MarkerSize', 5, ...
    'DisplayName','E[gasto | z]');
ylabel('Gasto medio E[c_F+p_I c_I | z]', 'Interpreter','none');
xlabel('Productividad z', 'Interpreter','none');
title('Gradiente estacionario de activos y gasto por productividad', 'Interpreter','none');
grid on;

sgtitle(sprintf('Mecanismo OU + prima de deuda dependiente de z | %s', mat_tag), ...
    'Interpreter','none', 'FontWeight','bold');

png_file = fullfile(out_dir, sprintf('figure_include_ou_mechanism_%s.png', mat_tag));
save_png_local(fig, png_file, 300);

txt_file = fullfile(out_dir, sprintf('figure_include_ou_mechanism_%s.txt', mat_tag));
fid = fopen(txt_file, 'w');
if fid >= 0
    fprintf(fid, 'Include-ready OU mechanism figure\n');
    fprintf(fid, 'mat_file=%s\n', mat_file);
    fprintf(fid, 'png_file=%s\n', png_file);
    fprintf(fid, 'recommended_use=slides_or_thesis_mechanism_section\n');
    fprintf(fid, 'axis_audit=include_safe: horizontal axes are exogenous productivity z or OU state index; endogenous variables appear only as outcomes.\n');
    fprintf(fid, 'reading=OU process is exogenous; low-z states face higher borrowing spread; formal share, assets, and expenditure gradients show whether the mechanism is economically visible.\n');
    fprintf(fid, 'rho_z_ar=%.10f\n', rho_z);
    fprintf(fid, 'sd_logz_ar=%.10f\n', sd_z);
    fprintf(fid, 'debt_prem_chi=%.10f\n', chi);
    fprintf(fid, 'debt_prem_eta=%.10f\n', eta);
    fprintf(fid, 'amin=%.10f\n', amin_val);
    fprintf(fid, 'z mass_ou mass_model debt_spread debt_share formal_share mean_assets mean_expenditure\n');
    for j = 1:Ns
        fprintf(fid, '%.10f %.10f %.10f %.10f %.10f %.10f %.10f %.10f\n', ...
            z(j), pi_z_ar(j), mass_z_model(j), debt_spread_z(j), mass_debt_by_z(j), ...
            form_share_by_z(j), mean_a_by_z(j), mean_exp_by_z(j));
    end
    fclose(fid);
end

files = struct('png', png_file, 'txt', txt_file);
end

function files = make_trap_diagnostics(mat_file, mat_tag, out_dir, a, z, aa, zz, g, da, ...
    c, c_F, c_I, exp_cons, debt_spread_aa, debt_spread_z, ctx)
% Diagnostics that help evaluate poverty/informality trap mechanisms.

[I, Ns] = size(g);
g_marg_a = sum(g, 2);
cdf_a = cumsum(g_marg_a) * da;
[qshare, qcuts] = weighted_quintile_shares(aa, g, da, 5);
qlabels = {'Q1','Q2','Q3','Q4','Q5'};

has_labor = isfield(ctx, 'ell_F') && isfield(ctx, 'ell_I');
if has_labor
    ell_F = ctx.ell_F;
    ell_I = ctx.ell_I;
else
    ell_F = NaN(I,Ns);
    ell_I = NaN(I,Ns);
end
kappa_F_aa = read_matrix_from_context(ctx, 'kappa_F_aa', zeros(I,Ns));
qq_informal = read_matrix_from_context(ctx, 'qq_informal', ones(I,Ns));

w_F = read_scalar_from_context(ctx, {'w_F_star','w_F'}, NaN);
w_I_hh = read_scalar_from_context(ctx, {'w_I_household_star','w_I_star','w_I'}, NaN);
theta = read_scalar_from_context(ctx, {'theta'}, 1);
nu_I = read_scalar_from_context(ctx, {'nu_I'}, 1);
r_eq = read_scalar_from_context(ctx, {'r_star','r_eq','r'}, 0);
tau = read_scalar_from_context(ctx, {'tau'}, 0);
T_lump = read_scalar_from_context(ctx, {'T_eq','T_star','T'}, 0);
Pi_lump = read_scalar_from_context(ctx, {'Pi_lump_star'}, NaN);
if ~isfinite(Pi_lump)
    profit_rule = read_char_from_context(ctx, 'informal_profit_rule', 'lump');
    if strcmpi(profit_rule, 'lump')
        Pi_lump = read_scalar_from_context(ctx, {'profit_I_star'}, 0);
    else
        Pi_lump = 0;
    end
end

if has_labor && isfinite(w_F) && isfinite(w_I_hh)
    income_formal = ((1 - tau) * w_F * zz - kappa_F_aa) .* ell_F;
    income_informal = w_I_hh * theta * (zz .^ nu_I) .* qq_informal .* ell_I;
    adot = income_formal + income_informal + r_eq * aa ...
        - debt_spread_aa .* max(-aa, 0) + T_lump + Pi_lump - exp_cons;
else
    income_formal = NaN(I,Ns);
    income_informal = NaN(I,Ns);
    adot = NaN(I,Ns);
end

Q_mass = zeros(5,1);
Q_mean_a = zeros(5,1);
Q_mean_exp = zeros(5,1);
Q_informal = zeros(5,1);
Q_formal = zeros(5,1);
Q_debt = zeros(5,1);
Q_adot = zeros(5,1);
Q_share_lowz = zeros(5,1);
z_low_cut = z(max(1, ceil(Ns/3)));
lowz_mask = z <= z_low_cut;

for q = 1:5
    gm = g .* qshare{q};
    Q_mass(q) = da * sum(gm(:));
    Q_mean_a(q) = da * sum(sum(gm .* aa)) / max(Q_mass(q), 1e-12);
    Q_mean_exp(q) = da * sum(sum(gm .* exp_cons)) / max(Q_mass(q), 1e-12);
    Q_debt(q) = da * sum(sum(gm .* (aa < 0))) / max(Q_mass(q), 1e-12);
    Q_share_lowz(q) = da * sum(sum(gm(:,lowz_mask))) / max(Q_mass(q), 1e-12);
    if has_labor
        ellF_q = da * sum(sum(gm .* ell_F)) / max(Q_mass(q), 1e-12);
        ellI_q = da * sum(sum(gm .* ell_I)) / max(Q_mass(q), 1e-12);
        Q_formal(q) = ellF_q / max(ellF_q + ellI_q, 1e-12);
        Q_informal(q) = ellI_q / max(ellF_q + ellI_q, 1e-12);
    else
        Q_formal(q) = NaN;
        Q_informal(q) = NaN;
    end
    Q_adot(q) = da * sum(sum(gm .* adot)) / max(Q_mass(q), 1e-12);
end

wealth_by_z = zeros(Ns, 5);
for j = 1:Ns
    mass_j = da * sum(g(:,j));
    for q = 1:5
        wealth_by_z(j,q) = da * sum(g(:,j) .* qshare{q}(:,j)) / max(mass_j, 1e-12);
    end
end

idx_show = unique([1 max(1, round((Ns+1)/2)) Ns], 'stable');
z_colors = [0.77 0.18 0.14; 0.35 0.35 0.35; 0.05 0.43 0.65];
if numel(idx_show) == 2
    z_colors = z_colors([1 3], :);
elseif numel(idx_show) == 1
    z_colors = z_colors(2, :);
end

w_all = g(:) * da;
if has_labor
    inf_dom = ell_I(:) > ell_F(:);
    form_dom = ell_F(:) >= ell_I(:);
else
    inf_dom = false(numel(g),1);
    form_dom = false(numel(g),1);
end
[x_inf, pdf_inf] = weighted_pdf_local(exp_cons(:), w_all .* double(inf_dom), 55);
[x_for, pdf_for] = weighted_pdf_local(exp_cons(:), w_all .* double(form_dom), 55);
[x_all, pdf_all] = weighted_pdf_local(exp_cons(:), w_all, 55);

support_score = 0;
checks = {};
checks{end+1} = sprintf('E[a|z_max]-E[a|z_min]=%.3f', z_conditional_gap(a, g, da, z, 'assets'));
if z_conditional_gap(a, g, da, z, 'assets') > 0, support_score = support_score + 1; end
checks{end+1} = sprintf('Pr(a<0|z_min)-Pr(a<0|z_max)=%.3f', ...
    z_debt_gap(a, g, da));
if z_debt_gap(a, g, da) > 0, support_score = support_score + 1; end
checks{end+1} = sprintf('Informalidad Q1-Q5=%.3f', Q_informal(1) - Q_informal(5));
if Q_informal(1) - Q_informal(5) > 0.05, support_score = support_score + 1; end
checks{end+1} = sprintf('Share low-z Q1-Q5=%.3f', Q_share_lowz(1) - Q_share_lowz(5));
if Q_share_lowz(1) - Q_share_lowz(5) > 0.05, support_score = support_score + 1; end
if Q_adot(1) <= Q_adot(5)
    support_score = support_score + 1;
end
checks{end+1} = sprintf('Drift activos Q1-Q5=%.4f', Q_adot(1) - Q_adot(5));

if support_score >= 4
    verdict = 'Gradientes por riqueza: marcados (4-5 de 5 criterios)';
elseif support_score >= 2
    verdict = 'Gradientes por riqueza: parciales (2-3 de 5 criterios)';
else
    verdict = 'Gradientes por riqueza: debiles (0-1 de 5 criterios)';
end

fig = figure('Color','white','Position',[60 60 1550 980]);
tiledlayout(fig, 3, 2, 'TileSpacing','compact', 'Padding','compact');

nexttile;
bar(1:5, [Q_informal, Q_debt, Q_share_lowz], 'grouped');
set(gca, 'XTick', 1:5, 'XTickLabel', qlabels, 'TickLabelInterpreter','none');
ylabel('Proporcion', 'Interpreter','none');
xlabel('Quintil de riqueza', 'Interpreter','none');
title('Informalidad, deuda y productividad baja por quintil de riqueza', 'Interpreter','none');
legend({'Share informal','Pr(a<0)','Share z bajo'}, 'Location','best', 'Interpreter','none');
ylim([0, max(1, 1.05 * max([Q_informal; Q_debt; Q_share_lowz]))]);
grid on;

nexttile;
yyaxis left;
plot(1:5, Q_mean_exp, '-o', 'LineWidth', 2.0);
ylabel('Gasto medio', 'Interpreter','none');
yyaxis right;
plot(1:5, Q_mean_a, '--s', 'LineWidth', 2.0);
ylabel('Riqueza media', 'Interpreter','none');
set(gca, 'XTick', 1:5, 'XTickLabel', qlabels, 'TickLabelInterpreter','none');
xlabel('Quintil de riqueza', 'Interpreter','none');
title('Consumo/gasto y activos por quintil de riqueza', 'Interpreter','none');
grid on;

nexttile;
hold on;
for kk = 1:numel(idx_show)
    j = idx_show(kk);
    plot(a, adot(:,j), 'LineWidth', 2.0, 'Color', z_colors(kk,:), ...
        'DisplayName', sprintf('z=%.2f', z(j)));
end
yline(0, ':', 'Color', [0.25 0.25 0.25], 'HandleVisibility','off');
for k = 1:4
    xline(qcuts(k), ':', 'Color', [0.55 0.55 0.55], 'HandleVisibility','off');
end
xlabel('Riqueza neta a', 'Interpreter','none');
ylabel('Drift de activos adot(a,z)', 'Interpreter','none');
title('Dinámica local: cruces de drift por productividad', 'Interpreter','none');
legend('Location','best', 'Interpreter','none');
grid on;

nexttile;
imagesc(wealth_by_z);
cb = colorbar;
cb.Label.String = 'Pr(quintil riqueza | z)';
set(gca, 'XTick', 1:5, 'XTickLabel', qlabels, ...
    'YTick', 1:Ns, 'YTickLabel', z_tick_labels(z), ...
    'TickLabelInterpreter','none');
xlabel('Quintil de riqueza', 'Interpreter','none');
ylabel('Estado OU z', 'Interpreter','none');
title('Concentracion estacionaria: productividad vs riqueza', 'Interpreter','none');

nexttile;
plot(x_all, pdf_all, '-', 'Color', [0.25 0.25 0.25], 'LineWidth', 1.8, 'DisplayName','Total');
hold on;
plot(x_inf, pdf_inf, '--', 'Color', [0.82 0.32 0.12], 'LineWidth', 2.2, 'DisplayName','Dominante informal');
plot(x_for, pdf_for, '-', 'Color', [0.05 0.43 0.65], 'LineWidth', 2.2, 'DisplayName','Dominante formal');
xlabel('Gasto c_F + p_I c_I', 'Interpreter','none');
ylabel('Densidad ponderada', 'Interpreter','none');
title('Distribucion de gasto por sector dominante', 'Interpreter','none');
legend('Location','best', 'Interpreter','none');
grid on;

nexttile;
axis off;
text(0.02, 0.90, verdict, 'FontSize', 14, 'FontWeight','bold', 'Interpreter','none');
text(0.02, 0.76, sprintf('Criterios descriptivos presentes: %d/5', support_score), ...
    'FontSize', 11, 'Interpreter','none');
for k = 1:numel(checks)
    text(0.02, 0.76 - 0.10*k, checks{k}, 'FontSize', 10, 'Interpreter','none');
end
text(0.02, 0.08, ['Lectura: estos paneles describen la asociacion estacionaria entre productividad, ' ...
    'riqueza, deuda, informalidad y acumulacion. Es una asociacion descriptiva: no identifica causalidad ' ...
    'ni multiples equilibrios dinamicos.'], 'FontSize', 9, 'Interpreter','none');

sgtitle(sprintf('Informalidad, deuda y productividad por quintil de riqueza | %s', mat_tag), ...
    'Interpreter','none', 'FontWeight','bold');

png_file = fullfile(out_dir, sprintf('trap_diagnostics_%s.png', mat_tag));
save_png_local(fig, png_file, 300);

txt_file = fullfile(out_dir, sprintf('trap_diagnostics_%s.txt', mat_tag));
fid = fopen(txt_file, 'w');
if fid >= 0
    fprintf(fid, 'Trap diagnostics\n');
    fprintf(fid, 'mat_file=%s\n', mat_file);
    fprintf(fid, 'verdict=%s\n', verdict);
    fprintf(fid, 'support_score=%d/5\n', support_score);
    fprintf(fid, 'q mean_a mean_exp informal_share formal_share debt_share lowz_share mean_adot\n');
    for q = 1:5
        fprintf(fid, '%d %.10f %.10f %.10f %.10f %.10f %.10f %.10f\n', ...
            q, Q_mean_a(q), Q_mean_exp(q), Q_informal(q), Q_formal(q), ...
            Q_debt(q), Q_share_lowz(q), Q_adot(q));
    end
    fprintf(fid, 'z debt_spread Pr_Q1 Pr_Q2 Pr_Q3 Pr_Q4 Pr_Q5\n');
    for j = 1:Ns
        fprintf(fid, '%.10f %.10f %.10f %.10f %.10f %.10f %.10f\n', ...
            z(j), debt_spread_z(j), wealth_by_z(j,1), wealth_by_z(j,2), ...
            wealth_by_z(j,3), wealth_by_z(j,4), wealth_by_z(j,5));
    end
    fclose(fid);
end

files = struct('png', png_file, 'txt', txt_file);
end

function files = make_policy_equilibrium_validation(mat_file, mat_tag, out_dir, a, z, aa, zz, g, da, ...
    c, c_F, c_I, exp_cons, debt_spread_z, ctx)
% Equilibrium, policy functions, Lorenz/Gini and labor allocation.

[I, Ns] = size(g);
has_labor = isfield(ctx, 'ell_F') && isfield(ctx, 'ell_I');
if has_labor
    ell_F = ctx.ell_F;
    ell_I = ctx.ell_I;
else
    ell_F = NaN(I,Ns);
    ell_I = NaN(I,Ns);
end

idx_show = unique([1 max(1, round((Ns+1)/2)) Ns], 'stable');
z_colors = [0.77 0.18 0.14; 0.35 0.35 0.35; 0.05 0.43 0.65];
if numel(idx_show) == 2
    z_colors = z_colors([1 3], :);
elseif numel(idx_show) == 1
    z_colors = z_colors(2, :);
end

p_I_val = read_scalar_from_context(ctx, {'p_I_star','p_I'}, evalin('caller','p_I'));
H_bar = 1;
if evalin('caller', 'exist(''H_bar'', ''var'')')
    H_bar = evalin('caller', 'H_bar');
end

mean_ellF_z = zeros(1,Ns);
mean_ellI_z = zeros(1,Ns);
mean_ocio_z = zeros(1,Ns);
share_formal_z = zeros(1,Ns);
share_informal_z = zeros(1,Ns);
for j = 1:Ns
    mass_j = da * sum(g(:,j));
    if has_labor
        mean_ellF_z(j) = da * sum(g(:,j) .* ell_F(:,j)) / max(mass_j, 1e-12);
        mean_ellI_z(j) = da * sum(g(:,j) .* ell_I(:,j)) / max(mass_j, 1e-12);
        mean_ocio_z(j) = max(H_bar - mean_ellF_z(j) - mean_ellI_z(j), 0);
        worked = mean_ellF_z(j) + mean_ellI_z(j);
        share_formal_z(j) = mean_ellF_z(j) / max(worked, 1e-12);
        share_informal_z(j) = mean_ellI_z(j) / max(worked, 1e-12);
    else
        mean_ellF_z(j) = NaN;
        mean_ellI_z(j) = NaN;
        mean_ocio_z(j) = NaN;
        share_formal_z(j) = NaN;
        share_informal_z(j) = NaN;
    end
end

low = 1;
high = Ns;
labor_rows = [mean_ellF_z([low high])', mean_ellI_z([low high])', mean_ocio_z([low high])'];
sector_rows = [share_formal_z([low high])', share_informal_z([low high])'];

r_star = read_scalar_from_context(ctx, {'r_star'}, NaN);
K_star = read_scalar_from_context(ctx, {'K_star'}, NaN);
L_F_star = read_scalar_from_context(ctx, {'L_F_star'}, NaN);
L_I_star = read_scalar_from_context(ctx, {'L_I_star'}, NaN);
w_F_star = read_scalar_from_context(ctx, {'w_F_star'}, NaN);
w_I_star = read_scalar_from_context(ctx, {'w_I_star'}, NaN);
w_I_hh = read_scalar_from_context(ctx, {'w_I_household_star'}, NaN);
Pi_I = read_scalar_from_context(ctx, {'profit_I_star'}, NaN);
T4_model = read_scalar_from_context(ctx, {'T4_model'}, NaN);
T4_data = read_scalar_from_context(ctx, {'T4_data'}, NaN);
T5_nom = read_scalar_from_context(ctx, {'T5_nom'}, NaN);
T5_data = read_scalar_from_context(ctx, {'T5_data'}, NaN);
Tkz_model = read_scalar_from_context(ctx, {'T_kappa_z_model'}, NaN);
Tkz_data = read_scalar_from_context(ctx, {'T_kappa_z_data'}, NaN);
Gini_a = read_scalar_from_context(ctx, {'Gini_a'}, NaN);
Gini_c = read_scalar_from_context(ctx, {'Gini_c'}, NaN);
ratio_gasto_FI = read_scalar_from_context(ctx, {'ratio_gasto_FI'}, NaN);
TgFI_data = read_scalar_from_context(ctx, {'TgFI_data'}, NaN);
profit_rule = read_char_from_context(ctx, 'informal_profit_rule', 'unknown');
profit_per_LI = Pi_I / max(L_I_star, 1e-12);

fig = figure('Color','white','Position',[45 45 1650 1050]);
tiledlayout(fig, 3, 2, 'TileSpacing','compact', 'Padding','compact');

nexttile;
axis off;
eq_lines = {
    sprintf('r* = %.4f        K* = %.4f', r_star, K_star)
    sprintf('p_I* = %.4f      L_F* = %.4f      L_I* = %.4f', p_I_val, L_F_star, L_I_star)
    sprintf('w_F = %.4f      w_I marginal = %.4f', w_F_star, w_I_star)
    sprintf('w_I_hh = %.4f   Pi_I/L_I = %.4f   regla = %s', w_I_hh, profit_per_LI, profit_rule)
    sprintf('T4 informalidad = %.3f  (dato %.3f)', T4_model, T4_data)
    sprintf('T5 PIB informal nominal = %.3f  (dato %.3f)', T5_nom, T5_data)
    sprintf('Tkz formalidad z_alto-z_bajo = %.3f  (dato %.3f)', Tkz_model, Tkz_data)
    sprintf('Gasto formal/informal = %.3f  (dato %.3f)', ratio_gasto_FI, TgFI_data)
    sprintf('Gini riqueza modelo = %.3f    Gini gasto modelo = %.3f', Gini_a, Gini_c)
    };
text(0.02, 0.94, 'Equilibrio y targets principales', 'FontSize', 15, 'FontWeight','bold', 'Interpreter','none');
for k = 1:numel(eq_lines)
    text(0.03, 0.88 - 0.075*k, eq_lines{k}, 'FontSize', 10.5, 'Interpreter','none');
end
text(0.03, 0.06, 'Validacion externa: Gini de gasto es comparable con gasto/ingreso; Gini de riqueza usa activos netos del modelo.', ...
    'FontSize', 9, 'Interpreter','none');

nexttile;
hold on;
if isfield(ctx, 'lorenz_a') && isfield(ctx, 'cum_pop_a')
    plot([0; ctx.cum_pop_a(:)], [0; ctx.lorenz_a(:)], '-', 'Color', [0.05 0.43 0.65], ...
        'LineWidth', 2.2, 'DisplayName', sprintf('Riqueza neta, Gini=%.3f', Gini_a));
end
if isfield(ctx, 'lorenz_c') && isfield(ctx, 'cum_pop_c')
    plot([0; ctx.cum_pop_c(:)], [0; ctx.lorenz_c(:)], '--', 'Color', [0.82 0.32 0.12], ...
        'LineWidth', 2.2, 'DisplayName', sprintf('Gasto, Gini=%.3f', Gini_c));
end
plot([0 1], [0 1], ':', 'Color', [0.35 0.35 0.35], 'HandleVisibility','off');
xlabel('Fraccion acumulada de hogares', 'Interpreter','none');
ylabel('Fraccion acumulada', 'Interpreter','none');
title('Lorenz/Gini para validacion externa', 'Interpreter','none');
legend('Location','northwest', 'Interpreter','none');
grid on;

nexttile;
hold on;
for kk = 1:numel(idx_show)
    j = idx_show(kk);
    plot(a, c_F(:,j), '-', 'Color', z_colors(kk,:), 'LineWidth', 2.0, ...
        'DisplayName', sprintf('c_F, z=%.2f', z(j)));
    plot(a, p_I_val * c_I(:,j), '--', 'Color', z_colors(kk,:), 'LineWidth', 2.0, ...
        'DisplayName', sprintf('p_I c_I, z=%.2f', z(j)));
end
xlabel('Riqueza neta a', 'Interpreter','none');
ylabel('Consumo/gasto sectorial', 'Interpreter','none');
title('Policy functions: consumo formal e informal', 'Interpreter','none');
legend('Location','best', 'Interpreter','none', 'FontSize', 8);
grid on;

nexttile;
hold on;
for kk = 1:numel(idx_show)
    j = idx_show(kk);
    plot(a, ell_F(:,j), '-', 'Color', z_colors(kk,:), 'LineWidth', 2.0, ...
        'DisplayName', sprintf('ell_F, z=%.2f', z(j)));
    plot(a, ell_I(:,j), '--', 'Color', z_colors(kk,:), 'LineWidth', 2.0, ...
        'DisplayName', sprintf('ell_I, z=%.2f', z(j)));
end
xlabel('Riqueza neta a', 'Interpreter','none');
ylabel('Horas', 'Interpreter','none');
title('Policy functions: horas formal e informal', 'Interpreter','none');
legend('Location','best', 'Interpreter','none', 'FontSize', 8);
grid on;

nexttile;
bar(labor_rows, 'stacked');
hold on;
yline(H_bar, ':', 'Color', [0.25 0.25 0.25], 'LineWidth', 1.2);
set(gca, 'XTick', 1:2, 'XTickLabel', ...
    {sprintf('z_bajo=%.2f', z(low)), sprintf('z_alto=%.2f', z(high))}, ...
    'TickLabelInterpreter','none');
ylabel('Horas (fraccion de H)', 'Interpreter','none');
xlabel('Productividad exogena z', 'Interpreter','none');
title('Uso del tiempo por tipo z', 'Interpreter','none');
legend({'Formal','Informal','Ocio'}, 'Location','southoutside', 'Orientation','horizontal', 'Interpreter','none');
grid on;

nexttile;
bar(sector_rows, 'stacked');
hold on;
if isfinite(T4_data)
    yline(T4_data, '--', 'Color', [0.25 0.25 0.25], 'LineWidth', 1.2, ...
        'DisplayName', sprintf('Meta T4=%.0f%%', 100*T4_data));
end
set(gca, 'XTick', 1:2, 'XTickLabel', ...
    {sprintf('z_bajo=%.2f', z(low)), sprintf('z_alto=%.2f', z(high))}, ...
    'TickLabelInterpreter','none');
ylabel('Fraccion de horas trabajadas', 'Interpreter','none');
xlabel('Productividad exogena z', 'Interpreter','none');
title('Composicion sectorial (excluye ocio)', 'Interpreter','none');
legend({'Formal','Informal','Meta T4'}, 'Location','southoutside', 'Orientation','horizontal', 'Interpreter','none');
ylim([0 1.05]);
grid on;

sgtitle(sprintf(['Equilibrio, validacion externa y policies OU | z_bajo: %.0f%% ocio, %.0f%% informal  |  ' ...
    'z_alto: %.0f%% ocio, %.0f%% informal'], ...
    100*mean_ocio_z(low), 100*share_informal_z(low), 100*mean_ocio_z(high), 100*share_informal_z(high)), ...
    'Interpreter','none', 'FontWeight','bold');

png_file = fullfile(out_dir, sprintf('policy_equilibrium_validation_%s.png', mat_tag));
save_png_local(fig, png_file, 300);

txt_file = fullfile(out_dir, sprintf('policy_equilibrium_validation_%s.txt', mat_tag));
fid = fopen(txt_file, 'w');
if fid >= 0
    fprintf(fid, 'Policy/equilibrium validation\n');
    fprintf(fid, 'mat_file=%s\n', mat_file);
    fprintf(fid, 'informal_profit_rule=%s\n', profit_rule);
    fprintf(fid, 'w_I_marginal=%.10f\n', w_I_star);
    fprintf(fid, 'profit_I=%.10f\n', Pi_I);
    fprintf(fid, 'L_I=%.10f\n', L_I_star);
    fprintf(fid, 'profit_per_LI=%.10f\n', profit_per_LI);
    fprintf(fid, 'w_I_household=%.10f\n', w_I_hh);
    fprintf(fid, 'r_star=%.10f K_star=%.10f p_I=%.10f\n', r_star, K_star, p_I_val);
    fprintf(fid, 'T4_model=%.10f T4_data=%.10f T5_nom=%.10f T5_data=%.10f\n', ...
        T4_model, T4_data, T5_nom, T5_data);
    fprintf(fid, 'Gini_a=%.10f Gini_c=%.10f\n', Gini_a, Gini_c);
    fprintf(fid, 'z mean_ellF mean_ellI mean_ocio share_formal_ex_ocio share_informal_ex_ocio debt_spread\n');
    for j = 1:Ns
        fprintf(fid, '%.10f %.10f %.10f %.10f %.10f %.10f %.10f\n', ...
            z(j), mean_ellF_z(j), mean_ellI_z(j), mean_ocio_z(j), ...
            share_formal_z(j), share_informal_z(j), debt_spread_z(j));
    end
    fclose(fid);
end

files = struct('png', png_file, 'txt', txt_file);
end

function files = make_income_substitution_diagnostics(mat_file, mat_tag, out_dir, a, z, aa, zz, g, da, ...
    c, c_F, c_I, exp_cons, debt_spread_z, ctx)
% Visual separation of income-effect and substitution-effect patterns.

[I, Ns] = size(g);
if ~(isfield(ctx, 'ell_F') && isfield(ctx, 'ell_I'))
    files = struct('png', '', 'txt', '');
    return;
end
ell_F = ctx.ell_F;
ell_I = ctx.ell_I;
kappa_F_aa = read_matrix_from_context(ctx, 'kappa_F_aa', zeros(I,Ns));
qq_informal = read_matrix_from_context(ctx, 'qq_informal', ones(I,Ns));
w_F = read_scalar_from_context(ctx, {'w_F_star','w_F'}, NaN);
w_I_hh = read_scalar_from_context(ctx, {'w_I_household_star','w_I_star','w_I'}, NaN);
theta = read_scalar_from_context(ctx, {'theta'}, 1);
nu_I = read_scalar_from_context(ctx, {'nu_I'}, 1);
tau = read_scalar_from_context(ctx, {'tau'}, 0);
H_bar = read_scalar_from_context(ctx, {'H_bar'}, 1);
ga = read_scalar_from_context(ctx, {'ga'}, 2);

total_hours = ell_F + ell_I;
formal_share = ell_F ./ max(total_hours, 1e-12);
informal_share = ell_I ./ max(total_hours, 1e-12);
kappa_by_z = mean(kappa_F_aa, 1);
q_by_z = mean(qq_informal, 1);
eff_wF_z = (1 - tau) * w_F * z - kappa_by_z;
eff_wI_z = w_I_hh * theta * (z .^ nu_I) .* q_by_z;

idx_low = closest_index(a, weighted_quantile(a, sum(g,2)*da, 0.20));
idx_mid = closest_index(a, weighted_quantile(a, sum(g,2)*da, 0.50));
idx_high = closest_index(a, weighted_quantile(a, sum(g,2)*da, 0.80));
idx_a = unique([idx_low idx_mid idx_high], 'stable');
a_colors = [0.77 0.18 0.14; 0.35 0.35 0.35; 0.05 0.43 0.65];
if numel(idx_a) == 2
    a_colors = a_colors([1 3], :);
elseif numel(idx_a) == 1
    a_colors = a_colors(2, :);
end

idx_z = unique([1 max(1, round((Ns+1)/2)) Ns], 'stable');
z_colors = [0.77 0.18 0.14; 0.35 0.35 0.35; 0.05 0.43 0.65];
if numel(idx_z) == 2
    z_colors = z_colors([1 3], :);
elseif numel(idx_z) == 1
    z_colors = z_colors(2, :);
end

avg_total_by_a = sum(g .* total_hours, 2) ./ max(sum(g,2), 1e-12);
avg_c_by_a = sum(g .* exp_cons, 2) ./ max(sum(g,2), 1e-12);
Va_proxy = max(c, 1e-12) .^ (-ga);
avg_Va_by_a = sum(g .* Va_proxy, 2) ./ max(sum(g,2), 1e-12);

fig = figure('Color','white','Position',[55 55 1600 980]);
tiledlayout(fig, 3, 2, 'TileSpacing','compact', 'Padding','compact');

nexttile;
plot(z, eff_wF_z, '-o', 'LineWidth', 2.1, 'DisplayName','Salario formal neto efectivo');
hold on;
plot(z, eff_wI_z, '--s', 'LineWidth', 2.1, 'DisplayName','Ingreso informal efectivo/hora');
plot(z, debt_spread_z, ':^', 'LineWidth', 2.1, 'DisplayName','Prima deuda');
xlabel('Productividad exogena z', 'Interpreter','none');
ylabel('Precio/sombra por hora', 'Interpreter','none');
title('Canal de sustitucion: retorno relativo de trabajar por z', 'Interpreter','none');
legend('Location','best', 'Interpreter','none');
grid on;

nexttile;
hold on;
for kk = 1:numel(idx_a)
    ia = idx_a(kk);
    plot(z, total_hours(ia,:), '-o', 'Color', a_colors(kk,:), 'LineWidth', 2.0, ...
        'DisplayName', sprintf('Horas totales | a=%.2f', a(ia)));
end
xlabel('Productividad exogena z', 'Interpreter','none');
ylabel('ell_F + ell_I', 'Interpreter','none');
title('Sustitucion pura aproximada: variar z con a fijo', 'Interpreter','none');
legend('Location','best', 'Interpreter','none');
grid on;

nexttile;
hold on;
for kk = 1:numel(idx_z)
    j = idx_z(kk);
    plot(a, total_hours(:,j), 'Color', z_colors(kk,:), 'LineWidth', 2.0, ...
        'DisplayName', sprintf('z=%.2f', z(j)));
end
xlabel('Riqueza neta a', 'Interpreter','none');
ylabel('ell_F + ell_I', 'Interpreter','none');
title('Efecto ingreso: riqueza alta reduce necesidad de trabajar', 'Interpreter','none');
legend('Location','best', 'Interpreter','none');
grid on;

nexttile;
hold on;
for kk = 1:numel(idx_a)
    ia = idx_a(kk);
    plot(z, formal_share(ia,:), '-o', 'Color', a_colors(kk,:), 'LineWidth', 2.0, ...
        'DisplayName', sprintf('Share formal | a=%.2f', a(ia)));
end
xlabel('Productividad exogena z', 'Interpreter','none');
ylabel('ell_F/(ell_F+ell_I)', 'Interpreter','none');
title('Sustitucion sectorial: formalidad aumenta con z', 'Interpreter','none');
legend('Location','best', 'Interpreter','none');
grid on;

nexttile;
yyaxis left;
plot(a, avg_total_by_a, '-', 'LineWidth', 2.0);
ylabel('Horas promedio cond. a', 'Interpreter','none');
yyaxis right;
plot(a, avg_c_by_a, '--', 'LineWidth', 2.0);
ylabel('Gasto promedio cond. a', 'Interpreter','none');
xlabel('Riqueza neta a', 'Interpreter','none');
title('Ingreso: mas riqueza coincide con mas gasto y menos horas', 'Interpreter','none');
grid on;

nexttile;
plot(a, avg_Va_by_a, '-', 'Color', [0.45 0.20 0.60], 'LineWidth', 2.0);
xlabel('Riqueza neta a', 'Interpreter','none');
ylabel('V_a proxy = C^{-gamma}', 'Interpreter','none');
title('Utilidad marginal: canal que disciplina efecto ingreso', 'Interpreter','none');
grid on;

sgtitle(sprintf('Efecto ingreso vs sustitucion | %s', mat_tag), ...
    'Interpreter','none', 'FontWeight','bold');

png_file = fullfile(out_dir, sprintf('income_substitution_effects_%s.png', mat_tag));
save_png_local(fig, png_file, 300);

txt_file = fullfile(out_dir, sprintf('income_substitution_effects_%s.txt', mat_tag));
fid = fopen(txt_file, 'w');
if fid >= 0
    fprintf(fid, 'Income and substitution diagnostics\n');
    fprintf(fid, 'mat_file=%s\n', mat_file);
    fprintf(fid, 'Interpretation: labor variation over a at fixed z approximates income effect; variation over z at fixed a captures substitution/comparative-advantage forces.\n');
    fprintf(fid, 'z eff_wF eff_wI debt_spread\n');
    for j = 1:Ns
        fprintf(fid, '%.10f %.10f %.10f %.10f\n', z(j), eff_wF_z(j), eff_wI_z(j), debt_spread_z(j));
    end
    fprintf(fid, 'asset_index a total_hours_by_z...\n');
    for kk = 1:numel(idx_a)
        ia = idx_a(kk);
        fprintf(fid, '%d %.10f', ia, a(ia));
        fprintf(fid, ' %.10f', total_hours(ia,:));
        fprintf(fid, '\n');
    end
    fclose(fid);
end

files = struct('png', png_file, 'txt', txt_file);
end

function png_file = make_ou_surfaces(mat_tag, out_dir, a, z, g, c, c_F, c_I, exp_cons, ctx)
% Internal diagnostic over the (a,z) state grid. Do not use as causal evidence.

[I, Ns] = size(g);
icut = find(cumsum(sum(g,2)) / max(sum(g(:)),1e-12) >= 0.995, 1, 'first');
if isempty(icut), icut = min(I, 80); end
icut = min(I, max(10, icut));
acut = a(1:icut);

has_labor = isfield(ctx, 'ell_F') && isfield(ctx, 'ell_I');
if has_labor
    ell_F = ctx.ell_F;
    ell_I = ctx.ell_I;
else
    ell_F = NaN(I,Ns);
    ell_I = NaN(I,Ns);
end

fig = figure('Color','white','Position',[50 50 1550 950]);
tiledlayout(fig, 2, 2, 'TileSpacing','compact', 'Padding','compact');

nexttile;
surf(acut, z, g(1:icut,:)');
shading interp;
view([45 25]);
xlabel('Riqueza a', 'Interpreter','none');
ylabel('Productividad z', 'Interpreter','none');
zlabel('Densidad g(a,z)', 'Interpreter','none');
title('Superficie estacionaria g(a,z)', 'Interpreter','none');
grid on;

nexttile;
surf(acut, z, exp_cons(1:icut,:)');
shading interp;
view([45 25]);
xlabel('Riqueza a', 'Interpreter','none');
ylabel('Productividad z', 'Interpreter','none');
zlabel('Gasto c_F + p_I c_I', 'Interpreter','none');
title('Superficie de gasto', 'Interpreter','none');
grid on;

nexttile;
surf(acut, z, ell_F(1:icut,:)');
shading interp;
view([45 25]);
xlabel('Riqueza a', 'Interpreter','none');
ylabel('Productividad z', 'Interpreter','none');
zlabel('ell_F(a,z)', 'Interpreter','none');
title('Horas formales', 'Interpreter','none');
grid on;

nexttile;
surf(acut, z, ell_I(1:icut,:)');
shading interp;
view([45 25]);
xlabel('Riqueza a', 'Interpreter','none');
ylabel('Productividad z', 'Interpreter','none');
zlabel('ell_I(a,z)', 'Interpreter','none');
title('Horas informales', 'Interpreter','none');
grid on;

sgtitle(sprintf('Diagnostico 3D OU, no causal: estado predeterminado (a,z) | %s', mat_tag), ...
    'Interpreter','none', 'FontWeight','bold');

png_file = fullfile(out_dir, sprintf('ou_3d_surfaces_%s.png', mat_tag));
save_png_local(fig, png_file, 300);
end

function separate_dir = make_separate_ou_figures(mat_file, mat_tag, out_dir, a, z, aa, zz, g, da, ...
    c, c_F, c_I, exp_cons, debt_spread_aa, debt_spread_z, ctx)
% Individual OU figures analogous to output_graphs_v10, adjusted to state (a,z).

[I, Ns] = size(g);
separate_dir = fullfile(out_dir, ['separate_' mat_tag]);
if ~exist(separate_dir, 'dir'), mkdir(separate_dir); end

fid = fopen(fullfile(separate_dir, 'run_source.txt'), 'w');
if fid >= 0
    fprintf(fid, 'mat_file: %s\n', mat_file);
    fprintf(fid, 'generated: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
    fprintf(fid, 'note: OU-specific separate figures; no q heterogeneity labels.\n');
    fclose(fid);
end

has_labor = isfield(ctx, 'ell_F') && isfield(ctx, 'ell_I');
if has_labor
    ell_F = ctx.ell_F;
    ell_I = ctx.ell_I;
else
    ell_F = NaN(I,Ns);
    ell_I = NaN(I,Ns);
end
idx_show = unique([1 max(1, round((Ns+1)/2)) Ns], 'stable');
z_colors = [0.77 0.18 0.14; 0.35 0.35 0.35; 0.05 0.43 0.65];
if numel(idx_show) == 2
    z_colors = z_colors([1 3], :);
elseif numel(idx_show) == 1
    z_colors = z_colors(2, :);
end
p_I_val = read_scalar_from_context(ctx, {'p_I_star','p_I'}, evalin('caller','p_I'));
T4_data = read_scalar_from_context(ctx, {'T4_data'}, NaN);
adot_sep = compute_adot_for_plot(a, aa, zz, exp_cons, debt_spread_aa, ctx);

% 1. Equilibrium summary.
fig = figure('Color','white','Position',[80 80 920 620]);
axis off;
eq_names = {'r*','K*','p_I*','L_F*','L_I*','w_F','w_I marg.','w_I hh','T4','T5','Tkz','Gini a','Gini gasto'};
eq_vals = [
    read_scalar_from_context(ctx, {'r_star'}, NaN)
    read_scalar_from_context(ctx, {'K_star'}, NaN)
    p_I_val
    read_scalar_from_context(ctx, {'L_F_star'}, NaN)
    read_scalar_from_context(ctx, {'L_I_star'}, NaN)
    read_scalar_from_context(ctx, {'w_F_star'}, NaN)
    read_scalar_from_context(ctx, {'w_I_star'}, NaN)
    read_scalar_from_context(ctx, {'w_I_household_star'}, NaN)
    read_scalar_from_context(ctx, {'T4_model'}, NaN)
    read_scalar_from_context(ctx, {'T5_nom'}, NaN)
    read_scalar_from_context(ctx, {'T_kappa_z_model'}, NaN)
    read_scalar_from_context(ctx, {'Gini_a'}, NaN)
    read_scalar_from_context(ctx, {'Gini_c'}, NaN)
    ];
text(0.05, 0.93, 'Resumen de equilibrio OU con prima z', 'FontSize', 18, 'FontWeight','bold', 'Interpreter','none');
for k = 1:numel(eq_names)
    col = 0.08 + 0.42 * (k > 7);
    row = k - 7 * (k > 7);
    text(col, 0.84 - 0.09*row, sprintf('%-12s %.4f', eq_names{k}, eq_vals(k)), ...
        'FontSize', 13, 'Interpreter','none');
end
text(0.05, 0.08, sprintf('profit rule: %s | figura generada desde %s', ...
    read_char_from_context(ctx, 'informal_profit_rule', 'unknown'), mat_tag), ...
    'FontSize', 10, 'Interpreter','none');
save_png_local(fig, fullfile(separate_dir, 'equilibrium_summary_ou.png'), 240);

% 2. OU mass and debt premium.
mass_z_model = da * sum(g, 1);
mass_z_model = mass_z_model / max(sum(mass_z_model), 1e-12);
if isfield(ctx, 'pi_z_ar')
    pi_z_ar = ctx.pi_z_ar(:)' / max(sum(ctx.pi_z_ar), 1e-12);
else
    pi_z_ar = mass_z_model;
end
fig = figure('Color','white','Position',[90 90 980 520]);
yyaxis left;
bar(1:Ns, [pi_z_ar(:), mass_z_model(:)], 'grouped');
ylabel('Masa', 'Interpreter','none');
yyaxis right;
plot(1:Ns, debt_spread_z, '--s', 'LineWidth', 2.0);
ylabel('Prima deuda spread_b(z)', 'Interpreter','none');
set(gca, 'XTick', 1:Ns, 'XTickLabel', z_tick_labels(z), 'TickLabelInterpreter','none');
xlabel('Estado OU z', 'Interpreter','none');
title('Proceso OU discretizado y prima z', 'Interpreter','none');
legend({'Masa OU','Masa modelo','Prima deuda'}, 'Location','best', 'Interpreter','none');
grid on;
save_png_local(fig, fullfile(separate_dir, 'ou_process_and_debt_premium.png'), 300);

% 3. Wealth distribution, with a mass-focused zoom because tails can be long.
g_marg_a = sum(g, 2);
w_a = g_marg_a * da;
a_p01 = weighted_quantile(a, w_a, 0.01);
a_p99 = weighted_quantile(a, w_a, 0.99);
a_p001 = weighted_quantile(a, w_a, 0.001);
a_p999 = weighted_quantile(a, w_a, 0.999);
zoom_lo = max(min(a), a_p01);
zoom_hi = min(max(a), a_p99);
if ~isfinite(zoom_lo) || ~isfinite(zoom_hi) || zoom_hi <= zoom_lo
    zoom_lo = min(a);
    zoom_hi = max(a);
end
fig = figure('Color','white','Position',[90 90 1180 560]);
tiledlayout(fig, 1, 2, 'TileSpacing','compact', 'Padding','compact');
nexttile;
plot(a, g_marg_a / max(sum(g_marg_a)*da, 1e-12), 'k-', 'LineWidth', 2.2, 'DisplayName','Total');
hold on;
for kk = 1:numel(idx_show)
    j = idx_show(kk);
    mass_j = da * sum(g(:,j));
    plot(a, g(:,j) / max(mass_j * da, 1e-12), 'Color', z_colors(kk,:), 'LineWidth', 1.8, ...
        'DisplayName', sprintf('z=%.2f', z(j)));
end
xline(0, ':', 'Color', [0.35 0.35 0.35], 'HandleVisibility','off');
xline(a_p001, '--', 'Color', [0.55 0.55 0.55], 'HandleVisibility','off');
xline(a_p999, '--', 'Color', [0.55 0.55 0.55], 'HandleVisibility','off');
xlim([min(a), max(a)]);
xlabel('Riqueza neta a', 'Interpreter','none');
ylabel('Densidad', 'Interpreter','none');
title(sprintf('Distribucion completa: grid a=[%.2f, %.2f]', min(a), max(a)), 'Interpreter','none');
legend('Location','best', 'Interpreter','none', 'FontSize', 8);
grid on;
nexttile;
plot(a, g_marg_a / max(sum(g_marg_a)*da, 1e-12), 'k-', 'LineWidth', 2.2, 'DisplayName','Total');
hold on;
for kk = 1:numel(idx_show)
    j = idx_show(kk);
    mass_j = da * sum(g(:,j));
    plot(a, g(:,j) / max(mass_j * da, 1e-12), 'Color', z_colors(kk,:), 'LineWidth', 1.8, ...
        'DisplayName', sprintf('z=%.2f', z(j)));
end
xline(0, ':', 'Color', [0.35 0.35 0.35], 'HandleVisibility','off');
xlim([zoom_lo, zoom_hi]);
xlabel('Riqueza neta a', 'Interpreter','none');
ylabel('Densidad', 'Interpreter','none');
title(sprintf('Zoom visual, no recorte del calculo: masa central 98%% [%.2f, %.2f]', zoom_lo, zoom_hi), 'Interpreter','none');
legend('Location','best', 'Interpreter','none', 'FontSize', 8);
grid on;
sgtitle(sprintf('Distribucion estacionaria OU: izquierda completa, derecha zoom visual | p0.1=%.2f, p99.9=%.2f', ...
    a_p001, a_p999), 'Interpreter','none', 'FontWeight','bold');
save_png_local(fig, fullfile(separate_dir, 'wealth_distribution_ou.png'), 300);

% 3b. Savings policy by productivity.
fig = figure('Color','white','Position',[90 90 1050 620]);
hold on;
for kk = 1:numel(idx_show)
    j = idx_show(kk);
    plot(a, adot_sep(:,j), 'Color', z_colors(kk,:), 'LineWidth', 2.0, ...
        'DisplayName', sprintf('z=%.2f', z(j)));
end
yline(0, ':', 'Color', [0.25 0.25 0.25], 'LineWidth', 1.2, 'DisplayName','adot=0');
xline(0, ':', 'Color', [0.45 0.45 0.45], 'HandleVisibility','off');
xlim([zoom_lo, zoom_hi]);
xlabel('Riqueza neta a', 'Interpreter','none');
ylabel('Ahorro / drift de activos adot(a,z)', 'Interpreter','none');
title('Politica de ahorro segun nivel de productividad', 'Interpreter','none');
legend('Location','best', 'Interpreter','none', 'FontSize', 8);
grid on;
save_png_local(fig, fullfile(separate_dir, 'savings_policy_ou.png'), 300);

% 4. Consumption policy.
fig = figure('Color','white','Position',[90 90 980 560]);
hold on;
for kk = 1:numel(idx_show)
    j = idx_show(kk);
    plot(a, c(:,j), 'Color', z_colors(kk,:), 'LineWidth', 2.0, ...
        'DisplayName', sprintf('C efectivo, z=%.2f', z(j)));
end
xlabel('Riqueza neta a', 'Interpreter','none');
ylabel('Consumo efectivo C', 'Interpreter','none');
title('Policy function: consumo efectivo', 'Interpreter','none');
legend('Location','best', 'Interpreter','none');
grid on;
save_png_local(fig, fullfile(separate_dir, 'consumption_policy_ou.png'), 300);

% 5. Formal/informal consumption components.
fig = figure('Color','white','Position',[90 90 1050 620]);
hold on;
for kk = 1:numel(idx_show)
    j = idx_show(kk);
    plot(a, c_F(:,j), '-', 'Color', z_colors(kk,:), 'LineWidth', 2.0, ...
        'DisplayName', sprintf('c_F, z=%.2f', z(j)));
    plot(a, p_I_val*c_I(:,j), '--', 'Color', z_colors(kk,:), 'LineWidth', 2.0, ...
        'DisplayName', sprintf('p_I c_I, z=%.2f', z(j)));
end
xlabel('Riqueza neta a', 'Interpreter','none');
ylabel('Gasto sectorial', 'Interpreter','none');
title('Consumo formal e informal', 'Interpreter','none');
legend('Location','best', 'Interpreter','none', 'FontSize', 8);
grid on;
save_png_local(fig, fullfile(separate_dir, 'consumption_formal_informal_ou.png'), 300);

% 5b. Component policy functions split by every z state.
make_consumption_policy_by_z_figure(separate_dir, a, z, c, c_F, c_I, p_I_val, zoom_lo, zoom_hi);

% 6. Expenditure distribution.
w_all = g(:) * da;
[x_c, pdf_c] = weighted_pdf_local(c(:), w_all, 60);
[x_e, pdf_e] = weighted_pdf_local(exp_cons(:), w_all, 60);
[x_cF, pdf_cF] = weighted_pdf_local(c_F(:), w_all, 60);
[x_pIcI, pdf_pIcI] = weighted_pdf_local((p_I_val*c_I(:)), w_all, 60);
fig = figure('Color','white','Position',[90 90 980 560]);
plot(x_c, pdf_c, '-', 'LineWidth', 2.2, 'DisplayName','Consumo efectivo C');
hold on;
plot(x_e, pdf_e, '--', 'LineWidth', 2.2, 'DisplayName','Gasto c_F+p_I c_I');
plot(x_cF, pdf_cF, '-.', 'LineWidth', 2.0, 'DisplayName','Bien formal c_F');
plot(x_pIcI, pdf_pIcI, ':', 'LineWidth', 2.4, 'DisplayName','Gasto bien informal p_I c_I');
xlabel('Consumo/gasto', 'Interpreter','none');
ylabel('Densidad ponderada', 'Interpreter','none');
title('Distribuciones de consumo y gasto', 'Interpreter','none');
legend('Location','best', 'Interpreter','none');
grid on;
save_png_local(fig, fullfile(separate_dir, 'consumption_expenditure_distribution_ou.png'), 300);

fig = figure('Color','white','Position',[90 90 980 560]);
plot(x_cF, pdf_cF, '-', 'LineWidth', 2.2, 'DisplayName','Bien formal c_F');
hold on;
plot(x_pIcI, pdf_pIcI, '--', 'LineWidth', 2.2, 'DisplayName','Bien informal p_I c_I');
plot(x_e, pdf_e, ':', 'LineWidth', 2.2, 'DisplayName','Gasto total');
xlabel('Gasto por componente', 'Interpreter','none');
ylabel('Densidad ponderada', 'Interpreter','none');
title('Distribucion de bienes consumidos: formal vs informal', 'Interpreter','none');
legend('Location','best', 'Interpreter','none');
grid on;
save_png_local(fig, fullfile(separate_dir, 'consumption_goods_distribution_ou.png'), 300);

make_consumption_distribution_model_output(separate_dir, c, c_F, c_I, exp_cons, p_I_val, w_all);

[x_adot, pdf_adot] = weighted_pdf_local(adot_sep(:), w_all, 70);
fig = figure('Color','white','Position',[90 90 980 560]);
plot(x_adot, pdf_adot, 'k-', 'LineWidth', 2.2, 'DisplayName','Distribucion adot');
hold on;
xline(0, ':', 'Color', [0.35 0.35 0.35], 'LineWidth', 1.2, 'DisplayName','adot=0');
for kk = 1:numel(idx_show)
    j = idx_show(kk);
    mass_j = da * sum(g(:,j));
    [x_az, pdf_az] = weighted_pdf_local(adot_sep(:,j), g(:,j)*da/max(mass_j, 1e-12), 55);
    plot(x_az, pdf_az, 'LineWidth', 1.8, 'Color', z_colors(kk,:), ...
        'DisplayName', sprintf('z=%.2f', z(j)));
end
xlabel('Ahorro / drift de activos adot(a,z)', 'Interpreter','none');
ylabel('Densidad ponderada', 'Interpreter','none');
title('Distribucion estacionaria de ahorro', 'Interpreter','none');
legend('Location','best', 'Interpreter','none');
grid on;
save_png_local(fig, fullfile(separate_dir, 'savings_distribution_ou.png'), 300);

% 7. Labor policy, split to avoid overplotting formal/informal margins.
fig = figure('Color','white','Position',[90 90 1180 560]);
tiledlayout(fig, 1, 2, 'TileSpacing','compact', 'Padding','compact');
nexttile;
hold on;
for kk = 1:numel(idx_show)
    j = idx_show(kk);
    plot(a, ell_F(:,j), '-', 'Color', z_colors(kk,:), 'LineWidth', 2.0, ...
        'DisplayName', sprintf('z=%.2f', z(j)));
end
xlabel('Riqueza neta a', 'Interpreter','none');
ylabel('Horas formales ell_F', 'Interpreter','none');
title('Policy function: labor formal', 'Interpreter','none');
legend('Location','best', 'Interpreter','none', 'FontSize', 8);
grid on;
nexttile;
hold on;
for kk = 1:numel(idx_show)
    j = idx_show(kk);
    plot(a, ell_I(:,j), '-', 'Color', z_colors(kk,:), 'LineWidth', 2.0, ...
        'DisplayName', sprintf('z=%.2f', z(j)));
end
xlabel('Riqueza neta a', 'Interpreter','none');
ylabel('Horas informales ell_I', 'Interpreter','none');
title('Policy function: labor informal', 'Interpreter','none');
legend('Location','best', 'Interpreter','none', 'FontSize', 8);
grid on;
sgtitle('Policy functions de labor por sector y productividad OU', ...
    'Interpreter','none', 'FontWeight','bold');
save_png_local(fig, fullfile(separate_dir, 'labor_policy_ou.png'), 300);

fig = figure('Color','white','Position',[90 90 980 560]);
hold on;
for kk = 1:numel(idx_show)
    j = idx_show(kk);
    plot(a, ell_F(:,j) + ell_I(:,j), '-', 'Color', z_colors(kk,:), 'LineWidth', 2.0, ...
        'DisplayName', sprintf('z=%.2f', z(j)));
end
xline(0, ':', 'Color', [0.45 0.45 0.45], 'HandleVisibility','off');
xlim([zoom_lo, zoom_hi]);
xlabel('Riqueza neta a', 'Interpreter','none');
ylabel('Horas totales ell_F + ell_I', 'Interpreter','none');
title('Oferta laboral total segun nivel de productividad', 'Interpreter','none');
legend('Location','best', 'Interpreter','none', 'FontSize', 8);
grid on;
save_png_local(fig, fullfile(separate_dir, 'labor_supply_by_productivity_ou.png'), 300);

% 8. Time allocation by z, similar to requested slide.
H_bar = read_scalar_from_context(ctx, {'H_bar'}, 1);
mean_ellF_z = zeros(1,Ns);
mean_ellI_z = zeros(1,Ns);
mean_ocio_z = zeros(1,Ns);
for j = 1:Ns
    mass_j = da * sum(g(:,j));
    mean_ellF_z(j) = da * sum(g(:,j).*ell_F(:,j)) / max(mass_j, 1e-12);
    mean_ellI_z(j) = da * sum(g(:,j).*ell_I(:,j)) / max(mass_j, 1e-12);
    mean_ocio_z(j) = max(H_bar - mean_ellF_z(j) - mean_ellI_z(j), 0);
end
low = 1; high = Ns;
worked = mean_ellF_z + mean_ellI_z;
sector_rows = [mean_ellF_z([low high])'./max(worked([low high])',1e-12), ...
    mean_ellI_z([low high])'./max(worked([low high])',1e-12)];
fig = figure('Color','white','Position',[80 80 1200 560]);
tiledlayout(fig, 1, 2, 'TileSpacing','compact', 'Padding','compact');
nexttile;
bar([mean_ellF_z([low high])', mean_ellI_z([low high])', mean_ocio_z([low high])'], 'stacked');
yline(H_bar, ':', 'Color', [0.25 0.25 0.25], 'LineWidth', 1.2);
set(gca, 'XTick', 1:2, 'XTickLabel', {sprintf('z_bajo=%.2f', z(low)), sprintf('z_alto=%.2f', z(high))}, ...
    'TickLabelInterpreter','none');
ylabel('Horas (fraccion de H)', 'Interpreter','none');
title('Uso del tiempo por productividad z', 'Interpreter','none');
legend({'Formal','Informal','Ocio'}, 'Location','southoutside', 'Orientation','horizontal', 'Interpreter','none');
grid on;
nexttile;
bar(sector_rows, 'stacked');
if isfinite(T4_data), yline(T4_data, '--', 'Color', [0.25 0.25 0.25], 'LineWidth', 1.2); end
set(gca, 'XTick', 1:2, 'XTickLabel', {sprintf('z_bajo=%.2f', z(low)), sprintf('z_alto=%.2f', z(high))}, ...
    'TickLabelInterpreter','none');
ylabel('Fraccion de horas trabajadas', 'Interpreter','none');
title('Composicion sectorial (excluye ocio)', 'Interpreter','none');
legend({'Formal','Informal','Meta T4'}, 'Location','southoutside', 'Orientation','horizontal', 'Interpreter','none');
ylim([0 1.05]);
grid on;
sgtitle(sprintf('Asignacion del tiempo OU | z_bajo %.0f%% ocio, %.0f%% informal | z_alto %.0f%% ocio, %.0f%% informal', ...
    100*mean_ocio_z(low), 100*sector_rows(1,2), 100*mean_ocio_z(high), 100*sector_rows(2,2)), ...
    'Interpreter','none', 'FontWeight','bold');
save_png_local(fig, fullfile(separate_dir, 'time_allocation_by_z_ou.png'), 300);

% 9. Lorenz/Gini.
fig = figure('Color','white','Position',[90 90 980 560]);
hold on;
if isfield(ctx, 'lorenz_a') && isfield(ctx, 'cum_pop_a')
    plot([0; ctx.cum_pop_a(:)], [0; ctx.lorenz_a(:)], '-', 'LineWidth', 2.2, ...
        'DisplayName', sprintf('Riqueza neta, Gini=%.3f', read_scalar_from_context(ctx, {'Gini_a'}, NaN)));
end
if isfield(ctx, 'lorenz_c') && isfield(ctx, 'cum_pop_c')
    plot([0; ctx.cum_pop_c(:)], [0; ctx.lorenz_c(:)], '--', 'LineWidth', 2.2, ...
        'DisplayName', sprintf('Gasto, Gini=%.3f', read_scalar_from_context(ctx, {'Gini_c'}, NaN)));
end
plot([0 1], [0 1], ':', 'Color', [0.35 0.35 0.35], 'HandleVisibility','off');
xlabel('Fraccion acumulada de hogares', 'Interpreter','none');
ylabel('Fraccion acumulada', 'Interpreter','none');
title('Lorenz/Gini: validacion externa', 'Interpreter','none');
legend('Location','northwest', 'Interpreter','none');
grid on;
save_png_local(fig, fullfile(separate_dir, 'lorenz_gini_ou.png'), 300);

% 10. Heterogeneity table, OU version of tabla_heterogeneidad.
[qshare, qcuts] = weighted_quintile_shares(aa, g, da, 5);
groups = cell(5,1);
group_names = {'Q1 riqueza','Q5 riqueza','z bajo','z mediano','z alto'};
groups{1} = qshare{1};
groups{2} = qshare{5};
z_low_cut = z(max(1, ceil(Ns/3)));
z_high_cut = z(min(Ns, floor(2*Ns/3)+1));
groups{3} = double(zz <= z_low_cut);
groups{4} = double(zz > z_low_cut & zz < z_high_cut);
groups{5} = double(zz >= z_high_cut);
metric_names = {'Masa','Riqueza a','Gasto','C efectivo','c_F','p_I c_I','ell_F','ell_I','Share informal','Pr(a<0)'};
tbl = zeros(numel(metric_names), numel(groups));
for ggidx = 1:numel(groups)
    wg = g .* groups{ggidx};
    mass_g = da * sum(wg(:));
    tbl(1,ggidx) = mass_g;
    tbl(2,ggidx) = da * sum(sum(wg .* aa)) / max(mass_g, 1e-12);
    tbl(3,ggidx) = da * sum(sum(wg .* exp_cons)) / max(mass_g, 1e-12);
    tbl(4,ggidx) = da * sum(sum(wg .* c)) / max(mass_g, 1e-12);
    tbl(5,ggidx) = da * sum(sum(wg .* c_F)) / max(mass_g, 1e-12);
    tbl(6,ggidx) = da * sum(sum(wg .* (p_I_val*c_I))) / max(mass_g, 1e-12);
    tbl(7,ggidx) = da * sum(sum(wg .* ell_F)) / max(mass_g, 1e-12);
    tbl(8,ggidx) = da * sum(sum(wg .* ell_I)) / max(mass_g, 1e-12);
    tbl(9,ggidx) = tbl(8,ggidx) / max(tbl(7,ggidx) + tbl(8,ggidx), 1e-12);
    tbl(10,ggidx) = da * sum(sum(wg .* (aa < 0))) / max(mass_g, 1e-12);
end
fig = figure('Color','white','Position',[70 70 1280 620]);
axis off;
text(0.03, 0.94, 'Tabla de heterogeneidad OU: riqueza y productividad', ...
    'FontSize', 17, 'FontWeight','bold', 'Interpreter','none');
text(0.03, 0.89, sprintf('Quintiles por masa estacionaria exacta. Cortes de riqueza: %.3f, %.3f, %.3f, %.3f', qcuts), ...
    'FontSize', 9.5, 'Interpreter','none');
x0 = 0.03; y0 = 0.82; row_h = 0.065;
col_w = [0.19 repmat(0.145, 1, numel(groups))];
col_x = x0 + [0 cumsum(col_w(1:end-1))];
rectangle('Position',[x0-0.01 y0-row_h*(numel(metric_names)+1)-0.012 sum(col_w)+0.02 row_h*(numel(metric_names)+1)+0.025], ...
    'FaceColor',[0.98 0.98 0.98], 'EdgeColor',[0.35 0.35 0.35]);
for ccol = 1:(numel(groups)+1)
    if ccol == 1, label = 'Variable'; else, label = group_names{ccol-1}; end
    text(col_x(ccol)+col_w(ccol)/2, y0-row_h/2, label, 'HorizontalAlignment','center', ...
        'FontWeight','bold', 'FontSize', 9.5, 'Interpreter','none');
end
for rr = 1:numel(metric_names)
    yy = y0 - row_h*(rr+0.5);
    if mod(rr,2)==0
        rectangle('Position',[x0-0.01 yy-row_h/2 sum(col_w)+0.02 row_h], ...
            'FaceColor',[0.93 0.95 0.97], 'EdgeColor','none');
    end
    text(col_x(1)+0.005, yy, metric_names{rr}, 'HorizontalAlignment','left', ...
        'FontSize', 9.5, 'Interpreter','none');
    for ccol = 1:numel(groups)
        text(col_x(ccol+1)+col_w(ccol+1)/2, yy, sprintf('%.3f', tbl(rr,ccol)), ...
            'HorizontalAlignment','center', 'FontSize', 9.5, 'Interpreter','none');
    end
end
save_png_local(fig, fullfile(separate_dir, 'tabla_heterogeneidad_ou.png'), 260);

% 11. Consumption by all OU z nodes.
mean_cF_z = zeros(1,Ns);
mean_pIcI_z = zeros(1,Ns);
mean_exp_z = zeros(1,Ns);
mean_C_z = zeros(1,Ns);
for j = 1:Ns
    mass_j = da * sum(g(:,j));
    mean_cF_z(j) = da * sum(g(:,j).*c_F(:,j)) / max(mass_j, 1e-12);
    mean_pIcI_z(j) = da * sum(g(:,j).*(p_I_val*c_I(:,j))) / max(mass_j, 1e-12);
    mean_exp_z(j) = da * sum(g(:,j).*exp_cons(:,j)) / max(mass_j, 1e-12);
    mean_C_z(j) = da * sum(g(:,j).*c(:,j)) / max(mass_j, 1e-12);
end
fig = figure('Color','white','Position',[90 90 1180 620]);
tiledlayout(fig, 1, 2, 'TileSpacing','compact', 'Padding','compact');
nexttile;
bar(1:Ns, [mean_cF_z(:), mean_pIcI_z(:)], 'stacked');
set(gca, 'XTick',1:Ns,'XTickLabel',z_tick_labels(z),'TickLabelInterpreter','none');
xlabel('Estado OU z', 'Interpreter','none');
ylabel('Gasto medio', 'Interpreter','none');
title('Canasta por productividad: c_F y p_I c_I', 'Interpreter','none');
legend({'c_F','p_I c_I'}, 'Location','best', 'Interpreter','none');
grid on;
nexttile;
plot(z, mean_C_z, '-o', 'LineWidth', 2.0, 'DisplayName','C efectivo');
hold on;
plot(z, mean_exp_z, '--s', 'LineWidth', 2.0, 'DisplayName','Gasto');
xlabel('Productividad z', 'Interpreter','none');
ylabel('Media condicional', 'Interpreter','none');
title('Consumo/gasto medio por z', 'Interpreter','none');
legend('Location','best','Interpreter','none');
grid on;
sgtitle('Consumo formal e informal segun todos los estados OU z', 'Interpreter','none', 'FontWeight','bold');
save_png_local(fig, fullfile(separate_dir, 'consumption_by_all_z_ou.png'), 300);

% 12. Labor by all OU z nodes.
fig = figure('Color','white','Position',[90 90 1180 620]);
tiledlayout(fig, 1, 2, 'TileSpacing','compact', 'Padding','compact');
nexttile;
labor_all_rows = [mean_ellF_z(:), mean_ellI_z(:), mean_ocio_z(:)];
bar(1:Ns, labor_all_rows, 'stacked');
hold on;
annotate_stacked_percent(labor_all_rows, 0.055, H_bar);
set(gca, 'XTick',1:Ns,'XTickLabel',z_tick_labels(z),'TickLabelInterpreter','none');
set_percent_yticks(gca);
xlabel('Estado OU z', 'Interpreter','none');
ylabel('Porcentaje de H', 'Interpreter','none');
title('Uso del tiempo por cada z', 'Interpreter','none');
legend({'Formal','Informal','Ocio'}, 'Location','best', 'Interpreter','none');
grid on;
nexttile;
share_F_z = mean_ellF_z ./ max(mean_ellF_z + mean_ellI_z, 1e-12);
share_I_z = mean_ellI_z ./ max(mean_ellF_z + mean_ellI_z, 1e-12);
sector_all_rows = [share_F_z(:), share_I_z(:)];
bar(1:Ns, sector_all_rows, 'stacked');
hold on;
annotate_stacked_percent(sector_all_rows, 0.055, 1);
if isfinite(T4_data)
    yline(T4_data, '--', sprintf('Meta T4=%.0f%%', 100*T4_data), ...
        'Color',[0.25 0.25 0.25], 'LineWidth',1.2, 'LabelHorizontalAlignment','left');
end
set(gca, 'XTick',1:Ns,'XTickLabel',z_tick_labels(z),'TickLabelInterpreter','none');
set_percent_yticks(gca);
xlabel('Estado OU z', 'Interpreter','none');
ylabel('Porcentaje de horas trabajadas', 'Interpreter','none');
title('Composicion sectorial por z (excluye ocio)', 'Interpreter','none');
legend({'Formal','Informal','Meta T4'}, 'Location','best', 'Interpreter','none');
ylim([0 1.05]);
grid on;
sgtitle('Labor formal/informal segun todos los estados OU z', 'Interpreter','none', 'FontWeight','bold');
save_png_local(fig, fullfile(separate_dir, 'labor_by_all_z_ou.png'), 300);

% 13. General equilibrium OU. Uses saved r-curve only when the .mat contains it.
has_ge_curve = isfield(ctx, 'r_grid') && isfield(ctx, 'S') && isfield(ctx, 'KD') && ...
    numel(ctx.r_grid) > 1 && numel(ctx.S) == numel(ctx.r_grid) && numel(ctx.KD) == numel(ctx.r_grid);
if ~has_ge_curve && isfield(ctx, 'ge_history') && isstruct(ctx.ge_history) && ...
        isfield(ctx.ge_history, 'r_grid') && isfield(ctx.ge_history, 'S') && isfield(ctx.ge_history, 'KD')
    ctx.r_grid = ctx.ge_history.r_grid;
    ctx.S = ctx.ge_history.S;
    ctx.KD = ctx.ge_history.KD;
    has_ge_curve = numel(ctx.r_grid) > 1 && numel(ctx.S) == numel(ctx.r_grid) && numel(ctx.KD) == numel(ctx.r_grid);
end
fig = figure('Color','white','Position',[90 90 1280 720]);
tiledlayout(fig, 2, 2, 'TileSpacing','compact', 'Padding','compact');
nexttile;
targets_model = [
    read_scalar_from_context(ctx, {'T4_model'}, NaN)
    read_scalar_from_context(ctx, {'T5_nom'}, NaN)
    read_scalar_from_context(ctx, {'T_kappa_z_model'}, NaN)
    read_scalar_from_context(ctx, {'ratio_gasto_FI'}, NaN)
    ];
targets_data = [
    read_scalar_from_context(ctx, {'T4_data'}, NaN)
    read_scalar_from_context(ctx, {'T5_data'}, NaN)
    read_scalar_from_context(ctx, {'T_kappa_z_data'}, NaN)
    read_scalar_from_context(ctx, {'TgFI_data'}, NaN)
    ];
if has_ge_curve
    r_curve = ctx.r_grid(:);
    S_curve = ctx.S(:);
    KD_curve = ctx.KD(:);
    ok_curve = isfinite(r_curve) & isfinite(S_curve) & isfinite(KD_curve);
    n_curve = sum(ok_curve);
    hold on;
    if n_curve >= 30
        plot(S_curve(ok_curve), r_curve(ok_curve), '-o', 'LineWidth', 2.0, 'MarkerSize', 4, 'DisplayName','Oferta S(r)');
        plot(KD_curve(ok_curve), r_curve(ok_curve), '-s', 'LineWidth', 2.0, 'MarkerSize', 4, 'DisplayName','Demanda K^d(r)');
        curve_title = 'Mercado de activos: barrido S(r) vs K^d(r)';
    else
        plot(S_curve(ok_curve), r_curve(ok_curve), ':', 'Color', [0.45 0.70 0.88], ...
            'LineWidth', 1.4, 'HandleVisibility','off');
        plot(KD_curve(ok_curve), r_curve(ok_curve), ':', 'Color', [0.92 0.58 0.32], ...
            'LineWidth', 1.4, 'HandleVisibility','off');
        scatter(S_curve(ok_curve), r_curve(ok_curve), 44, [0.05 0.43 0.65], 'filled', ...
            'DisplayName','Oferta S(r): puntos biseccion');
        scatter(KD_curve(ok_curve), r_curve(ok_curve), 44, [0.82 0.32 0.12], 's', 'filled', ...
            'DisplayName','Demanda K^d(r): puntos biseccion');
        curve_title = 'Mercado de activos: puntos de biseccion y guia conectada';
    end
    scatter(read_scalar_from_context(ctx, {'K_star'}, NaN), read_scalar_from_context(ctx, {'r_star'}, NaN), ...
        70, 'k', 'filled', 'DisplayName','Equilibrio guardado');
    xlabel('Capital / activos agregados', 'Interpreter','none');
    ylabel('r', 'Interpreter','none');
    title(curve_title, 'Interpreter','none');
    legend('Location','best','Interpreter','none');
    grid on;
else
    bar([targets_model, targets_data]);
    set(gca,'XTick',1:4,'XTickLabel',{'T4','T5','Tkz','TgFI'},'TickLabelInterpreter','none');
    ylabel('Momento', 'Interpreter','none');
    title('Modelo vs datos', 'Interpreter','none');
    legend({'Modelo','Dato'}, 'Location','best', 'Interpreter','none');
    grid on;
end
nexttile;
bar([read_scalar_from_context(ctx, {'K_F_star'}, NaN), read_scalar_from_context(ctx, {'K_I_star'}, NaN); ...
     read_scalar_from_context(ctx, {'L_F_star'}, NaN), read_scalar_from_context(ctx, {'L_I_star'}, NaN)]);
set(gca,'XTick',1:2,'XTickLabel',{'Capital','Trabajo eficiente'},'TickLabelInterpreter','none');
title('Asignacion agregada sectorial', 'Interpreter','none');
legend({'Formal','Informal'}, 'Location','best', 'Interpreter','none');
grid on;
nexttile;
bar([read_scalar_from_context(ctx, {'w_F_star'}, NaN), read_scalar_from_context(ctx, {'w_I_star'}, NaN), ...
    read_scalar_from_context(ctx, {'w_I_household_star'}, NaN), p_I_val, read_scalar_from_context(ctx, {'r_star'}, NaN)]);
set(gca,'XTick',1:5,'XTickLabel',{'w_F','w_I marg','w_I hh','p_I','r'},'TickLabelInterpreter','none');
title('Precios de equilibrio', 'Interpreter','none');
grid on;
nexttile;
axis off;
text(0.04, 0.82, 'Equilibrio general OU', 'FontSize', 15, 'FontWeight','bold', 'Interpreter','none');
text(0.04, 0.67, sprintf('K*=%.4f, r*=%.4f, p_I=%.4f', ...
    read_scalar_from_context(ctx, {'K_star'}, NaN), read_scalar_from_context(ctx, {'r_star'}, NaN), p_I_val), ...
    'FontSize', 11, 'Interpreter','none');
text(0.04, 0.52, sprintf('L_F=%.4f, L_I=%.4f, regla beneficios=%s', ...
    read_scalar_from_context(ctx, {'L_F_star'}, NaN), read_scalar_from_context(ctx, {'L_I_star'}, NaN), ...
    read_char_from_context(ctx, 'informal_profit_rule', 'unknown')), ...
    'FontSize', 11, 'Interpreter','none');
if has_ge_curve
    n_curve = sum(isfinite(ctx.r_grid(:)) & isfinite(ctx.S(:)) & isfinite(ctx.KD(:)));
    if n_curve >= 30
        note_curve = sprintf('Curva GE guardada desde la corrida: %d evaluaciones de r.', n_curve);
    else
        note_curve = sprintf(['Puntos GE guardados: %d evaluaciones reales de biseccion. ' ...
            'La linea punteada solo conecta puntos para orientacion; no es barrido denso.'], n_curve);
    end
    text(0.04, 0.33, note_curve, ...
        'FontSize', 9.5, 'Interpreter','none');
else
    text(0.04, 0.33, ['Este .mat es anterior al guardado de r_grid/S/KD; ' ...
        'se muestra solo el punto de equilibrio disponible.'], ...
        'FontSize', 9.5, 'Interpreter','none');
end
sgtitle('Equilibrio general OU', ...
    'Interpreter','none', 'FontWeight','bold');
save_png_local(fig, fullfile(separate_dir, 'equilibrium_general_ou.png'), 300);
end

function make_consumption_policy_by_z_figure(separate_dir, a, z, c, c_F, c_I, p_I_val, zoom_lo, zoom_hi)
Ns = numel(z);
ncols = min(3, Ns);
nrows = ceil(Ns / ncols);

fig = figure('Color','white','Position',[70 70 1500 max(720, 285*nrows)]);
tiledlayout(fig, nrows, ncols, 'TileSpacing','compact', 'Padding','compact');
for j = 1:Ns
    nexttile;
    plot(a, c_F(:,j), '-', 'Color', [0.05 0.43 0.65], 'LineWidth', 1.8, ...
        'DisplayName','c_F');
    hold on;
    plot(a, p_I_val*c_I(:,j), '--', 'Color', [0.82 0.32 0.12], 'LineWidth', 1.8, ...
        'DisplayName','p_I c_I');
    plot(a, c(:,j), ':', 'Color', [0.20 0.20 0.20], 'LineWidth', 1.6, ...
        'DisplayName','C efectivo');
    xline(0, ':', 'Color', [0.45 0.45 0.45], 'HandleVisibility','off');
    if isfinite(zoom_lo) && isfinite(zoom_hi) && zoom_hi > zoom_lo
        xlim([zoom_lo, zoom_hi]);
    end
    title(sprintf('z=%.2f', z(j)), 'Interpreter','none');
    xlabel('Riqueza neta a', 'Interpreter','none');
    ylabel('Policy de consumo', 'Interpreter','none');
    if j == 1
        legend('Location','best', 'Interpreter','none', 'FontSize', 8);
    end
    grid on;
end
sgtitle('Policy functions por productividad: consumo formal, informal y efectivo', ...
    'Interpreter','none', 'FontWeight','bold');
save_png_local(fig, fullfile(separate_dir, 'consumption_policy_by_z_components_ou.png'), 300);

txt_file = fullfile(separate_dir, 'consumption_policy_by_z_components_ou.txt');
fid = fopen(txt_file, 'w');
if fid >= 0
    fprintf(fid, 'Consumption policy by z components\n');
    fprintf(fid, 'interpretation=model policy functions over asset state a; useful model output, not micro-data evidence.\n');
    fprintf(fid, 'x_axis=wealth/state a, predetermined state in HJB; not an exogenous empirical treatment.\n');
    fprintf(fid, 'z mean_cF mean_pIcI mean_C min_cF max_cF min_pIcI max_pIcI\n');
    for j = 1:Ns
        fprintf(fid, '%.10f %.10f %.10f %.10f %.10f %.10f %.10f %.10f\n', ...
            z(j), mean(c_F(:,j)), mean(p_I_val*c_I(:,j)), mean(c(:,j)), ...
            min(c_F(:,j)), max(c_F(:,j)), min(p_I_val*c_I(:,j)), max(p_I_val*c_I(:,j)));
    end
    fclose(fid);
end
end

function make_consumption_distribution_model_output(separate_dir, c, c_F, c_I, exp_cons, p_I_val, w_all)
vars = struct();
vars.C_eff = c(:);
vars.expenditure = exp_cons(:);
vars.c_F = c_F(:);
vars.pI_cI = p_I_val * c_I(:);

[xC, FC] = weighted_cdf_local(vars.C_eff, w_all);
[xE, FE] = weighted_cdf_local(vars.expenditure, w_all);
[xF, pdfF] = weighted_pdf_local(vars.c_F, w_all, 70);
[xI, pdfI] = weighted_pdf_local(vars.pI_cI, w_all, 70);
[xCpdf, pdfC] = weighted_pdf_local(vars.C_eff, w_all, 70);
[xEpdf, pdfE] = weighted_pdf_local(vars.expenditure, w_all, 70);

quant_probs = [0.01 0.05 0.10 0.25 0.50 0.75 0.90 0.95 0.99];
qC = weighted_quantile_vec(vars.C_eff, w_all, quant_probs);
qE = weighted_quantile_vec(vars.expenditure, w_all, quant_probs);
qF = weighted_quantile_vec(vars.c_F, w_all, quant_probs);
qI = weighted_quantile_vec(vars.pI_cI, w_all, quant_probs);
statsC = weighted_stats_local(vars.C_eff, w_all);
statsE = weighted_stats_local(vars.expenditure, w_all);
statsF = weighted_stats_local(vars.c_F, w_all);
statsI = weighted_stats_local(vars.pI_cI, w_all);

fig = figure('Color','white','Position',[70 70 1450 900]);
tiledlayout(fig, 2, 2, 'TileSpacing','compact', 'Padding','compact');

nexttile;
plot(xCpdf, pdfC, '-', 'LineWidth', 2.1, 'DisplayName','C efectivo');
hold on;
plot(xEpdf, pdfE, '--', 'LineWidth', 2.1, 'DisplayName','Gasto total');
xline(qC(5), ':', 'Color', [0.05 0.43 0.65], 'HandleVisibility','off');
xline(qE(5), ':', 'Color', [0.82 0.32 0.12], 'HandleVisibility','off');
xlabel('Nivel', 'Interpreter','none');
ylabel('Densidad ponderada', 'Interpreter','none');
title('Distribucion modelada de consumo efectivo y gasto', 'Interpreter','none');
legend('Location','best', 'Interpreter','none');
grid on;

nexttile;
plot(xF, pdfF, '-', 'Color', [0.05 0.43 0.65], 'LineWidth', 2.1, 'DisplayName','c_F');
hold on;
plot(xI, pdfI, '--', 'Color', [0.82 0.32 0.12], 'LineWidth', 2.1, 'DisplayName','p_I c_I');
xlabel('Gasto por componente', 'Interpreter','none');
ylabel('Densidad ponderada', 'Interpreter','none');
title('Distribucion por bien: formal vs informal', 'Interpreter','none');
legend('Location','best', 'Interpreter','none');
grid on;

nexttile;
plot(xC, FC, '-', 'LineWidth', 2.1, 'DisplayName','CDF C efectivo');
hold on;
plot(xE, FE, '--', 'LineWidth', 2.1, 'DisplayName','CDF gasto');
xlabel('Nivel', 'Interpreter','none');
ylabel('Probabilidad acumulada', 'Interpreter','none');
title('CDF completa sin recorte de colas', 'Interpreter','none');
legend('Location','best', 'Interpreter','none');
grid on;

nexttile;
axis off;
rows = {
    sprintf('C efectivo: media %.4f, mediana %.4f, p10-p90 [%.4f, %.4f]', statsC.mean, qC(5), qC(3), qC(7))
    sprintf('Gasto total: media %.4f, mediana %.4f, p10-p90 [%.4f, %.4f]', statsE.mean, qE(5), qE(3), qE(7))
    sprintf('c_F: media %.4f, mediana %.4f, p10-p90 [%.4f, %.4f]', statsF.mean, qF(5), qF(3), qF(7))
    sprintf('p_I c_I: media %.4f, mediana %.4f, p10-p90 [%.4f, %.4f]', statsI.mean, qI(5), qI(3), qI(7))
    sprintf('CV gasto %.3f, CV C efectivo %.3f', statsE.cv, statsC.cv)
    };
text(0.02, 0.90, 'Distribucion micro generada por el modelo', ...
    'FontSize', 15, 'FontWeight','bold', 'Interpreter','none');
for k = 1:numel(rows)
    text(0.03, 0.82 - 0.11*k, rows{k}, 'FontSize', 10.5, 'Interpreter','none');
end
text(0.03, 0.08, ['Uso sugerido: aporte descriptivo del modelo. ' ...
    'No existe contraparte micro directa de activos/consumo en Peru en esta calibracion; ' ...
    'contrastar solo cualitativamente o contra momentos agregados disponibles.'], ...
    'FontSize', 9.5, 'Interpreter','none');

sgtitle('Distribucion estacionaria modelada de consumo, gasto y componentes', ...
    'Interpreter','none', 'FontWeight','bold');
save_png_local(fig, fullfile(separate_dir, 'consumption_distribution_model_output_ou.png'), 300);

txt_file = fullfile(separate_dir, 'consumption_distribution_model_output_ou.txt');
fid = fopen(txt_file, 'w');
if fid >= 0
    fprintf(fid, 'Consumption distribution model output\n');
    fprintf(fid, 'interpretation=model-generated micro distribution; useful contribution because direct Peru micro data for consumption/assets at this model level are not used here.\n');
    fprintf(fid, 'pdf_note=PDF panels use central binning for readability; CDF and quantiles use full support.\n');
    fprintf(fid, 'variable mean sd cv p01 p05 p10 p25 p50 p75 p90 p95 p99\n');
    write_consumption_summary_row(fid, 'C_eff', statsC, qC);
    write_consumption_summary_row(fid, 'expenditure', statsE, qE);
    write_consumption_summary_row(fid, 'c_F', statsF, qF);
    write_consumption_summary_row(fid, 'pI_cI', statsI, qI);
    fclose(fid);
end
end

function write_consumption_summary_row(fid, name, stats, q)
fprintf(fid, '%s %.10f %.10f %.10f', name, stats.mean, stats.sd, stats.cv);
for k = 1:numel(q)
    fprintf(fid, ' %.10f', q(k));
end
fprintf(fid, '\n');
end

function mat_file = default_results_file()
script_dir = fileparts(mfilename('fullpath'));
source_file = fullfile(script_dir, 'output_graphs_ou_debtprem', 'run_source.txt');
mat_file = '';
if exist(source_file, 'file')
    txt = fileread(source_file);
    tok = regexp(txt, 'mat_file:\s*([^\r\n]+)', 'tokens', 'once');
    if ~isempty(tok)
        candidate = strtrim(tok{1});
        if exist(candidate, 'file')
            mat_file = candidate;
            return;
        end
    end
end

files = dir(fullfile(script_dir, 'mat_outputs', 'fastdebug_runs_ou_debtprem', '*', 'results_*.mat'));
if ~isempty(files)
    [~, idx] = max([files.datenum]);
    mat_file = fullfile(files(idx).folder, files(idx).name);
    return;
end

fallback = fullfile(script_dir, 'results_v10_latest.mat');
if exist(fallback, 'file')
    mat_file = fallback;
    return;
end
error('No se encontro un results_*.mat OU/debtprem por defecto.');
end

function write_plot_context(context_file, mat_file, mat_tag, out_dir, ctx)
fid = fopen(context_file, 'w');
if fid < 0
    warning('No se pudo escribir contexto de plot: %s', context_file);
    return;
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, 'OU/debt-premium plot context\n');
fprintf(fid, 'mat_file=%s\n', mat_file);
fprintf(fid, 'mat_tag=%s\n', mat_tag);
fprintf(fid, 'plot_output_dir=%s\n', out_dir);
fprintf(fid, 'generated_at=%s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));

if isfield(ctx, 'metadata_file')
    fprintf(fid, 'metadata_file=%s\n', local_meta_str(ctx.metadata_file));
end
if isfield(ctx, 'results_file')
    fprintf(fid, 'results_file_saved=%s\n', local_meta_str(ctx.results_file));
end
if isfield(ctx, 'calib_file')
    fprintf(fid, 'calib_file_saved=%s\n', local_meta_str(ctx.calib_file));
end

if isfield(ctx, 'run_config') && isstruct(ctx.run_config)
    rc = ctx.run_config;
    fprintf(fid, '\n[run_config]\n');
    top_fields = {'created_at','script','script_file','run_tag','safe_run_tag', ...
        'output_dir','results_file','calib_file','metadata_file','mode', ...
        'fast_debug','total_elapsed','zdrift_method','zdrift_reuse','zdrift_npts'};
    for k = 1:numel(top_fields)
        if isfield(rc, top_fields{k})
            fprintf(fid, '%s=%s\n', top_fields{k}, local_meta_str(rc.(top_fields{k})));
        end
    end
    if isfield(rc, 'sources') && isstruct(rc.sources)
        fprintf(fid, '\n[sources]\n');
        write_struct_fields(fid, rc.sources, '');
    end
    if isfield(rc, 'core') && isstruct(rc.core)
        fprintf(fid, '\n[core]\n');
        write_struct_fields(fid, rc.core, '');
    end
    if isfield(rc, 'env') && isstruct(rc.env)
        fprintf(fid, '\n[env]\n');
        write_struct_fields(fid, rc.env, '');
    end
else
    fprintf(fid, '\n[run_config]\n');
    fprintf(fid, 'status=missing_in_mat_file\n');
end

fprintf(fid, '\n[loaded_scalars]\n');
scalar_fields = {'rho_z_ar','sd_logz_ar','debt_prem_chi','debt_prem_eta', ...
    'debt_prem_rebate','psi_F','psi_I','A_I','alpha_I','beta_I','theta','nu_I', ...
    'omega_C','sigma_C','kappa_z1','kappa_z2','kappa_z_shape','amin','amax','H_bar', ...
    'r_star','K_star','p_I','T4_model','T4_data','T5_nom','T5_data', ...
    'T_kappa_z_model','T_kappa_z_data','ratio_gasto_FI','TgFI_data', ...
    'mass_debt','mass_amin','DebtPremPayments','avg_debt_spread_paid'};
for k = 1:numel(scalar_fields)
    if isfield(ctx, scalar_fields{k})
        fprintf(fid, '%s=%s\n', scalar_fields{k}, local_meta_str(ctx.(scalar_fields{k})));
    end
end
end

function write_graph_audit(audit_file, mat_tag)
fid = fopen(audit_file, 'w');
if fid < 0
    warning('No se pudo escribir auditoria de graficos: %s', audit_file);
    return;
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, 'Graph audit for OU/debt-premium outputs\n');
fprintf(fid, 'mat_tag=%s\n', mat_tag);
fprintf(fid, 'principle=Moll-style output only: white background, blue solid vs red dashed, clean axes, and at most two panels per PNG.\n');

fprintf(fid, '\n[generated_main_set]\n');
fprintf(fid, 'moll_style_%s/moll_savings_policy.png\n', mat_tag);
fprintf(fid, '  Use: savings policy only.\n');
fprintf(fid, 'moll_style_%s/moll_wealth_distribution_by_z.png\n', mat_tag);
fprintf(fid, '  Use: wealth distribution only.\n');
fprintf(fid, 'moll_style_%s/moll_consumption_policy.png\n', mat_tag);
fprintf(fid, '  Use: model policy functions over the asset state; two panels.\n');
fprintf(fid, 'moll_style_%s/moll_consumption_labor_policy_by_wealth.png\n', mat_tag);
fprintf(fid, '  Use: consumo y oferta laboral total contra riqueza para z bajo, medio y alto; dos paneles.\n');
fprintf(fid, 'moll_style_%s/moll_labor_policy_by_wealth.png\n', mat_tag);
fprintf(fid, '  Use: formal and informal labor policy functions for z bajo, medio y alto; two panels.\n');
fprintf(fid, 'moll_style_%s/moll_labor_supply_by_productivity.png\n', mat_tag);
fprintf(fid, '  Use: total hours over assets for representative z nodes and average hours by all z nodes.\n');
fprintf(fid, 'moll_style_%s/moll_ou_stationary_masses.png\n', mat_tag);
fprintf(fid, '  Use: OU invariant distribution vs model stationary mass; one panel.\n');
fprintf(fid, 'moll_style_%s/moll_conditional_moments_by_z.png\n', mat_tag);
fprintf(fid, '  Use: activos y gasto promedio por estado exogeno de productividad; dos paneles.\n');
fprintf(fid, 'moll_style_%s/moll_informality_by_z.png\n', mat_tag);
fprintf(fid, '  Use: informalidad/formalidad por productividad only.\n');
fprintf(fid, 'moll_style_%s/moll_debt_probability_by_z.png\n', mat_tag);
fprintf(fid, '  Use: Pr(a<0|z) only; separate debt diagnostic.\n');
fprintf(fid, 'moll_style_%s/moll_consumption_distribution.png\n', mat_tag);
fprintf(fid, '  Use: stationary consumption/expenditure distribution; one panel.\n');
fprintf(fid, 'moll_style_%s/moll_consumption_components_distribution.png\n', mat_tag);
fprintf(fid, '  Use: formal vs informal consumption components; one panel.\n');
fprintf(fid, 'moll_style_%s/moll_consumption_components_by_z.png\n', mat_tag);
fprintf(fid, '  Use: formal and informal consumption/gasto by productivity z; two panels.\n');
fprintf(fid, 'moll_style_%s/moll_debt_premium_inequality_by_z.png\n', mat_tag);
fprintf(fid, '  Use: exogenous debt premium schedule by z and within-z consumption/gasto inequality gradient.\n');
fprintf(fid, 'moll_style_%s/moll_lorenz_curves.png\n', mat_tag);
fprintf(fid, '  Use: optional if Lorenz objects are stored in the mat file; one panel.\n');
fprintf(fid, 'moll_style_%s/moll_equilibrium_asset_market.png\n', mat_tag);
fprintf(fid, '  Use: optional equilibrium diagnostic if r-grid objects exist; one panel.\n');

fprintf(fid, '\n[caption_suggestion]\n');
fprintf(fid, 'Caption sugerido: La productividad sigue un proceso OU exogeno calibrado para Peru. Las figuras de policy sobre riqueza muestran z bajo, z mediano y z alto; las figuras por productividad usan todos los nodos Nz. La informalidad reportada es margen intensivo de horas, ell_I/(ell_F+ell_I), no margen extensivo de trabajadores informales.\n');
end

function write_struct_fields(fid, s, prefix)
fields = fieldnames(s);
for k = 1:numel(fields)
    name = fields{k};
    value = s.(name);
    if isstruct(value) && isscalar(value)
        write_struct_fields(fid, value, [prefix name '.']);
    else
        fprintf(fid, '%s%s=%s\n', prefix, name, local_meta_str(value));
    end
end
end

function s = local_meta_str(x)
if ischar(x)
    s = x;
elseif isstring(x)
    s = char(x);
elseif islogical(x)
    if isscalar(x)
        if x
            s = 'true';
        else
            s = 'false';
        end
    else
        s = mat2str(x);
    end
elseif isnumeric(x)
    if isempty(x)
        s = '';
    elseif isscalar(x)
        s = sprintf('%.12g', x);
    else
        s = mat2str(x, 12);
    end
else
    s = '<unsupported>';
end
end

function value = getv(name)
if evalin('caller', sprintf('exist(''%s'', ''var'')', name))
    value = evalin('caller', name);
else
    value = NaN;
end
if islogical(value)
    value = double(value);
end
if ~isnumeric(value) || isempty(value)
    value = NaN;
end
value = value(1);
end

function value = read_scalar_from_context(ctx, names, default_value)
value = default_value;
for k = 1:numel(names)
    if isfield(ctx, names{k})
        candidate = ctx.(names{k});
        if islogical(candidate)
            candidate = double(candidate);
        end
        if isnumeric(candidate) && ~isempty(candidate) && isfinite(candidate(1))
            value = candidate(1);
            return;
        end
    end
end
end

function value = read_matrix_from_context(ctx, name, default_value)
if isfield(ctx, name) && isnumeric(ctx.(name)) && ~isempty(ctx.(name))
    value = ctx.(name);
else
    value = default_value;
end
end

function value = read_char_from_context(ctx, name, default_value)
if isfield(ctx, name) && (ischar(ctx.(name)) || isstring(ctx.(name)))
    value = char(ctx.(name));
else
    value = default_value;
end
end

function gap = z_conditional_gap(a, g, da, z, metric)
switch metric
    case 'assets'
        mass_low = da * sum(g(:,1));
        mass_high = da * sum(g(:,end));
        low_val = da * sum(g(:,1) .* a) / max(mass_low, 1e-12);
        high_val = da * sum(g(:,end) .* a) / max(mass_high, 1e-12);
        gap = high_val - low_val;
    otherwise
        gap = NaN;
end
end

function gap = z_debt_gap(a, g, da)
mass_low = da * sum(g(:,1));
mass_high = da * sum(g(:,end));
low_val = da * sum(g(:,1) .* (a < 0)) / max(mass_low, 1e-12);
high_val = da * sum(g(:,end) .* (a < 0)) / max(mass_high, 1e-12);
gap = low_val - high_val;
end

function [qshare, qcuts] = weighted_quintile_shares(values, density, da, nq)
% Return fractional cell shares for exact weighted quintiles.
mass = density(:) * da;
x = values(:);
qshare_flat = zeros(numel(x), nq);
ok = isfinite(x) & isfinite(mass) & mass > 0;
idx_ok = find(ok);
[x_sorted, order] = sort(x(ok), 'ascend');
idx_sorted = idx_ok(order);
mass_sorted = mass(idx_sorted);
total_mass = sum(mass_sorted);

qcuts = zeros(1, nq-1);
cum_mass = cumsum(mass_sorted) / max(total_mass, 1e-12);
for q = 1:(nq-1)
    idx = find(cum_mass >= q/nq, 1, 'first');
    if isempty(idx), idx = numel(x_sorted); end
    qcuts(q) = x_sorted(idx);
end

bin = 1;
edge_next = total_mass / nq;
cum_abs = 0;
tol = 1e-13;
for k = 1:numel(idx_sorted)
    cell_idx = idx_sorted(k);
    rem = mass_sorted(k);
    while rem > tol && bin <= nq
        capacity = edge_next - cum_abs;
        if capacity <= tol
            bin = bin + 1;
            edge_next = total_mass * bin / nq;
            continue;
        end
        alloc = min(rem, capacity);
        qshare_flat(cell_idx, bin) = qshare_flat(cell_idx, bin) + alloc / max(mass(cell_idx), 1e-12);
        rem = rem - alloc;
        cum_abs = cum_abs + alloc;
        if cum_abs >= edge_next - tol
            bin = bin + 1;
            edge_next = total_mass * bin / nq;
        end
    end
    if bin > nq && rem > tol
        qshare_flat(cell_idx, nq) = qshare_flat(cell_idx, nq) + rem / max(mass(cell_idx), 1e-12);
    end
end

qshare = cell(nq, 1);
for q = 1:nq
    qshare{q} = reshape(qshare_flat(:,q), size(density));
end
end

function q = weighted_quantile(values, weights, prob)
values = values(:);
weights = weights(:);
ok = isfinite(values) & isfinite(weights) & weights > 0;
values = values(ok);
weights = weights(ok);
if isempty(values)
    q = NaN;
    return;
end
[values, order] = sort(values, 'ascend');
weights = weights(order);
cw = cumsum(weights) / max(sum(weights), 1e-12);
idx = find(cw >= prob, 1, 'first');
if isempty(idx), idx = numel(values); end
q = values(idx);
end

function q = weighted_quantile_vec(values, weights, probs)
q = zeros(size(probs));
for k = 1:numel(probs)
    q(k) = weighted_quantile(values, weights, probs(k));
end
end

function [x, F] = weighted_cdf_local(values, weights)
values = values(:);
weights = weights(:);
ok = isfinite(values) & isfinite(weights) & weights > 0;
values = values(ok);
weights = weights(ok);
if isempty(values)
    x = 0;
    F = 0;
    return;
end
[x, order] = sort(values, 'ascend');
weights = weights(order);
F = cumsum(weights) / max(sum(weights), 1e-12);
end

function stats = weighted_stats_local(values, weights)
values = values(:);
weights = weights(:);
ok = isfinite(values) & isfinite(weights) & weights > 0;
values = values(ok);
weights = weights(ok);
if isempty(values)
    stats = struct('mean', NaN, 'sd', NaN, 'cv', NaN);
    return;
end
weights = weights / max(sum(weights), 1e-12);
mu = sum(weights .* values);
sd = sqrt(sum(weights .* (values - mu).^2));
stats = struct('mean', mu, 'sd', sd, 'cv', sd / max(abs(mu), 1e-12));
end

function idx = closest_index(values, target)
if ~isfinite(target)
    idx = 1;
    return;
end
[~, idx] = min(abs(values(:) - target));
end

function labels = z_tick_labels(z)
labels = cell(1, numel(z));
for j = 1:numel(z)
    labels{j} = sprintf('%.2f', z(j));
end
end

function [centers, pdf_vals] = weighted_pdf_local(values, weights, nbins)
values = values(:);
weights = weights(:);
ok = isfinite(values) & isfinite(weights) & weights > 0;
values = values(ok);
weights = weights(ok);
if isempty(values)
    centers = 0;
    pdf_vals = 0;
    return;
end
lo = prctile(values, 0.5);
hi = prctile(values, 99.5);
if hi <= lo
    lo = min(values);
    hi = max(values);
end
if hi <= lo
    centers = lo;
    pdf_vals = 1;
    return;
end
edges = linspace(lo, hi, nbins + 1);
[~, bin] = histc(values, edges);
bin(values == edges(end)) = nbins;
valid = bin >= 1 & bin <= nbins;
counts = accumarray(bin(valid), weights(valid), [nbins 1], @sum, 0)';
binw = edges(2) - edges(1);
pdf_vals = counts / max(sum(counts) * binw, 1e-12);
centers = 0.5 * (edges(1:end-1) + edges(2:end));
end

function adot = compute_adot_for_plot(a, aa, zz, exp_cons, debt_spread_aa, ctx)
[I, Ns] = size(exp_cons);
adot = NaN(I, Ns);
if ~isfield(ctx, 'ell_F') || ~isfield(ctx, 'ell_I')
    return;
end
ell_F = ctx.ell_F;
ell_I = ctx.ell_I;
if ~isequal(size(ell_F), [I, Ns]) || ~isequal(size(ell_I), [I, Ns])
    return;
end
if isempty(debt_spread_aa) || ~isequal(size(debt_spread_aa), [I, Ns])
    debt_spread_aa = zeros(I, Ns);
end
kappa_F_aa = read_matrix_from_context(ctx, 'kappa_F_aa', zeros(I,Ns));
if ~isequal(size(kappa_F_aa), [I, Ns])
    kappa_F_aa = zeros(I, Ns);
end
qq_informal = read_matrix_from_context(ctx, 'qq_informal', ones(I,Ns));
if ~isequal(size(qq_informal), [I, Ns])
    qq_informal = ones(I, Ns);
end
w_F = read_scalar_from_context(ctx, {'w_F_star','w_F'}, NaN);
w_I_hh = read_scalar_from_context(ctx, {'w_I_household_star','w_I_star','w_I'}, NaN);
if ~isfinite(w_F) || ~isfinite(w_I_hh)
    return;
end
theta = read_scalar_from_context(ctx, {'theta'}, 1);
nu_I = read_scalar_from_context(ctx, {'nu_I'}, 1);
r_eq = read_scalar_from_context(ctx, {'r_star','r_eq','r'}, 0);
tau = read_scalar_from_context(ctx, {'tau'}, 0);
T_lump = read_scalar_from_context(ctx, {'T_eq','T_star','T'}, 0);
Pi_lump = read_scalar_from_context(ctx, {'Pi_lump_star'}, NaN);
if ~isfinite(Pi_lump)
    profit_rule = read_char_from_context(ctx, 'informal_profit_rule', 'lump');
    if strcmpi(profit_rule, 'lump')
        Pi_lump = read_scalar_from_context(ctx, {'profit_I_star'}, 0);
    else
        Pi_lump = 0;
    end
end
income_formal = ((1 - tau) * w_F * zz - kappa_F_aa) .* ell_F;
income_informal = w_I_hh * theta * (zz .^ nu_I) .* qq_informal .* ell_I;
adot = income_formal + income_informal + r_eq * aa ...
    - debt_spread_aa .* max(-aa, 0) + T_lump + Pi_lump - exp_cons;
end

function annotate_stacked_percent(rows, min_share, denom)
if nargin < 2 || isempty(min_share), min_share = 0.05; end
if nargin < 3 || isempty(denom), denom = 1; end
for irow = 1:size(rows, 1)
    base = 0;
    for jcol = 1:size(rows, 2)
        val = rows(irow, jcol);
        share = val / max(denom, 1e-12);
        if isfinite(val) && isfinite(share) && share >= min_share
            text(irow, base + val/2, sprintf('%.0f%%', 100*share), ...
                'HorizontalAlignment','center', 'VerticalAlignment','middle', ...
                'FontSize', 8.5, 'FontWeight','bold', 'Color',[0.08 0.08 0.08], ...
                'Interpreter','none');
        end
        base = base + max(val, 0);
    end
end
end

function set_percent_yticks(ax)
yt = 0:0.1:1;
set(ax, 'YTick', yt, 'YTickLabel', arrayfun(@(x) sprintf('%.0f%%', 100*x), yt, 'UniformOutput', false));
ylim(ax, [0 1.05]);
end

function [col, style, lw, name, visible] = moll_z_line_style(j, Ns, zval)
mid = max(1, round((Ns + 1) / 2));
if j == 1
    col = [0.00 0.00 1.00];
    style = '-';
    lw = 2.1;
    name = sprintf('z_mín=%.2f', zval);
    visible = 'on';
elseif j == Ns
    col = [1.00 0.00 0.00];
    style = '--';
    lw = 2.1;
    name = sprintf('z_máx=%.2f', zval);
    visible = 'on';
elseif j == mid
    col = [0.00 0.00 1.00];
    style = '-';
    lw = 1.5;
    name = sprintf('z mediano=%.2f', zval);
    visible = 'off';
else
    col = [0.70 0.70 0.70];
    style = '-';
    lw = 0.9;
    name = '';
    visible = 'off';
end
end

function gini = weighted_gini_positive(x, w)
x = x(:);
w = w(:);
ok = isfinite(x) & isfinite(w) & w > 0;
x = x(ok);
w = w(ok);
if isempty(x) || sum(w) <= 0
    gini = NaN;
    return;
end
x = max(x, 0);
mu = sum(w .* x) / sum(w);
if mu <= 1e-14
    gini = 0;
    return;
end
[x, order] = sort(x, 'ascend');
w = w(order);
cw = cumsum(w);
cxw = cumsum(w .* x);
cw = [0; cw / cw(end)];
cxw = [0; cxw / cxw(end)];
gini = 1 - sum((cxw(2:end) + cxw(1:end-1)) .* diff(cw));
gini = max(0, min(1, gini));
end

function [pop, lorenz, gini] = lorenz_from_context_or_data(ctx, pop_name, lorenz_name, gini_name, x, w, force_positive)
pop = [];
lorenz = [];
gini = NaN;

if isfield(ctx, pop_name) && isfield(ctx, lorenz_name)
    pop_ctx = ctx.(pop_name);
    lorenz_ctx = ctx.(lorenz_name);
    if isnumeric(pop_ctx) && isnumeric(lorenz_ctx) && ~isempty(pop_ctx) && ~isempty(lorenz_ctx)
        pop = pop_ctx(:);
        lorenz = lorenz_ctx(:);
        n = min(numel(pop), numel(lorenz));
        pop = pop(1:n);
        lorenz = lorenz(1:n);
        if isfield(ctx, gini_name)
            gini_ctx = ctx.(gini_name);
            if isnumeric(gini_ctx) && ~isempty(gini_ctx) && isfinite(gini_ctx(1))
                gini = gini_ctx(1);
            end
        end
        if ~isfinite(gini)
            gini = gini_from_lorenz_points(pop, lorenz);
        end
        return;
    end
end

[pop, lorenz, gini] = weighted_lorenz_curve(x, w, force_positive);
end

function [pop, lorenz, gini] = weighted_lorenz_curve(x, w, force_positive)
x = x(:);
w = w(:);
ok = isfinite(x) & isfinite(w) & w > 0;
x = x(ok);
w = w(ok);
if isempty(x) || sum(w) <= 0
    pop = [];
    lorenz = [];
    gini = NaN;
    return;
end
if force_positive
    x = max(x, 0);
end
[x, order] = sort(x, 'ascend');
w = w(order);
total_w = sum(w);
total_xw = sum(x .* w);
if abs(total_xw) <= 1e-14
    pop = cumsum(w) / total_w;
    lorenz = zeros(size(pop));
    gini = NaN;
    return;
end
pop = cumsum(w) / total_w;
lorenz = cumsum(x .* w) / total_xw;
gini = gini_from_lorenz_points(pop, lorenz);
if force_positive
    gini = max(0, min(1, gini));
end
end

function gini = gini_from_lorenz_points(pop, lorenz)
pop = pop(:);
lorenz = lorenz(:);
ok = isfinite(pop) & isfinite(lorenz);
pop = pop(ok);
lorenz = lorenz(ok);
if isempty(pop)
    gini = NaN;
    return;
end
if pop(1) > 0
    pop = [0; pop];
    lorenz = [0; lorenz];
end
if pop(end) < 1
    pop = [pop; 1];
    lorenz = [lorenz; lorenz(end)];
end
gini = 1 - sum((lorenz(2:end) + lorenz(1:end-1)) .* diff(pop));
end

function fig = moll_figure(pos)
fig = figure('Color', 'white', 'Position', pos, 'InvertHardcopy', 'off', ...
    'Renderer', 'painters', 'Visible', 'off');
set(fig, 'DefaultAxesFontName', 'Times New Roman');
set(fig, 'DefaultTextFontName', 'Times New Roman');
set(fig, 'DefaultLegendFontName', 'Times New Roman');
set(fig, 'DefaultAxesFontSize', 12);
set(fig, 'DefaultTextInterpreter', 'tex');
set(fig, 'DefaultLegendInterpreter', 'tex');
end

function moll_axis(ax)
set(ax, 'FontName', 'Times New Roman', 'FontSize', 12, ...
    'Box', 'on', 'TickDir', 'in', 'LineWidth', 0.75, ...
    'XColor', [0 0 0], 'YColor', [0 0 0]);
grid(ax, 'off');
ax.Title.FontWeight = 'normal';
ax.XLabel.FontName = 'Times New Roman';
ax.YLabel.FontName = 'Times New Roman';
ax.XLabel.FontSize = 13;
ax.YLabel.FontSize = 13;
end

function moll_caption(fig, caption_text)
drawnow;
layouts = findall(fig, '-isa', 'matlab.graphics.layout.TiledChartLayout');
if ~isempty(layouts)
    for il = 1:numel(layouts)
        try
            layouts(il).Padding = 'loose';
            layouts(il).TileSpacing = 'compact';
            layouts(il).Position = [0.055 0.18 0.90 0.76];
        catch
        end
    end
else
    axs = findall(fig, 'Type', 'axes');
    for iax = 1:numel(axs)
        pos = get(axs(iax), 'Position');
        if pos(2) < 0.18
            lift = min(0.055, max(0, 0.18 - pos(2)));
            pos(2) = pos(2) + lift;
            pos(4) = max(0.10, pos(4) - lift);
            set(axs(iax), 'Position', pos);
        end
    end
end
annotation(fig, 'textbox', [0.04 0.020 0.92 0.070], ...
    'String', caption_text, 'LineStyle', 'none', ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
    'FontName', 'Times New Roman', 'FontSize', 15, ...
    'Interpreter', 'tex');
end

function save_png_local(fig, file_name, resolution)
if nargin < 3, resolution = 300; end
set(fig, 'Color', 'white', 'InvertHardcopy', 'off');
dark = [0 0 0];
axs = findall(fig, 'Type', 'axes');
for iax = 1:numel(axs)
    try
        set(axs(iax), 'FontName', 'Times New Roman', 'Box', 'on', ...
            'TickDir', 'in', 'LineWidth', 0.75, ...
            'XColor', dark, 'YColor', dark, ...
            'GridAlpha', 0.10, 'GridLineStyle', '-', 'MinorGridAlpha', 0.05);
        if ~isempty(axs(iax).Title) && ~isempty(axs(iax).Title.String)
            axs(iax).Title.FontWeight = 'normal';
        end
        axs(iax).Toolbar.Visible = 'off';
    catch
    end
end
drawnow;
try
    print(fig, file_name, '-dpng', sprintf('-r%d', resolution));
catch print_err
    warning('print fallo para %s: %s. Reintentando con exportgraphics.', file_name, print_err.message);
    exportgraphics(fig, file_name, 'Resolution', resolution, 'BackgroundColor', 'white');
end
close(fig);
end

% =========================================================================
% NUEVAS FIGURAS PARA LA TESIS — JURADO
% =========================================================================

function files = make_thesis_targets_validation(mat_tag, out_dir, ctx)
% Validacion de targets: comparacion modelo vs datos Peru en un solo panel.
% Figura lista para insertar en la tesis (Seccion Resultados/Validacion).

T4_model = read_scalar_from_context(ctx, {'T4_model'}, NaN);
T4_data  = read_scalar_from_context(ctx, {'T4_data'}, NaN);
T5_nom   = read_scalar_from_context(ctx, {'T5_nom'}, NaN);
T5_data  = read_scalar_from_context(ctx, {'T5_data'}, NaN);
Tkz_model = read_scalar_from_context(ctx, {'T_kappa_z_model'}, NaN);
Tkz_data  = read_scalar_from_context(ctx, {'T_kappa_z_data'}, NaN);
TgFI_model = read_scalar_from_context(ctx, {'ratio_gasto_FI'}, NaN);
TgFI_data  = read_scalar_from_context(ctx, {'TgFI_data'}, NaN);
Gini_a = read_scalar_from_context(ctx, {'Gini_a'}, NaN);
Gini_c = read_scalar_from_context(ctx, {'Gini_c'}, NaN);

model_vals = [T4_model, T5_nom, Tkz_model, TgFI_model];
data_vals  = [T4_data,  T5_data,  Tkz_data,  TgFI_data];
target_names = {'T4: Empleo informal\nE[lI]/(E[lF]+E[lI])', ...
                'T5: PBI informal nominal\np_I Y_I / (Y_F + p_I Y_I)', ...
                'Tkz: Gap formalidad\nz_alto - z_bajo', ...
                'TgFI: Gasto formal/informal\nE[gasto|lF>lI]/E[gasto|lI>lF]'};

fig = figure('Color','white','Position',[80 80 1100 650]);
tiledlayout(fig, 1, 2, 'TileSpacing','compact', 'Padding','compact');

% Panel 1: Barras modelo vs dato
nexttile;
bar_data = [model_vals(:), data_vals(:)];
hb = bar(bar_data, 'grouped');
hb(1).FaceColor = [0.05 0.43 0.65];
hb(2).FaceColor = [0.82 0.32 0.12];
set(gca, 'XTick', 1:4, 'XTickLabel', target_names, 'TickLabelInterpreter','none');
ylabel('Valor');
title('Validacion: Modelo vs Datos Peru', 'FontWeight','bold');
legend({'Modelo v10 OU', 'Dato Peru'}, 'Location','northwest');
grid on;

% Panel 2: Tabla resumen con desviaciones
nexttile;
axis off;
text(0.05, 0.95, 'Resumen de Calibracion', 'FontSize', 15, 'FontWeight','bold');
text(0.05, 0.86, sprintf('Modelo: Aiyagari HACT 2 firmas, OU 7 estados, prima deuda por z'), 'FontSize', 10);
text(0.05, 0.80, sprintf('Parametros calibrados: A_I=%.3f, psi_F=%.1f, psi_I=%.1f, omega_C=%.2f', ...
    read_scalar_from_context(ctx,{'A_I'},NaN), read_scalar_from_context(ctx,{'psi_F'},NaN), ...
    read_scalar_from_context(ctx,{'psi_I'},NaN), read_scalar_from_context(ctx,{'omega_C'},NaN)), 'FontSize', 10);

target_short = {'T4','T5','Tkz','TgFI'};
ypos = 0.70;
text(0.05, ypos+0.02, 'Target         Modelo    Dato      Desv. %', 'FontSize', 11, 'FontWeight','bold');
for k = 1:4
    if isfinite(model_vals(k)) && isfinite(data_vals(k)) && data_vals(k) > 0
        dev = 100 * (model_vals(k) - data_vals(k)) / data_vals(k);
        text(0.05, ypos - 0.06*k, sprintf('%-12s %7.3f   %7.3f   %+6.1f%%', ...
            target_short{k}, model_vals(k), data_vals(k), dev), 'FontSize', 11);
    end
end

text(0.05, 0.24, 'Diagnosticos auxiliares:', 'FontSize', 11, 'FontWeight','bold');
text(0.05, 0.18, sprintf('Gini riqueza modelo: %.3f  |  Gini gasto modelo: %.3f', Gini_a, Gini_c), 'FontSize', 10);
text(0.05, 0.12, sprintf('r* = %.4f  |  p_I* = %.4f  |  K* = %.4f', ...
    read_scalar_from_context(ctx,{'r_star'},NaN), ...
    read_scalar_from_context(ctx,{'p_I_star'},NaN), ...
    read_scalar_from_context(ctx,{'K_star'},NaN)), 'FontSize', 10);
text(0.05, 0.06, sprintf('w_F/w_I marginal = %.2f  |  tau = %.2f  |  chi_b = %.3f', ...
    read_scalar_from_context(ctx,{'w_F_star'},NaN)/max(read_scalar_from_context(ctx,{'w_I_star'},NaN),1e-12), ...
    read_scalar_from_context(ctx,{'tau'},0), read_scalar_from_context(ctx,{'debt_prem_chi'},0)), 'FontSize', 10);

sgtitle(sprintf('Validacion Empirica — Peru | %s', mat_tag), 'FontWeight','bold');

png_file = fullfile(out_dir, sprintf('thesis_targets_validation_%s.png', mat_tag));
save_png_local(fig, png_file, 300);
files = struct('png', png_file);
end

function files = make_thesis_gdp_accounting(mat_tag, out_dir, ctx)
% GDP accounting: nominal vs real, formal vs informal, consistencia Walras.

Y_F = read_scalar_from_context(ctx, {'Y_F'}, NaN);
Y_I = read_scalar_from_context(ctx, {'Y_I'}, NaN);
p_I = read_scalar_from_context(ctx, {'p_I_star','p_I'}, NaN);
C_F = read_scalar_from_context(ctx, {'C_F_agg'}, NaN);
C_I = read_scalar_from_context(ctx, {'C_I_agg'}, NaN);
K_star = read_scalar_from_context(ctx, {'K_star'}, NaN);
d_val = 0.05;  % depreciacion
KappaCost = 0;  % aproximado

GDP_nom_F = Y_F;  % p_F = 1 numerario
GDP_nom_I = p_I * Y_I;
GDP_nom_total = GDP_nom_F + GDP_nom_I;
GDP_real_F = Y_F;
GDP_real_I = Y_I;
GDP_real_total = Y_F + Y_I;

consumo_nom_F = C_F;
consumo_nom_I = p_I * C_I;
consumo_nom_total = consumo_nom_F + consumo_nom_I;
inversion = d_val * K_star;

% Walras: Y_F = C_F + I + KappaCost => residual
walras_F = GDP_nom_F - consumo_nom_F - inversion;

share_informal_real = GDP_real_I / max(GDP_real_total, 1e-12);
share_informal_nom = GDP_nom_I / max(GDP_nom_total, 1e-12);
share_consumo_informal = consumo_nom_I / max(consumo_nom_total, 1e-12);

T5_data = read_scalar_from_context(ctx, {'T5_data'}, NaN);

fig = figure('Color','white','Position',[80 80 1200 650]);
tiledlayout(fig, 1, 2, 'TileSpacing','compact', 'Padding','compact');

% Panel 1: Composicion del PBI nominal y destino del producto
nexttile;
axis off;
text(0.05, 0.95, 'Composicion del Gasto (destino del producto)', 'FontSize', 12, 'FontWeight','bold');
text(0.05, 0.85, sprintf('Consumo formal:        C_F     = %.4f  (%.1f%%)', consumo_nom_F, 100*consumo_nom_F/(consumo_nom_total+inversion)), 'FontSize', 11);
text(0.05, 0.78, sprintf('Consumo informal:      p_I C_I = %.4f  (%.1f%%)', consumo_nom_I, 100*consumo_nom_I/(consumo_nom_total+inversion)), 'FontSize', 11);
text(0.05, 0.71, sprintf('Inversion:             d K     = %.4f  (%.1f%%)', inversion, 100*inversion/(consumo_nom_total+inversion)), 'FontSize', 11);
text(0.05, 0.64, sprintf('Gasto total:           C + I   = %.4f  (100%%)', consumo_nom_total+inversion), 'FontSize', 11, 'FontWeight','bold');
text(0.05, 0.52, 'Composicion del PBI (origen del producto)', 'FontSize', 12, 'FontWeight','bold');
text(0.05, 0.42, sprintf('PBI formal:            Y_F     = %.4f  (%.1f%%)', GDP_nom_F, 100*GDP_nom_F/GDP_nom_total), 'FontSize', 11);
text(0.05, 0.35, sprintf('PBI informal nominal:  p_I Y_I = %.4f  (%.1f%%)', GDP_nom_I, 100*share_informal_nom), 'FontSize', 11);
text(0.05, 0.28, sprintf('PBI total:             Y       = %.4f  (100%%)', GDP_nom_total), 'FontSize', 11, 'FontWeight','bold');
if isfinite(T5_data)
    text(0.05, 0.17, sprintf('T5 informal nominal: %.3f  (dato Peru: %.3f)', share_informal_nom, T5_data), 'FontSize', 11, 'FontWeight','bold', 'Color', [0.82 0.32 0.12]);
end
text(0.05, 0.07, sprintf('Cierre Walras: Y_F - C_F - d K = %.2e', walras_F), 'FontSize', 9);

% Panel 2: Tabla contable
nexttile;
axis off;
text(0.05, 0.95, 'Contabilidad Nacional — Equilibrio Estacionario', 'FontSize', 14, 'FontWeight','bold');

y0 = 0.85;
text(0.05, y0, 'PRODUCCION (real)', 'FontSize', 11, 'FontWeight','bold');
text(0.05, y0-0.04, sprintf('Y_F = %.4f    Y_I = %.4f    Total real = %.4f', Y_F, Y_I, GDP_real_total), 'FontSize', 10);
text(0.05, y0-0.08, sprintf('Share informal real = Y_I/(Y_F+Y_I) = %.3f', share_informal_real), 'FontSize', 10);

text(0.05, y0-0.15, 'PBI NOMINAL (precios corrientes)', 'FontSize', 11, 'FontWeight','bold');
text(0.05, y0-0.19, sprintf('p_F Y_F = %.4f    p_I Y_I = %.4f    Total nominal = %.4f', GDP_nom_F, GDP_nom_I, GDP_nom_total), 'FontSize', 10);
text(0.05, y0-0.23, sprintf('Share informal nominal = p_I Y_I/(Y_F+p_I Y_I) = %.3f  [T5 dato=%.3f]', ...
    share_informal_nom, T5_data), 'FontSize', 10, 'FontWeight','bold');

text(0.05, y0-0.30, 'CONSUMO (nominal)', 'FontSize', 11, 'FontWeight','bold');
text(0.05, y0-0.34, sprintf('C_F = %.4f    p_I C_I = %.4f    Total consumo = %.4f', ...
    consumo_nom_F, consumo_nom_I, consumo_nom_total), 'FontSize', 10);
text(0.05, y0-0.38, sprintf('Share consumo informal = %.3f  (vs share PBI informal = %.3f)', ...
    share_consumo_informal, share_informal_nom), 'FontSize', 10);

text(0.05, y0-0.45, 'INVERSION Y CIERRE', 'FontSize', 11, 'FontWeight','bold');
text(0.05, y0-0.49, sprintf('Inversion bruta d*K = %.4f x %.4f = %.4f', d_val, K_star, inversion), 'FontSize', 10);
text(0.05, y0-0.53, sprintf('Walras bien formal: Y_F - C_F - d*K = %.4e (≈0)', walras_F), 'FontSize', 10);

text(0.55, y0, 'PRECIOS DE EQUILIBRIO', 'FontSize', 11, 'FontWeight','bold');
text(0.55, y0-0.04, sprintf('r* = %.6f', read_scalar_from_context(ctx,{'r_star'},NaN)), 'FontSize', 10);
text(0.55, y0-0.08, sprintf('w_F* = %.4f', read_scalar_from_context(ctx,{'w_F_star'},NaN)), 'FontSize', 10);
text(0.55, y0-0.12, sprintf('w_I* = %.4f', read_scalar_from_context(ctx,{'w_I_star'},NaN)), 'FontSize', 10);
text(0.55, y0-0.16, sprintf('p_I* = %.4f', p_I), 'FontSize', 10);
text(0.55, y0-0.20, sprintf('K_F* = %.4f  K_I* = %.4f', ...
    read_scalar_from_context(ctx,{'K_F_star'},NaN), ...
    read_scalar_from_context(ctx,{'K_I_star'},NaN)), 'FontSize', 10);
text(0.55, y0-0.24, sprintf('L_F* = %.4f  L_I* = %.4f', ...
    read_scalar_from_context(ctx,{'L_F_star'},NaN), ...
    read_scalar_from_context(ctx,{'L_I_star'},NaN)), 'FontSize', 10);

text(0.05, 0.03, 'Nota: p_F=1 (numerario). Share informal nominal es el target T5 correcto (INEI Cuenta Satelite).', ...
    'FontSize', 9);

sgtitle(sprintf('Contabilidad del Modelo — Equilibrio General | %s', mat_tag), 'FontWeight','bold');

png_file = fullfile(out_dir, sprintf('thesis_gdp_accounting_%s.png', mat_tag));
save_png_local(fig, png_file, 300);
files = struct('png', png_file);
end

function files = make_thesis_mechanism_summary(mat_tag, out_dir, a, z, g, da, ...
    c, c_F, c_I, exp_cons, ell_F, ell_I, debt_spread_z, ctx)
% Figura RESUMEN de una pagina: el mecanismo central de la tesis.
% Disenada para ser la figura principal de la defensa.
%
% Panel 1: Proceso OU + momentos condicionales
% Panel 2: Oferta laboral por tipo z
% Panel 3: Distribucion de riqueza
% Panel 4: Evidencia de trampa (informalidad por quintil)

[I, Ns] = size(g);
idx_show = unique([1, max(1, round((Ns+1)/2)), Ns], 'stable');
z_colors = [0.77 0.18 0.14; 0.35 0.35 0.35; 0.05 0.43 0.65];
if numel(idx_show) == 2, z_colors = z_colors([1 3],:); end

g_marg_a = sum(g, 2);
cdf_a = cumsum(g_marg_a) * da;
p_I_val = read_scalar_from_context(ctx, {'p_I_star','p_I'}, NaN);
T4_data = read_scalar_from_context(ctx, {'T4_data'}, NaN);

% Momentos condicionales
mean_a_by_z = zeros(1,Ns);
form_share_by_z = zeros(1,Ns);
mass_debt_by_z = zeros(1,Ns);
for j = 1:Ns
    mass_j = da * sum(g(:,j));
    mean_a_by_z(j) = da * sum(g(:,j) .* a) / max(mass_j, 1e-12);
    ellF_j = da * sum(g(:,j) .* ell_F(:,j)) / max(mass_j, 1e-12);
    ellI_j = da * sum(g(:,j) .* ell_I(:,j)) / max(mass_j, 1e-12);
    form_share_by_z(j) = ellF_j / max(ellF_j + ellI_j, 1e-12);
    mass_debt_by_z(j) = da * sum(g(:,j) .* (a < 0)) / max(mass_j, 1e-12);
end

% Quintiles para trampa
[qshare, ~] = weighted_quintile_shares(a * ones(1, Ns), g, da, 5);
Q_informal = zeros(5,1);
Q_debt = zeros(5,1);
for q = 1:5
    gm = g .* qshare{q};
    Q_mass = da * sum(gm(:));
    ellF_q = da * sum(sum(gm .* ell_F)) / max(Q_mass, 1e-12);
    ellI_q = da * sum(sum(gm .* ell_I)) / max(Q_mass, 1e-12);
    Q_informal(q) = ellI_q / max(ellF_q + ellI_q, 1e-12);
    Q_debt(q) = da * sum(sum(gm .* (a * ones(1, Ns) < 0))) / max(Q_mass, 1e-12);
end

rho_z = read_scalar_from_context(ctx, {'rho_z_ar'}, NaN);
sd_z  = read_scalar_from_context(ctx, {'sd_logz_ar'}, NaN);

fig = figure('Color','white','Position',[50 50 1500 1000]);
tiledlayout(fig, 2, 2, 'TileSpacing','compact', 'Padding','compact');

% --- PANEL 1: Proceso exogeno + fricciones ---
nexttile;
yyaxis left;
plot(z, mean_a_by_z, '-o', 'Color', [0.05 0.43 0.65], 'LineWidth', 2.2, 'MarkerSize', 6);
ylabel('Riqueza media E[a|z]');
yyaxis right;
plot(z, mass_debt_by_z, '--s', 'Color', [0.82 0.32 0.12], 'LineWidth', 2.0, 'MarkerSize', 6);
hold on;
plot(z, debt_spread_z, ':^', 'Color', [0.45 0.20 0.60], 'LineWidth', 2.0, 'MarkerSize', 6);
ylabel('Pr(a<0|z) / spread');
xlabel('Productividad z');
if isfinite(rho_z) && isfinite(sd_z)
    title(sprintf('Proceso OU: \\rho_z=%.3f, \\sigma_{log z}=%.3f  |  Riqueza y deuda por z', rho_z, sd_z));
else
    title('Riqueza media y deuda por estado de productividad z');
end
legend({'E[a|z]','Pr(a<0|z)','Prima deuda'}, 'Location','northwest');
grid on;

% --- PANEL 2: Oferta laboral ---
nexttile;
hold on;
for kk = 1:numel(idx_show)
    j = idx_show(kk);
    plot(a, ell_F(:,j), '-', 'Color', z_colors(kk,:), 'LineWidth', 2.0, ...
        'DisplayName', sprintf('Formal, z=%.2f', z(j)));
    plot(a, ell_I(:,j), '--', 'Color', z_colors(kk,:), 'LineWidth', 2.0, ...
        'DisplayName', sprintf('Informal, z=%.2f', z(j)));
end
xline(0, ':', 'Color', [0.35 0.35 0.35], 'HandleVisibility','off');
xlabel('Riqueza neta a');
ylabel('Horas');
title('Oferta laboral: formal (--) e informal (--) por productividad');
legend('Location','best', 'FontSize', 8);
grid on;

% --- PANEL 3: Distribucion de riqueza ---
nexttile;
wealth_pdf = g_marg_a / max(sum(g_marg_a)*da, 1e-12);
plot(a, wealth_pdf, 'k-', 'LineWidth', 2.2, 'DisplayName', 'Total');
hold on;
for kk = 1:numel(idx_show)
    j = idx_show(kk);
    mass_j = da * sum(g(:,j));
    plot(a, g(:,j)/max(mass_j*da,1e-12), 'Color', z_colors(kk,:), 'LineWidth', 1.8, ...
        'DisplayName', sprintf('z=%.2f', z(j)));
end
xline(0, ':', 'Color', [0.35 0.35 0.35], 'HandleVisibility','off');
xlabel('Riqueza neta a');
ylabel('Densidad');
title('Distribucion estacionaria de riqueza g(a)');
legend('Location','best');
grid on;

% --- PANEL 4: Evidencia de trampa ---
nexttile;
bar([Q_informal, Q_debt], 'grouped');
set(gca, 'XTick', 1:5, 'XTickLabel', {'Q1','Q2','Q3','Q4','Q5'});
xlabel('Quintil de riqueza');
ylabel('Proporcion');
title('Informalidad y deuda por quintil de riqueza');
legend({'Share horas informales', 'Pr(a<0)'}, 'Location','northwest');
if isfinite(T4_data)
    yline(T4_data, '--', 'Color', [0.25 0.25 0.25], 'LineWidth', 1.2);
    text(3, T4_data+0.02, sprintf('Meta T4=%.1f%%', 100*T4_data), 'FontSize', 9);
end
grid on;

sgtitle(sprintf('Resumen del modelo: Productividad, Riqueza e Informalidad en Peru | %s', mat_tag), ...
    'FontWeight','bold', 'FontSize', 14);

png_file = fullfile(out_dir, sprintf('thesis_mechanism_summary_%s.png', mat_tag));
save_png_local(fig, png_file, 300);
files = struct('png', png_file);
end

function files = make_thesis_tabla1_riqueza_labor(mat_tag, out_dir, a, z, aa, zz, g, da, ...
    ell_F, ell_I, ctx)
% Tabla 1: Riqueza Media y Oferta de Trabajo por Cuartil de Riqueza y Productividad.
% Version OU puro (sin q). Formato listo para insertar en la tesis.

[I, Ns] = size(g);
z_low_idx = 1;
z_high_idx = Ns;

% Cuartiles via weighted_quintile_shares (usamos Q1,Q2,Q3,Q4)
[qshare, ~] = weighted_quintile_shares(aa, g, da, 5);
qlabels = {'Q1', 'Q2', 'Q3', 'Q4', 'Total'};

% --- Panel A: Toda la poblacion ---
Q_metrics = zeros(5, 5);  % [riqueza, ell_F, ell_I, ell_total, share_inf]
for q = 1:4
    gm = g .* qshare{q};
    Q_mass = da * sum(gm(:));
    Q_metrics(q,1) = da * sum(sum(gm .* aa)) / max(Q_mass, 1e-12);
    Q_metrics(q,2) = da * sum(sum(gm .* ell_F)) / max(Q_mass, 1e-12);
    Q_metrics(q,3) = da * sum(sum(gm .* ell_I)) / max(Q_mass, 1e-12);
    Q_metrics(q,4) = Q_metrics(q,2) + Q_metrics(q,3);
    Q_metrics(q,5) = Q_metrics(q,3) / max(Q_metrics(q,4), 1e-12);
end
Q_metrics(5,1) = da * sum(sum(g .* aa));
Q_metrics(5,2) = da * sum(sum(g .* ell_F));
Q_metrics(5,3) = da * sum(sum(g .* ell_I));
Q_metrics(5,4) = Q_metrics(5,2) + Q_metrics(5,3);
Q_metrics(5,5) = Q_metrics(5,3) / max(Q_metrics(5,4), 1e-12);

% --- Panel B: Por tipo de productividad (z bajo, z alto) ---
Z_metrics = cell(2,1);
z_idx_list = [z_low_idx, z_high_idx];
z_names = {sprintf('z bajo = %.2f', z(z_low_idx)), ...
           sprintf('z alto = %.2f', z(z_high_idx))};

for gz = 1:2
    z_idx = z_idx_list(gz);
    zm = zeros(5, 5);
    mask = zeros(size(g));
    mask(:, z_idx) = 1;
    for q = 1:4
        gm = g .* qshare{q} .* mask;
        Q_mass = da * sum(gm(:));
        if Q_mass > 1e-12
            zm(q,1) = da * sum(sum(gm .* aa)) / Q_mass;
            zm(q,2) = da * sum(sum(gm .* ell_F)) / Q_mass;
            zm(q,3) = da * sum(sum(gm .* ell_I)) / Q_mass;
            zm(q,4) = zm(q,2) + zm(q,3);
            zm(q,5) = zm(q,3) / max(zm(q,4), 1e-12);
        end
    end
    gm_all = g .* mask;
    Q_mass_all = da * sum(gm_all(:));
    zm(5,1) = da * sum(sum(gm_all .* aa)) / max(Q_mass_all, 1e-12);
    zm(5,2) = da * sum(sum(gm_all .* ell_F)) / max(Q_mass_all, 1e-12);
    zm(5,3) = da * sum(sum(gm_all .* ell_I)) / max(Q_mass_all, 1e-12);
    zm(5,4) = zm(5,2) + zm(5,3);
    zm(5,5) = zm(5,3) / max(zm(5,4), 1e-12);
    Z_metrics{gz} = zm;
end

T4_data = read_scalar_from_context(ctx, {'T4_data'}, NaN);

fig = figure('Color','white','Position',[40 40 1580 780]);

% --- Panel A: Tabla general ---
subplot(1,2,1);
axis off;
text(0.02, 0.96, 'Tabla 1a: Riqueza Media y Oferta Laboral por Cuartil', ...
    'FontSize', 12, 'FontWeight','bold');
text(0.02, 0.92, 'Todos los agentes, 7 estados OU', 'FontSize', 9);

col_hdrs = {'Riqueza', 'ell_F', 'ell_I', 'ell Total', 'Share Inf'};
col_x = [0.02, 0.22, 0.38, 0.54, 0.68, 0.82];
y0 = 0.86;
row_h = 0.07;

for cc = 1:numel(col_hdrs)
    text((col_x(cc)+col_x(cc+1))/2, y0, col_hdrs{cc}, 'FontSize', 9, ...
        'FontWeight','bold', 'HorizontalAlignment','center');
end
for rr = 1:5
    yy = y0 - row_h*rr;
    text(col_x(1)+0.02, yy, qlabels{rr}, 'FontSize', 9, 'FontWeight','bold');
    for cc = 1:5
        text((col_x(cc)+col_x(cc+1))/2, yy, sprintf('%.4f', Q_metrics(rr,cc)), ...
            'FontSize', 9, 'HorizontalAlignment','center');
    end
end
text(0.02, y0-row_h*6, sprintf('T4 informalidad dato=%.3f  |  modelo=%.4f', ...
    T4_data, Q_metrics(5,5)), 'FontSize', 8.5);

% --- Panel B: Por z ---
subplot(1,2,2);
for gz = 1:2
    subplot(2,1,gz);
    axis off;
    text(0.02, 0.88, sprintf('Tabla 1b: %s', z_names{gz}), 'FontSize', 11, 'FontWeight','bold');

    zm = Z_metrics{gz};
    col_x2 = [0.02, 0.22, 0.38, 0.54, 0.68, 0.82];
    for cc = 1:numel(col_hdrs)
        text((col_x2(cc)+col_x2(cc+1))/2, 0.76, col_hdrs{cc}, 'FontSize', 8.5, ...
            'FontWeight','bold', 'HorizontalAlignment','center');
    end
    for rr = 1:5
        yy = 0.68 - 0.10*rr;
        text(col_x2(1)+0.02, yy, qlabels{rr}, 'FontSize', 8.5);
        for cc = 1:5
            text((col_x2(cc)+col_x2(cc+1))/2, yy, sprintf('%.3f', zm(rr,cc)), ...
                'FontSize', 8.5, 'HorizontalAlignment','center');
        end
    end
end

sgtitle(sprintf('Tabla 1: Riqueza y Oferta Laboral | Modelo OU | %s', mat_tag), ...
    'FontWeight','bold', 'FontSize', 14);

png_file = fullfile(out_dir, sprintf('thesis_tabla1_riqueza_labor_%s.png', mat_tag));
save_png_local(fig, png_file, 300);
files = struct('png', png_file);
end

function files = make_income_decomposition_by_quintile(mat_tag, out_dir, a, z, aa, zz, g, da, ...
    exp_cons, debt_spread_aa, ctx)
% Descomposicion del ingreso medio por quintil de riqueza.
% Componentes: laboral formal, laboral informal, capital, transferencia, costo deuda.

[I, Ns] = size(g);

has_labor = isfield(ctx, 'ell_F') && isfield(ctx, 'ell_I');
if has_labor
    ell_F = ctx.ell_F;
    ell_I = ctx.ell_I;
else
    ell_F = zeros(I, Ns);
    ell_I = zeros(I, Ns);
end

kappa_F_aa = read_matrix_from_context(ctx, 'kappa_F_aa', zeros(I,Ns));
qq_informal = read_matrix_from_context(ctx, 'qq_informal', ones(I,Ns));
if isempty(debt_spread_aa) || ~isequal(size(debt_spread_aa), [I, Ns])
    debt_spread_aa = zeros(I, Ns);
end

w_F    = read_scalar_from_context(ctx, {'w_F_star','w_F'}, NaN);
w_I_hh = read_scalar_from_context(ctx, {'w_I_household_star','w_I_star','w_I'}, NaN);
theta  = read_scalar_from_context(ctx, {'theta'}, 1);
nu_I   = read_scalar_from_context(ctx, {'nu_I'}, 1);
r_eq   = read_scalar_from_context(ctx, {'r_star','r_eq','r'}, 0);
tau    = read_scalar_from_context(ctx, {'tau'}, 0);
T_lump = read_scalar_from_context(ctx, {'T_eq','T_star','T'}, 0);
Pi_lump = read_scalar_from_context(ctx, {'Pi_lump_star'}, NaN);
if ~isfinite(Pi_lump)
    profit_rule = read_char_from_context(ctx, 'informal_profit_rule', 'lump');
    if strcmpi(profit_rule, 'lump')
        Pi_lump = read_scalar_from_context(ctx, {'profit_I_star'}, 0);
    else
        Pi_lump = 0;
    end
end

% Matrices de ingresos (I x Ns)
inc_formal   = ((1 - tau) * w_F * zz - kappa_F_aa) .* ell_F;
inc_informal = w_I_hh * theta * (zz .^ nu_I) .* qq_informal .* ell_I;
inc_capital  = r_eq * aa;
inc_transfer = (T_lump + Pi_lump) * ones(I, Ns);
inc_debt_cost = -debt_spread_aa .* max(-aa, 0);   % <= 0

% Quintiles de riqueza
[qshare, qcuts] = weighted_quintile_shares(aa, g, da, 5);
qlabels = {'Q1','Q2','Q3','Q4','Q5'};
nq = 5;

Q_formal    = zeros(nq, 1);
Q_informal  = zeros(nq, 1);
Q_capital   = zeros(nq, 1);
Q_transfer  = zeros(nq, 1);
Q_debt_cost = zeros(nq, 1);
Q_exp       = zeros(nq, 1);
Q_mass      = zeros(nq, 1);

for q = 1:nq
    gm = g .* qshare{q};
    mq = da * sum(gm(:));
    Q_mass(q)      = mq;
    if mq < 1e-14, continue; end
    Q_formal(q)    = da * sum(sum(gm .* inc_formal))    / mq;
    Q_informal(q)  = da * sum(sum(gm .* inc_informal))  / mq;
    Q_capital(q)   = da * sum(sum(gm .* inc_capital))   / mq;
    Q_transfer(q)  = da * sum(sum(gm .* inc_transfer))  / mq;
    Q_debt_cost(q) = da * sum(sum(gm .* inc_debt_cost)) / mq;
    Q_exp(q)       = da * sum(sum(gm .* exp_cons))      / mq;
end

Q_gross_income = Q_formal + Q_informal + Q_capital + Q_transfer;
Q_net_income   = Q_gross_income + Q_debt_cost;

% Shares sobre ingreso bruto (> 0 para poder mostrar porcentaje)
denom = max(Q_gross_income, 1e-12);
sh_formal   = Q_formal   ./ denom;
sh_informal = Q_informal ./ denom;
sh_capital  = Q_capital  ./ denom;
sh_transfer = Q_transfer ./ denom;

stacked_abs   = [Q_formal, Q_informal, Q_capital, Q_transfer];
stacked_share = [sh_formal, sh_informal, sh_capital, sh_transfer];

T4_data   = read_scalar_from_context(ctx, {'T4_data'}, NaN);
T4_model  = read_scalar_from_context(ctx, {'T4_model'}, NaN);
Gini_a    = read_scalar_from_context(ctx, {'Gini_a'}, NaN);
Gini_c    = read_scalar_from_context(ctx, {'Gini_c'}, NaN);

comp_colors = [0.05 0.43 0.65;   % formal  — azul
               0.82 0.32 0.12;   % informal — naranja
               0.18 0.63 0.27;   % capital  — verde
               0.65 0.45 0.75];  % transfer — lila

fig = figure('Color','white','Position',[50 50 1500 960]);
tiledlayout(fig, 2, 2, 'TileSpacing','compact', 'Padding','compact');

% --- Panel 1: Niveles absolutos ---
nexttile;
b = bar(stacked_abs, 'stacked');
for kc = 1:4, b(kc).FaceColor = comp_colors(kc,:); end
hold on;
plot(1:nq, Q_debt_cost, 'v', 'Color', [0.77 0.18 0.14], 'MarkerSize', 8, ...
    'LineWidth', 1.8, 'DisplayName','Costo prima deuda');
plot(1:nq, Q_net_income, 's--', 'Color', [0.25 0.25 0.25], 'LineWidth', 1.8, ...
    'MarkerSize', 6, 'DisplayName','Ingreso neto');
yline(0, ':', 'Color',[0.4 0.4 0.4], 'HandleVisibility','off');
set(gca, 'XTick',1:nq, 'XTickLabel',qlabels, 'TickLabelInterpreter','none');
ylabel('Ingreso medio', 'Interpreter','none');
xlabel('Quintil de riqueza', 'Interpreter','none');
title('Descomposicion del ingreso medio por quintil', 'Interpreter','none');
legend({'Lab. formal','Lab. informal','Capital','Transferencia','Costo deuda','Ingreso neto'}, ...
    'Location','northwest', 'Interpreter','none', 'FontSize', 8);
grid on;

% --- Panel 2: Composicion porcentual (sobre ingreso bruto) ---
nexttile;
b2 = bar(stacked_share * 100, 'stacked');
for kc = 1:4, b2(kc).FaceColor = comp_colors(kc,:); end
set(gca, 'XTick',1:nq, 'XTickLabel',qlabels, 'TickLabelInterpreter','none');
ylabel('% del ingreso bruto', 'Interpreter','none');
xlabel('Quintil de riqueza', 'Interpreter','none');
title('Estructura del ingreso (% ingreso bruto)', 'Interpreter','none');
legend({'Lab. formal','Lab. informal','Capital','Transferencia'}, ...
    'Location','best', 'Interpreter','none', 'FontSize', 8);
ylim([0 120]);
grid on;

% --- Panel 3: Ingreso neto vs gasto por quintil ---
nexttile;
plot(1:nq, Q_net_income, 'o-', 'Color',[0.05 0.43 0.65], 'LineWidth', 2.0, ...
    'MarkerSize', 7, 'DisplayName','Ingreso neto');
hold on;
plot(1:nq, Q_exp, 's--', 'Color',[0.82 0.32 0.12], 'LineWidth', 2.0, ...
    'MarkerSize', 7, 'DisplayName','Gasto c_F + p_I c_I');
plot(1:nq, Q_net_income - Q_exp, '^:', 'Color',[0.18 0.63 0.27], 'LineWidth', 1.8, ...
    'MarkerSize', 6, 'DisplayName','Ahorro = ingreso - gasto');
yline(0, ':', 'Color',[0.4 0.4 0.4], 'HandleVisibility','off');
set(gca, 'XTick',1:nq, 'XTickLabel',qlabels, 'TickLabelInterpreter','none');
ylabel('Media dentro del quintil', 'Interpreter','none');
xlabel('Quintil de riqueza', 'Interpreter','none');
title('Ingreso neto vs gasto vs ahorro por quintil', 'Interpreter','none');
legend('Location','northwest', 'Interpreter','none');
grid on;

% --- Panel 4: Resumen texto ---
nexttile;
axis off;
text(0.03, 0.95, 'Descomposicion del ingreso por quintil — OU model', ...
    'FontSize', 13, 'FontWeight','bold', 'Interpreter','none');
text(0.03, 0.88, sprintf('tau=%.3f | T+Pi=%.4f | r*=%.4f | Gini riqueza=%.3f | Gini gasto=%.3f', ...
    tau, T_lump+Pi_lump, r_eq, Gini_a, Gini_c), 'FontSize', 9, 'Interpreter','none');

row_labels = {'Q1','Q2','Q3','Q4','Q5'};
col_labels = {'Lab. F', 'Lab. I', 'Capital', 'Transfer', 'Deuda', 'Neto', 'Gasto'};
tbl_vals = [Q_formal, Q_informal, Q_capital, Q_transfer, Q_debt_cost, Q_net_income, Q_exp];
col_x = linspace(0.03, 0.97, numel(col_labels)+1);
y0 = 0.80; rh = 0.08;
for cc = 1:numel(col_labels)
    text((col_x(cc)+col_x(cc+1))/2, y0, col_labels{cc}, 'FontSize', 8.5, ...
        'FontWeight','bold', 'HorizontalAlignment','center', 'Interpreter','none');
end
for rr = 1:nq
    yy = y0 - rh * rr;
    text(0.01, yy, row_labels{rr}, 'FontSize', 8.5, 'FontWeight','bold', 'Interpreter','none');
    for cc = 1:numel(col_labels)
        val = tbl_vals(rr, cc);
        text((col_x(cc)+col_x(cc+1))/2, yy, sprintf('%.4f', val), ...
            'FontSize', 8, 'HorizontalAlignment','center', 'Interpreter','none');
    end
end
text(0.03, y0 - rh*(nq+1.3), ...
    sprintf('T4 informalidad: modelo=%.3f | dato=%.3f', T4_model, T4_data), ...
    'FontSize', 9, 'Interpreter','none');
text(0.03, y0 - rh*(nq+2.2), ...
    sprintf('Cortes riqueza: %.3f | %.3f | %.3f | %.3f', qcuts), ...
    'FontSize', 8.5, 'Interpreter','none');
text(0.03, 0.04, ...
    ['Lectura: ingreso laboral formal incluye descuento tau. Capital puede ser negativo (deudores). ' ...
    'Costo prima deuda = -spread*max(-a,0) <= 0.'], ...
    'FontSize', 8, 'Interpreter','none');

sgtitle(sprintf('Descomposicion de Ingreso por Quintil de Riqueza | %s', mat_tag), ...
    'Interpreter','none', 'FontWeight','bold');

png_file = fullfile(out_dir, sprintf('income_decomposition_by_quintile_%s.png', mat_tag));
save_png_local(fig, png_file, 300);

txt_file = fullfile(out_dir, sprintf('income_decomposition_by_quintile_%s.txt', mat_tag));
fid = fopen(txt_file, 'w');
if fid >= 0
    fprintf(fid, 'Income decomposition by wealth quintile\n');
    fprintf(fid, 'mat_tag=%s\n', mat_tag);
    fprintf(fid, 'q mass lab_formal lab_informal capital transfer debt_cost net_income expenditure\n');
    for q = 1:nq
        fprintf(fid, '%d %.10f %.10f %.10f %.10f %.10f %.10f %.10f %.10f\n', ...
            q, Q_mass(q), Q_formal(q), Q_informal(q), Q_capital(q), ...
            Q_transfer(q), Q_debt_cost(q), Q_net_income(q), Q_exp(q));
    end
    fclose(fid);
end

files = struct('png', png_file, 'txt', txt_file);
end
