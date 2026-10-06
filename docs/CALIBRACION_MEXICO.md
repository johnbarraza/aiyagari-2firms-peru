# Prueba de calibracion para Mexico

## Resultado

Mexico es una prueba de transporte exigente y no una validacion exitosa de la
especificacion actual. La ENOE 2024-I permite reproducir la tasa oficial de
informalidad y construir momentos comparables. El modelo consigue acercarse a
las horas y al producto informal en corridas exploratorias, pero no ajusta al
mismo tiempo el gradiente educativo. El candidato mas cercano tampoco supera
la verificacion fina con 24 nodos de productividad. Por eso no se incorpora una
segunda calibracion nacional al resultado principal de Peru.

## Datos mexicanos

El archivo oficial de la ENOE 2024-I se procesa con
`scripts/data/mexico/build_enoe_moments.py`. La muestra contiene 193,108
ocupados y expande a 59.12 millones de personas. La tasa de informalidad
calculada es 54.35%, practicamente igual al 54.4% publicado por INEGI. Esta
coincidencia valida filtros, ponderadores y clasificacion antes de construir los
momentos nuevos.

| Momento | Valor | Fuente y definicion |
|---|---:|---|
| T4, fraccion de horas informales | 0.5071 | ENOE, horas semanales ponderadas por `FAC_TRI`; la condicion del empleo principal se aplica a las horas totales |
| T5, participacion informal en el PIB | 0.2540 | Medicion de la Economia Informal 2024 de INEGI |
| Tkz, brecha de formalidad por educacion | 0.5671 | Formalidad universitaria menos formalidad con menos de secundaria completa |
| Ratio salarial bruto | 1.4368 | Media ponderada del ingreso horario formal dividida por la informal; se reserva para validacion |

La limitacion de T4 importa. El archivo sociodemografico precodifica la
condicion formal del empleo principal, pero no separa la informalidad de cada
hora del empleo secundario. El momento mexicano es comparable, aunque no
identico, al reparto intensivo de horas del modelo.

## Parametros externos

| Bloque | Valor usado | Evidencia |
|---|---:|---|
| Capital formal | 0.33 | Leal Ordonez usa una participacion de capital de un tercio |
| Retornos informales | 0.33 para capital y 0.43 para trabajo | La suma 0.76 reproduce los rendimientos decrecientes de Leal Ordonez |
| Depreciacion | 0.05 | Calibracion anual de Leal Ordonez |
| Descuento | 0.0619 continuo | Transformacion de beta anual 0.94 |
| Cuña formal | 0.35 | Wedge regulatorio estimado por Alvarez y Ruane |
| Persistencia y dispersion | 0.78 y 0.84 | Proceso anual de ingreso neto reportado para Mexico por Auclert, Rognlie, Souchier y Straub |
| Elasticidad Frisch | 3.27 | Calibracion mexicana de Leyva y Urrutia |

Estas cifras no son estimaciones del presente modelo. Son correspondencias
entre objetos de modelos distintos y se mantienen fijas durante el cribado.

## Clasificacion de la literatura

El flujo de revision de Top Papers Creator separa cuatro familias. Leal Ordonez
es el antecedente macro cuantitativo mas cercano para tecnologia informal y
recaudacion. Alvarez y Ruane es la referencia estructural de firmas
heterogeneas, regulacion e informalidad. Leyva y Urrutia aporta disciplina del
mercado laboral y del ciclo. Auclert, Rognlie, Souchier y Straub aporta el
proceso de ingreso para hogares heterogeneos, aunque su pregunta principal es
monetaria. Esta clasificacion evita tomar todos los numeros de un solo trabajo
cuya estructura no coincide con el modelo.

## Corridas y diagnostico

La corrida base con parametros externos y sin recalibrar produjo T4 de 0.826,
T5 de 0.581 y Tkz de 0.726 en la grilla de cribado. Reducir la productividad
informal acerca T4 y T5. Cambiar solo la barrera no controla monotonicamente
Tkz porque la reasignacion de precios y riqueza domina el efecto parcial.

La corrida numericamente valida `mexico_2024_screen04` usa 12 nodos de
productividad. Produce T4 de 0.660, T5 de 0.361 y Tkz de 0.853, con exceso de
capital de 0.0015 y exceso del bien informal de 0.0022. Cierra los mercados,
pero falla los tres objetivos y sobrepredice el ratio salarial bruto, 1.924
frente a 1.437.

Una corrida posterior con carga de productividad informal de 0.90 produjo T4
de 0.551 y T5 de 0.268, cerca de los datos, pero Tkz permanecio en 0.837 y el
residuo de capital fue 0.442 en la grilla gruesa. No cuenta como calibracion.
Al repetir ese candidato con 24 nodos, las iteraciones alternaron entre masa
cero y masa elevada en el limite de activos. La verificacion se detuvo porque
la solucion no era estable. Aumentar nodos no corrige una identificacion debil.

La conclusion economica es concreta. La heterogeneidad unidimensional de
productividad, una barrera suave y una sola carga sectorial no bastan para
replicar conjuntamente informalidad agregada y sorting educativo en Mexico.
Una extension util necesita un margen extensivo de empleo o heterogeneidad
sectorial independiente, ambos presentes en los datos y en la literatura
mexicana.

## Reproduccion

```bash
python scripts/data/mexico/build_enoe_moments.py
```

```matlab
run('calibracion/setup_mexico_screen.m')
run('model_main.m')
run('calibracion/summarize_mexico_screens.m')
run('calibracion/validate_mexico_calibration.m')
```

La verificacion de 24 nodos se configura con
`calibracion/setup_mexico_nz24.m`. Su salida no debe citarse como equilibrio
hasta que cierre sin saltos en la masa de la restriccion de activos.

## Fuentes

INEGI ofrece la [ENOE](https://www.inegi.org.mx/programas/enoe/15ymas/) y la
[Medicion de la Economia Informal 2024](https://www.inegi.org.mx/contenidos/saladeprensa/boletines/2025/pibmed/MEI2024_CP.pdf).
Los parametros se contrastan con
[Leal Ordonez](https://www.banxico.org.mx/publications-and-press/banco-de-mexico-working-papers/%7B6EE7B434-BDC5-6393-4911-6122DED3E000%7D.pdf),
[Alvarez y Ruane](https://www.imf.org/en/Publications/WP/Issues/2019/11/27/Informality-and-Aggregate-Productivity-The-Case-of-Mexico-48754),
[Leyva y Urrutia](https://www.banxico.org.mx/publicaciones-y-prensa/documentos-de-investigacion-del-banco-de-mexico/%7BBD2BB2D4-6FE7-42BA-9E1C-C480DF6B91AC%7D.pdf)
y [Auclert, Rognlie, Souchier y Straub](https://www.nber.org/papers/w28872).
