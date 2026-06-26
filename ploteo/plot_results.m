% ============================================================
% DISABLED — plots migrados a Python.
% Usar: python ploteo/plot_ou_results.py --mat-file <ruta>.mat
% Este archivo se conserva como referencia pero NO debe ejecutarse.
% ============================================================
% plot_results_v10.m
% Genera todas las figuras del modelo v10 R2.
% Carga results_v10_latest.mat (guardado al final de aiyagari_2firms_v10_R2_precio_endogeno.m)
%
% Uso:
%   >> plot_results_v10              % usa results_v10_latest.mat
%   >> plot_results_v10('mi_run.mat') % usa archivo específico
%
% Requiere que el modelo haya corrido y guardado results_v10_latest.mat

function plot_results_v10(mat_file)
if nargin < 1 || isempty(mat_file)
    mat_file = 'results_v10_latest.mat';
end
if ~exist(mat_file, 'file')
    error('No se encontro %s. Corre primero aiyagari_2firms_v10_R2_precio_endogeno.m', mat_file);
end

% Declarar globals necesarios antes del load para que los helpers externos
% vean los parametros guardados en results_v10_latest.mat.
global p_I omega_C eta_C sigma_C kappa_F_aa qq_informal

fprintf('Cargando %s ...\n', mat_file);
g_r = []; c_r = []; ell_F_r = []; ell_I_r = []; V_r = [];
T_eq_r = []; Pi_I_eq_r = []; omega_I_eq_r = [];
load(mat_file);
if isempty(p_I) && exist('p_I_star', 'var')
    p_I = p_I_star;
end
if ~exist('T_eq', 'var') && exist('T_star', 'var')
    T_eq = T_star;
end
if ~exist('informal_profit_rule', 'var') || isempty(informal_profit_rule)
    informal_profit_rule = 'unknown';
end
if exist('w_I_star', 'var') && ~exist('w_I_household_star', 'var')
    if strcmp(informal_profit_rule, 'hours') && exist('profit_I_star', 'var') && exist('L_I_star', 'var')
        w_I_household_star = w_I_star + profit_I_star / max(L_I_star, 1e-12);
    else
        w_I_household_star = w_I_star;
    end
end
if ~exist('Pi_lump_star', 'var') && exist('profit_I_star', 'var')
    if strcmp(informal_profit_rule, 'hours')
        Pi_lump_star = 0;
    else
        Pi_lump_star = profit_I_star;
    end
end
if ~exist('kappa_F_vec', 'var')
    if exist('kappa_F_aa', 'var') && size(kappa_F_aa, 1) == numel(a)
        kappa_F_vec = kappa_F_aa(:,1);
    elseif exist('kappa_min', 'var') && exist('kappa_extra', 'var') && ...
            exist('gamma_k', 'var') && exist('a_bar_k', 'var')
        kappa_F_vec = kappa_min + kappa_extra ./ (1 + exp(gamma_k .* (a - a_bar_k)));
    else
        kappa_F_vec = zeros(numel(a), 1);
    end
end
fprintf('Generando figuras para EQUILIBRIUM_MODE=%d, USE_Q=%d, Ns=%d\n', ...
    EQUILIBRIUM_MODE, USE_Q, Ns);
[~, mat_tag, ~] = fileparts(mat_file);  % tag corto para títulos

% Targets de calibracion — del .mat si existen, sino valores por defecto
if exist('T4_data','var'), T4_plt = T4_data; else, T4_plt = 0.844; end
if exist('T5_data','var'), T5_plt = T5_data; else, T5_plt = 0.176; end
if exist('T6_data','var'), T6_plt = T6_data; else, T6_plt = 0.530; end
if exist('T6_Q1_data','var'), T6_Q1_plt = T6_Q1_data; else, T6_Q1_plt = 0.971; end
if exist('T6_Q5_data','var'), T6_Q5_plt = T6_Q5_data; else, T6_Q5_plt = 0.441; end
if exist('T1_ref','var'), T1_plt = T1_ref; else, T1_plt = 2.30; end

% 6. PLOTS
% =========================================================================

output_dir = 'output_graphs_v10';
if ~exist(output_dir, 'dir'), mkdir(output_dir); end
% Guardar fuente del run para identificar qué .mat generó estas figuras
fid_src = fopen(fullfile(output_dir, 'run_source.txt'), 'w');
if fid_src >= 0
    fprintf(fid_src, 'mat_file: %s\n', mat_file);
    fprintf(fid_src, 'generado: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
    fclose(fid_src);
end
old_fig_visible = get(groot, 'DefaultFigureVisible');
set(groot, 'DefaultFigureVisible', 'off');
restore_fig_visible = onCleanup(@() set(groot, 'DefaultFigureVisible', old_fig_visible));

% Extract equilibrium policies for plots
if EQUILIBRIUM_MODE == 2
    w_F     = w_F_star;
    w_I     = w_I_star;
    omega_I = omega_I_star;
    r_eq    = r_star;
    Pi_eq   = profit_I_star;
else
    ir_mid  = round(Ir/2);
    r_eq    = r_grid(ir_mid);
    KD_mid2 = (al*A_F/(r_eq + d))^(1/(1-al))*z_ave;
    w_F     = (1-al)*A_F*(KD_mid2/z_ave)^al;
    omega_I = omega_I_eq_r(ir_mid);
    w_I     = beta_I * omega_I;
    g       = g_r(:,:,ir_mid);
    c       = c_r(:,:,ir_mid);
    ell_F   = ell_F_r(:,:,ir_mid);
    ell_I   = ell_I_r(:,:,ir_mid);
    V       = V_r(:,:,ir_mid);
    T_eq    = T_eq_r(ir_mid);
    Pi_eq   = Pi_I_eq_r(ir_mid);
end

% Recover formal/informal consumption from stored C_eff policy.
[c_F, c_I, cons_exp] = ces_split_from_Ceff_v10(c);
C_eff = c;
share_cI = c_I ./ max(c_F + c_I, 1e-12);

% Lorenz/Gini objects used below.
% 1) riqueza neta: ordenar por a y acumular a.
% 2) gasto/consumo estandar: ordenar por gasto total y acumular gasto.
% 3) concentracion por riqueza: se reporta con quintiles de a, no como Gini.
g_marg_a = sum(g, 2) * da;
cum_pop_a = cumsum(g_marg_a);
mean_a_mod = sum(a .* g_marg_a);
lorenz_a = cumsum(a .* g_marg_a) / max(mean_a_mod, 1e-12);
Gini_a = 1 - 2 * trapz([0; cum_pop_a], [0; lorenz_a]);

exp_vec = cons_exp(:);
w_vec = g(:) * da;
ok_exp = isfinite(exp_vec) & isfinite(w_vec) & w_vec > 0;
[exp_sorted, idx_exp] = sort(exp_vec(ok_exp), 'ascend');
w_sorted = w_vec(ok_exp);
w_sorted = w_sorted(idx_exp);
cum_pop_c = cumsum(w_sorted) / max(sum(w_sorted), 1e-12);
lorenz_c = cumsum(exp_sorted .* w_sorted) / max(sum(exp_sorted .* w_sorted), 1e-12);
Gini_c = 1 - 2 * trapz([0; cum_pop_c], [0; lorenz_c]);

% Saving policy: adot = income - (c_F + p_I*c_I)
% (tau no cancela; T_tax es lump-sum; Pi_eq = DRS profit; kappa_F_aa = costo acceso formal)
adot = ((1-tau)*w_F*zz - kappa_F_aa).*ell_F + omega_I*theta*zz.*qq_informal.*ell_I + r_eq*aa + T_eq + Pi_eq - cons_exp;
income_formal   = ((1-tau)*w_F*zz - kappa_F_aa) .* ell_F;
income_informal = omega_I * theta * zz .* qq_informal .* ell_I;
income_transfer = T_eq * ones(I, Ns);
income_profit   = Pi_eq * ones(I, Ns);
income_assets   = r_eq * aa;

% Plot windows based on the stationary distribution, not on the raw grid upper bound.
g_total_plot = sum(g, 2);   % sum over all Ns types
cdf_total_plot = cumsum(g_total_plot) * da;
idx_p95_plot = find(cdf_total_plot >= 0.95, 1);
idx_p99_plot = find(cdf_total_plot >= 0.99, 1);
if isempty(idx_p95_plot), idx_p95_plot = I; end
if isempty(idx_p99_plot), idx_p99_plot = I; end

a95_plot  = a(idx_p95_plot);
a99_plot  = a(idx_p99_plot);
amin_grid = min(a);
amax_grid = max(a);
if exist('amin', 'var') && isfinite(amin)
    amin_data_plot = min(amin, amin_grid);
else
    amin_data_plot = amin_grid;
end
% Include zero whenever the asset grid allows debt. Otherwise percentile-based
% windows can make negative borrowing states look like the grid starts above 0.
if amin_data_plot < 0
    a95_plot  = max(a95_plot, min(amax_grid, 0));
    a99_plot  = max(a99_plot, min(amax_grid, 0));
end
amax_plot = a99_plot;
if ~isfinite(amax_plot) || amax_plot <= amin_data_plot
    amax_plot = amax_grid;
end
amin_plot = amin_data_plot;
if amin_data_plot < 0 && amax_plot > 0
    % Give the debt region visible width even when amin is close to zero.
    amin_plot = min(amin_data_plot, -0.08 * max(amax_plot, 1e-8));
end
idx_max   = idx_p99_plot;

% Wealth quartile classification (Q1=bottom 25%, Q4=top 25%).
% Usamos la distribucion estacionaria marginal (suma sobre todos los Ns tipos).
g_total = sum(g, 2);
cdf_total = cumsum(g_total) * da;
q25_idx = find(cdf_total >= 0.25, 1, 'first');
q75_idx = find(cdf_total >= 0.75, 1, 'first');
q25_a   = a(q25_idx);   % umbral Q1/Q2
q75_a   = a(q75_idx);   % umbral Q3/Q4

mask_Q1 = (a <= q25_a);   % bottom 25%
mask_Q4 = (a >= q75_a);   % top 25%

g_Q1 = g .* mask_Q1;
g_Q4 = g .* mask_Q4;

dens_Q1 = sum(g_Q1, 2);
dens_Q4 = sum(g_Q4, 2);

mass_Q1 = da * sum(dens_Q1);
mass_Q4 = da * sum(dens_Q4);

mean_a_Q1 = da * sum(a .* dens_Q1) / max(mass_Q1, 1e-12);
mean_a_Q4 = da * sum(a .* dens_Q4) / max(mass_Q4, 1e-12);

mean_c_Q1   = da * sum(sum(g_Q1 .* c))  / max(mass_Q1, 1e-12);
mean_c_Q4   = da * sum(sum(g_Q4 .* c))  / max(mass_Q4, 1e-12);
mean_cF_Q1  = da * sum(sum(g_Q1 .* c_F)) / max(mass_Q1, 1e-12);
mean_cF_Q4  = da * sum(sum(g_Q4 .* c_F)) / max(mass_Q4, 1e-12);
mean_cI_Q1  = da * sum(sum(g_Q1 .* c_I)) / max(mass_Q1, 1e-12);
mean_cI_Q4  = da * sum(sum(g_Q4 .* c_I)) / max(mass_Q4, 1e-12);

% Quintiles used in the empirical story (Q1 bottom 20%, Q5 top 20%).
q20_idx = find(cdf_total >= 0.20, 1, 'first');
q40_idx = find(cdf_total >= 0.40, 1, 'first');
q60_idx = find(cdf_total >= 0.60, 1, 'first');
q80_idx = find(cdf_total >= 0.80, 1, 'first');
if isempty(q20_idx), q20_idx = 1; end
if isempty(q40_idx), q40_idx = q20_idx; end
if isempty(q60_idx), q60_idx = q40_idx; end
if isempty(q80_idx), q80_idx = q60_idx; end
q20_a = a(q20_idx);
q40_a = a(q40_idx);
q60_a = a(q60_idx);
q80_a = a(q80_idx);
quint_masks = cell(5,1);
quint_masks{1} = (a <= q20_a);
quint_masks{2} = (a > q20_a) & (a <= q40_a);
quint_masks{3} = (a > q40_a) & (a <= q60_a);
quint_masks{4} = (a > q60_a) & (a <= q80_a);
quint_masks{5} = (a > q80_a);

Q_mass       = zeros(1,5);
Q_mean_a     = zeros(1,5);
Q_mean_c     = zeros(1,5);
Q_mean_cF    = zeros(1,5);
Q_mean_pIcI  = zeros(1,5);
Q_mean_ellF  = zeros(1,5);
Q_mean_ellI  = zeros(1,5);
Q_share_inf  = zeros(1,5);
Q_income_F   = zeros(1,5);
Q_income_I   = zeros(1,5);
Q_income_ra  = zeros(1,5);
Q_income_T   = zeros(1,5);
Q_income_Pi  = zeros(1,5);
for jq = 1:5
    qmask = quint_masks{jq};
    gq = g .* qmask;
    Q_mass(jq)      = da * sum(gq(:));
    Q_mean_a(jq)    = da * sum(a .* sum(gq,2)) / max(Q_mass(jq), 1e-12);
    Q_mean_c(jq)    = da * sum(sum(gq .* cons_exp)) / max(Q_mass(jq), 1e-12);
    Q_mean_cF(jq)   = da * sum(sum(gq .* c_F)) / max(Q_mass(jq), 1e-12);
    Q_mean_pIcI(jq) = da * sum(sum(gq .* (p_I*c_I))) / max(Q_mass(jq), 1e-12);
    Q_mean_ellF(jq) = da * sum(sum(gq .* ell_F)) / max(Q_mass(jq), 1e-12);
    Q_mean_ellI(jq) = da * sum(sum(gq .* ell_I)) / max(Q_mass(jq), 1e-12);
    Q_share_inf(jq) = Q_mean_ellI(jq) / max(Q_mean_ellF(jq) + Q_mean_ellI(jq), 1e-12);
    Q_income_F(jq)  = da * sum(sum(gq .* income_formal)) / max(Q_mass(jq), 1e-12);
    Q_income_I(jq)  = da * sum(sum(gq .* income_informal)) / max(Q_mass(jq), 1e-12);
    Q_income_ra(jq) = da * sum(sum(gq .* income_assets)) / max(Q_mass(jq), 1e-12);
    Q_income_T(jq)  = da * sum(sum(gq .* income_transfer)) / max(Q_mass(jq), 1e-12);
    Q_income_Pi(jq) = da * sum(sum(gq .* income_profit)) / max(Q_mass(jq), 1e-12);
end
T6_story = Q_share_inf(1) - Q_share_inf(5);
qlabels = {'Q1','Q2','Q3','Q4','Q5'};

% State groups for plots. With USE_Q=1 the columns are
% (z1,qL), (z1,qH), (z2,qL), (z2,qH), so z plots must aggregate over q.
z_vals_unique = unique(z, 'stable');
if numel(z_vals_unique) >= 2
    z1_val = z_vals_unique(1);
    z2_val = z_vals_unique(end);
else
    z1_val = z_vals_unique(1);
    z2_val = z_vals_unique(1);
end
idx_z1 = find(abs(z - z1_val) < 1e-12);
idx_z2 = find(abs(z - z2_val) < 1e-12);
if isempty(idx_z1), idx_z1 = 1; end
if isempty(idx_z2), idx_z2 = min(2, Ns); end

g_z1 = sum(g(:, idx_z1), 2);
g_z2 = sum(g(:, idx_z2), 2);
mass_z1_plot = max(da * sum(g_z1), 1e-12);
mass_z2_plot = max(da * sum(g_z2), 1e-12);

c_z1_curve    = sum(g(:,idx_z1).*c(:,idx_z1), 2) ./ max(g_z1, 1e-12);
c_z2_curve    = sum(g(:,idx_z2).*c(:,idx_z2), 2) ./ max(g_z2, 1e-12);
ellF_z1_curve = sum(g(:,idx_z1).*ell_F(:,idx_z1), 2) ./ max(g_z1, 1e-12);
ellF_z2_curve = sum(g(:,idx_z2).*ell_F(:,idx_z2), 2) ./ max(g_z2, 1e-12);
ellI_z1_curve = sum(g(:,idx_z1).*ell_I(:,idx_z1), 2) ./ max(g_z1, 1e-12);
ellI_z2_curve = sum(g(:,idx_z2).*ell_I(:,idx_z2), 2) ./ max(g_z2, 1e-12);
cF_z1_curve   = sum(g(:,idx_z1).*c_F(:,idx_z1), 2) ./ max(g_z1, 1e-12);
cF_z2_curve   = sum(g(:,idx_z2).*c_F(:,idx_z2), 2) ./ max(g_z2, 1e-12);
cI_z1_curve   = sum(g(:,idx_z1).*c_I(:,idx_z1), 2) ./ max(g_z1, 1e-12);
cI_z2_curve   = sum(g(:,idx_z2).*c_I(:,idx_z2), 2) ./ max(g_z2, 1e-12);
pIcI_z1_curve = p_I * cI_z1_curve;
pIcI_z2_curve = p_I * cI_z2_curve;
exp_z1_curve  = cF_z1_curve + pIcI_z1_curve;
exp_z2_curve  = cF_z2_curve + pIcI_z2_curve;
share_pIcI_z1_curve = pIcI_z1_curve ./ max(exp_z1_curve, 1e-12);
share_pIcI_z2_curve = pIcI_z2_curve ./ max(exp_z2_curve, 1e-12);

