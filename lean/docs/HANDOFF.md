# Handoff — verificación formal en Lean 4 y ajustes derivados

**Fecha:** 2026-09-07
**Repo de verificación:** `C:\Users\johnb\Documents\GitHub\BN26InformalityWealthPeru`
**Entorno Lean:** WSL Ubuntu, `~/EconCSLib` (Lean 4.30.0-rc2, Mathlib compilado)

---

## 1. Qué se hizo

**Verificación formal.** Se formalizó el anexo matemático en Lean 4 usando el flujo
de EconCSLib. 16 teoremas probados, **cero `sorry`**:

- 8 filas de revisión fuente-a-Lean sobre el anexo (generador OU, prima de deuda,
  reparto CES, CPO laboral interior, caso vinculante KKT, firma formal, firma
  informal, vaciamiento del bien formal).
- 8 teoremas de extensión que no son enunciados del anexo (anidamiento del
  Aiyagari clásico, sorting monótono por productividad, margen intensivo sin salto
  de participación, tres de fidelidad del proceso OU, dos de homoteticidad CES).

**Correcciones aplicadas al anexo** (`docs/anexo_matematico/anexo_matematico.tex`),
recompilado sin errores, 15 páginas:

| # | Corrección |
| --- | --- |
| 1 | `eq:ces` — pesos `ω^{1/σ}` → `ω` sin exponenciar |
| 2 | §4.2 demanda de `K_I` — agregado el factor `p_I` |
| 3 | `eq:debtprem` — `χ₀(z₁/z)^η` → `χ₀((z_max−z)/(z_max−z_min))^η` |
| 4 | §3.4 `κ_z` — interpolación suave explícita, numerada `eq:kappa_z` |
| 5 | §5.2 (i) activos — `K_D = k·L_F` → `k·L_F + K_I` |
| 6 | §5.2 (iii) Walras — identidad completa con `K = K_F + K_I` |

Se aclaró además la interpretación de la prima de deuda: costo real de
intermediación (enfoque institucional, De Soto/Loayza), quitando la cláusula
ambigua de incumplimiento implícito.

**Corrección aplicada al código** (`model_main.m`, ~línea 820):

```matlab
if debt_prem_rebate
    walras_err = abs(Y_F - C_F_agg - d*K_star - KappaCost);
else
    walras_err = abs(Y_F - C_F_agg - d*K_star - KappaCost - DebtPremPayments);
end
```

Reevaluado sobre la corrida guardada: residual `6.07e-04` → `4.71e-04`.

**Nada de esto está commiteado.** Todo vive en el working tree del paquete de
replicación, que ya traía otros cambios sin commitear de antes.

---

## 2. Baseline de referencia

Corrida `test_AI098_cierre`, con la que hay que comparar cualquier corrida nueva.

**Configuración:** `FAST_DEBUG=true`, `I=200`, `Nz_ar=40`, `width_z_ar=2.5`,
`sd_logz_ar=0.544`, `rho_z_ar=0.861`, `amin=-1`, `amax=20`.
Tiempo: **1985.9 s ≈ 33 min**.

| Momento | Modelo | Dato |
| --- | ---: | ---: |
| T4 (horas informales) | 0.517110 | 0.557000 |
| T5 (PBI informal nominal) | 0.187958 | 0.190000 |
| Tkz (gap formalidad por z) | 0.377518 | 0.386000 |
| T6 (gradiente por quintil) | 0.044079 | 0.530000 |

| Precio / agregado | Valor |
| --- | ---: |
| `r_star` | 0.066040 |
| `p_I_star` | 0.928115 |
| `w_F_star` | 2.250628 |
| `L_F_star` | 0.259438 |
| `L_I_star` | 0.247469 |
| `K_star` | 5.138390 |
| `Y_F` | 1.367442 |
| `Y_I` | 0.341026 |
| `Gini_a` | 0.521353 |
| `Gini_c` | 0.217911 |
| `walras_err` (criterio viejo) | 6.07e-04 |
| `goods_I_err` | −9.5e-05 |

