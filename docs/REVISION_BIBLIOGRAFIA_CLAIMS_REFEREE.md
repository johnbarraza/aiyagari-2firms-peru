# Revisión de bibliografía, claims y pedidos previsibles de un evaluador

**Fecha:** 2026-10-04
**Documento revisado:** `INFORMALIDAD_RIQUEZA_HA_PERU.md`, README y anexo matemático
**Método:** adaptación del flujo `review-paper` y `referee preview` de
`Top_papers_creator` a un modelo estructural calibrado, no a un diseño
econométrico causal.

## Veredicto ejecutivo

El proyecto puede sostenerse como un buen trabajo de curso sobre un mecanismo
estructural, pero necesita **revisiones mayores** antes de presentarse como paper
cuantitativo. Los problemas centrales no son la falta de econometría, sino:

1. el documento, el anexo y la corrida canónica describen calibraciones distintas;
2. se atribuyen efectos a mecanismos sin mostrar los contrafactuales que los aíslan;
3. cuatro parámetros internos se vinculan de manera poco clara con tres targets;
4. `T6` y `Tgasto` comparan objetos que no son equivalentes entre modelo y datos;
5. varias referencias contienen errores de autor, año, título o interpretación.

## Hallazgos bloqueantes

### 1. El anexo no documenta el modelo reportado

| Objeto | Documento principal | Anexo |
| --- | ---: | ---: |
| $\gamma$ | 1 | 2 |
| $\rho$ | 0.073 | 0.05 |
| $\psi_F,\psi_I$ | 55, 34 | 80, 100 |
| $\omega_C$ | 0.56 | 0.40 |
| $\alpha_K$ | 0.573 | 0.636 |
| $A_I$ | 0.98 | 0.305 |
| $\nu_I$ | 0.6 | 1.0 |
| $N_z$ | 40 | 7 |
| T4 modelo | 51.7% | 56.0% |
| Tkz modelo | 37.8% | 36.4% |
| Tgasto modelo | 1.465 | 1.153 |

El anexo también conserva una firma informal sin capital en su resumen inicial,
aunque otras secciones usan la especificación con capital. Debe regenerarse desde
la corrida canónica o rotularse inmediatamente como versión histórica no vigente.

### 2. La hipótesis central requiere contrafactuales

El equilibrio base muestra una asociación interna entre productividad, cuñas,
horas sectoriales y activos. Por sí solo no cuantifica cuánto de la desigualdad
es causado por la informalidad, cuánto aporta cada cuña ni cuánto reduce el ahorro
la oferta laboral endógena.

Tabla mínima requerida:

1. benchmark calibrado;
2. $\kappa=0$;
3. prima de deuda igual a cero;
4. ambas cuñas apagadas;
5. oferta laboral fija frente a endógena;
6. reducciones de 25%, 50% y 100% en la barrera formal.

En cada caso deben reportarse informalidad, producción, Gini de activos y consumo,
riqueza media/mediana, masa endeudada, $r$, $p_I$ y, si es posible, bienestar CEV.

### 3. La calibración está subdocumentada

El texto menciona cuatro parámetros internos, $\psi_F$, $\psi_I$, $A_I$ y
$\kappa_{z1}$, pero solo tres targets claramente vinculantes: T4, T5 y Tkz. No se
explica cómo T4 identifica separadamente ambos $\psi$, ni se publica función
objetivo, pesos, algoritmo o criterio de selección.

Opciones defendibles:

- normalizar uno de los dos $\psi$ y calibrar el otro;
- calibrar un nivel y el cociente $\psi_F/\psi_I$ usando dos momentos distintos;
- agregar un momento independiente de horas totales o elasticidad laboral.

`Tgasto` debe declararse target solo si entra realmente en la función objetivo. Si
no entra, debe rotularse como validación externa imperfecta.

### 4. T6 y Tgasto no son comparaciones homogéneas

- **T6:** el dato INEI es una clasificación extensiva de empleo informal por
  quintil, mientras el modelo reporta participación intensiva de horas por
  quintil de activos. El error de 53.0% frente a 4.4% no es un error de predicción
  bien definido. Debe usarse como validación cualitativa o reconstruirse con la
  misma población, variable de ordenamiento y definición de informalidad.
