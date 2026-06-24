# Plan de Calibración — HA-IE v10 ARz

> Estado: 21 Junio 2026. Benchmark vigente: `calib_nz20_AI099_b060_k110_psi180_om057_20260621`
> **⚠️ 21-Jun: z-process cambió a Hong (2022).** rho_z=0.860, sd_logz=0.542 reemplazan ENAHO GMM (0.485, 0.709). Benchmark debe re-correr.

## Restricciones duras (NO VIOLAR)

```
p_I < 1      ← bien informal más barato que formal
A_I < 1      ← PTF informal menor que formal
rho_z, sd_logz ← NO TOCAR. Valores de Hong (2022, J. Int. Economics)
                 rho_z = 0.8600132622 (0.963^4 trimestral → anual)
                 sd_logz = 0.5417411732 (0.146/sqrt(1-0.963²))
beta_I        ← NO TOCAR. Valores de Göbel et al. (2013, BCRP WP 2013-001)
                Sin K informal: beta_I = 0.60
                Con K informal, DRS: alpha_I=0.118, beta_I=0.605
                Con K informal, CRS: alpha_I=0.163, beta_I=0.837
nu_I          ← no muy pequeño. Benchmark usa 0.60. Margen: 0.4–0.8
alpha_I = 0   ← benchmark sin capital informal. PROBAR alpha_I>0
```

## Benchmark vigente (sin capital informal)

```
Nz=20, A_I=0.99, beta_I=0.60, nu_I=0.60, kappa_z1=0.110
psi_F=180, psi_I=50, omega_C=0.57, amin=-1.0
r_LO=-0.04, r_HI=0.15

p_I=0.979 ✓   T4=0.562 ✓   T5=0.131 ✗   Tkz=0.373 ✓   Tgasto=1.793 ≈
```

**Problema principal: T5 solo llega a 0.13 vs target 0.19.** Con `A_I<1` topeado en 0.99 y `p_I<1` casi en el borde (0.98), no hay más margen subiendo A_I o bajando omega_C.

## ⚠️ RECALIBRACIÓN HONG (2022) — 2026-06-21/22

Benchmark viejo (ENAHO GMM rho=0.485) NO funciona con Hong (rho=0.860). Ver `.planning/.continue-here.md` para bitácora completa.

### Diagnóstico del problema

Hong (rho=0.860, sd=0.542) da más persistencia que ENAHO GMM (rho=0.485, sd=0.709):
- Mayor ahorro precautorio → K sube → r* baja → w_F se dispara (~4.4 vs ~2.5 antes)
- w_F/w_I_hh ≈ 4.7 (ref BCR 2.30) → formal demasiado atractiva
- Producción informal colapsa → T5 baja de 0.13 a 0.07
- p_I cae de ~0.98 a ~0.45

### Corridas diagnóstico (Nz=14, fast debug, sin K informal)

| Run | psi_F | nu_I | omega_C | kappa_z1 | p_I | T4 | T5 | Tkz |
|-----|-------|------|---------|----------|-----|----|----|-----|
| om75_k110 | 180 | 0.60 | 0.75 | 0.110 | 0.45 | 0.50 | 0.067 | 0.114 |
| psif250 | 250 | 0.60 | 0.75 | 0.110 | 0.44 | 0.52 | 0.065 | 0.113 |
| nu04 | 180 | 0.40 | 0.75 | 0.110 | 0.45 | 0.50 | 0.067 | **0.163** |

- **T5 clavado en ~0.067** en todas las specs sin K informal — dominado por GE (w_F/w_I).
- **nu_I=0.40** subió Tkz de 0.11 a 0.16 (único parámetro que movió algo).
- **omega_C=0.75** deja p_I=0.45 → hay margen para bajarlo (subir demanda informal → subir p_I → subir T5 nominal).
- **psi_F** no ayuda: subirlo desvía horas a informal pero GE compensa (w_F sube más).

### Próximo: omega_C=0.65 + nu_I=0.40 (corriendo)

```matlab
HA_IE_REPLICATION_LOADED = true;
setenv('HA_IE_RUN_TAG', 'hong_nz14_om065_nu04');
setenv('HA_IE_OMEGA_C', '0.65');
setenv('HA_IE_NU_I', '0.40');
% ... resto igual
```

### Siguiente: DRS Göbel con K informal (corriendo)

```matlab
HA_IE_REPLICATION_LOADED = true;
setenv('HA_IE_RUN_TAG', 'hong_nz14_DRSGobel');
setenv('HA_IE_ALPHA_I', '0.118');
setenv('HA_IE_BETA_I', '0.605');
setenv('HA_IE_OMEGA_C', '0.65');
setenv('HA_IE_NU_I', '0.40');
```

## Tabla de escenarios (a llenar cuando terminen)

| Escenario | alpha_I | beta_I | omega_C | nu_I | p_I | T4 | T5 | Tkz | r* |
|-----------|---------|--------|---------|------|-----|----|----|-----|-----|
| A (sin K, om65) | 0.0 | 0.60 | 0.65 | 0.40 | ? | ? | ? | ? | ? |
| B (DRS Göbel) | 0.118 | 0.605 | 0.65 | 0.40 | ? | ? | ? | ? | ? |
| C (CRS Göbel) | 0.163 | 0.837 | — | — | — | — | — | — | — |

## Notas

- `Nz=7` y `Nz=14` convergen con Hong (a diferencia del benchmark viejo donde Nz=7 no convergía).
- Fast debug ahora demora ~16 min (vs ~7 min antes): ρ más alto → HJB requiere más iteraciones, más solves de GE (113+).
- `beta_I` NO SE TOCA. Valores Göbel fijos.
- `nu_I` margen 0.4–0.8. 0.40 mejora Tkz sin romper nada.
- Si T5 no llega a 0.19 ni con K informal → documentar como limitación estructural con Hong (2022).
