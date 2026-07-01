# Replication package - HA-IE 2025

Este directorio contiene el codigo y los archivos necesarios para replicar el
modelo de agentes heterogeneos en tiempo continuo usado en el documento final:

**Informalidad y Distribucion de Riqueza: Un Modelo de Agentes Heterogeneos con Oferta Laboral Endogena**

Repositorio de replicacion:
https://github.com/johnbarraza/aiyagari-2firms-peru

## Documento final

| Archivo | Contenido |
|---|---|
| `docs/IE2_ENTREGA_FINAL_CORREGIDA.md` | Fuente Markdown/LaTeX del documento final |
| `docs/IE2_ENTREGA_FINAL_CORREGIDA.pdf` | PDF final compilado |

## Codigo de replicacion

| Archivo | Uso |
|---|---|
| `model_main.m` | Solver principal. Corre el modelo con los valores finales por defecto |
| `generar_paquete_final.m` | Script de empaquetado. No resuelve el modelo; regenera figuras, resumen y zip desde la corrida final guardada |
| `ploteo/plot_moll_matlab_all.m` | Genera figuras desde un `results_*.mat` |
| `calibracion/grid_convergence_test.m` | Reproduce la prueba de tradeoff velocidad-precision |
| `calibracion/setup_calibration.m` | Helper opcional para fijar explicitamente los mismos parametros finales |

Hay dos scripts en la raiz porque cumplen funciones distintas:
`model_main.m` es el codigo economico-computacional que calcula el equilibrio;
`generar_paquete_final.m` solo toma resultados ya guardados y reconstruye las
figuras, el resumen y el zip de entrega.

Para replicar desde cero, correr:

```matlab
model_main
```

No es necesario usar `setenv` para la especificacion base: `model_main.m` ya
incluye los valores finales usados en la corrida de cierre (`Nz=40`, regla
`hours`, y parametros calibrados finales). Las variables de entorno quedan solo
para ejercicios de robustez.

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
