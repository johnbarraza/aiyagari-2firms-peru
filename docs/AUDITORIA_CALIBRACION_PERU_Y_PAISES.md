# Auditoria de calibracion de Peru y prueba en otros paises

Fecha de revision: 5 de octubre de 2026.

## Resultado principal

La calibracion peruana es numericamente defendible para sus tres targets directos, pero el paquete tenia una inconsistencia de documentacion. El articulo usa una fraccion de horas informales de 50.9% para 2015-2019, mientras que `model_main.m` y `setup_calibration.m` seguian mostrando 55.7%. El valor de 55.7% pertenece a una version anterior del benchmark y no corresponde al target principal pre-COVID del documento. Esta revision alinea el codigo con 50.9%. El cambio no altera el equilibrio porque el target se usa para evaluar la corrida y no entra en las ecuaciones del modelo.

La corrida guardada produce 51.71% de horas informales, 18.80% de PBI informal y un gap de formalidad por productividad de 37.75%. Frente a 50.9%, 19.0% y 38.6%, las brechas absolutas son 0.81, 0.20 y 0.85 puntos porcentuales. Los tres momentos quedan dentro de una tolerancia de un punto porcentual.

## Estado de la calibracion peruana

| Momento | Modelo | Dato | Brecha | Funcion |
|---|---:|---:|---:|---|
| T4, fraccion de horas informales | 0.5171 | 0.5090 | +0.0081 | Target |
| T5, PBI informal nominal | 0.1880 | 0.1900 | -0.0020 | Target |
| Tkz, gap de formalidad por productividad | 0.3775 | 0.3860 | -0.0085 | Target |
| Ratio de gasto formal dominante a informal dominante | 1.4654 | 1.9130 | -0.4476 | Validacion externa |
| T6, gap de informalidad Q1 a Q5 | 0.0441 | 0.5300 | -0.4859 | Diagnostico no homogeneo |
| Ratio salarial formal neto a informal | 2.327 | 2.300 | +0.027 | Validacion externa |

El buen ajuste de T4, T5 y Tkz no debe describirse como validacion fuera de muestra porque esos momentos disciplinan los parametros. El ratio salarial es el chequeo externo mas favorable. El ratio de gasto y T6 muestran las limitaciones cuantitativas principales.

## Problemas que deben resolverse antes de recalibrar

| Problema | Consecuencia | Decision recomendada |
|---|---|---|
| Cuatro parametros internos, `psi_F`, `psi_I`, `A_I` y `kappa_z1`, frente a tres targets directos | El nivel conjunto de las desutilidades no queda identificado solo por T4 | Normalizar una de las dos desutilidades o agregar horas totales como cuarto momento |
| La grilla con 40 nodos y ancho 2.5 realiza una desviacion de `log z` de 0.5281, no 0.5440 | La heterogeneidad efectiva es 2.9% menor que la declarada | Usar ancho 2.8268 con 40 nodos, o 60 nodos y ancho 3.0, y recalibrar los parametros internos |
| T6 compara horas intensivas del modelo con una clasificacion ocupacional discreta en los datos | La brecha de 48.6 puntos no identifica por si sola el mecanismo faltante | Construir primero un T6 de horas con la misma definicion en microdatos; mantener el T6 ocupacional como contraste |
| El parametro de descuento de 7.3% se recupero de la corrida y no de una estimacion externa | Ayuda a sostener `r* < rho`, pero no constituye evidencia independiente | Reportarlo como supuesto calibrado y mostrar sensibilidad |
| `grid_convergence_test.m` y `escenarios.m` conservan parametros de versiones anteriores | Sus resultados no prueban la especificacion final | No usarlos como evidencia del cierre hasta armonizarlos con `setup_calibration.m` |

## Que significa probar otro pais

Cambiar `HA_IE_T4_DATA` o `HA_IE_T5_DATA` solo cambia las cifras impresas. No produce una economia distinta. Una prueba internacional valida necesita una configuracion local de preferencias o una justificacion para mantenerlas, tecnologia formal e informal, impuesto al trabajo formal, proceso de productividad, barrera de acceso, prima de deuda y momentos construidos con definiciones equivalentes.

