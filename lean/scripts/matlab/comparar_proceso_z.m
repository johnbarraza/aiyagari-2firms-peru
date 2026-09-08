% Comparacion pareada del proceso de productividad, en grilla reducida.
%
% Ambas corridas usan I=100 en vez de 200 para que quepan en memoria. Eso
% desplaza los niveles respecto de la corrida de cierre, pero la COMPARACION
% entre las dos es limpia porque solo cambia el proceso de z.
%
%   A = baseline : sd=0.544 (sigma_P0 de Hong), width=2.5
%   B = corregido: sd=0.541741 (sd estacionaria), width=auto
%
% Todo lo demas identico.

repo = ['C:\Users\johnb\Documents\GitHub\HA-IE2025\Code\CONTINUOUS_TIME\' ...
        'Aiyagari_firmas\try_endog_labor_2_firms\replication_package'];
cd(repo);

comun = { ...
  'HA_IE_FAST_DEBUG','true'; 'HA_IE_VERBOSE','0'; 'HA_IE_EQ_MODE','2'; ...
  'HA_IE_DEBUG_I','100'; ...
  'HA_IE_RHO','0.073'; 'HA_IE_GA','1'; 'HA_IE_AMIN','-1.0'; ...
  'HA_IE_R_LO','0.055'; 'HA_IE_R_HI','0.078'; 'HA_IE_ZDRIFT_NPTS','25'; ...
  'HA_IE_Z_N','40'; 'HA_IE_Z_RHO','0.861'; ...
  'HA_IE_A_I','0.98'; 'HA_IE_ALPHA_I','0.220'; 'HA_IE_BETA_I','0.619'; ...
  'HA_IE_THETA','1.0'; 'HA_IE_NU_I','0.6'; ...
  'HA_IE_PSI_F','55'; 'HA_IE_PSI_I','34'; ...
  'HA_IE_OMEGA_C','0.56'; 'HA_IE_SIGMA_C','5'; ...
  'HA_IE_KAPPA_Z1','0.40'; 'HA_IE_KAPPA_Z_SHAPE','1.0'; ...
  'HA_IE_DEBT_PREM_CHI','0.02'; 'HA_IE_DEBT_PREM_ETA','1.0'; ...
  'HA_IE_DEBT_PREM_REBATE','0'; 'HA_IE_INFORMAL_PROFIT_RULE','hours' };

casos = { 'A_base_I100',  '0.544',      '2.5' ; ...
          'B_zfix_I100',  '0.541741',   'auto' };

for k = 1:size(casos,1)
    for r = 1:size(comun,1), setenv(comun{r,1}, comun{r,2}); end
    setenv('HA_IE_RUN_TAG', casos{k,1});
    setenv('HA_IE_Z_SD',    casos{k,2});
    setenv('HA_IE_Z_WIDTH', casos{k,3});
    fprintf('\n\n########## CASO %s : sd=%s width=%s ##########\n\n', ...
        casos{k,1}, casos{k,2}, casos{k,3});
    clearvars -except comun casos k repo
    model_main
    close all;
end

fprintf('\n\n########## COMPARACION ##########\n');
for k = 1:size(casos,1)
    tag = casos{k,1};
    f = fullfile(repo,'outputs','stationary',tag,['results_' tag '.mat']);
    if exist(f,'file')
        S = load(f);
        fprintf('\n--- %s ---\n', tag);
        fprintf('  sd_logz_ar=%.6f  width_z_ar=%.4f\n', S.sd_logz_ar, S.width_z_ar);
        m = sqrt(sum(S.pi_z_ar(:).*(S.logz_nodes(:)-sum(S.pi_z_ar(:).*S.logz_nodes(:))).^2));
        fprintf('  sd(log z) realizada = %.6f  (%.2f%% del objetivo)\n', m, 100*m/S.sd_logz_ar);
        fprintf('  r*=%.6f  p_I*=%.6f  K*=%.4f\n', S.r_star, S.p_I_star, S.K_star);
        fprintf('  T4=%.4f  T5=%.4f  Tkz=%.4f  T6=%.4f\n', ...
            S.T4_model, S.T5_nom, S.T_kappa_z_model, S.T6_model);
        fprintf('  Gini_a=%.4f  Gini_c=%.4f\n', S.Gini_a, S.Gini_c);
        fprintf('  walras_err=%.3e  goods_I_err=%.3e\n', S.walras_err, S.goods_I_err);
    else
        fprintf('\n--- %s : NO se genero el .mat ---\n', tag);
    end
end
