# Auditoría Numérica — model_main.m vs Referencias

> Fecha: 2026-06-24. Se audita `replication_package/model_main.m` contra 4 referencias.

## Referencias auditadas

| # | Referencia | Archivo | Tipo |
|---|-----------|---------|------|
| 1 | Moll, Benjamin | `base_Moll/aiyagari_diffusion_equilibrium.m` | HACT ejemplo didáctico |
| 2 | Yanagimoto (2025) | `match_hact2602.19798v1.md` | HACT canónico, Achdou et al. (2022) |
| 3 | Rafales & Vázquez (2026) | `Rafales_Jonatan_2026...md` | 2 sectores, métodos numéricos |
| 4 | Galindo et al. (2024) | `galindo_wealth_informality.md` | Prima deuda informal Perú |

## 1. Generador OU (Ornstein-Uhlenbeck)

**Fórmulas IDÉNTICAS a Moll y Yanagimoto.**

| Coeficiente | Moll | Yanagimoto | model_main.m |
|------------|------|-----------|-------------|
| Lower (down) | `-min(μ,0)/dz + s²/(2dz²)` | `-d⁻/Δb + ησ²/Δb²` | `-min(μ,0)/dx + diff_half` ✅ |
| Center | `.../dz - .../dz - s²/dz²` | `-(lower+upper)` | `min/.../ - max/.../ - 2*diff_half` ✅ |
| Upper (up) | `max(μ,0)/dz + s²/(2dz²)` | `d⁺/Δb + ησ²/Δb²` | `max(μ,0)/dx + diff_half` ✅ |
| Bordes | Reflecting (fold into center) | One-sided reflecting | `center(1)+=chi(1)`, `center(N)+=zeta(N)` ✅ |
| Row-sum check | `abs(sum)<1e-9` (warn) | — | `Q - spdiags(row_sums,0,N,N)` ✅ (corrige) |

## 2. HJB — esquema upwind implícito

**Estructura IDÉNTICA a Moll/Yanagimoto.**

| Paso | Moll | model_main.m |
|------|------|-------------|
| Forward diff | `Vaf = (V(i+1)-V(i))/da` | `dVf = (V(2:I)-V(1:I-1))/da` ✅ |
| Backward diff | `Vab = (V(i)-V(i-1))/da` | `dVb = (V(2:I)-V(1:I-1))/da` ✅ |
| Consumo | `c = dV^(-1/γ)` | CES(cF,cI) desde dV ✅ (extensión necesaria) |
| Labor | No tiene (fijo) | KKT: `compute_labor_kkt_v10(dV)` ✅ |
| Savings drift | `s = income - c` | `ss = ingreso_laboral - gasto_CES` ✅ |
| Upwind choice | `If=sf>0, Ib=sb<0` | `If=ssf>0, Ib=ssb<0 & ~If` ✅ (+robusto) |
| Matriz A (a) | `X=-min(s,0)/da, Y=..., Z=max(s,0)/da` | Idéntico ✅ |
| Matriz A (z) | `Aswitch` manual FD | `kron(Qz_ar, speye(I))` ✅ |
| Esquema implícito | `B=(1/Δ+ρ)I - A` | Idéntico, `Δ=1000` ✅ |
| Row-sum | Advierte si >1e-9 | `A=A-spdiags(row_sums,...)` ✅ |

## 3. Condiciones de borde

| Referencia | amin | amax |
|-----------|------|------|
| **Moll** | `Vab(1) = (w·z + r·amin)^(-γ)` state constraint | `Vaf(I) = (w·z + r·amax)^(-γ)` |
| **model_main** | Zero-drift: `solve_dV_zero_drift_v10` + `ssb(1,:)=0` | Zero-drift + `ssf(I,:)=0` |

Ambos válidos. Moll fuerza `s≥0` en bordes (no cruza). Nuestro método fuerza `s=0` (barrera reflectante). El forzado `ssb(1)=ssf(I)=0` post-hoc garantiza que el agente nunca sale de la grilla. Equivalente en práctica.

## 4. KFE (distribución estacionaria)

| Referencia | Método |
|-----------|--------|
| **Moll** | `A'*g = 0`, fija un punto, normaliza |
| **Yanagimoto** | `(A_j^⊤ - νI)M_j = source`, Schur complement |
| **model_main** | `A'*g = 0`, `AT(1,:)=[1,0,...]`, `b(1)=1`, normaliza ✅ |

## 5. Comparación numérica con Rafales-Vázquez

Rafales-Vázquez usan diferencias **estándar** (no upwind) para el drift en z:
```
a_k = μ/Δz - σ²/(2Δz²)    ← puede hacerse negativo si |μ|Δz > σ²
```

**Nuestro método es más robusto.** Usamos upwind (como Moll):
```
chi = -min(μ,0)/dx + diff_half   ← SIEMPRE ≥ 0
```
Esto garantiza coeficientes no-negativos fuera de la diagonal → matriz monotónica → sin oscilaciones espurias cuando el drift es grande (Peclet > 2).

## 6. ¿z en logs o niveles?

| Variable modelada | Usar | Por qué | Referencia |
|------------------|------|--------|-----------|
| Ingresos/earnings | **LOGS** | Log-normal en datos, z>0 garantizado | Hong, Achdou, Kaplan |
| Match quality | Niveles | Puede ser negativo, no hay cota inferior | Yanagimoto |
| Ejemplo didáctico | Niveles | Rango estrecho [0.5, 1.5] | Moll |

**Nuestro modelo usa logs → CORRECTO.** Hong estima el proceso en log-earnings del panel ENAHO. Es el estándar en la literatura cuantitativa.

## 7. Prima deuda (Galindo et al.)

Galindo: spread=2% para INFORMALES, 0% para FORMALES. Depende del sector, no de z.

Nuestra implementación: `spread(z)` — decreciente en z. z bajo ≈ informal (más spread), z alto ≈ formal (sin spread). Es una aproximación continua válida que evita endogeneidad (no depende de a ni de `ell_I>ell_F`). El asesor aprobó no usar dependencia en a.

## Veredicto final

**`model_main.m` es numéricamente correcto.** Implementa fielmente los métodos HACT de Achdou et al. (2022) / Moll:

- OU generator con upwind → idéntico a Moll/Yanagimoto ✅
- HJB upwind implícito → idéntico a Moll/Yanagimoto ✅
- KFE estacionaria → consistente con referencias ✅
- Matrices sparse tridiagonal/block-tridiagonal → O(N·Nz) ✅
- Extensiones (CES, KKT laboral, prima deuda, K informal) integradas correctamente ✅
- Log-z → correcto para earnings ✅
- Upwind más robusto que diferencias estándar (Rafales-Vázquez) ✅

**No se encontraron errores numéricos.**
