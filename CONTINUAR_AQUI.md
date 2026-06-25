# CONTINUAR AQUÍ — HA-IE Replication Package

> Última actualización: 2026-06-25. Benchmark: `Rho06_fine` (ρ=0.06).

## Benchmark actual (Rho06_fine)

```matlab
cd('C:\...\replication_package')

setenv('HA_IE_RUN_TAG',   'Rho06_fine')
setenv('HA_IE_FAST_DEBUG', '1')
setenv('HA_IE_EQ_MODE',    '2')
setenv('HA_IE_VERBOSE',    '0')
setenv('HA_IE_R_HI',       '0.20')
setenv('HA_IE_R_LO',       '-0.04')
setenv('HA_IE_Z_N',        '7')
setenv('HA_IE_Z_RHO',      '0.861')
setenv('HA_IE_Z_SD',       '0.544')
setenv('HA_IE_Z_WIDTH',    '2.5')
setenv('HA_IE_RHO',        '0.06')        % Hong: β=0.948 → ρ≈0.053. Perú MPC alto → ρ=0.06
setenv('HA_IE_A_I',        '1.0')
setenv('HA_IE_ALPHA_I',    '0.118')       % Göbel et al. (2013)
setenv('HA_IE_BETA_I',     '0.605')       % Göbel et al. (2013)
setenv('HA_IE_THETA',      '1.0')
setenv('HA_IE_NU_I',       '0.6')
setenv('HA_IE_PSI_F',      '140')
setenv('HA_IE_PSI_I',      '55')
setenv('HA_IE_SIGMA_C',    '8')           % alta sustitución → p_I más bajo
setenv('HA_IE_OMEGA_C',    '0.435')
setenv('HA_IE_TAU_C',      '0')           % IGV off
setenv('HA_IE_KAPPA_Z1',   '0.300')
setenv('HA_IE_KAPPA_Z_SHAPE', '2.0')
setenv('HA_IE_DEBT_PREM_CHI',    '0.02')
setenv('HA_IE_DEBT_PREM_ETA',    '1.25')
setenv('HA_IE_DEBT_PREM_REBATE', '0')
setenv('HA_IE_AMIN',       '-0.002')
setenv('HA_IE_INFORMAL_PROFIT_RULE', 'hours')

model_main
```

## Resultados

| Target | Modelo | Dato | Estado |
|--------|--------|------|--------|
| **T5** PBI informal nominal | **0.1905** | 0.190 | ✅ EXACTO |
| **T4** horas informales | **0.556** | 0.557 | ✅ |
| Tgasto (F-dom/I-dom) | 1.77 | 1.91 | ~ (-0.14) |
| T1 w_F/(w_I_hh·θ) | 1.99 | 2.30 | ~ (-0.31) |
| **Gini riqueza** | **0.336** | 0.4-0.5 | ⬆ mejorando |
| Tkz gap formal z | ~0.14 | 0.386 | ❌ estructural |
| **p_I** | **1.525** | <1 | ⬇ bajando pero >1 |
| **K/Y** | **3.47** | 2.7 | ⬇ mejorando, aún alto |
| r* | 0.055 | — | — |
| K* | 10.55 | — | — |
| K_I | 0.44 | — | — |

## Parámetros clave y sus efectos

| Parámetro | Valor | Efecto al subir | setenv |
|-----------|-------|----------------|--------|
| ρ (impaciencia) | 0.06 | ↓K, ↑r, ↓p_I, ↑Gini | `HA_IE_RHO` |
| σ_C (sustitución F/I) | 8 | ↓p_I, ↓T5 | `HA_IE_SIGMA_C` |
| ω_C (peso CES formal) | 0.435 | ↑ → ↓p_I ↓T5, ↓ → ↑T5 ↑p_I | `HA_IE_OMEGA_C` |
| psi_F/psi_I | 140/55 | ↑ratio → ↑T4, puede romper Tgasto | `HA_IE_PSI_F`, `_I` |
| A_I | 1.0 | ↑T5, ↑Y_I | `HA_IE_A_I` |
| κ_z1 | 0.30 | ↑Tkz (poco) | `HA_IE_KAPPA_Z1` |
| τ_c (IGV) | 0 | ↑ → ↑T5, ↓Gini (regresivo) | `HA_IE_TAU_C` |
| amin | -0.002 | Más negativo: ↑Gini poco | `HA_IE_AMIN` |
| γ (risk aversion) | 2 | 1 rompió (K subió) | `HA_IE_GA` |
| Frisch | 0.38 | 0.28 empeoró | `HA_IE_FRISCH` |

