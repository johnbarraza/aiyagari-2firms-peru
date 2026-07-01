# Instrucciones de replicacion

Estas instrucciones ejecutan el paquete desde MATLAB. Todo el flujo esta dentro
de este directorio `replication_package`.

## 1. Ubicarse en el paquete

```matlab
cd('C:\Users\johnb\Documents\GitHub\HA-IE2025\Code\CONTINUOUS_TIME\Aiyagari_firmas\try_endog_labor_2_firms\replication_package')
```

## 2. Correr el modelo desde cero

El script principal ya contiene los valores finales de la especificacion base
del documento: `Nz=40`, regla de beneficios `hours`, grilla de riqueza
`I=200` y parametros calibrados finales. No se necesita definir variables de
entorno para replicar la corrida base.

```matlab
model_main
```

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
generar_paquete_final
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

## 5. Inputs y corrida guardada

No hay `.mat` externo requerido en `inputs/`. La corrida final ya esta en:

```text
outputs/stationary/test_AI098_cierre/results_test_AI098_cierre.mat
```
