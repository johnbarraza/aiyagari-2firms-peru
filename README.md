<p align="center">
  <img src="assets/banner.svg" alt="Informalidad y Distribución de Riqueza: un modelo de agentes heterogéneos con oferta laboral endógena" width="100%">
</p>

<p align="center">
  <a href="docs/INFORMALIDAD_RIQUEZA_HA_PERU.pdf"><img alt="Documento" src="https://img.shields.io/badge/Documento-PDF-0C2852?style=for-the-badge"></a>
  <a href="docs/anexo_matematico/anexo_matematico.pdf"><img alt="Anexo matemático" src="https://img.shields.io/badge/Anexo%20matem%C3%A1tico-PDF-0C2852?style=for-the-badge"></a>
  <a href="lean/"><img alt="Formalización en Lean" src="https://img.shields.io/badge/Lean%204-16%20teoremas-2DD4BF?style=for-the-badge"></a>
  <a href="lean/FINAL_VALIDATION_REPORT.md"><img alt="Reporte de validación" src="https://img.shields.io/badge/Reporte-validaci%C3%B3n-2DD4BF?style=for-the-badge"></a>
  <a href="lean/docs/VERIFICACION_NUMERICA.md"><img alt="Cruce numérico" src="https://img.shields.io/badge/Cruce-num%C3%A9rico-F59E0B?style=for-the-badge"></a>
  <a href="lean/FINAL_VALIDATION_REPORT.md"><img alt="Estado" src="https://img.shields.io/badge/Estado-formalizaci%C3%B3n%20parcial-F59E0B?style=for-the-badge"></a>
</p>

<p align="center">
  <img alt="MATLAB" src="https://img.shields.io/badge/MATLAB-R2025b-E16737">
  <img alt="Lean 4" src="https://img.shields.io/badge/Lean-4.30.0--rc2-2DD4BF">
  <img alt="Mathlib" src="https://img.shields.io/badge/Mathlib-v4.30.0--rc2-6D28D9">
  <img alt="LaTeX" src="https://img.shields.io/badge/LaTeX-pdflatex-008080">
</p>

# Informalidad y Distribución de Riqueza

**Un Modelo de Agentes Heterogéneos con Oferta Laboral Endógena**

John Svante Barraza Ratachi · Enzo Andrés Nevado Martínez
Asesor: César Saturnino Salinas Depaz · Investigación Económica II, ciclo 2026-I

> **Estado.** Trabajo académico de curso, **no arbitrado** y no publicado, sin DOI.
> Este repositorio es el paquete de replicación: solver MATLAB, documento, anexo
> matemático, y la verificación formal del modelo en Lean 4.

---

## La pregunta y el mecanismo único

Perú combina informalidad laboral alta —71.1 % de la PEA ocupada en 2023 según
INEI–ENAHO— con desigualdad de riqueza marcada. La pregunta es cuánto de esa
desigualdad se explica por la decisión **endógena** de los hogares de repartir sus
horas entre el sector formal y el informal. El objetivo es cuantificar el efecto
de la informalidad sobre la distribución de riqueza, no explicar sus causas
estructurales.

El mecanismo es uno solo: **acumulación baja para los hogares de baja
productividad**. Dos cuñas exógenas, ambas decrecientes en la productividad `z`,
inclinan la asignación de horas hacia el sector informal en la parte baja de la
distribución: una barrera de acceso formal `\kappa(z)` que descuenta el salario
formal por hora trabajada, y una prima de deuda `\chi(z)` que encarece el
endeudamiento. De ahí emerge el resultado: quien tiene `z` baja trabaja más
informal, gana menos por hora, ahorra menos, y llega más expuesto al siguiente
shock.

El modelo combina las dos tradiciones con que la literatura lee la informalidad
peruana. Del **estructuralismo** (CEPAL, PREALC, Pinto, Tokman) toma la
heterogeneidad de productividad entre sectores; del enfoque **institucional**
(De Soto 1986, Loayza 2016) toma `\kappa(z)` y `\chi(z)` como costos regulatorios
y de acceso.

