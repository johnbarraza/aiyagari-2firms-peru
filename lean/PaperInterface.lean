import BN26InformalityWealthPeru.MainTheorems
import BN26InformalityWealthPeru.Assumptions

/-!
# Human-Facing Paper Interface: Informalidad y Distribucion de Riqueza: Un Modelo de Agentes Heterogeneos con Oferta Laboral Endogena (Anexo Matematico)

This is the compact Lean file a human should read after formalization to check
whether the paper's definitions and named theorem statements were represented
correctly. Keep the row-level dashboard and LLM audit statements in this file
for every paper. Move implementation details, proof aliases, and bulky helper
lemmas behind imported modules such as `AuditInterface.lean`, but expose the
audited paper-facing statements directly here; do not use
`paper_interface.audit_surface_path`.

Rules for completing this file:

- Keep the paper's definitions/formatted objects first, in source order.
- Expose the actual paper formulas here; do not only point to generic library
  definitions or implementation witnesses.
- A material reusable `EconCSLib` primitive may remain a reference here only
  after `audit/library_semantic_review.json` records its exact bounded library
  declaration and an explicit byte-pinned paper-source connection. The
  dashboard and human-review packet show and source-check that declaration
  before the dependent Spec; a library name, docstring, or glossary is not a
  semantic bridge. Do not add a duplicate paper claim merely to restate it.
- If a named theorem needs a hypothesis that is not derived from earlier Lean
  declarations, declare that hypothesis in `Assumptions.lean` and list it in
  `status.json` `review_surface.assumption_names`.
- Then state the named results directly, with assumptions visible in each
  theorem signature by referencing named paper assumptions imported from
  `Assumptions.lean`.
- In the statement-first phase, write every complete source-facing statement as
  a transparent `<name>Spec : Prop` here, exactly once. Put the paired
  theorem/lemma of that exact type in `ProofInterface.lean`; its temporary
  proof body may be `by sorry` only in a private draft. This separation keeps
  the human semantic surface free of thin wrapper declarations.
- Before drafting that Lean surface, independently inventory every material
  source atom from exact pinned source quote bytes. Do not infer source atoms
  from declaration, binder, field, function, or source-map names.
- Run raw-source-to-expanded-Spec statement matching plus recursive
  premise/conclusion provenance on the skeleton. The semantic comparison uses
  only byte-pinned source quotes (and separately pinned source context) against
  the expanded transparent Spec; map summaries and proof wrappers are not
  semantic inputs. Then freeze each canonical Lean declaration-manifest digest.
- In the proof phase, replace the `ProofInterface.lean` `sorry` with a short
  proof that calls into `MainTheorems.lean` or lower proof files without
  changing the specification or theorem type. Any specification/type change
  invalidates the freeze and requires a fresh statement audit.
- At formalized closeout, complete the v11 realization receipt: Lean Meta checks
  the theorem has exactly the transparent Spec type; each source atom is bound
  to the elaborated Spec surface; closure traversal includes proof and instance
  arguments; and every material terminal has a source, approved correction or
  additional assumption, checked derivation, or version-pinned foundation
  disposition. No data, container, or identifier-based exemption is allowed.
- The transparent `...Spec` is the sole semantic-review target for its source
  claim. The paired theorem/lemma is a proof endpoint whose exact Spec type is
  verified by Lean Meta, not a duplicate source-to-Lean comparison row.
- Keep proof endpoints, exhaustive endpoint aliases, and proof-seam checks in
  `ProofInterface.lean`, implementation modules, or `ProofLedger.lean`, not
  here. Do not create new `PostPaperAudit.lean` or `AuditLedger.lean` files;
  those names are legacy.

## Named Results

Each entry has one semantic-review target (`Spec`) and one proof endpoint (the
paired theorem/lemma). The human dashboard and review packet present that pair
once rather than treating the two declarations as duplicate paper claims.

