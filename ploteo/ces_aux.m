function [cF, cI, exp_cons] = ces_split_from_Ceff_v10(Ceff)
global p_I omega_C eta_C sigma_C

Ceff = max(real(Ceff), 1e-12);
xi = (omega_C*p_I / max(1-omega_C, 1e-12)).^sigma_C;
Kappa = (omega_C*xi.^eta_C + (1-omega_C)).^(1/eta_C);
cI = Ceff ./ Kappa;
cF = xi .* cI;
exp_cons = cF + p_I .* cI;
end
