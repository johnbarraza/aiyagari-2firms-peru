import BN26InformalityWealthPeru.MainTheorems

/-!
# Extension Results: qué distingue este modelo del Aiyagari clásico

Los teoremas de `PaperInterface.lean` verifican la **consistencia interna** de las
ecuaciones del anexo. Este módulo verifica algo distinto: las propiedades que
hacen de este modelo una **extensión** del Aiyagari de una firma, y que sostienen
el mecanismo económico central de la tesis.

Ninguna de estas afirmaciones es un enunciado literal del documento fuente, de
modo que **ninguna es una fila de revisión fuente-a-Lean** ni cuenta para la
cobertura del anexo. Son consecuencias probadas, registradas en la Sección 9 del
reporte de validación. Dos de ellas (`ou_stationary_variance_matches_target` y
`ou_mean_reversion_reproduces_ar1_persistence`) sí tienen anclaje en el anexo,
Sección 2.1, y podrían promoverse a filas de revisión en una futura pasada de
intake.

Convención declarada: los dos resultados del proceso Ornstein-Uhlenbeck usan como
hecho clásico conocido que un proceso `dX = eta (mu - X) dt + s dW` tiene varianza
estacionaria `s^2/(2 eta)` y autocorrelación `exp(-eta * dt)` a rezago `dt`. Lo
que se verifica aquí es que la **parametrización elegida** por el anexo devuelve
exactamente los momentos objetivo; la teoría de ecuaciones diferenciales
estocásticas no se formaliza.
-/

namespace BN26InformalityWealthPeru

/-! ## B1. El Aiyagari clásico es un caso particular -/

/--
**Anidamiento del Aiyagari clásico de una firma.**

Apagar el sector informal colapsa el modelo al Aiyagari estándar con oferta
laboral endógena, sin necesidad de tomar límites:

* si la ventaja salarial informal es nula, las horas informales óptimas son cero;
* con trabajo informal nulo el producto informal es cero, y con producto cero el
  beneficio informal es cero, de modo que no queda nada que distribuir;
* con `omegaC = 1` el agregador CES colapsa al bien formal único, de modo que
  desaparecen el segundo bien y el precio relativo `p_I`;
* la condición de primer orden laboral que queda es exactamente la del modelo de
  una firma con desutilidad isoelástica.

Este es el sentido preciso en que el modelo de dos firmas **contiene** al clásico.
-/
theorem classical_aiyagari_nesting :
    ∀ (Va psiF psiI phi tau wF z omegaC etaC cF cI AI alphaI betaI KI LI pI PiI YI : ℝ),
      0 < Va → 0 < psiF → 0 < psiI → 0 < phi →
      0 < betaI → 0 < AI → 0 ≤ KI → 0 ≤ cF → 0 ≤ cI → etaC ≠ 0 →
      (Va * 0 / psiI) ^ phi = 0
      ∧ (LI = 0 → YI = AI * KI ^ alphaI * LI ^ betaI → YI = 0)
      ∧ (YI = 0 → PiI = (1 - alphaI - betaI) * pI * YI → PiI = 0)
      ∧ (omegaC = 1 → (omegaC * cF ^ etaC + (1 - omegaC) * cI ^ etaC) ^ (1 / etaC) = cF)
      ∧ (0 < (1 - tau) * wF * z →
          psiF * ((Va * ((1 - tau) * wF * z) / psiF) ^ phi) ^ (1 / phi)
            = Va * ((1 - tau) * wF * z)) := by
  intro Va psiF psiI phi tau wF z omegaC etaC cF cI AI alphaI betaI KI LI pI PiI YI
    hVa hpsiF hpsiI hphi hbI hAI hKI hcF hcI hetaC
  have hphine : phi ≠ 0 := ne_of_gt hphi
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  · rw [mul_zero, zero_div]
    exact Real.zero_rpow hphine
  · intro hLI hYI
    rw [hYI, hLI, Real.zero_rpow (ne_of_gt hbI), mul_zero]
  · intro hYI hPiI
    rw [hPiI, hYI]; ring
  · intro hw
    rw [hw]
    norm_num
    rw [← Real.rpow_mul hcF, mul_inv_cancel₀ hetaC, Real.rpow_one]
  · intro hw
    have hq : (0:ℝ) < Va * ((1 - tau) * wF * z) / psiF := by positivity
    rw [← Real.rpow_mul hq.le, mul_one_div_cancel hphine, Real.rpow_one]
    field_simp

