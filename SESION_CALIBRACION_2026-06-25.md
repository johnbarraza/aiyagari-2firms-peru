# Sesión Calibración — 2026-06-25

## Resumen ejecutivo

**34 corridas.** De p_I=1.52, Gini=0.34, Tgasto=NaN → **p_I=0.94, T4=0.559, T5=0.180, Tkz=0.382, Tgasto=1.96, Gini=0.414, T1=2.07.**

6/7 targets clavados. K/Y=3.23 es implicancia de al=0.636.

---

## Calibración FINAL v11

```matlab
setenv('HA_IE_RUN_TAG',   'calib_v11_final')
setenv('HA_IE_RHO',        '0.073')       % → K/Y, Gini
setenv('HA_IE_GA',         '1.0')         % log utility → Gini>0.4
setenv('HA_IE_SIGMA_C',    '5')           % sweet spot elasticidad
setenv('HA_IE_OMEGA_C',    '0.56')        % → p_I≈0.94
setenv('HA_IE_A_I',        '1.38')        % → T5≈0.18, PTF informal +38%
setenv('HA_IE_PSI_F',      '110')         % → T4, Tgasto
setenv('HA_IE_PSI_I',      '49')          % → T4
setenv('HA_IE_KAPPA_Z1',   '0.65')        % → Tkz≈0.38
setenv('HA_IE_KAPPA_Z_SHAPE', '1.0')      % lineal: barrera ∝ distancia a z_max
setenv('HA_IE_INFORMAL_PROFIT_RULE', 'hours')
setenv('HA_IE_FAST_DEBUG', '1')
setenv('HA_IE_EQ_MODE',    '2')
setenv('HA_IE_Z_N',        '7')
setenv('HA_IE_Z_RHO',      '0.861')       % Hong (2022)
setenv('HA_IE_Z_SD',       '0.544')       % Hong (2022)
setenv('HA_IE_Z_WIDTH',    '2.5')
setenv('HA_IE_ALPHA_I',    '0.118')       % Göbel et al. (2013)
setenv('HA_IE_BETA_I',     '0.605')       % Göbel et al. (2013)
setenv('HA_IE_THETA',      '1.0')
setenv('HA_IE_NU_I',       '0.6')
setenv('HA_IE_TAU_C',      '0')
setenv('HA_IE_DEBT_PREM_CHI',    '0.02')
setenv('HA_IE_DEBT_PREM_ETA',    '1.25')
setenv('HA_IE_DEBT_PREM_REBATE', '0')
setenv('HA_IE_AMIN',       '-0.002')
setenv('HA_IE_FRISCH',     '0.38')
```

### Targets primarios (calibrados)

| Target | Modelo | Dato | Δ | Instrumento |
|--------|--------|------|---|-------------|
| **p_I** | **0.939** | <1.0 | ✅ | ω_C = 0.56 |
| **T4** | **0.559** | 0.557 | 0.002 | ψ_F/ψ_I = 110/49 |
| **T5** | **0.180** | 0.190 | 0.010 | A_I = 1.38 |
| **Tkz** | **0.382** | 0.386 | 0.004 | κ_z1 = 0.65, shape=1.0 |
| **Tgasto** | **1.963** | 1.913 | 0.050 | Sorting vía ψ + κ_z |

### Validación externa (NO calibrados)

| Target | Modelo | Dato/Ref | Diagnóstico |
|--------|--------|----------|-------------|
| **T1 hogar** w_F/(w_I_hh×θ) | **2.07** | ~2.30 | Prima formal razonable |
| **Gini riqueza** | **0.414** | ≥0.40 | ✅ |
| **Gini gasto** | **0.207** | ~0.40 ENAHO | Bajo (sin shocks idiosinc.) |
| **T5 real** Y_I/(Y_F+Y_I) | **0.189** | — | > T5_nom porque p_I<1 ✅ |
| **T6 gap Q1-Q5 horas inf.** | **0.051** | 0.530 | ❌ Estructural |
| **T4 extensivo** | **0.972** | — | 97% informal-dominantes |
| **Deuda masa a<0** | **0.036** | — | 3.6% con deuda |
| **E[ell_F+ell_I]** | **0.419** | — | Horas totales |

### Equilibrio general

