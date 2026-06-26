function plot_moll_matlab_all(mat_file, out_dir, only_figures)
%PLOT_MOLL_MATLAB_ALL Generate Moll-style figures from a saved HA .mat file.
%
% Usage:
%   plot_moll_matlab_all('outputs/stationary/RUN/results_RUN.mat')
%   plot_moll_matlab_all('outputs/stationary/RUN/results_RUN.mat', ...
%       'outputs/stationary/RUN/plots_matlab')
%   plot_moll_matlab_all(..., {'consumption_formal_z','lorenz'})
%
% This file is deliberately separate from model_main.m. The model solves and
% saves a complete results_*.mat payload; this plotter only reads that payload
% and writes figures. It does not require any variables in the caller workspace.

if nargin < 1 || isempty(mat_file)
    mat_file = default_results_file();
end
if nargin < 2 || isempty(out_dir)
    out_dir = fullfile(fileparts(mat_file), 'plots_matlab');
end
if nargin < 3
    only_figures = {};
end
if ~exist(mat_file, 'file')
    error('No se encontro el .mat: %s', mat_file);
end
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

ctx = load(mat_file);
ctx.mat_file = mat_file;
ctx.out_dir = out_dir;
ctx = prepare_context(ctx);
write_payload_audit(ctx);
set_moll_style();

fprintf('Generando figuras MATLAB estilo Moll en:\n  %s\n', out_dir);

if ~isempty(only_figures)
    run_selected_figures(ctx, only_figures);
    fprintf('Listo. PNGs seleccionados guardados en:\n  %s\n', out_dir);
    return;
end

fig_savings_policy(ctx);
fig_wealth_distribution_by_z(ctx);
fig_wealth_density_by_z(ctx);
fig_wealth_density_marginal(ctx);
fig_density_surface_3d(ctx);
fig_savings_surface_3d(ctx);
fig_consumption_surface_3d(ctx);
fig_expenditure_surface_3d(ctx);
fig_consumption_policy(ctx);
fig_consumption_labor_policy(ctx);
fig_consumption_distribution(ctx);
fig_consumption_components_distribution(ctx);
fig_consumption_components_by_z(ctx);
fig_consumption_components_distribution_by_z_groups(ctx);
fig_consumption_formal_distribution_by_z_groups(ctx);
fig_consumption_informal_distribution_by_z_groups(ctx);
fig_labor_policy_by_wealth(ctx);
fig_formal_hours_surface_3d(ctx);
fig_informal_hours_surface_3d(ctx);
fig_labor_supply_by_productivity(ctx);
fig_time_use_by_z_with_leisure(ctx);
fig_time_use_trend_by_z(ctx);
fig_time_use_by_z_excluding_leisure(ctx);
fig_income_decomposition_by_wealth_quintile(ctx);
fig_income_balance_by_wealth_quintile(ctx);
fig_income_decomposition_percent_by_wealth_quintile(ctx);
fig_informality_by_z(ctx);
fig_debt_probability_by_z(ctx);
fig_gasto_distribution_by_formality(ctx);
fig_lorenz_curves(ctx);
fig_debt_premium_inequality(ctx);
fig_ou_stationary_masses(ctx);
fig_conditional_moments_by_z(ctx);
fig_equilibrium_asset_market(ctx);
fig_calibration_tables(ctx);

fprintf('Listo. PNGs guardados en:\n  %s\n', out_dir);
end

function run_selected_figures(ctx, only_figures)
if ischar(only_figures) || isstring(only_figures)
    only_figures = cellstr(only_figures);
end
for k = 1:numel(only_figures)
    key = lower(strtrim(char(only_figures{k})));
    switch key
        case {'consumption_formal_z','formal_consumption_z','formal_z'}
            fig_consumption_formal_distribution_by_z_groups(ctx);
        case {'consumption_informal_z','informal_consumption_z','informal_z'}
            fig_consumption_informal_distribution_by_z_groups(ctx);
        case {'consumption_components_z','components_z'}
            fig_consumption_components_distribution_by_z_groups(ctx);
        case {'lorenz','lorenz_curves'}
            fig_lorenz_curves(ctx);
        case {'savings','ahorro','savings_policy'}
            fig_savings_policy(ctx);
        case {'surfaces','surface_3d','xyz'}
            fig_density_surface_3d(ctx);
            fig_savings_surface_3d(ctx);
            fig_consumption_surface_3d(ctx);
            fig_expenditure_surface_3d(ctx);
            fig_formal_hours_surface_3d(ctx);
            fig_informal_hours_surface_3d(ctx);
        case {'density_surface','density_3d'}
            fig_density_surface_3d(ctx);
        case {'savings_surface','savings_3d'}
            fig_savings_surface_3d(ctx);
        case {'consumption_surface','consumption_3d'}
            fig_consumption_surface_3d(ctx);
        case {'expenditure_surface','expenditure_3d'}
            fig_expenditure_surface_3d(ctx);
        case {'formal_hours_surface','formal_hours_3d'}
            fig_formal_hours_surface_3d(ctx);
        case {'informal_hours_surface','informal_hours_3d'}
            fig_informal_hours_surface_3d(ctx);
        otherwise
            warning('Figura seleccionada no reconocida: %s', key);
    end
end
end

function ctx = prepare_context(ctx)
required = {'a','z','g','c','da'};
missing = {};
for k = 1:numel(required)
    if ~isfield(ctx, required{k})
        missing{end+1} = required{k}; %#ok<AGROW>
    end
end
if ~isempty(missing)
    error('El .mat no contiene variables requeridas: %s', strjoin(missing, ', '));
end

ctx.a = ctx.a(:);
ctx.z = ctx.z(:)';
ctx.g = double(ctx.g);
ctx.c = double(ctx.c);
ctx.da = double(ctx.da);
[ctx.I, ctx.Ns] = size(ctx.g);
if numel(ctx.a) ~= ctx.I || numel(ctx.z) ~= ctx.Ns
    error('Dimensiones inconsistentes: a=%d, z=%d, g=%dx%d', ...
        numel(ctx.a), numel(ctx.z), ctx.I, ctx.Ns);
end
if ~isfield(ctx, 'aa'), ctx.aa = ctx.a * ones(1, ctx.Ns); end
if ~isfield(ctx, 'zz'), ctx.zz = ones(ctx.I, 1) * ctx.z; end

ctx.p_I = get_scalar(ctx, {'p_I_star','p_I'}, 1.0);
ctx.omega_C = get_scalar(ctx, {'omega_C'}, 0.5);
ctx.eta_C = get_scalar(ctx, {'eta_C'}, 0.5);
ctx.sigma_C = get_scalar(ctx, {'sigma_C'}, 1.0);
[ctx.c_F, ctx.c_I, ctx.exp_cons] = ces_split(ctx.c, ctx.p_I, ctx.omega_C, ctx.eta_C, ctx.sigma_C);

ctx.w_all = max(ctx.g(:) * ctx.da, 0);
ctx.g_marg_a = sum(ctx.g, 2);
ctx.mass_z = max(sum(ctx.g, 1) * ctx.da, 1e-12);
ctx.j_low = 1;
ctx.j_mid = max(1, round((ctx.Ns + 1) / 2));
ctx.j_high = ctx.Ns;
ctx.idx_show = unique([ctx.j_low, ctx.j_mid, ctx.j_high], 'stable');

ctx.zoom_lo = weighted_quantile(ctx.a, ctx.g_marg_a * ctx.da, 0.01);
ctx.zoom_hi = weighted_quantile(ctx.a, ctx.g_marg_a * ctx.da, 0.99);
if ~isfinite(ctx.zoom_lo) || ~isfinite(ctx.zoom_hi) || ctx.zoom_hi <= ctx.zoom_lo
    ctx.zoom_lo = min(ctx.a);
    ctx.zoom_hi = max(ctx.a);
end
if ctx.zoom_lo < 0 && ctx.zoom_hi > 0
    ctx.zoom_lo = min(ctx.zoom_lo, -0.08 * max(ctx.zoom_hi, 1e-8));
end

ctx.ell_F = get_matrix(ctx, 'ell_F', [ctx.I ctx.Ns], NaN);
ctx.ell_I = get_matrix(ctx, 'ell_I', [ctx.I ctx.Ns], NaN);
ctx.has_labor = all(isfinite(ctx.ell_F(:))) && all(isfinite(ctx.ell_I(:)));
ctx.H_bar = get_scalar(ctx, {'H_bar'}, 1.0);