La comparacion correcta tiene dos etapas. En la primera se mantienen los parametros internos de Peru y se sustituyen solo parametros externos medidos para el otro pais. Esta es una prueba de transporte y los momentos locales son predicciones fuera de muestra. En la segunda se recalibran `psi_F/psi_I`, `A_I` y `kappa_z1` contra T4, T5 y Tkz locales, manteniendo una normalizacion para la escala de las desutilidades. El ratio salarial, el ratio de gasto y el gradiente por quintil quedan reservados para validacion.

## Países candidatos

Las tasas siguientes son de empleo informal por persona, no fracciones de horas. Sirven para escoger comparadores, pero no pueden reemplazar directamente T4.

| País | Indicador oficial reciente | Afinidad con Perú | Factibilidad para el modelo | Prioridad |
|---|---:|---|---|---:|
| México | 54.4% en 2024 | Menor que Perú, pero suficientemente cercana para una prueba de transporte exigente | ENOE abierta, ENIGH 2024 y medición oficial de economía informal equivalente a 25.4% del PIB | 1 |
| Ecuador | 52.4% en 2024 | Economía andina, heterogeneidad urbana y rural, y una encuesta reciente de gasto | ENEMDU abierta y ENIGHUR 2024-2025; falta una cuenta de PBI informal equivalente | 2 |
| Colombia | 56.8% entre diciembre de 2024 y febrero de 2025 | Mercado laboral dual y microdatos laborales amplios | GEIH abierta y encuesta de presupuesto disponible; la economía no observada es más amplia que T5 | 3 |
| Paraguay | 62.5% en 2024, sin agricultura | Más próximo a Perú por extensión de la informalidad | EPHC abierta; no se encontró una cuenta actual de producto informal comparable | 4 |
| Bolivia | Informalidad muy alta en las comparaciones de OIT | Comparador andino relevante | La encuesta de hogares permite el bloque laboral, pero la medición compatible del producto informal es la principal restricción | 5 |

México debe ser la primera réplica completa por disponibilidad estadística. Ecuador pasa al segundo lugar porque la ENIGHUR 2024-2025 permite construir una validación de gasto reciente, además de los momentos laborales de ENEMDU. Colombia ofrece una encuesta laboral especialmente sólida, pero su medición de economía no observada no reemplaza el PBI informal del modelo. Paraguay funciona mejor como prueba de estrés del bloque laboral. Chile puede usarse como contraste de baja informalidad, no como país parecido.

## Resultado preliminar para México

Sin recalibrar ningún parámetro, el equilibrio peruano genera 51.71% de horas informales y 18.80% de PBI informal. INEGI reporta que en México 54.4% de las personas ocupadas trabajó en condiciones de informalidad en 2024 y que esas actividades produjeron 25.4% del PIB. El primer contraste es solo orientativo porque compara horas del modelo con personas en los datos. El segundo sí es conceptualmente cercano a T5.

| Magnitud | Modelo peruano transportado | México 2024 | Diferencia | Lectura |
|---|---:|---:|---:|---|
| Informalidad laboral | 51.71% de horas | 54.4% de personas | -2.69 puntos | Cercanía descriptiva, no prueba de T4 |
| Participación informal en el PIB | 18.80% | 25.4% | -6.60 puntos | El modelo peruano subpredice el peso productivo informal mexicano |

Este resultado descarta dos conclusiones apresuradas. No puede afirmarse todavía que el modelo ajusta México porque falta construir la fracción de horas con ENOE. Tampoco puede afirmarse que falla por completo. El nivel agregado de trabajo informal está cerca, mientras que la producción informal es demasiado baja. Esa combinación es informativa. Con la tecnología peruana, el modelo asigna a las horas informales menos producto del que muestran las cuentas mexicanas. La réplica mexicana deberá determinar si la brecha se corrige con la productividad informal relativa, con las participaciones de factores o con la composición sectorial, sin usar el ratio salarial ni el gasto para calibrar.

## Momentos que pueden construirse