## El problema del hogar

El hogar tiene riqueza `a` y productividad `z`, esta última un proceso de
Ornstein-Uhlenbeck calibrado a un AR(1) anual con datos peruanos. En cada instante
elige consumo formal e informal `(c_F, c_I)` y horas `(\ell_F, \ell_I)` sujeto a
`\ell_F + \ell_I \le \bar H`.

El consumo agregado es un compuesto CES,
`C = [\omega_C c_F^{\eta_C} + (1-\omega_C) c_I^{\eta_C}]^{1/\eta_C}`,
y la desutilidad del trabajo es isoelástica y separable por sector,
`\psi_F \ell_F^{1+1/\phi}/(1+1/\phi) + \psi_I \ell_I^{1+1/\phi}/(1+1/\phi)`.

La separabilidad es lo que permite resolver la oferta laboral en forma cerrada
dada la utilidad marginal de la riqueza. En el caso interior,
`\ell^{unc} = (\partial_a v \cdot w/\psi)^{\phi}` para cada sector. Cuando la
restricción de tiempo es vinculante, el reparto resuelve
`\psi_F \ell_F^{1/\phi} - \psi_I(\bar H - \ell_F)^{1/\phi} = \partial_a v (w_F^{net} - w_I^{eff})`.

La riqueza evoluciona según la restricción presupuestaria, con drift dado por
ingreso laboral neto de la barrera, ingreso informal, retorno de activos neto de
la prima de deuda, y transferencia fiscal, menos el gasto en consumo.

## El modelo: dos firmas, dos bienes

| Bloque | Contenido |
| --- | --- |
| **Firma formal** | Cobb-Douglas con retornos constantes, `Y_F = A_F K_F^{\alpha} L_F^{1-\alpha}`. Alquila capital al costo de uso `r+\delta` y paga el salario `w_F`. |
| **Firma informal** | `Y_I = A_I K_I^{\alpha_I} L_I^{\beta_I}` con `\alpha_I + \beta_I \le 1`. Su precio relativo `p_I` es endógeno; los beneficios se reparten en proporción a las horas informales. |
| **Gobierno** | Recauda `\tau w_F L_F` sobre la nómina formal y lo devuelve como transferencia de suma alzada. |

La distribución estacionaria resuelve la ecuación de Kolmogorov Forward. Los
precios `r` y `p_I` vacían el mercado de activos y el del bien informal.

## Verificación formal en Lean 4

