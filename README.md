# HA-IE Replication Package — v10 ARz + DRS Göbel

Modelo Aiyagari HACT 2 firmas (formal/informal), oferta laboral endógena, Perú.
z-process: Hong (2022, JIE). Firma informal: DRS Göbel et al. (2013).

---

## Estado del package (2026-06-22)

> **CALIBRACIÓN EN PROGRESO — targets aún no alcanzados.**
>
> Este package es la base funcional del modelo. El código corre y converge,
> pero la calibración todavía no reproduce los 4 targets de Perú simultáneamente.
> Ver sección "Estado calibración" para detalle de brechas.
>
> **Pendiente una vez se logre calibración estable:**
> - Crear `calibracion/calibracion_final.m` con los `setenv()` exactos del run ganador
> - Documentar parámetros finales en `CALIBRACION_CONTEXTO.md`
> - Correr gráficos completos con ese run y actualizar slides
> - Ese archivo será el punto de entrada oficial para replicar resultados

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
setenv('HA_IE_FAST_DEBUG', 'true')   % true = ~16 min (Nz=14, I=200)
                                     % false = ~4 h   (Nz=14, I=500)

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

| Target | Variable del modelo | Dato | Fuente |
|--------|---------------------|------|--------|
| T4: horas informales / total | `L_I / (L_F + L_I)` | 0.557 | INEI Cuenta Satélite 2024 |
| T5: PIB informal nominal / total | `p_I · Y_I / Y_total` | 0.190 | INEI Cuenta Satélite 2024 |
| Tkz: gap formalidad z alto − z bajo | `P(formal\|z_alto) − P(formal\|z_bajo)` | 0.386 | EPEN 2025 |
| Tgasto: ratio gasto F/I | `gasto_formal_dom / gasto_informal_dom` | 1.913 | ENAHO 2015-2019 |

---

## Estado calibración (2026-06-22)

Mejor run: `hong_nz14_DRS_om055`

| Target | Modelo | Dato | Estado |
|--------|--------|------|--------|
| p_I < 1 | 1.14 | <1 | ✗ viola |
| T4 | 0.560 | 0.557 | ✓ |
| T5 | 0.157 | 0.190 | ~ cerca |
| Tkz | 0.161 | 0.386 | ✗ lejos |
| Tgasto | 1.60 | 1.913 | ~ |

**p_I:** omega_C=0.55 viola restricción. Probar 0.57–0.60.
**Tkz:** kappa_z1=0.110 da 0.161. Probar 0.15–0.30.

### Secuencia sugerida

```
Paso A: encontrar omega_C con p_I<1 y T5 máximo
  → probar omega_C ∈ {0.60, 0.58, 0.57}

Paso B: con ese omega_C, subir kappa_z1 para cerrar Tkz
  → probar kappa_z1 ∈ {0.15, 0.20, 0.25, 0.30}
```

---

## Restricciones duras (NO VIOLAR)

```
p_I < 1                bien informal más barato que formal
A_I <= 1               PTF informal ≤ PTF formal
alpha_I = 0.118        Göbel et al. (2013)
beta_I  = 0.605        Göbel et al. (2013)
rho_z   = 0.8600132622 Hong (2022)
sd_logz = 0.5417411732 Hong (2022)
nu_I    ∈ [0.4, 0.8]
```

---

## Todos los parámetros disponibles via setenv

Ver `calibracion/setup_calibration.m` — lista comentada de todos los `HA_IE_*` con rangos y fuentes.

---

## Estructura

```
replication_package/
  README.md                    ← este archivo
  model_main.m                 ← solver (autocontenido, sin deps fuera de esta carpeta)
  PLAN_CALIBRACION.md          ← bitácora de calibración
  CALIBRACION_CONTEXTO.md      ← contexto completo
  CONTINUAR_AQUI.md            ← guía para retomar sesión

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
