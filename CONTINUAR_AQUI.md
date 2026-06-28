# CONTINUAR AQUÍ — sesión 2026-06-27

## Qué se hizo hoy

### 1. Corrida producción completada ✅
- Run: `v10_prod_kz38_psii34` (I=500, Nz=40, 11.2 horas)
- .mat: `outputs/stationary/v10_prod_kz38_psii34/results_v10_prod_kz38_psii34.mat`

| Momento | Modelo | Target | Gap |
|---------|--------|--------|-----|
| T4 horas informal | 0.510 | 0.557 | −4.7pp |
| T5 PBI nominal | 0.182 | 0.190 | −0.8pp ✓ |
| Tkz gap z2−z1 | 0.313 | 0.386 | −7.3pp |
| Tgasto F/I | 1.451 | 1.913 | −32% |
| r* | 0.066 | — | |
| p_I* | 0.943 | <1 ✅ | |

Cuello de botella: KFE = 80% del tiempo (Nz=40, I=500).

---

### 2. Fixes en `model_main.m`

| Fix | Línea | Descripción |
|-----|-------|-------------|
| scan coarse wI | ~1641 | Grid scan p_I usa `max_iter_wI_scan=8`, `damp_wI_scan=0.30` |
| `damp_wI_log` | 523 | 0.10 → 0.25 (convergencia ~3× más rápida) |
| `total_elapsed` en .mat | ~1424 | Añadido al `save()` |
| bug .txt metadata | 2563 | `run_config.fast_debug` → `run_config.modo_rapido` |

---

### 3. Script nuevo: `calibracion/grid_convergence_test.m`

Corre Nz={7,14,20,40} con I=200 (mismos params `test_kz38_psii34`) y genera figura precisión vs velocidad.

```matlab
>> grid_convergence_test          % corre todo (~45 min)
>> grid_convergence_test('plot')  % solo figura si ya hay .mat
```

Figura sale en: `outputs/grid_convergence/fig_grid_convergence.pdf`

El run Nz=40 I=500 (producción de hoy) se carga automáticamente sin re-correr.

---

## Pendientes próxima sesión

### Calibración (en orden de impacto)
1. **Tkz: 0.313→0.386** → probar `kappa_z1=0.50` (0.38 da 0.313)
2. **T4: 0.510→0.557** → probar `psi_I=28` (o `psi_F=65`)
3. **T5: 0.182→0.190** → probar `A_I=0.97` (gap pequeño)
4. **Tgasto: 1.451→1.913** — canal débil; explorar `amin` más negativo

Setenv rápido para siguiente calibración FAST_DEBUG:
```matlab
setenv('HA_IE_FAST_DEBUG','true')
setenv('HA_IE_KAPPA_Z1','0.50')
setenv('HA_IE_PSI_I','28')
setenv('HA_IE_A_I','0.97')
setenv('HA_IE_RUN_TAG','test_kz50_psii28_AI97')
model_main
```

### Grid convergence figure
```matlab
>> cd('replication_package')
>> grid_convergence_test
```
Faltan 3 puntos: Nz=7 (~2 min), Nz=14 (~8 min), Nz=20 (~18 min).

### Bug menor pendiente
`ha_write_run_metadata` línea 2621 — fix `fast_debug`→`modo_rapido` ya aplicado.
Verificar que el .txt se genera correctamente en la próxima corrida.

---

## Archivos clave

| Archivo | Descripción |
|---------|-------------|
| `model_main.m` | Modelo principal v10 |
| `calibracion/setup_calibration.m` | Setenv defaults |
| `calibracion/grid_convergence_test.m` | Script figura precisión/velocidad (NUEVO) |
| `outputs/stationary/v10_prod_kz38_psii34/` | Resultados producción hoy |
| `outputs/grid_convergence/` | Figura convergencia (pendiente) |

## Parámetros benchmark activos (test_kz38_psii34)
```
ga=1.0, rho=0.073, Frisch=0.38
psi_F=55, psi_I=34, theta=1.0, nu_I=0.6
A_I=0.95, alpha_I=0.220, beta_I=0.619, al=0.573
omega_C=0.56, sigma_C=5.0, tau_c=0, amin=-1.0
Nz=40, rho_z=0.860, sd_logz=0.542, z_width=2.5
kappa_z1=0.38, kappa_z_shape=2.0
debt_prem_chi=0.02, eta=1.0
```
