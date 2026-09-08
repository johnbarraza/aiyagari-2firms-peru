# Informalidad y Distribución de Riqueza — verificación en Lean 4

Este directorio contiene la **formalización parcial en Lean 4** del anexo
matemático de:

> John Svante Barraza Ratachi y Enzo Andrés Nevado Martínez,
> *Informalidad y Distribución de Riqueza: Un Modelo de Agentes Heterogéneos con
> Oferta Laboral Endógena*, Anexo Matemático v10 ARz DebtPrem, Junio 2026.
> Paquete de replicación: <https://github.com/johnbarraza/aiyagari-2firms-peru>

Se produjo con el flujo de formalización de papers de
[EconCSLib](https://gargnikhil.com/EconCSLib/), siguiendo el ejemplo de
referencia [QX26AgenticDelegation](https://github.com/alexanderquispe/QX26AgenticDelegation).

## Resultado de un vistazo

| Ítem | Resultado |
| --- | --- |
| Afirmaciones derivables inventariadas en el anexo | 8 |
| Proposiciones representadas en Lean | 8/8 |
| Teoremas adicionales sobre la extensión | 8 |
| Pruebas Lean completas (sin `sorry`) | 16/16 |
| Supuestos añadidos fuera del documento | 0 |
| Correcciones necesarias detectadas en la fuente | 5 |
| Revisiones humanas registradas | 0/8 pendientes |
| Estado general | **Formalización parcial** |

Las ocho afirmaciones seleccionadas están completamente probadas. El estado es
*formalización parcial* porque la existencia del equilibrio estacionario
—solución de la HJB, distribución invariante, y punto fijo de precios— **no**
está formalizada, y porque las líneas de auditoría semántica asistidas por
modelo del protocolo v11 no se ejecutaron.

## Qué queda verificado

1. **Generador OU discretizado** (`eq:Qz_construction`): las filas suman cero,
   tanto en nodos interiores como en los bordes reflectores. Es la condición que
   hace válido al generador y que preserva masa en la ecuación adjunta.
2. **Prima de deuda** (`eq:debtprem`): estrictamente decreciente en la
   productividad.
3. **Reparto CES óptimo** (`eq:ces_foc`): el ratio de demanda `ξ` satisface la
   tangencia con el precio relativo, y el agregado factoriza como deflactor por
   consumo informal.
4. **Oferta laboral interior** (`eq:foc_F`, `eq:foc_I`): la CPO isoelástica, la
   optimalidad **global** sobre todas las horas no negativas, y la unicidad del
   punto estacionario interior.
5. **Caso vinculante KKT** (`eq:kkt_binding`): monotonía estricta del residuo en
   todo el intervalo factible, valores exactos en ambos extremos, y las dos
   condiciones de esquina.
6. **Firma formal** (`eq:formal_foc`): razón capital-trabajo cerrada y
   agotamiento del producto entre pagos a capital y trabajo.
7. **Firma informal** (`eq:wI`, `eq:PiI`): beneficio residual
   `(1-α_I-β_I) p_I Y_I`, agotamiento de Euler bajo retornos constantes, y
   demanda estática de capital.
8. **Vaciamiento del bien formal**: la identidad de Walras, derivada de las demás
   condiciones del anexo.

## Correcciones que el anexo necesita

La verificación encontró cinco puntos a corregir. **Ninguno cambia los resultados
cuantitativos del trabajo**: en todos los casos la versión implementada en el
solver es la correcta y lo que hay que arreglar es el texto del anexo.

| # | Dónde | Qué dice el anexo | Qué corresponde |
| --- | --- | --- | --- |
| 1 | `eq:ces` §3.5 | pesos `ω^{1/σ}`, `(1-ω)^{1/σ}` | pesos `ω`, `(1-ω)` sin exponenciar |
| 2 | §4.2, demanda de `K_I` | `(α_I A_I/(r+δ))^{1/(1-α_I)} L_I^{β_I/(1-α_I)}` | `(p_I α_I A_I/(r+δ))^{1/(1-α_I)} L_I^{β_I/(1-α_I)}` |
| 3 | `eq:debtprem` §3.2 | `χ_0 (z_1/z)^{η}` | `χ_0 ((z_max-z)/(z_max-z_min))^{η}` |
| 4 | §3.4, barrera `κ_z` | positiva solo en el nodo más bajo | interpolación suave decreciente en `z` |
| 5 | §5.2 item (iii) | `C_F + δK_F + DebtPrem = Y_F` | `Y_F = C_F + δK + Kappa + DebtPrem`, con `K = K_F + K_I` |

El punto 1 es una inconsistencia **interna**: con los pesos impresos, la propia
`eq:ces_foc` del anexo no se sigue. Los puntos 3 y 4 son especificaciones
desactualizadas: el documento principal ya trae la forma correcta.

El punto 5 es el más importante y está desarrollado en la Sección 11 del reporte
de validación. La identidad impresa omite los pagos de la barrera de acceso
formal y usa `K_F` en lugar del capital total; vale exactamente cuando
`Kappa + δ K_I = 0`, y en la calibración de cierre ninguno de los dos términos es
nulo. Conviene notar que el chequeo residual del solver tampoco usa la identidad
correcta: comprueba `Y_F - C_F - δK - Kappa`, es decir incluye los pagos de
barrera pero omite los de prima de deuda. Cada criterio omite un término
distinto.

Fuera del anexo, el **documento principal** tiene dos erratas en §3.2.3: escribe
`Π_I = (1-β_I) p_I Y_I/(α_I+β_I)` en lugar de `(1-α_I-β_I) p_I Y_I`, y coloca el
precio dentro de la función de producción (`Y_I = p_I A_I K^{α} L^{β}`).

## Qué distingue esta extensión del Aiyagari clásico

Los ocho teoremas de arriba verifican la consistencia interna de las ecuaciones del
anexo. `ExtensionResults.lean` verifica algo distinto: lo que hace de este modelo
una **extensión**. Estos resultados no son enunciados literales del anexo, así que
no son filas de revisión fuente-a-Lean; son consecuencias probadas.

1. **Anidamiento del modelo clásico.** Apagar el sector informal colapsa el modelo
   al Aiyagari estándar con oferta laboral endógena, **sin tomar límites**: horas
   informales cero, producto y beneficio informal cero, el CES colapsa al bien
   único cuando `ω_C = 1`, y queda exactamente la CPO laboral de una firma. Es la
   prueba formal de que tu modelo *contiene* al clásico.
2. **Sorting monótono por productividad.** Con `κ(z)` decreciente y `ν_I < 1`, el
   atractivo relativo del sector formal `w_F^net(z)/w_I^eff(z)` es estrictamente
   creciente en `z`; en el caso interior la razón de horas lo hereda, y en el
   vinculante la monotonía estricta del residuo KKT lo traslada a las horas
   formales. Es el mecanismo del target `Tkz`, convertido en teorema.
   *Condicional a `V_a`*: aísla el canal de productividad con la valoración
   marginal de la riqueza fija — y por eso mismo el gradiente por **quintil de
   riqueza** (`T6`) no se sigue de aquí, que es justo donde el modelo subestima.
3. **Margen intensivo, sin salto de participación.** Como `κ` multiplica las horas
   (`−κ_F·ℓ_F`) y no es un costo fijo, la política laboral es **continua** en `z`:
   no hay umbral donde las horas salten de cero a positivo, que es lo que produce
   un modelo con margen extensivo. Y se prueba el umbral exacto de exclusión:
   `ℓ_F > 0 ⟺ κ(z) < (1−τ)w_F z`.
4. **El AR(1) de ENAHO sobrevive el paso a tiempo continuo.** La difusión
   `√(2η)σ` devuelve **exactamente** `σ²_logz` de varianza estacionaria; el mapeo
   `η = −log(ρ_z)/dt` reproduce **exactamente** `ρ_z`; y `E[z] = exp(σ²/2) > 1`
   siempre que `σ ≠ 0`, o sea la normalización ex-post no es opcional.
   *Convención declarada:* se usa como hecho clásico la varianza estacionaria
   `s²/(2η)` y la autocorrelación `exp(−η·dt)` del OU; no se formaliza la teoría
   de ecuaciones diferenciales estocásticas.
5. **Homoteticidad CES.** El agregador es homogéneo de grado uno, y la composición
   de la canasta `c_F/(p_I c_I) = (ω/(1−ω))^σ p_I^{σ−1}` es **idéntica para todos
   los agentes**. Es el diagnóstico `TgFI_canasta` que imprime el solver, hasta
   ahora afirmado solo en un comentario del código.

## Qué NO queda verificado

- Existencia y unicidad de la solución de la ecuación de Hamilton-Jacobi-Bellman.
- Existencia de la distribución estacionaria de la ecuación de Kolmogorov Forward.
- Existencia del punto fijo de precios que vacía simultáneamente los mercados.
- Condiciones de borde de drift nulo y construcción de la matriz de transición
  completa.
- Soluciones de esquina del reparto CES.
- Convergencia del algoritmo de bisección del caso vinculante.
- Concavidad conjunta del problema instantáneo en `(c_F, c_I, ℓ_F, ℓ_I)`, que es
  lo que garantizaría que las CPO son suficientes y no solo necesarias.
- Conservación de masa de la KFE discretizada.
- Toda la calibración y los resultados cuantitativos.

## Estructura

| Archivo | Rol |
| --- | --- |
| `PaperInterface.lean` | Superficie de revisión humana: una proposición transparente `...Spec : Prop` por afirmación de la fuente |
| `ProofInterface.lean` | Puntos de prueba, con el tipo exacto de cada `Spec` |
| `MainTheorems.lean` | Implementación de las pruebas y lemas auxiliares genéricos |
| `Assumptions.lean` | Supuestos de la fuente no derivados en Lean (vacío: no hay ninguno) |
| `ExtensionResults.lean` | Teoremas sobre la extensión, fuera de la superficie de revisión de la fuente |
| `FINAL_VALIDATION_REPORT.md` | Reporte de validación, veredicto humano y correcciones |
| `SOURCE.md` | Fijación de la fuente auditada por SHA-256 |
| `status.json` | Estado legible por máquina |
| `audit/` | Expedientes de auditoría, incluido el ledger de defectos de la fuente |
| `docs/DependencyDAG.tex` | Grafo de dependencias de las pruebas |
| `docs/FORMALIZATION_PLAN.md` | Bitácora del razonamiento fuera de Lean |

## Verificación

```bash
lake exe cache get   # opcional, acelera la primera compilación de Mathlib
lake build
bash scripts/check.sh
```

Requiere el toolchain fijado en `lean-toolchain` (`leanprover/lean4:v4.30.0-rc2`)
y Mathlib en la misma revisión.

Este proyecto vive dentro del paquete de replicación
[`aiyagari-2firms-peru`](https://github.com/johnbarraza/aiyagari-2firms-peru).
Dentro de una copia de EconCSLib, la verificación con alcance de paper es:

```bash
python3 scripts/paper_contribution.py check BN26InformalityWealthPeru --fast
```
