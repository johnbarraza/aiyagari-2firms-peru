"""
3 tablas ordenadas: targets primarios, validación externa, parámetros.
Uso: python plot_calibration_tables.py --mat-file <ruta>.mat [--out-dir <dir>]
"""
from pathlib import Path
import argparse
import numpy as np
import matplotlib.pyplot as plt
from scipy.io import loadmat

BLUE  = "#0055cc"
RED   = "#cc2200"
GRAY  = "#707070"
BLACK = "#000000"
GREEN = "#1f9d40"


def setup_style():
    plt.rcParams.update({
        "figure.facecolor": "white", "axes.facecolor": "white",
        "axes.edgecolor": BLACK, "axes.linewidth": 0.8, "axes.grid": False,
        "font.family": "Times New Roman", "font.size": 11,
        "savefig.facecolor": "white", "savefig.dpi": 300,
    })


def scalar(mat, *names, default=np.nan):
    for name in names:
        if name in mat:
            arr = np.asarray(mat[name]).reshape(-1)
            if arr.size > 0:
                try: return float(arr[0])
                except: pass
    return default


def load_all(mat):
    T4_m   = scalar(mat, "T4_model", default=np.nan)
    T4_d   = scalar(mat, "T4_data",  default=0.557)
    T5_m   = scalar(mat, "T5_nom",   default=np.nan)
    T5_d   = scalar(mat, "T5_data",  default=0.190)
    Tkz_m  = scalar(mat, "T_kappa_z_model", "Tkz_model", default=np.nan)
    Tkz_d  = scalar(mat, "T_kappa_z_data",  "Tkz_data",  default=0.386)
    Tg_m   = scalar(mat, "ratio_gasto_FI", default=np.nan)
    Tg_d   = scalar(mat, "TgFI_data",      default=1.913)
    pI_m   = scalar(mat, "p_I_star", "p_I", default=np.nan)
    Gini_a = scalar(mat, "Gini_wealth", "gini_a", "Gini", default=np.nan)
    r_star = scalar(mat, "r_star", "r_eq", default=np.nan)
    K_star = scalar(mat, "K_star", "K_eq", default=np.nan)

    KY_m = scalar(mat, "KY_ratio", "K_Y_ratio", default=np.nan)
    if not np.isfinite(KY_m) and np.isfinite(K_star):
        Y_nom = scalar(mat, "Y_nominal", "GDP_nominal", default=np.nan)
        if np.isfinite(Y_nom) and Y_nom > 0:
            KY_m = K_star / Y_nom

    T1_m   = scalar(mat, "T1_model", "wage_ratio_FI", default=np.nan)
    Gini_g = scalar(mat, "Gini_c", "Gini_gasto", "gini_exp", default=np.nan)
    T6_m   = scalar(mat, "T6_model", "T6_model_avg_ratio", "T6_gap_model", default=np.nan)
    eF     = scalar(mat, "E_ellF",  default=np.nan)
    eI     = scalar(mat, "E_ellI",  default=np.nan)
    hours  = (eF + eI) if np.isfinite(eF) and np.isfinite(eI) else scalar(mat, "mean_hours", default=np.nan)
    debt_m = scalar(mat, "debt_share", "mass_debt", "debt_mass", default=np.nan)
    T4_ext = scalar(mat, "T4_ext", "T4_extensivo", default=np.nan)
    w_F    = scalar(mat, "w_F_star", "w_F_bruto", default=np.nan)
    w_I    = scalar(mat, "w_I_star", "w_I_marg", default=np.nan)
    w_I_hh = scalar(mat, "w_I_hh", "w_I_household", default=np.nan)
    # T1 = w_F / (w_I_hh * theta)
    theta_val = scalar(mat, "theta", default=1.0)
    if np.isfinite(w_F) and np.isfinite(w_I_hh) and w_I_hh > 0 and theta_val > 0:
        T1_m = w_F / (w_I_hh * theta_val)
    else:
        T1_m = scalar(mat, "T1_model", default=np.nan)

    return {
        "primary": [
            ("T4 — Share horas informales",           T4_m,  T4_d,  "ℓ_I/(ℓ_F+ℓ_I)"),
            ("T5 — PBI informal nominal",              T5_m,  T5_d,  "p_I·Y_I/(Y_F+p_I·Y_I)"),
            ("Tkz — Sorting formalidad por z",         Tkz_m, Tkz_d, "gap z_alto − z_bajo"),
            ("Tgasto — Ratio gasto F-dominante/I-dom", Tg_m,  Tg_d,  "E[gasto|ℓ_F>ℓ_I]/E[gasto|ℓ_I≥ℓ_F]"),
            ("p_I — Precio relativo informal",         pI_m,  None,  "< 1 (numerario formal)"),
            ("Gini riqueza neta",                      Gini_a, None, "≥ 0.40"),
        ],
        "secondary": [
            ("T1 — Brecha salarial w_F / w_I_hh",  T1_m,  2.30,  "BCR — ingreso mixto"),
            ("Gini gasto",                          Gini_g, 0.40, "ENAHO ~0.40"),
            ("T6 — Gap Q1−Q5 horas informales",     T6_m,  0.530, "ENAHO Cs. Sat."),
            ("E[ℓ_F+ℓ_I] — Horas trabajadas",      hours, 0.40, "Perú ~40%"),
            ("Masa con deuda a<0",                  debt_m,None,  "Fracción deudores"),
            ("T4 extensivo — frac(ℓ_I > ℓ_F)",     T4_ext, None, "% informal-dominantes"),
            ("K/Y — Capital / Producto",            KY_m,  2.73, "PWT 11.0"),
        ],
        "params": {
            "r*": r_star, "K*": K_star, "p_I": pI_m,
            "w_F": w_F, "w_I": w_I,
            "T4_m": T4_m, "T5_m": T5_m, "Tkz_m": Tkz_m, "Tg_m": Tg_m,
            "Gini_a": Gini_a, "Gini_g": Gini_g, "KY_m": KY_m,
            "T1_m": T1_m, "T6_m": T6_m, "hours": hours,
        }
    }