## Nuevos parámetros disponibles (agregados 2026-06-25)

```
HA_IE_RHO     — discount rate (default 0.05)
HA_IE_GA      — risk aversion (default 2). ga=1 usa log utility
HA_IE_FRISCH  — Frisch elasticity (default 0.38)
HA_IE_TAU_C   — IGV on formal consumption (default 0.18, 0=off)
```

## Pendiente para mejorar

### Prioridad 1: Bajar p_I hacia 1
- **Problema:** p_I=1.52 porque Y_I es pequeño relativo a demanda de c_I
- **Canales:** subir ρ más (0.065-0.07), ajustar psi para mantener Tgasto
- **Riesgo:** Tgasto se vuelve NaN si todos son informal-dominantes
- **Alternativa:** cambiar utilidad a Horvath (no-separable) para reducir auto-aseguro

### Prioridad 2: Bajar K/Y hacia 2.7
- **Problema:** K/Y=3.47, Perú debería ser más bajo (menos ahorro, más impacientes)
- **Canal:** ρ↑ → K↓ → K/Y↓
- **Trade-off:** con ρ>0.065, Tgasto muere. Toca ajustar psi_F/psi_I simultáneamente

### Prioridad 3: Subir Gini a 0.4-0.5
- **Problema:** auto-aseguro vía oferta laboral comprime riqueza
- **Canales:** ρ↑ ayuda, amin más negativo ayuda poco
- **Estructural:** modelo HA estándar sin entrepreneurs/herencias

### Prioridad 4: Subir Tkz a 0.386
- **Problema:** κ_z1 tiene efecto marginal decreciente (0.01→0.30 solo sube Tkz 0.10→0.14)
- **Estructural:** con ρ_z=0.86 (Hong), el sorting por z es natural, κ_z añade poco

## Archivos clave generados

| Archivo | Contenido |
|---------|-----------|
| `AUDITORIA_NUMERICA.md` | Validación código vs Moll, Yanagimoto, Rafales, Galindo |
| `SESION_CALIBRACION_2026-06-24.md` | Bitácora completa 30+ corridas |
| `RESULTADOS_CORRIDAS_ABC.md` | Comparación primeras corridas |
| `REVISION_ou_prima_calib_try3.md` | Revisión run del compañero |

## Corridas en outputs/stationary/

Las más relevantes:
- `test_A_replica` — Réplica compañero (NO reproduce, código distinto)
- `test_G_AI10_om046` — Primer T5=0.19 (σ=5, p_I=1.51)
- `test_N3_kappa30` — T5=0.195, T4=0.556, Tgasto=1.82
- `test_O2_sig8_om0425` — p_I=1.60 con σ=8
- `test_T_Nz7_debt` — Nz=7 validación (mismos resultados, ~7 min)
- `test_RHO06` — ρ=0.06: p_I=1.55, Gini=0.34, T5=0.195
- **`test_RHO06_fine`** — 🏆 BENCHMARK: T5=0.1905, T4=0.556, p_I=1.525, K/Y=3.47

## Cómo correr desde cero

```matlab
cd('C:\Users\johnb\Documents\GitHub\HA-IE2025\Code\CONTINUOUS_TIME\Aiyagari_firmas\try_endog_labor_2_firms\replication_package')
% Copiar setenv del benchmark arriba
model_main
```