- **Tgasto:** el dato clasifica hogares por formalidad del jefe y usa gasto
  observado; el modelo clasifica estados por mayoría de horas y usa
  $c_F+p_Ic_I$. Debe explicitarse como proxy no equivalente.

## Auditoría bibliográfica priorizada

| Prioridad | Hallazgo | Corrección |
| --- | --- | --- |
| Crítica | Restrepo-Echavarría (2025), “Informal Labor Markets in General Equilibrium”, *Econometrica* R&R no pudo verificarse. | Eliminar el estado editorial y las atribuciones específicas. Si no existe un manuscrito estable, usar solo [Restrepo-Echavarría (2014)](https://doi.org/10.1016/j.euroecorev.2014.06.001) para las afirmaciones que realmente cubre. |
| Crítica | El anexo atribuye Galindo et al. a Galindo, Granda, Rodríguez y Villacorta. | Los autores correctos son Hamilton Galindo, Alan Ledesma, César Salinas y Luis Yepez; usar la [ficha oficial BCRP](https://investigacion.bcrp.gob.pe/en/research/working-papers/2024/dt-2024-005-en). |
| Crítica | Hong aparece como 2022 y como un mimeo distinto. Además, 0.544 se interpreta como desviación estacionaria de $\log z$. | La publicación final es Hong (2023), *JIE* 140, 103712, DOI [10.1016/j.jinteco.2022.103712](https://doi.org/10.1016/j.jinteco.2022.103712). Hong estima $\rho=0.963$ trimestral, de donde $\rho^4=0.861$ anual. El valor 0.544 es la desviación del draw inicial $P_0$, no la desviación estacionaria OU. Recalcular y documentar el mapeo. |
| Mayor | Castillo–Rojas tiene título, inicial y año inconsistentes. | Usar Paul Castillo y Youel Rojas (2014), “Términos de intercambio y productividad total de factores…”, *REE* 28. La fuente sí respalda $\delta=0.10$ para Perú; véase el [PDF oficial](https://www.bcrp.gob.pe/docs/Publicaciones/Revista-Estudios-Economicos/28/ree-28.pdf). |
| Mayor | $\alpha_K=0.573$ y $0.636$ se atribuyen a la misma estimación. | Céspedes et al. reporta estimadores distintos: 0.573 corresponde a efectos fijos restringidos y 0.636 a Arellano–Bond restringido. Elegir uno y justificarlo con el [artículo oficial](https://www.bcrp.gob.pe/docs/Publicaciones/Revista-Estudios-Economicos/28/ree-28-cespedes-aquije-sanchez-veratudela.pdf). |
| Mayor | $(\alpha_I,\beta_I)=(0.22,0.619)$ se presenta como proveniente de Göbel et al., mientras el anexo reporta estimaciones originales distintas. | Si 0.22/0.619 es calibración propia, declararlo. Separar estimación fuente de transformación propia y corregir el título usando la [ficha BCRP](https://investigacion.bcrp.gob.pe/en/research/working-papers/2013/dt-2013-001-en). |
| Mayor | Achdou et al. (2022) aparece en el anexo como libro de Princeton. | Es un artículo de *Review of Economic Studies* 89(1), 45–86, DOI [10.1093/restud/rdab002](https://doi.org/10.1093/restud/rdab002). Citar el apéndice por separado. |
| Mayor | Stiglitz y Weiss figura como 1992. | Cambiar a 1981, *AER* 71(3), 393–410. |
| Mayor | Bacher et al. se usa para afirmar mayor flexibilidad laboral en hogares de mayores ingresos. | El artículo encuentra un added-worker effect mayor en hogares jóvenes, no ese gradiente de ingreso. Usar el resultado correcto: [JME 150, 103696](https://doi.org/10.1016/j.jmoneco.2024.103696). |
| Mayor | Pijoan-Más se usa para concluir menor ahorro y menor Gini en este modelo. | La fuente motiva el canal de suavización mediante horas, pero las conclusiones para esta calibración requieren un contrafactual propio de oferta fija. |
| Mayor | Restan citas en texto sin entrada bibliográfica. | Añadir, como mínimo, Levy (2008), Perry et al. (2007), Bensoussan y Lions (1984), Kaplan–Moll–Violante (2018), Greenwood–Hercowitz–Huffman (1988), Yanagimoto (2026) y Goenka et al. (2025), o retirar las menciones no verificadas. |

## Claims que deben reformularse

### Claim central recomendado

> Construimos un modelo de equilibrio general calibrado para Perú en el que los
> hogares asignan horas entre dos sectores y enfrentan cuñas dependientes de la
> productividad. La calibración reproduce tres momentos directamente
> disciplinados y genera, condicionalmente a esas cuñas, una asociación
> estacionaria entre baja productividad, mayor participación informal y menor
> riqueza. Los resultados no identifican un efecto causal de la informalidad en
> los datos. La contribución de cada mecanismo debe cuantificarse mediante
> contrafactuales estructurales.

### Sustituciones puntuales

- “La informalidad genera/acentúa…” → “En la economía calibrada, las cuñas
  asociadas con la informalidad producen, dentro del modelo…” solo después de
  mostrar el contrafactual correspondiente.
- “Trampa de pobreza” → “asociación estacionaria entre baja productividad,
  participación informal y menor riqueza”, salvo que se documenten persistencia,
  tiempos de salida o dinámica de transición.
- “La oferta laboral endógena reduce el ahorro precautorio” → “ofrece un canal
  potencial de autoaseguramiento; su efecto cuantitativo se evalúa comparando con
  oferta laboral fija”.
- “La ausencia del margen extensivo explica T6” → “es una explicación plausible,
  junto con diferencias de medición y heterogeneidad omitida”.
- “Un costo fijo es incompatible con HACT” → “rompe el problema de control
  continuo resuelto por el esquema actual y requiere métodos de switching o QVI”.
- “El sorting es una validación” → “la pendiente agregada se disciplina con Tkz;
  es ajuste interno, no una predicción externa”.

## Qué probablemente pedirá un jurado o referee

### Imprescindible

1. Una especificación canónica única en paper, anexo, README, código y metadatos.
2. Tabla parámetro–fuente–target–identificación–rango de sensibilidad.
3. Función objetivo, pesos, algoritmo de calibración y diagnóstico de rango local.
4. Contrafactuales sin $\kappa$, sin prima, sin ambas cuñas y con trabajo fijo.
5. Tabla de ajuste completa que no omita el error de `Tgasto` (1.465 frente a
   1.913, aproximadamente -23.4%).
6. Reclasificar o reconstruir T6 y `Tgasto` con definiciones comparables.
7. Auditoría numérica: residuos HJB, KF, activos, bien informal, Walras,
   presupuesto público, masa en bordes y estabilidad desde múltiples inicios.
8. Una corrida canónica versionada y un comando único que regenere tablas y
   figuras.

### Recomendable

- sensibilidad a $\gamma,\rho,\phi,\sigma_C,\nu_I,\alpha_I,\beta_I$, límite de
  deuda y forma de $\kappa(z)$;
- comparación de tres modelos anidados: Aiyagari estándar, dos sectores con
  trabajo fijo y modelo completo;
- descomposición del cambio en Gini por canal e interacción;
- intervalos de targets ENAHO por bootstrap o variación anual;
- bienestar por quintil/productividad y robustez con devolución de pagos de
  barrera/prima en lugar de destrucción de recursos.

### No imprescindible para una entrega de curso

- margen extensivo completo;
- transición dinámica MIT;
- género, ciclo de vida o múltiples subsectores informales;
- formalización adicional de existencia/unicidad en Lean.

## Orden de trabajo recomendado

1. Congelar la corrida canónica y regenerar el anexo.
2. Corregir bibliografía y mapeos de parámetros, especialmente Hong.
3. Resolver la identificación de $\psi_F$ y $\psi_I$.
4. Ejecutar contrafactuales estacionarios mínimos.
5. Reescribir resumen, introducción, discusión y conclusiones con lenguaje
   condicional.
6. Rehacer la taxonomía: supuestos, parámetros externos, targets internos,
   validación externa y resultados endógenos.
7. Publicar la corrida reproducible y verificar que las tablas se regeneren.