- `paper_ou_generator_rows_sum_zeroSpec` -> `paper_ou_generator_rows_sum_zero`: Generador OU discretizado: filas suman cero, Section 2.2, Equation eq:Qz_construction, anexo_matematico.tex:97.
- `paper_debt_premium_decreasing_in_productivitySpec` -> `paper_debt_premium_decreasing_in_productivity`: Prima de deuda estrictamente decreciente en la productividad, Section 3.2, Equation eq:debtprem, anexo_matematico.tex:148.
- `paper_ces_optimal_demand_ratioSpec` -> `paper_ces_optimal_demand_ratio`: Consumo CES optimo: ratio de demanda y deflactor, Section 3.5, Equation eq:ces_foc, anexo_matematico.tex:188.
- `paper_interior_labor_first_order_conditionSpec` -> `paper_interior_labor_first_order_condition`: Oferta laboral interior: condicion de primer orden y optimalidad global, Section 3.6, Equation eq:foc_F, anexo_matematico.tex:206.
- `paper_binding_labor_kkt_monotone_and_cornersSpec` -> `paper_binding_labor_kkt_monotone_and_corners`: Caso vinculante KKT: monotonia estricta y casos de esquina, Section 3.6, Equation eq:kkt_binding, anexo_matematico.tex:211.
- `paper_formal_firm_first_order_conditionsSpec` -> `paper_formal_firm_first_order_conditions`: Firma formal Cobb-Douglas CRS: CPO estaticas y agotamiento del producto, Section 4.1, Equation eq:formal_foc, anexo_matematico.tex:243.
- `paper_informal_firm_profit_exhaustionSpec` -> `paper_informal_firm_profit_exhaustion`: Firma informal: PMgL, demanda de capital y beneficio residual, Section 4.2, Equation eq:PiI, anexo_matematico.tex:268.
- `paper_walras_formal_goods_marketSpec` -> `paper_walras_formal_goods_market`: Vaciamiento del mercado de bien formal (Ley de Walras), Section 5.2, anexo_matematico.tex:302.
-/

namespace BN26InformalityWealthPeru

/--
Generador OU discretizado: filas suman cero

Paper statement: Con mu_i = eta (mu_logz - x_i), sigma^2_diff = 2 eta sigma_logz^2, chi_i = -min(mu_i,0)/Delta_x + sigma^2_diff/(2 Delta_x^2), zeta_i = max(mu_i,0)/Delta_x + sigma^2_diff/(2 Delta_x^2) y psi_i = -chi_i - zeta_i, se obtiene una matriz tridiagonal sparse Q_z con filas que suman cero. En los bordes (i=1, i=N_z), chi_1 y zeta_{N_z} se absorben en psi_1 y psi_{N_z} respectivamente (barreras reflectoras), de modo que las filas de borde tambien suman cero.

Source location: Section 2.2, Equation eq:Qz_construction, anexo_matematico.tex:97
Source status: pinned statement-spec transcription; independent source audit pending

This transparent proposition is the exact statement-audit target. It is not
proof evidence. Its exact-type proof endpoint is declared in
`ProofInterface.lean`, so this human-facing file presents the full semantic
proposition once. At closeout, source atoms must be independently inventoried
from pinned source quote bytes and bound to this elaborated proposition rather
than inferred from identifiers.
-/
def paper_ou_generator_rows_sum_zeroSpec : Prop :=
  ∀ (etaZ muLogZ x dx sigmaLogZ chi zeta psi : ℝ),
      0 < dx →
      chi = -(min (etaZ * (muLogZ - x)) 0) / dx
          + (2 * etaZ * sigmaLogZ ^ 2) / (2 * dx ^ 2) →
      zeta = max (etaZ * (muLogZ - x)) 0 / dx
          + (2 * etaZ * sigmaLogZ ^ 2) / (2 * dx ^ 2) →
      psi = -chi - zeta →
      chi + psi + zeta = 0 ∧ (psi + chi) + zeta = 0 ∧ chi + (psi + zeta) = 0

/--
Prima de deuda estrictamente decreciente en la productividad

Paper statement: La prima de deuda es chi(z) = chi_0 (z_1/z)^{eta_chi} con chi_0 = 0.02 y eta_chi = 1.0. La prima es mayor para agentes de baja productividad: chi(z_min) > chi(z_max).

Source location: Section 3.2, Equation eq:debtprem, anexo_matematico.tex:148
Source status: pinned statement-spec transcription; independent source audit pending

