# HA-IE Replication Package — v10 ARz + DRS Göbel

Modelo Aiyagari HACT 2 firmas (formal/informal), oferta laboral endógena, Perú.
z-process: Hong (2022, JIE). Firma informal: DRS Göbel et al. (2013).

---

## Estado del package (2026-06-26)

> **CALIBRACIÓN EN PROGRESO — targets primarios cerca, producción pendiente.**
>
> Mejor run: `test_kz38_psii34` (MODO RÁPIDO). T4≈0.513 (target 0.516 pre-COVID), T5≈0.182 (target 0.190).
> Restricciones A_I=0.95<1 ✅ y p_I=0.938<1 ✅ satisfechas.
> Pendiente: corrida MODO PRECISIÓN (I=500) y ajuste fino T5 con A_I=0.98.
>
> Ver `CONTINUAR_AQUI.md` para retomar sesión y `REVISION_TRACKER.md` para bugs pendientes.
> Contexto de calibración y bitácoras en `.planning/` (no versionado).

---

## Cómo correr el modelo

### Paso 1 — Abrir MATLAB y pararse en esta carpeta

```matlab
cd('C:\...\replication_package')
```

### Paso 2 — Setenv con los parámetros que quieres explorar

`setenv()` persiste durante la sesión de MATLAB. No se borra al correr `model_main`.
Solo pon los parámetros que quieres cambiar — el resto usa los defaults del modelo.

```matlab
% ── Nombre del run (define la carpeta de output) ──────────────────
setenv('HA_IE_RUN_TAG',   'prueba_om058_k200')

% ── Velocidad ─────────────────────────────────────────────────────
setenv('HA_IE_FAST_DEBUG', '1')   % 1 = Modo Rápido    (~7 min,  I=200, exploración)
                                  % 0 = Modo Precisión (~4 h,    I=500, producción)

% ── Parámetros a explorar ─────────────────────────────────────────
setenv('HA_IE_OMEGA_C',         '0.58')   % peso CES formal  (↓→T5↑ pero p_I↑)
setenv('HA_IE_KAPPA_Z1',        '0.200')  % barrera formal   (↑→Tkz↑)
setenv('HA_IE_KAPPA_Z_SHAPE',   '2.0')    % curvatura barrera
setenv('HA_IE_NU_I',            '0.40')   % exp z informal   (↓→Tkz↑)
setenv('HA_IE_PSI_F',           '180')
setenv('HA_IE_PSI_I',           '50')

% ── Firma informal — NO TOCAR alpha_I/beta_I (Göbel 2013) ────────
setenv('HA_IE_A_I',             '0.99')
setenv('HA_IE_ALPHA_I',         '0.118')
setenv('HA_IE_BETA_I',          '0.605')

% ── z-process Hong 2022 — NO TOCAR rho/sd ────────────────────────
setenv('HA_IE_Z_N',   '14')
setenv('HA_IE_Z_RHO', '0.8600132622')
setenv('HA_IE_Z_SD',  '0.5417411732')

% ── Otros ────────────────────────────────────────────────────────
setenv('HA_IE_AMIN',                 '-1')
setenv('HA_IE_R_HI',                 '0.15')
setenv('HA_IE_INFORMAL_PROFIT_RULE', 'hours')
setenv('HA_IE_VERBOSE',              '0')
```

### Paso 3 — Correr

```matlab
model_main
```

Para el siguiente run solo cambia los setenv que quieres modificar y vuelve a correr.

---

## Output del modelo

Cada run genera una carpeta en:

```
outputs/stationary/<RUN_TAG>/
```

Archivos generados:

| Archivo | Contenido |
|---------|-----------|
| `results_<TAG>.mat` | Equilibrio completo: a, z, g, c, ell_F, ell_I, r*, K*, w_F*, p_I*, etc. |
| `calib_<TAG>.mat` | Resumen de parámetros usados |
| `run_metadata.txt` | Targets vs modelo (p_I, T4, T5, Tkz, Tgasto, r*, K*) |

---

## Generar gráficos

Los scripts de Python leen el `.mat` y generan PNGs en `<carpeta_run>/plots_moll/`.

### Desde MATLAB (recomendado)

