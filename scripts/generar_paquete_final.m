%% generar_paquete_final.m
% Genera figuras + resumen .txt desde la corrida final guardada
% y empaqueta todo en un .zip listo para entregar. No resuelve el modelo.
%
% USO desde la raiz del paquete:
%   >> run('scripts/generar_paquete_final.m')
%
% SALIDA: outputs/stationary/test_AI098_cierre/
%   plots_matlab/   <- PNGs (~33 figuras)
%   resumen_calibracion.txt  <- todos los valores clave
%   paquete_final.zip        <- zip con mat + plots + txt

script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir), script_dir = pwd; end
package_root = fileparts(script_dir);
if isempty(package_root), package_root = pwd; end
addpath(package_root);
addpath(fullfile(package_root, 'ploteo'));

RUN_TAG  = 'test_AI098_cierre';
run_dir  = fullfile(package_root, 'outputs', 'stationary', RUN_TAG);
mat_file = fullfile(run_dir, ['results_' RUN_TAG '.mat']);
txt_file = fullfile(run_dir, 'resumen_calibracion.txt');
zip_file = fullfile(run_dir, 'paquete_final.zip');

if ~exist(mat_file, 'file')
    error('No se encuentra: %s\n\nCorrer primero model_main con RUN_TAG=%s', mat_file, RUN_TAG);
end

% =========================================================================
% 1. GENERAR FIGURAS
% =========================================================================
fprintf('=== Generando figuras ===\n');
plot_moll_matlab_all(mat_file);
plots_dir = fullfile(run_dir, 'plots_matlab');
fprintf('PNGs guardados en: %s\n\n', plots_dir);

% =========================================================================
% 2. EXPORTAR RESUMEN .TXT
% =========================================================================
fprintf('=== Exportando resumen .txt ===\n');
r = load(mat_file);

fid = fopen(txt_file, 'w');
fprintf(fid, '================================================================\n');
fprintf(fid, '  RESUMEN CALIBRACION — Modelo 2 Firmas Aiyagari HACT — Peru\n');
fprintf(fid, '  Run: %s\n', RUN_TAG);
fprintf(fid, '  Fecha generacion: %s\n', datestr(now));
fprintf(fid, '================================================================\n\n');

fprintf(fid, '--- EQUILIBRIO ---\n');
fprintf(fid, '  r*        = %.6f\n', r.r_star);
fprintf(fid, '  p_I*      = %.6f\n', r.p_I_star);
fprintf(fid, '  w_F       = %.6f  (bruto)\n', r.w_F_star);
fprintf(fid, '  w_I_marg  = %.6f\n', r.w_I_star);
fprintf(fid, '  w_I_hh    = %.6f  (ingreso mixto)\n', r.w_I_household_star);
fprintf(fid, '  L_F*      = %.6f\n', r.L_F_star);
fprintf(fid, '  L_I*      = %.6f\n', r.L_I_star);
fprintf(fid, '  K*        = %.6f\n', r.K_star);
fprintf(fid, '  Y_F       = %.6f\n', r.Y_F);
fprintf(fid, '  Y_I       = %.6f\n', r.Y_I);
fprintf(fid, '  T (rebate)= %.6f\n', r.T_eq);
fprintf(fid, '\n');

fprintf(fid, '--- TARGETS (modelo | dato Peru) ---\n');
fprintf(fid, '  T4  share horas informal:    %.4f | 0.516  (ENAHO 2018 pre-COVID)\n', r.T4_model);
fprintf(fid, '  T5  share PIB informal nom:  %.4f | 0.190  (INEI Cuenta Sat. 2024)\n', r.T5_nom);
fprintf(fid, '  Tkz gap formal z2-z1:        %.4f | 0.386  (EPEN 2025)\n', r.T_kappa_z_model);
fprintf(fid, '  Tgasto formal/informal:      %.4f | 1.913  (ENAHO 2015-2019)\n', r.Tgasto_tipo);
fprintf(fid, '\n');

fprintf(fid, '--- DESIGUALDAD ---\n');
fprintf(fid, '  Gini_a (riqueza):  %.4f\n', r.Gini_a);
fprintf(fid, '  Gini_c (consumo):  %.4f\n', r.Gini_c);
if isfield(r, 'mass_amin')
    fprintf(fid, '  masa en amin:      %.4f (%.1f%% en constraint)\n', r.mass_amin, r.mass_amin*100);