/-! ## B2. El gradiente de informalidad emerge del modelo -/

/--
**Sorting monótono por productividad.**

Es el mecanismo central de la tesis, el que disciplina el target `Tkz`. Con la
barrera de acceso `kappa` decreciente en la productividad y ventaja comparativa
informal atenuada (`0 < nuI < 1`), el atractivo relativo del sector formal
`w_F^net(z) / w_I^eff(z)` es **estrictamente creciente en z**.

Tres conclusiones:

1. el atractivo relativo crece estrictamente con la productividad;
2. en el caso interior, la razón de horas formales a informales hereda esa
   monotonía, porque es una potencia positiva del atractivo relativo;
3. en el caso vinculante, la monotonía estricta del residuo KKT (verificada como
   fila de fuente) convierte un residuo mayor en horas formales estrictamente
   mayores.

La conclusión es condicional al multiplicador de riqueza `Va`: aísla el canal de
productividad manteniendo fija la valoración marginal de la riqueza. Esa es
exactamente la razón por la que el gradiente por **quintil de riqueza** (`T6`) no
se sigue de aquí y queda subestimado en la calibración.
-/
theorem productivity_sorting_monotone :
    ∀ (tau wF theta nuI kappa1 kappa2 z1 z2 psiF psiI phi : ℝ),
      0 < theta → 0 < nuI → nuI < 1 → 0 < (1 - tau) * wF →
      0 < z1 → z1 < z2 → 0 ≤ kappa2 → kappa2 ≤ kappa1 →
      0 < psiF → 0 < psiI → 0 < phi →
      ((1 - tau) * wF * z1 - kappa1) / (theta * z1 ^ nuI)
        < ((1 - tau) * wF * z2 - kappa2) / (theta * z2 ^ nuI)
      ∧ (0 < (1 - tau) * wF * z1 - kappa1 →
          (psiI / psiF * (((1 - tau) * wF * z1 - kappa1) / (theta * z1 ^ nuI))) ^ phi
            < (psiI / psiF * (((1 - tau) * wF * z2 - kappa2) / (theta * z2 ^ nuI))) ^ phi)
      ∧ (∀ (H lF1 lF2 : ℝ), 0 < H →
          lF1 ∈ Set.Icc (0:ℝ) H → lF2 ∈ Set.Icc (0:ℝ) H →
          psiF * lF1 ^ (1 / phi) - psiI * (H - lF1) ^ (1 / phi)
            < psiF * lF2 ^ (1 / phi) - psiI * (H - lF2) ^ (1 / phi) →
          lF1 < lF2) := by
  intro tau wF theta nuI kappa1 kappa2 z1 z2 psiF psiI phi
    hth hnu0 hnu1 hw hz1 hz12 hk2 hk21 hpsiF hpsiI hphi
  have hz2 : (0:ℝ) < z2 := hz1.trans hz12
  have hp1 : (0:ℝ) < z1 ^ nuI := Real.rpow_pos_of_pos hz1 _
  have hp2 : (0:ℝ) < z2 ^ nuI := Real.rpow_pos_of_pos hz2 _
  have hkey : z1 * z2 ^ nuI < z2 * z1 ^ nuI := by
    have h1 : z1 ^ (1 - nuI) < z2 ^ (1 - nuI) :=
      Real.rpow_lt_rpow hz1.le hz12 (by linarith)
    have e1 : z1 ^ (1 - nuI) * z1 ^ nuI = z1 := by
      rw [← Real.rpow_add hz1]; norm_num
    have e2 : z2 ^ (1 - nuI) * z2 ^ nuI = z2 := by
      rw [← Real.rpow_add hz2]; norm_num
    calc z1 * z2 ^ nuI = z1 ^ (1 - nuI) * (z1 ^ nuI * z2 ^ nuI) := by
          rw [← mul_assoc, e1]
      _ < z2 ^ (1 - nuI) * (z1 ^ nuI * z2 ^ nuI) :=
          mul_lt_mul_of_pos_right h1 (by positivity)
      _ = z2 * z1 ^ nuI := by
          rw [show z2 ^ (1 - nuI) * (z1 ^ nuI * z2 ^ nuI)
              = z2 ^ (1 - nuI) * z2 ^ nuI * z1 ^ nuI by ring, e2]
  have hzn : z1 ^ nuI < z2 ^ nuI := Real.rpow_lt_rpow hz1.le hz12 hnu0
  have hmain : ((1 - tau) * wF * z1 - kappa1) / (theta * z1 ^ nuI)
      < ((1 - tau) * wF * z2 - kappa2) / (theta * z2 ^ nuI) := by
    rw [div_lt_div_iff₀ (by positivity) (by positivity)]
    nlinarith [mul_pos hth (mul_pos hw (sub_pos.mpr hkey)),
      mul_nonneg hth.le (mul_nonneg hk2 (sub_nonneg.mpr hzn.le)),
      mul_nonneg hth.le (mul_nonneg (sub_nonneg.mpr hk21) hp2.le)]
  refine ⟨hmain, ?_, ?_⟩
  · intro hpos
    have hr1 : (0:ℝ) < ((1 - tau) * wF * z1 - kappa1) / (theta * z1 ^ nuI) := by positivity
    have hs : (0:ℝ) < psiI / psiF := by positivity
    exact Real.rpow_lt_rpow (by positivity) (mul_lt_mul_of_pos_left hmain hs) hphi
  · intro H lF1 lF2 hH h1 h2 hlt
    have he : (0:ℝ) < 1 / phi := by positivity
    have hmono : StrictMonoOn
        (fun l : ℝ => psiF * l ^ (1 / phi) - psiI * (H - l) ^ (1 / phi))
        (Set.Icc 0 H) := by
      intro a ha b hb hab
      simp only
      have g1 : a ^ (1 / phi) < b ^ (1 / phi) := Real.rpow_lt_rpow ha.1 hab he
      have g2 : (H - b) ^ (1 / phi) < (H - a) ^ (1 / phi) :=
        Real.rpow_lt_rpow (by linarith [hb.2]) (by linarith) he
      nlinarith [mul_lt_mul_of_pos_left g1 hpsiF, mul_lt_mul_of_pos_left g2 hpsiI]
    exact (hmono.lt_iff_lt h1 h2).mp hlt

