# CONTINUAR AQUÍ — HA-IE Replication Package

> Para el compañero que retoma. Todo lo necesario está en esta carpeta.

## Contexto (30 segundos)

Modelo Aiyagari HACT con 2 firmas (formal/informal), oferta laboral endógena, Perú.
**Cambio clave 2026-06-21:** Reemplazamos proceso z propio (ENAHO GMM) por **Hong (2022)**.

| Concepto                  | Valor                               | Fuente                               |
| ------------------------- | ----------------------------------- | ------------------------------------ |
| ρ_z (persistencia anual) | 0.8600132622                        | Hong (2022) JIE: 0.963⁴             |
| σ_logz (sd estacionaria) | 0.5417411732                        | Hong (2022) JIE: 0.146/√(1-0.963²) |
| Firma formal              | α=0.636 CRS                        | Céspedes et al. (2014)              |
| Firma informal            | α_I=0.118, β_I=0.605 DRS          | Göbel et al. (2013)                 |
| PDF paper                 | `docs/referencias/hong_emmpc.pdf` | Tabla 1, p.24                        |

## Restricciones duras (NO VIOLAR)

```
p_I < 1       bien informal más barato que formal
A_I ≤ 1       PTF informal ≤ PTF formal
β_I = 0.605   NO TOCAR (Göbel et al. 2013)
α_I = 0.118   NO TOCAR (Göbel et al. 2013)
ρ_z = 0.860   NO TOCAR (Hong 2022)
σ_logz = 0.542 NO TOCAR (Hong 2022)
ν_I ∈ [0.4, 0.8]
```

## Targets

| Target                      | Dato Perú | Fuente                     |
| --------------------------- | ---------- | -------------------------- |
| T4: L_I/(L_F+L_I)           | 0.557      | INEI Cuenta Satélite 2024 |
| T5: p_I·Y_I/(Y_F+p_I·Y_I) | 0.190      | INEI Cuenta Satélite 2024 |
| Tkz: gap formalidad z₂-z₁ | 0.386      | EPEN 2025                  |
| Tgasto: gasto F-dom / I-dom | 1.913      | ENAHO 2015-2019            |

## Mejor run hasta ahora

`hong_nz14_DRS_om055` (p_I=1.14 — VIOLA RESTRICCIÓN pero targets más cercanos)

| Target | Modelo   | Dato  | Brecha |
| ------ | -------- | ----- | ------ |
| p_I<1  | 1.14 ✗  | <1    | +0.14  |
| T4     | 0.560 ✓ | 0.557 | +0.003 |
| T5     | 0.157    | 0.190 | -0.033 |
| Tkz    | 0.161    | 0.386 | -0.225 |
| Tgasto | 1.60     | 1.913 | -0.31  |
| T1 hh  | 2.58     | ~2.30 | +0.28  |

Parámetros: Nz=14, A_I=0.99, psi_F=180, psi_I=50, ν_I=0.40, κ_z1=0.110, κ_shape=2.0, ω_C=0.55, amin=-1

## Estrategia de calibración

```
Instrumento     →  Target     Dirección
─────────────────────────────────────────
ω_C (subir)     →  p_I < 1    ω_C↑ → p_I↓
ω_C (bajar)     →  T5 ↑       ω_C↓ → demanda informal ↑ → p_I·Y_I ↑ → T5↑
psi_F/psi_I     →  T4         ratio psi_F/psi_I ↑ → T4 ↑
κ_z1 (subir)    →  Tkz ↑      más barrera a z bajo → gap sube
ν_I (bajar)     →  Tkz ↑      z^ν más plano → informal para z alto
```

**Tensión central:** bajar ω_C sube T5 pero también sube p_I (riesgo >1).
Hay que encontrar ω_C que maximice T5 con p_I<1. Ese ω_C está entre 0.55 y 0.65.
Puede ajustar un poco sigma_C como robustez (σ_C=3 o σ_C=7) si p_I no responde a ω_C.

## Nz vs velocidad vs precisión

