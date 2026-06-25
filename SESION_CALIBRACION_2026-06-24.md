# Sesión Calibración — 2026-06-24

> Corridas ejecutadas con `model_main.m` (MATLAB R2025b), Nz=14, fast debug (I=200).

## 1. Auditoría numérica (ver `AUDITORIA_NUMERICA.md`)

**model_main.m validado contra 4 referencias:**
- Moll: fórmulas OU idénticas ✅
- Yanagimoto (2025): HACT canónico ✅
- Rafales-Vázquez (2026): nuestro upwind más robusto ✅
- Galindo et al. (2024): spread(z) proxy válido ✅

**Veredicto:** Código correcto. Problemas son de calibración, no numéricos.

## 2. Parámetros fijos (NO TOCAR)

| Parámetro | Valor | Fuente |
|-----------|-------|--------|
| ρ_z | 0.860 | Hong (2022), ENAHO panel 2004-2016 |
| sd_logz | 0.542 | Hong (2022) |
| α_F | 0.636 | Céspedes et al. (2014), SUNAT |
| δ | 0.10 | Castillo & Rojas, BCRP REE-28 |
| τ | 0.18 | Galindo et al. (2024) |
| ρ | 0.05 | Estándar HA |
| γ | 2 | Estándar HA |
| Frisch | 0.38 | Céspedes & Rendón (2012) |
| H̄ | 1.0 | Normalización |
| z_process | 'ou' | OU en LOGS (correcto para earnings) |

## 3. Calibración — evolución de corridas

### Fase 1: Sin capital informal (α_I=0)

| Run | psi_F/I | θ | ω_C | κ_z1 | p_I | T4 | T5 | Nota |
|-----|---------|---|-----|------|-----|----|----|------|
| A | 100/75 | 0.55 | 0.55 | 0.01 | 1.41 | 0.41 | 0.051 | Réplica compañero — NO reproduce |
| B | 100/75 | 0.55 | 0.55 | 0.11 | 1.40 | 0.41 | 0.051 | κ no ayuda sin K informal |

**Hallazgo:** Código del compañero (HP) ≠ model_main. El compa usó versión modificada.

### Fase 2: DRS Göbel (α_I=0.118, β_I=0.605)

| Run | psi_F/I | ω_C | σ_C | A_I | κ_z1 | p_I | T4 | T5 | Tgasto | Gini | Tkz | T1 hh |
|-----|---------|-----|-----|-----|------|-----|----|----|--------|------|-----|--------|
| C | 180/50 | 0.57 | 5 | 0.99 | 0.11 | 1.01 | 0.53 | 0.115 | 1.53 | — | 0.115 | 3.35 |
| D | 180/50 | 0.53 | 5 | 0.99 | 0.11 | 1.17 | 0.55 | 0.138 | 1.75 | — | 0.115 | 2.87 |
| D2 | 180/50 | 0.50 | 5 | 0.99 | 0.11 | 1.31 | 0.56 | 0.158 | NaN | 0.31 | 0.114 | 2.57 |
| D3 | 180/50 | 0.515 | 5 | 0.99 | 0.11 | 1.24 | 0.55 | 0.148 | 1.75 | — | 0.115 | 2.72 |
| E | 180/50 | 0.49 | 5 | 1.0 | 0.11 | 1.35 | 0.56 | 0.166 | NaN | 0.31 | 0.114 | 2.45 |
| F | 180/50 | 0.47 | 5 | 1.0 | 0.11 | 1.46 | 0.57 | 0.181 | NaN | — | 0.114 | 2.28 |
| **G** | 180/50 | 0.46 | 5 | 1.0 | 0.11 | 1.51 | 0.57 | **0.189** | NaN | 0.31 | 0.113 | 2.19 |

**Hallazgo:** K informal ESENCIAL para T5>0.10. T5=0.19 alcanzable con A_I=1.0, ω_C=0.46. Pero Tgasto=NaN (todos informal-dominantes).

### Fase 3: Variando sigma_C (elasticidad de sustitución)