/-! ## B3. El margen es intensivo, no extensivo -/

/--
**No hay salto de participación: la barrera es una cuña, no un costo fijo.**

Como `kappa` entra en el presupuesto multiplicando las horas formales
(`- kappa_F(a,z) * l_F`), y no como un costo fijo de entrada, la política laboral
es una función **continua** de la productividad: no existe un umbral en el que las
horas formales salten de cero a un valor positivo. Un modelo con margen extensivo
—costo fijo de participación— produciría exactamente ese salto.

La segunda conclusión da el umbral exacto de exclusión: las horas formales son
estrictamente positivas si y solo si la barrera es menor que el ingreso laboral
formal bruto por unidad de tiempo. Es decir, la barrera exógena puede excluir por
completo del sector formal a los tipos de baja productividad, y se sabe
exactamente cuándo.

Esto formaliza la limitación reconocida en la sección de limitaciones del
documento principal: el modelo captura el reasignamiento de horas, no la elección
ocupacional discreta.
-/
theorem intensive_margin_no_participation_jump :
    ∀ (Va psiF phi tau wF : ℝ) (kappaF : ℝ → ℝ),
      0 < Va → 0 < psiF → 0 < phi → Continuous kappaF →
      Continuous (fun z : ℝ => (Va * max ((1 - tau) * wF * z - kappaF z) 0 / psiF) ^ phi)
      ∧ (∀ z : ℝ,
          0 < (Va * max ((1 - tau) * wF * z - kappaF z) 0 / psiF) ^ phi
            ↔ kappaF z < (1 - tau) * wF * z) := by
  intro Va psiF phi tau wF kappaF hVa hpsiF hphi hk
  have hphine : phi ≠ 0 := ne_of_gt hphi
  constructor
  · apply Continuous.rpow_const
    · fun_prop
    · intro _; exact Or.inr hphi.le
  · intro z
    constructor
    · intro hpos
      by_contra hle
      push Not at hle
      have hmax : max ((1 - tau) * wF * z - kappaF z) 0 = 0 := max_eq_right (by linarith)
      rw [hmax, mul_zero, zero_div, Real.zero_rpow hphine] at hpos
      exact lt_irrefl 0 hpos
    · intro hlt
      have hmax : (0:ℝ) < max ((1 - tau) * wF * z - kappaF z) 0 :=
        lt_max_of_lt_left (by linarith)
      exact Real.rpow_pos_of_pos (by positivity) _

