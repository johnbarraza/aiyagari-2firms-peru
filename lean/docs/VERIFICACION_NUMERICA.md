# Verificación numérica: los teoremas contra la corrida de cierre

Los teoremas de este repositorio se probaron en Lean sobre el anexo matemático.
Este documento los cruza contra la corrida de cierre real del paquete de
replicación, `outputs/stationary/test_AI098_cierre/results_test_AI098_cierre.mat`,
usando MATLAB R2025b. Los scripts están en `scripts/matlab/`.

El objetivo es doble: confirmar que lo probado en Lean se cumple en el equilibrio
computado, y usar los teoremas como diagnóstico para encontrar cosas que la
inspección directa del código no revela.

---

## 1. Los teoremas se cumplen en el equilibrio computado

| Teorema | Predicho | En la corrida | Diferencia |
| --- | --- | --- | --- |
| `ces_basket_ratio_is_agent_independent` | 2.477906 | `TgFI_canasta` = 2.477906 | `2.2e-15` |
| `formal_firm_first_order_conditions` (w_F) | 2.250628 | `w_F_star` = 2.250628 | `0` |
| `ou_generator_rows_sum_zero` | 0 | `max|fila de Q_z|` | `1.8e-15` |
| `ou_mean_reversion_reproduces_ar1_persistence` | `ρ_z` = 0.861000 | `exp(−η·dt)` = 0.861000 | `0` |
| `lognormal_mean_normalization_is_necessary` | `E[z]` = 1 tras normalizar | 1.000000 | `0` |
| `informal_firm_profit_exhaustion` (Π_I) | 0.050958 | `profit_I_star` = 0.050838 | `1.2e-04` |

`productivity_sorting_monotone` también se confirma, y de forma más fuerte que lo
probado. El teorema da monotonía **condicional al multiplicador de riqueza**; la
corrida muestra la participación formal integrada sobre toda la distribución de
riqueza, y es estrictamente creciente en los 40 nodos:

```
z_min                                                              z_max
0.1813 0.2609 0.3016 0.3296 0.3510 ... 0.5430 0.5462 0.5494 0.5526 0.5588
```

`intensive_margin_no_participation_jump` predice que las horas formales son
positivas si y solo si `κ(z) < (1−τ)w_F z`. En la corrida ningún nodo está
excluido, pero el margen en el nodo más bajo es estrecho:

| | `z_min` | `z_max` |
| --- | --- | --- |
| `κ_z(z)` | 0.4000 | 0.0000 |
| `(1−τ)·w_F·z` | 0.4124 | 6.2609 |
| holgura | **3.0 %** | — |

Es decir, en el tipo de productividad más baja la cuña formal se come el 97 % del
salario formal bruto. Un `κ_z1` apenas mayor que 0.4124 excluiría por completo a
ese tipo del sector formal, que es exactamente la esquina que identifica el
teorema. Vale como ejercicio de robustez: la calibración está justo en el borde.

**Sobre la diferencia de `1.2e-04` en Π_I.** No es un error de fórmula: es el
punto fijo amortiguado del beneficio informal (`damp_piI = 0.10`) deteniéndose
antes de converger del todo. El gap es 0.24 % del nivel. Bajar la tolerancia o
subir el número de iteraciones lo cierra.

---

## 2. El residual de Walras del bien formal

El teorema `walras_formal_goods_market` da la identidad correcta:

```
Y_F = C_F + δ·K + KappaCost + DebtPremPayments,     K = K_F + K_I
```

Evaluada en la corrida de cierre:

| Componente | Valor |
| --- | --- |
| `Y_F` | 1.36744243 |
| `C_F_agg` | 0.78406840 |
| `δ·K` | 0.51383895 (δ = 0.10, K = 5.138390 = 4.719016 + 0.419373) |
| `KappaCost` | 0.06892759 |
| `DebtPremPayments` | 0.00107866 |