```matlab
TAG = getenv('HA_IE_RUN_TAG');
MAT = sprintf('outputs/stationary/%s/results_%s.mat', TAG, TAG);
OUT = sprintf('outputs/stationary/%s/plots_moll', TAG);

system(sprintf('python ploteo/moll_mechanism.py --mat-file "%s" --out-dir "%s"', MAT, OUT));
system(sprintf('python ploteo/moll_gasto.py     --mat-file "%s" --out-dir "%s"', MAT, OUT));
```

### Desde terminal

```bash
cd replication_package

python ploteo/moll_mechanism.py \
  --mat-file "outputs/stationary/prueba_om058_k200/results_prueba_om058_k200.mat" \
  --out-dir  "outputs/stationary/prueba_om058_k200/plots_moll"

python ploteo/moll_gasto.py \
  --mat-file "outputs/stationary/prueba_om058_k200/results_prueba_om058_k200.mat" \
  --out-dir  "outputs/stationary/prueba_om058_k200/plots_moll"
```

Si omites `--out-dir`, los PNGs van al mismo directorio que el `.mat` en subcarpeta `plots_moll/`.

---

## Qué genera cada script

### `moll_mechanism.py` — 11 PNGs + 5 TXTs

| Archivo | Qué muestra |
|---------|-------------|
| `moll_savings_and_wealth_distribution.png` | Política de ahorro s(a,z) para z bajo vs alto **+** densidad de riqueza g(a\|z) condicional por z |
| `moll_savings_and_wealth_distribution_labeled.png` | Igual con caption de publicación |
| `moll_time_use_by_z_with_leisure.png` | Barras apiladas: horas formal / informal / ocio por cada nodo z |
| `moll_time_use_by_z_excluding_leisure.png` | Participación sectorial del trabajo (formal/informal) sin ocio, por z |
| `moll_consumption_distribution.png` | Distribución de consumo efectivo C (agrega utilidad) vs gasto X = c_F + p_I·c_I |
| `moll_consumption_components_distribution.png` | Distribución de c_F y p_I·c_I, agregado todos los z |
| `moll_consumption_components_distribution_by_z_groups.png` | Componentes c_F y p_I·c_I condicionados en z bajo / mediano / alto (3 paneles) |
| `moll_income_decomposition_by_wealth_quintile.png` | Ingreso medio por quintil de riqueza, descompuesto en: labor formal, labor informal, capital, transferencias, costo deuda |
| `moll_income_decomposition_percent_by_wealth_quintile.png` | Mismo en % del ingreso bruto por quintil |
| `moll_wealth_density_by_z_low_median_high.png` | Densidad de riqueza total y por z bajo/mediano/alto — panel completo + zoom 90% de masa |
| `moll_equilibrium_asset_market.png` | Curvas S(r) y K^D(r): intersección = equilibrio r*, K* (solo en modo GE) |

### `moll_gasto.py` — 1 PNG + 1 TXT

| Archivo | Qué muestra |
|---------|-------------|
| `moll_model_gasto_distribution_by_formality.png` | Distribución del gasto X = c_F + p_I·c_I, separado en: agentes formal-dominantes (ell_F ≥ ell_I), informal-dominantes, y total — histograma + KDE ponderada |

---

## Actualizar slides

```
presentacion/presentation_replication.tex
  → cambiar \graphicspath{{../outputs/stationary/<TAG>/plots_moll/}}
  → actualizar tabla de targets en slide "Calibración"
```

Compilar:
```bash
cd presentacion
pdflatex presentation_replication.tex
```

---

## Targets Perú

| Nivel | Target | Variable del modelo | Dato | Fuente |
|-------|--------|---------------------|------|--------|
| **primario** | T4: share horas informal | `E[ell_I]/(E[ell_F]+E[ell_I])` | 0.516 (2018) / 0.557 (2022) | ENAHO Mod.500, `emplpsec==1`, intensivo |
| **primario** | T5: PIB informal nominal / total | `p_I·Y_I / (Y_F+p_I·Y_I)` | 0.190 | INEI Cuenta Satélite 2024 |
| secundario | Tkz: gap formalidad z alto−z bajo | `P(formal\|z_alto)−P(formal\|z_bajo)` | 0.386 | EPEN 2025 |
| secundario | Tgasto: ratio gasto Q5/Q1 | `E[gasto\|ell_F>ell_I]/E[gasto\|ell_I≥ell_F]` | 1.913 | ENAHO 2015-2019 |
| secundario | p_I < 1 | precio bien informal | <1 | restricción teórica |
| validación | Gini gasto | distribución consumo | 0.401 | Banco Mundial (consumo, no riqueza) |

