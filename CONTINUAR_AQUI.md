# CONTINUAR AQUÍ — HA-IE Replication Package

> Última actualización: 2026-06-26. **Línea base: `test_kz38_psii34`** (al=0.573, A_I=0.95, κ_z=0.38, Gini=0.52, A_I<1).

---

## 🏆 Mejor corrida hasta ahora

```
outputs/stationary/test_kz38_psii34/results_test_kz38_psii34.mat
```

| Target | Valor | Dato |
|--------|-------|------|
| p_I | 0.94 | <1 ✅ |
| T4 | 0.51 | ~0.52 ✅ |
| T5 | 0.18 | 0.19 |
| Tkz | **0.32** | 0.39 |
| Gini riqueza | **0.52** | ≥0.40 ✅ |
| A_I | **0.95** | <1 🏆 |
| T4_ext (formal-dom) | **40%** | — |
| Ocio | 51% | — |

---

## 🚀 Cómo correr la calibración base

```matlab
cd('C:\Users\johnb\Documents\GitHub\HA-IE2025\Code\CONTINUOUS_TIME\Aiyagari_firmas\try_endog_labor_2_firms\replication_package')

setenv('HA_IE_RUN_TAG',   'mi_corrida')
setenv('HA_IE_RHO',        '0.073')
setenv('HA_IE_GA',         '1.0')
setenv('HA_IE_SIGMA_C',    '5')
setenv('HA_IE_OMEGA_C',    '0.56')
setenv('HA_IE_A_I',        '0.95')        % ← A_I < 1
setenv('HA_IE_PSI_F',      '55')
setenv('HA_IE_PSI_I',      '34')          % ← NO bajar de 34 (rompe Tkz)
setenv('HA_IE_KAPPA_Z1',   '0.38')        % ← Tkz ~0.32
setenv('HA_IE_KAPPA_Z_SHAPE', '1.0')
setenv('HA_IE_INFORMAL_PROFIT_RULE', 'hours')
setenv('HA_IE_NU_I',       '0.6')
setenv('HA_IE_AL',         '0.573')       % ← NUEVO capital share formal
setenv('HA_IE_ALPHA_I',    '0.220')       % ← NUEVO capital informal
setenv('HA_IE_BETA_I',     '0.619')       % ← NUEVO labor informal
setenv('HA_IE_THETA',      '1.0')
setenv('HA_IE_Z_N',        '40')
setenv('HA_IE_Z_RHO',      '0.861')
setenv('HA_IE_Z_SD',       '0.544')
setenv('HA_IE_Z_WIDTH',    '2.5')
setenv('HA_IE_FAST_DEBUG', '1')
setenv('HA_IE_EQ_MODE',    '2')
setenv('HA_IE_VERBOSE',    '0')
setenv('HA_IE_R_HI',       '0.20')        % ← OBLIGATORIO con rho=0.073
setenv('HA_IE_R_LO',       '-0.04')
setenv('HA_IE_TAU_C',      '0')
setenv('HA_IE_DEBT_PREM_CHI',    '0.02')
setenv('HA_IE_DEBT_PREM_ETA',    '1.0')
setenv('HA_IE_DEBT_PREM_REBATE', '0')
setenv('HA_IE_AMIN',       '-0.05')       % ← Restringir crédito → subir Gini gasto
setenv('HA_IE_FRISCH',     '0.38')

model_main
```

---

## 🧪 Pruebas pendientes (en orden de prioridad)

| # | Tag | Cambio vs base | Busca mejorar |
|---|-----|----------------|---------------|
| **1** | `test_amin005` | `amin = -0.05` (base usa -1.0) | **Gini gasto** (restringir crédito → consumo = ingreso) |
| **2** | `test_kz042` | `κ_z1 = 0.42` | **Tkz** → 0.39 (subir de 0.32) |
| **3** | `test_AI098` | `A_I = 0.98` | **T5** → 0.19 (subir de 0.18) |
| **4** | `test_psiI35` | `ψ_I = 35` | **T4** → 0.52 |
| **5** | `test_sdlogz070` | `sd_logz = 0.70` | **Gini gasto** (más dispersión ingreso) |

---

## 📊 Cómo generar los plots

### MATLAB (37 figuras Moll-style)

```matlab
cd('C:\Users\johnb\Documents\GitHub\HA-IE2025\Code\CONTINUOUS_TIME\Aiyagari_firmas\try_endog_labor_2_firms\replication_package')
addpath('ploteo')

% Con el .mat que quieras:
plot_moll_matlab_all('outputs/stationary/test_kz38_psii34/results_test_kz38_psii34.mat')

% Con carpeta de salida explícita:
plot_moll_matlab_all('outputs/stationary/MI_CORRIDA/results_MI_CORRIDA.mat', ...
                     'outputs/stationary/MI_CORRIDA/plots_matlab')

% Solo superficies 3D tipo Moll/XYZ:
plot_moll_matlab_all('outputs/stationary/MI_CORRIDA/results_MI_CORRIDA.mat', [], {'xyz'})
```