mean_a_z1_plot    = da * sum(a .* g_z1) / mass_z1_plot;
mean_a_z2_plot    = da * sum(a .* g_z2) / mass_z2_plot;
mean_c_z1_plot    = da * sum(sum(g(:,idx_z1).*c(:,idx_z1))) / mass_z1_plot;
mean_c_z2_plot    = da * sum(sum(g(:,idx_z2).*c(:,idx_z2))) / mass_z2_plot;
mean_cF_z1_plot   = da * sum(sum(g(:,idx_z1).*c_F(:,idx_z1))) / mass_z1_plot;
mean_cF_z2_plot   = da * sum(sum(g(:,idx_z2).*c_F(:,idx_z2))) / mass_z2_plot;
mean_cI_z1_plot   = da * sum(sum(g(:,idx_z1).*c_I(:,idx_z1))) / mass_z1_plot;
mean_cI_z2_plot   = da * sum(sum(g(:,idx_z2).*c_I(:,idx_z2))) / mass_z2_plot;
mean_pIcI_z1_plot = p_I * mean_cI_z1_plot;
mean_pIcI_z2_plot = p_I * mean_cI_z2_plot;
mean_share_pIcI_z1_plot = mean_pIcI_z1_plot / max(mean_cF_z1_plot + mean_pIcI_z1_plot, 1e-12);
mean_share_pIcI_z2_plot = mean_pIcI_z2_plot / max(mean_cF_z2_plot + mean_pIcI_z2_plot, 1e-12);
mean_ellF_z1_plot = da * sum(sum(g(:,idx_z1).*ell_F(:,idx_z1))) / mass_z1_plot;
mean_ellF_z2_plot = da * sum(sum(g(:,idx_z2).*ell_F(:,idx_z2))) / mass_z2_plot;
mean_ellI_z1_plot = da * sum(sum(g(:,idx_z1).*ell_I(:,idx_z1))) / mass_z1_plot;
mean_ellI_z2_plot = da * sum(sum(g(:,idx_z2).*ell_I(:,idx_z2))) / mass_z2_plot;

cdf_z1_plot = cumsum(g_z1) * da / mass_z1_plot;
cdf_z2_plot = cumsum(g_z2) * da / mass_z2_plot;
med_idx_z1_plot = find(cdf_z1_plot >= 0.5, 1);
med_idx_z2_plot = find(cdf_z2_plot >= 0.5, 1);
if isempty(med_idx_z1_plot), med_idx_z1_plot = I; end
if isempty(med_idx_z2_plot), med_idx_z2_plot = I; end
med_a_z1_plot = a(med_idx_z1_plot);
med_a_z2_plot = a(med_idx_z2_plot);

% -------------------------------------------------------------------------
% FIGURE 0: STORY DASHBOARD
%   Main presentation figure: assets, consumption, sectoral work, and
%   income sources by wealth quintile.
% -------------------------------------------------------------------------
if EQUILIBRIUM_MODE == 2
    fig_story = figure('Color','white','Position',[80 80 1280 760]);
    c_formal = [0.20 0.45 0.78];
    c_informal = [0.85 0.33 0.10];
    c_assets = [0.35 0.35 0.35];
    c_transfer = [0.47 0.67 0.19];
    c_profit = [0.49 0.18 0.56];
    w_all = da * g(:);
    gQ1_20 = g .* quint_masks{1};
    gQ5_20 = g .* quint_masks{5};
    w_Q1_20 = da * gQ1_20(:);
    w_Q5_20 = da * gQ5_20(:);

    subplot(2,3,1)
    hold on; box on; grid on
    yyaxis left
    plot(a, g_total_plot, 'Color', [0.12 0.28 0.46], 'LineWidth', 2.2)
    ylabel('Densidad estacionaria', 'Interpreter','none')
    yyaxis right
    plot(a, cdf_total, '--', 'Color', [0.55 0.55 0.55], 'LineWidth', 1.8)
    ylabel('CDF', 'Interpreter','none')
    for xq = [q20_a q40_a q60_a q80_a]
        xline(xq, ':', 'Color', [0.25 0.25 0.25], 'LineWidth', 0.9, 'HandleVisibility','off')
    end
    xlabel('Activos a', 'Interpreter','none')
    title('1. Distribucion de activos y cortes de quintil', 'Interpreter','none')
    xlim([amin_plot amax_plot])

    subplot(2,3,2)
    hold on; box on; grid on
    [x_c_all, pdf_c_all] = weighted_pdf(cons_exp(:), w_all, 55);
    [x_c_Q1, pdf_c_Q1] = weighted_pdf(cons_exp(:), w_Q1_20, 45);
    [x_c_Q5, pdf_c_Q5] = weighted_pdf(cons_exp(:), w_Q5_20, 45);
    plot(x_c_all, pdf_c_all, '-', 'Color', [0.35 0.35 0.35], 'LineWidth', 1.8, ...
        'DisplayName', 'Total')
    plot(x_c_Q1, pdf_c_Q1, '-', 'Color', c_informal, 'LineWidth', 2.2, ...
        'DisplayName', 'Q1')
    plot(x_c_Q5, pdf_c_Q5, '--', 'Color', c_formal, 'LineWidth', 2.2, ...
        'DisplayName', 'Q5')
    xline(Q_mean_c(1), ':', 'Color', c_informal, 'LineWidth', 1.1, 'HandleVisibility','off')
    xline(Q_mean_c(5), ':', 'Color', c_formal, 'LineWidth', 1.1, 'HandleVisibility','off')
    xlabel('Gasto total c_F + p_I c_I', 'Interpreter','none')
    ylabel('Densidad ponderada', 'Interpreter','none')
    title('2. Distribucion de consumo: Q1 vs Q5', 'Interpreter','none')
    legend('Location','best','Interpreter','none')

    subplot(2,3,3)
    hold on; box on; grid on
    b_cons = bar(1:5, [Q_mean_cF(:), Q_mean_pIcI(:)], 'stacked');
    b_cons(1).FaceColor = c_formal;
    b_cons(2).FaceColor = c_informal;
    set(gca, 'XTick', 1:5, 'XTickLabel', qlabels, 'TickLabelInterpreter','none')
    ylabel('Gasto medio', 'Interpreter','none')
    title('3. Canasta de consumo por quintil', 'Interpreter','none')
    legend({'Formal c_F','Informal p_I c_I'}, 'Location','northwest', 'Interpreter','none')

    subplot(2,3,4)
    hold on; box on; grid on
    plot(1:5, Q_share_inf, '-o', 'Color', c_informal, 'MarkerFaceColor', c_informal, ...
        'LineWidth', 2.4, 'DisplayName', 'Modelo')
    plot([1 5], [T6_Q1_plt T6_Q5_plt], 'k--s', 'LineWidth', 1.5, ...
        'MarkerFaceColor', [0.9 0.9 0.9], 'DisplayName', sprintf('Dato ENAHO (Q1=%.0f%%, Q5=%.0f%%)', T6_Q1_plt*100, T6_Q5_plt*100))
    yline(T4_plt, ':', 'Color', [0.20 0.20 0.20], 'LineWidth', 1.1, ...
        'DisplayName', sprintf('T4 agregado dato=%.3f', T4_plt))
    set(gca, 'XTick', 1:5, 'XTickLabel', qlabels, 'TickLabelInterpreter','none')
    ylim([0 1.05])
    ylabel('Share horas informales', 'Interpreter','none')
    title(sprintf('4. Informalidad por quintil: modelo %.3f | dato %.3f', T6_story, T6_plt), ...
        'Interpreter','none')
    legend('Location','best','Interpreter','none','FontSize',8)

    subplot(2,3,5)
    hold on; box on; grid on
    inc_mat = [Q_income_F(:), Q_income_I(:), Q_income_ra(:), Q_income_T(:), Q_income_Pi(:)];
    b_inc = bar(1:5, inc_mat, 'stacked');
    b_inc(1).FaceColor = c_formal;
    b_inc(2).FaceColor = c_informal;
    b_inc(3).FaceColor = c_assets;
    b_inc(4).FaceColor = c_transfer;
    b_inc(5).FaceColor = c_profit;
    set(gca, 'XTick', 1:5, 'XTickLabel', qlabels, 'TickLabelInterpreter','none')
    ylabel('Ingreso medio', 'Interpreter','none')
    title('5. Composicion de ingresos por quintil', 'Interpreter','none')
    legend({'Formal neto','Informal','Activos r*a','Transferencia T','Beneficio \Pi_I'}, ...
        'Location','northwest','Interpreter','none','FontSize',7)

    subplot(2,3,6)
    hold on; box on; grid on
    plot(1:5, Q_mean_ellF, '-o', 'Color', c_formal, 'MarkerFaceColor', c_formal, ...
        'LineWidth', 2.2, 'DisplayName', 'Horas formales')
    plot(1:5, Q_mean_ellI, '--s', 'Color', c_informal, 'MarkerFaceColor', c_informal, ...
        'LineWidth', 2.2, 'DisplayName', 'Horas informales')
    set(gca, 'XTick', 1:5, 'XTickLabel', qlabels, 'TickLabelInterpreter','none')
    ylabel('Horas medias', 'Interpreter','none')
    title('6. Asignacion de trabajo por quintil', 'Interpreter','none')
    legend('Location','best','Interpreter','none')

    T4_mod_dash = sum(Q_mean_ellI.*Q_mass)/max(sum((Q_mean_ellF+Q_mean_ellI).*Q_mass),1e-12);
    T5_mod_dash = p_I*Y_I/max(Y_F + p_I*Y_I,1e-12);
    T1_mod_dash = w_F/max(w_I*theta,1e-12);
    sgtitle(sprintf('Equilibrio estacionario — Peru | T1=%.2f(ref %.2f)  T4=%.3f(dat %.3f)  T5=%.3f(dat %.3f)  T6=%.3f(dat %.3f)', ...
        T1_mod_dash, T1_plt, T4_mod_dash, T4_plt, T5_mod_dash, T5_plt, T6_story, T6_plt), ...
        'Interpreter','none','FontSize',10)
    save_png(fig_story, fullfile(output_dir, 'story_dashboard_quintiles.png'), 300)

    fig_cdf = figure('Color','white','Position',[100 100 1050 430]);
    subplot(1,2,1)
    hold on; box on; grid on
    [xQ1, cdfQ1] = weighted_cdf(cons_exp(:), w_Q1_20);
    [xQ5, cdfQ5] = weighted_cdf(cons_exp(:), w_Q5_20);
    [xAll, cdfAll] = weighted_cdf(cons_exp(:), w_all);
    plot(xAll, cdfAll, '-', 'Color', [0.35 0.35 0.35], 'LineWidth', 1.8, 'DisplayName','Total')
    plot(xQ1, cdfQ1, '-', 'Color', c_informal, 'LineWidth', 2.3, 'DisplayName','Q1')
    plot(xQ5, cdfQ5, '--', 'Color', c_formal, 'LineWidth', 2.3, 'DisplayName','Q5')
    xlabel('Gasto total c_F + p_I c_I', 'Interpreter','none')
    ylabel('CDF ponderada', 'Interpreter','none')
    title('CDF de consumo: desplazamiento Q1-Q5', 'Interpreter','none')
    legend('Location','southeast','Interpreter','none')

    subplot(1,2,2)
    hold on; box on; grid on
    plot(a, c_z1_curve, '-', 'Color', c_informal, 'LineWidth', 2.2, ...
        'DisplayName', sprintf('z bajo = %.2f', z1_val))
    plot(a, c_z2_curve, '--', 'Color', c_formal, 'LineWidth', 2.2, ...
        'DisplayName', sprintf('z alto = %.2f', z2_val))
    for xq = [q20_a q40_a q60_a q80_a]
        xline(xq, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 0.8, 'HandleVisibility','off')
    end
    xlabel('Activos a, variable de estado', 'Interpreter','none')
    ylabel('Politica de gasto c_F + p_I c_I', 'Interpreter','none')
    title('Politica de consumo por estado, no scatter endogeno-endogeno', 'Interpreter','none')
    legend('Location','best','Interpreter','none')
    xlim([amin_plot amax_plot])
    grid on
    save_png(fig_cdf, fullfile(output_dir, 'consumption_assets_story.png'), 300)

    fig_trap = figure('Color','white','Position',[90 90 1180 720]);
    share_inf_by_a = sum(g .* ell_I, 2) ./ max(sum(g .* (ell_F + ell_I), 2), 1e-12);
    adot_by_a = sum(g .* adot, 2) ./ max(g_total_plot, 1e-12);
    eff_wF_z1 = (1-tau) * w_F * z1_val - kappa_F_vec;
    eff_wF_z2 = (1-tau) * w_F * z2_val - kappa_F_vec;
    eff_wI_z1 = w_I * theta * z1_val;
    eff_wI_z2 = w_I * theta * z2_val;

    subplot(2,2,1)
    hold on; box on; grid on
    plot(a, kappa_F_vec, 'Color', [0.15 0.15 0.15], 'LineWidth', 2.4)
    for xq = [q20_a q40_a q60_a q80_a]
        xline(xq, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 0.8)
    end
    xlabel('Activos a', 'Interpreter','none')
    ylabel('Costo formal kappa_F(a)', 'Interpreter','none')
    title('1. Barrera formal dependiente de activos', 'Interpreter','none')
    xlim([amin_plot amax_plot])

    subplot(2,2,2)
    hold on; box on; grid on
    plot(a, eff_wF_z1, '-', 'Color', c_informal, 'LineWidth', 2.1, ...
        'DisplayName', 'Formal efectivo neto, z bajo')
    plot(a, eff_wF_z2, '--', 'Color', c_formal, 'LineWidth', 2.1, ...
        'DisplayName', 'Formal efectivo neto, z alto')
    yline(eff_wI_z1, ':', 'Color', c_informal, 'LineWidth', 1.6, ...
        'DisplayName', 'Informal por hora, z bajo')
    yline(eff_wI_z2, '-.', 'Color', c_formal, 'LineWidth', 1.6, ...
        'DisplayName', 'Informal por hora, z alto')
    xlabel('Activos a', 'Interpreter','none')
    ylabel('Retorno laboral efectivo por hora', 'Interpreter','none')
    title('2. Formal vs informal por estado de activos', 'Interpreter','none')
    legend('Location','best','Interpreter','none','FontSize',8)
    xlim([amin_plot amax_plot])

    subplot(2,2,3)
    hold on; box on; grid on
    plot(a, share_inf_by_a, 'Color', c_informal, 'LineWidth', 2.4)
    yline(T4_plt, '--k', 'LineWidth', 1.1, 'DisplayName', sprintf('T4 dato=%.3f', T4_plt))
    for xq = [q20_a q40_a q60_a q80_a]
        xline(xq, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 0.8, 'HandleVisibility','off')
    end
    xlabel('Activos a', 'Interpreter','none')
    ylabel('Share horas informales', 'Interpreter','none')
    title('3. Gradiente de informalidad por riqueza (T6)', 'Interpreter','none')
    ylim([0 1.05])
    xlim([amin_plot amax_plot])

    subplot(2,2,4)
    hold on; box on; grid on
    yyaxis left
    plot(a, adot_by_a, 'Color', [0.12 0.28 0.46], 'LineWidth', 2.3)
    yline(0, '--k', 'LineWidth', 1.0)
    ylabel('Drift promedio de activos E[adot|a]', 'Interpreter','none')
    yyaxis right
    plot(a, g_total_plot, ':', 'Color', [0.65 0.65 0.65], 'LineWidth', 2.0)
    ylabel('Densidad marginal estacionaria g(a)', 'Interpreter','none')
    xlabel('Activos a', 'Interpreter','none')
    title('4. Drift de activos y distribucion estacionaria', 'Interpreter','none')
    xlim([amin_plot amax_plot])

    sgtitle(sprintf('Mecanismo kappa: barrera formal por riqueza (kappa_extra=%.3f, gamma_k=%.1f)', ...
        kappa_extra, gamma_k), 'Interpreter','none','FontSize',11)
    save_png(fig_trap, fullfile(output_dir, 'informality_trap_mechanism.png'), 300)

    story_txt = fullfile(output_dir, 'story_moments_quintiles.txt');
    fid_story = fopen(story_txt, 'w');
    if fid_story >= 0
        fprintf(fid_story, 'Story moments by wealth quintile\n');
        fprintf(fid_story, 'T1 wage gap model: %.6f\n', w_F/max(w_I*theta,1e-12));
        fprintf(fid_story, 'T4 aggregate informal hours: %.6f\n', ...
            sum(Q_mean_ellI .* Q_mass)/max(sum((Q_mean_ellF+Q_mean_ellI).*Q_mass),1e-12));
        fprintf(fid_story, 'T5 nominal informal output share: %.6f\n', p_I*Y_I/max(Y_F + p_I*Y_I,1e-12));
        fprintf(fid_story, 'T6 Q1-Q5 informal hours: %.6f\n\n', T6_story);
        fprintf(fid_story, 'Q mass mean_a mean_exp mean_cF mean_pIcI mean_ellF mean_ellI share_inf income_F income_I income_assets income_T income_Pi\n');
        for jq = 1:5
            fprintf(fid_story, '%d %.8f %.8f %.8f %.8f %.8f %.8f %.8f %.8f %.8f %.8f %.8f %.8f %.8f\n', ...
                jq, Q_mass(jq), Q_mean_a(jq), Q_mean_c(jq), Q_mean_cF(jq), Q_mean_pIcI(jq), ...
                Q_mean_ellF(jq), Q_mean_ellI(jq), Q_share_inf(jq), Q_income_F(jq), ...
                Q_income_I(jq), Q_income_ra(jq), Q_income_T(jq), Q_income_Pi(jq));
        end
        fclose(fid_story);
    end
end