---

## Estado calibración (2026-06-26)

Mejor run: `test_kz38_psii34` (MODO RÁPIDO — producción I=500 pendiente)

| Target | Modelo | Dato | Estado |
|--------|--------|------|--------|
| p_I | 0.938 | <1 | ✅ |
| A_I | 0.95 | <1 | ✅ |
| T4 | 0.513 | 0.516 (2018) | ✅ ~ok |
| T5 | 0.182 | 0.190 | ⚠️ cerca |
| Tkz | 0.318 | 0.386 | ⚠️ brecha |
| Tgasto | 1.458 | 1.913 | ✗ lejos |

**Próximo run:** `test_AI098_cierre` — A_I=0.98, κ_z1=0.40, resto igual.
Ver `REVISION_TRACKER.md` para bugs pendientes y `CONTINUAR_AQUI.md` para setenv completo.

---

## Restricciones duras (NO VIOLAR)

```
p_I  < 1               bien informal más barato que formal
A_I  ≤ 1               PTF informal ≤ PTF formal
al   = 0.573           capital share formal (Céspedes et al. 2014, estimación efectos fijos; MCO da 0.636)
alpha_I = 0.220        capital informal (calibrado)
beta_I  = 0.619        labor informal  (calibrado)
rho_z   = 0.861        Hong (2022, J. Int. Economics) — NO TOCAR
sd_logz = 0.544        Hong (2022) — NO TOCAR
psi_I  ≥ 34            floor: si baja, form_rate z_min→0 y Tkz salta
psi_F  ≥ 55            floor: si baja, Gini colapsa
R_HI   = 0.20          obligatorio con rho=0.073
```

---

## Todos los parámetros disponibles via setenv

Ver `calibracion/setup_calibration.m` — lista comentada de todos los `HA_IE_*` con rangos y fuentes.

---

## Estructura

```
replication_package/
  README.md                    ← este archivo
  model_main.m                 ← solver principal
  CONTINUAR_AQUI.md            ← punto de entrada para retomar sesión
  REVISION_TRACKER.md          ← bugs pendientes + historial de corridas

  .planning/                   ← contexto privado (no versionado, en .gitignore)
    CALIBRACION_CONTEXTO.md    ← parámetros, instrumentos, reglas aprendidas
    SESION_CALIBRACION_*.md    ← bitácoras de sesión
    NARRATIVA_CALIBRACION.md   ← cómo explicar resultados
    AUDITORIA_NUMERICA.md      ← chequeos numéricos
    FIGURAS_REFERENCIA.md      ← documentación de figuras
    REFERENCIAS_TEORICAS_*.md  ← citas y justificaciones
    PLAN_UTILIDAD_NO_SEPARABLE.md ← extensión futura

  calibracion/
    setup_calibration.m        ← referencia de todos los parámetros HA_IE_*
    escenarios.m               ← bloques setenv por escenario (A/B/C)
    convergence_test.m

  ploteo/
    moll_mechanism.py          ← genera 11 PNGs de mecanismo del modelo
    moll_gasto.py              ← genera 1 PNG de distribución de gasto
    zero_drift_solver.m        ← solver zero-drift vectorizado con prima de deuda (dep de model_main)
    plot_distributions.m       ← diagnóstico OU (MATLAB)
    plot_results.m

  docs/referencias/            ← papers fuente
  presentacion/                ← slides Beamer LaTeX
  inputs/                      ← .mat de referencia
  outputs/stationary/          ← output de cada run (auto-generado)
```

---

## Requisitos

- MATLAB (cualquier versión reciente)
- Python 3 con `numpy scipy matplotlib`:  `pip install numpy scipy matplotlib`
- pdflatex (solo para compilar slides)