Conteo actual del plotter MATLAB:

- Corrida completa: **37 PNG** en `plots_matlab`
- Solo `{'xyz'}`: **6 superficies 3D** (`g(a,z)`, ahorro, consumo, gasto, horas formales, horas informales)
- Las figuras se guardan con sufijo `_matlab.png`
- Si no se pasa `out_dir`, el plotter usa automaticamente `outputs/stationary/MI_CORRIDA/plots_matlab`

Ejemplo validado con la corrida nueva:

```matlab
plot_moll_matlab_all('outputs/stationary/final_newCD_tuned/results_final_newCD_tuned.mat', ...
                     'outputs/stationary/final_newCD_tuned/plots_matlab')
```

Desde PowerShell:

```powershell
matlab -batch "cd('C:\Users\johnb\Documents\GitHub\HA-IE2025\Code\CONTINUOUS_TIME\Aiyagari_firmas\try_endog_labor_2_firms\replication_package'); addpath('ploteo'); plot_moll_matlab_all('outputs/stationary/final_newCD_tuned/results_final_newCD_tuned.mat','outputs/stationary/final_newCD_tuned/plots_matlab');"
```

Figuras MATLAB importantes agregadas:

- `moll_savings_policy_matlab.png`: incluye `z_min`, `z_med`, `z_max`
- `moll_density_surface_3d_matlab.png`: superficie 3D estilo `MOLL_GRAPHS/MOLL_6.png`
- `moll_savings_surface_3d_matlab.png`: superficie 3D de ahorro
- `moll_consumption_surface_3d_matlab.png`: superficie 3D de consumo efectivo
- `moll_expenditure_surface_3d_matlab.png`: superficie 3D de gasto
- `moll_formal_hours_surface_3d_matlab.png`: superficie 3D de horas formales
- `moll_informal_hours_surface_3d_matlab.png`: superficie 3D de horas informales
- `moll_table_primary_matlab.png`, `moll_table_secondary_matlab.png`, `moll_table_params_matlab.png`: tablas separadas para PPT

### Python (19 figuras + 3 tablas)

```bash
cd replication_package

python ploteo/moll_mechanism.py \
  --mat-file "outputs/stationary/MI_CORRIDA/results_MI_CORRIDA.mat" \
  --out-dir "outputs/stationary/MI_CORRIDA/plots_python"

python ploteo/moll_gasto.py \
  --mat-file "outputs/stationary/MI_CORRIDA/results_MI_CORRIDA.mat" \
  --out-dir "outputs/stationary/MI_CORRIDA/plots_python"

python ploteo/plot_calibration_tables.py \
  --mat-file "outputs/stationary/MI_CORRIDA/results_MI_CORRIDA.mat" \
  --out-dir "outputs/stationary/MI_CORRIDA/plots_python"
```

---

## 📁 Archivos .mat disponibles

| Tag | Archivo | Destino |
|-----|---------|---------|
| `test_kz38_psii34` | `.../results_test_kz38_psii34.mat` | 🏆 Mejor balance (Tkz=0.32, Gini=0.52) |
| `final_newCD_tuned` | `.../results_final_newCD_tuned.mat` | Corrida nueva graficada con 37 PNG MATLAB en `plots_matlab` |
| `test_kz35_w25` | `.../results_test_kz35_w25.mat` | Tkz=0.27, T4_ext=65% |
| `test_kz44_AI98` | `.../results_test_kz44_AI98.mat` | T5=0.189 clavado |
| `test_theta07` | `.../results_test_theta07.mat` | θ=0.7 (descartado) |
| `test_noKI_b0696` | `.../results_test_noKI_b0696.mat` | Sin K informal (descartado) |

---

## ⚠️ Reglas aprendidas

1. **ψ_I ≥ 34** — si bajás de 34, form_rate z_min = 0% y Tkz salta a 0.55
2. **HA_IE_R_HI = 0.20** obligatorio con ρ=0.073, o el bracket de r no contiene r*
3. **κ_z muy sensible** con Nz=40 — cambios de ±0.03 causan saltos grandes en Tkz
4. **A_I < 1 se logró** bajando al de 0.636 a 0.573
5. **ψ_F=1 NO FUNCIONA** — colapso de Gini a 0.06
6. **θ<1 NO FUNCIONA** — p_I>1

## 📚 Documentación

| Archivo | Contenido |
|---------|-----------|
| `SESION_CALIBRACION_2026-06-25.md` | Bitácora 42+ corridas |
| `RECALIBRACION_CD.md` | Resumen nueva calibración CD |
| `NARRATIVA_CALIBRACION.md` | Cómo explicar los resultados |
| `REFERENCIAS_TEORICAS_TRABAJO_ENDOGENO.md` | Citas Marcet et al. (2007) |
| `PLAN_UTILIDAD_NO_SEPARABLE.md` | Plan para utilidad Horvath |
| `FIGURAS_REFERENCIA.md` | Documentación de figuras |
| `CONTINUAR_AQUI.md` | Este archivo |
