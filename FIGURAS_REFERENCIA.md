# Figuras Moll — Calibración FINAL v11 (A_I=1.38, Nz=7)

> **Fuente:** `outputs/stationary/grid_FINAL_AI138/results_grid_FINAL_AI138.mat`
> **Parámetros:** γ=1.0, ρ=0.073, σ_C=5, ω_C=0.56, A_I=1.38, ψ_F/ψ_I=110/49, κ_z1=0.65 shape=1.0, Nz=7, width=2.5
> **Targets:** p_I=0.939, T4=0.559, T5=0.180, Tkz=0.382, Tgasto=1.963, Gini=0.414

---

## 1. Ahorro y distribución de riqueza

### `moll_savings_policy.png` (RECOMENDADA)
Politica de ahorro s(a) para z bajo y z alto, en un solo panel estilo Moll.
- z alto ahorra mas (mayor ingreso -> mayor acumulacion).
- z bajo ahorra cerca de cero o desahorra en zona de deuda.

### `moll_wealth_distribution_by_z.png` (RECOMENDADA)
Densidad estacionaria g(a|z) separada de la politica de ahorro.

### `moll_wealth_density_by_z_low_median_high.png`
Densidad de riqueza normalizada para 3 grupos: z bajo, z medio, z alto.
- **Bump visible:** Nz=7 produce modos discretos. Cada nivel z tiene su nivel de riqueza objetivo. Al agrupar en 3, los modos no se superponen perfectamente → multimodalidad. Es normal en Aiyagari.
- Para suavizar: Nz=15, width=3.0.

---

## 2. Consumo

### `moll_consumption_policy.png`
C_efectivo(a) = agregado CES. Panel izq: z bajo y alto. Panel der: todos los z.

### `moll_consumption_distribution.png`
PDF + CDF de consumo efectivo y gasto monetario (c_F + p_I·c_I).

### `moll_consumption_components_distribution.png`
Distribución agregada de c_F (azul) y p_I·c_I (rojo). El consumo formal domina la canasta.

### `moll_consumption_components_by_z.png`
c_F(a) y p_I·c_I(a) para z bajo y z alto. Panel izq: z bajo consume más informal. Panel der: z alto consume más formal.

### `moll_consumption_components_distribution_by_z_groups.png`
Distribución normalizada de c_F y p_I·c_I condicional en 3 grupos z, con medias marcadas por líneas verticales.
- Si p_I·c_I muestra un pico alto en z alto, eso indica baja dispersión de la PDF, no mayor gasto informal.

### `moll_consumption_labor_policy_by_wealth.png`
Consumo total + horas totales contra riqueza para z bajo/medio/alto.

---

## 3. Oferta laboral y uso del tiempo

### `moll_labor_policy.png` (ELIMINADA)
Figura duplicada respecto de `moll_labor_policy_by_wealth.png`; no se genera en el set final.

### `moll_labor_policy_by_wealth.png`
ℓ_F(a) y ℓ_I(a) para z bajo, medio, alto.
- z bajo: casi todo informal (ℓ_F≈0, ℓ_I>0).
- z alto: mixto, más formal.

La informalidad cae con riqueza para z medio y alto.

### `moll_labor_supply_by_productivity.png`
Panel izq: horas totales contra riqueza para cada z. Panel der: E[ℓ|z] promedio.

### `moll_time_use_by_z_with_leisure.png`
% Ocio, % Formal, % Informal apilados por nodo z (7 nodos).
- Ocio ≈ 58% en todos los z.
- Formal crece con z, Informal cae con z.
- Nz=7: solo 7 barras. Con Nz=15 se vería más suave.

### `moll_time_use_by_z_excluding_leisure.png`
% Formal, % Informal (sin ocio) por nodo z.
- Muestra el sorting puro: a mayor z, mayor % formal dentro del tiempo trabajado.
- ⚠️ **Nótese:** solo 7 nodos z. Para más resolución visual regenerar con Nz=15.

---

### ¿Por qué hay tanto ocio? (~58%)

```
E[ℓ_F + ℓ_I] = 0.419 → Ocio = 1 - 0.419 = 0.581 (58%)
```

**No es un error.** Causas:
1. **H_bar=1 casi nunca bindea.** Los agentes eligen ℓ_F+ℓ_I < 1 libremente.
2. **ψ_F=110, ψ_I=49** calibrados a T4 (share informal), no a horas totales. La desutilidad laboral es alta → horas moderadas.
3. **Frisch=0.38** → baja elasticidad de oferta laboral.

**¿Es razonable?** En Perú, horas trabajadas ~40-45 semanales / ~112 horas despierto = **36-40%**. El modelo da 42% → **levemente alto pero plausible**. El "ocio" incluye producción doméstica, cuidado infantil, etc. — no es ocio puro.

---

## 4. Ingreso por quintil de riqueza

### `moll_income_decomposition_by_wealth_quintile.png` (NIVELES)
Ingreso en niveles absolutos por quintil de riqueza.

| Quintil | Ing. Formal | Ing. Informal | Ing. Capital | Transferencias | Deuda | Neto |
|---------|------------|---------------|-------------|----------------|-------|------|
| **Q1** (pobres) | 0.35 | 0.38 | 0.06 | 0.14 | ~0 | 0.93 |
| **Q2** | 0.50 | 0.41 | 0.27 | 0.14 | 0 | 1.32 |
| **Q3** | 0.55 | 0.41 | 0.52 | 0.14 | 0 | 1.62 |
| **Q4** | 0.58 | 0.40 | 0.82 | 0.14 | 0 | 1.94 |
| **Q5** (ricos) | 0.76 | 0.44 | 1.19 | 0.14 | ~0 | 2.53 |

