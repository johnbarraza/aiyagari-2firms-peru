# Replication package - HA-IE 2025

Este directorio contiene el codigo y los archivos necesarios para replicar el
modelo de agentes heterogeneos en tiempo continuo usado en el documento final:

**Informalidad y Distribucion de Riqueza: Un Modelo de Agentes Heterogeneos con Oferta Laboral Endogena**

El paquete esta preparado para MATLAB. No requiere codigo Python.

## Documento final

| Archivo | Contenido |
|---|---|
| `docs/IE2_ENTREGA_FINAL_CORREGIDA.md` | Fuente Markdown/LaTeX del documento final |
| `docs/IE2_ENTREGA_FINAL_CORREGIDA.pdf` | PDF final compilado |

## Codigo de replicacion

| Archivo | Uso |
|---|---|
| `model_main.m` | Solver principal del modelo |
| `generar_paquete_final.m` | Regenera figuras, resumen y zip de entrega desde `test_AI098_cierre` |
| `ploteo/plot_moll_matlab_all.m` | Genera figuras desde un `results_*.mat` |
| `calibracion/grid_convergence_test.m` | Reproduce la prueba de tradeoff velocidad-precision |
| `calibracion/setup_calibration.m` | Configura parametros base |

Los dos scripts principales se dejan en la raiz del paquete porque son los
puntos de entrada de la replicacion: `model_main.m` corre el modelo y
`generar_paquete_final.m` reconstruye las salidas finales.

La corrida final usada por el documento es:

```text
outputs/stationary/test_AI098_cierre/results_test_AI098_cierre.mat
```

## Instrucciones

Las instrucciones de ejecucion estan en:

```text
INSTRUCCIONES.md
```

## Estructura

```text
replication_package/
  README.md
  INSTRUCCIONES.md
  model_main.m
  generar_paquete_final.m
  .planning/
    CONTINUAR_AQUI.md
  calibracion/
  ploteo/
  inputs/
  outputs/
  docs/
```

## Requisitos

- MATLAB.
- `pdflatex` solo si se recompila el anexo matematico.
