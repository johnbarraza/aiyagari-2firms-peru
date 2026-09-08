# Final Validation Report: Informalidad y Distribucion de Riqueza: Un Modelo de Agentes Heterogeneos con Oferta Laboral Endogena (Anexo Matematico)
Updated: 2026-09-07

## 1. Human Verdict
Formalizacion parcial. Se verificaron mecanicamente las condiciones de primer
orden que definen el comportamiento optimo del hogar y de las dos firmas, la
propiedad de generador del proceso de productividad discretizado, y la identidad
contable que cierra el mercado del bien formal. El equilibrio estacionario como
objeto matematico (existencia y unicidad de la solucion del problema de control
optimo, de la distribucion invariante, y del punto fijo de precios) no esta
formalizado y permanece fuera del alcance verificado. Ninguna fila revisada
depende de un supuesto ajeno al documento fuente. La revision detecto cinco
correcciones que el documento fuente necesita, una de ellas en una identidad
contable central.

## 2. Closeout Status
- Completion status: partially formalized
- One-sentence recap: Las condiciones de optimalidad estatica y la contabilidad
  agregada del modelo estan verificadas; la existencia del equilibrio no lo esta.

## 3. Source and Scope
- Paper: Informalidad y Distribucion de Riqueza: Un Modelo de Agentes
  Heterogeneos con Oferta Laboral Endogena — Anexo Matematico
- Source version: Anexo Matematico v10 ARz DebtPrem, Junio 2026
  (paquete de replicacion `aiyagari-2firms-peru`)
- Lean folder: `papers/BN26InformalityWealthPeru`
- Human-facing theorem file: `papers/BN26InformalityWealthPeru/PaperInterface.lean`
- Paper assumption file: `papers/BN26InformalityWealthPeru/Assumptions.lean`
- DAG artifacts: `papers/BN26InformalityWealthPeru/docs/DependencyDAG.tex`
- Lean footprint: 8 propositions revisables con sus 8 puntos de prueba, 3 lemas
  auxiliares genericos de analisis real, y 8 teoremas adicionales de extension
  en `ExtensionResults.lean` que no son filas de revision de la fuente.

El anexo no contiene proposiciones ni teoremas numerados: su contenido teorico
esta organizado como ecuaciones numeradas y derivaciones. El alcance revisado es
el conjunto de ecuaciones que enuncian una afirmacion matematica derivable, no
una mera definicion de notacion.

## 4. Researcher Summary of Checked Results
Queda verificado que:

1. El generador infinitesimal del proceso de productividad discretizado tiene
   filas que suman cero, tanto en los nodos interiores como en los dos bordes
   con barreras reflectoras. Esta es la condicion que hace que la matriz sea un
   generador valido y que la ecuacion adjunta preserve masa.
2. La prima de deuda enunciada es estrictamente decreciente en la productividad,
   de modo que el agente menos productivo paga la prima mas alta.
3. En el reparto optimo del gasto entre bien formal e informal, el ratio de
   demanda enunciado satisface exactamente la condicion de tangencia con el
   precio relativo, y el agregado de consumo se factoriza como el deflactor CES
   multiplicado por el consumo informal.
4. La oferta laboral no restringida de cada sector iguala el beneficio marginal
   del trabajo con el costo marginal de la desutilidad isoelastica, maximiza
   globalmente el excedente instantaneo del hogar sobre todas las horas no
   negativas, y es el unico punto estacionario interior.
5. Cuando la restriccion de tiempo total es vinculante, el residuo que define el
   reparto de horas es estrictamente creciente en las horas formales sobre todo
   el intervalo factible, toma exactamente los valores enunciados en ambos
   extremos, y las dos condiciones de esquina se activan en los umbrales
   indicados. La monotonia estricta implica que la solucion interior es unica.
6. La firma formal con retornos constantes tiene la razon capital-trabajo cerrada
   enunciada, y su producto se agota exactamente entre pagos a capital y trabajo.
7. La firma informal tiene beneficio residual igual a la fraccion de retornos no
   agotada por los factores, que es cero bajo retornos constantes, y su demanda
   estatica de capital es la enunciada una vez corregido el factor de precio.
8. Las condiciones de equilibrio del anexo, junto con la agregacion de la
   restriccion presupuestaria del hogar en estado estacionario, implican una
   identidad de vaciamiento del bien formal que incluye dos terminos ausentes en
   la version impresa.