% -------------------------------------------------------------------------
% FIGURE 0b: LORENZ + GINI (validacion de desigualdad)
% -------------------------------------------------------------------------
if exist('lorenz_a','var') && exist('Gini_a','var')
    fig_lorenz = figure('Color','white','Position',[80 100 1260 420]);
    subplot(1,3,1)
    hold on; box on; grid on
    plot([0;cumsum(g_marg_a)], [0;lorenz_a], 'Color',[0.12 0.28 0.46], 'LineWidth', 2.4, ...
        'DisplayName', sprintf('Modelo (Gini=%.3f)', Gini_a))
    plot([0 1], [0 1], 'k--', 'LineWidth', 1.2, 'DisplayName', 'Igualdad perfecta')
    xlabel('Fraccion poblacion (por riqueza)', 'Interpreter','none')
    ylabel('Fraccion riqueza acumulada', 'Interpreter','none')
    title(sprintf('Curva de Lorenz - riqueza neta\nGini modelo=%.3f  |  ref riqueza externa por definir', Gini_a), ...
        'Interpreter','none')
    legend('Location','northwest','Interpreter','none')
    y_min_a = min([0; lorenz_a(:)]);
    y_pad_a = max(0.02, 0.05 * (1 - y_min_a));
    xlim([0 1]); ylim([y_min_a - y_pad_a, 1])
    if y_min_a < 0
        yline(0, ':', 'Color', [0.35 0.35 0.35], 'LineWidth', 0.9, ...
            'HandleVisibility','off')
    end

    subplot(1,3,2)
    hold on; box on; grid on
    if exist('lorenz_c','var') && exist('Gini_c','var')
        plot([0;cum_pop_c], [0;lorenz_c], 'Color',[0.85 0.33 0.10], 'LineWidth', 2.4, ...
            'DisplayName', sprintf('Modelo (Gini=%.3f)', Gini_c))
    end
    plot([0 1], [0 1], 'k--', 'LineWidth', 1.2, 'DisplayName', 'Igualdad perfecta')
    xlabel('Fraccion poblacion (por gasto)', 'Interpreter','none')
    ylabel('Fraccion gasto acumulada', 'Interpreter','none')
    title(sprintf('Curva de Lorenz - gasto\nGini modelo=%.3f  |  ref ENAHO gasto/ingreso', Gini_c), ...
        'Interpreter','none')
    legend('Location','northwest','Interpreter','none')
    xlim([0 1]); ylim([0 1])

    subplot(1,3,3)
    hold on; box on; grid on
    plot(1:5, Q_share_inf, '-o', 'Color', [0.85 0.33 0.10], ...
        'MarkerFaceColor', [0.85 0.33 0.10], 'LineWidth', 2.2, ...
        'DisplayName', 'Modelo')
    plot([1 5], [T6_Q1_plt T6_Q5_plt], 'k--s', 'LineWidth', 1.4, ...
        'MarkerFaceColor', [0.9 0.9 0.9], 'DisplayName', 'Dato Q1-Q5')
    yline(T4_plt, ':', 'Color', [0.20 0.20 0.20], 'LineWidth', 1.0, ...
        'DisplayName', 'T4 agregado')
    set(gca, 'XTick', 1:5, 'XTickLabel', qlabels, 'TickLabelInterpreter','none')
    xlabel('Quintil de riqueza', 'Interpreter','none')
    ylabel('Share horas informales', 'Interpreter','none')
    title(sprintf('Concentracion informal por riqueza\nQ1-Q5 modelo=%.3f | dato=%.3f', T6_story, T6_plt), ...
        'Interpreter','none')
    ylim([0 1.05])
    legend('Location','best','Interpreter','none','FontSize',8)

    sgtitle('Desigualdad del modelo — validacion (no target calibrado)', ...
        'Interpreter','none','FontSize',11)
    save_png(fig_lorenz, fullfile(output_dir, 'lorenz_gini.png'), 300)
end

% -------------------------------------------------------------------------
% FIGURE 0c: TABLAS LORENZ
%   1) Deciles del modelo ordenados por riqueza neta.
%   2) Quintiles de gasto/ingreso comparables con Banco Mundial/PIP Peru 2024.
% -------------------------------------------------------------------------
if EQUILIBRIUM_MODE == 2
    dec_n = 10;
    dec_mass = zeros(dec_n,1);
    dec_a_mean = zeros(dec_n,1);
    dec_exp_mean = zeros(dec_n,1);
    dec_wealth_share = zeros(dec_n,1);
    dec_exp_share = zeros(dec_n,1);
    dec_wealth_cum = zeros(dec_n,1);
    dec_exp_cum = zeros(dec_n,1);
    dec_pop_cum = (1:dec_n)' / dec_n;

    dec_edges_idx = zeros(dec_n-1,1);
    for jd = 1:(dec_n-1)
        idx_d = find(cdf_total >= jd/dec_n, 1, 'first');
        if isempty(idx_d), idx_d = I; end
        dec_edges_idx(jd) = idx_d;
    end

    dec_masks = cell(dec_n,1);
    for jd = 1:dec_n
        if jd == 1
            dec_masks{jd} = (a <= a(dec_edges_idx(1)));
        elseif jd == dec_n
            dec_masks{jd} = (a > a(dec_edges_idx(dec_n-1)));
        else
            dec_masks{jd} = (a > a(dec_edges_idx(jd-1))) & (a <= a(dec_edges_idx(jd)));
        end
    end

    total_wealth = da * sum(sum(g .* aa));
    total_exp = da * sum(sum(g .* cons_exp));
    for jd = 1:dec_n
        gd = g .* dec_masks{jd};
        dec_mass(jd) = da * sum(gd(:));
        dec_a_mean(jd) = da * sum(sum(gd .* aa)) / max(dec_mass(jd), 1e-12);
        dec_exp_mean(jd) = da * sum(sum(gd .* cons_exp)) / max(dec_mass(jd), 1e-12);
        dec_wealth_share(jd) = da * sum(sum(gd .* aa)) / max(total_wealth, 1e-12);
        dec_exp_share(jd) = da * sum(sum(gd .* cons_exp)) / max(total_exp, 1e-12);
    end
    dec_wealth_cum = cumsum(dec_wealth_share);
    dec_exp_cum = cumsum(dec_exp_share);

    lorenz_decile_file = fullfile(output_dir, 'lorenz_deciles_model.txt');
    fid_dec = fopen(lorenz_decile_file, 'w');
    if fid_dec >= 0
        fprintf(fid_dec, 'Decile table from model, ordered by net wealth a\n');
        fprintf(fid_dec, 'Gini wealth %.8f\n', Gini_a);
        fprintf(fid_dec, 'Gini expenditure %.8f\n', Gini_c);
        fprintf(fid_dec, 'decil mass pop_cum mean_a wealth_share wealth_cum mean_exp exp_share exp_cum\n');
        for jd = 1:dec_n
            fprintf(fid_dec, '%d %.8f %.8f %.8f %.8f %.8f %.8f %.8f %.8f\n', ...
                jd, dec_mass(jd), dec_pop_cum(jd), dec_a_mean(jd), ...
                dec_wealth_share(jd), dec_wealth_cum(jd), dec_exp_mean(jd), ...
                dec_exp_share(jd), dec_exp_cum(jd));
        end
        fclose(fid_dec);
    end

    fig_dec = figure('Color','white','Position',[80 80 1220 620]);
    annotation(fig_dec, 'textbox', [0.04 0.935 0.92 0.040], ...
        'String', sprintf('Tabla Lorenz por deciles del modelo  |  Gini riqueza=%.3f, Gini gasto=%.3f', Gini_a, Gini_c), ...
        'FontSize', 13, 'FontWeight','bold', 'Interpreter','none', ...
        'HorizontalAlignment','center', 'EdgeColor','none')
    annotation(fig_dec, 'textbox', [0.05 0.880 0.90 0.050], ...
        'String', {'Ordenado por riqueza neta a. Comparacion correcta: riqueza vs patrimonio; gasto/ingreso vs encuesta de hogares.', ...
        'wealth_cum puede ser negativo si los primeros deciles tienen deuda neta.'}, ...
        'FontSize', 9, 'Interpreter','none', 'HorizontalAlignment','center', ...
        'EdgeColor','none')
    axes('Parent', fig_dec, 'Position', [0.035 0.055 0.93 0.79]);
    axis off

    headers = {'D','Masa','Pob. acum','a medio','Share riqueza','Riq. acum','Gasto medio','Share gasto','Gasto acum'};
    data_mat = [(1:dec_n)', dec_mass, dec_pop_cum, dec_a_mean, dec_wealth_share, ...
        dec_wealth_cum, dec_exp_mean, dec_exp_share, dec_exp_cum];
    fmts = {'%d','%.3f','%.2f','%.3f','%.3f','%.3f','%.3f','%.3f','%.3f'};

    x0 = 0.035; y0 = 0.93; row_h = 0.078;
    col_w = [0.045 0.085 0.095 0.105 0.125 0.110 0.120 0.105 0.105];
    col_x = x0 + [0 cumsum(col_w(1:end-1))];
    total_w = sum(col_w);
    table_bottom = y0 - row_h*(dec_n+1) - 0.006;
    table_height = row_h*(dec_n+1) + 0.020;
    rectangle('Position',[x0-0.01, table_bottom, total_w+0.02, table_height], ...
        'FaceColor',[1 1 1], 'EdgeColor',[0.25 0.25 0.25], 'LineWidth',1.0)
    rectangle('Position',[x0-0.01, y0-row_h+0.008, total_w+0.02, row_h], ...
        'FaceColor',[0.90 0.93 0.96], 'EdgeColor','none')
    for jc = 1:numel(headers)
        text(col_x(jc)+col_w(jc)/2, y0-row_h/2, headers{jc}, ...
            'HorizontalAlignment','center', 'FontWeight','bold', 'FontSize',8.5, 'Interpreter','none')
    end
    for jd = 1:dec_n
        yy = y0 - row_h*(jd+0.5);
        if mod(jd,2)==0
            rectangle('Position',[x0-0.01, yy-row_h/2, total_w+0.02, row_h], ...
                'FaceColor',[0.97 0.97 0.97], 'EdgeColor','none')
        end
        for jc = 1:size(data_mat,2)
            text(col_x(jc)+col_w(jc)/2, yy, sprintf(fmts{jc}, data_mat(jd,jc)), ...
                'HorizontalAlignment','center', 'FontSize',8.5, 'Interpreter','none')
        end
    end
    save_png(fig_dec, fullfile(output_dir, 'lorenz_deciles_table.png'), 300)
    fprintf('Lorenz decile table saved to %s and PNG saved.\n', lorenz_decile_file)

    % Referencia externa publica: World Bank WDI / Poverty and Inequality
    % Platform, Peru 2024. Estos son shares de ingreso o consumo, no riqueza.
    wb_year = 2024;
    peru_gini_wb = 0.401;
    peru_q_share = [0.056; 0.106; 0.154; 0.221; 0.462];
    peru_q_cum = cumsum(peru_q_share);

    q_n = 5;
    exp_vec_q = cons_exp(:);
    w_vec_q = g(:) * da;
    ok_q = isfinite(exp_vec_q) & isfinite(w_vec_q) & w_vec_q > 0;
    [exp_sorted_q, idx_q] = sort(exp_vec_q(ok_q), 'ascend');
    w_sorted_q = w_vec_q(ok_q);
    w_sorted_q = w_sorted_q(idx_q);
    pop_sorted_q = cumsum(w_sorted_q) / max(sum(w_sorted_q), 1e-12);

    model_q_mass = zeros(q_n,1);
    model_q_exp_mean = zeros(q_n,1);
    model_q_share = zeros(q_n,1);
    total_exp_q = sum(exp_sorted_q .* w_sorted_q);
    for jq = 1:q_n
        lo_q = (jq-1) / q_n;
        hi_q = jq / q_n;
        if jq == 1
            mask_q = pop_sorted_q <= hi_q;
        else
            mask_q = pop_sorted_q > lo_q & pop_sorted_q <= hi_q;
        end
        if jq == q_n
            mask_q = pop_sorted_q > lo_q;
        end
        model_q_mass(jq) = sum(w_sorted_q(mask_q));
        model_q_exp_mean(jq) = sum(exp_sorted_q(mask_q) .* w_sorted_q(mask_q)) / max(model_q_mass(jq), 1e-12);
        model_q_share(jq) = sum(exp_sorted_q(mask_q) .* w_sorted_q(mask_q)) / max(total_exp_q, 1e-12);
    end
    model_q_cum = cumsum(model_q_share);

    lorenz_quintile_file = fullfile(output_dir, 'lorenz_quintiles_peru_comparison.txt');
    fid_q = fopen(lorenz_quintile_file, 'w');
    if fid_q >= 0
        fprintf(fid_q, 'Quintile comparison: model expenditure vs Peru World Bank/PIP %d income or consumption shares\n', wb_year);
        fprintf(fid_q, 'Model Gini expenditure %.8f\n', Gini_c);
        fprintf(fid_q, 'Peru World Bank Gini %.8f\n', peru_gini_wb);
        fprintf(fid_q, 'quintile model_mass model_exp_mean model_share model_cum peru_share peru_cum\n');
        for jq = 1:q_n
            fprintf(fid_q, '%d %.8f %.8f %.8f %.8f %.8f %.8f\n', ...
                jq, model_q_mass(jq), model_q_exp_mean(jq), model_q_share(jq), ...
                model_q_cum(jq), peru_q_share(jq), peru_q_cum(jq));
        end
        fclose(fid_q);
    end

    fig_q = figure('Color','white','Position',[90 90 1120 520]);
    annotation(fig_q, 'textbox', [0.04 0.935 0.92 0.040], ...
        'String', sprintf('Quintiles gasto/ingreso: modelo vs Peru %d  |  Gini modelo=%.3f, Peru=%.3f', ...
        wb_year, Gini_c, peru_gini_wb), ...
        'FontSize', 13, 'FontWeight','bold', 'Interpreter','none', ...
        'HorizontalAlignment','center', 'EdgeColor','none')
    annotation(fig_q, 'textbox', [0.06 0.875 0.88 0.050], ...
        'String', 'Fuente Peru: World Bank WDI/Poverty and Inequality Platform. Comparable con gasto/ingreso del modelo, no con riqueza neta a.', ...
        'FontSize', 9, 'Interpreter','none', 'HorizontalAlignment','center', ...
        'EdgeColor','none')
    axes('Parent', fig_q, 'Position', [0.045 0.080 0.91 0.76]);
    axis off

    headers_q = {'Q','Masa mod.','Gasto medio mod.','Share mod.','Acum. mod.','Share Peru','Acum. Peru','Dif. acum.'};
    data_q = [(1:q_n)', model_q_mass, model_q_exp_mean, model_q_share, model_q_cum, ...
        peru_q_share, peru_q_cum, model_q_cum - peru_q_cum];
    fmts_q = {'%d','%.3f','%.3f','%.3f','%.3f','%.3f','%.3f','%.3f'};

    x0q = 0.055; y0q = 0.88; row_hq = 0.125;
    col_wq = [0.055 0.115 0.165 0.115 0.115 0.115 0.115 0.115];
    col_xq = x0q + [0 cumsum(col_wq(1:end-1))];
    total_wq = sum(col_wq);
    table_bottom_q = y0q - row_hq*(q_n+1) - 0.010;
    table_height_q = row_hq*(q_n+1) + 0.025;
    rectangle('Position',[x0q-0.012, table_bottom_q, total_wq+0.024, table_height_q], ...
        'FaceColor',[1 1 1], 'EdgeColor',[0.25 0.25 0.25], 'LineWidth',1.0)
    rectangle('Position',[x0q-0.012, y0q-row_hq+0.010, total_wq+0.024, row_hq], ...
        'FaceColor',[0.90 0.93 0.96], 'EdgeColor','none')
    for jc = 1:numel(headers_q)
        text(col_xq(jc)+col_wq(jc)/2, y0q-row_hq/2, headers_q{jc}, ...
            'HorizontalAlignment','center', 'FontWeight','bold', 'FontSize',9, 'Interpreter','none')
    end
    for jq = 1:q_n
        yyq = y0q - row_hq*(jq+0.5);
        if mod(jq,2)==0
            rectangle('Position',[x0q-0.012, yyq-row_hq/2, total_wq+0.024, row_hq], ...
                'FaceColor',[0.97 0.97 0.97], 'EdgeColor','none')
        end
        for jc = 1:size(data_q,2)
            text(col_xq(jc)+col_wq(jc)/2, yyq, sprintf(fmts_q{jc}, data_q(jq,jc)), ...
                'HorizontalAlignment','center', 'FontSize',9, 'Interpreter','none')
        end
    end
    save_png(fig_q, fullfile(output_dir, 'lorenz_quintiles_peru_comparison.png'), 300)
    fprintf('Lorenz quintile comparison saved to %s and PNG saved.\n', lorenz_quintile_file)
end

% -------------------------------------------------------------------------
% FIGURE 1: SAVING POLICY
% -------------------------------------------------------------------------
figure('Position', [100, 100, 700, 500])
plot(a, sum(g(:,idx_z1).*adot(:,idx_z1), 2) ./ max(g_z1, 1e-12), 'b-', 'LineWidth', 2.5)
hold on
plot(a, sum(g(:,idx_z2).*adot(:,idx_z2), 2) ./ max(g_z2, 1e-12), 'r--', 'LineWidth', 2.5)
plot(linspace(amin_plot, amax_plot, 100), zeros(1,100), 'k--', 'LineWidth', 1)
line([amin_data_plot amin_data_plot], [min(min(adot))*1.1 max(max(adot))*1.1], ...
    'Color', 'k', 'LineStyle', '--', 'LineWidth', 1)
if amin_plot < 0 && amax_plot > 0
    xline(0, ':', 'Color', [0.35 0.35 0.35], 'LineWidth', 1, 'HandleVisibility', 'off')
end
legend(sprintf('z bajo=%.2f (baja prod.)', z1_val), sprintf('z alto=%.2f (alta prod.)', z2_val), 'Location','NorthEast')
xlabel('Riqueza a', 'FontSize', 14, 'Interpreter', 'none')
ylabel('Ahorro adot', 'FontSize', 14, 'Interpreter', 'none')
title(sprintf('Politica de ahorro — r*=%.4f, tau=%.2f', r_eq, tau), 'FontSize', 13, 'Interpreter', 'none')
xlim([amin_plot amax_plot])
y_min_adot = min(min(adot(1:idx_max,:)));
y_max_adot = max(max(adot(1:idx_max,:)));
if y_min_adot == y_max_adot
    y_min_adot = y_min_adot - 1e-3;
    y_max_adot = y_max_adot + 1e-3;
end
ylim([min(0, y_min_adot*1.2) max(0, y_max_adot*1.2)])
grid on; set(gca, 'FontSize', 12)
save_png(gcf, fullfile(output_dir, 'savings_policy.png'), 300)

