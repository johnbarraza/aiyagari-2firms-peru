# Revisión: `ou_prima_calib_try3` — 2026-06-24

> ⚠️ Corrida en `C:\Users\HP\Downloads\ie2\` (máquina HP, NO este repo).
> Usa `aiyagari_2firms_v10_R2_precio_endogeno_ARz_debtprem.m` (archivo viejo, NO `model_main.m` del replication_package).
> El `run_metadata.txt` en `mat_outputs/` es de una corrida anterior (2026-06-17) con resultados distintos (Nz=15, r*=0.050, p_I=1.41, T5=0.051). Los resultados analizados aquí vienen del console output que el usuario pegó.
> Próximo paso: migrar estos setenv al replication_package (`model_main.m`).

---

## ⭐ RESULTADOS CORRIDAS A/B/C (2026-06-24, ejecutado en este repo)

Se corrieron 3 variantes con `model_main.m` (Nz=14, fast debug, amin=-0.002):

| Variable | A: Réplica compa | B: κ=0.11 | C: DRS Göbel K | Target |
|----------|-----------------|-----------|----------------|--------|
| alpha_I / beta_I | 0.0 / 0.60 | 0.0 / 0.60 | **0.118 / 0.605** | — |
| A_I | 0.5 | 0.5 | **0.99** | ≤1 |
| psi_F/psi_I | 100/75 | 100/75 | **180/50** | — |
| theta | 0.55 | 0.55 | **1.0** | — |
| omega_C | 0.55 | 0.55 | **0.57** | — |
| kappa_z1 | 0.01 | **0.11** | 0.11 | — |
| **r\*** | 0.0497 | 0.0495 | ~0.05 | — |
| **p_I** | 1.407 | 1.404 | **1.010** ⭐ | <1 |
| **K_I** | 0 | 0 | **0.265** ⭐ | >0 |
| **w_F/w_I_hh** | 4.39 | 4.42 | **3.35** | ~2.30 |
| **T4** | 0.412 | 0.413 | **0.533** ✅ | 0.557 |
| **T5 nom** | 0.051 | 0.051 | **0.115** ⬆ | 0.190 |
| **Tkz** | 0.101 | 0.113 | 0.115 | 0.386 |
| **Tgasto** | NaN | NaN | **1.532** ✅ | 1.913 |
| **T1 marg** | 7.32 | 7.37 | 4.87 | ~2.30 |
| **Gini** | 0.262 | 0.261 | — | ~0.68 |

### Conclusiones post-corrida

1. **Código compañero ≠ model_main.** La corrida A (réplica exacta) da r*=0.050, p_I=1.41, T5=0.051 — totalmente distinto a lo reportado por el compa (r*=0.033, p_I=1.05, T5=0.193). El `run_metadata.txt` del repo (Jun 17) SÍ coincide con model_main. **El compañero usó código modificado.**

2. **DRS Göbel (C) es el camino correcto.** K_I>0 por primera vez. p_I casi <1 (1.01). T4 cerca (0.53 vs 0.56). T5 subió al doble (0.12). Tgasto_tipo funciona (1.53).

3. **T5=0.19 no alcanzable sin p_I>1 o código modificado.** Con Hong (ρ=0.86), ahorro precautorio alto → r*≈0.05 → w_F/w_I≈3.4-4.9 → informal poco atractiva. Límite estructural.

4. **Tkz estancado ~0.115.** Subir kappa_z1 de 0.11 a 0.15-0.30 puede ayudar.

Archivos .mat: `outputs/stationary/test_A_replica/`, `test_B_kappa110/`, `test_C_DRS_Gobel/`.
Ver comparación completa en `RESULTADOS_CORRIDAS_ABC.md`.

## 1. Verificación Hong (2022) — proceso z

| Concepto | Valor usado | Hong (2022) JIE | Match |
|----------|------------|-----------------|-------|
| ρ_z (persistencia anual) | 0.861 | 0.860 (0.963⁴) | ✅ Δ=+0.001 |
| σ_logz (sd estacionaria) | 0.544 | 0.542 (0.146/√(1-0.963²)) | ✅ Δ=+0.002 |
| Nz | 40 | — | ⚠️ Overkill para exploración |
| Proceso | OU (continuous-time) | OU | ✅ |
| width_z | 2.5 | √(Nz-1)=6.24 default | ⚠️ width=2.5 trunca colas |

**Veredicto:** Valores Hong OK. `width_z_ar=2.5` con Nz=40 trunca las colas de la distribución OU — usar `width_z_ar=sqrt(Nz-1)≈6.24` para Nz=40, o bajar a Nz=14 con width≈3.6 (balance velocidad/precisión según `CONTINUAR_AQUI.md`).

## 2. Verificación firma formal — Céspedes et al. (2014, BCRP REE-28)

| Concepto | Valor correcto | En corrida | Match |
|----------|---------------|------------|-------|
| α (capital share) | 0.636 | Hardcodeado en código (línea 336) | ✅ |
| δ (depreciación) | 0.10 | Hardcodeado en código (línea 337) | ✅ |
| A_F (PTF formal) | 1.0 | Hardcodeado en código (línea 335) | ✅ |
| CRS | α + (1-α) = 1 | Sí (0.636+0.364=1) | ✅ |

**Veredicto:** Firma formal correcta. Céspedes et al. (2014) usa datos SUNAT 2002-2011 a nivel de firma.

## 3. Resultados — targets vs datos

### 3.1 Resumen de parámetros usados

```
psi_F=100, psi_I=75       → ratio=1.33 (replication rec: 180/50=3.6)
A_I=0.5, alpha_I=0        → sin capital informal (legacy DRS)
beta_I=0.60                → NO es Göbel DRS (0.605) ni CRS (0.837)
theta=0.55                 → atenuación informal (replication rec: 1.0)
nu_I=0.60                  → ventaja comparativa (OK, dentro [0.4,0.8])
omega_C=0.55, sigma_C=5    → CES (replication rec: ω_C=0.57-0.65)
kappa_z1=0.01, shape=2.0   → barrera z MINÚSCULA (replication rec: 0.110)
amin=-0.002                → límite deuda CASI CERO (replication rec: -1.0)
debt_prem: chi=0.02, eta=1.25 → OK
```

### 3.2 Targets

| Target | Modelo | Dato | Brecha | Diagnóstico |
|--------|--------|------|--------|-------------|
| **p_I < 1** | **1.048** ✗ | <1 | +0.048 | Violado por poquito. Usuario dice OK si targets cierran. |
| **T4** (horas inf.) | 0.4757 | 0.507 | -0.031 | Cerca. psi_F/psi_I=1.33 muy bajo → informal recibe poco. |
| **T5** (PBI nom. inf.) | 0.1930 ✅ | 0.190 | +0.003 | **¡HIT!** Mejor logrado hasta ahora con Hong. |
| **Tkz** (gap formal z₂-z₁) | 0.1066 | 0.386 | -0.279 | Lejos. kappa_z1=0.01 ridículamente bajo. |
| **Tgasto_tipo** | 1.5178 | 1.913 | -0.395 | Lejos. Sorting z→gasto débil. |
| **T6** (gap Q1-Q5) | 0.0317 | 0.530 | -0.498 | Muy lejos. Casi sin gradiente de informalidad por riqueza. |
| **T1** w_F/(w_I_hh·θ) | 2.256 | ~2.30 | -0.044 | ¡Cerca! Pero es household, no marginal. |
| **Gini riqueza** | 0.5362 | ~0.68 | -0.144 | Aceptable para modelo HA básico. |

### 3.3 Estructura de producción

```
Y_F = 0.6854, Y_I = 0.1564
K_F = 2.8998, K_I = 0.0000  ← SIN capital informal (alpha_I=0)
w_F = 1.4132, w_I_marg = 0.6830
r* = 0.032731
L_F = 0.3153, L_I = 0.1441
```

## 4. Problemas detectados

### 4.1 BAJO (pospuesto): amin = -0.002 (prácticamente cero)
- Masa en amin = 8.5%, pero todos pegados a a=0
- Deuda máxima = 0.2% del ingreso medio → spread deuda IRRELEVANTE
- Pagos prima deuda = 0.000003 → canal deuda NO OPERA
- **Usuario: no tocar amin por ahora.** Fix pospuesto.

### 4.2 ALTO: kappa_z1 = 0.01 (barrera z minúscula)
- Tkz = 0.107 vs target 0.386
- Con kappa_z_shape=2, barrera concentrada en z más bajo pero kappa_z1=0.01 es insignificante
- form_rate_z1=0.469, form_rate_z2=0.576 → gap de solo 10.7pp
- **Fix:** `setenv('HA_IE_KAPPA_Z1','0.110')` o mayor (0.12-0.15)

### 4.3 MEDIO: psi_F/psi_I = 100/75 = 1.33 (ratio muy bajo)
- Replication recomienda 180/50 = 3.6
- Con ratio 1.33, informal es muy atractiva en desutilidad → T4 tiende a subir
- Pero como A_I=0.5 (bajo), el efecto ingreso compensa
- **Fix:** Probar psi_F=180, psi_I=50 (ratio 3.6, benchmark replication)

### 4.4 MEDIO: theta = 0.55 (atenuación informal agresiva)
- Replication recomienda theta=1.0
- theta<1 reduce productividad efectiva informal en TODOS los z
- Con nu_I=0.6, efecto combinado: z^0.6 * 0.55 → doble atenuación
- **Fix:** Probar theta=1.0 primero, solo bajar si T4 no cierra

### 4.5 BAJO: width_z_ar = 2.5 con Nz=40 (colas truncadas)
- Para Nz=40, width óptimo ≈ √39 ≈ 6.24
- width=2.5 trunca la distribución OU → z_max y z_min más cercanos
- Tkz subestimado porque gap z₂-z₁ es menor
- **Fix:** Omitir width (usar default) o Nz=14 con width=3.6

### 4.6 BAJO: Código viejo, no replication_package
- Corre `aiyagari_2firms_v10_R2_precio_endogeno_ARz_debtprem.m` desde `C:\Users\HP\Downloads\ie2\`
- NO usa `model_main.m` del replication_package
- **Fix:** Migrar setenv al replication_package

## 5. Próximas pruebas (orden de prioridad)

### Prueba 1: Corregir amin + kappa_z1 (mínimo viable)
```matlab
% Usar model_main.m del replication_package
cd('C:\Users\johnb\Documents\GitHub\HA-IE2025\Code\CONTINUOUS_TIME\Aiyagari_firmas\try_endog_labor_2_firms\replication_package')