## 5. Remaining Boundaries and Gaps
- La existencia y unicidad de la solucion de la ecuacion de
  Hamilton-Jacobi-Bellman, y la existencia de la distribucion estacionaria que
  resuelve la ecuacion de Kolmogorov Forward, no estan formalizadas. Ambas se
  toman como dadas.
- El equilibrio general no esta formalizado como objeto: no se verifica que
  exista un vector de precios que vacie simultaneamente el mercado de activos y
  el del bien informal, ni que el punto fijo de la transferencia fiscal exista.
- Las condiciones de borde de drift nulo y la construccion de la matriz de
  transicion en el espacio de estados completo estan fuera del alcance
  formalizado; solo se verifica la propiedad de suma cero del generador en la
  dimension de productividad.
- El reparto CES esta verificado en la solucion interior. Las soluciones de
  esquina, que el codigo compara por utilidad directa, no estan formalizadas.
- Las decisiones laborales estan verificadas sector por sector y en el caso
  vinculante. La convergencia del algoritmo numerico que resuelve el caso
  vinculante no esta formalizada.
- La demanda estatica de capital informal esta verificada en el caso con capital
  estrictamente positivo. El caso sin capital informal no esta cubierto por esa
  rama.
- La calibracion, los momentos objetivo y todos los resultados cuantitativos
  estan fuera del alcance de esta revision.

## 6. Additional Assumptions Beyond Paper
- None.

Las tres convenciones de modelo registradas en el expediente de fidelidad (drift
agregado nulo en estado estacionario, regla de reparto de beneficios por horas, y
ausencia de impuesto al consumo) son selecciones explicitas que el propio anexo
enuncia o que se siguen de la especificacion de cierre; no son premisas
adicionales al documento.

## 7. Proof-Strategy Deviations
- None.

## 8. Proof Tricks Worth Reusing
- La optimalidad global de la oferta laboral isoelastica se obtiene sin ningun
  argumento de derivadas, aplicando la desigualdad de Bernoulli para exponentes
  reales al excedente reescalado. El mismo patron sirve para cualquier problema
  de la forma ingreso lineal menos desutilidad isoelastica.
- La identidad de Walras se prueba como una combinacion lineal exacta de las
  condiciones de equilibrio, lo que la hace robusta a cambios de notacion y
  expone de inmediato que terminos faltan cuando la identidad impresa no cierra.

## 9. Generalizations, Conjectures, and Extensions
Ademas de las ocho filas de la fuente, se probaron ocho resultados que el anexo no
enuncia pero que caracterizan el modelo como extension del Aiyagari clasico. Viven
en `ExtensionResults.lean`, no cuentan para la cobertura del anexo, y no tienen
fila de revision fuente-a-Lean.

**Anidamiento del modelo clasico.** Apagar el sector informal colapsa el modelo al
Aiyagari estandar con oferta laboral endogena, sin tomar limites: si la ventaja
salarial informal es nula las horas informales optimas son cero; con trabajo
informal nulo el producto y el beneficio informal son cero; con peso CES uno sobre
el bien formal el agregador colapsa al bien unico y desaparece el precio relativo;
y la condicion de primer orden que queda es exactamente la del modelo de una firma.
Este es el sentido preciso en que el modelo de dos firmas contiene al clasico.

**Sorting monotono por productividad.** Con barrera de acceso decreciente en la
productividad y ventaja comparativa informal atenuada, el atractivo relativo del
sector formal es estrictamente creciente en la productividad; en el caso interior
la razon de horas hereda esa monotonia, y en el caso vinculante la monotonia
estricta del residuo KKT la traslada a las horas formales. Es el mecanismo que
disciplina el target de gap de formalidad por productividad. La conclusion es
condicional al multiplicador de riqueza: aisla el canal de productividad
manteniendo fija la valoracion marginal de la riqueza, y esa es exactamente la
razon por la que el gradiente por quintil de riqueza no se sigue de aqui.

**Margen intensivo sin salto de participacion.** Como la barrera entra
multiplicando las horas formales y no como costo fijo de entrada, la politica
laboral es una funcion continua de la productividad: no hay umbral en el que las
horas salten de cero a un valor positivo, que es lo que produciria un modelo con
margen extensivo. Se prueba ademas el umbral exacto de exclusion: las horas
formales son estrictamente positivas si y solo si la barrera es menor que el
ingreso laboral formal bruto por unidad de tiempo.