| Momento | México | Ecuador | Colombia | Paraguay |
|---|---|---|---|---|
| Fracción de horas informales | ENOE, ocupación principal y secundaria | ENEMDU | GEIH | EPHC |
| PBI informal | MEI 2024, directamente comparable | No disponible con equivalencia suficiente | No usar economía no observada sin depuración | No disponible con equivalencia suficiente |
| Gap de formalidad por productividad | ENOE, con grupos educativos comunes | ENEMDU | GEIH | EPHC |
| Ratio salarial | ENOE | ENEMDU | GEIH | EPHC |
| Ratio de gasto según formalidad del jefe | ENIGH 2024 | ENIGHUR 2024-2025 | ENPH 2016-2017 | Sin encuesta reciente equivalente identificada |
| Gradiente por riqueza | Aproximación con activos y tenencia en ENIGH | Aproximación con ENIGHUR | Aproximación con ENPH | Cobertura insuficiente para una comparación homogénea |

La fracción de horas debe calcularse como la suma ponderada de horas informales dividida entre la suma ponderada de horas totales. Cuando una encuesta identifica una ocupación secundaria, sus horas y su condición de formalidad deben incorporarse por separado. La tasa de personas informales no reemplaza ese cálculo.

El gap por productividad debe usar una regla común en los cuatro países. La opción reproducible inmediata es formar grupos por educación dentro de la población ocupada y medir la diferencia de formalidad entre los grupos alto y bajo. Una extensión más exigente estimaría residuos salariales comparables. No conviene mezclar ambas definiciones dentro de la misma tabla.

El ratio salarial debe construirse por hora y con la misma población. Si no se dispone de una medida homogénea de impuestos y contribuciones, se reportarán por separado el ratio bruto observado y el ratio neto ajustado. El primero es comparable entre encuestas; el segundo requiere parámetros institucionales nacionales.

## Criterio para afirmar que el modelo ajusta otro país

La prueba de transporte mantiene los parámetros internos de Perú y reemplaza únicamente los parámetros externos medidos en el país. El modelo ajustará razonablemente si T4, T5 y el gap de formalidad quedan próximos a los datos sin recalibrar las desutilidades, la productividad informal relativa ni la pendiente de la barrera. Una distancia de hasta dos puntos porcentuales en T4 y T5 puede considerarse un ajuste fuerte; entre dos y cinco puntos, un ajuste parcial; una brecha mayor exige explicar el mecanismo que no se transporta. Estos umbrales son reglas de reporte, no intervalos estadísticos.

La recalibración nacional es una prueba distinta. Allí T4, T5 y el gap disciplinan tres instrumentos internos, mientras que el ratio salarial, el ratio de gasto y el gradiente por riqueza permanecen fuera del ajuste. Un país solo contará como validación exitosa si mejora los targets sin deteriorar sistemáticamente estos momentos reservados.

## Insumos minimos por pais

| Bloque | Variable | Tratamiento |
|---|---|---|
| Productividad | Persistencia y desviacion estacionaria de residuos salariales | Estimar con panel o pseudopanel armonizado; no importar los valores peruanos |
| Produccion formal | Participacion del capital y depreciacion | Sustituir con estimaciones nacionales o una base internacional comun |
| Produccion informal | Participaciones de capital y trabajo, PTF relativa | Estimar o recalibrar con una medida compatible de valor agregado informal |
| Instituciones | Impuesto efectivo al trabajo formal | Sustituir por pais y documentar si incluye contribuciones sociales |
| Trabajo | Horas formales e informales y horas totales | Construir desde microdatos con una regla comun para ocupaciones principal y secundaria |
| Acceso formal | Gap por educacion o productividad | Construir con los mismos grupos en todos los paises |
| Validacion | Salarios, gasto y gradiente por quintil | No utilizarlos en la calibracion principal |

## Protocolo de prueba