setenv('HA_IE_RUN_TAG', 'test_hong_nz14_fix_amin_kappa')
setenv('HA_IE_Z_PROCESS', 'ou')
setenv('HA_IE_Z_N', '14')            % 14 para exploración (CONTINUAR_AQUI.md)
setenv('HA_IE_Z_RHO', '0.8600132622')
setenv('HA_IE_Z_SD', '0.5417411732')
setenv('HA_IE_FAST_DEBUG', '1')

% Corregir amin y kappa_z1
setenv('HA_IE_AMIN', '-1.0')         % ← CRÍTICO: permitir deuda
setenv('HA_IE_KAPPA_Z1', '0.110')    % ← Subir de 0.01 a benchmark
setenv('HA_IE_KAPPA_Z_SHAPE', '2.0')

% Mantener lo que funcionó para T5
setenv('HA_IE_PSI_F', '100')
setenv('HA_IE_PSI_I', '75')
setenv('HA_IE_A_I', '0.5')
setenv('HA_IE_ALPHA_I', '0.0')       % sin K informal
setenv('HA_IE_BETA_I', '0.60')
setenv('HA_IE_THETA', '0.55')
setenv('HA_IE_NU_I', '0.6')
setenv('HA_IE_OMEGA_C', '0.55')
setenv('HA_IE_SIGMA_C', '5')