This transparent proposition is the exact statement-audit target. It is not
proof evidence. Its exact-type proof endpoint is declared in
`ProofInterface.lean`, so this human-facing file presents the full semantic
proposition once. At closeout, source atoms must be independently inventoried
from pinned source quote bytes and bound to this elaborated proposition rather
than inferred from identifiers.
-/
def paper_debt_premium_decreasing_in_productivitySpec : Prop :=
  ∀ (chi0 z1 etaChi zmin zmax : ℝ),
      0 < chi0 → 0 < z1 → 0 < etaChi → 0 < zmin → zmin < zmax →
      chi0 * (z1 / zmax) ^ etaChi < chi0 * (z1 / zmin) ^ etaChi

/--
Consumo CES optimo: ratio de demanda y deflactor

Paper statement: Con xi = (omega_C p_I/(1-omega_C))^{sigma_C} y eta_C = 1 - 1/sigma_C, el reparto optimo entre bien formal e informal satisface c_F = xi c_I, la condicion de tangencia p_I omega_C c_F^{eta_C-1} = (1-omega_C) c_I^{eta_C-1}, y el agregado CES se factoriza como C = K c_I con deflactor K = (omega_C xi^{eta_C} + (1-omega_C))^{1/eta_C}.

Source location: Section 3.5, Equation eq:ces_foc, anexo_matematico.tex:188
Source status: pinned statement-spec transcription; independent source audit pending

This transparent proposition is the exact statement-audit target. It is not
proof evidence. Its exact-type proof endpoint is declared in
`ProofInterface.lean`, so this human-facing file presents the full semantic
proposition once. At closeout, source atoms must be independently inventoried
from pinned source quote bytes and bound to this elaborated proposition rather
than inferred from identifiers.
-/
def paper_ces_optimal_demand_ratioSpec : Prop :=
  ∀ (omegaC sigmaC pI cI etaC xi : ℝ),
      0 < omegaC → omegaC < 1 → 1 < sigmaC → 0 < pI → 0 < cI →
      etaC = 1 - 1 / sigmaC →
      xi = (omegaC * pI / (1 - omegaC)) ^ sigmaC →
      pI * (omegaC * (xi * cI) ^ (etaC - 1)) = (1 - omegaC) * cI ^ (etaC - 1) ∧
        (omegaC * (xi * cI) ^ etaC + (1 - omegaC) * cI ^ etaC) ^ (1 / etaC)
          = (omegaC * xi ^ etaC + (1 - omegaC)) ^ (1 / etaC) * cI

/--
Oferta laboral interior: condicion de primer orden y optimalidad global

Paper statement: En el caso interior la oferta laboral no restringida es ell^{unc} = (dV_a v w/psi)^{phi}, donde w es el salario efectivo del sector y psi su desutilidad marginal. Equivalentemente, ell^{unc} iguala el beneficio marginal dV_a v w con el costo marginal psi ell^{1/phi} de la desutilidad psi ell^{1+1/phi}/(1+1/phi), y maximiza el excedente instantaneo del hogar sobre ell >= 0.

Source location: Section 3.6, Equation eq:foc_F, anexo_matematico.tex:206
Source status: pinned statement-spec transcription; independent source audit pending

This transparent proposition is the exact statement-audit target. It is not
proof evidence. Its exact-type proof endpoint is declared in
`ProofInterface.lean`, so this human-facing file presents the full semantic
proposition once. At closeout, source atoms must be independently inventoried
from pinned source quote bytes and bound to this elaborated proposition rather
than inferred from identifiers.
-/
def paper_interior_labor_first_order_conditionSpec : Prop :=
  ∀ (Va w psi phi lStar : ℝ),
      0 < Va → 0 < w → 0 < psi → 0 < phi →
      lStar = (Va * w / psi) ^ phi →
      psi * lStar ^ (1 / phi) = Va * w ∧
        (∀ l : ℝ, 0 ≤ l →
          Va * w * l - psi * l ^ (1 + 1 / phi) / (1 + 1 / phi)
            ≤ Va * w * lStar - psi * lStar ^ (1 + 1 / phi) / (1 + 1 / phi)) ∧
        (∀ l : ℝ, 0 < l → psi * l ^ (1 / phi) = Va * w → l = lStar)

