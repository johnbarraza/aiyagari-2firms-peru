# Resultados Corridas A/B/C — 2026-06-24

> Ejecutado con `model_main.m` del replication_package (MATLAB R2025b).
> Nz=14, fast debug (I=200), amin=-0.002 en todas.

## Tabla comparativa

| Variable | A: Réplica compañero | B: kappa_z1=0.11 | C: DRS Göbel K inf. | Target Perú |
|----------|----------------------|-------------------|---------------------|-------------|
| **Parámetros** | | | | |
| alpha_I | 0.0 | 0.0 | **0.118** | — |
| beta_I | 0.60 | 0.60 | **0.605** | — |
| A_I | 0.5 | 0.5 | **0.99** | ≤1 |
| psi_F / psi_I | 100/75 | 100/75 | **180/50** | — |
| theta | 0.55 | 0.55 | **1.0** | ∈(0,1] |
| omega_C | 0.55 | 0.55 | **0.57** | — |
| kappa_z1 | 0.01 | **0.11** | 0.11 | ≥0 |
| **Precios** | | | | |
| r* | 0.049663 | 0.049542 | — | — |
| p_I* | 1.407 | 1.404 | **1.010** | <1 |
| w_F* | 4.560 | 4.567 | 4.693 | — |
| w_I_marg* | 1.133 | 1.127 | 0.964 | — |
| w_I_hh* | 1.888 | 1.877 | 1.401 | — |
| w_F/(w_I_hh·θ) | 4.39 | 4.42 | **3.35** | ~2.30 |
| **Cantidades** | | | | |
| K* | 12.655 | 12.676 | — | — |
| K_F* | 12.655 | 12.676 | — | — |
| K_I* | 0 | 0 | **0.265** | >0 |
| L_F* | 0.238 | 0.238 | 0.197 | — |
| L_I* | 0.085 | 0.085 | **0.208** | — |
| Y_F | 2.978 | — | — | — |
| Y_I | 0.114 | 0.114 | **0.324** | — |
| **Targets** | | | | |
| T4 (horas inf.) | 0.412 | 0.413 | **0.533** ✅ | 0.557 |
| T5 (PBI inf. nom.) | 0.051 | 0.051 | **0.115** ⬆ | 0.190 |
| T5 (real) | 0.037 | 0.037 | 0.114 | — |
| Tkz (gap formal z₂-z₁) | 0.101 | 0.113 | 0.115 | 0.386 |
| Tgasto_tipo | NaN | NaN | **1.532** ✅ | 1.913 |
| T6 (gap Q1-Q5) | 0.023 | 0.025 | 0.025 | 0.530 |
| T1 marginal | 7.32 | 7.37 | 4.87 | ~2.30 |
| **Diagnósticos** | | | | |
| T4 extensivo | 0.000 | 0.000 | **0.933** | — |
| Gini riqueza | 0.262 | 0.261 | — | ~0.68 |
| mass_amin | 0.008 | 0.008 | — | >0 |

## Hallazgos clave

### 1. Código del compañero NO coincide con model_main
- La corrida A (réplica exacta de parámetros) produce resultados DRAMÁTICAMENTE distintos al console output del compañero:
  - Compañero: r*=0.033, p_I=1.048, T5=0.193, K*=2.90
  - model_main: r*=0.050, p_I=1.407, T5=0.051, K*=12.66
- El `run_metadata.txt` del repo (Jun 17) SÍ coincide con model_main → el código actual es consistente
- **Conclusión:** El compañero usó una versión modificada del código en `C:\Users\HP\Downloads\ie2\`

### 2. Capital informal (DRS Göbel) es el camino ✅
- K_I = 0.265 > 0 por primera vez
- p_I bajó de 1.41 a 1.01 (casi <1)
- T4 saltó de 0.41 a 0.53 (cerca del target 0.557)
- T5 saltó de 0.05 a 0.12 (más del doble)
- Tgasto_tipo dejó de ser NaN (1.53)

### 3. Tkz estructuralmente bajo con Hong
- kappa_z1=0.11 solo da Tkz≈0.115 vs target 0.386
- La alta persistencia de Hong (ρ=0.86) comprime el gap formal entre z-alto y z-bajo
- Subir kappa_z1 más (0.15-0.30) puede ayudar pero requiere corridas adicionales

### 4. T5 estructuralmente limitado por Hong
- Con ρ_z=0.86, el ahorro precautorio es alto → K grande → r* bajo → w_F/w_I alto → formal atractiva
- T5 máximo observado: 0.115 con DRS Göbel + A_I=0.99
- Para llegar a 0.19 se necesitaría p_I>1 (como logró el compañero con su código modificado)

## Próximos pasos

1. **Ajuste fino C:** bajar omega_C a 0.55 para ver si T5 sube más (riesgo: p_I>1)
2. **Subir kappa_z1:** probar 0.15, 0.20, 0.30 para cerrar Tkz
3. **Recuperar código del compañero:** pedirle el archivo .m exacto que usó en `C:\Users\HP\Downloads\ie2\`
4. **Probar CRS Göbel:** alpha_I=0.163, beta_I=0.837 con profit_rule='lump'

## Archivos .mat generados

| Corrida | results_*.mat | calib_*.mat |
|---------|-------------|------------|
| A | `outputs/stationary/test_A_replica/results_test_A_replica.mat` | `outputs/stationary/test_A_replica/calib_test_A_replica.mat` |
| B | `outputs/stationary/test_B_kappa110/results_test_B_kappa110.mat` | `outputs/stationary/test_B_kappa110/calib_test_B_kappa110.mat` |
| C | `outputs/stationary/test_C_DRS_Gobel/results_test_C_DRS_Gobel.mat` | `outputs/stationary/test_C_DRS_Gobel/calib_test_C_DRS_Gobel.mat` |
