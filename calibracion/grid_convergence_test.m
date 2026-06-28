%% grid_convergence_test.m
% Sweep Nz={7,14,24,30,40} con I=200 (fast) y punto I=500 (producción).
% Muestra % error relativo al ground truth (Nz=40, I=500).
%
% USO:
%   >> grid_convergence_test          % corre todo (~45 min)
%   >> grid_convergence_test('plot')  % solo figura si ya hay .mat
%
% OUTPUT: outputs/grid_convergence/grid_convergence_results.mat
%         outputs/grid_convergence/fig_grid_convergence.pdf/.png

function grid_convergence_test(varargin)

script_dir = fileparts(mfilename('fullpath'));
repo_dir   = fullfile(script_dir, '..');
addpath(repo_dir);
addpath(fullfile(repo_dir, 'ploteo'));

out_dir = fullfile(repo_dir, 'outputs', 'grid_convergence');
if ~exist(out_dir, 'dir'), mkdir(out_dir); end

mat_summary = fullfile(out_dir, 'grid_convergence_results.mat');

only_plot = nargin > 0 && strcmpi(varargin{1}, 'plot');

%% ─── CONFIGURACIONES ────────────────────────────────────────────────────────
% {label, Nz, I, fast_debug_str, fallback_tag}
% fallback_tag: si no existe el tag canónico, buscar este otro run
configs = {
    'Nz=7  I=200',   7,  200, 'true',  '';
    'Nz=14 I=200',  14,  200, 'true',  '';
    'Nz=24 I=200',  24,  200, 'true',  '';
    'Nz=30 I=200',  30,  200, 'true',  '';
    'Nz=40 I=200',  40,  200, 'true',  'test_kz38_psii34';   % benchmark fast
    'Nz=40 I=500',  40,  500, 'false', 'v10_prod_kz38_psii34'; % ground truth
};

%% ─── PARÁMETROS FIJOS (test_kz38_psii34) ────────────────────────────────────
function set_base_params(nz, I_val, fast_str)
    setenv('HA_IE_EQ_MODE',          '2');
    setenv('HA_IE_FAST_DEBUG',       fast_str);
    setenv('HA_IE_VERBOSE',          '0');
    setenv('HA_IE_PROFILE',          'false');
    setenv('HA_IE_I',                num2str(I_val));
    setenv('HA_IE_AMIN',             '-1.0');
    setenv('HA_IE_AMAX',             '20');
    setenv('HA_IE_GA',               '1.0');
    setenv('HA_IE_RHO',              '0.073');
    setenv('HA_IE_FRISCH',           '0.38');
    setenv('HA_IE_PSI_F',            '55');
    setenv('HA_IE_PSI_I',            '34');
    setenv('HA_IE_THETA',            '1.0');
    setenv('HA_IE_NU_I',             '0.6');
    setenv('HA_IE_SIGMA_C',          '5.0');
    setenv('HA_IE_OMEGA_C',          '0.56');
    setenv('HA_IE_TAU_C',            '0');
    setenv('HA_IE_AL',               '0.573');
    setenv('HA_IE_A_I',              '0.95');
    setenv('HA_IE_ALPHA_I',          '0.220');
    setenv('HA_IE_BETA_I',           '0.619');
    setenv('HA_IE_INFORMAL_PROFIT_RULE', 'hours');
    setenv('HA_IE_Z_PROCESS',        'ou');
    setenv('HA_IE_Z_N',              num2str(nz));
    setenv('HA_IE_Z_RHO',            '0.8600132622');
    setenv('HA_IE_Z_SD',             '0.5417411732');
    setenv('HA_IE_Z_WIDTH',          '2.5');
    setenv('HA_IE_Z_MU',             '0.0');
    setenv('HA_IE_Z_DT',             '1.0');
    setenv('HA_IE_KAPPA_Z1',         '0.38');
    setenv('HA_IE_KAPPA_Z_SHAPE',    '2.0');
    setenv('HA_IE_DEBT_PREM_CHI',    '0.02');
    setenv('HA_IE_DEBT_PREM_ETA',    '1.0');
    setenv('HA_IE_DEBT_PREM_REBATE', 'false');
    setenv('HA_IE_R_LO',             '0.03');
    setenv('HA_IE_R_HI',             '0.12');
    setenv('HA_IE_TOL_R',            '1e-5');
    setenv('HA_IE_MAX_BISECT_R',     '40');
    setenv('HA_IE_TOL_T',            '1e-5');
    setenv('HA_IE_TOL_WI',           '1e-5');
    setenv('HA_IE_TOL_PI',           '1e-5');
    setenv('HA_IE_MAX_ITER_T',       '30');
    setenv('HA_IE_MAX_ITER_WI',      '40');
    setenv('HA_IE_MAX_ITER_PI',      '50');