| Run | σ_C | ω_C | p_I | T5 | T4 | Tgasto | T1 hh | Nota |
|-----|-----|-----|-----|----|----|--------|--------|------|
| K | 8 | 0.48 | 1.28 | 0.156 | 0.557 | NaN | 2.60 | Más sustitutos → p_I baja, T5 baja |
| K2 | 8 | 0.44 | 1.49 | 0.186 | 0.572 | NaN | 2.22 | |
| H | 3 | 0.44 | 1.99 | 0.222 | 0.536 | **1.58** | 1.55 | Menos sustitutos → p_I explota |
| J | 2 | 0.42 | 2.42 | 0.296 | 0.591 | NaN | 1.29 | σ_C=2 → p_I insostenible |

**Hallazgo:** σ_C↑ → p_I↓, T5↓. σ_C↓ → Tgasto se recupera pero p_I explota. σ_C=5 es el equilibrio.

### Fase 4: Ajustando psi_F/psi_I para recuperar Tgasto

| Run | psi_F/I | σ_C | ω_C | κ_z1 | p_I | T4 | T5 | Tgasto | T1 hh | Gini | Tkz |
|-----|---------|-----|-----|------|-----|----|----|--------|--------|------|-----|
| N | 140/55 | 5 | 0.45 | 0.15 | 1.60 | 0.55 | 0.187 | **1.80** | 2.01 | 0.30 | 0.120 |
| N2 | 140/55 | 5 | 0.44 | 0.15 | 1.66 | 0.55 | 0.195 | **1.80** | 1.94 | 0.30 | 0.120 |
| **N3** | **140/55** | **5** | **0.44** | **0.30** | **1.65** | **0.556** | **0.195** | **1.819** | **1.95** | **0.30** | **0.142** |
| O | 140/55 | 8 | 0.43 | 0.15 | 1.57 | 0.55 | 0.183 | **1.80** | 2.05 | 0.29 | 0.120 |
| P | 130/60 | 5 | 0.44 | 0.15 | 1.67 | 0.54 | 0.191 | 1.69 | 1.90 | 0.29 | 0.121 |

**Hallazgo:** Bajar ratio psi_F/psi_I de 3.6 a 2.55 recupera Tgasto (~1.80) manteniendo T4≈0.55 y T5≈0.19.

### Fase 5: Explorando amin y debt premium para Gini

| Run | amin | chi | r* | p_I | Gini | Masa deuda | T5 | T4 | Tgasto |
|-----|------|-----|-----|-----|------|-----------|-----|-----|--------|
| Q | -1.0 | 0.02 | 0.049 | 1.65 | 0.303 | 3.0% | 0.196 | 0.556 | 1.818 |
| Q2 | -3.0 | 0.005 | 0.049 | 1.65 | 0.323 | 6.1% | 0.197 | 0.557 | 1.817 |
| M | -1.0 | 0.02 | 0.048 | 1.51 | 0.321 | 3.5% | 0.190 | 0.573 | NaN |

**Hallazgo:** Gini estructuralmente ~0.30-0.32. Ni amin más negativo ni deuda más barata lo sube significativamente.

## 4. Límites estructurales documentados

### ¿Por qué Gini≈0.32?

**Doble auto-aseguramiento con alta persistencia:**

1. **Margen laboral:** Agente z bajo trabaja más informal (ell_I sube) → ingreso no cae tanto
2. **Margen ahorro:** Agente z alto ahorra para cuando eventualmente caiga (precaución)

Con ρ_z=0.86, ambos canales son fuertes → distribución de riqueza comprimida → Gini≈0.32.

Si ρ_z fuera más bajo, los agentes se endeudarían cuando están en z bajo (esperando volver pronto a z alto) → más desigualdad. Pero perderíamos el anclaje empírico de Hong (2022).

### ¿Por qué Tkz≈0.14?

La alta persistencia comprime el gap entre z_min y z_max en comportamiento. Los agentes en z bajo ya trabajan informal (sin necesidad de kappa_z), y los de z alto trabajan formal. El gap de formalidad existe pero es pequeño (~14pp) porque la productividad ya genera sorting natural.

kappa_z1 refuerza este sorting pero tiene efecto marginal decreciente: pasar de κ=0.01 a κ=0.30 solo sube Tkz de 0.10 a 0.14.

### ¿Por qué p_I>1?

