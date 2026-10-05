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

## Paises candidatos

Las tasas siguientes son de empleo informal por persona, no fracciones de horas. Sirven para escoger comparadores, pero no pueden reemplazar directamente T4.

| Pais | Indicador oficial reciente | Afinidad con Peru | Factibilidad para el modelo | Prioridad |
|---|---:|---|---|---:|
| Mexico | 53.2% en 2024 T2 | Informalidad menor, estructura productiva comparable | ENOE abierta y medicion oficial de economia informal equivalente a 24.8% del PIB en 2023 | 1 |
| Colombia | 56.8% en diciembre 2024 a febrero 2025 | Mercado laboral dual y microdatos amplios | GEIH abierta; el 29.9% de valor agregado de economia no observada es mas amplio que T5 y no debe usarse sin depuracion | 2 |
| Ecuador | 58.0% en diciembre de 2024 | Informalidad alta y economia andina | ENEMDU abierta; falta una medida de PBI informal suficientemente equivalente | 3 |
| Paraguay | 62.5% en 2024 | Mas cercano a Peru en informalidad extensa | EPHC disponible; falta una cuenta de producto informal comparable | 4 |
| Bolivia | Informalidad muy alta en las comparaciones de OIT | Comparador estructural cercano | Encuesta de Hogares disponible; comparabilidad y medicion de producto informal son las restricciones principales | 5 |

Mexico debe ser la primera replica completa por disponibilidad estadistica, aunque Paraguay, Ecuador y Bolivia se parecen mas a Peru por nivel de informalidad extensa. Chile puede usarse como contraste de baja informalidad, no como pais parecido.

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
| 3. Transporte a Mexico | Sustituir parametros externos mexicanos sin recalibrar parametros internos | Reportar errores fuera de muestra en T4, T5, Tkz, salarios y gasto |
| 4. Recalibracion Mexico | Ajustar tres instrumentos a tres targets con una normalizacion explicita | Evaluar solo los momentos no usados para ajustar |
| 5. Replicas Colombia y Ecuador | Repetir el protocolo con definiciones armonizadas | Comparar errores y no solo niveles de informalidad |

Con los insumos disponibles hoy se puede validar el cierre peruano, pero no afirmar que ya existe una calibracion internacional. La siguiente corrida sustantiva debe ser Mexico. Ejecutar el modelo para los otros paises antes de construir T4 en horas, T5 compatible y el proceso local de productividad produciria numeros, pero no una prueba economica identificada.

## Fuentes oficiales para la ampliacion

| Fuente | Uso |
|---|---|
| [ILOSTAT, estadisticas sobre economia informal](https://ilostat.ilo.org/topics/informality/) | Definiciones y comparacion armonizada de empleo informal |
| [INEI, Produccion y empleo informal en el Peru 2022-2023](https://www.inei.gob.pe/media/MenuRecursivo/publicaciones_digitales/Est/Lib1996/libro.pdf) | Cuenta satelite y benchmark peruano |
| [INEGI, Medicion de la Economia Informal 2023](https://www.inegi.org.mx/contenidos/saladeprensa/boletines/2024/MDEI/MDEI2023.pdf) | Valor agregado informal de Mexico |
| [INEGI, ENOE segundo trimestre de 2024](https://www.inegi.org.mx/contenidos/saladeprensa/boletines/2024/ENOE/ENOE2024_09_Mex.pdf) | Informalidad laboral y definicion mexicana |
| [DANE, empleo informal y seguridad social](https://www.dane.gov.co/index.php/estadisticas-por-tema/mercado-laboral/empleo-informal-y-seguridad-social/empleo-informal-y-seguridad-social-historicos) | Series y anexos de Colombia |
| [DANE, microdatos GEIH 2024](https://microdatos.dane.gov.co/index.php/catalog/819) | Construccion de horas, salarios y grupos de Colombia |
| [INEC, ENEMDU diciembre de 2024](https://www.ecuadorencifras.gob.ec/documentos/web-inec/EMPLEO/2024/Diciembre/202412_Mercado_Laboral.pdf) | Informalidad y microdatos de Ecuador |
| [INE Paraguay, ocupacion informal 2024](https://www.ine.gov.py/noticias/2422/la-ocupacion-) | Benchmark y definicion de Paraguay |