**Fidelidad de la traduccion del AR(1) a tiempo continuo.** Tres resultados con
anclaje en la Seccion 2.1 del anexo, que podrian promoverse a filas de revision en
una futura pasada de intake: la difusion elegida devuelve exactamente la varianza
estacionaria objetivo para cualquier velocidad de reversion; el mapeo de la
persistencia anual a la velocidad de reversion reproduce exactamente esa
persistencia; y la media de la log-normal es estrictamente mayor que uno para
cualquier dispersion no degenerada, de modo que la renormalizacion ex-post no es
opcional. Estos tres usan como hecho clasico conocido la varianza estacionaria y
la autocorrelacion de un Ornstein-Uhlenbeck; la teoria de ecuaciones diferenciales
estocasticas no se formaliza.

**Homoteticidad del consumo CES.** El agregador es homogeneo de grado uno, y en
consecuencia la composicion de la canasta formal-informal es identica para todos
los agentes, con valor cerrado independiente de la riqueza y de la productividad.
Es el diagnostico de canasta que imprime la implementacion, hasta ahora afirmado
en un comentario del codigo y no probado.

Sobre las filas de la fuente: la monotonia estricta del residuo laboral vinculante
vale para cualquier par de desutilidades isoelasticas con el mismo exponente de
Frisch; la identidad de vaciamiento admite de inmediato la variante con devolucion
de la prima de deuda, en la que ese termino desaparece; y el agotamiento de Euler
de la firma informal se generaliza sin cambios a cualquier tecnologia homogenea de
grado menor o igual que uno.


## 10. Mathematical Typos or Other Fixes Suggested in the Source Paper
La revision encontro seis correcciones necesarias en el anexo. Ninguna cambia los
resultados cuantitativos del trabajo, porque en todos los casos la version
implementada es la correcta; lo que habia que corregir era el texto del anexo.

**Estado: aplicadas.** Las seis correcciones se aplicaron al anexo aguas arriba en
septiembre de 2026 y el documento recompila sin errores. El texto corregido no ha
sido re-auditado: este reporte describe la version auditada original, cuyo digest
esta fijado en el registro de fuente.

1. **Pesos del agregador CES.** El anexo escribe el agregado de consumo con pesos
   elevados a `1/sigma_C`. Con esos pesos, la condicion de tangencia da un ratio
   de demanda `(omega_C/(1-omega_C)) * p_I^{sigma_C}`, que no coincide con el
   `xi = (omega_C * p_I/(1-omega_C))^{sigma_C}` que el propio anexo escribe dos
   parrafos despues. La forma consistente con esa condicion de primer orden es la
   de pesos sin exponenciar,
   `C = [omega_C c_F^{eta_C} + (1-omega_C) c_I^{eta_C}]^{1/eta_C}`.

2. **Demanda estatica de capital informal.** La formula cerrada de `K_I` omite el
   precio del bien informal. La condicion de primer orden del capital que el
   mismo anexo usa para el beneficio residual iguala el costo de uso al producto
   marginal en valor, de modo que la formula correcta es
   `K_I = (p_I alpha_I A_I/(r+delta))^{1/(1-alpha_I)} L_I^{beta_I/(1-alpha_I)}`.

3. **Forma funcional de la prima de deuda.** El anexo escribe
   `chi(z) = chi_0 (z_1/z)^{eta_chi}`. La especificacion vigente, que es tambien
   la del documento principal, es
   `chi(z) = chi_0 ((z_max - z)/(z_max - z_min))^{eta_chi}`. Ambas son
   decrecientes en `z`, de modo que la propiedad que el anexo advierte se
   conserva, pero la expresion impresa no es la del modelo.

4. **Forma de la barrera de acceso formal.** El anexo describe la barrera como un
   valor positivo unicamente en el nodo de productividad mas baja y cero en los
   demas. La especificacion vigente interpola de forma suave y decreciente entre
   `kappa_{z1}` en `z_min` y `kappa_{z2}` en `z_max`.

5. **Condicion de vaciamiento del mercado de activos.** El anexo escribe la
   demanda agregada de capital como `k(r) * L_F(r)`, omitiendo el capital
   informal, que se alquila al mismo costo de uso. La condicion correcta es
   `S(r) = k(r) * L_F(r) + K_I(r)`. Tal como estaba impresa, era incompatible con
   la condicion de Walras del bien formal, que requiere `K = K_F + K_I`.

6. **Identidad de vaciamiento del bien formal.** Ver la seccion siguiente.