end

%% ─── CORRER O CARGAR ─────────────────────────────────────────────────────────
if only_plot && exist(mat_summary, 'file')
    load(mat_summary, 'results');
    fprintf('Cargado %s — solo graficando.\n', mat_summary);
else
    n_cfg   = size(configs, 1);
    results = struct('label',{},'nz',{},'I',{},'elapsed',{},...
                     'r_star',{},'p_I',{},'T4',{},'T5',{},'Tkz',{},'Tgasto',{});

    for ic = 1:n_cfg
        label       = configs{ic,1};
        nz          = configs{ic,2};
        I_val       = configs{ic,3};
        fast_str    = configs{ic,4};
        fallback    = configs{ic,5};

        tag      = sprintf('gc_Nz%02d_I%03d', nz, I_val);
        run_mat  = fullfile(repo_dir, 'outputs', 'stationary', tag, ['results_' tag '.mat']);

        % Fallback a run existente con mismos params
        if ~exist(run_mat, 'file') && ~isempty(fallback)
            fb_mat = fullfile(repo_dir, 'outputs', 'stationary', fallback, ['results_' fallback '.mat']);
            if exist(fb_mat, 'file')
                run_mat = fb_mat;
                fprintf('[%d/%d] %s — usando fallback: %s\n', ic, n_cfg, label, fallback);
            end
        end

        if exist(run_mat, 'file')
            fprintf('[%d/%d] %s — cargando %s\n', ic, n_cfg, label, run_mat);
            d = load(run_mat);
            results(ic) = extract_result(label, nz, I_val, d, NaN);
            continue;
        end

        % Correr
        fprintf('\n[%d/%d] Corriendo: %s  (Nz=%d, I=%d) ...\n', ic, n_cfg, label, nz, I_val);
        set_base_params(nz, I_val, fast_str);
        setenv('HA_IE_RUN_TAG', tag);

        t0 = tic;
        evalin('base', 'model_main');   % script needs base workspace (static workspace fix)
        elapsed = toc(t0);

        if exist(run_mat, 'file')
            d = load(run_mat);
            results(ic) = extract_result(label, nz, I_val, d, elapsed);
        else
            warning('No se encontró %s tras correr.', run_mat);
            results(ic) = nan_result(label, nz, I_val, elapsed);
        end

        fprintf('  Listo en %.1f s (%.1f min)\n', elapsed, elapsed/60);
    end

    save(mat_summary, 'results');
    fprintf('\nResultados guardados en %s\n', mat_summary);
end

%% ─── TABLA CONSOLA + CSV ────────────────────────────────────────────────────
print_table(results);
save_csv_table(results, out_dir);

%% ─── FIGURA 1: estilo Achdou (error X, tiempo Y) ────────────────────────────
plot_grid_convergence_fig(results, out_dir);

%% ─── FIGURA 2: tradeoff (tiempo X, max-error Y) ─────────────────────────────
plot_tradeoff_fig(results, out_dir);

end  % function grid_convergence_test


%% ─── SUBFUNCION: extract_result ─────────────────────────────────────────────
function r = extract_result(label, nz, I_val, d, elapsed_override)
r.label   = label;
r.nz      = nz;
r.I       = I_val;
r.elapsed = get_elapsed(d, elapsed_override);
r.r_star  = safe_get(d, 'r_star');
r.p_I     = safe_get(d, 'p_I_star');
r.T4      = safe_get(d, 'T4_model');
r.T5      = safe_get(d, 'T5_nom');
r.Tkz     = safe_get(d, 'T_kappa_z_model');
r.Tgasto  = safe_get(d, 'Tgasto_tipo');
end

function r = nan_result(label, nz, I_val, elapsed)
r = struct('label',label,'nz',nz,'I',I_val,'elapsed',elapsed,...
    'r_star',NaN,'p_I',NaN,'T4',NaN,'T5',NaN,'Tkz',NaN,'Tgasto',NaN);
end

function v = safe_get(d, fname)
if isfield(d, fname) && ~isempty(d.(fname))
    v = d.(fname);
else
    v = NaN;
end
end

function t = get_elapsed(d, override)
if isfinite(override)
    t = override;
    return;
end
if isfield(d, 'total_elapsed') && isfinite(d.total_elapsed)
    t = d.total_elapsed;
elseif isfield(d, 'HA_IE_TIMINGS')
    T = d.HA_IE_TIMINGS;
    if isfield(T, 'solve_given_prices')
        t = T.solve_given_prices.time;
    elseif isfield(T, 'hjb_total')
        t = T.hjb_total.time + T.kfe_total.time;
    else
        t = NaN;
    end