| Variable | Valor |
|----------|-------|
| r* | 0.0682 |
| K* | 8.32 |
| K_F* | 8.00 |
| K_I* | 0.32 |
| w_F bruto | 3.72 |
| w_F neto (1-τ) | 3.05 |
| w_I marginal | 1.24 |
| w_I household | 1.80 |
| Y_F | 2.12 |
| Y_I | 0.49 |
| L_F* | 0.207 |
| L_I* | 0.227 |
| K/Y | 3.23 |

### Sorting por productividad (z)

| z | form_rate | ell_F | Riqueza media | Consumo medio |
|---|-----------|-------|---------------|---------------|
| z_min (0.22) | **13.7%** | 0.034 | 5.1 | 0.53 |
| z_max (3.30) | **51.9%** | 0.265 | 14.6 | 1.67 |
| **Gap** | **0.382** | 0.231 | 9.6 | 1.14 |

✅ Más productivos = más formales, más ricos, más consumo. Dirección correcta.

---

## Parámetros fijos (no calibrados)

| Parámetro | Valor | Fuente |
|-----------|-------|--------|
| al (capital share formal) | 0.636 | Cespedes et al. (2014, BCRP REE-28) |
| d (depreciación) | 0.10 | Castillo & Rojas (BCRP REE-28) |
| α_I (capital share informal) | 0.118 | Göbel et al. (2013) |
| β_I (labor share informal) | 0.605 | Göbel et al. (2013) |
| ρ_z (persistencia AR1 z) | 0.861 | Hong (2022, J. Int. Economics) |
| sd_logz | 0.544 | Hong (2022) |
| Frisch | 0.38 | Literatura |
| τ | 0.18 | IGV Perú |
| H_bar | 1.0 | Normalización |

---

## Hallazgos de la sesión

### 1. ω_C es LA palanca de p_I

ρ no mueve p_I. ω_C controla demanda relativa → p_I. Cada +0.02 ω_C → -0.12 p_I. Con ω_C=0.56, p_I≈0.94.

### 2. σ_C=5 es el sweet spot

σ_C=3: demanda inelástica → p_I alto. σ_C=8: magnifica sesgo pro-informal. σ_C=5: balance.

### 3. γ=1 (log) rompe Gini>0.4

Menor aversión al riesgo → menos ahorro precautorio → más desigualdad.

### 4. κ_z arregla Tkz, no A_I

Barrera formal por productividad (lineal, shape=1.0) genera sorting z. Pero no reemplaza A_I para T5. κ_z1=0.65 da Tkz=0.38.

### 5. A_I > 1 es inevitable con DRS

Con α_I+β_I=0.723, Y_I ∝ A_I^3.61. Para T5=0.19 con p_I<1, A_I≥1.27. A_I=1.38 es el compromiso (PTF informal +38%).

### 6. Frontera ω_C ↔ A_I

| ω_C | p_I | A_I para T5≈0.19 |
|-----|-----|-------------------|
| 0.53 | 1.17 | ~1.10 |
| 0.55 | 1.08 | ~1.15 |
| **0.56** | **0.94** | **~1.38** |
| 0.57 | 0.89 | ~1.55 |
| 0.60 | 0.76 | ~1.80 |

### 7. K/Y=3.23 es estructural con al=0.636

K_F/Y_F = al/(r+d) = 3.79. Informal baja agregado a 3.23. Para K/Y=2.73: al≈0.45.

### 8. Nz=40 no mejora T6 ni Gini

Problema estructural: decisión F/I depende de z (salarios), no de riqueza. Gradiente Q1-Q5 débil. Se documenta como limitación.

### 9. Lump-sum (profits perdidos) empeora Tgasto

Sin profit-sharing al informal, w_I_hh colapsa → informal muy pobre → Tgasto cae a 1.63.

### 10. rule='hours' es superior

Profits del DRS van al trabajador informal (ingreso mixto). Mejor ajuste a datos peruanos donde cuenta-propista recibe ingreso > PMgL.

---

## Grid completo (34 corridas)

