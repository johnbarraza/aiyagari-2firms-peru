# HA-IE Replication Package — Aiyagari 2 Firms, Endogenous Labor, Peru

Heterogeneous-agent continuous-time model (HACT) with two production sectors (formal/informal), endogenous labor supply, and idiosyncratic productivity risk. Applied to Peru.

**z-process:** OU continuous-time, calibrated from Hong (2022, *J. International Economics*).
**Informal firm:** decreasing returns à la Göbel, Görg & Maioli (2013).

---

## Calibration status (2026-06-28)

> **Production run complete.**
>
> Run: **`v10_prod_kz38_psii34`** — I=500, Nz=40, ~11 h.
> Best fast run: **`test_kz38_psii34`** — I=200, Nz=40, ~30 min (error <0.3pp vs production).

| Target | Model | Data | Source |
|--------|-------|------|--------|
| p_I | 0.943 | < 1 ✅ | theoretical |
| T4: informal hours share | 0.510 | 0.557 | ENAHO 2022, Module 500 |
| T5: informal GDP share | 0.182 | 0.190 | INEI Satellite Account 2024 |
| Tkz: formality gap z₂−z₁ | 0.313 | 0.386 | EPEN 2025 |
| Tgasto: expenditure ratio F/I | 1.451 | 1.913 | ENAHO 2015-2019 |

**Documented limitations:** Tgasto and T6 require DRS informal extension (future work).

---

## Grid convergence results (2026-06-28)

Speed-accuracy tradeoff varying Nz (z-grid), I=200 fixed. Ground truth = Nz=40, I=500.

| Nz | Time (min) | Max error (r*, p_I) |
|----|-----------|----------------------|
| 7 | 11 | ~1.6% |
| 14 | 18 | ~0.7% |
| 24 | 44 | ~0.35% |
| **30** | **41** | **<0.25%** ← sweet spot |
| 40 (I=200) | 30 | ~0.1% (vs I=500) |
| 40 (I=500) | 671 | 0% (ground truth) |

**Recommendation:** use Nz=30 for calibration (41 min, <0.25% error). Nz=14 for fast exploration (18 min, <1% error).

Figures: `outputs/grid_convergence/fig_grid_convergence.pdf`, `fig_tradeoff.pdf`.

---

## How to run

### Step 1 — Open MATLAB, navigate here

```matlab
cd('C:\...\replication_package')
```

### Step 2 — Set parameters via setenv

```matlab
% ── Run tag (defines output folder) ──────────────────────────────
setenv('HA_IE_RUN_TAG',    'my_run_tag')

% ── Speed ─────────────────────────────────────────────────────────
setenv('HA_IE_FAST_DEBUG', '1')   % 1 = fast (~7-40 min, I=200, calibration)
                                  % 0 = production (~11 h, I=500, final)

% ── z-grid (recommendation: Nz=30 for calibration, 40 for final) ─
setenv('HA_IE_Z_N', '30')

% ── Parameters to explore ─────────────────────────────────────────
setenv('HA_IE_OMEGA_C',       '0.56')   % CES formal weight
setenv('HA_IE_KAPPA_Z1',      '0.38')   % formal barrier (↑→Tkz↑)
setenv('HA_IE_KAPPA_Z_SHAPE', '2.0')    % barrier curvature
setenv('HA_IE_PSI_F',         '55')
setenv('HA_IE_PSI_I',         '34')

% ── Informal firm — DO NOT CHANGE (Göbel 2013 calibration) ───────
setenv('HA_IE_A_I',     '0.95')
setenv('HA_IE_ALPHA_I', '0.220')
setenv('HA_IE_BETA_I',  '0.619')

% ── z-process Hong (2022) — DO NOT CHANGE ─────────────────────────
setenv('HA_IE_Z_RHO', '0.8600132622')
setenv('HA_IE_Z_SD',  '0.5417411732')
```

### Step 3 — Run

```matlab
model_main
```

---

## Output

Each run creates a folder at `outputs/stationary/<RUN_TAG>/`:

| File | Contents |
|------|----------|
| `results_<TAG>.mat` | Full equilibrium: a, z, g, c, ell_F, ell_I, r*, K*, w_F*, p_I*, etc. |
| `calib_<TAG>.mat` | Parameters used |
| `run_metadata.txt` | Targets vs model (p_I, T4, T5, Tkz, Tgasto, r*, K*) |

---

## Plots

### From MATLAB

```matlab
TAG = getenv('HA_IE_RUN_TAG');
MAT = sprintf('outputs/stationary/%s/results_%s.mat', TAG, TAG);
OUT = sprintf('outputs/stationary/%s/plots_moll', TAG);
system(sprintf('python ploteo/moll_mechanism.py --mat-file "%s" --out-dir "%s"', MAT, OUT));
system(sprintf('python ploteo/moll_gasto.py     --mat-file "%s" --out-dir "%s"', MAT, OUT));
```