ctx.r_star = get_scalar(ctx, {'r_star','r_eq','r'}, NaN);
ctx.w_F = get_scalar(ctx, {'w_F_star','w_F'}, NaN);
ctx.w_I = get_scalar(ctx, {'w_I_household_star','w_I_star','w_I'}, NaN);
ctx.tau = get_scalar(ctx, {'tau'}, 0.0);
ctx.theta = get_scalar(ctx, {'theta'}, 1.0);
ctx.nu_I = get_scalar(ctx, {'nu_I'}, 1.0);
ctx.T_lump = get_scalar(ctx, {'T_star','T_eq','T'}, 0.0);
ctx.Pi_lump = get_scalar(ctx, {'Pi_lump_star','profit_I_star'}, 0.0);
ctx.kappa_F_aa = get_matrix(ctx, 'kappa_F_aa', [ctx.I ctx.Ns], 0);
ctx.qq_informal = get_matrix(ctx, 'qq_informal', [ctx.I ctx.Ns], 1);
ctx.debt_spread_aa = get_matrix(ctx, 'debt_spread_aa', [ctx.I ctx.Ns], 0);
ctx.debt_spread_z = get_vector(ctx, 'debt_spread_z', ctx.Ns, zeros(1, ctx.Ns));
ctx.pi_z_ar = get_vector(ctx, 'pi_z_ar', ctx.Ns, []);
if isempty(ctx.pi_z_ar)
    ctx.pi_z_ar = ctx.mass_z / max(sum(ctx.mass_z), 1e-12);
else
    ctx.pi_z_ar = ctx.pi_z_ar / max(sum(ctx.pi_z_ar), 1e-12);
end

ctx.mean_a_by_z = zeros(1, ctx.Ns);
ctx.mean_exp_by_z = zeros(1, ctx.Ns);
ctx.mean_c_by_z = zeros(1, ctx.Ns);
ctx.mean_cF_by_z = zeros(1, ctx.Ns);
ctx.mean_pIcI_by_z = zeros(1, ctx.Ns);
ctx.mass_debt_by_z = zeros(1, ctx.Ns);
ctx.mean_a_debt_by_z = NaN(1, ctx.Ns);
ctx.mean_ellF_by_z = NaN(1, ctx.Ns);
ctx.mean_ellI_by_z = NaN(1, ctx.Ns);
ctx.form_share_by_z = NaN(1, ctx.Ns);
for j = 1:ctx.Ns
    wj = ctx.g(:,j) * ctx.da;
    mass_j = max(sum(wj), 1e-12);
    ctx.mean_a_by_z(j) = sum(wj .* ctx.a) / mass_j;
    ctx.mean_exp_by_z(j) = sum(wj .* ctx.exp_cons(:,j)) / mass_j;
    ctx.mean_c_by_z(j) = sum(wj .* ctx.c(:,j)) / mass_j;
    ctx.mean_cF_by_z(j) = sum(wj .* ctx.c_F(:,j)) / mass_j;
    ctx.mean_pIcI_by_z(j) = sum(wj .* (ctx.p_I * ctx.c_I(:,j))) / mass_j;
    ctx.mass_debt_by_z(j) = sum(wj .* (ctx.a < 0)) / mass_j;
    wd = wj(ctx.a < 0);
    if sum(wd) > 1e-12
        ctx.mean_a_debt_by_z(j) = sum(wd .* ctx.a(ctx.a < 0)) / sum(wd);
    end
    if ctx.has_labor
        ctx.mean_ellF_by_z(j) = sum(wj .* ctx.ell_F(:,j)) / mass_j;
        ctx.mean_ellI_by_z(j) = sum(wj .* ctx.ell_I(:,j)) / mass_j;
        ctx.form_share_by_z(j) = ctx.mean_ellF_by_z(j) / ...
            max(ctx.mean_ellF_by_z(j) + ctx.mean_ellI_by_z(j), 1e-12);
    end
end
den = max(ctx.mean_cF_by_z + ctx.mean_pIcI_by_z, 1e-12);
ctx.share_cF_by_z = ctx.mean_cF_by_z ./ den;
ctx.share_pIcI_by_z = ctx.mean_pIcI_by_z ./ den;

ctx.income_formal = zeros(ctx.I, ctx.Ns);
ctx.income_informal = zeros(ctx.I, ctx.Ns);
ctx.income_assets = zeros(ctx.I, ctx.Ns);
ctx.income_transfer = ctx.T_lump * ones(ctx.I, ctx.Ns);
ctx.income_profit = ctx.Pi_lump * ones(ctx.I, ctx.Ns);
ctx.adot = NaN(ctx.I, ctx.Ns);
if ctx.has_labor && isfinite(ctx.r_star) && isfinite(ctx.w_F) && isfinite(ctx.w_I)
    ctx.income_formal = ((1 - ctx.tau) * ctx.w_F .* ctx.zz - ctx.kappa_F_aa) .* ctx.ell_F;
    ctx.income_informal = ctx.w_I * ctx.theta .* (ctx.zz .^ ctx.nu_I) .* ctx.qq_informal .* ctx.ell_I;
    ctx.income_assets = ctx.r_star .* ctx.aa;
    debt_cost = -ctx.debt_spread_aa .* max(-ctx.aa, 0);
    ctx.net_income = ctx.income_formal + ctx.income_informal + ctx.income_assets + ...
        ctx.income_transfer + ctx.income_profit + debt_cost;
    ctx.adot = ctx.net_income - ctx.exp_cons;
end

[ctx.lorenz_pop_a, ctx.lorenz_a_plot, ctx.Gini_a_calc] = lorenz_curve(ctx.aa(:), ctx.w_all);
[ctx.lorenz_pop_c, ctx.lorenz_c_plot, ctx.Gini_c_calc] = lorenz_curve(ctx.exp_cons(:), ctx.w_all);
ctx.Gini_a = get_scalar(ctx, {'Gini_a','Gini_wealth','Gini'}, ctx.Gini_a_calc);
ctx.Gini_c = get_scalar(ctx, {'Gini_c','Gini_gasto','Gini_expenditure'}, ctx.Gini_c_calc);

ctx.run_tag = regexprep(char(get_field(ctx, 'results_file', 'results')), '^.*results_', '');
ctx.run_tag = regexprep(ctx.run_tag, '\.mat$', '');
end

function set_moll_style()
try
    opengl software;
catch
end
set(groot, 'defaultFigureColor', 'white');
set(groot, 'defaultFigureVisible', 'off');
set(groot, 'defaultFigureRenderer', 'opengl');
set(groot, 'defaultAxesFontName', 'Times New Roman');
set(groot, 'defaultTextFontName', 'Times New Roman');
set(groot, 'defaultAxesFontSize', 13);
set(groot, 'defaultAxesLineWidth', 0.8);
set(groot, 'defaultLineLineWidth', 2.0);
set(groot, 'defaultLegendBox', 'on');
set(groot, 'defaultLegendInterpreter', 'latex');
set(groot, 'defaultTextInterpreter', 'latex');
set(groot, 'defaultAxesTickLabelInterpreter', 'latex');
end

function fig_savings_policy(ctx)
if all(isnan(ctx.adot(:))), return; end
f = newfig([100 100 960 640]); ax = axes(f); hold(ax, 'on');
for jj = ctx.idx_show
    [col, ls, lab] = z_style(jj, ctx);
    plot(ax, ctx.a, ctx.adot(:,jj), 'Color', col, 'LineStyle', ls, ...
        'DisplayName', lab);
end
xline(ax, 0, ':k', 'HandleVisibility', 'off');
yline(ax, 0, ':k', 'HandleVisibility', 'off');
xlim(ax, [ctx.zoom_lo ctx.zoom_hi]);
xlabel(ax, 'Riqueza, $a$'); ylabel(ax, 'Ahorro, $s(a,z)$');
legend(ax, 'Location', 'best');
moll_axes(ax);
caption(f, 'Savings policy by productivity');
save_png(f, ctx, 'moll_savings_policy.png');
end

function fig_wealth_distribution_by_z(ctx)
f = newfig([100 100 960 640]); ax = axes(f); hold(ax, 'on');
for jj = ctx.idx_show
    wj = ctx.g(:,jj);
    density = wj / max(sum(wj) * ctx.da, 1e-12);
    density = density / max(max(density), 1e-12);
    [col, ls, lab] = z_style(jj, ctx);
    plot(ax, ctx.a, density, 'Color', col, 'LineStyle', ls, 'DisplayName', lab);
end
xline(ax, 0, ':k', 'HandleVisibility', 'off');
xlim(ax, [ctx.zoom_lo ctx.zoom_hi]); ylim(ax, [0 1.05]);
xlabel(ax, 'Riqueza, $a$'); ylabel(ax, 'Densidad condicional normalizada');
legend(ax, 'Location', 'best');
moll_axes(ax);
caption(f, 'Stationary wealth distribution by productivity');
save_png(f, ctx, 'moll_wealth_distribution_by_z.png');
end

function fig_wealth_density_by_z(ctx)
f = newfig([100 100 980 640]); ax = axes(f); hold(ax, 'on');
total = sum(ctx.g, 2);
plot(ax, ctx.a, total / max(max(total), 1e-12), 'k-', 'DisplayName', 'Total');
for jj = ctx.idx_show
    density = ctx.g(:,jj) / max(sum(ctx.g(:,jj)) * ctx.da, 1e-12);
    density = density / max(max(density), 1e-12);
    [col, ls, lab] = z_style(jj, ctx);
    plot(ax, ctx.a, density, 'Color', col, 'LineStyle', ls, 'DisplayName', lab);
    xline(ax, ctx.mean_a_by_z(jj), ':', 'Color', col, 'HandleVisibility', 'off');