| # | Run | ρ | γ | ω_C | A_I | κ_z1 | ψ_F/ψ_I | p_I | T5 | T4 | Tkz | Tgasto | Gini |
|---|-----|---|---|-----|-----|------|---------|-----|-----|-----|-----|--------|------|
| 0 | bench_RHO06 | .060 | 2 | .435 | 1.0 | .30 | 140/55 | 1.52 | .191 | .556 | .15 | 1.77 | .336 |
| 1-6 | ρ grid, σ grid | — | 2 | var | 1.0 | .30 | 140/55 | var | var | var | — | var | var |
| 7 | OM057_AI13 | .065 | 2 | .57 | 1.3 | .30 | 140/48 | 0.93 | .156 | .549 | — | 1.72 | .360 |
| 8-12 | ρ, γ, ψ exploración | var | var | .57 | 1.45 | .30 | var | 0.90 | var | var | — | var | var |
| 13 | GA10_RHO070 | .070 | 1.0 | .57 | 1.55 | .30 | 120/48 | 0.89 | .188 | .554 | — | 1.90 | .406 |
| 14 | GA10_RHO073 | .073 | 1.0 | .57 | 1.55 | .30 | 120/48 | 0.88 | .192 | .556 | — | 1.88 | .418 |
| 15-19 | ω_C + A_I grid | .073 | 1.0 | var | var | .30 | 120/var | var | var | var | — | var | var |
| 20 | GOLDILOCKS | .073 | 1.0 | .56 | 1.42 | .30 | 120/47 | 0.94 | .186 | .555 | .15 | 1.88 | .418 |
| 21-23 | κ_z exploration | .073 | 1.0 | var | var | var | 120/var | var | var | var | var | var | var |
| 24-26 | shape=1.0 + κ_z fine | .073 | 1.0 | .56 | 1.35-1.40 | var | 120/var | 0.93-0.94 | .18 | .56-.57 | .37-.51 | 1.94-1.96 | .42 |
| 27 | ψ_F=110, ψ_I=50 | .073 | 1.0 | .56 | 1.40 | .65 | 110/50 | 0.94 | .181 | .558 | .383 | 1.963 | — |
| 28 | lump-sum test | .073 | 1.0 | .56 | 1.40 | .65 | 110/38 | 0.94 | .179 | .550 | .404 | **1.63** | .414 |
| 29-31 | min A_I search | .073 | 1.0 | .54-.56 | 1.15-1.30 | .50-.70 | 110/var | var | var | var | var | var | var |
| 32 | AI135_KZ65_PSII49 | .073 | 1.0 | .56 | 1.35 | .65 | 110/49 | 0.94 | .176 | .557 | .383 | 1.963 | .414 |
| **33** | **FINAL_AI138** | **.073** | **1.0** | **.56** | **1.38** | **.65** | **110/49** | **0.94** | **.180** | **.559** | **.382** | **1.963** | **.414** |
| 34 | NZ40_AI120 | .073 | 1.0 | .56 | 1.20 | .65 | 110/49 | 0.97 | .160 | .548 | .540 | 1.683 | .414 |

---

## Brechas documentables (para defensa)

1. **K/Y=3.23 vs 2.73.** Causa: al=0.636 (Cespedes, firma-level). Solución: al≈0.45 (macro). Requiere `HA_IE_AL` env var.
2. **T6=0.05 vs 0.53.** Canal riqueza→informalidad débil. Gradiente opera vía z, no vía a.
3. **A_I=1.38 > A_F=1.** PTF informal 38% mayor. Compensa DRS + bajo capital informal.
4. **Gini gasto=0.21 vs 0.40.** Sin shocks idiosincráticos de gasto/ingreso.
5. **T4 extensivo=0.97.** 97% de agentes son informal-dominantes. Pocos formales concentran horas formales.

---

## Archivos .mat

Todos en `outputs/stationary/`. El definitivo: **`grid_FINAL_AI138/`**

---

## Para retomar

```matlab
cd('C:\Users\johnb\Documents\GitHub\HA-IE2025\Code\CONTINUOUS_TIME\Aiyagari_firmas\try_endog_labor_2_firms\replication_package')

% Copiar setenv de arriba (calib_v11_final)
% FAST_DEBUG=false, I=500 para producción (~4-5 horas)
model_main
```

**Próximos pasos:**
1. Agregar `HA_IE_AL` env var → probar al=0.45 para K/Y
2. FAST_DEBUG=false, I=500 → corrida producción
3. Figuras para defensa
4. Discutir con profe: A_I=1.38, K/Y=3.23, T6=0.05