### Grid convergence figure

```matlab
addpath('calibracion')
grid_convergence_test('plot')   % regenerate figures from saved .mat
% grid_convergence_test         % re-run all configurations (~45 min)
```

---

## What each script produces

### `moll_mechanism.py` — 11 PNGs + 5 TXTs

| File | What it shows |
|------|--------------|
| `moll_savings_and_wealth_distribution.png` | Savings policy s(a,z) + wealth density g(a\|z) by z |
| `moll_time_use_by_z_with_leisure.png` | Hours: formal / informal / leisure by z node |
| `moll_time_use_by_z_excluding_leisure.png` | Sectoral labor participation (formal/informal) by z |
| `moll_consumption_distribution.png` | Effective consumption C vs expenditure X = c_F + p_I·c_I |
| `moll_consumption_components_distribution.png` | c_F and p_I·c_I distributions (all z) |
| `moll_consumption_components_distribution_by_z_groups.png` | Components by z low/median/high |
| `moll_income_decomposition_by_wealth_quintile.png` | Income by wealth quintile: labor F, labor I, capital, transfers |
| `moll_income_decomposition_percent_by_wealth_quintile.png` | Same in % of gross income |
| `moll_wealth_density_by_z_low_median_high.png` | Wealth density total + by z groups |
| `moll_equilibrium_asset_market.png` | S(r) and K^D(r) curves: intersection = r*, K* (GE only) |

### `moll_gasto.py` — 1 PNG

| File | What it shows |
|------|--------------|
| `moll_model_gasto_distribution_by_formality.png` | Expenditure X distribution by formality status (formal-dominant / informal-dominant / total) |

---

## Calibration targets

| Level | Target | Model variable | Data | Source |
|-------|--------|---------------|------|--------|
| **primary** | T4: informal hours share | `E[ell_I]/(E[ell_F]+E[ell_I])` | 0.557 (2022) | ENAHO Mod.500, `emplpsec==1`, intensive margin |
| **primary** | T5: informal nominal GDP | `p_I·Y_I / (Y_F+p_I·Y_I)` | 0.190 | INEI Satellite Account 2024 |
| secondary | Tkz: formality gap z₂−z₁ | `P(formal\|z_high)−P(formal\|z_low)` | 0.386 | EPEN 2025 |
| secondary | Tgasto: expenditure ratio | `E[X\|ell_F>ell_I]/E[X\|ell_I≥ell_F]` | 1.913 | ENAHO 2015-2019 |
| secondary | p_I < 1 | informal good price | < 1 | theoretical constraint |
| validation | Expenditure Gini | consumption distribution | 0.401 | World Bank (consumption, not wealth) |

---

## Hard constraints (DO NOT VIOLATE)

```
p_I   < 1          informal good cheaper than formal
A_I   ≤ 1          informal TFP ≤ formal TFP
al    = 0.573       formal capital share (Céspedes et al. 2014, FE estimate)
alpha_I = 0.220     informal capital elasticity (calibrated)
beta_I  = 0.619     informal labor elasticity (calibrated)
rho_z   = 0.861     Hong (2022, J. Int. Economics) — DO NOT CHANGE
sd_logz = 0.544     Hong (2022) — DO NOT CHANGE
psi_I  ≥ 34         floor: lower → formality rate at z_min → 0, Tkz spikes
psi_F  ≥ 55         floor: lower → Gini collapses
```

---

## Repository structure

```
replication_package/
  README.md                    ← this file
  model_main.m                 ← main solver (HACT 2-firm model)
  CONTINUAR_AQUI.md            ← session handoff notes
  REVISION_TRACKER.md          ← bugs and run history

  calibracion/
    setup_calibration.m        ← reference for all HA_IE_* parameters with ranges
    escenarios.m               ← setenv blocks by calibration scenario
    grid_convergence_test.m    ← speed-accuracy sweep (Nz={7,14,24,30,40})

  ploteo/
    moll_mechanism.py          ← 11 PNGs of model mechanism
    moll_gasto.py              ← 1 PNG of expenditure distribution
    zero_drift_solver.m        ← zero-drift solver (dependency of model_main)
    plot_distributions.m       ← OU diagnostic (MATLAB)

  outputs/
    stationary/                ← one folder per run (auto-generated)
    grid_convergence/          ← speed-accuracy figures and CSV

  docs/referencias/            ← source papers
  presentacion/                ← Beamer LaTeX slides
  inputs/                      ← reference .mat files
```

---

## Requirements

- MATLAB (recent version)
- Python 3: `pip install numpy scipy matplotlib`
- pdflatex (only for compiling slides)