| Criterio | Residual |
| --- | --- |
| El que usa el código hoy, `|Y_F − C_F − δK − Kappa|` | `6.07e-04` |
| **El correcto, `|Y_F − C_F − δK − Kappa − DP|`** | **`4.71e-04`** |
| El impreso en el anexo, `|Y_F − C_F − δK_F − DP|` | `1.10e-01` |

La versión del anexo está dos órdenes de magnitud peor, y la brecha es
exactamente `KappaCost + δ·K_I = 0.06893 + 0.04194 = 0.11087`, que es lo que el
teorema dice que falta. La confirmación numérica es exacta.

Pesos relativos: `KappaCost` es 5.04 % de `Y_F`; `DebtPremPayments` es 0.079 %.
Por eso la omisión del código es numéricamente menor y la del anexo no lo es.

El residual corregido, `4.71e-04`, no es cero de máquina: es el error de
discretización del esquema de diferencias finitas. Corregir la fórmula lo baja un
factor de 1.29 y, más importante, hace que el diagnóstico mida lo que dice medir.

**Estado: aplicado.** `model_main.m` ahora calcula el residual condicionando en
el régimen de la prima:

```matlab
if debt_prem_rebate
    walras_err = abs(Y_F - C_F_agg - d*K_star - KappaCost);
else
    walras_err = abs(Y_F - C_F_agg - d*K_star - KappaCost - DebtPremPayments);
end
```

Con `debt_prem_rebate = true` la prima se recicla vía `T` y su término se
cancela de la identidad, de modo que ambas ramas son correctas en su régimen.

Se verificó que `K_star` sí es capital total: `model_main.m` línea 2071 define
`KD = k_ratio*L_F + K_I`. El único término ausente era la prima de deuda. El
archivo editado pasa `checkcode` sin advertencias nuevas en el bloque, y
reevaluado sobre la corrida guardada el residual pasa de `6.07e-04` a
`4.71e-04`.

---

## 3. La prima de deuda: ¿devolverla a todos los agentes?

La configuración de cierre usa `debt_prem_rebate = false`, de modo que los pagos
de prima **desaparecen del sistema**. El anexo justifica esto como "costos de
intermediación o incumplimiento implícito". Esas son dos historias distintas y
piden tratamientos distintos.

**Historia A, costos de intermediación.** El spread paga recursos reales
consumidos por evaluar, monitorear y cobrar créditos a deudores de baja
productividad. Entonces no hay nada que devolver: los recursos se consumen. La
restricción de recursos agregada debe cargar el término, que es exactamente lo que
dice el teorema y lo que al código le faltaba. Es la tradición de verificación
costosa del estado (Bernanke–Gertler–Gilchrist): el costo de monitoreo es real.
**Es la historia coherente con `rebate = false`.**

**Historia B, rentas de intermediación.** El spread es una renta pura capturada
por intermediarios propiedad de los hogares. Entonces es una transferencia, no una
pérdida de recursos, y el término desaparece de la restricción agregada. Aquí sí
tiene sentido devolverla, y devolverla lump-sum a todos es defendible si la
propiedad de los intermediarios está repartida uniformemente.

**Historia C, incumplimiento implícito.** Si el spread compensa pérdidas esperadas
por default, los recursos **no se destruyen**: son una transferencia hacia el
deudor que incumple. Y aquí está el punto que importa para tu pregunta:
**devolverlos lump-sum a todos los agentes sería incorrecto**, porque deberían
regresar a los deudores que efectivamente incumplieron —agentes de baja `z` y
endeudados—, no repartirse uniformemente. Repartir uniformemente transfiere del
grupo que generó la pérdida hacia todos, lo que **invierte el signo** de la
redistribución que el mecanismo pretende capturar. En un modelo cuyo objeto es la
desigualdad, eso importa direccionalmente aunque la magnitud sea chica.