% -------------------------------------------------------------------------
% FIGURE 2: WEALTH DISTRIBUTION
% -------------------------------------------------------------------------
figure('Position', [100, 100, 700, 500])
plot(a, g_z1, 'b-', 'LineWidth', 2.5)
hold on
plot(a, g_z2, 'r--', 'LineWidth', 2.5)
line([amin_data_plot amin_data_plot], [0 max(max(g))*1.1], 'Color', 'k', 'LineStyle', '--', 'LineWidth', 1)
if amin_plot < 0 && amax_plot > 0
    xline(0, ':', 'Color', [0.35 0.35 0.35], 'LineWidth', 1, 'HandleVisibility', 'off')
end
legend(sprintf('g(a,z1=%.2f)', z1_val), sprintf('g(a,z2=%.2f)', z2_val), 'Location', 'NorthEast')
xlabel('Riqueza a', 'FontSize', 14, 'Interpreter', 'none')
ylabel('Densidad estacionaria g(a,z)', 'FontSize', 14, 'Interpreter', 'none')
title(sprintf('Distribucion estacionaria de riqueza — r*=%.4f', r_eq), 'FontSize', 13, 'Interpreter', 'none')
xlim([amin_plot amax_plot])
ylim([0 max(max(g(1:idx_max,:)))*1.1])
grid on; set(gca, 'FontSize', 12)
save_png(gcf, fullfile(output_dir, 'wealth_distribution.png'), 300)

% -------------------------------------------------------------------------
% FIGURE 3: EFFECTIVE CONSUMPTION POLICY
% -------------------------------------------------------------------------
figure('Position', [100, 100, 700, 500])
plot(a, c_z1_curve, 'b-', 'LineWidth', 2.5)
hold on
plot(a, c_z2_curve, 'r--', 'LineWidth', 2.5)
legend(sprintf('z bajo=%.2f', z1_val), sprintf('z alto=%.2f', z2_val), 'Location', 'SouthEast')
xlabel('Riqueza a', 'FontSize', 14, 'Interpreter', 'none')
ylabel('Gasto efectivo c_F + p_I c_I', 'FontSize', 14, 'Interpreter', 'none')
title(sprintf('Politica de consumo — r*=%.4f, tau=%.2f', r_eq, tau), 'FontSize', 13, 'Interpreter', 'none')
xlim([amin_plot amax_plot])
grid on; set(gca, 'FontSize', 12)
save_png(gcf, fullfile(output_dir, 'consumption_policy.png'), 300)

% -------------------------------------------------------------------------
% FIGURE 3b: FORMAL vs INFORMAL CONSUMPTION
% -------------------------------------------------------------------------
figure('Position', [100, 100, 1000, 450])
subplot(1,2,1)
plot(a, cF_z1_curve, 'b-', 'LineWidth', 2.2); hold on
plot(a, cI_z1_curve, 'r--', 'LineWidth', 2.2)
legend('c_F formal', 'c_I informal', 'Location', 'best', 'Interpreter', 'none')
xlabel('Riqueza a', 'FontSize', 13, 'Interpreter', 'none')
ylabel('Componentes de consumo', 'FontSize', 13, 'Interpreter', 'none')
title(sprintf('Baja productividad z=%.2f', z1_val), 'FontSize', 13, 'Interpreter', 'none')
xlim([amin_plot amax_plot]); grid on

subplot(1,2,2)
plot(a, cF_z2_curve, 'b-', 'LineWidth', 2.2); hold on
plot(a, cI_z2_curve, 'r--', 'LineWidth', 2.2)
legend('c_F formal', 'c_I informal', 'Location', 'best', 'Interpreter', 'none')
xlabel('Riqueza a', 'FontSize', 13, 'Interpreter', 'none')
ylabel('Componentes de consumo', 'FontSize', 13, 'Interpreter', 'none')
title(sprintf('Alta productividad z=%.2f', z2_val), 'FontSize', 13, 'Interpreter', 'none')
xlim([amin_plot amax_plot]); grid on
sgtitle(sprintf('Canasta de consumo formal/informal — p_I=%.2f, sigma_C=%.2f, omega_C=%.2f', p_I, sigma_C, omega_C), ...
    'FontSize', 12, 'Interpreter', 'none')
save_png(gcf, fullfile(output_dir, 'consumption_formal_informal.png'), 300)

% -------------------------------------------------------------------------
% FIGURE 4: FORMAL vs INFORMAL LABOR
% -------------------------------------------------------------------------
figure('Position', [100, 100, 1000, 450])
subplot(1,2,1)
plot(a, ellF_z1_curve, 'b-', 'LineWidth', 2.5)
hold on
plot(a, ellI_z1_curve, 'r-', 'LineWidth', 2.5)
legend({'Horas formales ell_F', 'Horas informales ell_I'}, ...
    'Interpreter', 'none', 'Location', 'NorthEast', 'FontSize', 11)
xlabel('Riqueza a', 'FontSize', 13, 'Interpreter', 'none')
ylabel('Horas de trabajo', 'FontSize', 13, 'Interpreter', 'none')
title(sprintf('Baja productividad (z=%.2f)', z1_val), 'FontSize', 13, 'Interpreter', 'none')
xlim([amin_plot amax_plot])
ylim([0 max(1, 1.05*max([ellF_z1_curve; ellI_z1_curve]))])
grid on; set(gca, 'FontSize', 11)

subplot(1,2,2)
plot(a, ellF_z2_curve, 'b--', 'LineWidth', 2.5)
hold on
plot(a, ellI_z2_curve, 'r--', 'LineWidth', 2.5)
legend({'Horas formales ell_F', 'Horas informales ell_I'}, ...
    'Interpreter', 'none', 'Location', 'NorthEast', 'FontSize', 11)
xlabel('Riqueza a', 'FontSize', 13, 'Interpreter', 'none')
ylabel('Horas de trabajo', 'FontSize', 13, 'Interpreter', 'none')
title(sprintf('Alta productividad (z=%.2f)', z2_val), 'FontSize', 13, 'Interpreter', 'none')
xlim([amin_plot amax_plot])
ylim([0 max(1, 1.05*max([ellF_z2_curve; ellI_z2_curve]))])
grid on; set(gca, 'FontSize', 11)

sgtitle(sprintf('Asignacion de trabajo: formal (w_F=%.3f, tau=%.2f) vs informal (w_I=%.3f, beta_I=%.2f)', ...
    w_F, tau, w_I, beta_I), 'FontSize', 12, 'Interpreter', 'none')
save_png(gcf, fullfile(output_dir, 'labor_formal_vs_informal.png'), 300)

if USE_Q == 1 && Ns == 4
    fig4q = figure('Color', 'white', 'Position', [100, 100, 980, 680]);
    state_labels = { ...
        sprintf('z1=%.2f, qL=%.2f', z(1), q_inf(1)), ...
        sprintf('z1=%.2f, qH=%.2f', z(2), q_inf(2)), ...
        sprintf('z2=%.2f, qL=%.2f', z(3), q_inf(3)), ...
        sprintf('z2=%.2f, qH=%.2f', z(4), q_inf(4))};
    for js = 1:4
        subplot(2,2,js)
        hold on; box on; grid on
        plot(a, ell_F(:,js), 'b-', 'LineWidth', 2.1, 'DisplayName', 'ell_F formal')
        plot(a, ell_I(:,js), 'r--', 'LineWidth', 2.1, 'DisplayName', 'ell_I informal')
        xlim([amin_plot amax_plot])
        ylim([0 1.05 * max(1, max([ell_F(:,js); ell_I(:,js)]))])
        title(state_labels{js}, 'Interpreter', 'none', 'FontSize', 11)
        xlabel('Wealth a', 'Interpreter', 'none')
        ylabel('Labor supply', 'Interpreter', 'none')
        if js == 1
            legend('Location', 'best', 'Interpreter', 'none')
        end
    end
    sgtitle('Labor policies by state (z,q): no aggregation over q', ...
        'FontSize', 12, 'Interpreter', 'none')
    save_png(fig4q, fullfile(output_dir, 'labor_by_zq_state.png'), 300)
end

% -------------------------------------------------------------------------
% FIGURE 4b: RATIO ell_F / ell_I vs wealth
%   Labor ratio ell_I / ell_F vs wealth
%   ratio = ell_I/ell_F should be constant in interior (FOC)
%   deviates at corners (all formal or all informal)
% -------------------------------------------------------------------------
if EQUILIBRIUM_MODE == 2
    eps_floor = 1e-8;
    ratio_z1  = ellI_z1_curve ./ max(ellF_z1_curve, eps_floor);
    ratio_z2  = ellI_z2_curve ./ max(ellF_z2_curve, eps_floor);

    % Theoretical ratio from unconstrained FOC interior solution
    % ell_I/ell_F = [(w_I*theta*psi_F) / ((1-tau)*w_F*psi_I)]^Frisch
    ratio_th = ((w_I*theta*psi_F) / ((1-tau)*w_F*psi_I))^Frisch;

    figure('Position', [100, 100, 700, 500])
    plot(a, ratio_z1, 'b-',  'LineWidth', 2.5); hold on
    plot(a, ratio_z2, 'r--', 'LineWidth', 2.5)
    yline(ratio_th, 'k--', 'LineWidth', 1.5)
    text(amax*0.7, ratio_th*1.05, sprintf('FOC ratio = %.3f', ratio_th), ...
        'FontSize', 10, 'Interpreter', 'latex')
    legend({'$\ell_I/\ell_F$ ($z_1$)', '$\ell_I/\ell_F$ ($z_2$)', 'FOC interior ratio'}, ...
        'Interpreter', 'latex', 'Location', 'NorthEast', 'FontSize', 10)
    xlabel('Wealth, $a$', 'FontSize', 13, 'Interpreter', 'latex')
    ylabel('$\ell_I / \ell_F$', 'FontSize', 13, 'Interpreter', 'latex')
    title(sprintf('Labor ratio $\\ell_I/\\ell_F$ ($\\tau=%.2f$, $\\beta_I=%.2f$)', tau, beta_I), ...
        'FontSize', 13, 'Interpreter', 'latex')
    xlim([amin_plot amax_plot])
    grid on; set(gca, 'FontSize', 11)
    save_png(gcf, fullfile(output_dir, 'labor_ratio.png'), 300)
end

% -------------------------------------------------------------------------
% FIGURE 5: INFORMAL WAGE CURVE
%   Shows w_I = beta_I * A_I * L_I^(beta_I-1) — decreasing in L_I
%   Equilibrium: intersection with household labor supply
% -------------------------------------------------------------------------
if EQUILIBRIUM_MODE == 2
    LI_range  = linspace(0.01, 1, 200);
    wI_demand = p_I * beta_I * A_I * LI_range.^(beta_I - 1);

    figure('Color', 'white', 'Position', [100 100 700 500])
    hold on; box on; grid on
    plot(LI_range, wI_demand, 'r-', 'LineWidth', 2.5, ...
        'DisplayName', '$w_I = p_I\beta_I A_I L_I^{\beta_I-1}$')
    plot(L_I_star, w_I_star, 'go', 'MarkerSize', 12, ...
        'MarkerFaceColor', [0.1 0.75 0.1], 'LineWidth', 2, ...
        'DisplayName', sprintf('Equilibrium $L_I^*=%.3f$, $w_I^*=%.3f$', L_I_star, w_I_star))
    plot([L_I_star L_I_star], [0 w_I_star], 'k--', 'LineWidth', 0.8, 'HandleVisibility', 'off')
    plot([0 L_I_star], [w_I_star w_I_star], 'k--', 'LineWidth', 0.8, 'HandleVisibility', 'off')
    xlabel('Informal labor $L_I$', 'FontSize', 14, 'Interpreter', 'latex')
    ylabel('Informal wage $w_I$',  'FontSize', 14, 'Interpreter', 'latex')
    title(sprintf('Informal Labor Market ($p_I=%.3f$, $\\beta_I=%.2f$, $A_I=%.4f$)', p_I, beta_I, A_I), ...
        'FontSize', 14, 'Interpreter', 'latex')
    legend('Location', 'NorthEast', 'Interpreter', 'latex', 'FontSize', 10)
    set(gca, 'FontSize', 12)
    save_png(gcf, fullfile(output_dir, 'informal_labor_market.png'), 300)
end

% -------------------------------------------------------------------------
% FIGURE 6: GENERAL EQUILIBRIUM (S(r) and K^D(r) curves)
% -------------------------------------------------------------------------
if EQUILIBRIUM_MODE == 2
    % Load PE curves if available
    fig6 = figure('Color', 'white', 'Position', [100, 100, 800, 550]);
    hold on; box on; grid on

    is_corner_formal = (K_star <= 1e-8) || (L_F_star <= 1e-8);
    has_pe_curves = exist('aiyagari_2firms_v10_R2_precio_endogeno_partial.mat', 'file');

    if has_pe_curves
        pe     = load('aiyagari_2firms_v10_R2_precio_endogeno_partial.mat', 'S', 'KD', 'r_grid');
        K_clip = max(K_star*10, max(pe.S)*3);
        ok     = isfinite(pe.S) & isfinite(pe.KD) & pe.S > 0 & pe.KD > 0 & pe.KD < K_clip;
        plot(pe.S(ok),  pe.r_grid(ok), 'b-', 'LineWidth', 2.2, ...
            'DisplayName', '$S(r)$ — household supply')
        plot(pe.KD(ok), pe.r_grid(ok), 'r-', 'LineWidth', 2.2, ...
            'DisplayName', '$K^D(r)$ — firm demand')
        xmax = max(max(pe.S(ok)), max(pe.KD(ok)))*1.15;
    elseif is_corner_formal
        xmax = max(0.05, 1.25 * max(K_star, 1e-6));
        text(0.04*xmax, rho*0.65, ...
            sprintf('Corner solution: K*=%.2e, L_F*=%.2e\\nNo PE S(r) file available.', K_star, L_F_star), ...
            'FontSize', 10, 'Interpreter', 'none', 'BackgroundColor', 'white', ...
            'EdgeColor', [0.75 0.75 0.75])
        fprintf('  [info] formal corner (K*=%.3e, L_F*=%.3e); skipping K^D approximation.\n', K_star, L_F_star)
    else
        rrr       = linspace(-0.04, rho*0.98, 120);
        KD_approx = (al*A_F ./ max(rrr + d, 1e-6)).^(1/(1-al)) * L_F_star;
        plot(KD_approx, rrr, 'r-', 'LineWidth', 2.0, ...
            'DisplayName', '$K^D(r)$ (approx., run PE mode for $S(r)$)')
        xmax = max(KD_approx(isfinite(KD_approx) & KD_approx > 0))*1.1;
        fprintf('  [info] partial.mat no encontrado — usando aprox. K^D(r). Corre MODE=1 para obtener S(r) completa.\n')
    end

    if isempty(xmax) || ~isfinite(xmax) || xmax <= 0
        xmax = max(1, 1.25 * max(K_star, 1e-6));
    end

    plot(K_star, r_star, 'go', 'MarkerSize', 14, 'MarkerFaceColor', [0.2 0.7 0.2], ...
        'LineWidth', 2, 'DisplayName', ...
        sprintf('Equilibrium  $r^*=%.4f$,  $K^*=%.4f$', r_star, K_star))
    plot([0 xmax], [rho rho], 'b:', 'LineWidth', 1.2, ...
        'DisplayName', sprintf('$\\rho=%.2f$', rho))
    plot([0 xmax], [-d  -d],  'm:', 'LineWidth', 1.2, ...
        'DisplayName', sprintf('$-\\delta=-%.2f$', d))
    plot([0 xmax], [r_star r_star], 'k--', 'LineWidth', 0.8, 'HandleVisibility', 'off')
    plot([K_star K_star], [-d*1.2 r_star], 'k--', 'LineWidth', 0.8, 'HandleVisibility', 'off')

    w_F_net_star = (1-tau) * w_F_star;
    annotation('textbox', [0.56 0.12 0.34 0.39], ...
        'String', { ...
            sprintf('$r^*   = %.5f$', r_star), ...
            sprintf('$K^*   = %.4f$', K_star), ...
            sprintf('$w_F^* gross = %.4f$', w_F_star), ...
            sprintf('$(1-\\tau)w_F^* = %.4f$', w_F_net_star), ...
            sprintf('$w_{I,marg}^* = %.4f$', w_I_star), ...
            sprintf('$w_{I,hh}^* = %.4f$', w_I_household_star), ...
            sprintf('$\\Pi_{lump} = %.4f$', Pi_lump_star), ...
            sprintf('$L_F^* = %.4f$', L_F_star), ...
            sprintf('$L_I^* = %.4f$', L_I_star), ...
            sprintf('rule: %s', informal_profit_rule), ...
            sprintf('$\\tau  = %.2f$',  tau), ...
            sprintf('$\\beta_I = %.2f$', beta_I)}, ...
        'Interpreter', 'latex', 'FontSize', 10, ...
        'BackgroundColor', [0.97 0.97 0.97], 'EdgeColor', [0.6 0.6 0.6])

    xlabel('Capital $K$',      'FontSize', 14, 'Interpreter', 'latex')
    ylabel('Interest rate $r$', 'FontSize', 14, 'Interpreter', 'latex')
    title(sprintf('General Equilibrium ($\\tau=%.2f$, $\\beta_I=%.2f$)', tau, beta_I), ...
        'FontSize', 14, 'Interpreter', 'latex')
    legend('Location', 'NorthEast', 'Interpreter', 'latex', 'FontSize', 10)
    xlim([0 xmax]); ylim([-d*1.2 rho*1.1])
    set(gca, 'FontSize', 12)
    save_png(fig6, fullfile(output_dir, 'equilibrium_general.png'), 300)
end

% -------------------------------------------------------------------------
% FIGURE 7: INCOME DECOMPOSITION
% -------------------------------------------------------------------------
income_formal   = ((1-tau)*w_F * zz - kappa_F_aa) .* ell_F;          % ingreso formal neto de impuesto y costo formal
income_informal = omega_I * theta * zz .* qq_informal .* ell_I;      % ingreso informal, incluyendo q si existe
income_transfer = T_eq * ones(I,Ns);                                  % transferencia lump-sum T_tax
income_assets   = r_eq * aa;                                          % ingreso de activos

