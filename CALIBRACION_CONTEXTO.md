# HA-IE v10 ARz — Contexto Completo de Calibración

> Autores: John Svante Barraza Ratachi, Enzo Andrés Nevado Martínez  
> Asesor: César Saturnino Salinas Depaz  
> Fecha: 21 Junio 2026  
> Código: `replication_package/run_model_main.m` (2804 líneas)

---

## 1. ESTRUCTURA DEL PAQUETE

```
replication_package/
  run_model_main.m              ← modelo principal (correr este)
  run_replication_main.m        ← wrapper con setenv + Python plots
  calibracion_escenarios.m      ← 3 escenarios (legacy/CRS_Göbel/DRS_Göbel)
  calibracion_setenv_v10_ARz.m  ← setenv base documentado
  convergence_analysis.m        ← análisis Nz × fastdebug
  anexo_matematico.pdf          ← derivación formal (14pp)
  README.md
  inputs/
  outputs/stationary/
  presentation/                 ← Beamer LaTeX
  MIT_borrador/
```

---

## 2. PARÁMETROS FIJOS (NO TOCAR)

| Parámetro | Valor | Fuente | Línea |
|-----------|-------|--------|-------|
| `A_F` | 1.0 | Normalización (numerario) | L322 |
| `al` | 0.636 | Céspedes, Aquije, Sánchez & Vera-Tudela (2014, BCRP REE-28), firmas SUNAT | L324 |
| `d` | 0.10 | Castillo & Rojas (BCRP REE-28) | L325 |
| `ga` | 2 | Estándar HA | L100 |
| `rho` | 0.05 | Estándar HA | L101 |
| `Frisch` | 0.38 | Céspedes & Rendón (2012, BCRP WP 2012-017), EPEN Lima | L102 |
| `tau` | 0.18 | Galindo et al. (2024, BCRP DT-005) | L449 |
| `H_bar` | 1.0 | Normalización | L450 |
| `Nz_ar` | 7 | Hong (2022) ENAHO + discretización Moll | L213 |
| `rho_z_ar` | 0.8600132622 | Hong (2022), ENAHO 2004-2016 panel | L214 |
| `sd_logz_ar` | 0.5417411732 | Hong (2022), ENAHO 2004-2016 panel | L215 |
| `z_process` | 'ou' | Moll HACT Sección 5 | L221 |
| `USE_Q` | 0 | Forzado en ARz (línea 383) | L377 |
| `kappa_min` | 0.0 | Forzado a 0 (línea 426), no overridable | L426 |
| `kappa_extra` | 0.0 | Forzado a 0 (línea 427), no overridable | L427 |

---

## 3. PARÁMETROS INFORMALES (SEGÚN ESCENARIO)

Fuente: Göbel, Grimm & Lay (2013, BCRP WP 2013-001), ENAHO 2002-2006 microempresas

| Escenario | `alpha_I` | `beta_I` | Suma | Tipo | `Pi_I` |
|-----------|-----------|----------|------|------|--------|
| **A) Legacy DRS** | 0.0 | 0.696 | 0.696 | DRS sin K informal | >0 (hours rule) |
| **B) CRS Göbel** | 0.163 | 0.837 | 1.000 | CRS con K informal | =0 (lump rule) |
| **C) DRS Göbel** | 0.118 | 0.605 | 0.723 | DRS con K informal | >0 (hours rule) |

**Nota:** Escenario A es el default en el código. Escenarios B y C activan capital informal (`alpha_I > 0`). La restricción `alpha_I + beta_I <= 1` fue relajada (antes era `< 1`, ahora `<= 1`, línea 353).

Archivo de referencia: `parametros_cobb_douglas_formal_informal_peru.md`

---

## 4. PARÁMETROS A CALIBRAR (MOVER CON `setenv`)