Se aclaro ademas la interpretacion de la prima de deuda. El anexo la justificaba
como "costos de intermediacion o incumplimiento implicito"; esas son dos historias
con tratamientos distintos, y solo la primera corresponde a la especificacion
implementada. El texto corregido se compromete con la lectura de costo real de
intermediacion, coherente con el enfoque institucional que adopta la revision
literaria del trabajo, y explica por que la lectura de incumplimiento exigiria
devolver los pagos a los deudores que incumplen y no repartirlos de forma uniforme.

Fuera del anexo, y por tanto fuera del alcance auditado, el documento principal
presenta dos erratas en la seccion de la firma informal: escribe el beneficio
como `(1-beta_I) p_I Y_I/(alpha_I+beta_I)` en lugar de
`(1-alpha_I-beta_I) p_I Y_I`, y coloca el precio dentro de la funcion de
produccion al escribir `Y_I = p_I A_I K_I^{alpha_I} L_I^{beta_I}`. El anexo y la
implementacion coinciden entre si y difieren del documento principal en ambos
puntos.

## 11. Paper Issues or Caveats
**La condicion de vaciamiento del bien formal, tal como esta impresa, no se sigue
de las demas condiciones del modelo.**

El anexo enuncia `C_F + delta K_F + DebtPremPayments = Y_F`. Agregando la
restriccion presupuestaria del hogar bajo la distribucion estacionaria, y usando
el presupuesto del gobierno, el agotamiento del producto formal, el beneficio
residual informal, el vaciamiento del bien informal y el vaciamiento de activos
—todas condiciones del propio anexo— la identidad que se obtiene es

`Y_F = C_F + delta K + KappaPayments + DebtPremPayments`,  con `K = K_F + K_I`.

Faltan dos cosas en la version impresa: los pagos de la barrera de acceso formal,
que salen del presupuesto del hogar y no se devuelven a ningun agente, y la
depreciacion del capital informal, que queda fuera al escribir `K_F` en lugar del
capital total. La version impresa vale exactamente cuando
`KappaPayments + delta K_I = 0`. En la especificacion de cierre ninguno de los
dos terminos es nulo, de modo que la identidad impresa no cierra.

Esto es sustantivo porque la identidad de Walras es el chequeo que valida la
consistencia contable de todo el equilibrio. La verificacion residual que hace la
implementacion tampoco corresponde a la identidad correcta: comprueba
`Y_F - C_F - delta K - KappaPayments`, es decir incluye los pagos de barrera pero
omite los pagos de prima de deuda. Los dos criterios, el del anexo y el del
codigo, omiten cada uno un termino distinto; el residuo reportado por el codigo
es pequeno porque los pagos de prima de deuda son pequenos en la calibracion, no
porque el criterio sea el correcto.

La identidad corregida esta completamente probada, junto con la caracterizacion
exacta de cuando la version impresa coincide con ella.

## 12. Detailed Formalization Evidence
Cada afirmacion revisada aparece exactamente una vez como una proposicion
transparente en `PaperInterface.lean`, con su punto de prueba de tipo identico en
`ProofInterface.lean` y su implementacion en `MainTheorems.lean`. La construccion
del paquete no contiene `sorry`, `admit`, ni declaraciones de axioma nuevas.

| Fila | Ancla en el anexo | Estado |
| --- | --- | --- |
| Generador OU: filas suman cero | Section 2.2, `eq:Qz_construction` | probado |
| Prima de deuda decreciente en `z` | Section 3.2, `eq:debtprem` | probado |
| Reparto CES optimo | Section 3.5, `eq:ces_foc` | probado con correccion de fuente |
| Oferta laboral interior | Section 3.6, `eq:foc_F`, `eq:foc_I` | probado |
| Caso vinculante KKT | Section 3.6, `eq:kkt_binding` | probado |
| Firma formal: CPO y agotamiento | Section 4.1, `eq:formal_foc` | probado |
| Firma informal: beneficio y capital | Section 4.2, `eq:wI`, `eq:PiI` | probado con correccion de fuente |
| Vaciamiento del bien formal | Section 5.2, item (iii) | probado con enunciado corregido |

Ademas, `ExtensionResults.lean` contiene ocho teoremas probados que no son filas
de la fuente: anidamiento del Aiyagari clasico, sorting monotono por
productividad, ausencia de salto de participacion con su umbral exacto de
exclusion, tres resultados de fidelidad del proceso de productividad, y dos de
homoteticidad CES. Ver la Seccion 9.

## 13. Paper Assumption Provenance
No hay supuestos declarados fuera del documento fuente. `Assumptions.lean` esta
vacio y `status.json` no lista nombres de supuestos.

