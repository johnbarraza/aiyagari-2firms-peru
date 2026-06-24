# Indice de Documentos de Referencia — HA-IE v10 ARz

Cada parametro del modelo esta respaldado por al menos un documento. Este indice mapea parametro → fuente → archivo.

---

## Parametro → Fuente → Archivo

| Parametro | Valor | Fuente | Archivo |
|-----------|-------|--------|---------|
| `al` (capital share formal) | 0.636 | Cespedes, Aquije, Sanchez & Vera-Tudela (2014, BCRP REE-28) | `parametros_cobb_douglas_formal_informal_peru.md` (Seccion 2) |
| `d` (depreciacion) | 0.10 | Castillo & Rojas (BCRP REE-28) | `ree-28-castillo-rojas.pdf` |
| `Frisch` | 0.38 | Cespedes & Rendon (2012, BCRP WP 2012-017) | `parametros_cobb_douglas_formal_informal_peru.md` no contiene este — ver `CALIBRACION_CONTEXTO.md` |
| `alpha_I, beta_I` (informal) | 0/0.696, 0.163/0.837, 0.118/0.605 | Gobel, Grimm & Lay (2013, BCRP WP 2013-001) | `parametros_cobb_douglas_formal_informal_peru.md` (Seccion 3-5) |
| `rho_z, sd_logz` | 0.860, 0.542 | Hong (2022) "MPCs in an Emerging Economy", J. Int. Economics | ENAHO 2004-2016, quarterly ρ=0.963, sd(v)=0.146. Annualizados: ρ=0.963^4=0.860, sd=0.146/sqrt(1-0.963²)=0.542 |
| `tau` | 0.18 | Galindo et al. (2024, BCRP DT-005) | `galindo_wealth_informality.pdf` |
| Modelo HACT | — | Achdou et al. (2022) + Numerical Appendix | `HACT_Numerical_Appendix.md`, `Moll_teoria_HA.md` |
| Oferta laboral endogena | — | Moll (2018) | `labor_supply.md` |
| 2 sectores, CES | — | Restrepo-Echavarria (2025, EER R&R) | `restrepo_EER_R&R.pdf` |
| 2 firmas, 2 bienes | — | Horvath (2000, JME) | `horvath bussines cycles.pdf` |

---

## Documentos en esta carpeta

```
referencias/
  INDICE_REFERENCIAS.md                          ← este archivo
  parametros_cobb_douglas_formal_informal_peru.md ← Gobel + Cespedes params
  ree-28-castillo-rojas.pdf                       ← delta=0.10 Peru
  galindo_wealth_informality.pdf                  ← HACT Peru, tau=0.18
  Moll_teoria_HA.md                               ← Moll slides Parte I+II
  HACT_Numerical_Appendix.md                      ← FD, upwind, adjunto, KF
  labor_supply.md                                 ← oferta laboral endogena
  restrepo_EER_R&R.pdf                            ← 2 sectores, CES F/I
  horvath bussines cycles.pdf                     ← 2 firmas, 2 bienes EG
```

---

## Documentos externos (no en el paquete, obtenibles online)

| Documento | Donde encontrarlo |
|-----------|-------------------|
| Cespedes & Rendon (2012, BCRP WP 2012-017) | https://www.bcrp.gob.pe/publicaciones/documentos-de-trabajo.html |
| Gobel, Grimm & Lay (2013, BCRP WP 2013-001) | https://www.bcrp.gob.pe/publicaciones/documentos-de-trabajo.html |
| Hong (2022) "Income Dynamics in Peru" | Mimeo |
| Achdou et al. (2022) libro | Princeton University Press |
| Moll HACT codes | https://benjaminmoll.com/codes/ |

---

## Verificacion de datos Peru

| Dato | Valor | Fuente primaria | Verificable en |
|------|-------|-----------------|---------------|
| Empleo informal (extensivo) | 71.1% | INEI-ENAHO 2023 | INEI web |
| Empleo informal (intensivo, horas) | 55.7% | INEI Cuenta Satelite 2024 | `T4_data=0.557` |
| PBI informal nominal | 19.0% | INEI Cuenta Satelite 2024 | `T5_data=0.190` |
| Ratio salarial w_F/w_I | 2.30 | BCRP | `T1_ref=2.30` |
| Gap formalidad por educacion | 0.386 | EPEN 2025 | `Tkz_data=0.386` |
| Gasto F-dom/I-dom | 1.913 | ENAHO 2015-2019 panel | `Tgasto_tipo_data=1.913` |
| Gini riqueza | ~0.68 | WID / Credit Suisse | Chequeo externo |