| Parámetro | `setenv` key | Default código | Calibración runner | Target | Regla |
|-----------|-------------|----------------|-------------------|--------|-------|
| `psi_F` | `HA_IE_PSI_F` | 80.0 | 175 | T4 = 0.557 | >0, ratio psi_F/psi_I ~1.5-3 |
| `psi_I` | `HA_IE_PSI_I` | 100.0 | 50 | T4 = 0.557 | >0 |
| `A_I` | `HA_IE_A_I` | 0.3 | 0.305 | T5 = 0.190 | **≤ 1.0** (PTF inf ≤ PTF formal) |
| `kappa_z1` | `HA_IE_KAPPA_Z1` | 0.0 | 0.080 | Tkz = 0.386 | ≥0, solo depende de z |
| `kappa_z_shape`| `HA_IE_KAPPA_Z_SHAPE` | 1.0 | 2.0 | curvatura barrera(z) | >0, 1=lineal, >1=concentra en z bajo |
| `sigma_C` | `HA_IE_SIGMA_C` | 5.0 | 5 | elasticidad F/I | >0 |
| `omega_C` | `HA_IE_OMEGA_C` | 0.4 | 0.58 | peso CES formal | ∈(0,1) |
| `theta` | `HA_IE_THETA` | 1.0 | 1.0 | atenuación informal | ∈(0,1] |
| `nu_I` | `HA_IE_NU_I` | 1.0 | 0.030 | ventaja comparativa | **≤ 1.0, evitar <0.5 salvo último recurso** |
| `debt_prem_chi` | `HA_IE_DEBT_PREM_CHI` | 0.02 | 0.02 | spread base | ≥0 |
| `debt_prem_eta` | `HA_IE_DEBT_PREM_ETA` | 1.0 | 1.25 | curvatura spread(z) | ≥0 |
| `debt_prem_rebate`| `HA_IE_DEBT_PREM_REBATE` | false | '0' | redistribuir spread | 'true'/'false' |
| `amin` | `HA_IE_AMIN` | -0.10 | -0.10 | límite deuda | <0 |

---

## 5. REGLAS DE CONSISTENCIA ECONÓMICA

### 5.1 Restricciones que el código NO verifica (debes chequear post-corrida):

```
1. p_I* ≤ 1     → bien informal debe ser más barato que el formal
   Si p_I > 1: omega_C muy bajo, sigma_C muy alto, o A_I muy bajo

2. A_I ≤ A_F=1  → PTF informal no puede exceder la formal
   Si A_I > 1: inconsistente con "informal = baja productividad"

3. nu_I ∈ [0.5, 1.0]  → ventaja comparativa razonable
   Si nu_I < 0.5: z^nu_I ≈ 1 para todo z → destruye sorting por productividad
   SOLO usar nu_I < 0.5 si todo lo demás falla

4. w_F > w_I     → salario formal > informal
   Si no: psi_F/psi_I mal calibrado o A_I muy alto

5. mass_amin > 0  → debe haber agentes en el límite de deuda
   Si mass_amin = 0: amin muy negativo o chi muy bajo
```

### 5.2 kappa(z) — VERIFICADO en código (líneas 636-651):

```matlab
kappa_F_aa = zeros(I, Ns);           % inicia en 0
kappa_z_vec = zeros(1, Ns);          % vector 1×Ns
for jz = 1:Ns
    low_weight = (max(z) - z(jz)) / (max(z) - min(z));
    low_weight = max(0, min(1, low_weight))^kappa_z_shape;
    kappa_z_vec(jz) = kappa_z2 + (kappa_z1 - kappa_z2) * low_weight;
end
kappa_F_aa = ones(I,1) * kappa_z_vec; % ← MISMO para todo a, varía solo con z ✓
```

**Forma funcional:** `kappa(z) = kappa_z1 * ((z_max - z)/(z_max - z_min))^shape`
- z = z_max → kappa = 0
- z = z_min → kappa = kappa_z1
- shape=1: lineal; shape=2: cuadrático (concentra en z bajo)
- **NO depende de a** ✓