| Assumption declaration | Lean declaration | Source location / statement | Assumption validators | Comments |
| --- | --- | --- | --- | --- |
| None | `none` | None | None | Ninguna fila revisada necesita una premisa ajena al anexo. |

## 14. Displayed Formula Provenance
| Paper formula / subclaim | Lean declaration | Provenance | Validators | Comments |
| --- | --- | --- | --- | --- |
| `eq:Qz_construction` filas suman cero | `paper_ou_generator_rows_sum_zeroSpec` | derivada de las definiciones del generador | Lean | Cubre fila interior y ambos bordes reflectores. |
| `eq:debtprem` monotonia | `paper_debt_premium_decreasing_in_productivitySpec` | derivada de la forma impresa | Lean | La forma impresa esta desactualizada; ver Seccion 10. |
| `eq:ces_foc` ratio y deflactor | `paper_ces_optimal_demand_ratioSpec` | derivada del agregador corregido | Lean | Ver correccion 1 en Seccion 10. |
| `eq:foc_F` / `eq:foc_I` | `paper_interior_labor_first_order_conditionSpec` | derivada del problema instantaneo | Lean | Incluye optimalidad global y unicidad. |
| `eq:kkt_binding` | `paper_binding_labor_kkt_monotone_and_cornersSpec` | derivada del residuo impreso | Lean | Monotonia estricta, extremos y ambas esquinas. |
| `eq:formal_foc` | `paper_formal_firm_first_order_conditionsSpec` | derivada de la CPO del capital | Lean | Incluye agotamiento del producto. |
| `eq:PiI` y demanda de `K_I` | `paper_informal_firm_profit_exhaustionSpec` | derivada de ambas CPO | Lean | Ver correccion 2 en Seccion 10. |
| Vaciamiento del bien formal | `paper_walras_formal_goods_marketSpec` | derivada de la agregacion presupuestaria | Lean | Ver Seccion 11. |

## 15. Library Lift Pass
- Reusable library extraction candidates: la cota de excedente isoelastica
  (Bernoulli) y las dos identidades de potencia real usadas para desplazar
  exponentes son genericas y podrian moverse a la libreria compartida.
- Library certificate/source-boundary audit: no aplica. Las filas revisadas no
  consumen ninguna API de la libreria del repositorio que tome certificados;
  dependen solo de aritmetica real y de potencias reales de Mathlib.
- Paper-local hidden-premise audit: no se ejecuto el auditor recursivo. Las ocho
  proposiciones estan escritas con todas sus premisas visibles en la firma, sin
  registros, envoltorios ni certificados intermedios.

## 16. DAG Audit
- Rendered artifact: `docs/DependencyDAG.pdf`, generado con pdflatex, una pagina.
  El preambulo TikZ vive junto al diagrama en `docs/dag_preamble.tex`.
- Topology: verificada contra las dependencias reales de las pruebas. La cota de
  Bernoulli alimenta la CPO laboral interior; las identidades de potencias reales
  alimentan las dos filas de firmas; las conclusiones de ambas firmas son
  hipotesis de la identidad de vaciamiento; y esa identidad apunta, con arista
  discontinua, al bloque de existencia del equilibrio que no esta formalizado.
  Las cuatro filas restantes no tienen aristas porque se prueban directamente
  desde Mathlib, sin lemas auxiliares propios ni conclusiones de otras filas.
- Layout: inspeccionado sobre el PDF renderizado; sin solapamientos de cajas,
  aristas ni etiquetas.

## 17. Validation Checks
- `lake build BN26InformalityWealthPeru`: exitoso, 8319 objetivos, incluyendo
  `ExtensionResults.lean`.
- Barrido de `sorry`, `admit` y declaraciones de axioma en el paquete: limpio.
- Verificacion del contribuyente en modo rapido y en modo completo con la fuente
  presente: ejecutadas.
- Cruce numerico de los teoremas contra la corrida de cierre del paquete de
  replicacion, en `docs/VERIFICACION_NUMERICA.md`: las filas verificables se
  cumplen en el equilibrio computado con errores entre 1e-15 y 1e-4, la
  identidad de vaciamiento corregida reduce el residual reportado, y la version
  impresa en el anexo falla por exactamente el termino que el teorema senala.
  El mismo documento reporta una sensibilidad de la discretizacion de la
  productividad que muestra un sesgo de dispersion controlado por el ancho de
  grilla y no por el numero de nodos.
