# Instrucciones de replicacion

Estas instrucciones ejecutan el paquete desde MATLAB. Todo el flujo esta dentro
de este directorio `replication_package`.

## 1. Ubicarse en el paquete

```matlab
cd('C:\Users\"user"\Documents\GitHub\HA-IE2025\Code\CONTINUOUS_TIME\Aiyagari_firmas\try_endog_labor_2_firms\replication_package')
```

## 2. Correr el modelo desde cero

El script principal contiene los parametros calibrados finales del documento:
`Nz=40`, regla de beneficios `hours`, utilidad logaritmica (`gamma=1`),
`rho=0.073`, y un bracket de bisection de `r` que contiene el `r*=0.066`
reportado.

```matlab
model_main
```

Eso corre la especificacion base en **grilla de produccion**, `I=500`. La
corrida de cierre que reporta el documento uso la grilla rapida, `I=200`, de
modo que para reproducir sus numeros exactos hay que activarla:

```matlab
setenv('HA_IE_FAST_DEBUG','true');
model_main
```

o, mas simple, usar el script que fija todo el entorno de esa corrida:

```matlab
run('lean/scripts/matlab/reproducir_cierre.m')
```

> **Nota historica.** Hasta septiembre de 2026 los defaults del script eran
> `gamma=2`, `rho=0.05` y un bracket `r` maximo de `0.0499`, y `model_main` no
> reproducia la corrida de cierre. Lo grave era silencioso: con `gamma=2` y
> `rho=0.05` el modelo converge a otro equilibrio sin avisar, y la corrida final
> sobreescribia ambos por variables de entorno que el metadata no registraba. El
> bracket, en cambio, avisaba: con la calibracion correcta el `r*` reportado cae
> fuera de el y el chequeo de signos del solver aborta con `invalid bracket in
> r`. Los defaults ya se corrigieron y el metadata registra ahora los parametros
> de preferencias y el bracket.

Los resultados nuevos quedan en `outputs/stationary/<RUN_TAG>/`. Si no se fija
un `RUN_TAG`, MATLAB crea una carpeta con timestamp para no sobreescribir la
corrida final guardada.

Las variables `HA_IE_*` se mantienen solo para ejercicios de robustez, por
ejemplo cambiar `I`, `Nz`, tolerancias o el nombre de la corrida.

## 3. Regenerar figuras

Desde cualquier archivo `results_*.mat`:

```matlab
addpath('ploteo')
TAG = getenv('HA_IE_RUN_TAG');
MAT = sprintf('outputs/stationary/%s/results_%s.mat', TAG, TAG);
OUT = sprintf('outputs/stationary/%s/plots_matlab', TAG);

plot_moll_matlab_all(MAT, OUT)
```

Para regenerar el paquete final desde la corrida final guardada:

```matlab
run('scripts/generar_paquete_final.m')
```

Esto crea:

```text
outputs/stationary/test_AI098_cierre/plots_matlab/
outputs/stationary/test_AI098_cierre/resumen_calibracion.txt
outputs/stationary/test_AI098_cierre/paquete_final.zip
```

## 4. Tradeoff velocidad-precision

La grilla final del paper es `Nz=40`. Las grillas `Nz=7`, `Nz=14`, `Nz=24` y
`Nz=30` se usaron solo para medir el tradeoff velocidad-precision contra la
referencia `Nz=40, I=500`.

| Grilla | I | Tiempo aprox. | Uso |
|---|---:|---:|---|
| Nz=7 | 200 | 10.7 min | comparacion del tradeoff |
| Nz=14 | 200 | 18.2 min | comparacion del tradeoff |
| Nz=24 | 200 | 44.2 min | comparacion del tradeoff |
| Nz=30 | 200 | 40.7 min | comparacion del tradeoff |
| Nz=40 | 200 | 30.3 min | comparacion rapida |
| Nz=40 | 500 | 670.7 min | referencia de produccion |

Para regenerar solo las figuras desde resultados guardados:

```matlab
addpath('calibracion')
grid_convergence_test('plot')
```

Para correr nuevamente toda la prueba:

```matlab
addpath('calibracion')
grid_convergence_test
```

Las salidas quedan en:

```text
outputs/grid_convergence/
```

## 4bis. Ancho de la grilla de productividad

Achdou et al. (2022) especifican el proceso de productividad como un
Ornstein-Uhlenbeck, analogo en tiempo continuo de un AR(1), *"with comparable
persistence and standard deviation"*. La persistencia calza de forma exacta por
construccion, via `eta = -log(rho_z)/dt`. La desviacion estandar no: el apendice
numerico de HACT impone barreras reflectoras en los bordes de la grilla, y sobre
un soporte truncado la distribucion ergodica tiene menos dispersion que el
objetivo.

Con `width_z_ar = 2.5` y `Nz = 40`, la grilla entrega `sd(log z) = 0.5281`
frente al objetivo `0.5440`, un 2.9 % por debajo. **El sesgo lo controla el
ancho, no el numero de nodos**: a ancho fijo, subir `Nz` lo empeora, porque el
limite lo fija el truncamiento y no la resolucion. El solver ahora avisa cuando
el desvio supera el 2 %.

Para que la desviacion estandar calce igual que la persistencia:

```matlab
setenv('HA_IE_Z_WIDTH','auto');
```

Resuelve por biseccion el ancho tal que la `sd(log z)` ergodica iguale el
objetivo. Anchos que produce, todos con `100.00 %` del objetivo:

| Nz | 7 | 14 | 20 | 30 | 40 | 60 | 80 |
|---|---|---|---|---|---|---|---|
| ancho | 2.169 | 2.457 | 2.594 | 2.734 | **2.827** | 2.951 | 3.037 |

Cambiar el ancho mueve la dispersion efectiva de `z` y por lo tanto **exige
recalibrar** `psi_F`, `psi_I`, `A_I` y `kappa_z1`, que estan ajustados a T4, T5 y
Tkz bajo la dispersion actual. Por eso `auto` no es el default: es un ejercicio
de robustez, no un parche silencioso.

## 5. Recompilar los documentos

El documento final se genera desde su fuente Markdown con pandoc y xelatex. El
`--resource-path` es necesario porque el documento mezcla rutas relativas a la
raiz (la portada) con rutas relativas a `docs/` (las figuras):

```powershell
pandoc docs/INFORMALIDAD_RIQUEZA_HA_PERU.md `
  -o docs/INFORMALIDAD_RIQUEZA_HA_PERU.pdf `
  --pdf-engine=xelatex `
  --resource-path=".;docs;docs/images"
```

El anexo matematico es LaTeX autocontenido, dos pasadas por el indice:

```powershell
cd docs/anexo_matematico
pdflatex -interaction=nonstopmode anexo_matematico.tex
pdflatex -interaction=nonstopmode anexo_matematico.tex
```

## 5. Inputs y corrida guardada

No hay `.mat` externo requerido en `inputs/`. La corrida final ya esta en:

```text
outputs/stationary/test_AI098_cierre/results_test_AI098_cierre.mat
```
