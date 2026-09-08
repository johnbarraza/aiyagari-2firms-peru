import Mathlib

/-!
# Paper-Facing Theorems: Informalidad y Distribucion de Riqueza: Un Modelo de Agentes Heterogeneos con Oferta Laboral Endogena (Anexo Matematico)

This file is the implementation theorem layer for the source paper. Keep
source-faithful definitions and theorem wrappers here, and expose only the
compact human-review subset in `PaperInterface.lean`.

During the statement-first phase, each exact paper-facing proposition lives in a
transparent `<name>Spec : Prop` declaration in `PaperInterface.lean`; the paired
theorem/lemma endpoint belongs in `ProofInterface.lean` and has exactly that
type. Add proof implementations here only after those specifications pass v11
raw-source-to-expanded-Spec review and recursive premise provenance audit. Before full closeout, the v11
realization audit independently binds pinned source atoms to the elaborated Spec
and accounts for the complete Lean closure; a proof hole or a declaration name
is never evidence for that correspondence.
-/

namespace BN26InformalityWealthPeru

/-! ## Internal analytic helpers

These are generic real-analysis facts, not paper claims. They carry no source
content of their own and exist only to keep the paper-facing proofs short.
-/

/-- Bernoulli surplus bound: on `0 ≤ t` the map `t ↦ S * t - S * t ^ q / q` with
`1 < q` is maximized at `t = 1`. This is the isoelastic-disutility optimality
step used by the household labor first-order condition. -/
lemma surplus_le_at_one {S q t : ℝ} (hS : 0 ≤ S) (hq : 1 < q) (ht : 0 ≤ t) :
    S * t - S * t ^ q / q ≤ S * (1 - 1 / q) := by
  have hq0 : (0:ℝ) < q := lt_trans one_pos hq
  have bern : 1 + q * (t - 1) ≤ t ^ q := by
    have h := one_add_mul_self_le_rpow_one_add (s := t - 1) (by linarith) (le_of_lt hq)
    simpa using h
  have key : 0 ≤ S / q * (t ^ q - (q * t - q + 1)) := by
    apply mul_nonneg (by positivity)
    linarith
  have hexp : S * (1 - 1 / q) - (S * t - S * t ^ q / q)
      = S / q * (t ^ q - (q * t - q + 1)) := by
    field_simp
    ring
  linarith [key, hexp]

/-- `x ^ (y - 1) * x = x ^ y` for a positive real base. -/
lemma rpow_sub_one_mul_self {x y : ℝ} (hx : 0 < x) : x ^ (y - 1) * x = x ^ y := by
  rw [← Real.rpow_add_one (ne_of_gt hx) (y - 1)]
  congr 1
  ring

/-- `x ^ (y - 1) = (x ^ (1 - y))⁻¹` for a positive real base. -/
lemma rpow_sub_one_eq_inv {x y : ℝ} (hx : 0 < x) : x ^ (y - 1) = (x ^ (1 - y))⁻¹ := by
  rw [← Real.rpow_neg hx.le]
  congr 1
  ring

/-! ## Paper claims

Each lemma below is stated exactly as the corresponding transparent
`...Spec : Prop` in `PaperInterface.lean`, so `ProofInterface.lean` can route
the proof endpoint by definitional unfolding.
-/

/-- Discretized Ornstein-Uhlenbeck generator: interior and reflecting-boundary
rows both sum to zero (Anexo Matematico, Section 2.2, Equation eq:Qz_construction). -/
theorem ou_generator_rows_sum_zero :
    ∀ (etaZ muLogZ x dx sigmaLogZ chi zeta psi : ℝ),
      0 < dx →
      chi = -(min (etaZ * (muLogZ - x)) 0) / dx
          + (2 * etaZ * sigmaLogZ ^ 2) / (2 * dx ^ 2) →
      zeta = max (etaZ * (muLogZ - x)) 0 / dx
          + (2 * etaZ * sigmaLogZ ^ 2) / (2 * dx ^ 2) →
      psi = -chi - zeta →
      chi + psi + zeta = 0 ∧ (psi + chi) + zeta = 0 ∧ chi + (psi + zeta) = 0 := by
  intro _ _ _ _ _ chi zeta psi _ _ _ hpsi
  subst hpsi
  refine ⟨by ring, by ring, by ring⟩

