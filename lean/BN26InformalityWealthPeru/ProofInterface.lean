import BN26InformalityWealthPeru.PaperInterface

/-!
# Proof Interface: Informalidad y Distribucion de Riqueza: Un Modelo de Agentes Heterogeneos con Oferta Laboral Endogena (Anexo Matematico)

This file contains exact-type proof endpoints for the transparent propositions
in `PaperInterface.lean`. It is not a human semantic-review surface: one source
claim is reviewed once, against its expanded `...Spec : Prop` declaration.
-/

namespace BN26InformalityWealthPeru

/--
Lean proof endpoint for `paper_ou_generator_rows_sum_zeroSpec`.

This theorem is intentionally outside `PaperInterface.lean`: Lean Meta checks
that it has exactly the transparent Spec type, while source-to-Lean semantic
review compares the raw source bundle only to that Spec.
-/
theorem paper_ou_generator_rows_sum_zero :
  paper_ou_generator_rows_sum_zeroSpec :=
  ou_generator_rows_sum_zero

/--
Lean proof endpoint for `paper_debt_premium_decreasing_in_productivitySpec`.

This theorem is intentionally outside `PaperInterface.lean`: Lean Meta checks
that it has exactly the transparent Spec type, while source-to-Lean semantic
review compares the raw source bundle only to that Spec.
-/
theorem paper_debt_premium_decreasing_in_productivity :
  paper_debt_premium_decreasing_in_productivitySpec :=
  debt_premium_decreasing_in_productivity

/--
Lean proof endpoint for `paper_ces_optimal_demand_ratioSpec`.

This theorem is intentionally outside `PaperInterface.lean`: Lean Meta checks
that it has exactly the transparent Spec type, while source-to-Lean semantic
review compares the raw source bundle only to that Spec.
-/
theorem paper_ces_optimal_demand_ratio :
  paper_ces_optimal_demand_ratioSpec :=
  ces_optimal_demand_ratio

/--
Lean proof endpoint for `paper_interior_labor_first_order_conditionSpec`.

This theorem is intentionally outside `PaperInterface.lean`: Lean Meta checks
that it has exactly the transparent Spec type, while source-to-Lean semantic
review compares the raw source bundle only to that Spec.
-/
theorem paper_interior_labor_first_order_condition :
  paper_interior_labor_first_order_conditionSpec :=
  interior_labor_first_order_condition

/--
Lean proof endpoint for `paper_binding_labor_kkt_monotone_and_cornersSpec`.

This theorem is intentionally outside `PaperInterface.lean`: Lean Meta checks
that it has exactly the transparent Spec type, while source-to-Lean semantic
review compares the raw source bundle only to that Spec.
-/
theorem paper_binding_labor_kkt_monotone_and_corners :
  paper_binding_labor_kkt_monotone_and_cornersSpec :=
  binding_labor_kkt_monotone_and_corners

/--
Lean proof endpoint for `paper_formal_firm_first_order_conditionsSpec`.

This theorem is intentionally outside `PaperInterface.lean`: Lean Meta checks
that it has exactly the transparent Spec type, while source-to-Lean semantic
review compares the raw source bundle only to that Spec.
-/
theorem paper_formal_firm_first_order_conditions :
  paper_formal_firm_first_order_conditionsSpec :=
  formal_firm_first_order_conditions

/--
Lean proof endpoint for `paper_informal_firm_profit_exhaustionSpec`.

This theorem is intentionally outside `PaperInterface.lean`: Lean Meta checks
that it has exactly the transparent Spec type, while source-to-Lean semantic
review compares the raw source bundle only to that Spec.
-/
theorem paper_informal_firm_profit_exhaustion :
  paper_informal_firm_profit_exhaustionSpec :=
  informal_firm_profit_exhaustion

/--
Lean proof endpoint for `paper_walras_formal_goods_marketSpec`.

This theorem is intentionally outside `PaperInterface.lean`: Lean Meta checks
that it has exactly the transparent Spec type, while source-to-Lean semantic
review compares the raw source bundle only to that Spec.
-/
theorem paper_walras_formal_goods_market :
  paper_walras_formal_goods_marketSpec :=
  walras_formal_goods_market

end BN26InformalityWealthPeru