---

## 3. Corridas pendientes

### Corrida A — verificar el ajuste de Walras end-to-end (~33 min)

> **Atención:** los defaults de `model_main.m` **no** reproducen la corrida de
> cierre. Ver la sección 3bis. Usar el entorno completo, que deja listo el script:

```matlab
run('C:\Users\johnb\Documents\GitHub\BN26InformalityWealthPeru\scripts\matlab\reproducir_cierre.m')
```

Ese script hace el `cd`, fija las 24 variables de entorno necesarias —incluida
`HA_IE_RHO=0.073`, que no aparece en el metadata— y llama a `model_main`.

**Qué esperar.** El ajuste toca solo un diagnóstico, no el equilibrio. Todos los
momentos y precios deben reproducir el baseline al dígito. Lo único que cambia es
la línea `Walras formal residual`, que debe pasar de `6.07e-04` a **`4.71e-04`**.

Si algún momento se mueve, algo más cambió y hay que investigarlo antes de seguir.

### Corrida B — sensibilidad de dispersión en equilibrio general (~45-60 min)

Esta es la que informa la decisión abierta. Con `Nz=60, width=3.0` la grilla
reproduce `sd(log z) = 0.5453` (100.2 % del objetivo) en vez de `0.5281` (97.1 %),
y el Gini de `z` pasa de 0.2910 a 0.29996 contra 0.299515 exacto.

```matlab
setenv('HA_IE_FAST_DEBUG','true');
setenv('HA_IE_Z_N','60');
setenv('HA_IE_Z_WIDTH','3.0');
setenv('HA_IE_RUN_TAG','sens_z_Nz60_w30');
model_main
```

**Qué esperar.** Los momentos **sí** se van a mover, porque la dispersión efectiva
de productividad sube ~3 %. La pregunta es en qué dirección y cuánto:

- `Gini_a` debería **subir** (más dispersión de productividad ⇒ más dispersión de
  riqueza en un modelo de Bewley).
- `T6` debería **mejorar** algo respecto de 0.044, que es la hipótesis a testear.
- `T4`, `T5` y `Tkz` se van a descalibrar en alguna medida; eso es esperado y es
  precisamente lo que decidiría si vale la pena recalibrar.

**Importante:** limpiar las variables después, porque persisten en la sesión de
MATLAB.

```matlab
setenv('HA_IE_Z_N','');
setenv('HA_IE_Z_WIDTH','');
setenv('HA_IE_RUN_TAG','');
```

### Qué reportar de vuelta

De la salida de consola basta con estos bloques:

- `--- Precios ---`
- `--- Desigualdad (validacion, no targets) ---`
- `--- Market Clearing ---`
- la tabla de targets (T4 / T5 / Tkz / T6)

O más simple: el archivo `outputs/stationary/<RUN_TAG>/run_metadata.txt` y el
`results_<RUN_TAG>.mat`, que traen todo.

---

## 3bis. HALLAZGO CRÍTICO: la corrida de cierre no es reproducible desde el paquete

Al intentar reproducir `test_AI098_cierre` se descubrió que **`model_main` con sus
valores por defecto no reproduce la corrida que reporta el documento**. Hay dos
causas independientes, y ninguna produce un mensaje de error: el modelo converge
en silencio a un equilibrio distinto.

**Causa 1 — la tasa de descuento.** La corrida de cierre usó `rho = 0.073`, dato
que solo sobrevive dentro del campo `rho` del `results_*.mat`. El default del
script es `rho = 0.05`, y se verificó con `git show 7e8cc77:model_main.m` que
**también era 0.05 en el commit de la corrida**. Es decir, la corrida fijó
`HA_IE_RHO=0.073` en la sesión de MATLAB, y el bloque `[env]` de
`run_metadata.txt` **no registra esa variable** (tampoco `HA_IE_GA`, `HA_IE_AL`,
`HA_IE_FRISCH`, `HA_IE_TAU`, `HA_IE_D`). El metadata no es autosuficiente
precisamente en los parámetros que fijan `r*`.

