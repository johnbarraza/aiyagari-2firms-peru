function [dV0, cF0, cI0, c0, stats] = zero_drift_solver( ...
    a, z, w_F, w_I_hh, theta, r, ga, Frisch, psi_F, psi_I, tau, T, ...
    Pi_lump, H_bar, kappa_F_aa, qq_informal, c0_prev, slow_solver, debt_spread_aa)
%ZERO_DRIFT_GRID_FAST_V10_DEBTPREM Vectorized zero-drift solver with debt premium.
%
% CPU-first replacement for the old point-by-point loop, with
% debt_spread_aa.*max(-a,0) subtracted from household resources:
%   dV0(i,j) = solve_dV_zero_drift_v10(params_ij, dV_guess)
%
% Method control:
%   HA_IE_ZDRIFT_METHOD=auto  vectorized solve, fallback bad points (default)
%   HA_IE_ZDRIFT_METHOD=fast  vectorized solve, fallback bad points
%   HA_IE_ZDRIFT_METHOD=slow  original scalar solve for every point
%
% Tuning:
%   HA_IE_ZDRIFT_FAST_ITERS   default 6
%   HA_IE_ZDRIFT_FAST_TOL     default 1e-7 residual tolerance
%   HA_IE_ZDRIFT_FAST_MAXSTEP default 1.25 max log(dV) Newton step

global nu_I
% NOTA: Frisch_F = Frisch_I = Frisch siempre. Se usa el parametro Frisch
% directamente en todas las funciones. Los globals Frisch_F/Frisch_I
% del script principal no se usan en este archivo.

I = numel(a);
Ns = numel(z);
a = a(:);
z = z(:)';
aa = repmat(a, 1, Ns);
zz = ones(I,1) * z;
if nargin < 19 || isempty(debt_spread_aa)
    debt_spread_aa = zeros(I, Ns);
end

method = lower(strtrim(getenv('HA_IE_ZDRIFT_METHOD')));
if isempty(method), method = 'auto'; end
if ~ismember(method, {'auto','fast','slow'})
    method = 'auto';
end

if nargin < 18 || isempty(slow_solver)
    error('zero_drift_solver requires a slow_solver function handle.');
end

dV_guess = initial_guess(a, z, w_F, w_I_hh, theta, r, ga, tau, T, Pi_lump, ...
    kappa_F_aa, qq_informal, c0_prev, I, Ns, debt_spread_aa);

stats = struct('method', method, 'fallback_count', 0, 'total_count', I*Ns, ...
    'max_abs_resid', NaN, 'fast_iters', 0);

if strcmp(method, 'slow')
    [dV0, cF0, cI0, c0, fallback_count] = slow_grid(a, z, w_F, w_I_hh, theta, r, ...
        ga, Frisch, psi_F, psi_I, tau, T, Pi_lump, H_bar, kappa_F_aa, ...
        qq_informal, dV_guess, slow_solver, debt_spread_aa);
    stats.fallback_count = fallback_count;
    stats.max_abs_resid = NaN;
    return;
end

fast_iters = str2double(getenv('HA_IE_ZDRIFT_FAST_ITERS'));
fast_debug = any(strcmp(lower(strtrim(getenv('HA_IE_FAST_DEBUG'))), {'1','true','yes','on'}));
if ~isfinite(fast_iters) || fast_iters < 1
    if fast_debug
        fast_iters = 4;
    else
        fast_iters = 6;
    end
end
fast_iters = round(fast_iters);

tol_resid = str2double(getenv('HA_IE_ZDRIFT_FAST_TOL'));
if ~isfinite(tol_resid) || tol_resid <= 0
    if fast_debug
        tol_resid = 1e-6;
    else
        tol_resid = 1e-7;
    end
end

max_step = str2double(getenv('HA_IE_ZDRIFT_FAST_MAXSTEP'));
if ~isfinite(max_step) || max_step <= 0
    if fast_debug
        max_step = 1.5;
    else
        max_step = 1.25;
    end
end

x = log(max(dV_guess, 1e-12));
h = 1e-4;

for iter = 1:fast_iters
    dV = exp(x);
    [resid, ~, ~, ~, exp_cons] = residual_grid(dV, aa, zz, w_F, w_I_hh, theta, ...
        r, ga, Frisch, psi_F, psi_I, tau, T, Pi_lump, H_bar, kappa_F_aa, qq_informal, debt_spread_aa);
    scale = max(1, abs(exp_cons));
    active = isfinite(resid) & abs(resid) > tol_resid .* scale;
    if ~any(active(:))
        break;
    end

    dV_hi = exp(x + h);
    [resid_hi, ~, ~, ~, ~] = residual_grid(dV_hi, aa, zz, w_F, w_I_hh, theta, ...
        r, ga, Frisch, psi_F, psi_I, tau, T, Pi_lump, H_bar, kappa_F_aa, qq_informal, debt_spread_aa);
    deriv = (resid_hi - resid) / h;

    dx = -resid ./ deriv;
    good_step = active & isfinite(dx) & isfinite(deriv) & abs(deriv) > 1e-12;
    dx = max(min(dx, max_step), -max_step);
    x(good_step) = x(good_step) + dx(good_step);
    x = max(min(x, 40), -40);
