# Paper source record

- Title: *Informalidad y Distribución de Riqueza: Un Modelo de Agentes
  Heterogéneos con Oferta Laboral Endógena* — **Anexo Matemático**
- Authors: John Svante Barraza Ratachi and Enzo Andrés Nevado Martínez
  (advisor: César Saturnino Salinas Depaz)
- Audited version: Anexo Matemático v10 ARz DebtPrem, Junio 2026
- Replication package:
  https://github.com/johnbarraza/aiyagari-2firms-peru
- Audited artifact: `docs/anexo_matematico/anexo_matematico.tex`
- Audited TeX SHA-256:
  `2b7c3362e5845d109839829e8af95ec2453e20588b259efed69338a1ac7929ef`
- Companion annex PDF SHA-256:
  `65a07441e33b7c42d5b47c6793eddcde0c1af45022c4089543b9dc88405c5808`
- Main thesis document PDF SHA-256 (context only, not the audited artifact):
  `d82eebc3e5eccff6abcb1087f21d7f95021bed75ee8fd8c6898ae0e534e44262`
- Reference implementation cross-checked during the audit:
  `model_main.m` in the same replication package
  (closing run `outputs/stationary/test_AI098_cierre`)

The audited artifact is the mathematical annex, because that is where the
model's theoretical content is stated. The main thesis document and the MATLAB
solver were read as cross-checks and are named in the validation report where
they disagree with the annex.

## Estado de la fuente tras la revisión

La auditoría de este repositorio se realizó contra la versión del anexo cuyo
SHA-256 se fija arriba, `2b7c3362…7929ef`. Las correcciones que la
verificación identificó (Secciones 10 y 11 del reporte de validación) **fueron
aplicadas al anexo aguas arriba** en septiembre de 2026, produciendo:

- Anexo corregido, TeX SHA-256:
  `50f8847069a3a71a64966a69550f284834eb2c8ee25d8a700813cb0976942189`
- Anexo corregido, PDF SHA-256:
  `65c3aa371cfc7bc7140626c48fb6e9fda07a816419052aa8bdf927fcda8832c6`

El texto corregido **no ha sido re-auditado**. Las filas de revisión, el
expediente de defectos y el reporte de validación de este repositorio describen
la versión auditada original. Promover el trabajo a la versión corregida exige
una nueva pasada de intake contra el nuevo digest.

Source bytes are not committed to this repository. The audit artifacts retain
the paths, anchors, and digests needed to identify the exact source, and the
Lean project builds without those local bytes.