setenv('HA_IE_DEBT_PREM_CHI', '0.02')
setenv('HA_IE_DEBT_PREM_ETA', '1.25')
setenv('HA_IE_DEBT_PREM_REBATE', '0')
setenv('HA_IE_INFORMAL_PROFIT_RULE', 'hours')
setenv('HA_IE_R_HI', '0.15')

model_main
```
**Qué esperar:** Tkz debe subir (kappa_z1=0.110). T5 puede bajar un poco (más deuda → más ahorro precautorio → K sube → r* baja → w_F sube). p_I puede moverse.

### Prueba 2: Subir psi_F/psi_I al benchmark
```matlab
% Mismo que Prueba 1, cambiar:
setenv('HA_IE_RUN_TAG', 'test_hong_nz14_psi_bench')
setenv('HA_IE_PSI_F', '180')          % benchmark replication
setenv('HA_IE_PSI_I', '50')           % benchmark replication → ratio=3.6
setenv('HA_IE_THETA', '1.0')          % quitar atenuación theta
```
**Qué esperar:** T4 debe acercarse a 0.507-0.557. T1 w_F/(w_I·θ) debe bajar hacia 2.30.

### Prueba 3: Capital informal DRS Göbel ⭐ NUEVO
```matlab
% Mismo que Prueba 2, agregar K informal:
setenv('HA_IE_RUN_TAG', 'test_hong_nz14_DRS_Gobel_K')
setenv('HA_IE_ALPHA_I', '0.118')      % Göbel et al. (2013)
setenv('HA_IE_BETA_I', '0.605')       % Göbel et al. (2013)
setenv('HA_IE_A_I', '0.99')           % SUBIR PTF informal (K informal absorbe parte)
setenv('HA_IE_INFORMAL_PROFIT_RULE', 'hours')  % Pi_I>0 con DRS
setenv('HA_IE_OMEGA_C', '0.57')       % ajustar para p_I<1
```
**Qué esperar:** K_I > 0 por primera vez. Y_I sube (más insumos). p_I puede bajar (más oferta informal). T5 nominal puede subir. r* sube (más demanda de capital). w_F/w_I puede mejorar.

### Prueba 4: Ajuste fino omega_C para p_I < 1
```matlab
% Si p_I > 1 en Prueba 3, subir omega_C:
setenv('HA_IE_RUN_TAG', 'test_hong_nz14_DRS_om060')
setenv('HA_IE_OMEGA_C', '0.60')
% Si p_I < 0.85, bajar omega_C para más T5:
setenv('HA_IE_OMEGA_C', '0.53')
```

### Prueba 5: Subir kappa_z1 para Tkz
```matlab
% Una vez p_I<1 y T5 cerca de 0.19:
setenv('HA_IE_RUN_TAG', 'test_hong_nz14_DRS_k120')
setenv('HA_IE_KAPPA_Z1', '0.120')
% Probar 0.130, 0.150 si Tkz no llega a 0.386
```

## 6. Veredicto general

### Lo que funciona ✅
- **T5 = 0.193**: PRIMERA VEZ que T5 da en el clavo con Hong (2022). Excelente.
- **p_I = 1.048**: solo 4.8% arriba de 1. Usuario acepta.
- **T1 household = 2.26**: cerca del reference BCR 2.30.
- **r* = 0.033**: razonable para modelo HA anual.
- **Gini riqueza = 0.536**: razonable.

### Lo que no funciona ❌
- **amin = -0.002**: deuda irrelevante. Canal deuda no opera. Urgente corregir.
- **kappa_z1 = 0.01**: barrera z insignificante. Tkz = 0.107 vs 0.386. Subir 10x.
- **T6 = 0.032**: casi sin gradiente de informalidad por riqueza. Requiere amin más negativo + kappa_z1 más alto.
- **theta = 0.55**: atenuación doble con nu_I=0.6. Usar theta=1.0 primero.
- **K_I = 0**: sin capital informal. Probar DRS Göbel.

### Recomendación
1. **Primero:** Corregir amin=-1.0 y kappa_z1=0.110 (Prueba 1). Son fixes mecánicos.
2. **Segundo:** Migrar a `model_main.m` del replication_package (código más limpio, mismo motor).
3. **Tercero:** Probar capital informal DRS Göbel (Prueba 3) — puede resolver tensión p_I vs T5.
4. **Cuarto:** Ajuste fino de omega_C para p_I ≤ 1.02 (margen laxo aceptado por usuario).

## 7. Notas técnicas

### ¿Por qué T5=0.193 funciona con A_I=0.5 y alpha_I=0?
- Sin capital informal, Y_I = A_I * L_I^beta_I = 0.5 * L_I^0.6
- p_I = 1.048 > 1 infla el PBI nominal informal
- T5_nom = p_I*Y_I/(Y_F + p_I*Y_I) = 0.193
- **T5 real** = Y_I/(Y_F+Y_I) = 0.186 (más bajo, pero el target es nominal)
- El "truco" es p_I > 1: infla el numerador nominal. Con p_I ≤ 1, T5 bajaría.

### ¿Por qué Tkz no sube con kappa_z1=0.01?
- A z_min, kappa(z_min) = kappa_z1 * 1^shape = 0.01
- Esto es 0.01 unidades de costo adicional sobre consumo formal
- Con c ≈ 0.5-0.7, el costo relativo es ~1.5-2% — insignificante
- Se necesita kappa_z1 ≥ 0.10 para que la barrera muerda

### Hong vs ENAHO GMM
- Hong (2022): ρ_z=0.860, σ_logz=0.542 → mayor persistencia, menor varianza cruzada
- ENAHO GMM propio: ρ_F=0.485, sd_F=0.709 → menor persistencia, mayor varianza
- Con Hong, ahorro precautorio es mayor → K sube → r* baja → w_F/w_I se dispara
- Esto hace que T5 sea ESTRUCTURALMENTE más bajo con Hong que con ENAHO GMM
- Solo se logra T5≈0.19 con p_I>1 (inflando numerador nominal) o con capital informal