else
    t = NaN;
end
end


%% ─── SUBFUNCION: TABLA ───────────────────────────────────────────────────────
function print_table(results)
% Ground truth = último resultado (Nz=40, I=500)
n  = numel(results);
gt = results(n);

fprintf('\n%s\n', repmat('─',1,80));
fprintf('%-18s %6s %5s %7s | %6s %6s %6s %6s\n', ...
    'Config','Nz','I','min', 'T4 err','T5 err','Tkz err','r* err');
fprintf('%s\n', repmat('─',1,80));
for i = 1:n
    r = results(i);
    if i == n
        pct = @(x,ref) 0;  % ground truth = 0% error
    else
        pct = @(x,ref) (x - ref) / abs(ref) * 100;
    end
    fprintf('%-18s %6d %5d %7.1f | %+6.2f%% %+6.2f%% %+6.2f%% %+6.2f%%\n', ...
        r.label, r.nz, r.I, r.elapsed/60, ...
        pct(r.T4,  gt.T4), ...
        pct(r.T5,  gt.T5), ...
        pct(r.Tkz, gt.Tkz), ...
        pct(r.r_star, gt.r_star));
end
fprintf('%s\n', repmat('─',1,80));
fprintf('Ground truth: T4=%.4f  T5=%.4f  Tkz=%.4f  r*=%.4f\n',...
    gt.T4, gt.T5, gt.Tkz, gt.r_star);
fprintf('%s\n\n', repmat('─',1,80));

% Guardar tabla como CSV (se pasa out_dir como segundo argumento)
end

function save_csv_table(results, out_dir)
n  = numel(results);
gt = results(n);

csv_path = fullfile(out_dir, 'grid_convergence_table.csv');
fid = fopen(csv_path, 'w');
fprintf(fid, 'label,nz,I,elapsed_min,T4,T5,Tkz,r_star,T4_pct_err,T5_pct_err,Tkz_pct_err,r_pct_err\n');
for i = 1:n
    r = results(i);
    if i == n
        e4=0; e5=0; ekz=0; er=0;
    else
        e4  = (r.T4     - gt.T4)     / abs(gt.T4)     * 100;
        e5  = (r.T5     - gt.T5)     / abs(gt.T5)     * 100;
        ekz = (r.Tkz    - gt.Tkz)    / abs(gt.Tkz)    * 100;
        er  = (r.r_star - gt.r_star) / abs(gt.r_star) * 100;
    end
    fprintf(fid, '%s,%d,%d,%.2f,%.5f,%.5f,%.5f,%.5f,%.3f,%.3f,%.3f,%.3f\n', ...
        r.label, r.nz, r.I, r.elapsed/60, ...
        r.T4, r.T5, r.Tkz, r.r_star, e4, e5, ekz, er);
end
fclose(fid);
fprintf('CSV guardado: %s\n', csv_path);
end


%% ─── SUBFUNCION: FIGURA (estilo Moll/Achdou Fig 4) ──────────────────────────
function plot_grid_convergence_fig(results, out_dir)

n    = numel(results);
gt   = results(n);   % ground truth: Nz=40, I=500

nz_vec      = [results.nz];
I_vec       = [results.I];
elapsed_min = reshape([results.elapsed] / 60, 1, []);   % force row

% cols: [r_star, p_I]
gt_vals = [gt.r_star, gt.p_I];

abs_pct = NaN(n, 2);
for i = 1:n-1
    vals = [results(i).r_star, results(i).p_I];
    abs_pct(i,:) = abs((vals - gt_vals) ./ gt_vals) * 100;
end

is_fallback = (nz_vec == 40) & (I_vec == 200);
idx_clean   = find(~is_fallback & I_vec == 200);
idx_fb      = find(is_fallback);

c_main   = [0.15 0.40 0.75];
c_fallbk = [0.55 0.55 0.55];

panels       = [1, 2];   % r_star=col1, p_I=col2
panel_titles = {'(a) Speed-accuracy tradeoff: equilibrium interest rate', ...
                '(b) Speed-accuracy tradeoff: informal good price'};
xlbl         = {'r^* error in %', ...
                'p_I error in %'};

% ── figura estilo Moll ────────────────────────────────────────────────────────
fig = figure('Units','centimeters','Position',[2 2 18 7.5],'Color','white');