/-! ## B5. El AR(1) de ENAHO sobrevive la traducción a tiempo continuo -/

/--
**La difusión elegida reproduce exactamente la desviación estándar objetivo.**

El anexo escribe la difusión del proceso de log-productividad como
`sqrt(2 eta) * sigma_logz`. Usando la fórmula clásica de la varianza estacionaria
de un Ornstein-Uhlenbeck, `s^2 / (2 eta)`, esa elección devuelve exactamente
`sigma_logz^2`: la parametrización no es una aproximación, calza el momento
objetivo de forma exacta y para cualquier velocidad de reversión.
-/
theorem ou_stationary_variance_matches_target :
    ∀ (etaZ sigmaLogZ : ℝ), 0 < etaZ →
      (Real.sqrt (2 * etaZ) * sigmaLogZ) ^ 2 / (2 * etaZ) = sigmaLogZ ^ 2 := by
  intro etaZ sigmaLogZ hEta
  have h2 : (0:ℝ) < 2 * etaZ := by linarith
  have hsq : Real.sqrt (2 * etaZ) ^ 2 = 2 * etaZ := Real.sq_sqrt h2.le
  field_simp
  nlinarith [hsq]

/--
**El mapeo AR(1) anual a tiempo continuo reproduce la persistencia estimada.**

Con `eta = -log(rho_z)/dt`, la autocorrelación del Ornstein-Uhlenbeck a rezago
`dt`, que es `exp(-eta * dt)`, devuelve exactamente `rho_z`. La persistencia
estimada con ENAHO se conserva sin pérdida al pasar a tiempo continuo.
-/
theorem ou_mean_reversion_reproduces_ar1_persistence :
    ∀ (rhoZ dt : ℝ), 0 < rhoZ → 0 < dt →
      Real.exp (-(-Real.log rhoZ / dt) * dt) = rhoZ := by
  intro rhoZ dt hrho hdt
  have hdtne : dt ≠ 0 := ne_of_gt hdt
  have hsimp : -(-Real.log rhoZ / dt) * dt = Real.log rhoZ := by field_simp
  rw [hsimp, Real.exp_log hrho]

/--
**La normalización ex-post no es opcional.**

Si `log z` es normal de media cero y varianza `sigma_logz^2`, entonces
`E[z] = exp(sigma_logz^2 / 2)`, que es estrictamente mayor que uno para cualquier
dispersión no degenerada. Sin renormalizar, `E[z] = 1` sería falso y el nivel de
la productividad agregada quedaría sesgado hacia arriba.
-/
theorem lognormal_mean_normalization_is_necessary :
    ∀ (sigmaLogZ : ℝ), sigmaLogZ ≠ 0 → 1 < Real.exp (sigmaLogZ ^ 2 / 2) := by
  intro sigmaLogZ hne
  have hpos : (0:ℝ) < sigmaLogZ ^ 2 / 2 := by positivity
  have h := Real.add_one_le_exp (sigmaLogZ ^ 2 / 2)
  linarith