Cómo lo trata la literatura, en resumen: en modelos con una cuña de endeudamiento
exógena conviven las dos primeras convenciones, y el paper declara cuál usa; los
modelos de default endógeno (Chatterjee–Corbae–Nakajima–Ríos-Rull;
Livshits–MacGee–Tertilt) no imponen un spread exógeno en absoluto, sino un
*schedule* de precios `q(a′,z)` que hace que el prestamista competitivo obtenga
beneficio cero contra la probabilidad de default efectiva, de modo que no hay
peso muerto más allá de lo que la quiebra destruye. Esa es la formulación correcta
de la historia C, y es un proyecto de modelado bastante mayor.

**El propio documento ya elige.** La revisión literaria del trabajo final es
explícita al respecto: el modelo *"incorpora elementos de ambos enfoques. Del
paradigma estructuralista toma la existencia de diferencias de productividad entre
sectores (tecnologías distintas). Del enfoque institucional incorpora una barrera
de acceso al sector formal κ(z) y una prima de deuda spread(z), que actúan como
aproximaciones a costos regulatorios, financieros y de acceso que enfrentan los
agentes de menor productividad."*

Es decir, la prima está definida como **costo institucional de acceso** en la
tradición de De Soto (1986) y Loayza (2016), no como compensación por default. Eso
es exactamente la historia A: costos regulatorios y de acceso al crédito formal
son recursos reales consumidos en un entorno de derechos de propiedad débiles.

**Recomendación.** Mantener `rebate = false` —ya coherente con el marco teórico
declarado—, y **quitar "o incumplimiento implícito" del anexo**: esa cláusula
introduce la historia C, que el modelo no implementa y que, de implementarse,
exigiría devolver los pagos a los deudores que incumplen y no lump-sum a todos.
Como `DebtPremPayments` es 0.079 % de `Y_F`, nada de esto mueve los resultados; es
cuestión de que el anexo cuente la misma historia que la revisión literaria.

---

## 3bis. Estado de las correcciones del anexo

Las seis correcciones identificadas **se aplicaron al anexo** el 2026-09-07 y el
documento recompila sin errores ni referencias sin resolver (15 páginas):

| # | Qué se corrigió |
| --- | --- |
| 1 | pesos del agregador CES: `ω^{1/σ}` → `ω` |
| 2 | demanda de capital informal: se agrega el factor `p_I` |
| 3 | prima de deuda: `χ₀(z₁/z)^η` → `χ₀((z_max−z)/(z_max−z_min))^η` |
| 4 | barrera `κ_z`: interpolación suave, con la fórmula explícita como `eq:kappa_z` |
| 5 | vaciamiento de activos: se agrega `K_I` a la demanda agregada de capital |
| 6 | vaciamiento del bien formal: identidad completa con `K = K_F + K_I` |

Se aclaró además la interpretación de la prima, comprometiendo el texto con la
lectura de costo real de intermediación.

Los **valores de parámetros** del anexo no se tocaron: el documento se titula
"Versión 10" y audita `aiyagari_2firms_v10_R2_...`, de modo que describen
legítimamente esa versión y no la calibración de cierre del paquete. Sincronizar
esos números es una decisión editorial aparte.

---

## 4. Sensibilidad de la discretización de la productividad

La corrida de cierre usa `Nz_ar = 40` y `width_z_ar = 2.5`. La desviación estándar
de `log z` que realmente produce esa grilla, bajo su propia distribución ergódica,
es **0.5281** contra el objetivo de calibración **0.5440**: un **2.9 % por
debajo**.

Conviene subrayar por qué esto importa más de lo que parece. Los dos parámetros
del proceso de productividad, `rho_z = 0.861` y `sd_logz = 0.544`, no son valores
libres: son momentos **estimados con datos peruanos** (Hong 2022, sobre ENAHO), y
el trabajo se toma el cuidado de documentar esa procedencia, igual que con el
resto de la calibración externa —Céspedes et al. (2014, BCRP) para la tecnología
formal, Göbel, Grimm & Lay (2013, BCRP) para la informal, Castillo & Rojas (BCRP)
para la depreciación. El desfase de 2.9 % no es entonces un detalle numérico: es
el modelo dejando de reproducir un momento empírico que se estimó y se citó a
propósito.

