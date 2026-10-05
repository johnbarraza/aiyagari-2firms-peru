# Busqueda de datos con Top Papers Creator

La etapa de descubrimiento se ejecuto el 5 de octubre de 2026 con el tema de empleo informal, producto informal, horas, productividad y calibracion para Peru, Mexico, Colombia, Ecuador y Paraguay. La salida original quedo en el proyecto local `informality_cross_country_20261005` de `Top_papers_creator`.

El buscador comprobo que los modulos laborales de ENAHO 2021-2025 se pueden descargar mediante el conector de microdatos del INEI. Esto permite actualizar T4 y los perfiles de productividad de Peru. El archivo laboral de 2025 supera 900 MB, por lo que debe procesarse por columnas y no cargarse completo en memoria.

La busqueda encontro el paquete de replicacion de *The Dynamics of Informality and Fiscal Policy under Sovereign Risk*, publicado en el repositorio de JPE Macroeconomics. El paquete puede servir para comparar decisiones de modelacion y pruebas numericas, pero no contiene los momentos nacionales armonizados que necesita esta calibracion. Su registro esta disponible en [Harvard Dataverse](https://doi.org/10.7910/DVN/LCSLHP).

Ninguna base internacional supero el filtro automatico. El motivo principal fue metodologico. El buscador trato la aparicion de Peru como una restriccion geografica y descarto resultados de Mexico, Colombia y Ecuador. Semantic Scholar tambien devolvio un limite temporal de consultas. Por ello, la busqueda automatizada complementa, pero no reemplaza, las fuentes oficiales nacionales.

La combinacion recomendada usa ENAHO para Peru, ENOE para Mexico, GEIH para Colombia, ENEMDU para Ecuador y EPHC para Paraguay. Las tasas de personas ocupadas solo sirven para escoger comparadores. Cada T4 debe reconstruirse como participacion de horas con una regla comun para ocupaciones principal y secundaria. T5 debe provenir de cuentas de valor agregado compatibles y no de una medida amplia de economia no observada.