/--
Caso vinculante KKT: monotonia estricta y casos de esquina

Paper statement: Cuando la restriccion ell_F + ell_I <= H_bar es vinculante, ell_F resuelve psi_F ell_F^{1/phi} - psi_I (H_bar - ell_F)^{1/phi} = dV_a v (w_F^{net} - w_I^{eff}). El lado izquierdo es estrictamente creciente en ell_F sobre [0, H_bar], vale -psi_I H_bar^{1/phi} en ell_F = 0 y psi_F H_bar^{1/phi} en ell_F = H_bar. Casos de esquina: ell_F = H_bar si el lado derecho es mayor o igual que psi_F H_bar^{1/phi}; ell_I = H_bar si el lado derecho es menor o igual que -psi_I H_bar^{1/phi}.

Source location: Section 3.6, Equation eq:kkt_binding, anexo_matematico.tex:211
Source status: pinned statement-spec transcription; independent source audit pending

This transparent proposition is the exact statement-audit target. It is not
proof evidence. Its exact-type proof endpoint is declared in
`ProofInterface.lean`, so this human-facing file presents the full semantic
proposition once. At closeout, source atoms must be independently inventoried
from pinned source quote bytes and bound to this elaborated proposition rather
than inferred from identifiers.
-/
def paper_binding_labor_kkt_monotone_and_cornersSpec : Prop :=
  ∀ (psiF psiI phi H rhs : ℝ),
      0 < psiF → 0 < psiI → 0 < phi → 0 < H →
      StrictMonoOn
          (fun l : ℝ => psiF * l ^ (1 / phi) - psiI * (H - l) ^ (1 / phi))
          (Set.Icc 0 H) ∧
        psiF * (0 : ℝ) ^ (1 / phi) - psiI * (H - 0) ^ (1 / phi)
          = -(psiI * H ^ (1 / phi)) ∧
        psiF * H ^ (1 / phi) - psiI * (H - H) ^ (1 / phi) = psiF * H ^ (1 / phi) ∧
        (psiF * H ^ (1 / phi) ≤ rhs →
          ∀ l ∈ Set.Icc (0 : ℝ) H,
            psiF * l ^ (1 / phi) - psiI * (H - l) ^ (1 / phi) ≤ rhs) ∧
        (rhs ≤ -(psiI * H ^ (1 / phi)) →
          ∀ l ∈ Set.Icc (0 : ℝ) H,
            rhs ≤ psiF * l ^ (1 / phi) - psiI * (H - l) ^ (1 / phi))

/--
Firma formal Cobb-Douglas CRS: CPO estaticas y agotamiento del producto

Paper statement: Para Y_F = A_F K_F^{alpha_K} L_F^{1-alpha_K}, las condiciones de primer orden estaticas dan k = K_F/L_F = (alpha_K A_F/(r+delta))^{1/(1-alpha_K)} y w_F = (1-alpha_K) A_F k^{alpha_K}. Con retornos constantes a escala el producto por unidad de trabajo se agota entre pagos a capital y trabajo.

Source location: Section 4.1, Equation eq:formal_foc, anexo_matematico.tex:243
Source status: pinned statement-spec transcription; independent source audit pending

This transparent proposition is the exact statement-audit target. It is not
proof evidence. Its exact-type proof endpoint is declared in
`ProofInterface.lean`, so this human-facing file presents the full semantic
proposition once. At closeout, source atoms must be independently inventoried
from pinned source quote bytes and bound to this elaborated proposition rather
than inferred from identifiers.
-/
def paper_formal_firm_first_order_conditionsSpec : Prop :=
  ∀ (AF alphaK r delta k wF : ℝ),
      0 < AF → 0 < alphaK → alphaK < 1 → 0 < r + delta → 0 < k →
      alphaK * AF * k ^ (alphaK - 1) = r + delta →
      wF = (1 - alphaK) * AF * k ^ alphaK →
      k = (alphaK * AF / (r + delta)) ^ (1 / (1 - alphaK)) ∧
        AF * k ^ alphaK - (r + delta) * k - wF = 0

/--
Firma informal: PMgL, demanda de capital y beneficio residual