end
xlim(ax, [ctx.zoom_lo ctx.zoom_hi]); ylim(ax, [0 1.05]);
xlabel(ax, 'Riqueza, $a$'); ylabel(ax, 'Densidad condicional normalizada');
legend(ax, 'Location', 'best');
moll_axes(ax);
caption(f, 'Wealth density by productivity; vertical lines are means');
save_png(f, ctx, 'moll_wealth_density_by_z_low_median_high.png');
end

function fig_wealth_density_marginal(ctx)
f = newfig([100 100 900 620]); ax = axes(f); hold(ax, 'on');
density = ctx.g_marg_a / max(sum(ctx.g_marg_a) * ctx.da, 1e-12);
plot(ax, ctx.a, density, 'k-', 'DisplayName', '$g(a)$');
xline(ax, 0, ':k', 'HandleVisibility', 'off');
xlim(ax, [ctx.zoom_lo ctx.zoom_hi]);
xlabel(ax, 'Riqueza, $a$'); ylabel(ax, 'Densidad estacionaria');
legend(ax, 'Location', 'best');
moll_axes(ax);
caption(f, 'Marginal stationary wealth density');
save_png(f, ctx, 'moll_wealth_density_marginal.png');
end

function fig_density_surface_3d(ctx)
f = newfig([100 100 980 700]);
[a_cut, g_cut] = surface_cut(ctx, ctx.g);
plot_surface_xyz(a_cut, ctx.z, g_cut, 'Riqueza, $a$', 'Productividad, $z$', '$g(a,z)$');
caption(f, 'Stationary density surface');
save_png(f, ctx, 'moll_density_surface_3d.png');
end

function fig_savings_surface_3d(ctx)
if all(isnan(ctx.adot(:))), return; end
f = newfig([100 100 980 700]);
[a_cut, x_cut] = surface_cut(ctx, ctx.adot);
plot_surface_xyz(a_cut, ctx.z, x_cut, 'Riqueza, $a$', 'Productividad, $z$', 'Ahorro, $s(a,z)$');
caption(f, 'Saving policy surface');
save_png(f, ctx, 'moll_savings_surface_3d.png');
end

function fig_consumption_surface_3d(ctx)
f = newfig([100 100 980 700]);
[a_cut, x_cut] = surface_cut(ctx, ctx.c);
plot_surface_xyz(a_cut, ctx.z, x_cut, 'Riqueza, $a$', 'Productividad, $z$', 'Consumo efectivo, $C(a,z)$');
caption(f, 'Effective consumption surface');
save_png(f, ctx, 'moll_consumption_surface_3d.png');
end

function fig_expenditure_surface_3d(ctx)
f = newfig([100 100 980 700]);
[a_cut, x_cut] = surface_cut(ctx, ctx.exp_cons);
plot_surface_xyz(a_cut, ctx.z, x_cut, 'Riqueza, $a$', 'Productividad, $z$', 'Gasto, $c_F+p_I c_I$');
caption(f, 'Expenditure surface');
save_png(f, ctx, 'moll_expenditure_surface_3d.png');
end

function fig_formal_hours_surface_3d(ctx)
if ~ctx.has_labor, return; end
f = newfig([100 100 980 700]);
[a_cut, x_cut] = surface_cut(ctx, ctx.ell_F);
plot_surface_xyz(a_cut, ctx.z, x_cut, 'Riqueza, $a$', 'Productividad, $z$', 'Horas formales, $\ell_F(a,z)$');
caption(f, 'Formal hours surface');
save_png(f, ctx, 'moll_formal_hours_surface_3d.png');
end

function fig_informal_hours_surface_3d(ctx)
if ~ctx.has_labor, return; end
f = newfig([100 100 980 700]);
[a_cut, x_cut] = surface_cut(ctx, ctx.ell_I);
plot_surface_xyz(a_cut, ctx.z, x_cut, 'Riqueza, $a$', 'Productividad, $z$', 'Horas informales, $\ell_I(a,z)$');
caption(f, 'Informal hours surface');
save_png(f, ctx, 'moll_informal_hours_surface_3d.png');
end