### 5.3 debt_spread(z) — VERIFICADO en código (líneas 653-659):

```matlab
debt_low_weight = (max(z) - z(:)') ./ max(max(z) - min(z), 1e-12);
debt_low_weight = max(0, min(1, debt_low_weight));
debt_spread_z = debt_prem_chi * debt_low_weight.^debt_prem_eta;
debt_spread_aa = ones(I,1) * debt_spread_z;  % ← MISMO para todo a ✓
```

**Forma funcional:** `spread(z) = chi * ((z_max - z)/(z_max - z_min))^eta`
- z = z_max → spread = 0
- z = z_min → spread = chi
- eta=1: lineal; eta>1: concentra en z bajo
- **NO depende de a** ✓
- Solo aplica cuando a < 0: `r*a - spread(z)*max(-a,0)`

---

## 6. DOCUMENTOS DE REFERENCIA

| Doc | Ubicación | Qué contiene |
|-----|-----------|-------------|
| Anexo matemático | `_teoria_md/anexo_matematico/anexo_matematico.pdf` | Derivación formal completa |
| Parámetros CD Perú | `parametros_cobb_douglas_formal_informal_peru.md` | α_K, α_L formal e informal |
| Moll teoría HA | `_teoria_md/Moll_teoria_HA/Moll_teoria_HA.md` | Slides Moll Parte I y II |
| Moll HACT Appendix | `_teoria_md/HACT_Numerical_Appendix/HACT_Numerical_Appendix.md` | Apéndice numérico (FD, upwind, adjunto) |
| Moll labor supply | `_teoria_md/labor_supply/labor_supply.md` | Oferta laboral endógena (Huggett) |
| Restrepo-Echavarria | `pdfs/otros_autores/restrepo_EER_R&R.pdf` | 2 sectores, CES, F/I |
| Horvath | `pdfs/otros_autores/horvath bussines cycles.pdf` | 2 firmas, 2 bienes EG |
| Castillo-Rojas | `_teoria_md/ree-28-castillo-rojas.pdf` | δ=0.10 para Perú |
| Göbel et al. | BCRP WP 2013-001 | α_K informal microempresas |
| Céspedes et al. | BCRP REE-28 (2014) | α_K=0.636 firmas formales |
| Céspedes-Rendón | BCRP WP 2012-017 | Frisch=0.38 |
| Hong (2022) | Mimeo | ρ_z, σ_z ENAHO panel |
| Galindo et al. | BCRP DT-005-2024 | τ=0.18, referencia HACT Perú |
| IE2_ENTREGAFINAL | `IE2_ENTREGAFINAL.docx.md` | Plan de tesis enviado al jurado |
| Presentación | `replication_package/presentation/` | Beamer 18 slides |

---

## 7. COMANDOS PARA CORRER

### 7.1 Escenario A — Legacy DRS (sin K informal)