figure('Position', [100, 100, 800, 500])
subplot(1,2,1)
yyaxis left
plot(a, income_formal(:,1),   'b-',  'LineWidth', 2)
hold on
plot(a, income_informal(:,1), 'r--', 'LineWidth', 2)
plot(a, income_transfer(:,1), 'm-.', 'LineWidth', 2)
ylim([0 1.10*max([income_formal(1:idx_max,1); income_informal(1:idx_max,1); income_transfer(1:idx_max,1); 1e-8])])
yyaxis right
plot(a, income_assets(:,1),   'k:',  'LineWidth', 2)
y_asset_1 = income_assets(1:idx_max,1);
y_asset_min_1 = min([y_asset_1; 0]);
y_asset_max_1 = max([y_asset_1; 0]);
if y_asset_min_1 == y_asset_max_1
    y_asset_min_1 = y_asset_min_1 - 1e-3;
    y_asset_max_1 = y_asset_max_1 + 1e-3;
end
ylim([1.10*y_asset_min_1 1.10*y_asset_max_1])
legend('$(1-\tau)w_Fz\ell_F-\kappa_F(a)\ell_F$', '$\omega_I\theta zq\ell_I$', '$T_{tax}$', '$ra$', ...
    'Interpreter', 'latex', 'Location', 'best')
xlabel('Wealth, $a$', 'FontSize', 12, 'Interpreter', 'latex')
ylabel('Labor income / transfers', 'FontSize', 12)
yyaxis right
ylabel('Asset income $ra$', 'FontSize', 12, 'Interpreter', 'latex')
title('After-tax Income by Source (Low Prod.)', 'FontSize', 13)
xlim([amin_plot amax_plot]); grid on

subplot(1,2,2)
yyaxis left
plot(a, income_formal(:,2),   'b-',  'LineWidth', 2)
hold on
plot(a, income_informal(:,2), 'r--', 'LineWidth', 2)
plot(a, income_transfer(:,2), 'm-.', 'LineWidth', 2)
ylim([0 1.10*max([income_formal(1:idx_max,2); income_informal(1:idx_max,2); income_transfer(1:idx_max,2); 1e-8])])
yyaxis right
plot(a, income_assets(:,2),   'k:',  'LineWidth', 2)
y_asset_2 = income_assets(1:idx_max,2);
y_asset_min_2 = min([y_asset_2; 0]);
y_asset_max_2 = max([y_asset_2; 0]);
if y_asset_min_2 == y_asset_max_2
    y_asset_min_2 = y_asset_min_2 - 1e-3;
    y_asset_max_2 = y_asset_max_2 + 1e-3;
end
ylim([1.10*y_asset_min_2 1.10*y_asset_max_2])
legend('Formal net', 'Informal', 'Transfer', 'Assets', 'Location', 'best')
xlabel('Wealth, $a$', 'FontSize', 12, 'Interpreter', 'latex')
ylabel('Labor income / transfers', 'FontSize', 12)
yyaxis right
ylabel('Asset income $ra$', 'FontSize', 12, 'Interpreter', 'latex')
title('After-tax Income by Source (High Prod.)', 'FontSize', 13)
xlim([amin_plot amax_plot]); grid on
save_png(gcf, fullfile(output_dir, 'income_decomposition.png'), 300)

% -------------------------------------------------------------------------
% FIGURE 8: GOVERNMENT VARIABLES
% -------------------------------------------------------------------------
if EQUILIBRIUM_MODE == 2
    figure('Position', [100, 100, 600, 500])
    gov_vals   = [tax_rev, profit_I_star, Y_F, Y_I];
    gov_labels = {'\tau w_F L_F', '\pi_I (DRS)', 'Y_F', 'Y_I'};
    gov_colors = [0.8500 0.3250 0.0980; 0.4660 0.6740 0.1880; ...
                  0 0.4470 0.7410; 0.4940 0.1840 0.5560];
    bh2 = bar(1:4, gov_vals, 0.6, 'FaceColor', 'flat');
    for k = 1:4, bh2.CData(k,:) = gov_colors(k,:); end
    set(gca, 'XTickLabel', gov_labels, 'FontSize', 12)
    ylabel('Value', 'FontSize', 14)
    title(sprintf('Government Variables ($\\tau=%.2f$)', tau), ...
        'FontSize', 14, 'Interpreter', 'latex')
    for k = 1:4
        text(k, gov_vals(k) + max(gov_vals)*0.02, sprintf('%.4f', gov_vals(k)), ...
            'HorizontalAlignment', 'center', 'FontSize', 10)
    end
    grid on
    save_png(gcf, fullfile(output_dir, 'government_variables.png'), 300)
end

% -------------------------------------------------------------------------
% FIGURE 9: LABOR DENSITY g(a,z)*ell_j(a,z)
% -------------------------------------------------------------------------
if EQUILIBRIUM_MODE == 2
    ld_F = g .* ell_F;
    ld_I = g .* ell_I;
    ld_F_z1 = sum(ld_F(:, idx_z1), 2);
    ld_F_z2 = sum(ld_F(:, idx_z2), 2);
    ld_I_z1 = sum(ld_I(:, idx_z1), 2);
    ld_I_z2 = sum(ld_I(:, idx_z2), 2);

    fig9 = figure('Color', 'white', 'Position', [100 100 1000 420]);

    subplot(1,2,1); hold on; box on; grid on
    plot(a, ld_F_z1, 'b-',  'LineWidth', 2.2, 'DisplayName', 'z1, agregado sobre q')
    plot(a, ld_F_z2, 'b--', 'LineWidth', 2.2, 'DisplayName', 'z2, agregado sobre q')
    xlabel('Wealth $a$', 'FontSize', 13, 'Interpreter', 'latex')
    ylabel('$g(a,z)\,\ell_F(a,z)$', 'FontSize', 13, 'Interpreter', 'latex')
    title('Formal labor density', 'FontSize', 13)
    legend('Interpreter', 'none', 'Location', 'NorthEast', 'FontSize', 10)
    xlim([amin_plot 2]); ylim([0 inf])

    subplot(1,2,2); hold on; box on; grid on
    plot(a, ld_I_z1, 'r-',  'LineWidth', 2.2, 'DisplayName', 'z1, agregado sobre q')
    plot(a, ld_I_z2, 'r--', 'LineWidth', 2.2, 'DisplayName', 'z2, agregado sobre q')
    xlabel('Wealth $a$', 'FontSize', 13, 'Interpreter', 'latex')
    ylabel('$g(a,z)\,\ell_I(a,z)$', 'FontSize', 13, 'Interpreter', 'latex')
    title('Informal labor density', 'FontSize', 13)
    legend('Interpreter', 'none', 'Location', 'NorthEast', 'FontSize', 10)
    xlim([amin_plot 2]); ylim([0 inf])

    sgtitle(sprintf('Labor density by sector ($\\tau=%.2f$, $\\beta_I=%.2f$)', tau, beta_I), ...
        'FontSize', 13, 'FontWeight', 'bold', 'Interpreter', 'latex')
    save_png(fig9, fullfile(output_dir, 'labor_density.png'), 300)
    fprintf('Figure labor_density saved.\n')
end

% =========================================================================
% FIGURES 10-12: HETEROGENEIDAD POR TIPO DE PRODUCTIVIDAD (z1 vs z2)
%   La unica heterogeneidad genuina en este modelo es z1 vs z2.
    %   Con un solo shock z y theta comun, ell_F(a,z) puede seguir siendo casi plana
