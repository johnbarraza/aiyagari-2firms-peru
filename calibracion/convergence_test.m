%% CONVERGENCE ANALYSIS — Nz + Fast-Debug Tradeoff
% Tests NZ ∈ {7, 15, 25, 35, 40} and FastDebug ON vs OFF.
% Collects: prices, targets, timing, accuracy loss.
%
% USAGE:
%   >> convergence_analysis          % runs ALL combos (~30-60 min total)
%   >> convergence_analysis('quick') % Nz = [7, 15, 25] only, fastdebug ON
%
% OUTPUT:
%   convergence_results.mat  — table with all runs
%   convergence_plot.png     — tradeoff figure

function convergence_analysis(mode)
if nargin < 1, mode = 'full'; end

%% ─── Grid definitions ───────────────────────────────────────────
switch mode
    case 'quick'
        Nz_list   = [7, 15, 25];
        debug_modes = [true];
    case 'medium'
        Nz_list   = [7, 15, 25, 35];
        debug_modes = [true, false];
    otherwise % full
        Nz_list   = [7, 15, 25, 35, 40];
        debug_modes = [true, false];
end

n_runs = numel(Nz_list) * numel(debug_modes);
fprintf('=== Convergence analysis: %d runs ===\n', n_runs);

%% ─── Baseline calibration (common across runs) ──────────────────
setenv('HA_IE_EQ_MODE',          '2');
setenv('HA_IE_Z_PROCESS',        'ou');
setenv('HA_IE_Z_RHO',            '0.8600132622');  % Hong (2022): quarterly 0.963^4
setenv('HA_IE_Z_SD',             '0.5417411732');   % Hong (2022): 0.146/sqrt(1-0.963^2)
setenv('HA_IE_AMIN',             '-0.10');
setenv('HA_IE_VERBOSE',          '0');
setenv('HA_IE_PROFILE',          '1');
setenv('HA_IE_PSI_F',            '175');
setenv('HA_IE_PSI_I',            '50');
setenv('HA_IE_THETA',            '1.0');
setenv('HA_IE_NU_I',             '0.030');
setenv('HA_IE_SIGMA_C',          '5');
setenv('HA_IE_OMEGA_C',          '0.58');
setenv('HA_IE_A_I',              '0.305');
setenv('HA_IE_ALPHA_I',          '0.0');
setenv('HA_IE_BETA_I',           '0.6');
setenv('HA_IE_KAPPA_Z1',         '0.080');
setenv('HA_IE_KAPPA_Z_SHAPE',    '2.0');
setenv('HA_IE_DEBT_PREM_CHI',    '0.02');
setenv('HA_IE_DEBT_PREM_ETA',    '1.25');
setenv('HA_IE_DEBT_PREM_REBATE', '0');
setenv('HA_IE_INFORMAL_PROFIT_RULE', 'hours');
setenv('HA_IE_ZDRIFT_NPTS',      '25');

results = [];
run_id = 0;

%% ─── Run grid ───────────────────────────────────────────────────
for debug_flag = debug_modes
for Nz = Nz_list
    run_id = run_id + 1;
    tag = sprintf('conv_Nz%02d_%s', Nz, ternary(debug_flag,'fast','full'));
    fprintf('\n=== [%d/%d] Nz=%d, fastdebug=%d ===\n', run_id, n_runs, Nz, debug_flag);

    setenv('HA_IE_RUN_TAG', tag);
    setenv('HA_IE_OUTPUT_DIR', fullfile(pwd, 'outputs', 'convergence'));
    setenv('HA_IE_Z_N', num2str(Nz));
    setenv('HA_IE_Z_WIDTH', num2str(sqrt(Nz-1)));
    if debug_flag
        setenv('HA_IE_FAST_DEBUG', 'true');
        setenv('HA_IE_ZDRIFT_NPTS', '25');
    else
        setenv('HA_IE_FAST_DEBUG', 'false');
        setenv('HA_IE_ZDRIFT_NPTS', '80');
    end

    t_start = tic;
    try
        run_model_main;
    catch ME
        warning('Run %s failed: %s', tag, ME.message);
        results(run_id).error = ME.message;
        continue;
    end
    elapsed = toc(t_start);

    % After model clears workspace, reload results
    out_dir = fullfile(pwd, 'outputs', 'convergence', tag);
    res_file = dir(fullfile(out_dir, 'results_*.mat'));
    if isempty(res_file)
        warning('No results file found for %s', tag);
        continue;
    end
    res = load(fullfile(out_dir, res_file(1).name));

    % Extract key metrics
    if isfield(res, 'r_star')
        r_star = res.r_star;
        pI_star = res.p_I_star;
        w_F = res.w_F_star;
        w_I = res.w_I_star;
        T4 = res.T4_model;
        T5 = res.T5_model;
        Tkz = res.Tkz_model;
        L_F = res.L_F_star;
        L_I = res.L_I_star;
        S = res.S_star;
        KD = res.KD_star;
        Gini = res.Gini_wealth;
    else
        % Try calib_ file
        cal_file = dir(fullfile(out_dir, 'calib_*.mat'));
        if isempty(cal_file), continue; end
        cal = load(fullfile(out_dir, cal_file(1).name));
        r_star = cal.r_star;
        pI_star = cal.pI_star;
        T4 = cal.T4_model;
        T5 = cal.T5_model;
    end

    results(run_id).run_id    = run_id;
    results(run_id).tag       = tag;
    results(run_id).Nz        = Nz;
    results(run_id).fastdebug = debug_flag;
    results(run_id).I_grid    = ternary(debug_flag, 200, 500);
    results(run_id).elapsed_min = elapsed / 60;
    results(run_id).r_star    = r_star;
    results(run_id).pI_star   = pI_star;
    results(run_id).w_F       = w_F;
    results(run_id).w_I       = w_I;
    results(run_id).T4        = T4;
    results(run_id).T5        = T5;
    results(run_id).Tkz       = Tkz;
    results(run_id).L_F       = L_F;
    results(run_id).L_I       = L_I;
    results(run_id).S         = S;
    results(run_id).KD        = KD;
    results(run_id).Gini      = Gini;

    fprintf('  r*=%.6f, pI=%.4f, T4=%.4f, T5=%.4f, Tkz=%.4f, time=%.1f min\n', ...
        r_star, pI_star, T4, T5, Tkz, elapsed/60);