function fig_consumption_policy(ctx)
f = newfig([100 100 1200 560]);
tiledlayout(f, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
ax = nexttile; hold(ax, 'on');
for jj = [ctx.j_low, ctx.j_high]
    [col, ls, lab] = z_style(jj, ctx);
    plot(ax, ctx.a, ctx.c(:,jj), 'Color', col, 'LineStyle', ls, 'DisplayName', lab);
end
xlim(ax, [ctx.zoom_lo ctx.zoom_hi]);
xlabel(ax, 'Riqueza, $a$'); ylabel(ax, 'Consumo efectivo, $C$');
legend(ax, 'Location', 'best'); moll_axes(ax);
ax = nexttile; hold(ax, 'on');
for jj = [ctx.j_low, ctx.j_high]
    [col, ls, lab] = z_style(jj, ctx);
    plot(ax, ctx.a, ctx.exp_cons(:,jj), 'Color', col, 'LineStyle', ls, 'DisplayName', lab);
end
xlim(ax, [ctx.zoom_lo ctx.zoom_hi]);
xlabel(ax, 'Riqueza, $a$'); ylabel(ax, 'Gasto, $c_F+p_I c_I$');
legend(ax, 'Location', 'best'); moll_axes(ax);
caption(f, 'Effective CES consumption and monetary expenditure by wealth');
save_png(f, ctx, 'moll_consumption_policy.png');
end

function fig_consumption_labor_policy(ctx)
f = newfig([100 100 1200 560]);
tiledlayout(f, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
ax = nexttile; hold(ax, 'on');
for jj = [ctx.j_low, ctx.j_high]
    [col, ls, lab] = z_style(jj, ctx);
    plot(ax, ctx.a, ctx.exp_cons(:,jj), 'Color', col, 'LineStyle', ls, 'DisplayName', lab);
end
xlim(ax, [ctx.zoom_lo ctx.zoom_hi]);
xlabel(ax, 'Riqueza, $a$'); ylabel(ax, 'Gasto');
legend(ax, 'Location', 'best'); moll_axes(ax);
ax = nexttile; hold(ax, 'on');
if ctx.has_labor
    for jj = [ctx.j_low, ctx.j_high]
        [col, ls, lab] = z_style(jj, ctx);
        plot(ax, ctx.a, ctx.ell_F(:,jj) + ctx.ell_I(:,jj), 'Color', col, ...
            'LineStyle', ls, 'DisplayName', lab);
    end
end
xlim(ax, [ctx.zoom_lo ctx.zoom_hi]);
xlabel(ax, 'Riqueza, $a$'); ylabel(ax, 'Horas totales, $\ell_F+\ell_I$');
legend(ax, 'Location', 'best'); moll_axes(ax);
caption(f, 'Consumption and total labor policy by wealth');
save_png(f, ctx, 'moll_consumption_labor_policy_by_wealth.png');
end

function fig_consumption_distribution(ctx)
[x1, y1] = weighted_pdf(ctx.c(:), ctx.w_all, 70);
[x2, y2] = weighted_pdf(ctx.exp_cons(:), ctx.w_all, 70);
f = newfig([100 100 900 620]); ax = axes(f); hold(ax, 'on');
plot(ax, x1, y1, 'b-', 'DisplayName', 'Consumo efectivo $C$');
plot(ax, x2, y2, 'r--', 'DisplayName', 'Gasto $c_F+p_I c_I$');
xlabel(ax, 'Consumo / gasto'); ylabel(ax, 'Densidad estacionaria');
legend(ax, 'Location', 'best'); moll_axes(ax);
caption(f, 'Stationary distribution of effective consumption and expenditure');
save_png(f, ctx, 'moll_consumption_distribution.png');
end

function fig_consumption_components_distribution(ctx)
[x1, y1] = weighted_pdf(ctx.c_F(:), ctx.w_all, 70);
[x2, y2] = weighted_pdf((ctx.p_I * ctx.c_I(:)), ctx.w_all, 70);
f = newfig([100 100 900 620]); ax = axes(f); hold(ax, 'on');
plot(ax, x1, y1, 'b-', 'DisplayName', '$c_F$');
plot(ax, x2, y2, 'r--', 'DisplayName', '$p_I c_I$');
xlabel(ax, 'Componente de gasto'); ylabel(ax, 'Densidad estacionaria');
legend(ax, 'Location', 'best'); moll_axes(ax);
caption(f, 'Aggregate distribution of formal and informal expenditure components');
save_png(f, ctx, 'moll_consumption_components_distribution.png');
end

function fig_consumption_components_by_z(ctx)
f = newfig([100 100 1200 560]);
tiledlayout(f, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
ax = nexttile; hold(ax, 'on');
plot(ax, ctx.z, ctx.mean_cF_by_z, 'b-o', 'DisplayName', '$E[c_F|z]$');
plot(ax, ctx.z, ctx.mean_pIcI_by_z, 'r--s', 'DisplayName', '$E[p_I c_I|z]$');
xlabel(ax, 'Productividad, $z$'); ylabel(ax, 'Media condicional');
legend(ax, 'Location', 'best'); moll_axes(ax);
ax = nexttile; hold(ax, 'on');
plot(ax, ctx.z, ctx.share_cF_by_z, 'b-o', 'DisplayName', 'Participacion formal');
plot(ax, ctx.z, ctx.share_pIcI_by_z, 'r--s', 'DisplayName', 'Participacion informal');
ylim(ax, [0 1]); xlabel(ax, 'Productividad, $z$'); ylabel(ax, 'Participacion en gasto');
legend(ax, 'Location', 'best'); moll_axes(ax);
caption(f, 'Gasto formal e informal por productividad');
save_png(f, ctx, 'moll_consumption_components_by_z.png');
end

function fig_consumption_components_distribution_by_z_groups(ctx)
f = newfig([100 100 1500 580]);
tiledlayout(f, 1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
all_x = [ctx.c_F(:); ctx.p_I * ctx.c_I(:)];
all_w = [ctx.w_all; ctx.w_all];
xlo = weighted_quantile(all_x, all_w, 0.001);
xhi = weighted_quantile(all_x, all_w, 0.999);
ratio = ctx.c_F ./ max(ctx.p_I * ctx.c_I, 1e-12);
for kk = 1:numel(ctx.idx_show)
    jj = ctx.idx_show(kk);
    ax = nexttile; hold(ax, 'on');
    wj = ctx.g(:,jj) * ctx.da;
    [xF, yF] = weighted_pdf(ctx.c_F(:,jj), wj, 70);
    [xI, yI] = weighted_pdf(ctx.p_I * ctx.c_I(:,jj), wj, 70);
    plot(ax, xF, normalize_peak(yF), 'b-', 'DisplayName', '$c_F$');
    plot(ax, xI, normalize_peak(yI), 'r--', 'DisplayName', '$p_I c_I$');
    xline(ax, ctx.mean_cF_by_z(jj), ':b', 'HandleVisibility', 'off');
    xline(ax, ctx.mean_pIcI_by_z(jj), ':r', 'HandleVisibility', 'off');
    xlim(ax, [xlo xhi]); ylim(ax, [0 1.05]);
    title(ax, sprintf('$z=%.2f$; medias %.2f / %.2f', ctx.z(jj), ...
        ctx.mean_cF_by_z(jj), ctx.mean_pIcI_by_z(jj)));
    xlabel(ax, 'Componente de gasto');
    if kk == 1, ylabel(ax, 'Densidad condicional normalizada'); end
    if kk == 1, legend(ax, 'Location', 'best'); end
    moll_axes(ax);
end
caption(f, sprintf('Distribucion estacionaria condicional a z, normalizada al pico. CES: c_F/(p_I c_I)=%.2f, sd=%.1e', ...
    mean(ratio(:), 'omitnan'), std(ratio(:), 'omitnan')));
save_png(f, ctx, 'moll_consumption_components_distribution_by_z_groups.png');
end

function fig_consumption_formal_distribution_by_z_groups(ctx)
plot_component_distribution_by_z(ctx, ctx.c_F, ctx.mean_cF_by_z, ...
    'Consumo formal $c_F$', 'Densidad de consumo formal por productividad', ...
    'moll_consumption_formal_distribution_by_z_groups.png');
end

function fig_consumption_informal_distribution_by_z_groups(ctx)
plot_component_distribution_by_z(ctx, ctx.p_I * ctx.c_I, ctx.mean_pIcI_by_z, ...
    'Gasto informal $p_I c_I$', 'Densidad de gasto informal por productividad', ...
    'moll_consumption_informal_distribution_by_z_groups.png');
end

function plot_component_distribution_by_z(ctx, xmat, means_by_z, x_label, ttl, file_name)
f = newfig([100 100 900 620]); ax = axes(f); hold(ax, 'on');
all_x = xmat(:);
all_w = ctx.w_all;
xlo = weighted_quantile(all_x, all_w, 0.001);
xhi = weighted_quantile(all_x, all_w, 0.999);
for kk = 1:numel(ctx.idx_show)
    jj = ctx.idx_show(kk);
    wj = ctx.g(:,jj) * ctx.da;
    [x_pdf, y_pdf] = weighted_pdf(xmat(:,jj), wj, 70);
    [col, ls, lab] = z_style(jj, ctx);
    plot(ax, x_pdf, normalize_peak(y_pdf), 'Color', col, 'LineStyle', ls, ...
        'DisplayName', sprintf('%s; media %.2f', lab, means_by_z(jj)));
    xline(ax, means_by_z(jj), ':', 'Color', col, 'HandleVisibility', 'off');
end
xlim(ax, [xlo xhi]); ylim(ax, [0 1.05]);
title(ax, ttl, 'Interpreter', 'none');
xlabel(ax, x_label); ylabel(ax, 'Densidad condicional normalizada');
legend(ax, 'Location', 'northoutside', 'Orientation', 'horizontal');
moll_axes(ax);
caption(f, [ttl '. Estacionaria condicional a z y normalizada al pico.']);
save_png(f, ctx, file_name);
end

function fig_labor_policy_by_wealth(ctx)
if ~ctx.has_labor, return; end
f = newfig([100 100 1200 560]);
tiledlayout(f, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
ax = nexttile; hold(ax, 'on');
for jj = [ctx.j_low, ctx.j_high]
    [col, ls, lab] = z_style(jj, ctx);
    plot(ax, ctx.a, ctx.ell_F(:,jj), 'Color', col, 'LineStyle', ls, 'DisplayName', lab);
end
xlim(ax, [ctx.zoom_lo ctx.zoom_hi]);
xlabel(ax, 'Riqueza, $a$'); ylabel(ax, 'Horas formales, $\ell_F(a,z)$');
legend(ax, 'Location', 'best'); moll_axes(ax);
ax = nexttile; hold(ax, 'on');
for jj = [ctx.j_low, ctx.j_high]
    [col, ls, lab] = z_style(jj, ctx);
    plot(ax, ctx.a, ctx.ell_I(:,jj), 'Color', col, 'LineStyle', ls, 'DisplayName', lab);
end
xlim(ax, [ctx.zoom_lo ctx.zoom_hi]);
xlabel(ax, 'Riqueza, $a$'); ylabel(ax, 'Horas informales, $\ell_I(a,z)$');
legend(ax, 'Location', 'best'); moll_axes(ax);
caption(f, 'Labor policies by wealth');
save_png(f, ctx, 'moll_labor_policy_by_wealth.png');
end

function fig_labor_supply_by_productivity(ctx)
if ~ctx.has_labor, return; end
f = newfig([100 100 1200 560]);
tiledlayout(f, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
ax = nexttile; hold(ax, 'on');
plot(ax, ctx.z, ctx.mean_ellF_by_z + ctx.mean_ellI_by_z, 'k-o', 'DisplayName', 'Total');
plot(ax, ctx.z, ctx.mean_ellF_by_z, 'b-o', 'DisplayName', 'Formal');
plot(ax, ctx.z, ctx.mean_ellI_by_z, 'r--s', 'DisplayName', 'Informal');
xlabel(ax, 'Productividad, $z$'); ylabel(ax, 'Horas promedio');
legend(ax, 'Location', 'best'); moll_axes(ax);
ax = nexttile; hold(ax, 'on');
for jj = ctx.idx_show
    [col, ls, lab] = z_style(jj, ctx);
    plot(ax, ctx.a, ctx.ell_F(:,jj) + ctx.ell_I(:,jj), 'Color', col, ...
        'LineStyle', ls, 'DisplayName', lab);
end
xlim(ax, [ctx.zoom_lo ctx.zoom_hi]);
xlabel(ax, 'Riqueza, $a$'); ylabel(ax, 'Horas totales');
legend(ax, 'Location', 'best'); moll_axes(ax);
caption(f, 'Labor supply by productivity and wealth');
save_png(f, ctx, 'moll_labor_supply_by_productivity.png');
end

function fig_time_use_by_z_with_leisure(ctx)
if ~ctx.has_labor, return; end
F = ctx.mean_ellF_by_z; I = ctx.mean_ellI_by_z;
L = max(ctx.H_bar - F - I, 0);
total = max(F + I + L, 1e-12);
f = newfig([100 100 1250 620]); ax = axes(f); hold(ax, 'on');
x = 1:ctx.Ns;
bar(ax, x, [F(:)./total(:), I(:)./total(:), L(:)./total(:)] * 100, 'stacked');
colormap(ax, [0 0 1; 1 0 0; 0.45 0.45 0.45]);
ylim(ax, [0 100]); xlim(ax, [0.25 ctx.Ns + 0.75]);
set(ax, 'XTick', x, 'XTickLabel', z_tick_labels(ctx.z), 'XTickLabelRotation', 45);
xlabel(ax, 'Productividad, $z$'); ylabel(ax, 'Porcentaje de dotacion de tiempo');
legend(ax, {'Formal','Informal','Ocio'}, 'Location', 'northoutside', 'Orientation', 'horizontal');
moll_axes(ax);
caption(f, 'Time use by productivity');
save_png(f, ctx, 'moll_time_use_by_z_with_leisure.png');
end

function fig_time_use_trend_by_z(ctx)
if ~ctx.has_labor, return; end
F = ctx.mean_ellF_by_z; I = ctx.mean_ellI_by_z;
L = max(ctx.H_bar - F - I, 0);
total = max(F + I + L, 1e-12);
work = max(F + I, 1e-12);
f = newfig([100 100 1200 560]);
tiledlayout(f, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
ax = nexttile; hold(ax, 'on');
plot(ax, ctx.z, 100 * L ./ total, 'Color', [0.45 0.45 0.45], 'DisplayName', 'Ocio');
plot(ax, ctx.z, 100 * I ./ total, 'r--', 'DisplayName', 'Informal');
plot(ax, ctx.z, 100 * F ./ total, 'b:', 'DisplayName', 'Formal');
ylim(ax, [0 100]); xlabel(ax, 'Productividad, $z$'); ylabel(ax, 'Porcentaje del tiempo');
legend(ax, 'Location', 'best'); moll_axes(ax);
ax = nexttile; hold(ax, 'on');
plot(ax, ctx.z, 100 * I ./ work, 'r--', 'DisplayName', 'Informal');
plot(ax, ctx.z, 100 * F ./ work, 'b-', 'DisplayName', 'Formal');
ylim(ax, [0 100]); xlabel(ax, 'Productividad, $z$'); ylabel(ax, 'Porcentaje de horas trabajadas');
legend(ax, 'Location', 'best'); moll_axes(ax);
caption(f, 'Time-use trends by productivity');
save_png(f, ctx, 'moll_time_use_trend_by_z.png');
end

function fig_time_use_by_z_excluding_leisure(ctx)
if ~ctx.has_labor, return; end
F = ctx.mean_ellF_by_z; I = ctx.mean_ellI_by_z;
work = max(F + I, 1e-12);
f = newfig([100 100 1250 620]); ax = axes(f); hold(ax, 'on');
x = 1:ctx.Ns;
bar(ax, x, [I(:)./work(:), F(:)./work(:)] * 100, 'stacked');
colormap(ax, [1 0 0; 0 0 1]);
ylim(ax, [0 100]); xlim(ax, [0.25 ctx.Ns + 0.75]);
set(ax, 'XTick', x, 'XTickLabel', z_tick_labels(ctx.z), 'XTickLabelRotation', 45);
xlabel(ax, 'Productividad, $z$'); ylabel(ax, 'Porcentaje de horas trabajadas');
legend(ax, {'Informal','Formal'}, 'Location', 'northoutside', 'Orientation', 'horizontal');
moll_axes(ax);
caption(f, 'Sectoral composition of worked hours by productivity');
save_png(f, ctx, 'moll_time_use_by_z_excluding_leisure.png');
end

function fig_income_decomposition_by_wealth_quintile(ctx)
if all(isnan(ctx.adot(:))), return; end
[Q, labels] = quintile_stats(ctx);
x = 1:5;
gross = max(Q.F + Q.I + Q.A + Q.T + Q.P, 1e-12);
pct = 100 * [Q.F(:), Q.I(:), Q.A(:), Q.T(:), Q.P(:)] ./ gross(:);
f = newfig([100 100 980 640]); ax = axes(f); hold(ax, 'on');
bar(ax, x, pct, 'stacked');
colormap(ax, [0 0 1; 1 0 0; 0.1 0.62 0.25; 0.45 0.45 0.45; 0.55 0.31 0.70]);
set(ax, 'XTick', x, 'XTickLabel', labels);
xlabel(ax, 'Quintil de riqueza'); ylabel(ax, 'Porcentaje del ingreso bruto');
ylim(ax, [0 100]);
legend(ax, {'Formal','Informal','Activos','Transferencia','Beneficio'}, ...
    'Location', 'northoutside', 'Orientation', 'horizontal');
annotate_stacked_percent(ax, x, pct);
moll_axes(ax);
caption(f, 'Composicion porcentual del ingreso por quintil de riqueza');
save_png(f, ctx, 'moll_income_decomposition_by_wealth_quintile.png');
end

function fig_income_balance_by_wealth_quintile(ctx)
if all(isnan(ctx.adot(:))), return; end
[Q, labels] = quintile_stats(ctx);
x = 1:5;
f = newfig([100 100 900 620]); ax = axes(f); hold(ax, 'on');
plot(ax, x, Q.net, 'b-o', 'DisplayName', 'Ingreso neto');
plot(ax, x, Q.exp, 'r--s', 'DisplayName', 'Gasto');
plot(ax, x, Q.net - Q.exp, 'g:^', 'DisplayName', 'Ahorro');
yline(ax, 0, ':k', 'HandleVisibility', 'off');
set(ax, 'XTick', x, 'XTickLabel', labels);
xlabel(ax, 'Quintil de riqueza'); ylabel(ax, 'Media dentro del quintil');
legend(ax, 'Location', 'best'); moll_axes(ax);
caption(f, 'Ingreso, gasto y ahorro medio por quintil de riqueza');
save_png(f, ctx, 'moll_income_balance_by_wealth_quintile.png');
end

function fig_income_decomposition_percent_by_wealth_quintile(ctx)
if all(isnan(ctx.adot(:))), return; end
[Q, labels] = quintile_stats(ctx);
gross = max(Q.F + Q.I + Q.A + Q.T + Q.P, 1e-12);
pct = 100 * [Q.F(:), Q.I(:), Q.A(:), Q.T(:), Q.P(:)] ./ gross(:);
f = newfig([100 100 900 620]); ax = axes(f);
bar(ax, 1:5, pct, 'stacked');
colormap(ax, [0 0 1; 1 0 0; 0.1 0.62 0.25; 0.45 0.45 0.45; 0.55 0.31 0.70]);
ylim(ax, [0 100]); set(ax, 'XTick', 1:5, 'XTickLabel', labels);
xlabel(ax, 'Quintil de riqueza'); ylabel(ax, 'Porcentaje del ingreso bruto');
legend(ax, {'Formal','Informal','Activos','Transferencia','Beneficio'}, ...
    'Location', 'northoutside', 'Orientation', 'horizontal');
annotate_stacked_percent(ax, 1:5, pct);
moll_axes(ax);
caption(f, 'Composicion porcentual del ingreso por quintil de riqueza');
save_png(f, ctx, 'moll_income_decomposition_percent_by_wealth_quintile.png');
end

function fig_informality_by_z(ctx)
if ~ctx.has_labor, return; end
f = newfig([100 100 1040 640]); ax = axes(f); hold(ax, 'on');
plot(ax, ctx.z, 1 - ctx.form_share_by_z, 'r-s', 'DisplayName', 'Horas informales / total');
plot(ax, ctx.z, ctx.form_share_by_z, 'b-o', 'DisplayName', 'Horas formales / total');
ylim(ax, [0 1]); xlabel(ax, 'Productividad, $z$'); ylabel(ax, 'Participacion de horas');
legend(ax, 'Location', 'northoutside', 'Orientation', 'horizontal');
moll_axes(ax);
caption(f, 'Informality on the intensive margin by productivity');
save_png(f, ctx, 'moll_informality_by_z.png');
end

function fig_debt_probability_by_z(ctx)
f = newfig([100 100 1200 560]);
tiledlayout(f, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
ax = nexttile; hold(ax, 'on');
plot(ax, ctx.z, ctx.mass_debt_by_z, 'r--s');
ylim(ax, [0, min(1, max(0.05, 1.15 * max(ctx.mass_debt_by_z)))]);
xlabel(ax, 'Productividad, $z$'); ylabel(ax, '$Pr(a<0|z)$'); moll_axes(ax);
ax = nexttile; hold(ax, 'on');
plot(ax, ctx.z, ctx.mean_a_debt_by_z, 'b--s');
xlabel(ax, 'Productividad, $z$'); ylabel(ax, '$E[a|a<0,z]$'); moll_axes(ax);
caption(f, 'Debt probability and mean debt by productivity');
save_png(f, ctx, 'moll_debt_probability_by_z.png');
end

function fig_gasto_distribution_by_formality(ctx)
if ~ctx.has_labor, return; end
formal = ctx.ell_F(:) >= ctx.ell_I(:);
x = ctx.exp_cons(:);
w = ctx.w_all / max(sum(ctx.w_all), 1e-12);
xlo = max(0, weighted_quantile(x, w, 0.001));
xhi = weighted_quantile(x, w, 0.995);
f = newfig([100 100 1400 620]);
tiledlayout(f, 1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
plot_group_hist(nexttile, x, w, formal, [0 0 1], 'Dominio formal', [xlo xhi]);
plot_group_hist(nexttile, x, w, ~formal, [1 0 0], 'Dominio informal', [xlo xhi]);
plot_group_hist(nexttile, x, w, true(size(x)), [0.45 0.45 0.45], 'Total', [xlo xhi]);
caption(f, 'Distribucion del gasto del modelo por sector laboral dominante');
save_png(f, ctx, 'moll_model_gasto_distribution_by_formality.png');
end

function fig_lorenz_curves(ctx)
f = newfig([100 100 760 720]); ax = axes(f); hold(ax, 'on');
plot(ax, [0 1], [0 1], ':k', 'HandleVisibility', 'off');
plot(ax, ctx.lorenz_pop_a, ctx.lorenz_a_plot, 'b-', ...
    'DisplayName', sprintf('Riqueza, Gini=%.3f', ctx.Gini_a));
plot(ax, ctx.lorenz_pop_c, ctx.lorenz_c_plot, 'r--', ...
    'DisplayName', sprintf('Gasto, Gini=%.3f', ctx.Gini_c));
xlim(ax, [0 1]); ylim(ax, [0 1]);
axis(ax, 'square');
xlabel(ax, 'Poblacion acumulada'); ylabel(ax, 'Participacion acumulada');
legend(ax, 'Location', 'northwest'); moll_axes(ax);
caption(f, 'Lorenz curves');
save_png(f, ctx, 'moll_lorenz_curves.png');
end

function fig_debt_premium_inequality(ctx)
f = newfig([100 100 1200 560]);
tiledlayout(f, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
ax = nexttile; hold(ax, 'on');
plot(ax, ctx.z, ctx.debt_spread_z, 'r--s', 'DisplayName', 'Prima de deuda');
plot(ax, ctx.z, ctx.mass_debt_by_z, 'b-o', 'DisplayName', '$Pr(a<0|z)$');
xlabel(ax, 'Productividad, $z$'); ylabel(ax, 'Prima / probabilidad');
legend(ax, 'Location', 'best'); moll_axes(ax);
ax = nexttile; hold(ax, 'on');
plot(ax, ctx.z, ctx.mean_a_by_z, 'k-o', 'DisplayName', '$E[a|z]$');
plot(ax, ctx.z, ctx.mean_exp_by_z, 'r--s', 'DisplayName', '$E[gasto|z]$');
xlabel(ax, 'Productividad, $z$'); ylabel(ax, 'Media condicional');
legend(ax, 'Location', 'best'); moll_axes(ax);
caption(f, 'Debt premium and inequality gradients by productivity');
save_png(f, ctx, 'moll_debt_premium_inequality_by_z.png');
end

function fig_ou_stationary_masses(ctx)
f = newfig([100 100 1100 620]); ax = axes(f); hold(ax, 'on');
x = 1:ctx.Ns;
bar(ax, x, [ctx.pi_z_ar(:), (ctx.mass_z(:) / max(sum(ctx.mass_z), 1e-12))], 'grouped');
set(ax, 'XTick', x, 'XTickLabel', z_tick_labels(ctx.z), 'XTickLabelRotation', 45);
xlabel(ax, 'Estado de productividad'); ylabel(ax, 'Masa');
legend(ax, {'OU ergodica','Modelo estacionario'}, 'Location', 'best');
moll_axes(ax);
caption(f, 'Stationary masses of the discretized OU process');
save_png(f, ctx, 'moll_ou_stationary_masses.png');
end

function fig_conditional_moments_by_z(ctx)
f = newfig([100 100 1200 560]);
tiledlayout(f, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
ax = nexttile; hold(ax, 'on');
plot(ax, ctx.z, ctx.mean_a_by_z, 'b-o', 'DisplayName', '$E[a|z]$');
plot(ax, ctx.z, ctx.mean_exp_by_z, 'r--s', 'DisplayName', '$E[gasto|z]$');
xlabel(ax, 'Productividad, $z$'); ylabel(ax, 'Media condicional');
legend(ax, 'Location', 'best'); moll_axes(ax);
ax = nexttile; hold(ax, 'on');
plot(ax, ctx.z, ctx.mass_debt_by_z, 'r--s', 'DisplayName', '$Pr(a<0|z)$');
if ctx.has_labor
    plot(ax, ctx.z, 1 - ctx.form_share_by_z, 'b-o', 'DisplayName', 'Participacion informal');
end
xlabel(ax, 'Productividad, $z$'); ylabel(ax, 'Participacion');
legend(ax, 'Location', 'best'); moll_axes(ax);
caption(f, 'Conditional moments by productivity');
save_png(f, ctx, 'moll_conditional_moments_by_z.png');
end

function fig_equilibrium_asset_market(ctx)
if ~isfield(ctx, 'r_grid') || ~isfield(ctx, 'S') || ~isfield(ctx, 'KD'), return; end
f = newfig([100 100 900 620]); ax = axes(f); hold(ax, 'on');
plot(ax, ctx.r_grid(:), ctx.S(:), 'b-', 'DisplayName', 'Oferta de activos $S(r)$');
plot(ax, ctx.r_grid(:), ctx.KD(:), 'r--', 'DisplayName', 'Demanda de capital $K^D(r)$');
if isfinite(ctx.r_star), xline(ax, ctx.r_star, ':k', 'DisplayName', sprintf('$r^*=%.4f$', ctx.r_star)); end
Kstar = get_scalar(ctx, {'K_star'}, NaN);
if isfinite(Kstar), yline(ax, Kstar, ':', 'Color', [0.45 0.45 0.45], 'DisplayName', sprintf('$K^*=%.2f$', Kstar)); end
xlabel(ax, 'Tasa de interes, $r$'); ylabel(ax, 'Nivel agregado');
legend(ax, 'Location', 'best'); moll_axes(ax);
caption(f, 'Stationary equilibrium in the asset market');
save_png(f, ctx, 'moll_equilibrium_asset_market.png');
end

function fig_calibration_tables(ctx)
t1_model = get_scalar(ctx, {'T1_wage_gross','T1_net','T1_wage_net'}, NaN);
if ~isfinite(t1_model)
    wf = get_scalar(ctx, {'w_F_star','w_F'}, NaN);
    wi = get_scalar(ctx, {'w_I_household_star','w_I_star','w_I'}, NaN);
    theta_val = get_scalar(ctx, {'theta'}, 1.0);
    if isfinite(wf) && isfinite(wi) && wi > 0 && theta_val > 0
        t1_model = wf / (wi * theta_val);
    end
end
primary = {
    'T4 horas informales / total', get_scalar(ctx, {'T4_model'}, NaN), get_scalar(ctx, {'T4_data'}, 0.557), 'INEI'
    'T5 PBI informal nominal', get_scalar(ctx, {'T5_nom'}, NaN), get_scalar(ctx, {'T5_data'}, 0.190), 'INEI'
    'Tkz sorting formalidad por z', get_scalar(ctx, {'T_kappa_z_model'}, NaN), get_scalar(ctx, {'T_kappa_z_data'}, 0.386), 'ENAHO'
    'Tgasto ratio gasto F/I', get_scalar(ctx, {'ratio_gasto_FI','Tgasto_tipo'}, NaN), get_scalar(ctx, {'TgFI_data'}, 1.913), 'ENAHO'
    'p_I precio relativo informal', ctx.p_I, NaN, '< 1'
    'Gini riqueza neta', ctx.Gini_a, NaN, '>= 0.40'
    };
secondary = {
    'T1 brecha salarial w_F/w_I', t1_model, get_scalar(ctx, {'T1_ref'}, 2.30), 'BCR'
    'Gini gasto', ctx.Gini_c, 0.40, 'ENAHO'
    'T6 gap Q1-Q5 horas informales', get_scalar(ctx, {'T6_model'}, NaN), get_scalar(ctx, {'T6_data'}, 0.530), 'ENAHO'
    'Horas trabajadas promedio', mean(ctx.mean_ellF_by_z + ctx.mean_ellI_by_z, 'omitnan'), 0.40, 'Peru aprox.'
    'Masa con deuda a<0', get_scalar(ctx, {'mass_debt'}, mean(ctx.mass_debt_by_z, 'omitnan')), NaN, 'Modelo'
    'T4 extensivo frac. informal-dom.', get_scalar(ctx, {'T4_ext'}, NaN), NaN, 'Diagnostico'
    'K/Y capital-producto', get_KY(ctx), 2.73, 'PWT'
    };
params = {
    'gamma', get_scalar(ctx, {'ga'}, 1.0), 'Avers. riesgo'
    'rho', get_scalar(ctx, {'rho'}, NaN), 'Descuento'
    'omega_C', ctx.omega_C, 'Peso formal CES'
    'sigma_C', ctx.sigma_C, 'Sustitucion CES'
    'A_I', get_scalar(ctx, {'A_I'}, NaN), 'PTF informal'
    'psi_F', get_scalar(ctx, {'psi_F'}, NaN), 'Desutilidad formal'
    'psi_I', get_scalar(ctx, {'psi_I'}, NaN), 'Desutilidad informal'
    'kappa_z1', get_scalar(ctx, {'kappa_z1'}, NaN), 'Barrera formal'
    'amin', min(ctx.a), 'Limite deuda'
    };
draw_table_png(ctx, primary, {'Momento','Modelo','Dato','Fuente'}, 'moll_table_primary.png', 'Targets primarios');
draw_table_png(ctx, secondary, {'Momento','Modelo','Dato','Fuente'}, 'moll_table_secondary.png', 'Validacion y targets secundarios');
draw_table_png(ctx, params, {'Parametro','Valor','Rol'}, 'moll_table_params.png', 'Parametros');
old_combined = fullfile(ctx.out_dir, matlab_png_name('moll_calibration_table.png'));
if exist(old_combined, 'file')
    delete(old_combined);
end
end

function draw_table_png(ctx, rows, headers, file_name, ttl)
f = newfig([100 100 1280 430]); ax = axes(f); axis(ax, 'off');
nrow = size(rows, 1) + 1; ncol = numel(headers);
cell_text = cell(nrow, ncol);
cell_text(1,:) = headers;
for i = 1:size(rows, 1)
    for j = 1:ncol
        v = rows{i,j};
        if isnumeric(v)
            cell_text{i+1,j} = fmt_num(v);
        else
            cell_text{i+1,j} = char(v);
        end
    end
end
draw_axes_table(ax, cell_text, ttl);
save_png(f, ctx, file_name);
end

function draw_big_calibration_table(ctx, primary, secondary, params)
f = newfig([100 100 1600 900]);
tiledlayout(f, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
draw_table_tile(nexttile, params, {'Parameter','Value','Role'}, 'A. Parameters');
draw_table_tile(nexttile, primary, {'Moment','Model','Data','Source'}, 'B. Primary targets');
draw_table_tile(nexttile, secondary, {'Moment','Model','Data','Source'}, 'C. Validation');
ax = nexttile; axis(ax, 'off');
text(ax, 0.05, 0.8, sprintf('Run: %s', ctx.run_tag), 'FontSize', 13, 'Interpreter', 'none');
text(ax, 0.05, 0.65, sprintf('r*=%.4f  p_I=%.3f  Gini_a=%.3f  Gini_e=%.3f', ...
    ctx.r_star, ctx.p_I, ctx.Gini_a, ctx.Gini_c), 'FontSize', 13, 'Interpreter', 'none');
text(ax, 0.05, 0.50, sprintf('K/Y=%s', fmt_num(get_KY(ctx))), 'FontSize', 13, 'Interpreter', 'none');
caption(f, 'Calibration summary from the same results .mat used by the figures');
save_png(f, ctx, 'moll_calibration_table.png');
end

function draw_table_tile(ax, rows, headers, ttl)
axis(ax, 'off');
nrow = size(rows, 1) + 1; ncol = numel(headers);
cell_text = cell(nrow, ncol);
cell_text(1,:) = headers;
for i = 1:size(rows, 1)
    for j = 1:ncol
        v = rows{i,j};
        if isnumeric(v), cell_text{i+1,j} = fmt_num(v); else, cell_text{i+1,j} = char(v); end
    end
end
draw_axes_table(ax, cell_text, ttl);
end

function draw_axes_table(ax, cell_text, ttl)
axis(ax, 'off');
set(ax, 'XLim', [0 1], 'YLim', [0 1]);
[nrow, ncol] = size(cell_text);
left = 0.02; bottom = 0.04; width = 0.96; height = 0.82;
row_h = height / nrow;
col_w = width / ncol;
title(ax, ttl, 'FontWeight', 'bold', 'Interpreter', 'none');
for i = 1:nrow
    y = bottom + height - i * row_h;
    for j = 1:ncol
        x = left + (j - 1) * col_w;
        if i == 1
            bg = [0.10 0.22 0.38];
            fg = [1 1 1];
            fw = 'bold';
        elseif mod(i, 2) == 0
            bg = [0.92 0.96 1.00];
            fg = [0 0 0];
            fw = 'normal';
        else
            bg = [1 1 1];
            fg = [0 0 0];
            fw = 'normal';
        end
        rectangle(ax, 'Position', [x y col_w row_h], 'FaceColor', bg, ...
            'EdgeColor', [0.55 0.62 0.70], 'LineWidth', 0.5);
        text(ax, x + col_w/2, y + row_h/2, cell_text{i,j}, ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
            'FontSize', 9, 'Color', fg, 'FontWeight', fw, ...
            'Interpreter', 'none');
    end
end
end

function [Q, labels] = quintile_stats(ctx)
w = ctx.g * ctx.da;
q = weighted_quantile(ctx.aa(:), w(:), [0.2 0.4 0.6 0.8]);
masks = cell(1,5);
masks{1} = ctx.aa <= q(1);
masks{2} = ctx.aa > q(1) & ctx.aa <= q(2);
masks{3} = ctx.aa > q(2) & ctx.aa <= q(3);
masks{4} = ctx.aa > q(3) & ctx.aa <= q(4);
masks{5} = ctx.aa > q(4);
fields = {'F','I','A','T','P','net','exp'};
for k = 1:numel(fields), Q.(fields{k}) = zeros(1,5); end
for i = 1:5
    wi = w .* masks{i};
    Q.F(i) = wmean(ctx.income_formal, wi);
    Q.I(i) = wmean(ctx.income_informal, wi);
    Q.A(i) = wmean(ctx.income_assets, wi);
    Q.T(i) = wmean(ctx.income_transfer, wi);
    Q.P(i) = wmean(ctx.income_profit, wi);
    Q.net(i) = Q.F(i) + Q.I(i) + Q.A(i) + Q.T(i) + Q.P(i);
    Q.exp(i) = wmean(ctx.exp_cons, wi);
end
labels = {'Q1','Q2','Q3','Q4','Q5'};
end

function plot_group_hist(ax, x, w, mask, color, ttl, xlim_vals)
hold(ax, 'on');
xg = x(mask); wg = w(mask);
ok = isfinite(xg) & isfinite(wg) & wg > 0;
xg = xg(ok); wg = wg(ok);
if isempty(xg)
    text(ax, 0.5, 0.5, 'Sin masa', 'Units', 'normalized', 'HorizontalAlignment', 'center');
else
    edges = linspace(xlim_vals(1), xlim_vals(2), 36);
    [mids, counts] = weighted_hist_pdf(xg, wg, edges);
    bar(ax, mids, counts, 1, 'FaceColor', color, 'FaceAlpha', 0.24, ...
        'EdgeColor', color, 'DisplayName', 'Histograma');
    [x_pdf, y_pdf] = weighted_pdf(xg, wg, 70);
    plot(ax, x_pdf, y_pdf, 'Color', color, 'LineWidth', 2.2, 'DisplayName', 'Curva suavizada');
    st = weighted_stats(xg, wg);
    xline(ax, st.mean, ':k', 'HandleVisibility', 'off');
    text(ax, 0.96, 0.92, sprintf('media=%.3f\nmediana=%.3f\ndesv. est.=%.3f\nmasa=%.1f%%', ...
        st.mean, st.median, st.sd, 100 * st.mass), ...
        'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
        'FontSize', 9.5, 'Interpreter', 'none');
    legend(ax, 'Location', 'northoutside', 'Orientation', 'horizontal');
end
xlim(ax, xlim_vals);
title(ax, ttl, 'Interpreter', 'none');
xlabel(ax, 'Gasto del modelo'); ylabel(ax, 'Densidad');
moll_axes(ax);
end

function write_payload_audit(ctx)
file_name = fullfile(ctx.out_dir, 'moll_matlab_payload_audit.txt');
fid = fopen(file_name, 'w');
if fid < 0, return; end
fprintf(fid, 'mat_file=%s\n', ctx.mat_file);
fprintf(fid, 'generated=%s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf(fid, 'required=a,z,g,c,da\n');
fprintf(fid, 'recommended=ell_F,ell_I,V,p_I,omega_C,eta_C,sigma_C,r_star,w_F_star,w_I_star,T4_model,T5_nom,ratio_gasto_FI,Gini_a,Gini_c,r_grid,S,KD\n');
fprintf(fid, 'has_labor=%d\n', ctx.has_labor);
fprintf(fid, 'I=%d Ns=%d\n', ctx.I, ctx.Ns);
fprintf(fid, 'p_I=%.10f omega_C=%.10f sigma_C=%.10f\n', ctx.p_I, ctx.omega_C, ctx.sigma_C);
fclose(fid);
end

function [c_F, c_I, exp_cons] = ces_split(c_eff, p_i, omega_c, eta_c, sigma_c)
c_eff = max(real(c_eff), 1e-12);
xi = (omega_c * p_i / max(1 - omega_c, 1e-12)) ^ sigma_c;
kappa = (omega_c * xi ^ eta_c + (1 - omega_c)) ^ (1 / eta_c);
c_I = c_eff / kappa;
c_F = xi * c_I;
exp_cons = c_F + p_i * c_I;
end

function [x, pdf] = weighted_pdf(x0, w0, bins)
x0 = x0(:); w0 = w0(:);
ok = isfinite(x0) & isfinite(w0) & w0 > 0;
x0 = x0(ok); w0 = w0(ok);
if isempty(x0)
    x = []; pdf = []; return;
end
lo = weighted_quantile(x0, w0, 0.005);
hi = weighted_quantile(x0, w0, 0.995);
if ~isfinite(lo) || ~isfinite(hi) || hi <= lo
    lo = min(x0); hi = max(x0);
end
n_grid = max(160, 3 * bins);
x = linspace(lo, hi, n_grid);
w0 = w0 / max(sum(w0), 1e-12);
mu = sum(w0 .* x0);
sd = sqrt(sum(w0 .* (x0 - mu).^2));
n_eff = 1 / max(sum(w0 .^ 2), 1e-12);
bw = 1.06 * sd * n_eff ^ (-1/5);
if ~isfinite(bw) || bw <= 0
    bw = max((hi - lo) / 40, 1e-6);
end
pdf = zeros(size(x));
chunk = 500;
norm_const = 1 / (sqrt(2*pi) * bw);
for i0 = 1:chunk:numel(x0)
    ii = i0:min(i0 + chunk - 1, numel(x0));
    u = (x(:) - x0(ii)') / bw;
    pdf = pdf + (exp(-0.5 * u.^2) * w0(ii))' * norm_const;
end
end

function [mids, pdf] = weighted_hist_pdf(x, w, edges)
nb = numel(edges) - 1;
mids = 0.5 * (edges(1:end-1) + edges(2:end));
pdf = zeros(1, nb);
if isempty(x) || nb < 1
    return;
end
[~, bin] = histc(x, edges);
bin(x == edges(end)) = nb;
ok = bin >= 1 & bin <= nb & isfinite(w) & w > 0;
if any(ok)
    counts = accumarray(bin(ok), w(ok), [nb, 1], @sum, 0);
    widths = diff(edges(:));
    total_w = sum(w(ok));
    pdf = (counts ./ max(total_w .* widths, 1e-12))';
end
end

function [a_cut, x_cut] = surface_cut(ctx, xmat)
icut = min(ctx.I, max(12, round(0.55 * ctx.I)));
a_cut = ctx.a(1:icut);
x_cut = xmat(1:icut, :);
end

function plot_surface_xyz(a, z, xmat, xlab, ylab, zlab)
[A, Z] = meshgrid(a, z);
surf(A, Z, xmat', 'FaceColor', 'interp', ...
    'EdgeColor', [0 0 0], 'EdgeAlpha', 0.85, 'LineWidth', 0.35);
view([45 25]);
colormap(parula);
grid on; box on;
xlim([min(a) max(a)]);
ylim([min(z) max(z)]);
xlabel(xlab, 'FontSize', 16, 'Interpreter', 'latex');
ylabel(ylab, 'FontSize', 16, 'Interpreter', 'latex');
zlabel(zlab, 'FontSize', 16, 'Interpreter', 'latex');
set(gca, 'FontSize', 14, 'LineWidth', 0.8, ...
    'TickLabelInterpreter', 'latex', 'Projection', 'perspective');
end

function st = weighted_stats(x, w)
x = x(:); w = w(:);
ok = isfinite(x) & isfinite(w) & w > 0;
x = x(ok); w = w(ok);
if isempty(x)
    st = struct('mass', 0, 'mean', NaN, 'median', NaN, 'sd', NaN);
    return;
end
mass = sum(w);
wn = w / max(mass, 1e-12);
mu = sum(wn .* x);
st = struct();
st.mass = mass;
st.mean = mu;
st.median = weighted_quantile(x, w, 0.5);
st.sd = sqrt(sum(wn .* (x - mu).^2));
end

function annotate_stacked_percent(ax, x, pct)
bottom = zeros(1, size(pct, 1));
for k = 1:size(pct, 2)
    vals = pct(:,k)';
    for i = 1:numel(x)
        if vals(i) >= 5
            text(ax, x(i), bottom(i) + vals(i)/2, sprintf('%.0f%%', vals(i)), ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
                'FontSize', 8.5, 'Color', 'white', 'FontWeight', 'bold', ...
                'Interpreter', 'none');
        end
    end
    bottom = bottom + vals;
end
end

function q = weighted_quantile(x, w, p)
x = x(:); w = w(:);
ok = isfinite(x) & isfinite(w) & w > 0;
x = x(ok); w = w(ok);
if isempty(x)
    q = NaN(size(p)); return;
end
[x, idx] = sort(x);
w = w(idx);
cw = cumsum(w) / max(sum(w), 1e-12);
q = interp1(cw, x, p, 'linear', 'extrap');
end

function [pop, lor, gini] = lorenz_curve(x, w)
x = x(:); w = w(:);
ok = isfinite(x) & isfinite(w) & w > 0;
x = x(ok); w = w(ok);
if isempty(x) || sum(w) <= 0
    pop = [0;1]; lor = [0;1]; gini = NaN; return;
end
shift = 0;
if min(x) < 0
    shift = -min(x) + 1e-10;
end
x = x + shift;
[x, idx] = sort(x);
w = w(idx);
pop = [0; cumsum(w) / sum(w)];
total = sum(x .* w);
if total <= 0
    lor = [0; pop(2:end)]; gini = NaN; return;
end
lor = [0; cumsum(x .* w) / total];
gini = 1 - 2 * trapz(pop, lor);
end

function y = normalize_peak(x)
if isempty(x) || max(x) <= 0
    y = x;
else
    y = x / max(x);
end
end

function val = wmean(x, w)
ok = isfinite(x) & isfinite(w) & w > 0;
if ~any(ok(:)), val = NaN; else, val = sum(x(ok) .* w(ok)) / sum(w(ok)); end
end

function m = get_matrix(ctx, name, shape, default_val)
if isfield(ctx, name) && isequal(size(ctx.(name)), shape)
    m = double(ctx.(name));
else
    m = default_val * ones(shape);
end
end

function v = get_vector(ctx, name, n, default_val)
if isfield(ctx, name)
    v = double(ctx.(name));
    v = v(:)';
    if numel(v) == n, return; end
end
v = default_val;
if ~isempty(v), v = v(:)'; end
end

function val = get_scalar(ctx, names, default_val)
val = default_val;
for k = 1:numel(names)
    name = names{k};
    if isfield(ctx, name)
        tmp = ctx.(name);
        if isnumeric(tmp) && ~isempty(tmp)
            val = double(tmp(1)); return;
        end
    end
end
end

function v = get_field(ctx, name, default_val)
if isfield(ctx, name), v = ctx.(name); else, v = default_val; end
end

function ky = get_KY(ctx)
ky = get_scalar(ctx, {'KY_ratio','K_Y_ratio'}, NaN);
if ~isfinite(ky)
    K = get_scalar(ctx, {'K_star'}, NaN);
    YF = get_scalar(ctx, {'Y_F'}, NaN);
    YI = get_scalar(ctx, {'Y_I'}, NaN);
    if isfinite(K) && isfinite(YF) && isfinite(YI) && YF + YI > 0
        ky = K / (YF + YI);
    end
end
end

function [col, ls, lab] = z_style(j, ctx)
if j == ctx.j_low
    col = [0 0 1]; ls = '-'; lab = sprintf('$z_{min}=%.2f$', ctx.z(j));
elseif j == ctx.j_high
    col = [1 0 0]; ls = '--'; lab = sprintf('$z_{max}=%.2f$', ctx.z(j));
else
    col = [0.45 0.45 0.45]; ls = '-.'; lab = sprintf('$z_{med}=%.2f$', ctx.z(j));
end
end

function labels = z_tick_labels(z)
n = numel(z);
labels = cell(1, n);
for i = 1:n
    if n > 16 && mod(i-1, max(1, round(n/10))) ~= 0 && i ~= n
        labels{i} = '';
    else
        labels{i} = sprintf('%.2f', z(i));
    end
end
end

function f = newfig(pos)
f = figure('Color', 'white', 'Position', pos, 'Visible', 'off', 'Renderer', 'opengl');
end

function moll_axes(ax)
box(ax, 'on');
set(ax, 'LineWidth', 0.8, 'TickDir', 'in', 'Layer', 'top');
grid(ax, 'off');
end

function caption(f, txt) %#ok<INUSD>
% Keep exported PNGs free of bottom annotations; MATLAB's batch renderer can
% place these too close to x-axis labels in compact tiled figures.
end

function save_png(f, ctx, file_name)
path = fullfile(ctx.out_dir, matlab_png_name(file_name));
set(f, 'PaperPositionMode', 'auto');
set(f, 'InvertHardcopy', 'off');
print(f, path, '-dpng', '-r300');
close(f);
fprintf('  saved: %s\n', matlab_png_name(file_name));
end

function out = matlab_png_name(file_name)
[folder, base, ext] = fileparts(file_name);
if isempty(ext)
    ext = '.png';
end
if endsWith(base, '_matlab')
    out = [base ext];
else
    out = [base '_matlab' ext];
end
if ~isempty(folder)
    out = fullfile(folder, out);
end
end

function s = fmt_num(x)
if ~isfinite(x)
    s = 'n/d';
elseif abs(x) >= 10
    s = sprintf('%.2f', x);
else
    s = sprintf('%.3f', x);
end
end

function mat_file = default_results_file()
here = fileparts(mfilename('fullpath'));
root = fileparts(here);
files = dir(fullfile(root, 'outputs', 'stationary', '*', 'results_*.mat'));
if isempty(files)
    error('No se encontro outputs/stationary/*/results_*.mat. Pasa mat_file explicitamente.');
end
[~, idx] = max([files.datenum]);
mat_file = fullfile(files(idx).folder, files(idx).name);
end