/-- The productivity-indexed debt premium is strictly decreasing in `z`
(Anexo Matematico, Section 3.2, Equation eq:debtprem). -/
theorem debt_premium_decreasing_in_productivity :
    ∀ (chi0 z1 etaChi zmin zmax : ℝ),
      0 < chi0 → 0 < z1 → 0 < etaChi → 0 < zmin → zmin < zmax →
      chi0 * (z1 / zmax) ^ etaChi < chi0 * (z1 / zmin) ^ etaChi := by
  intro chi0 z1 etaChi zmin zmax hchi0 hz1 heta hzmin hlt
  have hzmax : (0:ℝ) < zmax := hzmin.trans hlt
  have hinv : zmax⁻¹ < zmin⁻¹ :=
    inv_strictAntiOn (Set.mem_Ioi.mpr hzmin) (Set.mem_Ioi.mpr hzmax) hlt
  have hbase : z1 / zmax < z1 / zmin := by
    simpa [div_eq_mul_inv] using mul_lt_mul_of_pos_left hinv hz1
  have hrpow : (z1 / zmax) ^ etaChi < (z1 / zmin) ^ etaChi :=
    Real.rpow_lt_rpow (by positivity) hbase heta
  exact mul_lt_mul_of_pos_left hrpow hchi0

/-- CES consumption split: the demand ratio `xi` satisfies the price tangency
condition, and the aggregator factors through the CES deflator
(Anexo Matematico, Section 3.5, Equation eq:ces_foc). -/
theorem ces_optimal_demand_ratio :
    ∀ (omegaC sigmaC pI cI etaC xi : ℝ),
      0 < omegaC → omegaC < 1 → 1 < sigmaC → 0 < pI → 0 < cI →
      etaC = 1 - 1 / sigmaC →
      xi = (omegaC * pI / (1 - omegaC)) ^ sigmaC →
      pI * (omegaC * (xi * cI) ^ (etaC - 1)) = (1 - omegaC) * cI ^ (etaC - 1) ∧
        (omegaC * (xi * cI) ^ etaC + (1 - omegaC) * cI ^ etaC) ^ (1 / etaC)
          = (omegaC * xi ^ etaC + (1 - omegaC)) ^ (1 / etaC) * cI := by
  intro omegaC sigmaC pI cI etaC xi hw0 hw1 hs1 hpI hcI hetaC hxi
  have hs0 : (0:ℝ) < sigmaC := lt_trans one_pos hs1
  have hsne : sigmaC ≠ 0 := ne_of_gt hs0
  have hw1' : (0:ℝ) < 1 - omegaC := by linarith
  have hb : (0:ℝ) < omegaC * pI / (1 - omegaC) := by positivity
  have hxipos : (0:ℝ) < xi := by rw [hxi]; exact Real.rpow_pos_of_pos hb _
  have hetapos : (0:ℝ) < etaC := by
    rw [hetaC]
    have h : 1 / sigmaC < 1 := by rw [div_lt_one hs0]; exact hs1
    linarith
  have hetane : etaC ≠ 0 := ne_of_gt hetapos
  have hexp : sigmaC * (etaC - 1) = -1 := by
    rw [hetaC]
    field_simp
    ring
  have hxie : xi ^ (etaC - 1) = (1 - omegaC) / (omegaC * pI) := by
    rw [hxi, ← Real.rpow_mul hb.le, hexp, Real.rpow_neg_one]
    field_simp
  constructor
  · rw [Real.mul_rpow hxipos.le hcI.le, hxie]
    field_simp
  · have hfac : omegaC * (xi * cI) ^ etaC + (1 - omegaC) * cI ^ etaC
        = (omegaC * xi ^ etaC + (1 - omegaC)) * cI ^ etaC := by
      rw [Real.mul_rpow hxipos.le hcI.le]; ring
    have hA : (0:ℝ) ≤ omegaC * xi ^ etaC + (1 - omegaC) := by positivity
    rw [hfac, Real.mul_rpow hA (Real.rpow_nonneg hcI.le _),
      ← Real.rpow_mul hcI.le, mul_one_div_cancel hetane, Real.rpow_one]