- No se ejecutaron las lineas de auditoria semantica asistidas por modelo
  (correspondencia fuente-a-Spec, cobertura de la fuente, y revision de supuestos).
  Sin ellas este trabajo no puede reclamar cierre completo, y por eso el estado
  declarado es formalizacion parcial.

## 18. Paper Definitions Checked
Se leyeron y usaron como insumo, sin declararlas como filas revisables propias,
las definiciones de: proceso de productividad y su discretizacion, preferencias y
restriccion presupuestaria del hogar, prima de deuda, barrera de acceso formal,
ecuacion de Hamilton-Jacobi-Bellman, agregador CES, salarios efectivos por sector,
tecnologias formal e informal, presupuesto del gobierno, ecuacion de Kolmogorov
Forward, y definicion de equilibrio estacionario recursivo.

## 19. Named Theorem Statements Checked
El anexo no numera proposiciones ni teoremas. El alcance revisado corresponde a
las ecuaciones numeradas que enuncian una afirmacion derivable, listadas en la
tabla de la Seccion 12.

## 20. Paper-Facing Statement Validator Ledger
| Paper-facing statement | Lean declaration | Validators | Validator comments |
| --- | --- | --- | --- |
| Generador OU: filas suman cero | `paper_ou_generator_rows_sum_zeroSpec` | Lean (prueba) | Sin revision humana registrada. |
| Prima de deuda decreciente | `paper_debt_premium_decreasing_in_productivitySpec` | Lean (prueba) | Sin revision humana registrada. |
| Reparto CES optimo | `paper_ces_optimal_demand_ratioSpec` | Lean (prueba) | Sin revision humana registrada. |
| Oferta laboral interior | `paper_interior_labor_first_order_conditionSpec` | Lean (prueba) | Sin revision humana registrada. |
| Caso vinculante KKT | `paper_binding_labor_kkt_monotone_and_cornersSpec` | Lean (prueba) | Sin revision humana registrada. |
| Firma formal: CPO | `paper_formal_firm_first_order_conditionsSpec` | Lean (prueba) | Sin revision humana registrada. |
| Firma informal: beneficio | `paper_informal_firm_profit_exhaustionSpec` | Lean (prueba) | Sin revision humana registrada. |
| Vaciamiento del bien formal | `paper_walras_formal_goods_marketSpec` | Lean (prueba) | Sin revision humana registrada. |

## 21. Source-Coverage Audit Ledger
- Source inventory: 8 afirmaciones derivables inventariadas sobre
  `anexo_matematico.tex`, mas 12 definiciones de modelo usadas como insumo.
- Coverage result: 8 cubiertas de forma directa; la existencia del equilibrio y
  el esquema numerico quedan como material fuera del alcance revisado.
- LLM-as-judge coverage audit: no ejecutado.
- Row-local statement checks: no ejecutados.

| Source statement | Linked Lean review rows | Coverage judgment | Row-local statement checks | Comments |
| --- | --- | --- | --- | --- |
| `eq:Qz_construction` y suma de filas | `paper_ou_generator_rows_sum_zeroSpec` | covered | no ejecutado | — |
| `eq:debtprem` y su monotonia | `paper_debt_premium_decreasing_in_productivitySpec` | covered | no ejecutado | Forma impresa desactualizada. |
| `eq:ces_foc` | `paper_ces_optimal_demand_ratioSpec` | covered | no ejecutado | Requiere el agregador corregido. |
| `eq:foc_F`, `eq:foc_I` | `paper_interior_labor_first_order_conditionSpec` | covered | no ejecutado | — |
| `eq:kkt_binding` y esquinas | `paper_binding_labor_kkt_monotone_and_cornersSpec` | covered | no ejecutado | — |
| `eq:formal_foc` | `paper_formal_firm_first_order_conditionsSpec` | covered | no ejecutado | — |
| `eq:wI`, `eq:PiI`, demanda de `K_I` | `paper_informal_firm_profit_exhaustionSpec` | covered | no ejecutado | Requiere el factor de precio corregido. |
| Vaciamiento de mercados, item (iii) | `paper_walras_formal_goods_marketSpec` | covered | no ejecutado | Enunciado corregido; ver Seccion 11. |
| `eq:HJB`, `eq:KF`, definicion de equilibrio | — | out-of-scope | — | Existencia no formalizada; ver Seccion 5. |
| `eq:boundary`, `eq:Aswitch`, esquema upwind | — | out-of-scope | — | Metodo numerico; ver Seccion 5. |