end
end

%% ─── Save and plot ──────────────────────────────────────────────
save('convergence_results.mat', 'results');
fprintf('\n=== Results saved to convergence_results.mat ===\n');

% Build table for analysis
if isempty(results), error('No successful runs.'); end
T = struct2table(results);

% Use Nz=40 (full) as reference if available
ref_rows = T.Nz == 40 & ~T.fastdebug;
if any(ref_rows)
    ref = T(ref_rows, :);
else
    ref_rows = T.Nz == max(T.Nz) & ~T.fastdebug;
    if any(ref_rows)
        ref = T(ref_rows, :);
    else
        ref = T(1, :);  % fallback
    end
end
if size(ref,1) > 1, ref = ref(1,:); end

fprintf('\n=== Reference (Nz=%d, full): r*=%.6f, pI=%.4f, T4=%.4f, T5=%.4f ===\n', ...
    ref.Nz, ref.r_star, ref.pI_star, ref.T4, ref.T5);

fprintf('\n%-6s %3s %6s %8s %8s %8s %8s %8s\n', 'Mode', 'Nz', 'I', 'r*', 'pI', 'T4', 'T5', 'min');
fprintf('%s\n', repmat('-',1,65));
for i = 1:height(T)
    fprintf('%-6s %3d %6d %8.4f %8.4f %8.4f %8.4f %8.1f\n', ...
        ternary(T.fastdebug(i),'fast','full'), T.Nz(i), T.I_grid(i), ...
        T.r_star(i), T.pI_star(i), T.T4(i), T.T5(i), T.elapsed_min(i));
end

%% ─── Convergence metrics (% error vs reference) ─────────────────
fprintf('\n=== Convergence: %% error vs Nz=%d full ===\n', ref.Nz);
fprintf('%-6s %3s %8s %8s %8s %8s\n', 'Mode', 'Nz', 'r_err%', 'pI_err%', 'T4_err%', 'T5_err%');
fprintf('%s\n', repmat('-',1,50));
for i = 1:height(T)
    if T.Nz(i) == ref.Nz && T.fastdebug(i) == ref.fastdebug, continue; end
    fprintf('%-6s %3d %8.3f %8.3f %8.3f %8.3f\n', ...
        ternary(T.fastdebug(i),'fast','full'), T.Nz(i), ...
        100*abs(T.r_star(i)-ref.r_star)/abs(ref.r_star), ...
        100*abs(T.pI_star(i)-ref.pI_star)/abs(ref.pI_star), ...
        100*abs(T.T4(i)-ref.T4)/max(abs(ref.T4),1e-6), ...
        100*abs(T.T5(i)-ref.T5)/max(abs(ref.T5),1e-6));
end

%% ─── Plot ───────────────────────────────────────────────────────
figure('Position', [100 100 1200 500]);
subplot(1,3,1);
fast_rows = T.fastdebug == true;
full_rows = T.fastdebug == false;
plot(T.Nz(full_rows), T.elapsed_min(full_rows), 'b-o', 'LineWidth', 2); hold on;
plot(T.Nz(fast_rows), T.elapsed_min(fast_rows), 'r--s', 'LineWidth', 2);
xlabel('N_z'); ylabel('Time (min)'); legend('Full (I=500)', 'Fast (I=200)');
title('Speed vs N_z'); grid on;

subplot(1,3,2);
plot(T.Nz(full_rows), T.r_star(full_rows), 'b-o', 'LineWidth', 2); hold on;
plot(T.Nz(fast_rows), T.r_star(fast_rows), 'r--s', 'LineWidth', 2);
yline(ref.r_star, 'k--');
xlabel('N_z'); ylabel('r*'); legend('Full', 'Fast', 'Ref Nz=40');
title('Interest rate convergence'); grid on;

subplot(1,3,3);
plot(T.Nz(full_rows), T.pI_star(full_rows), 'b-o', 'LineWidth', 2); hold on;
plot(T.Nz(fast_rows), T.pI_star(fast_rows), 'r--s', 'LineWidth', 2);
yline(ref.pI_star, 'k--');
xlabel('N_z'); ylabel('p_I*'); legend('Full', 'Fast', 'Ref Nz=40');
title('Informal price convergence'); grid on;

saveas(gcf, 'convergence_plot.png');
fprintf('\nPlot saved: convergence_plot.png\n');
fprintf('=== Convergence analysis complete ===\n');
end

function s = ternary(cond, t, f)
if cond, s = t; else, s = f; end
end