/-- Interior sectoral labor supply: the isoelastic first-order condition holds,
the candidate is the global maximizer of the instantaneous surplus, and it is the
unique interior stationary point (Anexo Matematico, Section 3.6, Equation eq:foc_F). -/
theorem interior_labor_first_order_condition :
    ∀ (Va w psi phi lStar : ℝ),
      0 < Va → 0 < w → 0 < psi → 0 < phi →
      lStar = (Va * w / psi) ^ phi →
      psi * lStar ^ (1 / phi) = Va * w ∧
        (∀ l : ℝ, 0 ≤ l →
          Va * w * l - psi * l ^ (1 + 1 / phi) / (1 + 1 / phi)
            ≤ Va * w * lStar - psi * lStar ^ (1 + 1 / phi) / (1 + 1 / phi)) ∧
        (∀ l : ℝ, 0 < l → psi * l ^ (1 / phi) = Va * w → l = lStar) := by
  intro Va w psi phi lStar hVa hw hpsi hphi hlStar
  have hphine : phi ≠ 0 := ne_of_gt hphi
  have hpsine : psi ≠ 0 := ne_of_gt hpsi
  have hA : (0:ℝ) < Va * w := by positivity
  have hq : (0:ℝ) < Va * w / psi := by positivity
  have hlpos : (0:ℝ) < lStar := by rw [hlStar]; exact Real.rpow_pos_of_pos hq _
  have hlne : lStar ≠ 0 := ne_of_gt hlpos
  have hpow : lStar ^ (1 / phi) = Va * w / psi := by
    rw [hlStar, ← Real.rpow_mul hq.le, mul_one_div_cancel hphine, Real.rpow_one]
  have hfoc : psi * lStar ^ (1 / phi) = Va * w := by
    rw [hpow]; field_simp
  refine ⟨hfoc, ?_, ?_⟩
  · intro l hl
    have hqgt : (1:ℝ) < 1 + 1 / phi := by
      have h : (0:ℝ) < 1 / phi := by positivity
      linarith
    have hq0 : (0:ℝ) < 1 + 1 / phi := lt_trans one_pos hqgt
    have htnn : (0:ℝ) ≤ l / lStar := by positivity
    have hlt : l = lStar * (l / lStar) := by field_simp
    have hlq : l ^ (1 + 1 / phi) = lStar ^ (1 + 1 / phi) * (l / lStar) ^ (1 + 1 / phi) := by
      nth_rewrite 1 [hlt]
      rw [Real.mul_rpow hlpos.le htnn]
    have hlStarq : lStar ^ (1 + 1 / phi) = lStar * (Va * w / psi) := by
      rw [Real.rpow_add hlpos, Real.rpow_one, hpow]
    have hS : (0:ℝ) ≤ Va * w * lStar := by positivity
    have hmain := surplus_le_at_one (S := Va * w * lStar) (q := 1 + 1 / phi)
      (t := l / lStar) hS hqgt htnn
    have hL : Va * w * l - psi * l ^ (1 + 1 / phi) / (1 + 1 / phi)
        = Va * w * lStar * (l / lStar)
          - Va * w * lStar * (l / lStar) ^ (1 + 1 / phi) / (1 + 1 / phi) := by
      rw [hlq, hlStarq]
      field_simp
    have hR : Va * w * lStar - psi * lStar ^ (1 + 1 / phi) / (1 + 1 / phi)
        = Va * w * lStar * (1 - 1 / (1 + 1 / phi)) := by
      rw [hlStarq]
      field_simp
    rw [hL, hR]
    exact hmain
  · intro l hlp hfl
    have h2 : l ^ (1 / phi) = Va * w / psi := by
      rw [eq_div_iff hpsine, mul_comm]
      exact hfl
    have h3 := congrArg (fun y : ℝ => y ^ phi) h2
    simp only at h3
    rw [← Real.rpow_mul hlp.le, one_div, inv_mul_cancel₀ hphine, Real.rpow_one,
      ← hlStar] at h3
    exact h3

/-- Binding time-constraint case: the KKT residual is strictly increasing on
`[0, H]`, attains the stated endpoint values, and the two corner conditions hold
(Anexo Matematico, Section 3.6, Equation eq:kkt_binding). -/
theorem binding_labor_kkt_monotone_and_corners :
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
            rhs ≤ psiF * l ^ (1 / phi) - psiI * (H - l) ^ (1 / phi)) := by
  intro psiF psiI phi H rhs hF hI hphi hH
  have he : (0:ℝ) < 1 / phi := by positivity
  have hene : (1:ℝ) / phi ≠ 0 := ne_of_gt he
  have hzero : (0:ℝ) ^ (1 / phi) = 0 := Real.zero_rpow hene
  have hmono : StrictMonoOn
      (fun l : ℝ => psiF * l ^ (1 / phi) - psiI * (H - l) ^ (1 / phi))
      (Set.Icc 0 H) := by
    intro a ha b hb hab
    simp only
    have h1 : a ^ (1 / phi) < b ^ (1 / phi) := Real.rpow_lt_rpow ha.1 hab he
    have h2 : (H - b) ^ (1 / phi) < (H - a) ^ (1 / phi) :=
      Real.rpow_lt_rpow (by linarith [hb.2]) (by linarith) he
    nlinarith [mul_lt_mul_of_pos_left h1 hF, mul_lt_mul_of_pos_left h2 hI]
  have hv0 : psiF * (0 : ℝ) ^ (1 / phi) - psiI * (H - 0) ^ (1 / phi)
      = -(psiI * H ^ (1 / phi)) := by
    rw [hzero, sub_zero]; ring
  have hvH : psiF * H ^ (1 / phi) - psiI * (H - H) ^ (1 / phi)
      = psiF * H ^ (1 / phi) := by
    rw [sub_self, hzero]; ring
  refine ⟨hmono, hv0, hvH, ?_, ?_⟩
  · intro hrhs l hl
    have hmem : (H : ℝ) ∈ Set.Icc (0:ℝ) H := ⟨hH.le, le_refl H⟩
    have hle := hmono.monotoneOn hl hmem hl.2
    simp only at hle
    rw [hvH] at hle
    linarith
  · intro hrhs l hl
    have hmem : (0 : ℝ) ∈ Set.Icc (0:ℝ) H := ⟨le_refl 0, hH.le⟩
    have hle := hmono.monotoneOn hmem hl hl.1
    simp only at hle
    rw [hv0] at hle
    linarith

