# Replication package - HA-IE 2025

Este directorio contiene el codigo y los archivos necesarios para replicar el
modelo de agentes heterogeneos en tiempo continuo usado en el documento final:

**Informalidad y Distribucion de Riqueza: Un Modelo de Agentes Heterogeneos con Oferta Laboral Endogena**

Repositorio de replicacion:
https://github.com/johnbarraza/aiyagari-2firms-peru

Link del documento
https://github.com/johnbarraza/aiyagari-2firms-peru/blob/codex/organize-replication-package/docs/INFORMALIDAD_RIQUEZA_HA_PERU.pdf 

## Documento final

| Archivo | Contenido |
|---|---|
| `docs/INFORMALIDAD_RIQUEZA_HA_PERU.md` | Fuente Markdown/LaTeX del documento final |
| `docs/INFORMALIDAD_RIQUEZA_HA_PERU.pdf` | PDF final compilado |

## Codigo de replicacion

| Archivo | Uso |
|---|---|
| `model_main.m` | Solver principal. Corre el modelo con los valores finales por defecto |

| `ploteo/plot_moll_matlab_all.m` | Genera figuras desde un `results_*.mat` |
| `calibracion/grid_convergence_test.m` | Reproduce la prueba de tradeoff velocidad-precision |
| `calibracion/setup_calibration.m` | Helper opcional para fijar explicitamente los mismos parametros finales |

El unico punto de entrada en la raiz para replicar el modelo es `model_main.m`.

Para replicar desde cero, correr:

```matlab
model_main
```

No es necesario usar `setenv` para la especificacion base: `model_main.m` ya
incluye los valores finales usados en la corrida de cierre (`Nz=40`, regla
`hours`, y parametros calibrados finales). Las variables de entorno quedan solo
para ejercicios de robustez o para ajustes rápidos.

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
  scripts/
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
