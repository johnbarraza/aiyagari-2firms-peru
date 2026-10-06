"""Construye momentos mexicanos con la ENOE 2024-I.

Fuente oficial
https://www.inegi.org.mx/programas/enoe/15ymas/

EMP_PPAL clasifica el trabajo principal como informal (1) o formal (2).
HRSOCUP contiene horas trabajadas por semana. La ENOE no entrega en SDEM una
clasificacion precodificada equivalente para cada hora del trabajo secundario.
Por eso T4 asigna HRSOCUP a la condicion del trabajo principal y se reporta
esta limitacion junto al resultado.
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
import pandas as pd


ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "inputs" / "mexico" / "enoe_2024q1" / "raw" / "ENOE_SDEMT124.csv"
OUTPUT = ROOT / "inputs" / "mexico" / "moments_enoe_2024q1.json"


def weighted_mean(values: pd.Series, weights: pd.Series) -> float:
    valid = values.notna() & weights.notna() & (weights > 0)
    return float(np.average(values[valid], weights=weights[valid]))


def weighted_share(mask: pd.Series, weights: pd.Series) -> float:
    valid = mask.notna() & weights.notna() & (weights > 0)
    return float(np.average(mask[valid].astype(float), weights=weights[valid]))


def main() -> None:
    columns = [
        "r_def",
        "c_res",
        "eda",
        "clase2",
        "fac_tri",
        "emp_ppal",
        "anios_esc",
        "hrsocup",
        "ingocup",
        "ing_x_hrs",
    ]
    data = pd.read_csv(SOURCE, usecols=columns, encoding="latin1", low_memory=False)
    for column in columns:
        data[column] = pd.to_numeric(data[column], errors="coerce")

    employed = data.loc[
        data["r_def"].eq(0)
        & data["c_res"].isin([1, 3])
        & data["eda"].between(15, 98)
        & data["clase2"].eq(1)
        & data["emp_ppal"].isin([1, 2])
        & data["fac_tri"].gt(0)
    ].copy()
    employed["informal"] = employed["emp_ppal"].eq(1)
    employed["formal"] = employed["emp_ppal"].eq(2)

    person_informality = weighted_share(employed["informal"], employed["fac_tri"])

    hours = employed.loc[employed["hrsocup"].between(1, 168)].copy()
    hour_weights = hours["fac_tri"] * hours["hrsocup"]
    informal_hours = float(hour_weights[hours["informal"]].sum() / hour_weights.sum())

    low_education = employed.loc[employed["anios_esc"].between(0, 8)]
    university = employed.loc[employed["anios_esc"].between(16, 30)]
    formal_low = weighted_share(low_education["formal"], low_education["fac_tri"])
    formal_university = weighted_share(university["formal"], university["fac_tri"])
    formality_gap = formal_university - formal_low

    earners = employed.loc[
        employed["ing_x_hrs"].gt(0) & employed["ing_x_hrs"].lt(999_999)
    ].copy()
    hourly_formal = weighted_mean(
        earners.loc[earners["formal"], "ing_x_hrs"],
        earners.loc[earners["formal"], "fac_tri"],
    )
    hourly_informal = weighted_mean(
        earners.loc[earners["informal"], "ing_x_hrs"],
        earners.loc[earners["informal"], "fac_tri"],
    )

    result = {
        "country": "Mexico",
        "survey": "ENOE 2024-I, cuestionario ampliado",
        "sample_observations": int(len(employed)),
        "expanded_employment": float(employed["fac_tri"].sum()),
        "person_informality": person_informality,
        "T4_informal_hours_main_job_classification": informal_hours,
        "formality_low_education": formal_low,
        "formality_university": formal_university,
        "Tkz_education_formality_gap": formality_gap,
        "gross_hourly_wage_formal": hourly_formal,
        "gross_hourly_wage_informal": hourly_informal,
        "gross_hourly_wage_ratio": hourly_formal / hourly_informal,
        "T5_informal_gdp_official_2024": 0.254,
        "definitions": {
            "informal": "EMP_PPAL=1; formal is EMP_PPAL=2",
            "T4": "weighted informal hours divided by weighted total hours; hours inherit main-job status",
            "low_education": "ANIOS_ESC from 0 through 8, below completed secondary",
            "university": "ANIOS_ESC from 16 through 30",
            "Tkz": "formal person share among university minus formal person share among low education",
            "wage_ratio": "weighted arithmetic mean of positive hourly income, formal divided by informal",
        },
    }

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