El barrido siguiente reproduce exactamente `ou_ar1_generator_grid` de
`model_main.m` y mide la sd realizada. Filas: `Nz`. Columnas: `width_z_ar`.

### sd(log z) realizada

| Nz \ w | 2.0 | 2.5 | 3.0 | 3.5 | 4.0 | 5.0 |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 7 | 0.5233 | 0.5774 | 0.6145 | 0.6408 | 0.6602 | 0.6873 |
| 14 | 0.4991 | 0.5472 | 0.5767 | 0.5958 | 0.6097 | 0.6318 |
| 20 | 0.4922 | 0.5379 | 0.5637 | 0.5786 | 0.5884 | 0.6027 |
| 30 | 0.4873 | 0.5313 | 0.5543 | 0.5661 | 0.5729 | 0.5820 |
| **40** | 0.4850 | **0.5281** | 0.5498 | 0.5600 | 0.5654 | 0.5721 |
| 60 | 0.4828 | 0.5251 | 0.5453 | 0.5540 | 0.5580 | 0.5625 |
| 80 | 0.4817 | 0.5236 | 0.5431 | 0.5511 | 0.5544 | 0.5578 |
| 120 | 0.4806 | 0.5221 | 0.5410 | 0.5482 | 0.5508 | 0.5531 |

### porcentaje del objetivo alcanzado

| Nz \ w | 2.0 | 2.5 | 3.0 | 3.5 | 4.0 | 5.0 |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 7 | 96.19 % | 106.14 % | 112.95 % | 117.79 % | 121.37 % | 126.35 % |
| 14 | 91.75 % | 100.60 % | 106.01 % | 109.52 % | 112.07 % | 116.14 % |
| 20 | 90.48 % | 98.88 % | 103.63 % | 106.36 % | 108.16 % | 110.79 % |
| 30 | 89.58 % | 97.66 % | 101.89 % | 104.06 % | 105.31 % | 106.98 % |
| **40** | 89.15 % | **97.08 %** | 101.06 % | 102.94 % | 103.93 % | 105.16 % |
| 60 | 88.74 % | 96.52 % | 100.24 % | 101.84 % | 102.58 % | 103.40 % |
| 80 | 88.54 % | 96.25 % | 99.84 % | 101.30 % | 101.91 % | 102.53 % |
| 120 | 88.34 % | 95.98 % | 99.44 % | 100.76 % | 101.25 % | 101.68 % |

### El hallazgo

Leer la columna `w = 2.5` de arriba a abajo: al refinar la grilla de `Nz = 7` a
`Nz = 120`, la sd realizada **baja** de 0.5774 a 0.5221 y converge a ≈ 0.521, que
es el **95.8 %** del objetivo. Con `Nz = 200` da 0.5210. Es decir:

> A ancho fijo `w = 2.5`, aumentar `Nz` **no** acerca la dispersión al objetivo:
> la aleja, y converge a un valor con un sesgo permanente de ≈ 4 %.

El sesgo lo controla `width_z_ar`, no `Nz`. La comprobación analítica lo confirma:
una normal truncada en ±`w`·σ tiene desviación estándar igual a la siguiente
fracción de σ.

| w | fracción de σ | sd efectiva con σ = 0.544 |
| ---: | ---: | ---: |
| 2.0 | 0.8796 | 0.4785 |
| 2.5 | 0.9546 | 0.5193 |
| 3.0 | 0.9866 | 0.5367 |
| 3.5 | 0.9969 | 0.5423 |
| 4.0 | 0.9995 | 0.5437 |

El límite de la columna `w = 2.5` (0.521) es esencialmente el límite de
truncamiento (0.5193), con un pequeño exceso por la acumulación de masa en las
barreras reflectoras de los bordes.