| Nz | Tiempo fast debug | Ventaja | Riesgo |
|----|-------------------|---------|--------|
| 7  | ~8 min | Rápido para explorar | Tkz subestimado, extremos truncados |
| 14 | ~16 min | Balance velocidad/precisión | OK para calibrar |
| 20 | ~25 min | Convergencia más fina | No necesario hasta ajuste final |
| 40 | ~1h+ | Benchmark Moll-style | Solo para validación final |

**Regla:** Calibrar en Nz=14 (o Nz=7 para exploración rápida). Solo correr Nz=20 o Nz=40 al final para validar que resultados no cambian.

## Cómo se generan los gráficos

Cada gráfico de la presentación → script que lo produce:

| Slide | Gráfico | Script |
|-------|---------|--------|
| Uso del tiempo | `moll_time_use_by_z_excluding_leisure.png` | `ploteo/moll_mechanism.py` |
| Ahorro y riqueza | `moll_savings_and_wealth_distribution.png` | `ploteo/moll_mechanism.py` |
| Densidad por z | `moll_wealth_density_by_z_low_median_high.png` | `ploteo/moll_mechanism.py` |
| Ingreso por quintil | `moll_income_decomposition_percent_by_wealth_quintile.png` | `ploteo/moll_mechanism.py` |
| Gasto por formalidad | `moll_model_gasto_distribution_by_formality.png` | `ploteo/moll_gasto.py` |
| Componentes consumo | `moll_consumption_components_distribution.png` | `ploteo/moll_mechanism.py` |

Todos se generan con `python ploteo/<script>.py --mat-file <results.mat> --out-dir <dir>`.
El .mat lo produce `model_main.m` al terminar.

## PASO 1 — Correr ω_C=0.60 (el punto dulce)

```matlab
HA_IE_REPLICATION_LOADED = true;
cd('C:\Users\johnb\Documents\GitHub\HA-IE2025\Code\CONTINUOUS_TIME\Aiyagari_firmas\try_endog_labor_2_firms\replication_package')

setenv('HA_IE_RUN_TAG', 'hong_nz14_DRS_om060');
setenv('HA_IE_Z_N', '14');
setenv('HA_IE_Z_RHO', '0.8600132622');
setenv('HA_IE_Z_SD', '0.5417411732');
setenv('HA_IE_ALPHA_I', '0.118');
setenv('HA_IE_BETA_I', '0.605');
setenv('HA_IE_OMEGA_C', '0.60');
setenv('HA_IE_NU_I', '0.40');
setenv('HA_IE_PSI_F', '180');
setenv('HA_IE_PSI_I', '50');
setenv('HA_IE_A_I', '0.99');
setenv('HA_IE_KAPPA_Z1', '0.110');
setenv('HA_IE_KAPPA_Z_SHAPE', '2.0');
setenv('HA_IE_FAST_DEBUG', '1');
setenv('HA_IE_R_HI', '0.15');
setenv('HA_IE_VERBOSE', '0');
setenv('HA_IE_AMIN', '-1');
setenv('HA_IE_INFORMAL_PROFIT_RULE', 'hours');
model_main
```

~16 min en fast debug. Si no converge, subir `HA_IE_R_HI` a 0.30.

**Si p_I<1:** ¡Éxito! Ir a PASO 2.
**Si p_I>1:** Subir ω_C a 0.62-0.63 y repetir.
**Si p_I<0.80:** Bajar ω_C a 0.58 y repetir (hay margen para más T5).

## PASO 2 — Graficar

```matlab
RESULTS = 'outputs/stationary/hong_nz14_DRS_om060/results_hong_nz14_DRS_om060.mat';
PLOTS   = 'outputs/stationary/hong_nz14_DRS_om060/plots_moll';
system(sprintf('python ploteo/moll_mechanism.py --mat-file "%s" --out-dir "%s"', RESULTS, PLOTS));
system(sprintf('python ploteo/moll_gasto.py --mat-file "%s" --out-dir "%s"', RESULTS, PLOTS));
```

12 PNGs en `plots_moll/`.

## PASO 3 — Actualizar presentación

