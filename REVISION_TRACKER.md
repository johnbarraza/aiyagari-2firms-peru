# REVISION TRACKER — HA-IE Replication Package

> Última actualización: 2026-06-26.
> Propósito: tracking de correcciones pendientes al código, al doc y a la calibración.
> Auditar y actualizar este archivo cada sesión.

---

## JERARQUÍA DE TARGETS

| Nivel | Momento | Dato Perú | Fuente |
|-------|---------|-----------|--------|
| **PRIMARIO** | T4 — share horas informal | 0.557 | INEI Cuenta Satélite 2021 |
| **PRIMARIO** | T5 — share PBI informal | 0.190 | INEI Cuenta Satélite 2021 |
| secundario | Tkz — gap formalidad por z | 0.386 | ENAHO quintiles |
| secundario | Tgasto_tipo — ratio gasto Q5/Q1 | 1.913 | ENAHO |
| secundario | p_I — precio bien informal | <1 (consistencia) | teoría |
| validación externa | Gini_gasto | 0.401 | Banco Mundial (consumo, no riqueza) |
| descriptivo | Gini_a (riqueza) | sin target formal | — |

> **Nota Gini:** BM 0.401 es Gini de consumo/gasto (ENAHO-based), NO de riqueza.
> No usar como target de `Gini_a`. El modelo debe computar Gini_gasto separado para comparar.
> Gini_a del modelo es desconocido actualmente (no se ha extraído de los .mat).

---

## ESTADO ACTUAL DE CORRIDAS

| Run tag | FAST_DEBUG | I | Nz | A_I | psi_F | psi_I | κ_z1 | T4 | T5 | Tkz | Tgasto | r* | p_I | Gini_a | Gini_gasto |
|---------|------------|---|----|-----|-------|-------|------|----|----|-----|--------|----|-----|--------|------------|
| `test_kz38_psii34` | ✅ true | 200 | 40 | 0.95 | 55 | 34 | 0.38 | 0.513 | 0.182 | 0.318 | 1.458 | 0.066 | 0.938 | ? | ? |
| `final_newCD_tuned` | ✅ true | 200 | 40 | 0.88 | 80 | 38 | 0.45 | 0.538 | 0.179 | ? | ? | 0.065 | 0.937 | ? | ? |
| **Dato Peru** | — | — | — | — | — | — | — | **0.557** | **0.190** | **0.386** | **1.913** | — | — | — | **0.401** |

**NINGUNA CORRIDA ES PRODUCCIÓN** — ambas usan `FAST_DEBUG=true` (I=200, maxit=40, tolerancias flojas).
La corrida canónica de producción (I=500, FAST_DEBUG=false) está pendiente.

---

## BUGS CÓDIGO — model_main.m

### [ ] BUG-1: `FAST_DEBUG_RUN = true` hardcodeado (línea 131) — ALTO
```matlab
% ACTUAL (incorrecto como default):
FAST_DEBUG_RUN = true;
% CORRECCIÓN:
FAST_DEBUG_RUN = false;
```
**Impacto:** cualquiera que corra sin setenv obtiene resultados de debug (I=200) creyendo que es producción.

### [ ] BUG-2: `A_F` local en `ces_consumption_from_dV_v10` pisa global (línea 2282) — MEDIO
```matlab
% ACTUAL (pisa el global A_F = TFP formal):
A_F = omega_C.^(1/eta_C);
A_Ionly = max(1-omega_C, 1e-12).^(1/eta_C);
% CORRECCIÓN:
A_ces_F = omega_C.^(1/eta_C);
A_ces_I = max(1-omega_C, 1e-12).^(1/eta_C);
% (renombrar también A_Ionly → A_ces_I en las líneas siguientes)
```

### [ ] BUG-3: `tol_wI` absoluta para `Pi_I` — escala distinta (línea 2035) — MEDIO
```matlab
% ACTUAL:
if abs(w_I_new - w_I) < tol_wI && abs(Pi_I_new - Pi_I_share) < tol_wI
% CORRECCIÓN (relativa para Pi_I):
if abs(w_I_new - w_I) < tol_wI && ...
   abs(Pi_I_new - Pi_I_share) / max(Pi_I_share, 1e-8) < tol_wI
```
**Impacto:** Pi_I ≈ 0.01–0.05 es más pequeño que w_I ≈ 0.1–0.3. La tolerancia absoluta puede disparar exit prematuro en w_I.

### [ ] LIMPIEZA-4: Código muerto `if false` (líneas 1310–1330) — BAJO
Bloque de `fprintf` dentro de `if false`. Borrar.

### [ ] LIMPIEZA-5: `addpath` duplicado (líneas 36–42 y 74–82) — BAJO
Mismos paths agregados dos veces. Eliminar bloque líneas 36–42.

### [ ] LIMPIEZA-6: `kappa_extra = 0` reseteado dos veces (líneas 439–440 y 453–454) — TRIVIAL
Borrar segundo reset.

---

## BUGS DOCUMENTACIÓN — CONTINUAR_AQUI.md

### [ ] DOC-1: `RECALIBRACION_CD.md` referenciado pero no existe
Tabla de docs línea 177. Borrar fila o crear el archivo.

### [ ] DOC-2: Script base tiene `HA_IE_FAST_DEBUG = '1'` (línea 51)
Quien copia el bloque "Cómo correr la calibración base" obtiene debug run.
Cambiar a `'0'` o agregar comentario `% CAMBIAR A '0' PARA PRODUCCIÓN`.