/-- Formal Cobb-Douglas firm with constant returns: the capital first-order
condition pins the capital-labor ratio and the product is exhausted by factor
payments (Anexo Matematico, Section 4.1, Equation eq:formal_foc). -/
theorem formal_firm_first_order_conditions :
    ∀ (AF alphaK r delta k wF : ℝ),
      0 < AF → 0 < alphaK → alphaK < 1 → 0 < r + delta → 0 < k →
      alphaK * AF * k ^ (alphaK - 1) = r + delta →
      wF = (1 - alphaK) * AF * k ^ alphaK →
      k = (alphaK * AF / (r + delta)) ^ (1 / (1 - alphaK)) ∧
        AF * k ^ alphaK - (r + delta) * k - wF = 0 := by
  intro AF alphaK r delta k wF hAF ha0 ha1 hrd hk hfoc hwF
  have h1a : (0:ℝ) < 1 - alphaK := by linarith
  have h1ane : (1:ℝ) - alphaK ≠ 0 := ne_of_gt h1a
  have hupos : (0:ℝ) < k ^ (1 - alphaK) := Real.rpow_pos_of_pos hk _
  have hune : k ^ (1 - alphaK) ≠ 0 := ne_of_gt hupos
  have hneg : k ^ (alphaK - 1) = (k ^ (1 - alphaK))⁻¹ := rpow_sub_one_eq_inv hk
  have hinv : alphaK * AF * (k ^ (1 - alphaK))⁻¹ = r + delta := by rw [← hneg]; exact hfoc
  have hmul : alphaK * AF = (r + delta) * k ^ (1 - alphaK) := by
    rw [← hinv]; field_simp
  have hkpow : k ^ (1 - alphaK) = alphaK * AF / (r + delta) := by
    rw [eq_div_iff (ne_of_gt hrd), mul_comm]
    exact hmul.symm
  constructor
  · rw [← hkpow, ← Real.rpow_mul hk.le, mul_one_div_cancel h1ane, Real.rpow_one]
  · have hshift : k ^ (alphaK - 1) * k = k ^ alphaK := rpow_sub_one_mul_self hk
    have hrk : (r + delta) * k = alphaK * AF * k ^ alphaK := by
      rw [← hfoc, mul_assoc, hshift]
    rw [hwF, hrk]
    ring

