function results = run_nz_tests(mode)
% RUN_NZ_TESTS selecciona la grilla de productividad en dos etapas.
%
%   run_nz_tests('grid')
%       Prueba solo el generador OU. Tarda segundos y escribe la tabla de
%       momentos de la grilla.
%
%   run_nz_tests('equilibrium')
%       Corre el equilibrio con la calibracion final para el benchmark
%       original y dos grillas con dispersion corregida. Puede tardar horas.
%
%   run_nz_tests('report')
%       Carga las corridas disponibles y vuelve a escribir la comparacion.

if nargin < 1 || isempty(mode)
    mode = 'grid';
end
mode = lower(string(mode));

script_dir = fileparts(mfilename('fullpath'));
repo_dir = fileparts(script_dir);
out_dir = fullfile(repo_dir, 'outputs', 'nz_selection');
if ~isfolder(out_dir), mkdir(out_dir); end

switch mode
    case "grid"
        results = grid_diagnostic(out_dir);
    case "equilibrium"
        grid_diagnostic(out_dir);
        results = equilibrium_sweep(repo_dir, out_dir, true);
    case "report"
        results = equilibrium_sweep(repo_dir, out_dir, false);
    otherwise
        error('Modo invalido. Use grid, equilibrium o report.');
end
end

function results = grid_diagnostic(out_dir)
nz_values = [20 30 40 60 80 120];
rho_z = 0.861;
sd_target = 0.544;

n = numel(nz_values);
results = table('Size',[n 9], ...
    'VariableTypes', repmat({'double'},1,9), ...
    'VariableNames', {'Nz','width','sd_logz','sd_error_pct','gini_z', ...
    'z_p05','z_p50','z_p95','nnz_Q'});

for i = 1:n
    nz = nz_values(i);
    width = match_width(nz, rho_z, sd_target);
    [x,Q,pi] = ou_grid(nz, rho_z, sd_target, width);
    z = exp(x);
    z = z / sum(pi .* z);
    mu_x = sum(pi .* x);
    sd_x = sqrt(sum(pi .* (x-mu_x).^2));
    results{i,:} = [nz, width, sd_x, 100*(sd_x/sd_target-1), ...
        weighted_gini(z,pi), weighted_quantile(z,pi,0.05), ...
        weighted_quantile(z,pi,0.50), weighted_quantile(z,pi,0.95), nnz(Q)];
end

ref = results(end,:);
results.gini_error_pct = 100*(results.gini_z/ref.gini_z-1);
results.p95_error_pct = 100*(results.z_p95/ref.z_p95-1);
writetable(results, fullfile(out_dir,'nz_grid_diagnostic.csv'));
save(fullfile(out_dir,'nz_grid_diagnostic.mat'),'results');

disp(results);
eligible = find(abs(results.gini_error_pct) <= 0.2 & ...
    abs(results.p95_error_pct) <= 2.0, 1, 'first');
if isempty(eligible)
    fprintf('La prueba de grilla no selecciona un Nz. Amplie los candidatos.\n');
else
    fprintf('Candidato minimo de la prueba de grilla, Nz=%d.\n', results.Nz(eligible));
    fprintf('La decision final requiere comparar los equilibrios de Nz=40 y Nz=60.\n');
end
end

function results = equilibrium_sweep(repo_dir, out_dir, run_missing)
configs = {
    'baseline_Nz40_w2500', 40, '2.5';
    'corrected_Nz40_auto', 40, 'auto';
    'corrected_Nz60_auto', 60, 'auto'
};

n = size(configs,1);
rows = repmat(struct('config','', 'Nz',NaN, 'width',NaN, 'sd_logz',NaN, ...
    'elapsed_min',NaN, 'r_star',NaN, 'p_I',NaN, 'T4',NaN, 'T5',NaN, ...
    'Tkz',NaN, 'Tgasto',NaN, 'T6',NaN),n,1);

for i = 1:n
    tag = ['nztest_' configs{i,1}];
    result_file = fullfile(repo_dir,'outputs','stationary',tag, ...
        ['results_' tag '.mat']);
    if i == 1 && ~isfile(result_file)
        closing_file = fullfile(repo_dir,'outputs','stationary', ...
            'test_AI098_cierre','results_test_AI098_cierre.mat');
        if isfile(closing_file), result_file = closing_file; end
    end
    if ~isfile(result_file) && run_missing
        set_final_environment(configs{i,2}, configs{i,3}, tag);
        model_file = fullfile(repo_dir,'model_main.m');
        fprintf('Corriendo %s.\n', configs{i,1});
        evalin('base', sprintf("run('%s')", strrep(model_file,"'","''")));
    end
    if ~isfile(result_file)
        fprintf('Falta %s.\n', result_file);
        continue;
    end
    s = load(result_file);
    rows(i).config = configs{i,1};
    rows(i).Nz = configs{i,2};
    rows(i).width = getfield_safe(s,'width_z_ar');
    rows(i).sd_logz = getfield_safe(s,'sd_logz_realizada');
    rows(i).elapsed_min = get_elapsed(s)/60;
    rows(i).r_star = getfield_safe(s,'r_star');
    rows(i).p_I = getfield_safe(s,'p_I_star');
    rows(i).T4 = getfield_safe(s,'T4_model');
    rows(i).T5 = getfield_safe(s,'T5_nom');
    rows(i).Tkz = getfield_safe(s,'T_kappa_z_model');
    rows(i).Tgasto = getfield_safe(s,'Tgasto_tipo');
    rows(i).T6 = getfield_safe(s,'T6_model');
end

