% Sensibilidad de la discretizacion del proceso de productividad.
% Replica exactamente ou_ar1_generator_grid de model_main.m y mide cuanta
% dispersion pierde la grilla respecto del objetivo de calibracion.

rho   = 0.861;
sd_t  = 0.544;     % objetivo de calibracion (Hong 2022, ENAHO)
mu    = 0.0;
dt    = 1;

Nz_list    = [7 14 20 30 40 60 80 120];
width_list = [2.0 2.5 3.0 3.5 4.0 5.0];

fprintf('Objetivo: sd(log z) = %.4f, rho = %.3f\n\n', sd_t, rho);
fprintf('=== A. sd(log z) realizada bajo la distribucion ergodica ===\n');
fprintf('%6s', 'Nz\\w');
for w = width_list, fprintf('%9.1f', w); end
fprintf('\n');
SD = nan(numel(Nz_list), numel(width_list));
EZ = nan(numel(Nz_list), numel(width_list));
GI = nan(numel(Nz_list), numel(width_list));
for i = 1:numel(Nz_list)
    fprintf('%6d', Nz_list(i));
    for j = 1:numel(width_list)
        [x, Q, pi] = ou_grid(Nz_list(i), rho, sd_t, width_list(j), mu, dt);
        m  = sum(pi(:).*x(:));
        sd = sqrt(sum(pi(:).*(x(:)-m).^2));
        SD(i,j) = sd;
        zr = exp(x(:));
        EZ(i,j) = sum(pi(:).*zr);
        z  = zr / EZ(i,j);
        GI(i,j) = gini_disc(z, pi(:));
        fprintf('%9.4f', sd);
    end
    fprintf('\n');
end

fprintf('\n=== B. porcentaje del objetivo alcanzado ===\n');
fprintf('%6s', 'Nz\\w');
for w = width_list, fprintf('%9.1f', w); end
fprintf('\n');
for i = 1:numel(Nz_list)
    fprintf('%6d', Nz_list(i));
    for j = 1:numel(width_list)
        fprintf('%8.2f%%', 100*SD(i,j)/sd_t);
    end
    fprintf('\n');
end

fprintf('\n=== C. Gini de z tras normalizar E[z]=1 ===\n');
fprintf('%6s', 'Nz\\w');
for w = width_list, fprintf('%9.1f', w); end
fprintf('\n');
for i = 1:numel(Nz_list)
    fprintf('%6d', Nz_list(i));
    for j = 1:numel(width_list)
        fprintf('%9.4f', GI(i,j));
    end
    fprintf('\n');
end

% Referencia analitica: log-normal exacta
fprintf('\n=== D. referencias analiticas de la log-normal exacta ===\n');
fprintf('E[z] sin normalizar  = exp(sd^2/2) = %.6f\n', exp(sd_t^2/2));
fprintf('Gini exacto de una log-normal      = 2*Phi(sd/sqrt(2)) - 1 = %.6f\n', ...
    2*normcdf(sd_t/sqrt(2)) - 1);
fprintf('sd de una normal truncada en +-w*sd, como fraccion de sd:\n');
for w = width_list
    v = 1 - 2*w*normpdf(w)/(2*normcdf(w)-1);
    fprintf('  w=%.1f -> %.4f  (sd efectiva %.4f)\n', w, sqrt(v), sd_t*sqrt(v));
end

fprintf('\n=== E. configuracion actual del paquete (Nz=40, w=2.5) ===\n');
[x0, Q0, pi0] = ou_grid(40, rho, sd_t, 2.5, mu, dt);
m0 = sum(pi0(:).*x0(:));
sd0 = sqrt(sum(pi0(:).*(x0(:)-m0).^2));
z0 = exp(x0(:)); z0 = z0/sum(pi0(:).*z0);
fprintf('sd(log z) = %.6f  (%.2f%% del objetivo)\n', sd0, 100*sd0/sd_t);
fprintf('Gini(z)   = %.6f  vs log-normal exacta %.6f\n', ...
    gini_disc(z0, pi0(:)), 2*normcdf(sd_t/sqrt(2))-1);
fprintf('rango z   = [%.4f, %.4f]\n', min(z0), max(z0));
fprintf('masa en los dos nodos extremos: %.4f%% y %.4f%%\n', 100*pi0(1), 100*pi0(end));
fprintf('max |suma de fila de Q| = %.3e\n', max(abs(full(sum(Q0,2)))));

% ---------- helpers (copiados de model_main.m) ----------
function [x, Q, pi] = ou_grid(N, rho_z, sd_uncond, width_mult, mu_uncond, dt)
eta = -log(rho_z) / dt;
xmax = width_mult * sd_uncond;
x = linspace(mu_uncond - xmax, mu_uncond + xmax, N);
dx = x(2) - x(1);
dx2 = dx^2;
mu = eta * (mu_uncond - x);
variance_coeff = 2 * eta * sd_uncond^2;
diff_half = variance_coeff / (2 * dx2);
chi = -min(mu, 0) / dx + diff_half;
yy = min(mu, 0) / dx - max(mu, 0) / dx - 2 * diff_half;
zeta = max(mu, 0) / dx + diff_half;
lower = zeros(N, 1); center = yy(:); upper = zeros(N, 1);
lower(1:N-1) = chi(2:N);
upper(2:N) = zeta(1:N-1);
center(1) = center(1) + chi(1);
center(N) = center(N) + zeta(N);
Q = spdiags([lower, center, upper], [-1, 0, 1], N, N);
row_sums = full(sum(Q, 2));
if max(abs(row_sums)) > 1e-10
    Q = Q - spdiags(row_sums, 0, N, N);
end
A = [Q'; ones(1, N)];
b = [zeros(N, 1); 1];
pic = A \ b;
pic = max(real(pic), 0);
pi = (pic / max(sum(pic), 1e-12))';
end

function g = gini_disc(v, w)
[vs, idx] = sort(v(:));
ws = w(:); ws = ws(idx);
cw = cumsum(ws);
cv = cumsum(vs.*ws);
cv = cv / cv(end);
g = 1 - 2*trapz([0; cw], [0; cv]);
end
