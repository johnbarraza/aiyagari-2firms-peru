# Revision de convergencia de la grilla Nz

Este archivo resume la evidencia numerica usada para revisar el tradeoff entre
velocidad y precision de la grilla de productividad. No forma parte del paper
principal; queda como nota de revision del paquete de replicacion.

Fuente principal:

```text
outputs/grid_convergence/grid_convergence_table.csv
calibracion/grid_convergence_test.m
```

No se encontro una corrida `Nz=28` en el paquete. La prueba guardada usa
`Nz = 7, 14, 24, 30, 40` con `I = 200`, y compara contra la referencia
`Nz = 40, I = 500`.

## Tabla principal

El error porcentual se calcula contra la referencia de produccion
`Nz = 40, I = 500`. El "error maximo" toma el mayor valor absoluto entre los
errores de T4, T5, Tkz y r*.

| Configuracion | Tiempo | T4 | T5 | Tkz | r* | Error maximo | Lectura |
|---|---:|---:|---:|---:|---:|---:|---|
| Nz = 7, I = 200 | 10.66 min | +0.583% | -1.191% | +5.225% | -1.566% | 5.225% | Rapida, pero imprecisa en Tkz |
| Nz = 14, I = 200 | 18.15 min | +0.187% | -0.505% | +1.635% | -0.722% | 1.635% | Diagnostico intermedio |
| Nz = 24, I = 200 | 44.23 min | +0.052% | -0.212% | +0.387% | -0.350% | 0.387% | Buena aproximacion puntual |
| Nz = 30, I = 200 | 40.74 min | +0.019% | -0.136% | +0.081% | -0.254% | 0.254% | Bajo error puntual, pero no seleccionado por estabilidad |
| Nz = 40, I = 200 | 30.32 min | +0.625% | +0.160% | +1.765% | -0.114% | 1.765% | Grilla base rapida del paquete |
| Nz = 40, I = 500 | 670.68 min | 0.000% | 0.000% | 0.000% | 0.000% | 0.000% | Referencia de produccion |

## Nota sobre Nz = 30

No conviene describir `Nz = 30` como punto optimo. En la tabla de convergencia
su error porcentual puntual es bajo, pero la revision posterior de estabilidad
mostro que era menos robusto que `Nz = 40`:

| Metricas de estabilidad post-correccion | Nz = 40 | Nz = 30 |
|---|---:|---:|
| Fallback points | 23 | 193 |
| zero_drift_max_resid | 1.16e-03 | 5.40e-01 |
| Tiempo FAST_DEBUG | 75.8 min | 64.7 min |

La diferencia de tiempo entre `Nz = 30` y `Nz = 40` no compensa la perdida de
estabilidad numerica. Por eso la especificacion documentada mantiene `Nz = 40`
como grilla base.

## Conclusion operativa

- Para diagnosticos muy rapidos, `Nz = 7` o `Nz = 14` sirven solo como pruebas
  preliminares.
- Para revisar convergencia, usar la tabla completa y no interpretar el menor
  error puntual como criterio unico.
- Para el paquete final y las corridas reportables, mantener `Nz = 40`.
- La referencia de produccion sigue siendo `Nz = 40, I = 500`, aunque su costo
  computacional es alto: 670.68 minutos.