%   para todo a dentro de cada z — el hallazgo en si mismo.
%   Fig 10: Distribucion de riqueza  — g(a|z1) vs g(a|z2)
%   Fig 11: Consumo vs riqueza      — c(a,z1) vs c(a,z2)
%   Fig 12: Asignacion de horas     — ell_F(a,z1) vs ell_F(a,z2) (casi constante)
% =========================================================================
if EQUILIBRIUM_MODE == 2

    % Distribution-based zoom instead of grid-based zoom.
    a95 = a95_plot;

    % Colores: z1=naranja/informal, z2=azul/formal
    c_z1 = [0.85 0.33 0.10];
    c_z2 = [0.00 0.45 0.74];

    if ~exist('zdiag', 'var') && exist('calib_peru_v9_3_consumo_FI.mat', 'file')
        calib_file = load('calib_peru_v9_3_consumo_FI.mat', 'zdiag');
        if isfield(calib_file, 'zdiag')
            zdiag = calib_file.zdiag;
        end
    end
    if exist('zdiag', 'var')
        mean_rhs_z1  = zdiag.mean_rhs_z1;
        mean_rhs_z2  = zdiag.mean_rhs_z2;
        ellF_rhs0    = zdiag.ellF_rhs0;
    else
        mean_rhs_z1 = NaN;
        mean_rhs_z2 = NaN;
        ellF_rhs0 = NaN;
    end
    mass_z1      = mass_z1_plot;
    mass_z2      = mass_z2_plot;
    mean_a_z1    = mean_a_z1_plot;
    mean_a_z2    = mean_a_z2_plot;
    med_a_z1     = med_a_z1_plot;
    med_a_z2     = med_a_z2_plot;
    mean_c_z1    = mean_c_z1_plot;
    mean_c_z2    = mean_c_z2_plot;
    mean_ellF_z1 = mean_ellF_z1_plot;
    mean_ellF_z2 = mean_ellF_z2_plot;
    mean_ellI_z1 = mean_ellI_z1_plot;
    mean_ellI_z2 = mean_ellI_z2_plot;
    max_gap_ellF = max(abs(ellF_z1_curve - ellF_z2_curve));
    if ~exist('ext_inf_aa', 'var')
        ext_inf_aa = double(ell_I > ell_F);
    end

    % ------------------------------------------------------------------
    % FIGURE 10: Distribucion de RIQUEZA — g(a|z1) vs g(a|z2)
    %   Muestra como difieren los hogares de baja y alta productividad
    %   en terminos de acumulacion de riqueza
    % ------------------------------------------------------------------
    fig10 = figure('Color','white','Position',[100 100 900 480]);

    subplot(1,2,1)
    hold on; box on; grid on
    % Densidades condicionales normalizadas (area = 1 para cada z)
    z_lbl1 = sprintf('Baja productividad (z=%.2f)', z1_val);
    z_lbl2 = sprintf('Alta productividad (z=%.2f)', z2_val);
    plot(a, g_z1/mass_z1, '-',  'Color', c_z1, 'LineWidth', 2.5, 'DisplayName', z_lbl1)
    plot(a, g_z2/mass_z2, '--', 'Color', c_z2, 'LineWidth', 2.5, 'DisplayName', z_lbl2)
    % Solo una línea vertical por tipo (media) — sin congestión
    xline(mean_a_z1, ':', 'Color', c_z1, 'LineWidth', 1.8, 'HandleVisibility','off')
    xline(mean_a_z2, ':', 'Color', c_z2, 'LineWidth', 1.8, 'HandleVisibility','off')
    ylim_top = max([max(g_z1/mass_z1), max(g_z2/mass_z2)]) * 1.12;
    text(mean_a_z1 + 0.05, ylim_top*0.72, sprintf('media z_bajo = %.3f', mean_a_z1), ...
        'Color', c_z1, 'FontSize', 10, 'Interpreter', 'none')
    text(mean_a_z2 + 0.05, ylim_top*0.55, sprintf('media z_alto = %.3f', mean_a_z2), ...
        'Color', c_z2, 'FontSize', 10, 'Interpreter', 'none')
    xlabel('Riqueza neta a', 'FontSize',13,'Interpreter','none')
    ylabel('Densidad condicional g(a|z)', 'FontSize',12,'Interpreter','none')
    title('Distribucion de riqueza por tipo de productividad', 'FontSize',12,'Interpreter','none')
    legend('Interpreter','none','Location','NorthEast','FontSize',10)
    xlim([amin_plot a95])

    subplot(1,2,2)
    hold on; box on; grid on
    cdf_z1 = cumsum(g_z1) * da / mass_z1;
    cdf_z2 = cumsum(g_z2) * da / mass_z2;
    plot(a, cdf_z1, '-',  'Color', c_z1, 'LineWidth', 2.5, ...
        'DisplayName', sprintf('Baja productividad (z=%.2f)', z1_val))
    plot(a, cdf_z2, '--', 'Color', c_z2, 'LineWidth', 2.5, ...
        'DisplayName', sprintf('Alta productividad (z=%.2f)', z2_val))
    % Medias como lineas verticales
    xline(mean_a_z1, ':', 'Color', c_z1, 'LineWidth', 1.6, 'HandleVisibility','off')
    xline(mean_a_z2, ':', 'Color', c_z2, 'LineWidth', 1.6, 'HandleVisibility','off')
    xlabel('Riqueza a', 'FontSize',13,'Interpreter','none')
    ylabel('Probabilidad acumulada', 'FontSize',12,'Interpreter','none')
    title('CDF de riqueza: z_bajo a la izquierda = menos riqueza', 'FontSize',11,'Interpreter','none')
    legend('Interpreter','none','Location','SouthEast','FontSize',10)
    xlim([amin_plot a95])

    sgtitle(sprintf('Heterogeneidad patrimonial: baja productividad acumula menos riqueza\nmedia activos z_bajo=%.3f  vs  z_alto=%.3f', ...
        mean_a_z1, mean_a_z2), 'FontSize',12,'Interpreter','none')
    save_png(fig10, fullfile(output_dir, 'wealth_by_ztype.png'), 300)
    fprintf('Figure wealth_by_ztype saved.\n')

    % ------------------------------------------------------------------
    % FIGURE 11: CONSUMO — c(a,z1) vs c(a,z2)
    %   Panel izquierdo: politica de consumo c(a,z) — dos curvas
    %   Panel derecho:   distribucion de consumo g(a,z)*c(a,z)
    % ------------------------------------------------------------------
    fig11 = figure('Color','white','Position',[100 100 900 480]);

    subplot(1,2,1)
    hold on; box on; grid on
    plot(a, c_z1_curve, '-',  'Color', c_z1, 'LineWidth', 2.5, ...
        'DisplayName', 'c(a,z1), agregado sobre q')
    plot(a, c_z2_curve, '--', 'Color', c_z2, 'LineWidth', 2.5, ...
        'DisplayName', 'c(a,z2), agregado sobre q')
    % Lineas de consumo medio
    yline(mean_c_z1, ':', 'Color', c_z1, 'LineWidth', 1.5, 'HandleVisibility','off')
    yline(mean_c_z2, ':', 'Color', c_z2, 'LineWidth', 1.5, 'HandleVisibility','off')
    text(a95*0.6, mean_c_z1*0.97, sprintf('mean c(z1)=%.4f', mean_c_z1), ...
        'Color', c_z1, 'FontSize', 9, 'Interpreter', 'none')
    text(a95*0.6, mean_c_z2*1.01, sprintf('mean c(z2)=%.4f', mean_c_z2), ...
        'Color', c_z2, 'FontSize', 9, 'Interpreter', 'none')
    xlabel('Riqueza a', 'FontSize',13,'Interpreter','none')
    ylabel('Consumo c(a,z)', 'FontSize',12,'Interpreter','none')
    title('Politica de consumo por tipo', 'FontSize',12)
    legend('Interpreter','none','Location','SouthEast','FontSize',10)
    xlim([amin_plot a95])

    subplot(1,2,2)
    hold on; box on; grid on
    % Densidad de consumo: g(a,z) pesado por c(a,z), normalizado
    gc_z1 = sum(g(:,idx_z1) .* c(:,idx_z1), 2);
    gc_z2 = sum(g(:,idx_z2) .* c(:,idx_z2), 2);
    gc_z1 = gc_z1 / (da * sum(gc_z1));
    gc_z2 = gc_z2 / (da * sum(gc_z2));
    plot(a, gc_z1, '-',  'Color', c_z1, 'LineWidth', 2.5, ...
        'DisplayName', sprintf('Baja prod. z=%.2f (donde consume)', z1_val))
    plot(a, gc_z2, '--', 'Color', c_z2, 'LineWidth', 2.5, ...
        'DisplayName', sprintf('Alta prod. z=%.2f (donde consume)', z2_val))
    xlabel('Riqueza a', 'FontSize',13,'Interpreter','none')
    ylabel('Densidad g(a,z) x consumo — area=1 por tipo', 'FontSize',10)
    title('Concentracion del consumo por riqueza y productividad', 'FontSize',11)
    legend('Interpreter','none','Location','NorthEast','FontSize',9)
    xlim([amin_plot a95])

    sgtitle(sprintf(['Consumo: productividad baja z1 vs alta z2 (agregado sobre q)' ...
        '\ntau=%.2f, beta_I=%.2f'], tau, beta_I), ...
        'FontSize',12,'Interpreter','none')
    save_png(fig11, fullfile(output_dir, 'consumption_by_ztype.png'), 300)
    fprintf('Figure consumption_by_ztype saved.\n')

    % ------------------------------------------------------------------
    % FIGURE 11b: COMPONENTES DE CONSUMO POR z ACTUAL
    %   c_F y c_I son cantidades fisicas; p_I*c_I y el share informal
    %   son objetos de gasto observables en unidades del bien formal.
    % ------------------------------------------------------------------
    fig11b = figure('Color','white','Position',[100 100 1200 420]);

    subplot(1,3,1)
    hold on; box on; grid on
    plot(a, cF_z1_curve, '-',  'Color', c_z1, 'LineWidth', 2.4, ...
        'DisplayName', sprintf('z actual bajo=%.2f', z1_val))
    plot(a, cF_z2_curve, '--', 'Color', c_z2, 'LineWidth', 2.4, ...
        'DisplayName', sprintf('z actual alto=%.2f', z2_val))
    yline(mean_cF_z1_plot, ':', 'Color', c_z1, 'LineWidth', 1.2, 'HandleVisibility','off')
    yline(mean_cF_z2_plot, ':', 'Color', c_z2, 'LineWidth', 1.2, 'HandleVisibility','off')
    xlabel('Riqueza actual a', 'FontSize',12,'Interpreter','none')
    ylabel('Consumo formal c_F(a,z)', 'FontSize',11,'Interpreter','none')
    title('Bien formal', 'FontSize',12,'Interpreter','none')
    legend('Interpreter','none','Location','SouthEast','FontSize',9)
    xlim([amin_plot a95])

    subplot(1,3,2)
    hold on; box on; grid on
    plot(a, cI_z1_curve, '-',  'Color', c_z1, 'LineWidth', 2.4, ...
        'DisplayName', sprintf('z actual bajo=%.2f', z1_val))
    plot(a, cI_z2_curve, '--', 'Color', c_z2, 'LineWidth', 2.4, ...
        'DisplayName', sprintf('z actual alto=%.2f', z2_val))
    yline(mean_cI_z1_plot, ':', 'Color', c_z1, 'LineWidth', 1.2, 'HandleVisibility','off')
    yline(mean_cI_z2_plot, ':', 'Color', c_z2, 'LineWidth', 1.2, 'HandleVisibility','off')
    xlabel('Riqueza actual a', 'FontSize',12,'Interpreter','none')
    ylabel('Consumo informal c_I(a,z)', 'FontSize',11,'Interpreter','none')
    title('Bien informal', 'FontSize',12,'Interpreter','none')
    legend('Interpreter','none','Location','SouthEast','FontSize',9)
    xlim([amin_plot a95])

    subplot(1,3,3)
    hold on; box on; grid on
    plot(a, share_pIcI_z1_curve, '-',  'Color', c_z1, 'LineWidth', 2.4, ...
        'DisplayName', sprintf('z actual bajo=%.2f', z1_val))
    plot(a, share_pIcI_z2_curve, '--', 'Color', c_z2, 'LineWidth', 2.4, ...
        'DisplayName', sprintf('z actual alto=%.2f', z2_val))
    yline(mean_share_pIcI_z1_plot, ':', 'Color', c_z1, 'LineWidth', 1.2, 'HandleVisibility','off')
    yline(mean_share_pIcI_z2_plot, ':', 'Color', c_z2, 'LineWidth', 1.2, 'HandleVisibility','off')
    xlabel('Riqueza actual a', 'FontSize',12,'Interpreter','none')
    ylabel('Share gasto informal p_I c_I/(c_F+p_I c_I)', 'FontSize',10,'Interpreter','none')
    title('Composicion del gasto', 'FontSize',12,'Interpreter','none')
    legend('Interpreter','none','Location','best','FontSize',9)
    xlim([amin_plot a95])
    ylim([0, min(1, 1.05*max([share_pIcI_z1_curve(:); share_pIcI_z2_curve(:)]))])

    sgtitle(sprintf(['Componentes de consumo condicionales al estado actual z' ...
        '\nMedias: c_F(z1)=%.4f, c_F(z2)=%.4f; c_I(z1)=%.4f, c_I(z2)=%.4f; p_I=%.4f'], ...
        mean_cF_z1_plot, mean_cF_z2_plot, mean_cI_z1_plot, mean_cI_z2_plot, p_I), ...
        'FontSize',12,'Interpreter','none')
    save_png(fig11b, fullfile(output_dir, 'consumption_components_by_ztype.png'), 300)
    fprintf('Figure consumption_components_by_ztype saved.\n')

    % ------------------------------------------------------------------
    % FIGURE 12: ASIGNACION DE HORAS — ell_F(a,z1) vs ell_F(a,z2)
    %   Hallazgo: ell_F es casi constante en a y casi identico entre z1 y z2.
    %   Esto es una prediccion del modelo intensivo actual,
    %   no un bug del grafico ni del solver.
    % ------------------------------------------------------------------
    fig12 = figure('Color','white','Position',[100 100 1000 440]);

    subplot(1,3,1)
    hold on; box on; grid on
    plot(a, ellF_z1_curve, '-',  'Color', c_z1, 'LineWidth', 2.5, ...
        'DisplayName', sprintf('ell_F(a,z1), z1=%.1f', z1_val))
    plot(a, ellF_z2_curve, '--', 'Color', c_z2, 'LineWidth', 2.5, ...
        'DisplayName', sprintf('ell_F(a,z2), z2=%.1f', z2_val))
    yline(mean_ellF_z1, ':', 'Color', c_z1, 'LineWidth',1.5, 'HandleVisibility','off')
    yline(mean_ellF_z2, ':', 'Color', c_z2, 'LineWidth',1.5, 'HandleVisibility','off')
    text(a95*0.55, mean_ellF_z1*0.92, sprintf('mean ell_F(z1)=%.3f', mean_ellF_z1), ...
        'Color',c_z1,'FontSize',9,'Interpreter','none')
    text(a95*0.55, mean_ellF_z2*1.04, sprintf('mean ell_F(z2)=%.3f', mean_ellF_z2), ...
        'Color',c_z2,'FontSize',9,'Interpreter','none')
    xlabel('Riqueza a', 'FontSize',13,'Interpreter','none')
    ylabel('Horas formales ell_F(a,z)', 'FontSize',12,'Interpreter','none')
    title('Horas formales vs. riqueza', 'FontSize',12)
    legend('Interpreter','none','Location','best','FontSize',10)
    xlim([amin_plot a95]); ylim([0 max(1, 1.05*max([ell_F(:,1); ell_F(:,2); ell_I(:,1); ell_I(:,2)]))])

    subplot(1,3,2)
    hold on; box on; grid on
    plot(a, ellI_z1_curve, '-',  'Color', c_z1, 'LineWidth', 2.5, ...
        'DisplayName', 'ell_I(a,z1)')
    plot(a, ellI_z2_curve, '--', 'Color', c_z2, 'LineWidth', 2.5, ...
        'DisplayName', 'ell_I(a,z2)')
    xlabel('Riqueza a', 'FontSize',13,'Interpreter','none')
    ylabel('Horas informales ell_I(a,z)', 'FontSize',12,'Interpreter','none')
    title('Horas informales vs. riqueza', 'FontSize',12)
    legend('Interpreter','none','Location','best','FontSize',10)
    xlim([amin_plot a95]); ylim([0 max(1, 1.05*max([ell_F(:,1); ell_F(:,2); ell_I(:,1); ell_I(:,2)]))])

    subplot(1,3,3)
    hold on; box on; grid on
    % Ratio ell_F/ell_I por z-state — muestra si la proporcion varia con a
    ratio_z1 = ellF_z1_curve ./ max(ellI_z1_curve, 1e-8);
    ratio_z2 = ellF_z2_curve ./ max(ellI_z2_curve, 1e-8);
    plot(a, ratio_z1, '-',  'Color', c_z1, 'LineWidth', 2.5, ...
        'DisplayName', 'ell_F/ell_I (z1)')
    plot(a, ratio_z2, '--', 'Color', c_z2, 'LineWidth', 2.5, ...
        'DisplayName', 'ell_F/ell_I (z2)')
    xlabel('Riqueza a', 'FontSize',13,'Interpreter','none')
    ylabel('Ratio ell_F/ell_I', 'FontSize',12,'Interpreter','none')
    title('Ratio formal/informal vs. riqueza', 'FontSize',12)
    legend('Interpreter','none','Location','best','FontSize',10)
    xlim([amin_plot a95])

    sgtitle(sprintf(['Asignacion sectorial: heterogeneidad por productividad z (agregada sobre q)' ...
        '\nRHS medio FOC: z1=%.2f, z2=%.2f, ell_F(RHS=0)=%.4f'], ...
        mean_rhs_z1, mean_rhs_z2, ellF_rhs0), 'FontSize',12,'Interpreter','none')
    save_png(fig12, fullfile(output_dir, 'labor_allocation_by_ztype.png'), 300)
    fprintf('Figure labor_allocation_by_ztype saved.\n')

    % ------------------------------------------------------------------
    % FIGURA: PRODUCTIVIDAD EXOGENA z vs HORAS (recomendacion asesor)
    %   "Enfocarse en la relacion entre la productividad (exogena) z
    %    y las horas trabajadas" — no en riqueza (endogena) vs horas.
    %   Con 2 estados z, esta figura muestra E[ell_F|z] y E[ell_I|z]
    %   para cada tipo, permitiendo ver si mayor z implica mas/menos
    %   horas en cada sector.
    % ------------------------------------------------------------------
    fig_z_hrs = figure('Color','white','Position',[100 100 640 490]);

    z_vals     = [z1_val, z2_val];
    ellF_by_z  = [mean_ellF_z1, mean_ellF_z2];
    ellI_by_z  = [mean_ellI_z1, mean_ellI_z2];
    ellT_by_z  = ellF_by_z + ellI_by_z;

    % Ocio = H_bar - ell_F - ell_I  (tiempo no trabajado — resultado interior FOC)
    ocio_by_z = max(H_bar - ellF_by_z - ellI_by_z, 0);

    ax1 = subplot(1,2,1);
    hold on; box on; grid on
    b = bar(1:2, [ellF_by_z; ellI_by_z; ocio_by_z]', 'stacked');
    b(1).FaceColor = [0.20 0.45 0.78];   % azul — formal
    b(2).FaceColor = [0.85 0.33 0.10];   % naranja — informal
    b(3).FaceColor = [0.75 0.75 0.75];   % gris — ocio
    b(1).FaceAlpha = 0.90; b(2).FaceAlpha = 0.90; b(3).FaceAlpha = 0.70;
    yline(H_bar, ':k', 'LineWidth', 1.2, 'HandleVisibility','off')
    set(gca, 'XTick', 1:2, 'XTickLabel', ...
        {sprintf('z_{bajo}=%.2f', z1_val), sprintf('z_{alto}=%.2f', z2_val)}, ...
        'TickLabelInterpreter','tex', 'FontSize', 11)
    ylabel('Horas (fracción de H_{bar}=1)', 'FontSize', 12, 'Interpreter', 'tex')
    xlabel('Productividad exógena z', 'FontSize', 12, 'Interpreter', 'none')
    title('Uso del tiempo por tipo z', 'FontSize', 12, 'Interpreter', 'none')
    % Etiquetas numéricas en segmentos
    xlabs = [1 2]; ybase = [0 0];
    for ig = 1:2
        vals3 = [ellF_by_z(ig), ellI_by_z(ig), ocio_by_z(ig)];
        for ib = 1:3
            if vals3(ib) > 0.02
                text(xlabs(ig), ybase(ig) + vals3(ib)/2, sprintf('%.2f', vals3(ib)), ...
                    'HorizontalAlignment','center','FontSize',9,'Interpreter','none','FontWeight','bold')
            end
            ybase(ig) = ybase(ig) + vals3(ib);
        end
    end
    ylim([0 H_bar*1.08])

    ax2 = subplot(1,2,2);
    hold on; box on; grid on
    % Panel derecho: fracción de horas TRABAJADAS (excluye ocio)
    share_F_by_z = ellF_by_z ./ max(ellT_by_z, 1e-12);
    share_I_by_z = ellI_by_z ./ max(ellT_by_z, 1e-12);
    b2 = bar(1:2, [share_F_by_z; share_I_by_z]', 'stacked');
    b2(1).FaceColor = [0.20 0.45 0.78];
    b2(2).FaceColor = [0.85 0.33 0.10];
    b2(1).FaceAlpha = 0.90; b2(2).FaceAlpha = 0.90;
    set(gca, 'XTick', 1:2, 'XTickLabel', ...
        {sprintf('z_{bajo}=%.2f', z1_val), sprintf('z_{alto}=%.2f', z2_val)}, ...
        'TickLabelInterpreter','tex', 'FontSize', 11)
    h_t4 = yline(T4_plt, '--k', 'LineWidth', 1.2, 'DisplayName', sprintf('Meta T4=%.0f%% (INEI)', T4_plt*100));
    ylabel('Fracción de horas trabajadas', 'FontSize', 12, 'Interpreter', 'none')
    xlabel('Productividad exógena z', 'FontSize', 12, 'Interpreter', 'none')
    title({'Composición sectorial','(excluye ocio)'},'FontSize',12,'Interpreter','none')
    ylim([0 1.05])

    sgtitle(sprintf('Asignación del tiempo por productividad z  |  z_{bajo}: %.0f%% ocio, %.0f%% informal  |  z_{alto}: %.0f%% ocio, %.0f%% informal', ...
        ocio_by_z(1)*100, ellI_by_z(1)*100, ocio_by_z(2)*100, ellI_by_z(2)*100), ...
        'FontSize', 11, 'Interpreter', 'tex')

    % Subir ambos paneles para dejar espacio al pie para la leyenda
    drawnow;
    for ax_tmp = [ax1, ax2]
        p = get(ax_tmp, 'Position');
        set(ax_tmp, 'Position', [p(1), p(2)+0.10, p(3), p(4)-0.10]);
    end

    % Leyenda compartida horizontal debajo de ambos paneles
    lgnd_shared = legend(ax1, [b(1), b(2), b(3), h_t4], ...
        {'Formal', 'Informal', 'Ocio (n=H-\ell_F-\ell_I)', ...
         sprintf('Meta T4=%.0f%% (INEI)', T4_plt*100)}, ...
        'Orientation', 'horizontal', 'Interpreter', 'tex', 'FontSize', 10);
    drawnow;
    lgnd_shared.Position = [0.05, 0.02, 0.90, 0.07];

    save_png(fig_z_hrs, fullfile(output_dir, 'hours_by_ztype.png'), 300)
    fprintf('Figure hours_by_ztype (z vs horas, recomendacion asesor) saved.\n')

    % ------------------------------------------------------------------
    % TABLA RESUMEN: heterogeneidad por cuartil de riqueza
    % ------------------------------------------------------------------
    % Medias de ell_F y ell_I por cuartil
    mean_ellF_Q1 = da * sum(sum(g_Q1 .* ell_F)) / max(mass_Q1,1e-12);
    mean_ellF_Q4 = da * sum(sum(g_Q4 .* ell_F)) / max(mass_Q4,1e-12);
    mean_ellI_Q1 = da * sum(sum(g_Q1 .* ell_I)) / max(mass_Q1,1e-12);
    mean_ellI_Q4 = da * sum(sum(g_Q4 .* ell_I)) / max(mass_Q4,1e-12);
    mean_exp_Q1  = da * sum(sum(g_Q1 .* cons_exp)) / max(mass_Q1,1e-12);
    mean_exp_Q4  = da * sum(sum(g_Q4 .* cons_exp)) / max(mass_Q4,1e-12);
    mean_pIcI_Q1 = da * sum(sum(g_Q1 .* (p_I*c_I))) / max(mass_Q1,1e-12);
    mean_pIcI_Q4 = da * sum(sum(g_Q4 .* (p_I*c_I))) / max(mass_Q4,1e-12);
    T4ext_Q1     = da * sum(sum(g_Q1 .* ext_inf_aa)) / max(mass_Q1,1e-12);
    T4ext_Q4     = da * sum(sum(g_Q4 .* ext_inf_aa)) / max(mass_Q4,1e-12);
    shareI_Q1    = mean_ellI_Q1 / max(mean_ellF_Q1 + mean_ellI_Q1, 1e-12);
    shareI_Q4    = mean_ellI_Q4 / max(mean_ellF_Q4 + mean_ellI_Q4, 1e-12);

    w_Q1_tbl = da * g_Q1(:);
    w_Q4_tbl = da * g_Q4(:);
    med_a_Q1      = weighted_median(aa(:), w_Q1_tbl);
    med_a_Q4      = weighted_median(aa(:), w_Q4_tbl);
    med_ceff_Q1   = weighted_median(c(:), w_Q1_tbl);
    med_ceff_Q4   = weighted_median(c(:), w_Q4_tbl);
    med_exp_Q1    = weighted_median(cons_exp(:), w_Q1_tbl);
    med_exp_Q4    = weighted_median(cons_exp(:), w_Q4_tbl);
    med_cF_Q1     = weighted_median(c_F(:), w_Q1_tbl);
    med_cF_Q4     = weighted_median(c_F(:), w_Q4_tbl);
    med_cI_Q1     = weighted_median(c_I(:), w_Q1_tbl);
    med_cI_Q4     = weighted_median(c_I(:), w_Q4_tbl);
    med_pIcI_Q1   = weighted_median((p_I*c_I(:)), w_Q1_tbl);
    med_pIcI_Q4   = weighted_median((p_I*c_I(:)), w_Q4_tbl);
    med_ellF_Q1   = weighted_median(ell_F(:), w_Q1_tbl);
    med_ellF_Q4   = weighted_median(ell_F(:), w_Q4_tbl);
    med_ellI_Q1   = weighted_median(ell_I(:), w_Q1_tbl);
    med_ellI_Q4   = weighted_median(ell_I(:), w_Q4_tbl);

    fprintf('\n========================================\n')
    fprintf('TABLA: Heterogeneidad por cuartil de riqueza\n')
    fprintf('========================================\n')
    fprintf('%-34s %10s %10s %10s %10s %10s\n', 'Variable', 'Q1 mean', 'Q1 med', 'Q4 mean', 'Q4 med', 'Ratio')
    fprintf('%-34s %10s %10s %10s %10s %10s\n', repmat('-',1,34), repmat('-',1,10), repmat('-',1,10), repmat('-',1,10), repmat('-',1,10), repmat('-',1,10))
    fprintf('%-34s %10.3f %10.3f %10.3f %10.3f %9.1fx\n', 'Riqueza a',                  mean_a_Q1,    med_a_Q1,    mean_a_Q4,    med_a_Q4,    mean_a_Q4/max(mean_a_Q1,1e-12))
    fprintf('%-34s %10.4f %10.4f %10.4f %10.4f %9.1fx\n', 'Gasto total cF+pI*cI',       mean_exp_Q1,  med_exp_Q1,  mean_exp_Q4,  med_exp_Q4,  mean_exp_Q4/max(mean_exp_Q1,1e-12))
    fprintf('%-34s %10.4f %10.4f %10.4f %10.4f %9.1fx\n', 'Indice CES C_eff',           mean_c_Q1,    med_ceff_Q1, mean_c_Q4,    med_ceff_Q4, mean_c_Q4/max(mean_c_Q1,1e-12))
    fprintf('%-34s %10.4f %10.4f %10.4f %10.4f %9.1fx\n', 'Consumo formal c_F',         mean_cF_Q1,   med_cF_Q1,   mean_cF_Q4,   med_cF_Q4,   mean_cF_Q4/max(mean_cF_Q1,1e-12))
    fprintf('%-34s %10.4f %10.4f %10.4f %10.4f %9.1fx\n', 'Consumo informal c_I',       mean_cI_Q1,   med_cI_Q1,   mean_cI_Q4,   med_cI_Q4,   mean_cI_Q4/max(mean_cI_Q1,1e-12))
    fprintf('%-34s %10.4f %10.4f %10.4f %10.4f %9.1fx\n', 'Gasto informal pI*c_I',      mean_pIcI_Q1, med_pIcI_Q1, mean_pIcI_Q4, med_pIcI_Q4, mean_pIcI_Q4/max(mean_pIcI_Q1,1e-12))
    fprintf('%-34s %10.4f %10.4f %10.4f %10.4f %9.1fx\n', 'Horas formales ell_F',       mean_ellF_Q1, med_ellF_Q1, mean_ellF_Q4, med_ellF_Q4, mean_ellF_Q4/max(mean_ellF_Q1,1e-12))
    fprintf('%-34s %10.4f %10.4f %10.4f %10.4f %9.1fx\n', 'Horas informales ell_I',     mean_ellI_Q1, med_ellI_Q1, mean_ellI_Q4, med_ellI_Q4, mean_ellI_Q4/max(mean_ellI_Q1,1e-12))
    fprintf('%-34s %10.4f %10s %10.4f %10s %9.1fx\n',     'Share horas informales',     shareI_Q1,    '---',       shareI_Q4,    '---',       shareI_Q4/max(shareI_Q1,1e-12))
    fprintf('%-34s %10.4f %10s %10.4f %10s %9.1fx\n',     'Informal ext. 1[ellI>ellF]', T4ext_Q1,     '---',       T4ext_Q4,     '---',       T4ext_Q4/max(T4ext_Q1,1e-12))
    fprintf('%-32s %10.4f %10.4f\n',          'Umbral riqueza (a)',        q25_a,        q75_a)
    fprintf('========================================\n\n')

    % ------------------------------------------------------------------
    % FIGURA TABLA PNG: heterogeneidad por cuartil de riqueza
    % ------------------------------------------------------------------
    tbl_vars  = {'Riqueza a'; 'Gasto total c_F+p_I c_I'; 'Indice CES C_{eff}'; ...
                 'Consumo formal c_F'; 'Consumo informal c_I'; 'Gasto informal p_I c_I'; ...
                 'Horas formales ell_F'; 'Horas informales ell_I'; 'Share horas informales'};
    tbl_Q1_mean = [mean_a_Q1;   mean_exp_Q1;  mean_c_Q1;   mean_cF_Q1;   mean_cI_Q1;   mean_pIcI_Q1; mean_ellF_Q1; mean_ellI_Q1; shareI_Q1];
    tbl_Q1_med  = [med_a_Q1;    med_exp_Q1;   med_ceff_Q1; med_cF_Q1;    med_cI_Q1;    med_pIcI_Q1;  med_ellF_Q1;  med_ellI_Q1;  NaN];
    tbl_Q4_mean = [mean_a_Q4;   mean_exp_Q4;  mean_c_Q4;   mean_cF_Q4;   mean_cI_Q4;   mean_pIcI_Q4; mean_ellF_Q4; mean_ellI_Q4; shareI_Q4];
    tbl_Q4_med  = [med_a_Q4;    med_exp_Q4;   med_ceff_Q4; med_cF_Q4;    med_cI_Q4;    med_pIcI_Q4;  med_ellF_Q4;  med_ellI_Q4;  NaN];
    tbl_ratio   = tbl_Q4_mean ./ max(tbl_Q1_mean, 1e-12);

    nrows = numel(tbl_vars);
    fig_tbl = figure('Color','white','Position',[100 100 980 430]);
    ax_tbl = axes('Position',[0 0 1 1],'Visible','off'); %#ok<NASGU>
    hold on

    % Colores de cabecera y filas alternadas
    col_hdr  = [0.20 0.33 0.55];   % azul oscuro
    col_row1 = [0.93 0.95 0.98];   % gris muy claro
    col_row2 = [1.00 1.00 1.00];   % blanco

    % Posiciones (normalized units)
    x0 = 0.03; xw = 0.97;
    col_x = [x0, x0+0.34, x0+0.47, x0+0.58, x0+0.71, x0+0.82, x0+0.93];
    row_h = 0.072;
    hdr_y = 0.82;

    % Cabecera
    rectangle('Position',[x0, hdr_y, xw-x0, row_h], ...
        'FaceColor', col_hdr, 'EdgeColor', 'none')
    hdrs = {'Variable', 'Q1 mean', 'Q1 med', 'Q4 mean', 'Q4 med', 'Ratio mean'};
    hdr_cx = [col_x(1)+0.16, col_x(2)+0.055, col_x(3)+0.050, col_x(4)+0.055, col_x(5)+0.050, col_x(6)+0.055];
    for h = 1:6
        text(hdr_cx(h), hdr_y + row_h*0.38, hdrs{h}, ...
            'Color','white','FontSize',9,'FontWeight','bold', ...
            'HorizontalAlignment','center','Units','normalized')
    end

    % Filas de datos
    fmt3 = '%.3f';
    fmt4 = '%.4f';
    fmts = {fmt3; fmt4; fmt4; fmt4; fmt4; fmt4; fmt4; fmt4; fmt4};
    for r = 1:nrows
        ry = hdr_y - r*row_h;
        fc = col_row1;
        if mod(r,2)==0, fc = col_row2; end
        rectangle('Position',[x0, ry, xw-x0, row_h], ...
            'FaceColor', fc, 'EdgeColor',[0.80 0.80 0.80], 'LineWidth', 0.5)
        % Variable name
        text(col_x(1)+0.005, ry+row_h*0.35, tbl_vars{r}, ...
            'FontSize', 8.6, 'Units','normalized', 'Interpreter','tex')
        text(hdr_cx(2), ry+row_h*0.35, sprintf(fmts{r}, tbl_Q1_mean(r)), ...
            'FontSize', 8.6, 'HorizontalAlignment','center','Units','normalized', ...
            'Color', [0.00 0.45 0.74])
        if isfinite(tbl_Q1_med(r))
            q1med_txt = sprintf(fmts{r}, tbl_Q1_med(r));
        else
            q1med_txt = '---';
        end
        text(hdr_cx(3), ry+row_h*0.35, q1med_txt, ...
            'FontSize', 8.6, 'HorizontalAlignment','center','Units','normalized', ...
            'Color', [0.00 0.45 0.74])
        text(hdr_cx(4), ry+row_h*0.35, sprintf(fmts{r}, tbl_Q4_mean(r)), ...
            'FontSize', 8.6, 'HorizontalAlignment','center','Units','normalized', ...
            'Color', [0.85 0.33 0.10])
        if isfinite(tbl_Q4_med(r))
            q4med_txt = sprintf(fmts{r}, tbl_Q4_med(r));
        else
            q4med_txt = '---';
        end
        text(hdr_cx(5), ry+row_h*0.35, q4med_txt, ...
            'FontSize', 8.6, 'HorizontalAlignment','center','Units','normalized', ...
            'Color', [0.85 0.33 0.10])
        text(hdr_cx(6), ry+row_h*0.35, sprintf('%.1fx', tbl_ratio(r)), ...
            'FontSize', 8.6, 'HorizontalAlignment','center','Units','normalized', ...
            'FontWeight','bold')
    end

    % Linea separadora final
    bot_y = hdr_y - nrows*row_h;
    line([x0, xw], [bot_y bot_y], 'Color',[0.5 0.5 0.5],'LineWidth',1)

    % Titulo y nota al pie
    text(0.5, hdr_y + row_h*1.35, ...
        sprintf('Heterogeneidad por cuartil de riqueza: media vs mediana  (r*=%.4f, \\tau=%.2f, \\beta_I=%.2f)', ...
        r_eq, tau, beta_I), ...
        'FontSize', 10, 'FontWeight','bold','HorizontalAlignment','center', ...
        'Units','normalized')
    text(0.5, bot_y - 0.09, ...
        sprintf('Q1: bottom 25%% de riqueza (a < %.3f). Q4: top 25%% (a > %.3f). C_eff es indice CES; gasto observado = c_F + p_I c_I.', ...
        q25_a, q75_a), ...
        'FontSize', 7.5, 'HorizontalAlignment','center','Color',[0.4 0.4 0.4], ...
        'Units','normalized')

    axis([0 1 0 1]); axis off
    save_png(fig_tbl, fullfile(output_dir, 'tabla_heterogeneidad.png'), 200)
    fprintf('Figure tabla_heterogeneidad saved.\n')

    % ------------------------------------------------------------------
    % FIGURE 13: TABLA VISUAL (barras) + CONSUMO POR HORAS FORMALES
    % ------------------------------------------------------------------
    c_Q1c = [0.00 0.45 0.74];
    c_Q4c = [0.85 0.33 0.10];

    % --- Corte por horas formales: mediana ponderada de ell_F ---
    % Calcula share formal = ell_F/(ell_F+ell_I) para cada estado (a,z,q)
    share_F = ell_F ./ max(ell_F + ell_I, 1e-8);  % fraccion de horas en formal
    share_F_vec = share_F(:);
    g_vec       = g(:);
    % Mediana ponderada de share_F
    [sf_sorted, sf_idx] = sort(share_F_vec);
    cdf_sf = cumsum(g_vec(sf_idx)) * da;
    med_shareF = sf_sorted(find(cdf_sf >= 0.5, 1, 'first'));

    % Mascaras: "mas formal" (share_F > mediana) y "mas informal" (share_F <= mediana)
    mask_hiF = (share_F > med_shareF);   % I x Ns
    mask_loF = ~mask_hiF;

    g_hiF = g .* mask_hiF;
    g_loF = g .* mask_loF;
    mass_hiF = da * sum(g_hiF(:));
    mass_loF = da * sum(g_loF(:));

    mean_c_hiF = da * sum(sum(g_hiF .* c)) / max(mass_hiF,1e-12);
    mean_c_loF = da * sum(sum(g_loF .* c)) / max(mass_loF,1e-12);
    mean_ellF_hiF = da * sum(sum(g_hiF .* ell_F)) / max(mass_hiF,1e-12);
    mean_ellF_loF = da * sum(sum(g_loF .* ell_F)) / max(mass_loF,1e-12);

    fprintf('--- Corte por horas formales (mediana share_F = %.4f) ---\n', med_shareF)
    fprintf('  Grupo "mas formal"  (share_F > %.4f): c_medio=%.4f, ell_F_medio=%.4f\n', med_shareF, mean_c_hiF, mean_ellF_hiF)
    fprintf('  Grupo "mas informal"(share_F <= %.4f): c_medio=%.4f, ell_F_medio=%.4f\n\n', med_shareF, mean_c_loF, mean_ellF_loF)

    fig13 = figure('Color','white','Position',[100 100 1100 480]);

    % --- Subplot 1: Grafico de barras resumen Q1 vs Q4 ---
    subplot(1,2,1)
    vars_lbl = {'Gasto total', 'Horas formales', 'Horas informales'};
    vals_Q1  = [mean_exp_Q1, mean_ellF_Q1, mean_ellI_Q1];
    vals_Q4  = [mean_exp_Q4, mean_ellF_Q4, mean_ellI_Q4];
    b = bar([vals_Q1; vals_Q4]', 'grouped');
    b(1).FaceColor = c_Q4c;   % naranja = Q4 ricos (primer grupo en legend)
    b(2).FaceColor = c_Q1c;   % azul = Q1 pobres
    % Reordenar para que Q1 sea primer grupo
    b(1).FaceColor = c_Q1c;
    b(2).FaceColor = c_Q4c;
    set(gca, 'XTickLabel', vars_lbl, 'FontSize', 11)
    ylabel('Valor medio', 'FontSize', 12)
    title('Q1 (pobres) vs Q4 (ricos)', 'FontSize', 12, 'FontWeight', 'bold')
    legend({'Q1 — pobres (bottom 25\%)', 'Q4 — ricos (top 25\%)'}, ...
        'Location', 'NorthEast', 'FontSize', 9, 'Interpreter', 'latex')
    grid on; box on

    % Anotar valores sobre las barras
    for k = 1:3
        text(k-0.15, vals_Q1(k)*1.04, sprintf('%.3f', vals_Q1(k)), ...
            'HorizontalAlignment','center','FontSize',8,'Color',c_Q1c)
        text(k+0.15, vals_Q4(k)*1.04, sprintf('%.3f', vals_Q4(k)), ...
            'HorizontalAlignment','center','FontSize',8,'Color',c_Q4c)
    end

    % --- Subplot 2: Distribucion de consumo por intensidad formal ---
    subplot(1,2,2)
    c_vals2 = c(:);
    w_hiF_vec = da * g_hiF(:);
    w_loF_vec = da * g_loF(:);
    c_lo2 = min(c_vals2); c_hi2 = max(c_vals2);
    if c_hi2 <= c_lo2, c_hi2 = c_lo2 + 1e-8; end
    edges_c2 = linspace(c_lo2, c_hi2, 45);
    ctr_c2   = 0.5*(edges_c2(1:end-1)+edges_c2(2:end));
    binw_c2  = edges_c2(2)-edges_c2(1);
    bin_idx2 = discretize(c_vals2, edges_c2);
    vhiF = ~isnan(bin_idx2) & (w_hiF_vec>0);
    vloF = ~isnan(bin_idx2) & (w_loF_vec>0);
    cnt_hiF = accumarray(bin_idx2(vhiF), w_hiF_vec(vhiF), [numel(edges_c2)-1,1], @sum, 0)';
    cnt_loF = accumarray(bin_idx2(vloF), w_loF_vec(vloF), [numel(edges_c2)-1,1], @sum, 0)';
    pdf_hiF = cnt_hiF / max(sum(cnt_hiF)*binw_c2, 1e-12);
    pdf_loF = cnt_loF / max(sum(cnt_loF)*binw_c2, 1e-12);
    hold on; box on; grid on
    plot(ctr_c2, pdf_hiF, '-',  'Color', [0.00 0.45 0.74], 'LineWidth', 2.5, ...
        'DisplayName', sprintf('Mas formal (mean ell_F=%.3f)', mean_ellF_hiF))
    plot(ctr_c2, pdf_loF, '--', 'Color', [0.85 0.33 0.10], 'LineWidth', 2.5, ...
        'DisplayName', sprintf('Mas informal (mean ell_F=%.3f)', mean_ellF_loF))
    xline(mean_c_hiF, ':', 'Color', [0.00 0.45 0.74], 'LineWidth', 1.3, 'HandleVisibility','off')
    xline(mean_c_loF, ':', 'Color', [0.85 0.33 0.10], 'LineWidth', 1.3, 'HandleVisibility','off')
    xlabel('Consumo c', 'FontSize', 13, 'Interpreter', 'none')
    ylabel('Densidad', 'FontSize', 12)
    title('Consumo: mas formal vs mas informal', 'FontSize', 12, 'FontWeight', 'bold')
    legend('Location', 'NorthEast', 'FontSize', 9, 'Interpreter', 'none')

    sgtitle(sprintf(['Figura 13: heterogeneidad — cuartiles y horas formales' ...
        '\nCorte horas formales: mediana share\\_F = %.3f'], med_shareF), ...
        'FontSize', 11)
    save_png(fig13, fullfile(output_dir, 'distributions_by_quartile.png'), 300)
    fprintf('Figure distributions_by_quartile saved.\n')

    % ------------------------------------------------------------------
    % FIGURE 14: DISTRIBUCION DE CONSUMO Y GASTO
    % ------------------------------------------------------------------
    fig14 = figure('Color','white','Position',[100 100 980 420]);
    weights_all = da * g(:);

    subplot(1,2,1)
    hold on; box on; grid on
    [x_c, pdf_c] = weighted_pdf(c(:), weights_all, 50);
    [x_e, pdf_e] = weighted_pdf(cons_exp(:), weights_all, 50);
    plot(x_c, pdf_c, 'Color', [0.00 0.45 0.74], 'LineWidth', 2.2, ...
        'DisplayName', 'Consumo efectivo C_eff')
    plot(x_e, pdf_e, '--', 'Color', [0.85 0.33 0.10], 'LineWidth', 2.2, ...
        'DisplayName', 'Gasto total c_F + p_I c_I')
    xline(da * sum(sum(g .* c)), ':', 'Color', [0.00 0.45 0.74], 'LineWidth', 1.2, 'HandleVisibility','off')
    xline(da * sum(sum(g .* cons_exp)), ':', 'Color', [0.85 0.33 0.10], 'LineWidth', 1.2, 'HandleVisibility','off')
    xlabel('Nivel', 'Interpreter', 'none')
    ylabel('Densidad ponderada', 'Interpreter', 'none')
    title('Distribucion: consumo efectivo vs gasto', 'Interpreter', 'none')
    legend('Location', 'best', 'Interpreter', 'none')

    subplot(1,2,2)
    hold on; box on; grid on
    [x_f, pdf_f] = weighted_pdf(c_F(:), weights_all, 50);
    [x_i, pdf_i] = weighted_pdf((p_I*c_I(:)), weights_all, 50);
    plot(x_f, pdf_f, 'Color', [0.20 0.45 0.78], 'LineWidth', 2.2, ...
        'DisplayName', 'Consumo formal c_F')
    plot(x_i, pdf_i, '--', 'Color', [0.80 0.25 0.15], 'LineWidth', 2.2, ...
        'DisplayName', 'Gasto informal p_I c_I')
    xline(da * sum(sum(g .* c_F)), ':', 'Color', [0.20 0.45 0.78], 'LineWidth', 1.2, 'HandleVisibility','off')
    xline(da * sum(sum(g .* (p_I*c_I))), ':', 'Color', [0.80 0.25 0.15], 'LineWidth', 1.2, 'HandleVisibility','off')
    xlabel('Nivel', 'Interpreter', 'none')
    ylabel('Densidad ponderada', 'Interpreter', 'none')
    title('Componentes del gasto', 'Interpreter', 'none')
    legend('Location', 'best', 'Interpreter', 'none')

    sgtitle('Figura 14: distribuciones ponderadas por la estacionaria g(a,z,q)', ...
        'FontSize', 11, 'Interpreter', 'none')
    save_png(fig14, fullfile(output_dir, 'consumption_expenditure_distribution.png'), 300)
    fprintf('Figure consumption_expenditure_distribution saved.\n')

% -------------------------------------------------------------------------
% FIGURE 15: TASA DE AHORRO POR RIQUEZA
%   Evidencia directa de trampa de baja acumulacion:
%   hogares pobres desahorran / no acumulan mientras informales.
% -------------------------------------------------------------------------
    income_total      = income_formal + income_informal + income_assets + income_transfer + income_profit;
    income_by_a       = sum(g .* income_total, 2) ./ max(g_total_plot, 1e-12);
    savings_rate_by_a = adot_by_a ./ max(abs(income_by_a), 1e-12);
    savings_rate_by_a(~isfinite(savings_rate_by_a)) = 0;
    savings_rate_by_a = max(min(savings_rate_by_a, 2), -2);

    Q_adot_mean  = zeros(1,5);
    Q_income_tot = Q_income_F + Q_income_I + Q_income_ra + Q_income_T + Q_income_Pi;
    Q_srate      = zeros(1,5);
    for jq = 1:5
        gq = g .* quint_masks{jq};
        Q_adot_mean(jq) = da * sum(sum(gq .* adot)) / max(Q_mass(jq), 1e-12);
        Q_srate(jq)     = Q_adot_mean(jq) / max(abs(Q_income_tot(jq)), 1e-12);
    end

    % Componentes de ingreso por nivel de riqueza (para Panel 2)
    income_F_by_a   = sum(g .* income_formal,   2) ./ max(g_total_plot, 1e-12);
    income_I_by_a   = sum(g .* income_informal, 2) ./ max(g_total_plot, 1e-12);
    income_ra_by_a  = sum(g .* income_assets,   2) ./ max(g_total_plot, 1e-12);

    fig15 = figure('Color','white','Position',[100 100 1200 700]);

    % Panel 1: drift de activos — todos acumulan, pero convergen a distinto nivel
    subplot(2,2,1)
    hold on; box on; grid on
    plot(a, adot_by_a, 'Color', [0.12 0.28 0.46], 'LineWidth', 2.4)
    yline(0, '--k', 'LineWidth', 1.2)
    for xq = [q20_a q40_a q60_a q80_a]
        xline(xq, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 0.8)
    end
    xlabel('Activos a', 'Interpreter','none')
    ylabel('$E[\dot{a}\mid a]$', 'Interpreter','latex')
    title('1. Drift de activos: todos acumulan, drift cae al equilibrio', 'Interpreter','none')
    xlim([amin_plot amax_plot])
    text(0.04, 0.90, 'Drift cae a 0 cerca del nivel estacionario de cada tipo z', ...
        'Units','normalized','FontSize',8,'Color',[0.25 0.25 0.25],'Interpreter','none')

    % Panel 2: composicion de ingreso por riqueza — ingreso formal + activos
    %          solo emerge con riqueza alta; pobres dependen de ingreso informal
    subplot(2,2,2)
    hold on; box on; grid on
    area(a(1:idx_max), income_ra_by_a(1:idx_max), 'FaceColor', c_assets, ...
        'EdgeColor','none', 'FaceAlpha', 0.7, 'DisplayName', 'r*a (activos)')
    area(a(1:idx_max), income_F_by_a(1:idx_max),  'FaceColor', c_formal, ...
        'EdgeColor','none', 'FaceAlpha', 0.6, 'DisplayName', 'Ingreso formal neto')
    area(a(1:idx_max), income_I_by_a(1:idx_max),  'FaceColor', c_informal, ...
        'EdgeColor','none', 'FaceAlpha', 0.5, 'DisplayName', 'Ingreso informal')
    for xq = [q20_a q40_a q60_a q80_a]
        xline(xq, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 0.8, 'HandleVisibility','off')
    end
    xlabel('Activos a', 'Interpreter','none')
    ylabel('Ingreso medio por fuente', 'Interpreter','none')
    title('2. Composicion de ingreso por riqueza', 'Interpreter','none')
    xlim([amin_plot amax_plot])
    legend('Location','northwest','Interpreter','none','FontSize',8)
    text(0.04, 0.12, 'Q1: casi todo informal (bajo)', ...
        'Units','normalized','FontSize',8,'Color',[0.60 0.10 0.10],'Interpreter','none')

    % Panel 3: distribucion estacionaria por tipo z (la trampa es de nivel)
    subplot(2,2,3)
    hold on; box on; grid on
    plot(a, g_z1 / max(da*sum(g_z1),1e-12), '-', 'Color', c_informal, 'LineWidth', 2.2, ...
        'DisplayName', sprintf('z bajo=%.2f (mas informal)', z1_val))
    plot(a, g_z2 / max(da*sum(g_z2),1e-12), '--', 'Color', c_formal, 'LineWidth', 2.2, ...
        'DisplayName', sprintf('z alto=%.2f (mas formal)', z2_val))
    xlabel('Activos a', 'Interpreter','none')
    ylabel('Densidad estacionaria (normalizada)', 'Interpreter','none')
    title('3. z_bajo converge a MENOR riqueza: esa es la trampa', 'Interpreter','none')
    xlim([amin_plot amax_plot])
    legend('Location','northeast','Interpreter','none','FontSize',9)
    text(0.04, 0.88, sprintf('Media z_bajo=%.3f  vs  z_alto=%.3f', mean_a_z1_plot, mean_a_z2_plot), ...
        'Units','normalized','FontSize',8,'Color',[0.25 0.25 0.25],'Interpreter','none')

    % Panel 4: ingreso total vs informalidad por quintil (mecanismo)
    subplot(2,2,4)
    hold on; box on; grid on
    yyaxis left
    h_inf = plot(1:5, Q_share_inf*100, '-o', 'Color', c_informal, ...
        'MarkerFaceColor', c_informal, 'LineWidth', 2.2);
    ylabel('Share horas informales (%)', 'Interpreter','none')
    ylim([0 105])
    yyaxis right
    h_inc = plot(1:5, Q_income_tot, '--s', 'Color', c_formal, ...
        'MarkerFaceColor', c_formal, 'LineWidth', 2.2);
    ylabel('Ingreso total medio', 'Interpreter','none')
    set(gca,'XTick',1:5,'XTickLabel',qlabels,'TickLabelInterpreter','none')
    xlabel('Quintil de riqueza', 'Interpreter','none')
    title('4. Mas informal = menos ingreso (mecanismo de la trampa)', 'Interpreter','none')
    legend([h_inf h_inc], {'Share informal','Ingreso total'}, ...
        'Location','east','Interpreter','none','FontSize',8)

    sgtitle(sprintf(['La trampa es de NIVEL: z_bajo converge a menor riqueza por menor ingreso formal' ...
        '\nz_bajo media=%.3f  vs  z_alto media=%.3f  |  r*=%.4f, tau=%.2f'], ...
        mean_a_z1_plot, mean_a_z2_plot, r_eq, tau), ...
        'Interpreter','none','FontSize',10)
    save_png(fig15, fullfile(output_dir, 'savings_rate_by_wealth.png'), 300)
    fprintf('Figure savings_rate_by_wealth saved.\n')

% -------------------------------------------------------------------------
% FIGURE 16: MECANISMO POR QUINTIL — cuadro resumen para tesis
%   Historia completa en 4 paneles: riqueza → informalidad → consumo → ahorro.
%   Panel 2 incluye validacion externa con dato ENAHO (Q1, Q5).
% -------------------------------------------------------------------------
    fig16 = figure('Color','white','Position',[110 110 1240 680]);
    c_neu  = [0.50 0.50 0.50];   % gris neutro para consumo

    subplot(2,2,1)
    hold on; box on; grid on
    b16a = bar(1:5, Q_mean_a, 'FaceColor', c_formal, 'EdgeColor','none', 'BarWidth', 0.65);
    set(gca,'XTick',1:5,'XTickLabel',qlabels,'TickLabelInterpreter','none')
    xlabel('Quintil de riqueza', 'Interpreter','none')
    ylabel('Activos medios (a)', 'Interpreter','none')
    title('1. Riqueza media por quintil', 'Interpreter','none','FontWeight','bold')
    % annotate gradient arrow message
    text(0.50, 0.88, 'Mas rico  \rightarrow', ...
        'Units','normalized','FontSize',9,'HorizontalAlignment','center','Interpreter','tex')

    subplot(2,2,2)
    hold on; box on; grid on
    bar(1:5, Q_share_inf*100, 'FaceColor', c_informal, 'EdgeColor','none', ...
        'BarWidth', 0.65, 'HandleVisibility','off');
    % Validez externa: ENAHO Q1 y Q5 desplazados lateralmente para no solapar barra
    plot(1.35, T6_Q1_plt*100, 'kd', 'MarkerFaceColor','white', 'MarkerSize', 12, 'LineWidth', 2.0, ...
        'DisplayName', sprintf('ENAHO Q1=%.0f%% (ext.)', T6_Q1_plt*100))
    plot(5.35, T6_Q5_plt*100, 'k^', 'MarkerFaceColor','white', 'MarkerSize', 12, 'LineWidth', 2.0, ...
        'DisplayName', sprintf('ENAHO Q5=%.0f%% (ext.)', T6_Q5_plt*100))
    yline(T4_plt*100, '--', 'Color', [0.3 0.3 0.3], 'LineWidth', 1.1, ...
        'DisplayName', sprintf('Promedio INEI=%.0f%%', T4_plt*100))
    set(gca,'XTick',1:5,'XTickLabel',qlabels,'TickLabelInterpreter','none')
    xlim([0.5 5.9])
    ylim([0 110])
    xlabel('Quintil de riqueza (modelo: activos; ENAHO: ingreso)', 'Interpreter','none')
    ylabel('Informalidad (%)', 'Interpreter','none')
    title('2. Informalidad por quintil: modelo (int.) vs ENAHO (ext.)', ...
        'Interpreter','none','FontWeight','bold')
    legend('Location','northeast','Interpreter','none','FontSize',7.5)
    % nota aclarando comparacion
    text(0.02, 0.04, 'Modelo: share horas informales (intensivo). ENAHO: % trab. informales (extensivo, quintil ingreso).', ...
        'Units','normalized','FontSize',6.5,'Color',[0.35 0.35 0.35],'Interpreter','none')

    subplot(2,2,3)
    hold on; box on; grid on
    bar(1:5, Q_mean_c, 'FaceColor', c_neu, 'EdgeColor','none', 'BarWidth', 0.65)
    set(gca,'XTick',1:5,'XTickLabel',qlabels,'TickLabelInterpreter','none')
    xlabel('Quintil de riqueza', 'Interpreter','none')
    ylabel('Gasto total medio (c_F + p_I c_I)', 'Interpreter','none')
    title('3. Consumo promedio por quintil', 'Interpreter','none','FontWeight','bold')

    subplot(2,2,4)
    hold on; box on; grid on
    clrs16 = repmat(c_formal, 5, 1);
    for jq = 1:5
        if Q_adot_mean(jq) < 0, clrs16(jq,:) = c_informal; end
    end
    for jq = 1:5
        bar(jq, Q_adot_mean(jq), 'FaceColor', clrs16(jq,:), 'EdgeColor','none')
    end
    yline(0, '--k', 'LineWidth', 1.3)
    set(gca,'XTick',1:5,'XTickLabel',qlabels,'TickLabelInterpreter','none')
    xlabel('Quintil de riqueza', 'Interpreter','none')
    ylabel('Acumulacion media de activos (adot)', 'Interpreter','none')
    title('4. Acumulacion de activos por quintil', 'Interpreter','none','FontWeight','bold')

    sgtitle(sprintf(['Mecanismo: Q1 mas informal, menor consumo y menor acumulacion que Q5\n' ...
        'Barras = modelo | Diamante/triangulo = dato ENAHO 2017 (quintil gasto per capita)'], ...
        T6_Q1_plt*100, T6_Q5_plt*100), ...
        'Interpreter','none','FontSize',10)
    save_png(fig16, fullfile(output_dir, 'mechanism_by_quintile.png'), 300)
    fprintf('Figure mechanism_by_quintile saved.\n')

end  % end EQUILIBRIUM_MODE == 2 for figs 10-12

fprintf('Graphs saved to %s/\n', output_dir);

% =========================================================================
% 6. SAVE
% =========================================================================

if EQUILIBRIUM_MODE == 1
    save('aiyagari_2firms_v10_R2_precio_endogeno_partial.mat', ...
        'r_grid', 'S', 'KD', 'w_F_r', 'V_r', 'g_r', 'c_r', ...
        'ell_F_r', 'ell_I_r', 'L_F', 'L_I', 'T_eq_r', 'w_I_eq_r', 'Pi_I_eq_r', ...
        'p_I_eq_r', 'Y_I_eq_r', 'C_I_eq_r', 'a', 'z', ...
        'tau', 'H_bar', 'beta_I', 'theta', 'A_I', 'psi_F', 'psi_I', ...
        'p_I', 'omega_C', 'eta_C', 'sigma_C', 'EQUILIBRIUM_MODE')
else
    save('aiyagari_2firms_v10_R2_precio_endogeno_general.mat', ...
        'r_star', 'K_star', 'w_F_star', 'w_I_star', 'omega_I_star', ...
        'L_F_star', 'L_I_star', 'T_star', 'tax_rev', 'profit_I_star', 'p_I_star', ...
        'walras_err', 'goods_I_err', 'labor_clear', 'pmgl_check', 'Y_F', 'Y_I', 'C_I_agg', 'C_F_agg', 'beta_I', ...
        'V', 'g', 'c', 'c_F', 'c_I', 'C_eff', 'share_cI', 'ell_F', 'ell_I', 'a', 'z', ...
        'tau', 'H_bar', 'theta', 'A_I', 'psi_F', 'psi_I', ...
        'p_I', 'omega_C', 'eta_C', 'sigma_C', 'EQUILIBRIUM_MODE')
end

fprintf('=== v10 R2 precio endogeno COMPLETE ===\n')


% =========================================================================
% LOCAL FUNCTION: save_png
% =========================================================================

end  % function plot_results_v10

function save_png(fig, file_name, resolution)
    if nargin < 3 || isempty(resolution)
        resolution = 300;
    end

    fprintf('Saving %s ...\n', file_name);
    set(fig, 'Color', 'white', 'Renderer', 'painters');
    axs = findall(fig, 'Type', 'axes');
    dark = [0.15 0.15 0.15];   % Moll-style axis color
    for iax = 1:numel(axs)
        try
            axtoolbar(axs(iax), 'none');
        catch
            try
                axs(iax).Toolbar.Visible = 'off';
            catch
            end
        end
        % Uniform Moll-style polish (same treatment as MIT figures):
        % clean fonts, box on, ticks out, light grid, bold titles.
        try
            set(axs(iax), 'FontName', 'Helvetica', 'Box', 'on', ...
                'TickDir', 'out', 'LineWidth', 0.75, ...
                'XColor', dark, 'YColor', dark, ...
                'GridAlpha', 0.12, 'GridLineStyle', '-', 'MinorGridAlpha', 0.06);
            if ~isempty(axs(iax).Title) && ~isempty(axs(iax).Title.String)
                axs(iax).Title.FontWeight = 'bold';
            end
        catch
        end
    end
    drawnow;

    print(fig, file_name, '-dpng', sprintf('-r%d', resolution), '-painters');

    close(fig);
    fprintf('  saved.\n');
end

function [centers, pdf_vals] = weighted_pdf(values, weights, nbins)
    values = values(:);
    weights = weights(:);
    ok = isfinite(values) & isfinite(weights) & weights > 0;
    values = values(ok);
    weights = weights(ok);

    if isempty(values)
        centers = 0;
        pdf_vals = 0;
        return
    end

    lo = min(values);
    hi = max(values);
    if hi <= lo
        hi = lo + 1e-8;
    end

    edges = linspace(lo, hi, nbins + 1);
    centers = 0.5 * (edges(1:end-1) + edges(2:end));
    binw = edges(2) - edges(1);
    bins = discretize(values, edges);
    valid = ~isnan(bins);
    counts = accumarray(bins(valid), weights(valid), [nbins, 1], @sum, 0)';
    pdf_vals = counts / max(sum(counts) * binw, 1e-12);
end

function [x_sorted, cdf_vals] = weighted_cdf(values, weights)
    values = values(:);
    weights = weights(:);
    ok = isfinite(values) & isfinite(weights) & weights > 0;
    values = values(ok);
    weights = weights(ok);

    if isempty(values)
        x_sorted = 0;
        cdf_vals = 0;
        return
    end

    [x_sorted, idx] = sort(values);
    w_sorted = weights(idx);
    cdf_vals = cumsum(w_sorted) / max(sum(w_sorted), 1e-12);
end

function med_val = weighted_median(values, weights)
    values = values(:);
    weights = weights(:);
    ok = isfinite(values) & isfinite(weights) & weights > 0;
    values = values(ok);
    weights = weights(ok);

    if isempty(values)
        med_val = NaN;
        return
    end

    [values_sorted, idx] = sort(values);
    weights_sorted = weights(idx);
    cdf_vals = cumsum(weights_sorted) / max(sum(weights_sorted), 1e-12);
    med_idx = find(cdf_vals >= 0.5, 1, 'first');
    if isempty(med_idx)
        med_idx = numel(values_sorted);
    end
    med_val = values_sorted(med_idx);
end
