# Inputs

No hay archivos `.mat` externos requeridos para replicar el paquete final.

La corrida canónica usada por el documento final ya está guardada en:

```text
outputs/stationary/test_AI098_cierre/results_test_AI098_cierre.mat
```

El archivo de referencia antiguo fue retirado porque correspondia a una corrida
con `Nz=7`, no a la grilla final `Nz=40`.

La corrida se regenera con `scripts/generar_paquete_final.m`, que fija el mismo
`RUN_TAG = 'test_AI098_cierre'`. Los resultados históricos con otra etiqueta no
deben usarse para actualizar las tablas del manuscrito o del anexo matemático.
