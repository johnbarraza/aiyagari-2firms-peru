![Informalidad y Distribución de Riqueza](assets/banner.svg)

[![Documento final](https://img.shields.io/badge/documento-PDF-1f6feb)](docs/INFORMALIDAD_RIQUEZA_HA_PERU.pdf)
[![Anexo matemático](https://img.shields.io/badge/anexo%20matem%C3%A1tico-PDF-1f6feb)](docs/anexo_matematico/anexo_matematico.pdf)
[![Fuente LaTeX](https://img.shields.io/badge/fuente-LaTeX-008080)](docs/anexo_matematico/anexo_matematico.tex)
[![Verificación Lean 4](https://img.shields.io/badge/Lean%204-16%20teoremas%20probados-2dd4bf)](lean/)
[![Reporte de validación](https://img.shields.io/badge/reporte-validaci%C3%B3n-2dd4bf)](lean/FINAL_VALIDATION_REPORT.md)
[![Verificación numérica](https://img.shields.io/badge/cruce-num%C3%A9rico-f59e0b)](lean/docs/VERIFICACION_NUMERICA.md)
[![Estado](https://img.shields.io/badge/estado-formalizaci%C3%B3n%20parcial-f59e0b)](lean/FINAL_VALIDATION_REPORT.md)

![MATLAB](https://img.shields.io/badge/MATLAB-R2025b-e16737)
![Lean 4](https://img.shields.io/badge/Lean-4.30.0--rc2-2dd4bf)
![Mathlib](https://img.shields.io/badge/Mathlib-v4.30.0--rc2-6d28d9)
![LaTeX](https://img.shields.io/badge/LaTeX-pdflatex-008080)

# Informalidad y Distribución de Riqueza

**Un Modelo de Agentes Heterogéneos con Oferta Laboral Endógena**

John Svante Barraza Ratachi · Enzo Andrés Nevado Martínez
Asesor: César Saturnino Salinas Depaz · Investigación Económica II, ciclo 2026-I

> **Estado.** Trabajo académico de curso, **no arbitrado** y no publicado. No
> tiene DOI. Este repositorio es el paquete de replicación: código, datos de
> calibración, documento y la verificación formal del modelo en Lean 4.

---

## La pregunta

La economía peruana combina informalidad laboral alta (71.1 % de la PEA ocupada
en 2023, INEI–ENAHO) con desigualdad de riqueza marcada. La pregunta es cuánto de
esa desigualdad se explica por la decisión **endógena** de los hogares de repartir
sus horas entre el sector formal y el informal.

El objetivo es cuantificar el efecto de la informalidad sobre la distribución de
riqueza, no explicar sus causas estructurales.

## El mecanismo

Uno solo: **acumulación baja para los hogares de baja productividad.**

Los hogares eligen horas formales `ℓ_F` e informales `ℓ_I` sujetos a
`ℓ_F + ℓ_I ≤ H̄`. Dos cuñas exógenas, ambas decrecientes en la productividad `z`,
inclinan esa decisión:

- una **barrera de acceso formal** `κ(z)`, que descuenta el salario formal por
  hora trabajada;
- una **prima de deuda** `χ(z)`, que encarece el endeudamiento.

De ahí sale el resultado endógeno: los hogares de baja `z` trabajan más informal,
ganan menos por hora, ahorran menos, y quedan más expuestos al siguiente shock.
La informalidad no es un atributo fijo del hogar sino el resultado de esa
asignación óptima.

El repositorio combina las dos tradiciones que la literatura usa para leer la
informalidad peruana: del **estructuralismo** (CEPAL, PREALC, Pinto, Tokman) toma
la heterogeneidad de productividad entre sectores; del enfoque **institucional**
(De Soto, Loayza) toma `κ(z)` y `χ(z)` como costos regulatorios y de acceso.

## Estructura del modelo

Tres bloques, en tiempo continuo, siguiendo el marco HACT de Achdou et al. (2022):

| Bloque | Contenido |
| --- | --- |
| **Hogares** | Riqueza `a` y productividad `z` (Ornstein-Uhlenbeck). Consumo CES entre bien formal e informal. Desutilidad isoelástica separable por sector. Ecuación de Hamilton-Jacobi-Bellman. |
| **Dos firmas** | Formal Cobb-Douglas con retornos constantes; informal con retornos no crecientes y precio relativo `p_I` endógeno. |
| **Gobierno** | Impuesto a la nómina formal, devuelto como transferencia de suma alzada. |

La distribución estacionaria resuelve la ecuación de Kolmogorov Forward, y los
precios `r` y `p_I` vacían el mercado de activos y el del bien informal.

## Qué está verificado formalmente

El anexo matemático está formalizado en **Lean 4** con Mathlib usando el flujo de
[EconCSLib](https://gargnikhil.com/EconCSLib/). **16 teoremas probados, sin
`sorry`, `admit` ni axiomas nuevos.** El proyecto está en [`lean/`](lean/).

Ocho corresponden a afirmaciones del anexo:

| Afirmación del anexo | Qué queda probado |
| --- | --- |
| Generador OU discretizado | las filas suman cero, en nodos interiores y en ambos bordes reflectores |
| Prima de deuda | estrictamente decreciente en la productividad |
| Reparto CES óptimo | el ratio de demanda satisface la tangencia con el precio relativo |
| Oferta laboral interior | la CPO isoelástica, y que es el óptimo **global**, no solo estacionario |
| Caso vinculante KKT | monotonía estricta del residuo, valores en los extremos, ambas esquinas |
| Firma formal | razón capital-trabajo cerrada y agotamiento del producto |
| Firma informal | beneficio residual, agotamiento de Euler, demanda de capital |
| Vaciamiento del bien formal | la identidad de Walras (ver abajo) |

Y ocho caracterizan la extensión frente al Aiyagari clásico de una firma:
anidamiento del modelo clásico como caso particular, sorting monótono por
productividad, ausencia de margen extensivo con su umbral exacto de exclusión,
tres de fidelidad del proceso de productividad, y dos de homoteticidad CES.

**Lo que no está formalizado:** la existencia y unicidad de la solución de la
HJB, la existencia de la distribución estacionaria, y la existencia del punto fijo
de precios. Se toman como dadas. Por eso el estado es *formalización parcial* y no
*formalizado*. El detalle está en el
[reporte de validación](lean/FINAL_VALIDATION_REPORT.md), secciones 5 y 11.

## La identidad de vaciamiento, en su forma corregida

La verificación encontró que la condición de Walras impresa en el anexo no se
seguía de las demás condiciones del modelo. La forma correcta es

$$Y_F = C_F + \delta K + \mathrm{Kappa} + \mathrm{DebtPrem}, \qquad K = K_F + K_I$$

donde `Kappa` son los pagos agregados de la barrera de acceso y `DebtPrem` los de
la prima de deuda. Se obtiene agregando la restricción presupuestaria del hogar
bajo la distribución estacionaria, y requiere:

- **drift agregado nulo** en el estado estacionario;
- el presupuesto del gobierno `T = τ w_F L_F`;
- el agotamiento del producto formal `Y_F = w_F L_F + (r+δ) K_F`;
- el beneficio residual informal `Π_I = p_I Y_I − w_I L_I − (r+δ) K_I`;
- el vaciamiento del bien informal `C_I = Y_I`;
- el vaciamiento de activos con **capital total** `K = K_F + K_I`;
- la regla `hours` de reparto de beneficios informales;
- prima de deuda **no devuelta**, es decir tratada como costo real de
  intermediación.

La versión impresa originalmente, `C_F + δK_F + DebtPrem = Y_F`, vale
**exactamente cuando** `Kappa + δ K_I = 0`. En la calibración de cierre ninguno de
los dos términos es nulo: evaluada sobre esa corrida, la identidad impresa deja un
residual de `1.10e-01` contra `4.71e-04` de la corregida. Ambas correcciones ya
están aplicadas al anexo y al solver.

Las derivaciones completas están en el
[anexo matemático](docs/anexo_matematico/anexo_matematico.pdf); el cruce numérico
contra la corrida de cierre, en
[`lean/docs/VERIFICACION_NUMERICA.md`](lean/docs/VERIFICACION_NUMERICA.md).

## Replicación

> **Importante.** `model_main` con sus valores por defecto **no** reproduce la
> corrida de cierre que reporta el documento: converge en silencio a otro
> equilibrio. Hacen falta `HA_IE_RHO=0.073` y un bracket de bisección ampliado.
> El script de reproducción fija las 24 variables necesarias.

```matlab
cd('<ruta al repositorio>')
run('lean/scripts/matlab/reproducir_cierre.m')
```

La corrida tarda ~33 min y necesita ~10 GB de RAM libres. Los resultados quedan en
`outputs/stationary/<RUN_TAG>/`. Instrucciones completas y ejercicios de robustez
en [`INSTRUCCIONES.md`](INSTRUCCIONES.md).

Para verificar la formalización, con Lean y Mathlib instalados:

```bash
cd lean && lake build && bash scripts/check.sh
```

## Estructura del repositorio

```text
.
├── README.md
├── INSTRUCCIONES.md                      instrucciones de replicación
├── model_main.m                          solver principal, único punto de entrada
├── assets/banner.svg
├── calibracion/                          grid convergence y helpers de calibración
├── ploteo/                               generación de figuras desde results_*.mat
├── inputs/                               insumos de calibración
├── outputs/stationary/                   corridas guardadas, incluida la de cierre
├── scripts/                              empaquetador de la corrida final
├── docs/
│   ├── INFORMALIDAD_RIQUEZA_HA_PERU.pdf  documento final
│   ├── anexo_matematico/                 derivación formal completa (.tex y .pdf)
│   ├── referencias/                      papers de referencia
│   └── images/
└── lean/                                 verificación formal en Lean 4
    ├── PaperInterface.lean               superficie de revisión: una proposición por afirmación
    ├── ProofInterface.lean               puntos de prueba con el tipo exacto de cada proposición
    ├── MainTheorems.lean                 implementación de las pruebas
    ├── ExtensionResults.lean             teoremas sobre la extensión
    ├── Assumptions.lean                  supuestos no derivados (vacío)
    ├── FINAL_VALIDATION_REPORT.md        veredicto y correcciones a la fuente
    ├── SOURCE.md                         fijación de la fuente auditada por SHA-256
    ├── audit/                            expedientes de auditoría
    ├── docs/VERIFICACION_NUMERICA.md     cruce de los teoremas contra la corrida
    └── scripts/matlab/                   scripts de verificación y reproducción
```

## Licencia

La formalización en Lean bajo [`lean/`](lean/) se distribuye con la licencia
Apache-2.0 que acompaña al flujo de EconCSLib
([`lean/LICENSE`](lean/LICENSE)). El resto del repositorio —código MATLAB,
documento y anexo— **no tiene licencia declarada todavía**; hasta que se elija
una, se reservan todos los derechos.