end

dV0 = exp(x);
[resid, cF0, cI0, c0, exp_cons] = residual_grid(dV0, aa, zz, w_F, w_I_hh, theta, ...
    r, ga, Frisch, psi_F, psi_I, tau, T, Pi_lump, H_bar, kappa_F_aa, qq_informal, debt_spread_aa);

scale = max(1, abs(exp_cons));
bad = ~isfinite(dV0) | ~isfinite(resid) | abs(resid) > tol_resid .* scale;
stats.fast_iters = iter;
stats.max_abs_resid = max(abs(resid(isfinite(resid))), [], 'all');
if isempty(stats.max_abs_resid), stats.max_abs_resid = NaN; end

% Robustness: the vectorized solve should be fast for most points, but the
% original scalar method remains the authority for difficult points.
if any(bad(:))
    [dV0, cF0, cI0, c0, fallback_count] = fallback_bad_points(dV0, cF0, cI0, c0, ...
        bad, a, z, w_F, w_I_hh, theta, r, ga, Frisch, psi_F, psi_I, tau, T, ...
        Pi_lump, H_bar, kappa_F_aa, qq_informal, dV_guess, slow_solver, debt_spread_aa);
    stats.fallback_count = fallback_count;
end
end

function dV_guess = initial_guess(a, z, w_F, w_I_hh, theta, r, ga, tau, T, Pi_lump, ...
    kappa_F_aa, qq_informal, c0_prev, I, Ns, debt_spread_aa)
global nu_I

if ~isempty(c0_prev) && isequal(size(c0_prev), [I, Ns])
    dV_guess = max(real(c0_prev), 1e-8).^(-ga);
    return;
end

dV_guess = zeros(I, Ns);
for j = 1:Ns
    zI_j = z(j)^nu_I;
    income_guess = (1-tau)*w_F*z(j)*0.5 - kappa_F_aa(:,j)*0.5 ...
        + w_I_hh*theta*zI_j*qq_informal(:,j)*0.5 ...
        + r*a - debt_spread_aa(:,j).*max(-a,0) + T + Pi_lump;
    dV_guess(:,j) = max(income_guess, 1e-8).^(-ga);
end
end

function [resid, cF, cI, Ceff, exp_cons] = residual_grid(dV, aa, zz, w_F, w_I_hh, ...
    theta, r, ga, Frisch, psi_F, psi_I, tau, T, Pi_lump, H_bar, kappa_F_aa, qq_informal, debt_spread_aa)
global nu_I

dV = max(real(dV), 1e-12);
eff_wF = (1-tau)*w_F*zz - kappa_F_aa;
wI_inf = w_I_hh * theta * (zz.^nu_I) .* qq_informal;

ell_F_unc = max(dV .* eff_wF / psi_F, 0).^Frisch;
ell_I_unc = max(dV .* wI_inf / psi_I, 0).^Frisch;
ell_F = ell_F_unc;
ell_I = ell_I_unc;

if isfinite(H_bar)
    binding = (ell_F_unc + ell_I_unc) > H_bar;
    if any(binding(:))
        g_lo = -psi_I * H_bar^(1/Frisch);
        g_hi =  psi_F * H_bar^(1/Frisch);
        RHS = dV .* (eff_wF - wI_inf);

        ell_F(binding & RHS <= g_lo) = 0;
        ell_I(binding & RHS <= g_lo) = H_bar;
        ell_F(binding & RHS >= g_hi) = H_bar;
        ell_I(binding & RHS >= g_hi) = 0;

        interior = binding & RHS > g_lo & RHS < g_hi;
        if any(interior(:))
            lo = zeros(size(dV));
            hi = H_bar * ones(size(dV));
            RHS_int = RHS;
            for kb = 1:60
                mid = 0.5 * (lo + hi);
                fm = psi_F*mid.^(1/Frisch) - psi_I*(H_bar-mid).^(1/Frisch) - RHS_int;
                move_lo = interior & fm < 0;
                move_hi = interior & fm >= 0;
                lo(move_lo) = mid(move_lo);
                hi(move_hi) = mid(move_hi);
            end
            ell_F(interior) = 0.5 * (lo(interior) + hi(interior));
            ell_I(interior) = H_bar - ell_F(interior);
        end
    end