def draw_table(ax, title, headers, rows, col_widths=None):
    """Draw a clean table with model (blue) vs data (red) cells."""
    ax.axis("off")
    ax.set_title(title, fontsize=12, fontweight="bold", pad=4)

    n_rows = len(rows) + 1  # + header
    n_cols = len(headers)

    table_data = [headers] + rows
    tbl = ax.table(
        cellText=table_data,
        cellLoc="center",
        loc="center",
        colWidths=col_widths,
        bbox=[0.0, 0.02, 1.0, 0.86],
    )

    tbl.auto_set_font_size(False)
    tbl.set_fontsize(9)

    for (row, col), cell in tbl.get_celld().items():
        cell.set_edgecolor(BLACK)
        cell.set_linewidth(0.5)
        if row == 0:
            cell.set_facecolor("#e8e8e8")
            cell.set_text_props(weight="bold", fontsize=9)
        else:
            cell.set_facecolor("white")
        # Color code: model values in blue, data in red
        if col == 1 and row > 0:  # model column
            cell.get_text().set_color(BLUE)
        elif col == 2 and row > 0:  # data column
            cell.get_text().set_color(RED)


def make_primary_figure(data, out_dir):
    rows = []
    for label, m, d, note in data["primary"]:
        m_str = f"{m:.3f}" if np.isfinite(m) else "—"
        d_str = f"{d:.3f}" if d is not None and np.isfinite(d) else note if note else "—"
        rows.append([label, m_str, d_str])

    fig, ax = plt.subplots(figsize=(13.33, 3.0))
    draw_table(ax, "Targets Primarios — Modelo vs Dato (Perú)",
               ["Target", "Modelo", "Dato / Referencia"], rows,
               col_widths=[0.50, 0.20, 0.30])
    fig.tight_layout()
    png = out_dir / "moll_table_primary.png"
    fig.savefig(png, bbox_inches="tight")
    plt.close(fig)
    print(f"Saved: {png}")
    return png


def make_secondary_figure(data, out_dir):
    rows = []
    for label, m, d, note in data["secondary"]:
        m_str = f"{m:.3f}" if np.isfinite(m) else "—"
        if d is not None and np.isfinite(d):
            d_str = f"{d:.3f}"
        elif note:
            d_str = note
        else:
            d_str = "—"
        rows.append([label, m_str, d_str])

    fig, ax = plt.subplots(figsize=(13.33, 3.2))
    draw_table(ax, "Validación Externa — NO Calibrados",
               ["Validación", "Modelo", "Referencia / Dato"], rows,
               col_widths=[0.50, 0.20, 0.30])
    fig.tight_layout()
    png = out_dir / "moll_table_secondary.png"
    fig.savefig(png, bbox_inches="tight")
    plt.close(fig)
    print(f"Saved: {png}")
    return png