results = struct2table(rows);
writetable(results, fullfile(out_dir,'nz_equilibrium_comparison.csv'));
save(fullfile(out_dir,'nz_equilibrium_comparison.mat'),'results');
disp(results);

valid = isfinite(results.T4);
if sum(valid) >= 2
    ref_idx = find(valid,1,'last');
    moment_names = {'r_star','p_I','T4','T5','Tkz','Tgasto','T6'};
    fprintf('Cambios porcentuales frente a %s.\n', results.config{ref_idx});
    for j = 1:numel(moment_names)
        name = moment_names{j};
        values = results.(name);
        change = 100*(values/values(ref_idx)-1);
        fprintf('%-10s',name);
        fprintf(' %9.3f',change);
        fprintf('\n');
    end
end
end

function set_final_environment(nz,width,tag)
setenv('HA_IE_RUN_TAG',tag);
setenv('HA_IE_EQ_MODE','2');
setenv('HA_IE_FAST_DEBUG','true');
setenv('HA_IE_VERBOSE','0');
setenv('HA_IE_PROFILE','false');
setenv('HA_IE_I','200');
setenv('HA_IE_AMIN','-1.0');
setenv('HA_IE_AMAX','20');
setenv('HA_IE_R_LO','-0.04');
setenv('HA_IE_R_HI','0.20');
setenv('HA_IE_ZDRIFT_NPTS','25');
setenv('HA_IE_Z_PROCESS','ou');
setenv('HA_IE_Z_N',num2str(nz));
setenv('HA_IE_Z_RHO','0.861');
setenv('HA_IE_Z_SD','0.544');
setenv('HA_IE_Z_WIDTH',width);
setenv('HA_IE_RHO','0.073');
setenv('HA_IE_GA','1');
setenv('HA_IE_FRISCH','0.38');
setenv('HA_IE_PSI_F','55');
setenv('HA_IE_PSI_I','34');
setenv('HA_IE_A_F','1');
setenv('HA_IE_A_I','0.98');
setenv('HA_IE_ALPHA_I','0.220');
setenv('HA_IE_BETA_I','0.619');
setenv('HA_IE_THETA','1');
setenv('HA_IE_NU_I','0.6');
setenv('HA_IE_OMEGA_C','0.56');
setenv('HA_IE_SIGMA_C','5');
setenv('HA_IE_KAPPA_Z1','0.40');
setenv('HA_IE_KAPPA_Z_SHAPE','1');
setenv('HA_IE_DEBT_PREM_CHI','0.02');
setenv('HA_IE_DEBT_PREM_ETA','1');
setenv('HA_IE_DEBT_PREM_REBATE','0');
setenv('HA_IE_INFORMAL_PROFIT_RULE','hours');
setenv('HA_IE_T4_DATA','0.509');
setenv('HA_IE_T5_DATA','0.190');
setenv('HA_IE_TKZ_DATA','0.386');
setenv('HA_IE_TGASTO_TIPO_DATA','1.913');
end

function width = match_width(nz,rho_z,sd_target)
lo = 1; hi = 6;
for i = 1:80
    mid = (lo+hi)/2;
    [x,~,pi] = ou_grid(nz,rho_z,sd_target,mid);
    mu = sum(pi.*x);
    sd_now = sqrt(sum(pi.*(x-mu).^2));
    if sd_now < sd_target, lo = mid; else, hi = mid; end
end
width = (lo+hi)/2;
end

function [x,Q,pi] = ou_grid(nz,rho_z,sd_target,width)
eta = -log(rho_z);
x = linspace(-width*sd_target,width*sd_target,nz);
dx = x(2)-x(1);
drift = -eta*x;
half_diffusion = eta*sd_target^2/dx^2;
lower_rate = -min(drift,0)/dx + half_diffusion;
upper_rate = max(drift,0)/dx + half_diffusion;
center = min(drift,0)/dx-max(drift,0)/dx-2*half_diffusion;
lower = zeros(nz,1); upper = zeros(nz,1);
lower(1:nz-1) = lower_rate(2:nz);
upper(2:nz) = upper_rate(1:nz-1);
center(1) = center(1)+lower_rate(1);
center(nz) = center(nz)+upper_rate(nz);
Q = spdiags([lower center(:) upper],[-1 0 1],nz,nz);
Q = Q-spdiags(full(sum(Q,2)),0,nz,nz);
A = [Q';ones(1,nz)];
b = [zeros(nz,1);1];
pi = max(real(A\b),0)';
pi = pi/sum(pi);
end

function value = weighted_quantile(x,w,p)
x = x(:);
w = w(:);
[x,idx] = sort(x);
w = w(idx);
cw = cumsum(w)/sum(w);
value = x(find(cw>=p,1,'first'));
end

function value = weighted_gini(x,w)
x = x(:);
w = w(:);
[x,idx] = sort(x);
w = w(idx);
w = w/sum(w);
income = w.*x;
cum_w = [0;cumsum(w)];
cum_income = [0;cumsum(income)/sum(income)];
value = 1-sum((cum_income(2:end)+cum_income(1:end-1)).*diff(cum_w));
end

function value = getfield_safe(s,name)
if isfield(s,name) && isscalar(s.(name)), value=s.(name); else, value=NaN; end
end

function elapsed = get_elapsed(s)
elapsed = NaN;
if isfield(s,'total_elapsed') && isscalar(s.total_elapsed)
    elapsed = s.total_elapsed;
elseif isfield(s,'HA_IE_TIMINGS') && isfield(s.HA_IE_TIMINGS,'solve_given_prices')
    elapsed = s.HA_IE_TIMINGS.solve_given_prices.time;
end
end