**Consecuencia para el test de convergencia existente.**
`calibracion/grid_convergence_test.m` barre `Nz ∈ {7, 14, 24, 30, 40}` con
`width_z_ar` fijo y toma `Nz = 40, I = 500` como *ground truth*. Ese diseño no
puede detectar este sesgo: mide convergencia en la dimensión equivocada, y su
propio *ground truth* lo arrastra. Los números de arriba muestran además que en
`Nz` bajo los dos errores se compensan por accidente: `Nz = 7, w = 2.5` da 106 %
del objetivo y `Nz = 40, w = 2.5` da 97 %, de modo que un barrido en `Nz` "ve"
que el resultado se mueve y lo atribuye a la grilla fina, cuando en realidad está
cruzando el objetivo de arriba hacia abajo.

### Efecto sobre la desigualdad

El Gini de `z` tras normalizar `E[z] = 1`, contra el valor exacto de la
log-normal, `2Φ(σ/√2) − 1 = 0.299515`:

| Configuración | Gini(z) | sd(log z) | soporte de z |
| --- | ---: | ---: | --- |
| **Actual: Nz = 40, w = 2.5** | **0.290953** | 0.528123 | [0.223, 3.393] |
| Nz = 40, w = 3.0 | 0.302093 | 0.549753 | [0.168, 4.398] |
| **Nz = 60, w = 3.0** | **0.299955** | 0.545317 | [0.169, 4.409] |
| Nz = 40, w = 2.5 con σ ajustada | 0.299176 | 0.544000 | [0.213, 3.505] |
| log-normal exacta | 0.299515 | 0.544000 | — |

La configuración actual subestima el Gini de productividad en 2.9 %. Como en un
modelo de Bewley la dispersión de riqueza amplifica la dispersión de ingreso, el
sesgo se propaga hacia abajo en los momentos de desigualdad que reporta el
trabajo, y va en la misma dirección que el déficit del gradiente de informalidad
por quintil de riqueza (`T6` = 4.4 % del modelo contra 53 % del dato). No es una
explicación del gap —el margen extensivo ausente sigue siendo la razón principal—
pero sí contribuye en el mismo sentido, y conviene descartarlo.

### Tres opciones, cuantificadas

**Opción 1, la recomendada: `Nz = 60`, `width_z_ar = 3.0`.** Da sd = 0.5453
(100.2 % del objetivo) y Gini = 0.29996 contra 0.299515 exacto: calza ambos
momentos con error menor a 0.2 %, y recupera la cola superior, con `z` hasta 4.41
en vez de 3.39. Cuesta 50 % más de nodos en la dimensión `z`.

**Opción 2, mínimo cambio: mantener `Nz = 40` y poner `width_z_ar = 2.8268`.** Da
sd exactamente 0.5440. El ancho que calza el objetivo depende de `Nz`, porque los
dos errores interactúan:

| Nz | `width_z_ar` que calza | sd lograda |
| ---: | ---: | ---: |
| 20 | 2.5942 | 0.544000 |
| 30 | 2.7341 | 0.544000 |
| 40 | **2.8268** | 0.544000 |
| 60 | 2.9513 | 0.544000 |
| 80 | 3.0367 | 0.544000 |

**Opción 3, no tocar la grilla: poner `sd_logz_ar = 0.560354`.** Con `Nz = 40` y
`w = 2.5`, ese insumo produce una sd realizada de 0.5440 exacta y un Gini de
0.299176. Es la opción más barata, pero es un parche: calza el segundo momento
dejando el soporte truncado en ±1.401 en logs, o sea `z` como máximo 3.505. Si
alguna conclusión depende de la cola alta de productividad, esta opción no la
recupera.

### Advertencia importante

