f = 'C:\Users\johnb\Documents\GitHub\HA-IE2025\Code\CONTINUOUS_TIME\Aiyagari_firmas\try_endog_labor_2_firms\replication_package\outputs\stationary\test_AI098_cierre\results_test_AI098_cierre.mat';
S = load(f);

fprintf('=====================================================\n');
fprintf(' A. RESIDUAL DE WALRAS DEL BIEN FORMAL\n');
fprintf('=====================================================\n');
KappaCost = S.da * sum(sum(S.kappa_F_aa .* S.ell_F .* S.g));
DP = S.DebtPremPayments;

fprintf('Y_F                = %.8f\n', S.Y_F);
fprintf('C_F_agg            = %.8f\n', S.C_F_agg);
fprintf('delta*K            = %.8f   (delta=%.4f, K=%.6f = K_F %.6f + K_I %.6f)\n', ...
    S.d*S.K_star, S.d, S.K_star, S.K_F_star, S.K_I_star);
fprintf('KappaCost          = %.8f   (recalculado de kappa_F_aa, ell_F, g)\n', KappaCost);
fprintf('DebtPremPayments   = %.8f\n', DP);
fprintf('debt_prem_rebate   = %d\n\n', S.debt_prem_rebate);

orig = Y_res(S.Y_F, S.C_F_agg, S.d*S.K_star, KappaCost, 0);
corr = Y_res(S.Y_F, S.C_F_agg, S.d*S.K_star, KappaCost, DP);
fprintf('residual ACTUAL del codigo   |Y_F - C_F - dK - Kappa|      = %.6e\n', orig);
fprintf('residual CORREGIDO           |Y_F - C_F - dK - Kappa - DP| = %.6e\n', corr);
fprintf('walras_err guardado                                        = %.6e\n', S.walras_err);
fprintf('DP como %% de Y_F: %.5f%%   | Kappa como %% de Y_F: %.4f%%\n', ...
    100*DP/S.Y_F, 100*KappaCost/S.Y_F);
if corr < orig
    fprintf('=> la correccion REDUCE el residual (factor %.2fx)\n\n', orig/max(corr,eps));
else
    fprintf('=> la correccion AUMENTA el residual (factor %.2fx)\n\n', corr/max(orig,eps));
end

fprintf('Version impresa en el anexo |Y_F - C_F - d*K_F - DP| = %.6e\n\n', ...
    abs(S.Y_F - S.C_F_agg - S.d*S.K_F_star - DP));

fprintf('=====================================================\n');
fprintf(' B. CRUCE DE LOS TEOREMAS LEAN CONTRA LA CORRIDA\n');
fprintf('=====================================================\n');

% B6: ratio de canasta homotetico  (omega/(1-omega))^sigma * p_I^(sigma-1)
pred_basket = (S.omega_C/(1-S.omega_C))^S.sigma_C * S.p_I_star^(S.sigma_C-1);
fprintf('B6 canasta CES: predicho = %.6f | TgFI_canasta guardado = %.6f | dif = %.3e\n', ...
    pred_basket, S.TgFI_canasta, abs(pred_basket - S.TgFI_canasta));

% T7: Pi_I = (1 - alpha_I - beta_I) * p_I * Y_I
pred_Pi = (1 - S.alpha_I - S.beta_I) * S.p_I_star * S.Y_I;
fprintf('T7 beneficio informal: predicho = %.6f | profit_I_star = %.6f | dif = %.3e\n', ...
    pred_Pi, S.profit_I_star, abs(pred_Pi - S.profit_I_star));

% T6: w_F = (1-alpha)*A_F*k^alpha con k = (alpha*A_F/(r+delta))^(1/(1-alpha))
k_pred = (S.al*S.A_F/(S.r_star+S.d))^(1/(1-S.al));
wF_pred = (1-S.al)*S.A_F*k_pred^S.al;
fprintf('T6 salario formal: predicho = %.6f | w_F_star = %.6f | dif = %.3e\n', ...
    wF_pred, S.w_F_star, abs(wF_pred - S.w_F_star));

% T1: filas de Qz suman cero
Qz = full(S.Qz_ar);
fprintf('T1 filas de Qz: max |suma de fila| = %.3e  (Nz=%d)\n', ...
    max(abs(sum(Qz,2))), size(Qz,1));

% B5: varianza estacionaria y persistencia del OU
fprintf('B5 OU: sd_logz objetivo = %.6f | sd de los nodos ponderada = %.6f\n', ...
    S.sd_logz_ar, sqrt(sum(S.pi_z_ar(:).*(S.logz_nodes(:)-sum(S.pi_z_ar(:).*S.logz_nodes(:))).^2)));
fprintf('B5 OU: rho_z = %.6f | exp(-eta*dt) = %.6f | dif = %.3e\n', ...
    S.rho_z_ar, exp(-S.eta_z_ar*S.dt_z_ar), abs(S.rho_z_ar - exp(-S.eta_z_ar*S.dt_z_ar)));
fprintf('B5 OU: E[z] tras normalizar = %.6f (debe ser 1)\n', sum(S.pi_z_ar(:).*S.z(:)));

% B2: sorting monotono - participacion formal por nodo z
share = zeros(1, S.Ns);
for j = 1:S.Ns
    hF = S.da*sum(S.g(:,j).*S.ell_F(:,j));
    hI = S.da*sum(S.g(:,j).*S.ell_I(:,j));
    share(j) = hF/max(hF+hI, 1e-12);
end
fprintf('B2 participacion formal por z (de z_min a z_max):\n   ');
fprintf('%.4f ', share); fprintf('\n');
fprintf('   monotona creciente en z: %d\n', all(diff(share) >= -1e-10));

% B3: margen intensivo - hay algun nodo con ell_F exactamente cero?
fprintf('B3 nodos z con horas formales agregadas nulas: %d de %d\n', ...
    sum(share < 1e-12), S.Ns);
fprintf('   kappa_z por nodo (de z_min a z_max): ');
fprintf('%.4f ', S.kappa_F_aa(1,:)); fprintf('\n');
fprintf('   (1-tau)*w_F*z por nodo:              ');
fprintf('%.4f ', (1-S.tau)*S.w_F_star*S.z(:)'); fprintf('\n');

function r = Y_res(YF, CF, dK, Kappa, DP)
    r = abs(YF - CF - dK - Kappa - DP);
end