def make_params_figure(data, out_dir):
    p = data["params"]

    # Calibration parameters
    calib_params = [
        ("γ (risk aversion)",     "1.0",   "Log utilidad"),
        ("ρ (discount rate)",     "0.073", "→ K/Y, Gini"),
        ("σ_C (CES substitution)","5",     "Sweet spot"),
        ("ω_C (CES weight formal)","0.56", "→ p_I ≈ 0.94"),
        ("A_I (PTF informal)",    "1.38",  "→ T5 ≈ 0.18"),
        ("ψ_F / ψ_I",             "110 / 49", "→ T4 ≈ 0.56"),
        ("κ_z1 / shape",          "0.65 / 1.0", "→ Tkz ≈ 0.38"),
        ("Nz / Z_WIDTH",          "40 / 2.5", "Productividad"),
        ("amin / Frisch",         "-1.0 / 0.38", "Deuda / labor"),
    ]

    # Fixed parameters
    fixed_params = [
        ("al (capital share formal)",  "0.636", "Cespedes et al. 2014"),
        ("d (depreciation)",           "0.10",  "Castillo & Rojas"),
        ("α_I (capital informal)",     "0.118", "Göbel et al. 2013"),
        ("β_I (labor informal)",       "0.605", "Göbel et al. 2013"),
        ("ρ_z (persistence)",          "0.861", "Hong 2022"),
        ("sd(log z)",                  "0.544", "Hong 2022"),
        ("τ (income tax)",             "0.18",  "Perú IGV"),
        ("θ / ν_I",                    "1.0 / 0.6", "Normalización"),
    ]

    # Equilibrium
    eq_values = [
        (f"r* = {p['r*']:.4f}" if np.isfinite(p['r*']) else "r*", "", ""),
        (f"K* = {p['K*']:.2f}" if np.isfinite(p['K*']) else "K*", "", ""),
        (f"p_I = {p['p_I']:.3f}" if np.isfinite(p['p_I']) else "p_I", "", ""),
        (f"w_F = {p['w_F']:.2f}" if np.isfinite(p['w_F']) else "w_F", "", ""),
        (f"w_I = {p['w_I']:.2f}" if np.isfinite(p['w_I']) else "w_I", "", ""),
        (f"K/Y = {p['KY_m']:.2f}" if np.isfinite(p['KY_m']) else "K/Y", "", ""),
    ]

    fig, axes = plt.subplots(
        1, 3, figsize=(13.33, 4.2),
        gridspec_kw={"width_ratios": [1.05, 1.05, 0.35]},
    )

    # Panel 1: calibrated
    draw_table(axes[0], "Parámetros Calibrados",
               ["Parámetro", "Valor", "Rol"],
               calib_params, col_widths=[0.42, 0.22, 0.36])

    # Panel 2: fixed
    draw_table(axes[1], "Parámetros Fijos (Literatura)",
               ["Parámetro", "Valor", "Fuente"],
               fixed_params, col_widths=[0.42, 0.22, 0.36])

    # Panel 3: equilibrium
    axes[2].axis("off")
    axes[2].set_title("Equilibrio General", fontsize=12, fontweight="bold", pad=4)
    eq_text = "\n".join([f"{r[0]}" for r in eq_values])
    axes[2].text(0.03, 0.48, eq_text, fontsize=9, va="center", fontfamily="monospace",
                 linespacing=1.65)

    fig.tight_layout()
    png = out_dir / "moll_table_params.png"
    fig.savefig(png, bbox_inches="tight")
    plt.close(fig)
    print(f"Saved: {png}")
    return png


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--mat-file", required=True)
    parser.add_argument("--out-dir",  default=None)
    args = parser.parse_args()

    mat_file = Path(args.mat_file).resolve()
    out_dir  = Path(args.out_dir).resolve() if args.out_dir else mat_file.parent / "plots_python"
    out_dir.mkdir(parents=True, exist_ok=True)
    setup_style()

    mat  = loadmat(mat_file, squeeze_me=True, struct_as_record=False)
    data = load_all(mat)

    make_primary_figure(data, out_dir)
    make_secondary_figure(data, out_dir)
    make_params_figure(data, out_dir)


if __name__ == "__main__":
    main()