**Causa 2 — el bracket de bisección.** El default es `r ∈ [-0.04, 0.0499]`, y el
`r*` reportado es **0.066040**, fuera del bracket. `FAST_DEBUG` no lo modifica. La
corrida usó `HA_IE_R_HI=0.20`, que sí quedó registrado en `[env]`.

**Corrección posterior sobre la causa 2.** Al probar el arreglo se verificó que
esta causa **no** produce un resultado erróneo en silencio: el solver ya hacía un
chequeo de signos sobre `excess_low` y `excess_high` que aborta con `invalid
bracket in r` cuando el equilibrio cae fuera. Impedía reproducir la corrida, pero
avisaba. La causa silenciosa es la 1, y ahora sabemos que son dos parámetros y no
uno. El guardia adicional que se había agregado aquí resultó incorrecto —se
disparaba en cualquier corrida no convergida, porque la bisección siempre deja
`r` sobre uno de los extremos— y se reemplazó por un aviso de no convergencia.

**Evidencia.** Una primera corrida lanzada solo con `HA_IE_FAST_DEBUG=true`, tal
como indica `INSTRUCCIONES.md`, convergía a `r ≈ 0.0419`, `K ≈ 8.25`,
`p_I ≈ 0.954` — contra `r* = 0.0660`, `K* = 5.138`, `p_I* = 0.928` del baseline.
Se abortó al detectarlo.

**Por qué importa.** `INSTRUCCIONES.md` afirma: *"No se necesita definir variables
de entorno para replicar la corrida base"*, y `README.md` que *"`model_main.m` ya
incluye los valores finales usados en la corrida de cierre"*. Ambas son falsas.
Quien siga las instrucciones —un jurado, el asesor, un futuro tesista— obtiene una
calibración distinta sin ningún aviso. Para un paquete de replicación esto es más
grave que cualquiera de las erratas de fórmula del anexo, porque esas no cambiaban
ningún número y esta sí.

**Actualización 2026-09-07: los cuatro arreglos están aplicados.**

Además, al aplicarlos apareció una tercera causa que no había detectado: el
script traía `gamma = 2` mientras la corrida usó **`gamma = 1`** (utilidad
logarítmica). El documento final lo dice explícitamente: *"Se corrigió la
especificación previa gamma = 2, rho = 0.05 por utilidad logarítmica (gamma = 1)
y rho = 0.073"*. El valor de `gamma` **no se guarda en ningún archivo** de la
corrida, así que hubo que inferirlo numéricamente de la política de consumo:
mediana 0.988, cuartiles 0.983 a 1.000, incompatible con 2.

Eso significa que los tres intentos de Corrida A de esa noche corrían con
`gamma = 2` y no habrían reproducido el baseline aunque hubieran terminado.

Lo aplicado:

1. `model_main.m`: defaults `ga = 1` y `rho = 0.073`, con comentario que cita la
   justificación real de `rho`: consistencia interna con `r* < rho` y el
   `r* = 0.066` que reporta el documento, no una fuente externa.
2. `model_main.m`: bracket por defecto ampliado a `r_high = 0.20`.
3. `model_main.m`: guardia de bracket. Si la bisección termina a menos de un 20 %
   del ancho del bracket de cualquiera de sus extremos sin cerrar la tolerancia,
   ahora lanza un **error explícito** en vez de reportar ese punto como
   equilibrio. Si termina en el interior sin alcanzar tolerancia, emite una
   advertencia. Probado en los tres casos.
4. `model_main.m`: el metadata registra ahora `ga`, `rho`, `Frisch`, `al`, `d`,
   `tau`, `r_low` y `r_high` en `[core]`, y `HA_IE_GA`, `HA_IE_RHO`,
   `HA_IE_FRISCH`, `HA_IE_AL`, `HA_IE_D`, `HA_IE_TAU` en `[env]`.