for ip = 1:2
    col = panels(ip);
    ax  = subplot(1,2,ip);
    set(ax,'Color','white','FontSize',9,'TickDir','out','LineWidth',0.7, ...
        'XColor',[0 0 0],'YColor',[0 0 0],'GridColor',[0.85 0.85 0.85], ...
        'GridAlpha',1,'GridLineStyle','-');
    hold on; box on;

    % datos limpios: forzar columnas para evitar broadcast
    xc  = abs_pct(idx_clean, col);        % k×1
    yc  = elapsed_min(idx_clean(:)).';    % k×1
    [xc_s, ord] = sort(xc(:));
    yc_s = yc(ord);                        % k×1
    nz_s = nz_vec(idx_clean(ord));
    valid = isfinite(xc_s) & isfinite(yc_s) & xc_s > 0;

    % curva principal
    if sum(valid) > 1
        plot(xc_s(valid), yc_s(valid), '-o', ...
            'Color',c_main,'MarkerFaceColor',c_main, ...
            'MarkerEdgeColor',[1 1 1],'MarkerSize',6,'LineWidth',1.2);
    end

    % etiquetas Nz (offset limpio)
    for k = 1:numel(idx_clean)
        xv = abs_pct(idx_clean(k), col);
        yv = elapsed_min(idx_clean(k));
        if ~isfinite(xv) || xv <= 0, continue; end
        text(xv*1.12, yv+0.8, sprintf('N_z=%d', nz_vec(idx_clean(k))), ...
            'FontSize', 7.5, 'Color', c_main, 'FontWeight','normal');
    end

    % punto fallback (gris, cuadrado hueco)
    for k = idx_fb
        xv = abs_pct(k, col);
        yv = elapsed_min(k);
        if ~isfinite(xv) || xv <= 0, continue; end
        plot(xv, yv, 's', 'Color',c_fallbk,'MarkerFaceColor',[1 1 1], ...
            'MarkerEdgeColor',c_fallbk,'MarkerSize',7,'LineWidth',1.2);
        text(xv*1.12, yv-1.5, sprintf('N_z=%d (fallback)', nz_vec(k)), ...
            'FontSize',6.5,'Color',c_fallbk);
    end

    % xlim: incluir todos los puntos con margen
    all_x = abs_pct([idx_clean, idx_fb], col);
    all_x = all_x(isfinite(all_x) & all_x > 0);
    if ~isempty(all_x)
        xlim([min(all_x)*0.4, max(all_x)*2.5]);
    end
    ylim([0, max(elapsed_min)*1.12]);

    set(ax,'XScale','log');
    grid(ax,'on');
    xlabel(xlbl{ip}, 'FontSize', 9);
    ylabel('Speed in minutes', 'FontSize', 9);
    title(panel_titles{ip}, 'FontSize', 9, 'FontWeight','normal', ...
        'Interpreter','tex');
end

% leyenda en panel (a)
ax1 = subplot(1,2,1);
hl1 = plot(ax1, NaN, NaN, '-o', 'Color',c_main,'MarkerFaceColor',c_main, ...
    'MarkerEdgeColor',[1 1 1],'MarkerSize',6,'LineWidth',1.2);
hl2 = plot(ax1, NaN, NaN, 's', 'Color',c_fallbk,'MarkerFaceColor',[1 1 1], ...
    'MarkerEdgeColor',c_fallbk,'MarkerSize',7,'LineWidth',1.2);
leg = legend(ax1, [hl1 hl2], ...
    {'I=200, N_z variable (método diferencias finitas)', ...
     'N_z=40 I=200 fallback (outlier)'}, ...
    'Location','northeast','FontSize',7.5,'Box','on','Interpreter','tex');
