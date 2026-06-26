# Plan: Utilidad No-Separable (Horvath) — HA-IE 2 Firmas

> Fecha: 2026-06-25 | Estado: PLANIFICACIÓN

---

## 1. Utilidad actual vs propuesta

### Actual (separable)
```
U = C(c_F, c_I)^(1-γ)/(1-γ) − ψ_F·v(ℓ_F) − ψ_I·v(ℓ_I)
    C = [ω_C·c_F^η + (1-ω_C)·c_I^η]^(1/η)
```
- c_F, c_I independientes de ℓ_F, ℓ_I
- ℓ_F/ℓ_I no depende de riqueza (dV cancela)
- ψ_F, ψ_I controlan nivel y composición de horas

### Propuesta (Horvath 2021, no-separable)
```
U = [C(c_F, c_I)^b × (1 − ℓ_F − ℓ_I)^(1−b)]^(1−γ) / (1−γ)
    C = [ω_C·c_F^η + (1-ω_C)·c_I^η]^(1/η)
```
- **b**: peso del consumo en la utilidad (0<b<1)
- **1−b**: peso del ocio
- Consumo y ocio son **sustitutos** vía Cobb-Douglas
- **Se eliminan ψ_F, ψ_I** (reemplazados por b y salarios relativos)
- ℓ_F/ℓ_I depende de riqueza vía V_a (el rico consume más ocio)

---

## 2. Derivación de FOCs

### Notación:
- C = agregado CES de consumo
- ℓ = ℓ_F + ℓ_I (trabajo total)
- o = 1 − ℓ (ocio)
- P_CES = precio del bien compuesto C

### FOC consumo-ocio (CD):
```
∂U/∂C = b × U/C × ...
∂U/∂o = (1−b) × U/o × ...

C / o = [b/(1−b)] × (w_eff / P_CES)
```
donde `w_eff` es un salario efectivo ponderado.

### FOC c_F / c_I (CES, igual que antes):
```
c_F / c_I = [ω_C/(1−ω_C) × p_I/(1+τ_c)]^σ_C
```

### FOC ℓ_F / ℓ_I:
```
ℓ_F / ℓ_I depende de w_F_eff / w_I_eff
```
Ya NO depende de ψ_F/ψ_I — depende de salarios relativos y del parámetro b.

---

## 3. Algoritmo por punto (a,z)

Dado V_a (derivada del valor):

```
1. Suponer ℓ_total (inicializar con valor anterior)
2. Calcular ingreso = (1−τ)·w_F·z·ℓ_F + w_I·θ·z^ν·ℓ_I + r·a + T + Π
3. Del CD consumo-ocio:
   C = [b/(1−b)] × (ingreso/P_CES) × (1−ℓ) / ℓ  ← aprox, derivar exacto
4. Del CES: c_F, c_I a partir de C y p_I
5. Verificar: c_F + p_I·c_I ≤ ingreso (factibilidad)
6. De FOC ℓ_F, ℓ_I: resolver sistema 2×2 con KKT si ℓ_F+ℓ_I > H_bar
7. Iterar hasta convergencia de ℓ
```

**Simplificación clave:** con CD entre C y ocio, el problema tiene solución semi-analítica. No requiere Newton 4×4.

---

## 4. Cambios en el código

### Archivo: `model_main.m`

**A) Nueva función:** `horvath_consumption_leisure_from_dV_v10(dV, z, w_F, w_I, params)`
- Reemplaza `ces_consumption_from_dV_v10` + `lab_solve_v10_dV`
- Resuelve (c_F, c_I, ℓ_F, ℓ_I) simultáneamente
- Usa CD + CES → semi-analítico
- Maneja KKT para H_bar

**B) Modificar HJB:**
- Línea ~1900: reemplazar llamada a políticas
- El drift se calcula igual: adot = income − c_F − p_I·c_I

**C) Boundary zero-drift (nuevo):**
- Similar a Moll `lab_solve.m` pero con 2 sectores
- Precomputar en amin y amax usando fzero sobre ℓ condicional

**D) Parámetros nuevos:**
- `b`: share del consumo en CD (reemplaza ψ_F, ψ_I)
- Se eliminan `psi_F`, `psi_I` del código

---

## 5. Referencias

| Fuente | Qué aporta |
|--------|-----------|
| **Horvath (2021)** | Utilidad CD(CES, ocio) para 2 sectores F/I. FOCs acopladas. |
| **Moll labor_supply.md** | Algoritmo para trabajo endógeno separable. Zero-drift con fzero. |
| **Moll HACT Appendix** | Upwind, state constraint, implicit scheme. Base del solver. |
| **Sabet & Schneider (Nested Drift)** | Posiblemente: método para drift con utilidad anidada. |

---

## 6. Estimación de esfuerzo

| Tarea | Dificultad | Tiempo estimado |
|-------|-----------|----------------|
| Derivar FOCs completas | Media | 2-3 horas |
| Implementar `horvath_consumption_leisure_from_dV` | Alta | 4-6 horas |
| Adaptar HJB loop | Media | 1-2 horas |
| Boundary zero-drift | Media | 1-2 horas |
| Debug y test | Alta | 3-4 horas |
| Recalibrar (b, ω_C, A_I, κ_z, ρ) | Alta | 4-6 horas |
| **Total** | | **15-23 horas** |

---

## 7. ¿Vale la pena?

### A favor:
- Elimina ψ_F, ψ_I (parámetros "feos")
- Solo 1 parámetro nuevo (b) en vez de 2
- Ocio endógeno vinculado a riqueza → T6 mejora naturalmente
- Más formal-dominantes (rico elige formal + más ocio)
- Horvath ya lo validó para sector informal

### En contra:
- ~15-23 horas de desarrollo
- HJB ~5× más lento
- Recalibrar desde cero
- Sin ψ_F, ψ_I se pierde control directo sobre T4 y nivel de horas

### Decisión: **Implementar después de cerrar calibración actual con separable.**