5. `INSTRUCCIONES.md` y `README.md`: corregidas las dos afirmaciones falsas, con
   una nota histórica de qué pasaba antes.
6. `reproducir_cierre.m`: fijaba `HA_IE_RHO` pero **no** `HA_IE_GA`. Corregido.

**Arreglo original sugerido, ya superado por lo anterior.**

1. Poner `rho = 0.073` como default en `model_main.m`, o bien dejar `0.05` y
   documentar explícitamente el `setenv` requerido. Lo primero es preferible: el
   README promete que los defaults son los de la corrida final.
2. Ampliar el bracket por defecto a `r_high = 0.20`, o al menos hacer que el
   solver **falle ruidosamente** cuando la bisección termina pegada a un extremo
   del bracket en vez de reportar un equilibrio.
3. Agregar `HA_IE_RHO`, `HA_IE_GA`, `HA_IE_AL`, `HA_IE_D`, `HA_IE_TAU` y
   `HA_IE_FRISCH` al volcado `[env]` de `run_metadata.txt`, para que el metadata
   sea autosuficiente.
4. Corregir las dos afirmaciones de `INSTRUCCIONES.md` y `README.md`.

**Entorno completo para reproducir** (script listo en
`BN26InformalityWealthPeru/scripts/matlab/reproducir_cierre.m`):

```matlab
setenv('HA_IE_FAST_DEBUG','true');  setenv('HA_IE_RHO','0.073');
setenv('HA_IE_R_LO','-0.04');       setenv('HA_IE_R_HI','0.20');
setenv('HA_IE_AMIN','-1.0');        setenv('HA_IE_ZDRIFT_NPTS','25');
setenv('HA_IE_Z_N','40');   setenv('HA_IE_Z_RHO','0.861');
setenv('HA_IE_Z_SD','0.544');       setenv('HA_IE_Z_WIDTH','2.5');
setenv('HA_IE_A_I','0.98'); setenv('HA_IE_ALPHA_I','0.220');
setenv('HA_IE_BETA_I','0.619');     setenv('HA_IE_THETA','1.0');
setenv('HA_IE_NU_I','0.6'); setenv('HA_IE_PSI_F','55');
setenv('HA_IE_PSI_I','34'); setenv('HA_IE_OMEGA_C','0.56');
setenv('HA_IE_SIGMA_C','5');        setenv('HA_IE_KAPPA_Z1','0.40');
setenv('HA_IE_KAPPA_Z_SHAPE','1.0');
setenv('HA_IE_DEBT_PREM_CHI','0.02'); setenv('HA_IE_DEBT_PREM_ETA','1.0');
setenv('HA_IE_DEBT_PREM_REBATE','0');
setenv('HA_IE_INFORMAL_PROFIT_RULE','hours');
setenv('HA_IE_RUN_TAG','<tu_tag>');
model_main
```

Nota aparte: el `α_K` de la corrida es **0.573** (Céspedes et al., efectos fijos),
mientras el anexo escribe 0.636. Es otra diferencia de valores entre el anexo v10
y la corrida de cierre, del mismo tipo que las ya señaladas.

---

## 3ter. Nota operativa: la Corrida A no se pudo completar en esta máquina

Se intentó tres veces la noche del 2026-09-07 y las tres fueron terminadas por el
guardia de memoria del sistema, cada vez más temprano (12867, 1373 y 896 líneas de
log). **No es un fallo del modelo:** las tres arrancaron con el bracket correcto
`r ∈ [-0.04, 0.20]` y la primera llegó a `GE iter 3` con `r = 0.0608`,
`p_I = 0.938`, `K = 6.12`, convergiendo hacia el baseline `r* = 0.0660`,
`p_I* = 0.928`, `K* = 5.138`.