1. Editar `presentacion/presentation_replication.tex`:
   - `\graphicspath{{../outputs/stationary/<NUEVO_DIR>/plots_moll/}}`
   - Actualizar tabla de targets en slide "Calibración"
2. Compilar: `cd presentacion && pdflatex presentation_replication.tex`

## PASO 4 — Ajustar Tkz

Una vez p_I<1 con buen T5, subir κ_z1 para cerrar Tkz:

```matlab
setenv('HA_IE_RUN_TAG', 'hong_nz14_DRS_k120');
setenv('HA_IE_KAPPA_Z1', '0.120');
% ... resto igual que PASO 1
```

Probar κ_z1 ∈ {0.120, 0.130, 0.150} hasta Tkz≈0.386.

## PASO 5 — Si T5 no llega a 0.19

Con Hong (ρ=0.860) el ahorro precautorio es más alto que con ENAHO GMM:

- K sube → r* baja → w_F/w_I se dispara (~4 en modelo vs ~2.30 BCR)
- Formal demasiado atractiva → Y_I bajo → T5 estructuralmente bajo

Si con p_I≈0.95 y A_I=0.99, T5<0.15: **documentar como limitación estructural**.
Ver `PLAN_CALIBRACION.md` paso 5 para redacción sugerida.

## PASO 6 (opcional) — CRS Göbel

```matlab
setenv('HA_IE_RUN_TAG', 'hong_nz14_CRS_Gobel');
setenv('HA_IE_ALPHA_I', '0.163');
setenv('HA_IE_BETA_I', '0.837');
setenv('HA_IE_INFORMAL_PROFIT_RULE', 'lump');
model_main
```

## Historial de corridas

| Run                 | ω_C | α_I  | β_I  | ν_I | p_I    | T4   | T5    | Tkz   |
| ------------------- | ---- | ----- | ----- | ---- | ------ | ---- | ----- | ----- |
| hong_nz14_om75_k110 | 0.75 | 0     | 0.60  | 0.60 | 0.45   | 0.50 | 0.067 | 0.114 |
| hong_nz14_nu04      | 0.75 | 0     | 0.60  | 0.40 | 0.45   | 0.50 | 0.067 | 0.163 |
| hong_nz14_DRSGobel  | 0.65 | 0.118 | 0.605 | 0.40 | 0.77   | 0.52 | 0.094 | 0.163 |
| hong_nz14_DRS_om055 | 0.55 | 0.118 | 0.605 | 0.40 | 1.14✗ | 0.56 | 0.157 | 0.161 |

## Pipeline de gráficos

| Tipo             | Comando                                                              | Output  |
| ---------------- | -------------------------------------------------------------------- | ------- |
| Moll mechanism   | `python ploteo/moll_mechanism.py --mat-file <mat> --out-dir <dir>` | 11 PNGs |
| Gasto formalidad | `python ploteo/moll_gasto.py --mat-file <mat> --out-dir <dir>`     | 1 PNG   |
| OU diagnóstico  | `plot_ou_process_distributions('<mat>')`                           | PNGs    |
| Slides           | `cd presentacion && pdflatex presentation_replication.tex`         | PDF     |

## Archivos clave en este package

| Archivo                                       | Qué es                                                    |
| --------------------------------------------- | ---------------------------------------------------------- |
| `model_main.m`                              | Solver principal                                          |
| `ploteo/zero_drift_solver.m`               | Solver zero-drift vectorizado (dep de model_main, ex `zero_drift_grid_fast_v10_debtprem`) |
| `PLAN_CALIBRACION.md`                       | Plan completo + bitácora                                 |
| `CALIBRACION_CONTEXTO.md`                   | Documentación de parámetros                             |
| `docs/referencias/hong_emmpc.pdf`           | Paper fuente del proceso z                                |
| `ploteo/moll_mechanism.py`                  | Gráficos publicación                                    |
| `ploteo/moll_gasto.py`                      | Gasto por formalidad                                      |
| `presentacion/presentation_replication.tex` | Slides Beamer                                             |
| `calibracion/escenarios.m`                  | Selector de escenarios                                    |