end

[cF, cI, Ceff, exp_cons] = ces_from_dV(dV, ga);
resid = eff_wF.*ell_F + wI_inf.*ell_I + r*aa ...
    - debt_spread_aa.*max(-aa,0) + T + Pi_lump - exp_cons;
end

function [cF, cI, Ceff, exp_cons] = ces_from_dV(dV, ga)
global p_I omega_C eta_C sigma_C

dV = max(real(dV), 1e-12);
xi = (omega_C*p_I / max(1-omega_C, 1e-12)).^sigma_C;
Kappa = (omega_C*xi.^eta_C + (1-omega_C)).^(1/eta_C);
M = omega_C * xi.^(eta_C-1) * Kappa.^(1-eta_C);

Ceff = (M ./ dV).^(1/ga);
cI = Ceff ./ Kappa;
cF = xi .* cI;
exp_cons = cF + p_I .* cI;

if abs(eta_C) > 1e-10
    A_F = omega_C.^(1/eta_C);
    A_Ionly = max(1-omega_C, 1e-12).^(1/eta_C);

    cF_only = (A_F.^(1-ga) ./ dV).^(1/ga);
    C_Fonly = A_F .* cF_only;
    exp_Fonly = cF_only;

    cI_only = (A_Ionly.^(1-ga) ./ max(dV * p_I, 1e-12)).^(1/ga);
    C_Ionly = A_Ionly .* cI_only;
    exp_Ionly = p_I .* cI_only;

    obj_int = Ceff.^(1-ga)/(1-ga) - dV .* exp_cons;
    obj_Fonly = C_Fonly.^(1-ga)/(1-ga) - dV .* exp_Fonly;
    obj_Ionly = C_Ionly.^(1-ga)/(1-ga) - dV .* exp_Ionly;

    use_F = obj_Fonly > obj_int & obj_Fonly >= obj_Ionly;
    use_I = obj_Ionly > obj_int & obj_Ionly > obj_Fonly;

    cF(use_F) = cF_only(use_F);
    cI(use_F) = 0;
    Ceff(use_F) = C_Fonly(use_F);
    exp_cons(use_F) = exp_Fonly(use_F);

    cF(use_I) = 0;
    cI(use_I) = cI_only(use_I);
    Ceff(use_I) = C_Ionly(use_I);
    exp_cons(use_I) = exp_Ionly(use_I);
end

cF = max(real(cF), 0);
cI = max(real(cI), 0);
Ceff = max(real(Ceff), 1e-12);
exp_cons = max(real(exp_cons), 1e-12);
end

function [dV0, cF0, cI0, c0, count] = slow_grid(a, z, w_F, w_I_hh, theta, r, ...
    ga, Frisch, psi_F, psi_I, tau, T, Pi_lump, H_bar, kappa_F_aa, ...
    qq_informal, dV_guess, slow_solver, debt_spread_aa)
global nu_I

I = numel(a);
Ns = numel(z);
dV0 = zeros(I, Ns);
cF0 = zeros(I, Ns);
cI0 = zeros(I, Ns);
c0 = zeros(I, Ns);
count = I * Ns;

for j = 1:Ns
    for i = 1:I
        params_ij = [a(i), z(j), w_F, w_I_hh, theta, r, ga, Frisch, psi_F, psi_I, ...
            tau, T, Pi_lump, H_bar, kappa_F_aa(i,j), qq_informal(i,j), debt_spread_aa(i,j)];
        dV0(i,j) = slow_solver(params_ij, dV_guess(i,j));
        [cF0(i,j), cI0(i,j), c0(i,j), ~] = ces_from_dV(dV0(i,j), ga);
    end
end
end

function [dV0, cF0, cI0, c0, count] = fallback_bad_points(dV0, cF0, cI0, c0, ...
    bad, a, z, w_F, w_I_hh, theta, r, ga, Frisch, psi_F, psi_I, tau, T, ...
    Pi_lump, H_bar, kappa_F_aa, qq_informal, dV_guess, slow_solver, debt_spread_aa)

[ii, jj] = find(bad);
count = numel(ii);
for k = 1:count
    i = ii(k);
    j = jj(k);
    params_ij = [a(i), z(j), w_F, w_I_hh, theta, r, ga, Frisch, psi_F, psi_I, ...
        tau, T, Pi_lump, H_bar, kappa_F_aa(i,j), qq_informal(i,j), debt_spread_aa(i,j)];
    dV0(i,j) = slow_solver(params_ij, dV_guess(i,j));
    [cF0(i,j), cI0(i,j), c0(i,j), ~] = ces_from_dV(dV0(i,j), ga);
end
end