Cambiar la dispersión efectiva de `z` **mueve los targets de calibración**. Los
cuatro parámetros calibrados internamente —`ψ_F`, `ψ_I`, `A_I`, `κ_z1`— están
ajustados a `T4`, `T5` y `Tkz` bajo la dispersión actual. Adoptar cualquiera de
las tres opciones exige recalibrar. Por eso esto se plantea como ejercicio de
robustez, no como corrección a aplicar sin más: el resultado esperado es que la
desigualdad suba y que `T6` mejore algo, y vale la pena verificar si es así.

---

---

## 6. El proceso de productividad: definición, fuente y metodología

Esta sección documenta la revisión de los dos parámetros del proceso de
productividad contra su fuente primaria y contra la metodología de referencia.

### 6.1 De dónde salen los valores

La Tabla 1 de Hong (2022), cuya nota dice *"The time unit is a quarter"*,
reporta para Perú:

| Símbolo | Descripción | Valor |
| --- | --- | ---: |
| `ρ` | persistencia del componente AR(1) | 0.963 |
| `σ_ps` | SD de los shocks al AR(1) (innovación) | 0.146 |
| `σ_tr` | SD del componente i.i.d. transitorio | 0.443 |
| `σ_P0` | SD del draw inicial `P₀` | 0.544 |

El modelo usa `rho_z_ar = 0.861` y `sd_logz_ar = 0.544`. El comentario del código
documenta el mapeo como `rho_z_ar = 0.963^4` y
`sd_logz_ar = 0.146/sqrt(1-0.963^2)`. Evaluado:

| Cantidad | Fórmula documentada | Valor usado | Desvío |
| --- | ---: | ---: | ---: |
| persistencia anual | 0.860013 | 0.861 | +0.11 % |
| sd estacionaria | 0.541741 | 0.544 | +0.42 % |

El `0.544` coincide dígito por dígito con el `σ_P0` de Hong, no con el resultado
de la fórmula. Son cosas distintas: `σ_P0` es la **condición inicial** del
componente persistente a los 25 años en un modelo de ciclo de vida no
estacionario, mientras que este modelo es estacionario e infinito y su objetivo
natural es la **sd estacionaria del AR(1)**, `0.541741`.

Numéricamente da casi igual, 0.42 %. Lo que conviene es que el comentario y el
valor digan lo mismo.

Se verificó además que la sd estacionaria es invariante a la frecuencia: mapeada
a anual da `0.541741`, idéntica a la trimestral, de modo que el mapeo
`rho_anual = rho_trimestral^4` con la sd sin reescalar es correcto.

### 6.2 La parametrización de la difusión es la estándar

El modelo escribe la difusión del OU como `sqrt(2*eta)*sigma`. Esa es exactamente
la parametrización de Yanagimoto (2026), *Marriage and Divorce in Continuous
Time*, ecuación (6):

```
db_t = eta*(mu_m - b_t) dt + sigma_m*sqrt(2*eta) dB_t
```

y el paper explica por qué se usa así: *"Under this parametrization, the
stationary distribution of b_t is N(mu_m, sigma_m^2), so mu_m and sigma_m have
the same interpretation as in the discrete-time AR(1) specification."*

Es decir, el factor `sqrt(2*eta)` existe precisamente para que `sigma` signifique
la desviación estándar **estacionaria**. Eso confirma la definición del punto
anterior. El mismo paper escribe su AR(1) como
`b = (1-rho)*mu + rho*b_{-1} + sigma*sqrt(1-rho^2)*xi`, que es la relación
inversa de `sd_estacionaria = sd_innovacion/sqrt(1-rho^2)`, y usa el mismo mapeo
`eta = -log(rho)/dt`.

Sobre las unidades: Hong estima el proceso sobre el componente no predecible del
**logaritmo** del ingreso, de modo que sus sigmas están en logs. El modelo
especifica el OU sobre `log z`, consistente. Esto lo aparta del código base de
Moll, que hace el OU **en niveles**, pero apartarse es lo correcto dado el origen
de los datos. El precio es que `z = exp(x)` es log-normal y `E[z] != 1`, lo que
obliga a normalizar; el código lo hace.