/-- Informal firm: the marginal-product conditions imply the residual-profit
identity, Euler exhaustion under constant returns, and the static informal
capital demand (Anexo Matematico, Section 4.2, Equation eq:PiI). -/
theorem informal_firm_profit_exhaustion :
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
            * LI ^ (betaI / (1 - alphaI))) := by
  intro AI alphaI betaI pI r delta KI LI YI wI PiI hAI ha0 hb0 hab hpI hrd hKI hLI
    hYI hwI hrdfoc hPiI
  have hbshift : LI ^ (betaI - 1) * LI = LI ^ betaI := rpow_sub_one_mul_self hLI
  have hashift : KI ^ (alphaI - 1) * KI = KI ^ alphaI := rpow_sub_one_mul_self hKI
  have hwl : wI * LI = pI * betaI * YI := by
    rw [hwI, hYI]
    calc pI * betaI * AI * KI ^ alphaI * LI ^ (betaI - 1) * LI
        = pI * betaI * AI * KI ^ alphaI * (LI ^ (betaI - 1) * LI) := by ring
      _ = pI * betaI * (AI * KI ^ alphaI * LI ^ betaI) := by rw [hbshift]; ring
  have hrk : (r + delta) * KI = pI * alphaI * YI := by
    rw [hrdfoc, hYI]
    calc pI * alphaI * AI * KI ^ (alphaI - 1) * LI ^ betaI * KI
        = pI * alphaI * AI * (KI ^ (alphaI - 1) * KI) * LI ^ betaI := by ring
      _ = pI * alphaI * (AI * KI ^ alphaI * LI ^ betaI) := by rw [hashift]; ring
  have hmain : PiI = (1 - alphaI - betaI) * pI * YI := by
    rw [hPiI, hwl, hrk]; ring
  refine ⟨hmain, ?_, ?_⟩
  · intro hcrs
    rw [hmain]
    have hz : 1 - alphaI - betaI = 0 := by linarith
    rw [hz]; ring
  · intro hapos
    have h1a : (0:ℝ) < 1 - alphaI := by linarith
    have h1ane : (1:ℝ) - alphaI ≠ 0 := ne_of_gt h1a
    have hupos : (0:ℝ) < KI ^ (1 - alphaI) := Real.rpow_pos_of_pos hKI _
    have hune : KI ^ (1 - alphaI) ≠ 0 := ne_of_gt hupos
    have hneg : KI ^ (alphaI - 1) = (KI ^ (1 - alphaI))⁻¹ := rpow_sub_one_eq_inv hKI
    have hinv : pI * alphaI * AI * (KI ^ (1 - alphaI))⁻¹ * LI ^ betaI = r + delta := by
      rw [← hneg]; exact hrdfoc.symm
    have hmul : pI * alphaI * AI * LI ^ betaI = (r + delta) * KI ^ (1 - alphaI) := by
      rw [← hinv]; field_simp
    have hrdne : r + delta ≠ 0 := ne_of_gt hrd
    have hKpow : KI ^ (1 - alphaI) = pI * alphaI * AI / (r + delta) * LI ^ betaI := by
      field_simp
      linear_combination -hmul
    have hbase : (0:ℝ) ≤ pI * alphaI * AI / (r + delta) := by positivity
    have hLb : (0:ℝ) ≤ LI ^ betaI := Real.rpow_nonneg hLI.le _
    calc KI = (KI ^ (1 - alphaI)) ^ (1 / (1 - alphaI)) := by
              rw [← Real.rpow_mul hKI.le, mul_one_div_cancel h1ane, Real.rpow_one]
      _ = (pI * alphaI * AI / (r + delta) * LI ^ betaI) ^ (1 / (1 - alphaI)) := by
              rw [hKpow]
      _ = (pI * alphaI * AI / (r + delta)) ^ (1 / (1 - alphaI))
            * (LI ^ betaI) ^ (1 / (1 - alphaI)) := Real.mul_rpow hbase hLb
      _ = (pI * alphaI * AI / (r + delta)) ^ (1 / (1 - alphaI))
            * LI ^ (betaI / (1 - alphaI)) := by
              rw [← Real.rpow_mul hLI.le]
              congr 2
              field_simp

/-- Walras law for the formal good: aggregating the household budget at zero
aggregate drift together with the government, firm and informal-good clearing
conditions leaves `Y_F = C_F + delta K + kappa payments + debt-premium payments`.
The printed identity of the annex holds exactly when the access-cost payments and
the informal capital depreciation vanish
(Anexo Matematico, Section 5.2, market clearing item (iii)). -/
theorem walras_formal_goods_market :
    ∀ (tau wF LF kappaCost wI LI PiI r K debtPrem T CF pI CI YF YI delta KF KI : ℝ),
      T = tau * wF * LF →
      YF = wF * LF + (r + delta) * KF →
      PiI = pI * YI - wI * LI - (r + delta) * KI →
      CI = YI →
      K = KF + KI →
      (1 - tau) * wF * LF - kappaCost + (wI * LI + PiI) + r * K - debtPrem + T
          - (CF + pI * CI) = 0 →
      YF = CF + delta * K + kappaCost + debtPrem ∧
        (YF = CF + delta * KF + debtPrem ↔ kappaCost + delta * KI = 0) := by
  intro tau wF LF kappaCost wI LI PiI r K debtPrem T CF pI CI YF YI delta KF KI
    hT hYF hPiI hCI hK hbudget
  subst hT; subst hYF; subst hPiI; subst hCI; subst hK
  constructor
  · linear_combination hbudget
  · constructor
    · intro h; linear_combination h - hbudget
    · intro h; linear_combination hbudget + h

end BN26InformalityWealthPeru
