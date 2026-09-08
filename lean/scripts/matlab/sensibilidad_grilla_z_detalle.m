rho = 0.861; sd_t = 0.544; mu = 0.0; dt = 1;
ncdf = @(x) 0.5*(1+erf(x/sqrt(2)));
npdf = @(x) exp(-x.^2/2)/sqrt(2*pi);

fprintf('=== D. referencias analiticas de la log-normal exacta ===\n');
fprintf('E[z] sin normalizar = exp(sd^2/2)      = %.6f\n', exp(sd_t^2/2));
fprintf('Gini exacto log-normal = 2*Phi(sd/r2)-1 = %.6f\n', 2*ncdf(sd_t/sqrt(2))-1);
fprintf('sd de normal truncada en +-w*sd (fraccion de sd, y sd efectiva):\n');
for w = [2.0 2.5 3.0 3.5 4.0 5.0]
    v = 1 - 2*w*npdf(w)/(2*ncdf(w)-1);
    fprintf('  w=%.1f -> %.4f  ->  %.4f\n', w, sqrt(v), sd_t*sqrt(v));
end

fprintf('\n=== E. limite Nz -> inf por ancho de grilla ===\n');
fprintf('%6s %10s %10s %10s\n','width','Nz=120','Nz=200','%% objetivo');
for w = [2.0 2.5 3.0 3.5 4.0]
    s120 = sd_of(120, rho, sd_t, w, mu, dt);
    s200 = sd_of(200, rho, sd_t, w, mu, dt);
    fprintf('%6.1f %10.4f %10.4f %9.2f%%\n', w, s120, s200, 100*s200/sd_t);
end

fprintf('\n=== F. ancho que calza el objetivo, por Nz ===\n');
fprintf('%6s %12s %12s\n','Nz','width*','sd lograda');
for N = [20 30 40 60 80]
    lo = 2.0; hi = 4.5;
    for it = 1:60
        md = (lo+hi)/2;
        if sd_of(N, rho, sd_t, md, mu, dt) < sd_t, lo = md; else, hi = md; end
    end
    ws = (lo+hi)/2;
    fprintf('%6d %12.4f %12.6f\n', N, ws, sd_of(N, rho, sd_t, ws, mu, dt));
end

fprintf('\n=== G. si prefieres NO tocar la grilla (Nz=40, w=2.5):\n');
fprintf('    que sd_logz_ar hay que ingresar para que la realizada sea %.4f?\n', sd_t);
lo = 0.4; hi = 0.9;
for it = 1:80
    md = (lo+hi)/2;
    if sd_of(40, rho, md, 2.5, mu, dt) < sd_t, lo = md; else, hi = md; end
end
sd_in = (lo+hi)/2;
fprintf('    sd_logz_ar = %.6f   (realizada = %.6f)\n', sd_in, sd_of(40, rho, sd_in, 2.5, mu, dt));
fprintf('    ojo: esto calza el segundo momento pero deja el soporte truncado en +-%.3f\n', 2.5*sd_in);

fprintf('\n=== H. Gini de z en las opciones relevantes ===\n');
fprintf('exacto log-normal                : %.6f\n', 2*ncdf(sd_t/sqrt(2))-1);
cfgs = {{40,2.5,sd_t,'actual Nz=40 w=2.5'}, {40,3.0,sd_t,'Nz=40 w=3.0'}, ...
        {60,3.0,sd_t,'Nz=60 w=3.0'}, {40,2.5,sd_in,'Nz=40 w=2.5 con sd ajustada'}};
for k = 1:numel(cfgs)
    c = cfgs{k};
    [x,~,pi] = ou_grid(c{1}, rho, c{3}, c{2}, mu, dt);
    z = exp(x(:)); z = z/sum(pi(:).*z);
    m = sum(pi(:).*x(:)); s = sqrt(sum(pi(:).*(x(:)-m).^2));
    fprintf('%-32s : Gini=%.6f  sd=%.6f  z in [%.3f, %.3f]\n', ...
        c{4}, gini_disc(z, pi(:)), s, min(z), max(z));
end

function s = sd_of(N, rho, sd_u, w, mu, dt)
[x,~,pi] = ou_grid(N, rho, sd_u, w, mu, dt);
m = sum(pi(:).*x(:));
s = sqrt(sum(pi(:).*(x(:)-m).^2));
end

function [x, Q, pi] = ou_grid(N, rho_z, sd_uncond, width_mult, mu_uncond, dt)
eta = -log(rho_z) / dt;
xmax = width_mult * sd_uncond;
x = linspace(mu_uncond - xmax, mu_uncond + xmax, N);
dx = x(2) - x(1); dx2 = dx^2;
mu = eta * (mu_uncond - x);
variance_coeff = 2 * eta * sd_uncond^2;
diff_half = variance_coeff / (2 * dx2);
chi = -min(mu, 0) / dx + diff_half;
yy = min(mu, 0) / dx - max(mu, 0) / dx - 2 * diff_half;
zeta = max(mu, 0) / dx + diff_half;
lower = zeros(N,1); center = yy(:); upper = zeros(N,1);
lower(1:N-1) = chi(2:N); upper(2:N) = zeta(1:N-1);
center(1) = center(1) + chi(1); center(N) = center(N) + zeta(N);
Q = spdiags([lower, center, upper], [-1,0,1], N, N);
rs = full(sum(Q,2));
if max(abs(rs)) > 1e-10, Q = Q - spdiags(rs, 0, N, N); end
A = [Q'; ones(1,N)]; b = [zeros(N,1); 1];
pic = A\b; pic = max(real(pic),0);
pi = (pic/max(sum(pic),1e-12))';
end

function g = gini_disc(v, w)
[vs, idx] = sort(v(:)); ws = w(:); ws = ws(idx);
cw = cumsum(ws); cv = cumsum(vs.*ws); cv = cv/cv(end);
g = 1 - 2*trapz([0; cw], [0; cv]);
end