end
fprintf(fid, '\n');

fprintf(fid, '--- T6 DIAGNOSTICO (sin target calibrado) ---\n');
fprintf(fid, '  T6 gap Q1-Q5 horas inf:  %.4f | 0.530  (INEI-ENAHO 2017)\n', r.T6_model);
fprintf(fid, '  Q1 share horas inf:      %.4f | 0.971\n', r.T6_Q1);
fprintf(fid, '  Q5 share horas inf:      %.4f | 0.441\n', r.T6_Q5);
fprintf(fid, '\n');

fprintf(fid, '--- PARAMETROS USADOS ---\n');
fprintf(fid, '  A_F       = %.4f\n', r.A_F);
fprintf(fid, '  A_I       = %.4f\n', r.A_I);
fprintf(fid, '  alpha_I   = %.4f\n', r.alpha_I);
fprintf(fid, '  beta_I    = %.4f\n', r.beta_I);
fprintf(fid, '  al (F)    = %.4f  (Cespedes et al. 2014, EF)\n', r.al);
fprintf(fid, '  psi_F     = %.4f\n', r.psi_F);
fprintf(fid, '  psi_I     = %.4f\n', r.psi_I);
fprintf(fid, '  theta     = %.4f\n', r.theta);
fprintf(fid, '  nu_I      = %.4f\n', r.nu_I);
fprintf(fid, '  kappa_z1  = %.4f\n', r.kappa_z1);
fprintf(fid, '  omega_C   = %.4f\n', r.omega_C);
fprintf(fid, '  sigma_C   = %.4f\n', r.sigma_C);
fprintf(fid, '  rho       = %.4f\n', r.rho);
fprintf(fid, '  Frisch    = %.4f\n', r.Frisch);
fprintf(fid, '  amin      = %.4f\n', r.amin);
fprintf(fid, '  amax      = %.4f\n', r.amax);
fprintf(fid, '  tau_c     = %.4f\n', r.tau_c);
fprintf(fid, '  debt_chi  = %.4f\n', r.debt_prem_chi);
fprintf(fid, '\n');

fprintf(fid, '--- PROCESO Z (Hong 2022, J.Int.Econ) ---\n');
fprintf(fid, '  rho_z     = %.6f\n', r.rho_z_ar);
fprintf(fid, '  sd_logz   = %.6f\n', r.sd_logz_ar);
fprintf(fid, '  Nz        = %d\n',   r.Nz_ar);
fprintf(fid, '  z_min     = %.4f\n', r.z(1));
fprintf(fid, '  z_max     = %.4f\n', r.z(end));
fprintf(fid, '\n');

fprintf(fid, '--- ARCHIVOS ---\n');
fprintf(fid, '  results:  results_%s.mat\n', RUN_TAG);
fprintf(fid, '  calib:    calib_%s.mat\n', RUN_TAG);
fprintf(fid, '  plots:    plots_matlab/ (%d figuras PNG)\n', ...
    numel(dir(fullfile(plots_dir, '*.png'))));
fprintf(fid, '\n');
fprintf(fid, '================================================================\n');
fclose(fid);
fprintf('Resumen guardado en: %s\n\n', txt_file);

% =========================================================================
% 3. CREAR ZIP
% =========================================================================
fprintf('=== Creando zip ===\n');
files_to_zip = {
    mat_file
    fullfile(run_dir, ['calib_' RUN_TAG '.mat'])
    txt_file
};
png_files = dir(fullfile(plots_dir, '*.png'));
for k = 1:numel(png_files)
    files_to_zip{end+1} = fullfile(plots_dir, png_files(k).name); %#ok<SAGROW>
end

if exist(zip_file, 'file'), delete(zip_file); end
zip(zip_file, files_to_zip);
fprintf('ZIP creado: %s\n', zip_file);
fprintf('Archivos incluidos: %d (2 .mat + 1 .txt + %d .png)\n\n', ...
    numel(files_to_zip), numel(png_files));
fprintf('=== LISTO ===\n');