leg.BoxFace.ColorType = 'truecoloralpha';
leg.BoxFace.ColorData = uint8([255 255 255 230]');

sgtitle('Speed-accuracy tradeoff: grilla z  |  ground truth = N_z=40, I=500', ...
    'FontSize', 9.5, 'FontWeight','normal', 'Interpreter','tex', ...
    'Color',[0.3 0.3 0.3]);

% Guardar fig1
fig_base = fullfile(out_dir, 'fig_grid_convergence');
exportgraphics(fig, [fig_base '.pdf'], 'ContentType','vector');
exportgraphics(fig, [fig_base '.png'], 'Resolution', 200);
fprintf('Figura guardada: %s.pdf/.png\n', fig_base);

end


%% ─── FIGURA 2: tradeoff frontier (tiempo X, max-error Y) ────────────────────
function plot_tradeoff_fig(results, out_dir)
% Curva Pareto: X = tiempo (min, log), Y = max |% error| sobre [r*, p_I] (log).
% Muestra el "elbow" y anota el sweet spot Nz=30.

n    = numel(results);
gt   = results(n);

nz_vec      = reshape([results.nz],      1, []);
I_vec       = reshape([results.I],       1, []);
elapsed_min = reshape([results.elapsed], 1, []) / 60;

gt_r  = gt.r_star;
gt_pI = gt.p_I;

% max |% error| sobre r* y p_I
max_err = NaN(1, n);
for i = 1:n-1
    e_r  = abs((results(i).r_star - gt_r)  / gt_r)  * 100;
    e_pI = abs((results(i).p_I   - gt_pI) / gt_pI) * 100;
    max_err(i) = max(e_r, e_pI);
end

is_fallback = (nz_vec == 40) & (I_vec == 200);
idx_clean   = find(~is_fallback & I_vec == 200);
idx_fb      = find(is_fallback);

c_main   = [0.15 0.40 0.75];
c_fallbk = [0.55 0.55 0.55];
c_sweet  = [0.85 0.25 0.10];   % rojo para sweet spot

% ── datos limpios ordenados por tiempo ───────────────────────────────────────
xc = elapsed_min(idx_clean);
yc = max_err(idx_clean);
nz_c = nz_vec(idx_clean);
[xc_s, ord] = sort(xc);
yc_s  = yc(ord);
nz_s  = nz_c(ord);

fig2 = figure('Units','centimeters','Position',[2 2 12 9],'Color','white');
ax   = axes(fig2);
set(ax,'Color','white','FontSize',9.5,'TickDir','out','LineWidth',0.7,...
    'XColor',[0 0 0],'YColor',[0 0 0],...
    'GridColor',[0.85 0.85 0.85],'GridAlpha',1,'GridLineStyle','-');
hold on; box on;

valid = isfinite(xc_s) & isfinite(yc_s) & yc_s > 0;

% curva principal
if sum(valid) > 1
    plot(xc_s(valid), yc_s(valid), '-o', ...
        'Color',c_main,'MarkerFaceColor',c_main,...
        'MarkerEdgeColor',[1 1 1],'MarkerSize',7,'LineWidth',1.3);
end

% etiquetas Nz
for k = 1:numel(idx_clean)
    xv = elapsed_min(idx_clean(k));
    yv = max_err(idx_clean(k));
    if ~isfinite(xv) || ~isfinite(yv) || yv <= 0, continue; end
    nz_k = nz_vec(idx_clean(k));
    % sweet spot Nz=30: label rojo + anotación
    if nz_k == 30
        plot(xv, yv, 'o','Color',c_sweet,'MarkerFaceColor',c_sweet,...
            'MarkerEdgeColor',[1 1 1],'MarkerSize',9,'LineWidth',1.3);
        text(xv*1.06, yv*1.35, sprintf('N_z=%d\n(sweet spot)', nz_k),...
            'FontSize',8,'Color',c_sweet,'FontWeight','bold','Interpreter','tex');
    else
        text(xv*1.06, yv*1.2, sprintf('N_z=%d', nz_k),...
            'FontSize',8,'Color',c_main,'Interpreter','tex');
    end
end

% fallback gris
for k = idx_fb
    xv = elapsed_min(k);
    yv = max_err(k);
    if ~isfinite(xv) || ~isfinite(yv) || yv <= 0, continue; end
    plot(xv, yv, 's','Color',c_fallbk,'MarkerFaceColor',[1 1 1],...
        'MarkerEdgeColor',c_fallbk,'MarkerSize',7,'LineWidth',1.2);
    text(xv*1.06, yv*0.75, sprintf('N_z=%d\n(fallback)', nz_vec(k)),...
        'FontSize',7,'Color',c_fallbk,'Interpreter','tex');
end

set(ax,'XScale','log','YScale','log');
grid(ax,'on');
xlabel('Compute time (minutes)',   'FontSize',10);
ylabel('Max error in %  (r^* and p_I)', 'FontSize',10, 'Interpreter','tex');
title('Speed-accuracy tradeoff: z-grid refinement', ...
    'FontSize',10,'FontWeight','normal');

% anotación ground truth
xl = xlim; yl = ylim;
text(xl(1)*1.1, yl(1)*1.5, 'Ground truth: N_z=40, I=500 (670 min)', ...
    'FontSize',7,'Color',[0.5 0.5 0.5],'Interpreter','tex');

% Guardar fig2
fig2_base = fullfile(out_dir, 'fig_tradeoff');
exportgraphics(fig2, [fig2_base '.pdf'], 'ContentType','vector');
exportgraphics(fig2, [fig2_base '.png'], 'Resolution', 200);
fprintf('Figura tradeoff guardada: %s.pdf/.png\n', fig2_base);

end