Con Hong, el ahorro precautorio es alto → K* grande → r*≈0.05 → la firma formal demanda mucho capital → w_F/w_I≈3-5 → formal muy atractiva → Y_I pequeño. Para que el mercado de bien informal vacíe (C_I=Y_I), p_I debe ser >1 (bien informal más caro que el formal). p_I≈1.65 en el mejor run.

Esto es consecuencia del equilibrio general con α_F=0.636 >> α_I=0.118. La firma formal es mucho más productiva en capital → absorbe casi todo el ahorro → sector informal pequeño.

## 5. Mejor benchmark: N3

```
DRS Göbel: α_I=0.118, β_I=0.605
A_I=1.0, A_F=1.0
psi_F=140, psi_I=55 (ratio 2.55)
σ_C=5, ω_C=0.44
kappa_z1=0.30, kappa_z_shape=2.0
debt_prem_chi=0.02, debt_prem_eta=1.25
amin=-0.002
theta=1.0, nu_I=0.6
```

| Target | N3 | Dato | Estado |
|--------|-----|------|--------|
| T5 PBI inf. nominal | 0.195 | 0.190 | ✅ |
| T4 horas inf. | 0.556 | 0.557 | ✅ |
| Tgasto (F-dominante/I-dominante) | 1.819 | 1.913 | ✅ |
| T1 w_F/w_I_hh | 1.95 | ~2.30 | ~ |
| Tkz gap formal z | 0.142 | 0.386 | ❌ |
| Gini riqueza | 0.30 | 0.4-0.5 | ❌ |
| p_I < 1 | 1.65 | <1 | ❌ |

## 6. Lecciones aprendidas

1. **Capital informal (α_I>0) es ESENCIAL.** Sin él, T5<0.06.
2. **σ_C=5 es el sweet spot.** σ_C alto → p_I baja pero T5 baja. σ_C bajo → Tgasto se recupera pero p_I explota.
3. **psi_F/psi_I controla Tgasto.** Ratio ~2.5-2.6 permite algunos agentes formal-dominantes (Tgasto no NaN).
4. **ω_C mueve T5.** Cada -0.01 de ω_C → T5 sube ~2pp, p_I sube ~0.08.
5. **Gini≈0.32 es límite estructural** con ρ_z=0.86 + oferta laboral endógena. No es bug, es resultado económico.
6. **Tkz≈0.14 es límite estructural.** κ_z1 tiene efecto marginal decreciente.
7. **amin solo es relevante si la deuda es barata.** Con r*≈5% y spread≥0.5%, pocos agentes se endeudan.
8. **z en LOGS es correcto** para earnings. Moll usa niveles solo en ejemplo didáctico.
9. **OU con upwind es más robusto** que diferencias estándar (Rafales-Vázquez).
10. **spread(z) como proxy de spread por sector** es válido. No usar spread(a) (endógeno, asesor lo vetó).

## 7. Referencias clave

| Referencia | Archivo | Qué aporta |
|-----------|---------|-----------|
| Hong (2022) | `hong_emmpc.pdf` | ρ_z=0.860, sd_logz=0.542 (ENAHO Perú) |
| Galindo et al. (2024) | `galindo_wealth_informality.md` | θ_debt=0.02, τ=0.18 (BCRP) |
| Göbel et al. (2013) | `parametros_cobb_douglas...md` | α_I=0.118, β_I=0.605 (microempresas Perú) |
| Céspedes et al. (2014) | `ree-28-castillo-rojas.pdf` | α_F=0.636 (SUNAT), δ=0.10 |
| Moll (HACT) | `aiyagari_diffusion_equilibrium.m` | OU generator, HJB upwind |
| Yanagimoto (2025) | `match_hact2602.19798v1.md` | Validación HACT canónico |
| Rafales-Vázquez (2026) | `Rafales_Jonatan_2026...md` | Métodos numéricos 2 sectores |

## 8. Archivos generados esta sesión

| Archivo | Contenido |
|---------|-----------|
| `AUDITORIA_NUMERICA.md` | Auditoría completa del código vs 4 referencias |
| `RESULTADOS_CORRIDAS_ABC.md` | Resultados corridas A-B-C iniciales |
| `REVISION_ou_prima_calib_try3.md` | Revisión del run del compañero |
| `test_companero_vs_replication.m` | Script para reproducir pruebas |
| `outputs/stationary/test_*` | .mat de todas las corridas |