### 6.3 El mapeo ingenuo no garantiza los momentos: precedente publicado

Yanagimoto (2026) es explícito sobre el límite del mapeo AR(1) a OU:

> *"A naive approach is to set the parameters of the OU process to match the mean
> and variance of the AR(1) process. However, this approach does not work well in
> practice ... naively matching the OU parameters via the standard mapping
> `eta = -log(rho)/dt` systematically overstates the divorce rate."*

Y su respuesta fue **recalibrar el proceso en tiempo continuo**:

| Parámetro | Mapeo ingenuo | Re-estimado en CT |
| --- | ---: | ---: |
| `mu_m` | 0.521 | 0.951 |
| `sigma_m^2` | 0.68 | 0.83 |
| `eta` | 0.11 | 0.113 |

Subieron `sigma_m^2` un 22 %. Solo `eta` quedó igual.

El mecanismo concreto que ellos corrigen, el *continuous monitoring problem*, es
propio de modelos con umbral absorbente: en tiempo discreto la decisión se evalúa
una vez por período y en continuo a cada instante, de modo que cruzar el umbral
es más probable. Este modelo no tiene nada absorbente —las esquinas KKT no
terminan nada— así que ese canal no aplica. La lección metodológica sí: el mapeo
es un punto de partida, hay que verificar que el modelo en tiempo continuo
reproduzca el momento objetivo, y ajustar si no.

### 6.4 Qué pasa al corregir

Efecto sobre la discretización, con `Nz = 40`:

| Configuración | width | sd realizada | % objetivo | Gini(z) | soporte de z |
| --- | ---: | ---: | ---: | ---: | --- |
| Actual, `sd=0.5440`, `w=2.50` | 2.5000 | 0.528123 | 97.08 % | 0.290953 | [0.223, 3.393] |
| Solo corregir la sd a 0.5417 | 2.5000 | 0.525930 | 97.08 % | 0.289814 | [0.225, 3.377] |
| **Corregido, `sd=0.5417`, `w=auto`** | **2.8268** | **0.541741** | **100.00 %** | **0.297946** | [0.187, 3.996] |

Referencia analítica: el Gini exacto de una log-normal con `sd = 0.5417` es
`0.298331`; la configuración corregida queda a 0.13 % de ese valor.

Conclusión operativa: **corregir solo la sd no sirve**. El desvío sigue en
97.08 % y la sd realizada incluso baja. El ancho de grilla es lo que controla el
sesgo. Las dos correcciones juntas dan el objetivo exacto y recuperan cola
superior, con `z` hasta 3.996 en vez de 3.393.

### 6.5 Límite de alcance, no de definición

El modelo excluye deliberadamente el componente transitorio `σ_tr = 0.443`, y el
código lo documenta: *"The transitory shock sd=0.443 is not part of the
persistent productivity state."* Es una decisión defendible, porque `z` es el
estado persistente. Cuantificada:

| Componente | SD |
| --- | ---: |
| persistente | 0.5417 |
| transitorio | 0.4430 |
| **total residual** | **0.6998** |

El modelo captura el **59.9 % de la varianza** y el **77.4 % de la desviación
estándar** de la dispersión residual del ingreso laboral que Hong estima.

No es un error, pero es material para las conclusiones sobre desigualdad, y va en
la misma dirección que los otros dos canales identificados: el truncamiento de
grilla, y el gradiente por quintil de riqueza que el modelo subestima. De los
tres, este es con diferencia el mayor. Conviene declararlo en el documento y no
solo en un comentario del código.

## 7. Reproducción

```matlab
run('scripts/matlab/verificacion_numerica.m')     % secciones 1 y 2
run('scripts/matlab/sensibilidad_grilla_z.m')     % sección 4
```

El primero necesita el `.mat` de la corrida de cierre del paquete de replicación.
El segundo es autocontenido: reproduce `ou_ar1_generator_grid` y no requiere
ninguna corrida previa. Ninguno de los dos necesita la Statistics Toolbox.