Causa: la máquina tiene 31 GB y ~25 GB están tomados por aplicaciones abiertas
(VS Code con 69 procesos ≈ 6 GB, navegador ≈ 2.25 GB, Claude ≈ 1.8 GB). Al cerrar
la VM de WSL quedaban ~5.7 GB libres, pero Docker Desktop la reinicia en segundos y
vuelve a tomar ~2 GB, momento en que salta el guardia. El tercer intento usó
`-singleCompThread` sin éxito. No se cerró ninguna aplicación del usuario.

**Para completarla:** cerrar algunas ventanas de VS Code y, si no se está usando,
Docker Desktop; luego correr el script de reproducción. Con ~10 GB libres debería
terminar en ~33 min (o ~60 min con `-singleCompThread`).

Lo que la corrida confirmaría es redundante respecto de lo ya establecido: el
diagnóstico de reproducibilidad quedó demostrado por las corridas parciales, y el
número del residual de Walras corregido (`4.71e-04`) se calculó de forma exacta
sobre el `results_*.mat` guardado, sin necesidad de recomputar el equilibrio.

---

## 4. Decisiones abiertas

1. **Grilla de `z`.** Tres opciones cuantificadas en `docs/VERIFICACION_NUMERICA.md`
   §4: `Nz=60, w=3.0` (recomendada); `Nz=40, w=2.8268` (mínimo cambio); o dejar la
   grilla y poner `sd_logz_ar = 0.560354` (parche, deja el soporte truncado).
   **Cualquiera obliga a recalibrar** `ψ_F, ψ_I, A_I, κ_z1`. La corrida B da la
   evidencia para decidir.

2. **Documento principal.** Sigue con dos erratas en §3.2.3
   (`Π_I = (1−β_I)p_I Y_I/(α_I+β_I)` en vez de `(1−α_I−β_I)p_I Y_I`; y el precio
   dentro de la función de producción). Además define `κ(z)` y no lo incluye en la
   restricción presupuestaria, y lo llama "costo de entrada al empleo formal"
   cuando en el código es una cuña por hora: el modelo es margen **intensivo**
   puro y `κ` es exógeno.

3. **Valores de parámetros del anexo.** El anexo se titula "Versión 10" y audita
   `aiyagari_2firms_v10_R2_...`, así que sus números (`ω_C = 0.4`, `β_I = 0.6`,
   `A_I = 0.099`, `N_z = 7`) describen esa versión, no la calibración de cierre.
   Decisión editorial: actualizarlos, o dejar claro que documenta v10.

4. **Teorema opcional.** El sorting está probado bajo `ν_I < 1` y `κ` no creciente,
   lo que cubre el canal estructuralista puro (`κ` constante). El canal
   institucional puro (`ν_I = 1`, gradiente solo por `κ`) queda fuera de las
   hipótesis. Probarlo permitiría afirmar que **cada paradigma por separado genera
   el gradiente, y juntos se refuerzan**.

---

## 5. Dónde está todo

| Qué | Dónde |
| --- | --- |
| Teoremas y pruebas | `BN26InformalityWealthPeru/{PaperInterface,ProofInterface,MainTheorems,ExtensionResults}.lean` |
| Veredicto y correcciones | `BN26InformalityWealthPeru/FINAL_VALIDATION_REPORT.md` §10-11 |
| Cruce numérico y sensibilidad | `BN26InformalityWealthPeru/docs/VERIFICACION_NUMERICA.md` |
| Scripts MATLAB de verificación | `BN26InformalityWealthPeru/scripts/matlab/` |
| Expediente de defectos | `BN26InformalityWealthPeru/audit/source_proof_fidelity.json` |
| Procedencia de la fuente | `BN26InformalityWealthPeru/SOURCE.md` |

Verificación del paquete Lean, desde `~/EconCSLib` en WSL:

```bash
python3 scripts/paper_contribution.py check BN26InformalityWealthPeru --fast
```

Estado actual: EXIT 0, build completo 8319 objetivos.