```matlab
cd('C:\Users\johnb\Documents\GitHub\HA-IE2025\Code\CONTINUOUS_TIME\Aiyagari_firmas\try_endog_labor_2_firms\replication_package')
clear; clc;
setenv('HA_IE_RUN_TAG', 'test_legacy');
setenv('HA_IE_OUTPUT_DIR', fullfile(pwd, 'outputs', 'stationary'));
setenv('HA_IE_FAST_DEBUG', 'true');
setenv('HA_IE_EQ_MODE', '2');
setenv('HA_IE_VERBOSE', '1');
setenv('HA_IE_AMIN', '-0.10');
setenv('HA_IE_Z_PROCESS', 'ou');
setenv('HA_IE_Z_N', '7');
setenv('HA_IE_Z_RHO', '0.8600132622');  % Hong (2022): quarterly 0.963^4
setenv('HA_IE_Z_SD', '0.5417411732');   % Hong (2022): 0.146/sqrt(1-0.963^2)
setenv('HA_IE_PSI_F', '175');
setenv('HA_IE_PSI_I', '50');
setenv('HA_IE_THETA', '1.0');
setenv('HA_IE_NU_I', '1.0');
setenv('HA_IE_SIGMA_C', '5');
setenv('HA_IE_OMEGA_C', '0.58');
setenv('HA_IE_A_I', '0.305');
setenv('HA_IE_ALPHA_I', '0.0');
setenv('HA_IE_BETA_I', '0.696');
setenv('HA_IE_KAPPA_Z1', '0.080');
setenv('HA_IE_KAPPA_Z_SHAPE', '2.0');
setenv('HA_IE_DEBT_PREM_CHI', '0.02');
setenv('HA_IE_DEBT_PREM_ETA', '1.25');
setenv('HA_IE_DEBT_PREM_REBATE', '0');
setenv('HA_IE_INFORMAL_PROFIT_RULE', 'hours');
run_model_main
```

### 7.2 Escenario B — CRS Göbel (con K informal)

```matlab
% Mismos setenv que arriba, CAMBIAR solo:
setenv('HA_IE_RUN_TAG', 'test_crs_gobel');
setenv('HA_IE_ALPHA_I', '0.163');
setenv('HA_IE_BETA_I', '0.837');
setenv('HA_IE_INFORMAL_PROFIT_RULE', 'lump');  % Pi_I=0, no hay beneficio que distribuir
run_model_main
```

### 7.3 Escenario C — DRS Göbel (con K informal)

```matlab
setenv('HA_IE_RUN_TAG', 'test_drs_gobel');
setenv('HA_IE_ALPHA_I', '0.118');
setenv('HA_IE_BETA_I', '0.605');
setenv('HA_IE_INFORMAL_PROFIT_RULE', 'hours');  % Pi_I>0
run_model_main
```

---

## 8. VERIFICACIONES POST-CORRIDA

Después de cada corrida, revisar en el output:

```
1. p_I* < 1.0        → □  (si >1, informal más caro que formal: INCONSISTENTE)
2. A_I ≤ 1.0         → □  (PTF informal ≤ formal)
3. w_F > w_I         → □  (salario formal > informal)
4. T4 ≈ 0.557        → □  (target horas)
5. T5 ≈ 0.190        → □  (target PBI informal)
6. Tkz ≈ 0.386       → □  (target gap formalidad)
7. Tgasto ≈ 1.913    → □  (target gasto relativo)
8. mass_amin > 0     → □  (agentes en límite de deuda)
9. Gini ∈ [0.4, 0.8] → □  (desigualdad razonable)
```

---

## 9. ν_I — NOTA IMPORTANTE

`ν_I = 0.030` está en la calibración actual del runner. Esto significa:
- `z^0.030 ≈ 1` para cualquier z razonable
- La productividad informal NO varía con z → **destruye el sorting por productividad**
- El canal "baja productividad → más informalidad" DESAPARECE

**Regla:** Empezar con `ν_I = 1.0`. Solo bajar si:
1. T4 no se alcanza con psi_F/psi_I
2. Tkz no se alcanza con kappa_z1
3. El sorting cualitativo (más formal para z alto) no aparece

`ν_I < 0.5` debe ser ÚLTIMO RECURSO.
```

## 10. VERSIONES DE ARCHIVOS

| Archivo | Versión | Último cambio |
|---------|---------|--------------|
| `run_model_main.m` | v10 ARz final | CRS constraint relax, params Göbel |
| `anexo_matematico.tex` | 14pp | Firmas actualizadas Céspedes+Göbel |
| `calibracion_escenarios.m` | v1 | 3 escenarios con setenv |
| `convergence_analysis.m` | v1 | NZ × fastdebug grid |
| `calibracion_setenv_v10_ARz.m` | v1 | setenv documentado |
`