| Etapa | Ejecucion | Criterio de exito |
|---|---|---|
| 1. Cierre Peru | Ejecutar `reproducir_cierre.m` y luego `validate_peru_calibration.m` | Los tres targets directos quedan a menos de un punto porcentual |
| 2. Robustez de grilla | Repetir Peru con ancho 2.8268, o con 60 nodos y ancho 3.0, y recalibrar | Los resultados economicos no cambian materialmente y la desviacion realizada coincide con 0.544 |
| 3. Microdatos de México | Construir T4, gap de formalidad y ratio salarial con ENOE; construir gasto con ENIGH | Reproducir primero los agregados publicados por INEGI |
| 4. Transporte a México | Sustituir parámetros externos mexicanos sin recalibrar parámetros internos | Reportar errores fuera de muestra en T4, T5, gap, salarios y gasto |
| 5. Recalibración de México | Ajustar tres instrumentos a tres targets con una normalización explícita | Evaluar solo los momentos no usados para ajustar |
| 6. Réplicas de Ecuador y Colombia | Repetir el protocolo con definiciones armonizadas, dejando T5 como no disponible | Comparar errores laborales y de gasto, no solo tasas de personas informales |
| 7. Prueba de estrés con Paraguay | Transportar el bloque laboral a una economía con mayor informalidad | Evaluar si el mecanismo conserva el orden y los gradientes empíricos |

Con los insumos disponibles hoy se puede validar el cierre peruano y hacer el contraste agregado preliminar de México. Todavía no existe una calibración internacional completa. La siguiente corrida sustantiva debe hacerse después de construir los momentos mexicanos con microdatos. Ejecutar el modelo para los otros países antes de construir T4 en horas y el proceso local de productividad produciría números, pero no una prueba económica identificada.

## Fuentes oficiales para la ampliacion

| Fuente | Uso |
|---|---|
| [ILOSTAT, estadisticas sobre economia informal](https://ilostat.ilo.org/topics/informality/) | Definiciones y comparacion armonizada de empleo informal |
| [INEI, Produccion y empleo informal en el Peru 2022-2023](https://www.inei.gob.pe/media/MenuRecursivo/publicaciones_digitales/Est/Lib1996/libro.pdf) | Cuenta satelite y benchmark peruano |
| [INEGI, Medición de la Economía Informal 2024](https://www.inegi.org.mx/contenidos/saladeprensa/boletines/2025/pibmed/MEI2024_CP.pdf) | PBI informal de México y empleo informal agregado |
| [INEGI, ENOE](https://www.inegi.org.mx/programas/enoe/15ymas/) | Microdatos trimestrales para horas, formalidad, salarios y educación |
| [INEGI, ENOE 2024, cuestionario ampliado](https://www.inegi.org.mx/rnm/index.php/catalog/983) | Metadatos del primer trimestre, que ofrece el mayor detalle laboral |
| [INEGI, ENIGH 2024](https://www.inegi.org.mx/programas/enigh/nc/2024/) | Gasto, ingreso, activos y características ocupacionales de los hogares mexicanos |
| [DANE, empleo informal y seguridad social](https://www.dane.gov.co/index.php/estadisticas-por-tema/mercado-laboral/empleo-informal-y-seguridad-social/empleo-informal-y-seguridad-social-historicos) | Series y definición oficial de Colombia |
| [DANE, microdatos GEIH 2024](https://microdatos.dane.gov.co/index.php/catalog/819) | Horas, salarios y grupos de Colombia |
| [DANE, microdatos ENPH 2016-2017](https://microdatos.dane.gov.co/index.php/catalog/566) | Gasto de los hogares colombianos |
| [INEC, ENEMDU anual 2024](https://www.ecuadorencifras.gob.ec/documentos/web-inec/EMPLEO/2024/anual/Boletin_tecnico_anual_enero-diciembre_2024.pdf) | Benchmark laboral de Ecuador |
| [INEC, estadísticas laborales ENEMDU](https://www.ecuadorencifras.gob.ec/estadisticas-laborales-enemdu/) | Microdatos para horas, salarios y formalidad de Ecuador |
| [INEC, ENIGHUR 2024-2025](https://www.ecuadorencifras.gob.ec/institucional/el-inec-socializa-los-resultados-de-la-enighur-2024-2025-para-fortalecer-politicas-publicas-y-decisiones-basadas-en-evidencia/) | Gasto e ingreso recientes de hogares ecuatorianos |
| [INE Paraguay, ocupación informal 2024](https://www.ine.gov.py/noticias/2422/la-ocupacion-) | Benchmark y definición de Paraguay |
| [INE Paraguay, microdatos EPHC](https://www.ine.gov.py/microdatos/) | Horas, ingresos y empleo de Paraguay |