El anexo matemático está formalizado en **Lean 4** con Mathlib, siguiendo el flujo
de formalización de papers de [EconCSLib](https://gargnikhil.com/EconCSLib/). El
proyecto está en [`lean/`](lean/).

### Resultado de un vistazo

| Ítem | Resultado |
| --- | --- |
| Afirmaciones derivables inventariadas en el anexo | 8 |
| Afirmaciones representadas en Lean | 8 / 8 |
| Teoremas adicionales sobre la extensión | 8 |
| Pruebas completas, sin `sorry` ni `admit` ni axiomas nuevos | 16 / 16 |
| Supuestos añadidos fuera del documento | 0 |
| Errores de fórmula detectados en la fuente | 6 |
| Revisiones humanas registradas | 0 / 8 pendientes |
| Estado general | **Formalización parcial** |

### Qué establece cada resultado

| Afirmación del anexo | Endpoint en Lean | Contenido verificado por máquina | Salvedad |
| --- | --- | --- | --- |
| Generador OU discretizado | `paper_ou_generator_rows_sum_zero` | las filas suman cero en nodos interiores y en ambos bordes reflectores | no cubre la existencia de la distribución ergódica |
| Prima de deuda | `paper_debt_premium_decreasing_in_productivity` | estrictamente decreciente en la productividad | probada sobre la forma impresa, que estaba desactualizada |
| Reparto CES óptimo | `paper_ces_optimal_demand_ratio` | tangencia con el precio relativo y factorización por el deflactor | solución interior; las esquinas no están formalizadas |
| Oferta laboral interior | `paper_interior_labor_first_order_condition` | la CPO, la optimalidad **global** sobre todas las horas no negativas, y la unicidad del punto estacionario interior | un sector a la vez, con `\partial_a v` dado |
| Caso vinculante KKT | `paper_binding_labor_kkt_monotone_and_corners` | monotonía estricta del residuo, valores exactos en ambos extremos, y las dos condiciones de esquina | no cubre la convergencia de la bisección numérica |
| Firma formal | `paper_formal_firm_first_order_conditions` | razón capital-trabajo cerrada y agotamiento del producto entre factores | retornos constantes, `p_F` normalizado a uno |
| Firma informal | `paper_informal_firm_profit_exhaustion` | beneficio residual, agotamiento de Euler bajo CRS, demanda estática de capital | requirió corregir un factor de precio ausente en la fuente |
| Vaciamiento del bien formal | `paper_walras_formal_goods_market` | la identidad de recursos y la caracterización exacta de cuándo coincide con la impresa | enunciado corregido; ver abajo |

### El hallazgo que cambió el enunciado del anexo

La condición de Walras impresa en el anexo **no se seguía** de las demás
condiciones del modelo. La forma que sí se deriva es

`Y_F = C_F + \delta K + \mathrm{Kappa} + \mathrm{DebtPrem}`, con `K = K_F + K_I`,

donde `Kappa` son los pagos agregados de la barrera de acceso y `DebtPrem` los de
la prima de deuda. La derivación necesita, todas ellas condiciones del propio
anexo: drift agregado nulo en estado estacionario, el presupuesto del gobierno
`T = \tau w_F L_F`, el agotamiento del producto formal
`Y_F = w_F L_F + (r+\delta)K_F`, el beneficio residual informal
`\Pi_I = p_I Y_I - w_I L_I - (r+\delta)K_I`, el vaciamiento del bien informal
`C_I = Y_I`, el vaciamiento de activos con capital **total** `K = K_F + K_I`, la
regla `hours` de reparto de beneficios, y la prima de deuda tratada como costo
real de intermediación y por tanto no devuelta.

La versión impresa, `C_F + \delta K_F + \mathrm{DebtPrem} = Y_F`, vale
**exactamente cuando** `\mathrm{Kappa} + \delta K_I = 0`. En la calibración de
cierre ninguno de los dos términos es nulo: evaluada sobre esa corrida, la
identidad impresa deja un residual de `1.10e-01` contra `4.71e-04` de la
corregida.

Las seis correcciones que la verificación encontró ya están aplicadas al anexo y
al solver. Ninguna cambia un número reportado: en todos los casos la
implementación ya usaba la versión correcta. Están listadas en las secciones 10 y
11 del [reporte de validación](lean/FINAL_VALIDATION_REPORT.md).

### Qué distingue esta extensión del Aiyagari clásico

Ocho teoremas adicionales, en `ExtensionResults.lean`, verifican lo que hace de
este modelo una extensión y no una variante:

- **Anidamiento del modelo clásico.** Apagar el sector informal colapsa el modelo
  al Aiyagari estándar con oferta laboral endógena, sin tomar límites.
- **Sorting monótono por productividad.** El atractivo relativo del sector formal
  `((1-\tau)w_F z - \kappa(z))/(\theta z^{\nu_I})` es estrictamente creciente en
  `z`. Es el mecanismo que disciplina el target `Tkz`, convertido en teorema. El
  numerador lleva el canal institucional y el denominador el estructuralista.
- **Margen intensivo sin salto de participación.** La política laboral es continua
  en `z`, y las horas formales son positivas si y solo si
  `\kappa(z) < (1-\tau)w_F z`.
- **Fidelidad del proceso de productividad y homoteticidad CES.** La difusión
  elegida devuelve exactamente la varianza estacionaria objetivo, el mapeo de la
  persistencia anual es exacto, y la composición de la canasta es idéntica para
  todos los agentes.

### Cómo está organizada la formalización

| Archivo o carpeta | Rol |
| --- | --- |
| `lean/PaperInterface.lean` | superficie de revisión humana: una proposición transparente por afirmación de la fuente |
| `lean/ProofInterface.lean` | puntos de prueba, con el tipo exacto de cada proposición |
| `lean/MainTheorems.lean` | implementación de las pruebas y lemas auxiliares genéricos |
| `lean/ExtensionResults.lean` | teoremas sobre la extensión, fuera de la superficie de revisión de la fuente |
| `lean/Assumptions.lean` | supuestos de la fuente no derivados en Lean; está **vacío** |
| `lean/FINAL_VALIDATION_REPORT.md` | veredicto humano, boundaries y correcciones a la fuente |
| `lean/SOURCE.md` | fijación de la fuente auditada por SHA-256 |
| `lean/audit/` | expedientes de auditoría, incluido el ledger de defectos |
| `lean/docs/VERIFICACION_NUMERICA.md` | cruce de los teoremas contra la corrida de cierre |

### Cómo interpretar "verificado"

Que un teorema esté probado en Lean significa que **la conclusión se sigue de las
hipótesis escritas en su enunciado**, y nada más. En particular:

- No significa que el modelo sea empíricamente correcto, ni que la calibración sea
  la adecuada.
- No significa que el equilibrio exista. La existencia y unicidad de la solución de
  la HJB, la existencia de la distribución estacionaria, y la existencia del punto
  fijo de precios **no están formalizadas**: se toman como dadas.
- La correspondencia entre el texto de la fuente y el enunciado en Lean fue hecha
  a mano y está documentada, pero las líneas de auditoría semántica asistidas por
  modelo del protocolo v11 **no se ejecutaron**. Por eso el estado es *formalización
  parcial* y no *formalizado*.
- Tres de las ocho filas usan un enunciado **corregido** respecto del impreso. Las
  correcciones están registradas con su obligación de reparación en
  `lean/audit/source_proof_fidelity.json`.

### Validación y orden de lectura recomendado

| Paso de validación | Resultado registrado |
| --- | --- |
| `lake build` del paquete completo | correcto, 8319 objetivos |
| Barrido de `sorry`, `admit` y axiomas nuevos | limpio |
| Verificación con alcance de paper en EconCSLib, modo rápido | correcto |
| Cruce numérico contra la corrida de cierre | errores entre `1e-15` y `1e-4`; ver `lean/docs/VERIFICACION_NUMERICA.md` |

Para leerlo: empezar por el [reporte de validación](lean/FINAL_VALIDATION_REPORT.md),
secciones 1 a 5; luego `lean/PaperInterface.lean`, que es la superficie pensada
para revisión humana; y finalmente
[`lean/docs/VERIFICACION_NUMERICA.md`](lean/docs/VERIFICACION_NUMERICA.md) para el
contraste con la corrida real.

## Qué no se sostiene

### El equilibrio no está formalizado

Todo lo verificado es optimalidad estática y contabilidad agregada. Que exista un
vector de precios que vacíe simultáneamente los mercados, que la HJB tenga
solución única, y que la distribución invariante exista, se asumen.

### El gradiente por quintil de riqueza queda muy corto

El modelo produce `T6 = 4.4 %` contra un dato de `53 %`. El trabajo lo atribuye a
la ausencia del margen extensivo, y la formalización refina ese diagnóstico: el
teorema de sorting es **condicional a la utilidad marginal de la riqueza**, o sea
aísla el canal de productividad. El gradiente por riqueza no se sigue de él.

Hay además una contribución de segundo orden en la misma dirección: la grilla de
productividad entrega `sd(log z) = 0.5281` contra el objetivo calibrado de
`0.5440`, un 2.9 % menos. El sesgo lo controla el ancho de la grilla y **no** el
número de nodos, de modo que refinar `Nz` lo empeora. El análisis y tres opciones
cuantificadas están en la sección 4 del
[cruce numérico](lean/docs/VERIFICACION_NUMERICA.md).

### La corrida de cierre no se reproduce con los valores por defecto

`model_main` con sus defaults **no** reproduce la corrida que reporta el
documento: converge en silencio a otro equilibrio, sin mensaje de error. Faltan
`HA_IE_RHO=0.073`, que no queda registrado en el metadata de la corrida, y un
bracket de bisección ampliado, porque el `r*` reportado cae fuera del rango por
defecto. El script de reproducción fija las variables necesarias.

## Calibración y datos

Los parámetros externos vienen de literatura peruana y están documentados en el
trabajo: el proceso de productividad de Hong (2022) sobre ENAHO, la tecnología
formal de Céspedes, Aquije, Sánchez y Vera-Tudela (2014, BCRP), la informal de
Göbel, Grimm y Lay (2013, BCRP), y la depreciación de Castillo y Rojas (BCRP).
Los targets de informalidad y gasto salen de ENAHO e INEI.

Cuatro parámetros se calibran internamente —`\psi_F`, `\psi_I`, `A_I`,
`\kappa_{z1}`— contra tres targets: participación de horas informales, PBI
informal nominal, y gap de formalidad por productividad.

## Reproducir

```matlab
run('lean/scripts/matlab/reproducir_cierre.m')
```

El script localiza la raíz del paquete relativa a sí mismo, fija las 24 variables
de entorno necesarias y llama a `model_main`. Tarda unos 33 minutos y necesita del
orden de 10 GB de RAM libres. Los resultados quedan en
`outputs/stationary/<RUN_TAG>/`. Los ejercicios de robustez y las variables
`HA_IE_*` están en [`INSTRUCCIONES.md`](INSTRUCCIONES.md).

Para verificar la formalización, con Lean y Mathlib instalados:

```bash
cd lean && lake build && bash scripts/check.sh
```

## Mapa del repositorio

```text
.
├── README.md
├── INSTRUCCIONES.md                      instrucciones de replicación
├── model_main.m                          solver principal, único punto de entrada
├── assets/                               banner
├── calibracion/                          convergencia de grilla y helpers
├── ploteo/                               figuras desde results_*.mat
├── inputs/                               insumos de calibración
├── outputs/stationary/                   corridas guardadas, incluida la de cierre
├── scripts/                              empaquetador de la corrida final
├── docs/
│   ├── INFORMALIDAD_RIQUEZA_HA_PERU.pdf  documento final
│   ├── anexo_matematico/                 derivación formal completa (.tex y .pdf)
│   ├── referencias/                      papers de referencia
│   └── images/
└── lean/                                 verificación formal en Lean 4
    ├── PaperInterface.lean               superficie de revisión humana
    ├── ProofInterface.lean               puntos de prueba
    ├── MainTheorems.lean                 implementación de las pruebas
    ├── ExtensionResults.lean             teoremas sobre la extensión
    ├── Assumptions.lean                  supuestos no derivados (vacío)
    ├── FINAL_VALIDATION_REPORT.md        veredicto y correcciones a la fuente
    ├── SOURCE.md                         fuente auditada, fijada por SHA-256
    ├── audit/                            expedientes de auditoría
    ├── docs/                             cruce numérico, plan, DAG, handoff
    └── scripts/matlab/                   verificación y reproducción
```

## Cómo citar

```bibtex
@misc{barraza_nevado_2026_informalidad,
  author = {Barraza Ratachi, John Svante and Nevado Martínez, Enzo Andrés},
  title  = {Informalidad y Distribución de Riqueza: Un Modelo de Agentes
            Heterogéneos con Oferta Laboral Endógena},
  year   = {2026},
  note   = {Investigación Económica II. Trabajo académico no arbitrado.
            Paquete de replicación y verificación formal en Lean 4},
  url    = {https://github.com/johnbarraza/aiyagari-2firms-peru}
}
```

## Licencia

La formalización en Lean bajo [`lean/`](lean/) se distribuye con la licencia
Apache-2.0 que acompaña al flujo de EconCSLib ([`lean/LICENSE`](lean/LICENSE)).
El resto del repositorio —código MATLAB, documento y anexo— **no tiene licencia
declarada todavía**; hasta que se elija una, se reservan todos los derechos.