/-! ## B6. Homoteticidad del consumo CES -/

/--
**El agregador CES es homogéneo de grado uno.**

Escalar ambos consumos por un factor positivo escala el agregado por el mismo
factor. Es la propiedad que hace válida la factorización por el deflactor CES y,
con ella, que el reparto del gasto no dependa del nivel de gasto.
-/
theorem ces_homogeneous_of_degree_one :
    ∀ (omegaC etaC cF cI t : ℝ),
      0 ≤ cF → 0 ≤ cI → 0 < t → etaC ≠ 0 → 0 ≤ omegaC → omegaC ≤ 1 →
      (omegaC * (t * cF) ^ etaC + (1 - omegaC) * (t * cI) ^ etaC) ^ (1 / etaC)
        = t * (omegaC * cF ^ etaC + (1 - omegaC) * cI ^ etaC) ^ (1 / etaC) := by
  intro omegaC etaC cF cI t hcF hcI ht hetaC hw0 hw1
  have hA : (0:ℝ) ≤ omegaC * cF ^ etaC + (1 - omegaC) * cI ^ etaC := by
    have h1 : (0:ℝ) ≤ 1 - omegaC := by linarith
    positivity
  have hexp : omegaC * (t * cF) ^ etaC + (1 - omegaC) * (t * cI) ^ etaC
      = t ^ etaC * (omegaC * cF ^ etaC + (1 - omegaC) * cI ^ etaC) := by
    rw [Real.mul_rpow ht.le hcF, Real.mul_rpow ht.le hcI]; ring
  rw [hexp, Real.mul_rpow (Real.rpow_nonneg ht.le _) hA,
    ← Real.rpow_mul ht.le, mul_one_div_cancel hetaC, Real.rpow_one]

/--
**La composición de la canasta es la misma para todos los agentes.**

El ratio de gasto formal a gasto informal `c_F / (p_I c_I)` no depende del nivel
de consumo del hogar, y por lo tanto tampoco de su riqueza ni de su productividad:
vale `(omega_C/(1-omega_C))^{sigma_C} * p_I^{sigma_C - 1}` para todos. Es
exactamente el diagnóstico `TgFI_canasta` que imprime el solver, que hasta ahora
estaba afirmado en un comentario del código y no probado.
-/
theorem ces_basket_ratio_is_agent_independent :
    ∀ (omegaC sigmaC pI cI1 cI2 xi : ℝ),
      0 < omegaC → omegaC < 1 → 0 < pI → 0 < cI1 → 0 < cI2 →
      xi = (omegaC * pI / (1 - omegaC)) ^ sigmaC →
      (xi * cI1) / (pI * cI1) = (xi * cI2) / (pI * cI2)
      ∧ (xi * cI1) / (pI * cI1)
          = (omegaC / (1 - omegaC)) ^ sigmaC * pI ^ (sigmaC - 1) := by
  intro omegaC sigmaC pI cI1 cI2 xi hw0 hw1 hpI hc1 hc2 hxi
  have hw1' : (0:ℝ) < 1 - omegaC := by linarith
  have hratio : ∀ c : ℝ, 0 < c → (xi * c) / (pI * c) = xi / pI := by
    intro c hc
    field_simp
  refine ⟨by rw [hratio cI1 hc1, hratio cI2 hc2], ?_⟩
  rw [hratio cI1 hc1, hxi]
  have hsplit : (omegaC * pI / (1 - omegaC)) ^ sigmaC
      = (omegaC / (1 - omegaC)) ^ sigmaC * pI ^ sigmaC := by
    rw [show omegaC * pI / (1 - omegaC) = omegaC / (1 - omegaC) * pI by ring]
    exact Real.mul_rpow (by positivity) hpI.le
  rw [hsplit, Real.rpow_sub hpI, Real.rpow_one]
  field_simp

end BN26InformalityWealthPeru