Paper statement: Para Y_I = A_I K_I^{alpha_I} L_I^{beta_I} con alpha_I + beta_I <= 1, las condiciones de primer orden dan w_I = p_I beta_I A_I K_I^{alpha_I} L_I^{beta_I-1} y el costo de uso del capital iguala su producto marginal en valor. Entonces Pi_I = p_I Y_I - w_I L_I - (r+delta) K_I = (1 - alpha_I - beta_I) p_I Y_I; en el escenario de retornos constantes alpha_I + beta_I = 1 se obtiene Pi_I = 0 (agotamiento de Euler), y la demanda estatica de capital informal es K_I = (p_I alpha_I A_I/(r+delta))^{1/(1-alpha_I)} L_I^{beta_I/(1-alpha_I)}.

Source location: Section 4.2, Equation eq:PiI, anexo_matematico.tex:268
Source status: pinned statement-spec transcription; independent source audit pending

This transparent proposition is the exact statement-audit target. It is not
proof evidence. Its exact-type proof endpoint is declared in
`ProofInterface.lean`, so this human-facing file presents the full semantic
proposition once. At closeout, source atoms must be independently inventoried
from pinned source quote bytes and bound to this elaborated proposition rather
than inferred from identifiers.
-/
def paper_informal_firm_profit_exhaustionSpec : Prop :=
  ∀ (AI alphaI betaI pI r delta KI LI YI wI PiI : ℝ),
      0 < AI → 0 ≤ alphaI → 0 < betaI → alphaI + betaI ≤ 1 →
      0 < pI → 0 < r + delta → 0 < KI → 0 < LI →
      YI = AI * KI ^ alphaI * LI ^ betaI →
      wI = pI * betaI * AI * KI ^ alphaI * LI ^ (betaI - 1) →
      r + delta = pI * alphaI * AI * KI ^ (alphaI - 1) * LI ^ betaI →
      PiI = pI * YI - wI * LI - (r + delta) * KI →
      PiI = (1 - alphaI - betaI) * pI * YI ∧
        (alphaI + betaI = 1 → PiI = 0) ∧
        (0 < alphaI →
          KI = (pI * alphaI * AI / (r + delta)) ^ (1 / (1 - alphaI))
            * LI ^ (betaI / (1 - alphaI)))

/--
Vaciamiento del mercado de bien formal (Ley de Walras)

Paper statement: En el equilibrio estacionario, agregando la restriccion presupuestaria de los hogares con drift agregado nulo, junto con T = tau w_F L_F, el agotamiento del producto formal Y_F = w_F L_F + (r+delta) K_F, el beneficio informal Pi_I = p_I Y_I - w_I L_I - (r+delta) K_I, el vaciamiento del bien informal C_I = Y_I y el vaciamiento de activos K = K_F + K_I, el mercado del bien formal vacia. El anexo enuncia esta condicion como C_F + delta K_F + DebtPremPayments = Y_F.

Source location: Section 5.2, anexo_matematico.tex:302
Source status: pinned statement-spec transcription; independent source audit pending

This transparent proposition is the exact statement-audit target. It is not
proof evidence. Its exact-type proof endpoint is declared in
`ProofInterface.lean`, so this human-facing file presents the full semantic
proposition once. At closeout, source atoms must be independently inventoried
from pinned source quote bytes and bound to this elaborated proposition rather
than inferred from identifiers.
-/
def paper_walras_formal_goods_marketSpec : Prop :=
  ∀ (tau wF LF kappaCost wI LI PiI r K debtPrem T CF pI CI YF YI delta KF KI : ℝ),
      T = tau * wF * LF →
      YF = wF * LF + (r + delta) * KF →
      PiI = pI * YI - wI * LI - (r + delta) * KI →
      CI = YI →
      K = KF + KI →
      (1 - tau) * wF * LF - kappaCost + (wI * LI + PiI) + r * K - debtPrem + T
          - (CF + pI * CI) = 0 →
      YF = CF + delta * K + kappaCost + debtPrem ∧
        (YF = CF + delta * KF + debtPrem ↔ kappaCost + delta * KI = 0)

end BN26InformalityWealthPeru