**Patrón:** Ingreso capital EXPLOTA en Q5 (1.19 vs 0.06 en Q1 = 20×). Ingreso laboral solo 2×. Transferencias igual para todos (lump-sum fiscal).

### `moll_income_decomposition_percent_by_wealth_quintile.png` (NIVELES + PORCENTAJES)
Ingreso medio por quintil en niveles; los porcentajes aparecen dentro de cada barra para indicar composición.

| Quintil | % Formal | % Informal | % Capital | % Transferencias |
|---------|----------|-----------|-----------|-----------------|
| **Q1** | **38%** | **41%** | 6% | **15%** |
| **Q2** | 38% | 31% | 20% | 11% |
| **Q3** | 34% | 25% | 32% | 9% |
| **Q4** | 30% | 21% | 42% | 7% |
| **Q5** | 30% | 17% | **47%** | 5% |

**Lectura:** Q1 depende de trabajo informal (41%) + transferencias (15%). Q5 depende de capital (47%). El gradiente es claro: **los pobres trabajan, los ricos poseen capital.** Las transferencias son regresivas en % (15% en Q1, 5% en Q5) pero iguales en nivel.

⚠️ **Ya son 2 archivos separados.** `_by_wealth_quintile` = niveles, `_percent_by_wealth_quintile` = %.

---

## 5. Informalidad

### `moll_informality_by_z.png` (RECOMENDADA)
Share informal y share formal de horas por nodo z. Esta es la figura limpia para discutir sorting sectorial.

### `moll_debt_probability_by_z.png` (RECOMENDADA)
Probabilidad de deuda Pr(a<0|z) por productividad. Esta figura queda separada de informalidad.

### `moll_informality_intensive_by_z.png` (ELIMINADA)
Figura acoplada eliminada. Usar `moll_informality_by_z.png` y `moll_debt_probability_by_z.png`.

### `moll_model_gasto_distribution_by_formality.png`
Distribución del gasto para hogares F-dominantes (ℓ_F>ℓ_I) vs I-dominantes (ℓ_I≥ℓ_F).
- F-dominantes: E[gasto]=3.18, SD=0.90 → minoría rica (3% de agentes).
- I-dominantes: E[gasto]=1.62, SD=0.56 → mayoría (97%).

---

## 6. Desigualdad

### `moll_lorenz_curves.png`
Curvas de Lorenz: riqueza neta (Gini=0.414) y gasto (Gini=0.207).
- Gini riqueza > Gini gasto: estándar en modelos de ciclo vital con ahorro precautorio.
- Gini gasto=0.21 vs ENAHO ~0.35-0.45: subestimado (sin shocks idiosincráticos de ingreso/gasto).

### `moll_conditional_moments_by_z.png`
E[a|z] (activos) y E[gasto|z] por nodo de productividad.
- Crecientes en z: mayor productividad → mayor riqueza y gasto.

---

## 7. Equilibrio general

### `moll_equilibrium_asset_market.png`
S(r) = ahorro agregado, KD(r) = demanda de capital. Intersección: r*=0.068, K*=8.32.
- Brecha ρ-r = 0.073-0.068 = 0.005 (ahorro precautorio modesto).

---

## 8. Proceso OU y mecanismos

### `moll_ou_stationary_masses.png`
Masa invariante del proceso OU vs masa estacionaria del modelo por z.
- Verifica que la discretización del proceso z es precisa.

### `moll_debt_premium_inequality_by_z.png`
Prima de deuda (spread) por z + desigualdad de consumo dentro de cada z.
- z bajo enfrenta mayor spread (0.02) → restricción crediticia más fuerte.

---

## Resumen de issues

| Issue | Figura afectada | Acción |
|-------|----------------|--------|
| Ahorro + riqueza juntos | `moll_savings_and_wealth_distribution.png` | Corregido: eliminado; usar `moll_savings_policy.png` + `moll_wealth_distribution_by_z.png` |
| Informalidad + deuda juntos | `moll_informality_intensive_by_z.png` | Corregido: eliminado; usar `moll_informality_by_z.png` + `moll_debt_probability_by_z.png` |
| Trabajo duplicado | `moll_labor_policy.png` | Corregido: eliminado; usar `moll_labor_policy_by_wealth.png` |
| Bump en densidad riqueza | `moll_wealth_density_by_z_*.png` | Normal (Nz=7), regenerar con Nz=15 si se quiere |
| Time use pocos nodos | `moll_time_use_by_z_*.png` | Nz=7 funcional, Nz=15 visual |
| Ocio 58% | `moll_time_use_by_z_with_leisure.png` | Razonable (~42% tiempo trabajado). ψ_F, ψ_I no calibrados a horas totales |
| Ingreso niveles + % | Ya son 2 archivos separados ✅ | — |

---

## Parámetros de la corrida

| Parámetro | Valor | Fuente |
|-----------|-------|--------|
| γ | 1.0 | Log utilidad |
| ρ | 0.073 | → K/Y, Gini |
| σ_C | 5 | Sweet spot elasticidad |
| ω_C | 0.56 | → p_I≈0.94 |
| A_I | 1.38 | → T5≈0.18 |
| ψ_F / ψ_I | 110 / 49 | → T4≈0.56 |
| κ_z1 / shape | 0.65 / 1.0 | → Tkz≈0.38 |
| al / d | 0.636 / 0.10 | Cespedes, Castillo & Rojas |
| α_I / β_I | 0.118 / 0.605 | Göbel et al. |
| Nz | 7 | Suficiente para targets |
| Frisch | 0.38 | Literatura |