### [ ] DOC-3: Prueba pendiente #1 contradice el script base
Script base tiene `HA_IE_AMIN = '-0.05'`, pero prueba #1 dice "base usa -1.0". Aclarar.

### [ ] DOC-4: `final_newCD_tuned` en tabla sin momentos ni nota de FAST_DEBUG
Agregar columna con T4=0.538, T5=0.179, r*=0.065 y nota "⚠️ FAST_DEBUG".

### [ ] DOC-5: No está claro cuál es la corrida oficial para la tesis
`test_kz38_psii34` dice "Mejor balance" pero `final_newCD_tuned` es la graficada.
Declarar explícitamente cuál va a la tesis y cuál es exploración.

---

## CALIBRACIÓN — PENDIENTES

### [ ] CAL-1: Correr producción de la mejor configuración — PRIORIDAD ALTA
La corrida canónica debe ser FAST_DEBUG=false, I=500, zdrift_npts=80.
Configuración base: `test_kz38_psii34` (A_I=0.95, psi_F=55, psi_I=34, κ_z=0.38).

```matlab
setenv('HA_IE_FAST_DEBUG', '0')   % PRODUCCIÓN
setenv('HA_IE_RUN_TAG',    'PRODUCCION_v1')
setenv('HA_IE_RHO',        '0.073')
setenv('HA_IE_GA',         '1.0')
setenv('HA_IE_SIGMA_C',    '5')
setenv('HA_IE_OMEGA_C',    '0.56')
setenv('HA_IE_A_I',        '0.95')
setenv('HA_IE_PSI_F',      '55')
setenv('HA_IE_PSI_I',      '34')
setenv('HA_IE_KAPPA_Z1',   '0.38')
setenv('HA_IE_KAPPA_Z_SHAPE', '1.0')
setenv('HA_IE_INFORMAL_PROFIT_RULE', 'hours')
setenv('HA_IE_NU_I',       '0.6')
setenv('HA_IE_AL',         '0.573')
setenv('HA_IE_ALPHA_I',    '0.220')
setenv('HA_IE_BETA_I',     '0.619')
setenv('HA_IE_THETA',      '1.0')
setenv('HA_IE_Z_N',        '40')
setenv('HA_IE_Z_RHO',      '0.861')
setenv('HA_IE_Z_SD',       '0.544')
setenv('HA_IE_Z_WIDTH',    '2.5')
setenv('HA_IE_EQ_MODE',    '2')
setenv('HA_IE_VERBOSE',    '0')
setenv('HA_IE_R_HI',       '0.20')
setenv('HA_IE_R_LO',       '-0.04')
setenv('HA_IE_TAU_C',      '0')
setenv('HA_IE_DEBT_PREM_CHI',    '0.02')
setenv('HA_IE_DEBT_PREM_ETA',    '1.0')
setenv('HA_IE_DEBT_PREM_REBATE', '0')
setenv('HA_IE_AMIN',       '-1.0')
setenv('HA_IE_FRISCH',     '0.38')
model_main
```

Targets esperados después de debug (I=200): T4=0.513, T5=0.182, Tkz=0.318, r*=0.066.
Con I=500 los momentos pueden cambiar — registrar aquí al completar.

### [ ] CAL-2: Subir Tkz de 0.318 → 0.386 — PENDIENTE
- Prueba A: `κ_z1 = 0.42` (tag `test_kz042`) — ¿cuánto sube Tkz sin mover T4?
- Prueba B: `κ_z1 = 0.46` — cota superior antes de que form_rate_z1 → 0

### [ ] CAL-3: Subir T5 de 0.182 → 0.190 — PENDIENTE
- Prueba A: `A_I = 0.98` (tag `test_AI098`) — riesgo: sube Tkz también
- Prueba B: `A_I = 0.97 + κ_z1 = 0.40` conjunto

### [ ] CAL-4: Subir Tgasto_tipo de 1.458 → 1.913 — PENDIENTE (brecha grande)
- Canal: sorting riqueza/z. Difícil de mover sin cambiar omega_C.
- Prueba A: `omega_C = 0.60` — sube demanda formal
- Prueba B: `amin = -0.05` — restringe crédito → consumo ≈ ingreso → más sorting

### [ ] CAL-5: Completar tabla de momentos para `final_newCD_tuned`
Tkz, Tgasto_tipo y Gini_a no están en el metadata. Correr `calib = load(...)` y extraer.

---

## CHECKLIST DE SESIÓN (marcar al completar)

Antes de cerrar sesión, verificar:

- [ ] Este archivo actualizado con resultados nuevos
- [ ] CONTINUAR_AQUI.md actualizado si cambió la mejor corrida
- [ ] Commit en replication_package con tag de la corrida
- [ ] Si se corrió producción: mover .mat a `outputs/stationary/PRODUCCION_v1/`

---

## HISTORIAL DE CORRIDAS (agregar una fila por sesión)

| Fecha | Tag | FAST_DEBUG | T4 | T5 | Tkz | Tgasto | Nota |
|-------|-----|------------|----|----|-----|--------|------|
| 2026-06-25 | `final_newCD_tuned` | true | 0.538 | 0.179 | ? | ? | A_I=0.88, psi_F=80 |
| 2026-06-26 | `test_kz38_psii34` | true | 0.513 | 0.182 | 0.318 | 1.458 | A_I=0.95, psi_I=34, κ_z=0.38 |
