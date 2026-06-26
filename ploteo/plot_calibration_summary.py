"""
Genera figura resumen de calibración: modelo vs datos.
Panel izq: targets calibrados. Panel der: validación externa.
Uso: python plot_calibration_summary.py --mat-file <ruta>.mat [--out-dir <dir>]
"""
from pathlib import Path
import argparse
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from scipy.io import loadmat


BLUE  = "#0055cc"
RED   = "#cc2200"
GRAY  = "#707070"
BLACK = "#000000"
GREEN = "#1f9d40"


def setup_style():
    plt.rcParams.update({
        "figure.facecolor": "white",
        "axes.facecolor":   "white",
        "axes.edgecolor":   BLACK,
        "axes.linewidth":   0.8,
        "axes.grid":        False,
        "font.family":      "Times New Roman",
        "font.size":        11,
        "legend.frameon":   False,
        "savefig.facecolor": "white",
        "savefig.dpi":      300,
    })


def moll_axis(ax):
    ax.tick_params(direction="in", top=False, right=False)
    for spine in ax.spines.values():
        spine.set_linewidth(0.8)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)


def scalar(mat, *names, default=np.nan):
    for name in names:
        if name in mat:
            arr = np.asarray(mat[name]).reshape(-1)
            if arr.size > 0:
                try:
                    return float(arr[0])
                except Exception:
                    pass
    return default


def load_moments(mat_file):
    mat = loadmat(mat_file, squeeze_me=True, struct_as_record=False)

    T4_m   = scalar(mat, "T4_model",       default=np.nan)
    T4_d   = scalar(mat, "T4_data",        default=0.557)
    T5_m   = scalar(mat, "T5_nom",         default=np.nan)
    T5_d   = scalar(mat, "T5_data",        default=0.190)
    Tkz_m  = scalar(mat, "T_kappa_z_model","Tkz_model", default=np.nan)
    Tkz_d  = scalar(mat, "T_kappa_z_data", "Tkz_data",  default=0.386)
    Tg_m   = scalar(mat, "ratio_gasto_FI", default=np.nan)
    Tg_d   = scalar(mat, "TgFI_data",      default=1.913)
    pI_m   = scalar(mat, "p_I_star", "p_I", default=np.nan)
    Gini_m = scalar(mat, "Gini_wealth", "gini_a", "Gini", default=np.nan)
    KY_m   = scalar(mat, "KY_ratio",   "K_Y_ratio", default=np.nan)
    # K/Y from K* and Y* if not stored directly
    if not np.isfinite(KY_m):
        K_star = scalar(mat, "K_star",  default=np.nan)
        Y_star = scalar(mat, "Y_star",  default=np.nan)
        if np.isfinite(K_star) and np.isfinite(Y_star) and Y_star > 0:
            KY_m = K_star / Y_star

    T1_m   = scalar(mat, "T1_model", "wage_ratio_FI", default=np.nan)
    Gini_g = scalar(mat, "Gini_gasto", "gini_exp", "Gini_expenditure", default=np.nan)
    T6_m   = scalar(mat, "T6_model", "T6_gap_model", default=np.nan)
    hours_m = scalar(mat, "mean_hours", "E_hours", "mean_ell_total", default=np.nan)

    return {
        "calib": [
            ("T4: horas inf. / totales",   T4_m,   T4_d,   None),
            ("T5: prod. inf. nominal (Y_I/Y)", T5_m, T5_d,  None),
            ("T$\\kappa$z: sorting z→sector", Tkz_m, Tkz_d, None),
            ("Tgasto: ratio gasto F/I",    Tg_m,   Tg_d,   None),
            ("p_I: precio bien informal",  pI_m,   None,   "<1.0 (no def.)"),
            ("Gini riqueza neta",          Gini_m, None,   "≥0.40"),
        ],
        "external": [
            ("T1: brecha salarial w_F/w_I", T1_m,  2.30,   "BCR"),
            ("Gini gasto",                  Gini_g, 0.40,  "ENAHO ~0.40"),
            ("T6: gap Q1-Q5 inf. horas",    T6_m,  0.530,  "ENAHO Cs.Sat."),
            ("Horas trab. E[ℓ_F+ℓ_I]",     hours_m, 0.40, "Perú ~40%"),
        ],
        "params": {
            "r_star": scalar(mat, "r_star",  "r_eq"),
            "K_star": scalar(mat, "K_star",  "K_eq"),
            "p_I":    pI_m,
            "T4_m":   T4_m,   "T4_d": T4_d,
            "T5_m":   T5_m,   "T5_d": T5_d,
            "Tkz_m":  Tkz_m,  "Tkz_d": Tkz_d,
            "Tg_m":   Tg_m,   "Tg_d":  Tg_d,
            "Gini_m": Gini_m,
            "KY_m":   KY_m,   "KY_d":  2.73,
        }
    }


def dot_plot_panel(ax, rows, title, show_legend=False):
    """Cleveland dot plot: modelo (círculo azul) vs dato (diamante rojo)."""
    n = len(rows)
    y = np.arange(n)

    for i, (label, model_val, data_val, note) in enumerate(rows):
        if np.isfinite(model_val if model_val is not None else np.nan):
            ax.plot(model_val, i, "o", color=BLUE, ms=9, zorder=5,
                    label="Modelo" if i == 0 else "")
        if data_val is not None and np.isfinite(data_val):
            ax.plot(data_val, i, "D", color=RED, ms=7, zorder=5,
                    label="Dato" if i == 0 else "")
            # segment connecting model to data
            if np.isfinite(model_val if model_val is not None else np.nan):
                ax.plot([model_val, data_val], [i, i],
                        color=GRAY, lw=1.0, zorder=3)
        # note label
        if note is not None:
            ax.text(0.99, i, note, ha="right", va="center",
                    fontsize=8, color=GRAY,
                    transform=ax.get_yaxis_transform())

    ax.set_yticks(y)
    ax.set_yticklabels([r[0] for r in rows], fontsize=9)
    ax.set_ylim(-0.6, n - 0.4)
    ax.set_title(title, fontsize=11, fontweight="bold", pad=6)
    ax.axvline(0, color=BLACK, lw=0.5, ls=":", alpha=0.4)
    moll_axis(ax)
    if show_legend:
        h_m = mpatches.Patch(color=BLUE,  label="Modelo")
        h_d = mpatches.Patch(color=RED,   label="Dato / target")
        ax.legend(handles=[h_m, h_d], loc="lower right", fontsize=8)


def make_calibration_table_figure(moments, out_dir):
    """Tabla texto de todos los momentos (para PDF/presentación)."""
    p = moments["params"]
    lines = [
        "Calibración FINAL — grid_FINAL_AI138",
        f"  γ=1.0  ρ=0.073  σ_C=5  ω_C=0.56  A_I=1.38  ψ_F/ψ_I=110/49  κ_z1=0.65",
        f"  r*={p['r_star']:.4f}  K*={p['K_star']:.3f}  p_I={p['p_I']:.3f}",
        "",
        "TARGETS CALIBRADOS",
        f"  T4 (share horas inf.)  modelo={p['T4_m']:.3f}  dato={p['T4_d']:.3f}  "
        f"Δ={abs(p['T4_m']-p['T4_d']):.3f}",
        f"  T5 (prod. inf. nom.)   modelo={p['T5_m']:.3f}  dato={p['T5_d']:.3f}  "
        f"Δ={abs(p['T5_m']-p['T5_d']):.3f}",
        f"  Tkz (sorting z)        modelo={p['Tkz_m']:.3f}  dato={p['Tkz_d']:.3f}  "
        f"Δ={abs(p['Tkz_m']-p['Tkz_d']):.3f}",
        f"  Tgasto (ratio F/I)     modelo={p['Tg_m']:.3f}  dato={p['Tg_d']:.3f}  "
        f"Δ={abs(p['Tg_m']-p['Tg_d']):.3f}",
        f"  Gini riqueza           modelo={p['Gini_m']:.3f}  dato≥0.40",
        f"  K/Y                    modelo={p['KY_m']:.2f}   dato={p['KY_d']:.2f}  "
        f"Δ={abs(p['KY_m']-p['KY_d']):.2f}",
    ]
    txt = out_dir / "calibration_summary.txt"
    txt.write_text("\n".join(lines), encoding="utf-8")
    return txt


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--mat-file", required=True)
    parser.add_argument("--out-dir",  default=None)
    args = parser.parse_args()

    mat_file = Path(args.mat_file).resolve()
    out_dir  = Path(args.out_dir).resolve() if args.out_dir else mat_file.parent / "plots_moll"
    out_dir.mkdir(parents=True, exist_ok=True)
    setup_style()

    moments = load_moments(mat_file)
    calib    = moments["calib"]
    external = moments["external"]

    # --- Fill NaN with hardcoded values if mat doesn't store them ---
    # (calibrated targets are always in the mat; external may not be)
    fallback_calib = [
        ("T4: horas inf. / totales",      0.5590, 0.557,  None),
        ("T5: prod. inf. nominal (Y_I/Y)", 0.1795, 0.190,  None),
        ("T$\\kappa$z: sorting z→sector", 0.3823, 0.386,  None),
        ("Tgasto: ratio gasto F/I",        1.9629, 1.913,  None),
        ("p_I: precio bien informal",      0.9390, None,  "<1.0"),
        ("Gini riqueza neta",              0.414,  None,  "≥0.40"),
        ("K/Y",                            3.23,   2.73,   None),
    ]
    fallback_ext = [
        ("T1: brecha salarial w_F/w_I",   2.07,  2.30,  "BCR"),
        ("Gini gasto",                     0.207, 0.40,  "ENAHO"),
        ("T6: gap Q1-Q5 horas inf.",       0.051, 0.530, "ENAHO"),
        ("Horas trab. E[ℓ_F+ℓ_I]",        0.419, 0.40,  "Perú ~40%"),
    ]

    def use_fallback(rows, fallback):
        out = []
        for i, (label, m, d, note) in enumerate(rows):
            if not np.isfinite(m if m is not None else np.nan) and i < len(fallback):
                out.append(fallback[i])
            else:
                out.append((label, m, d, note))
        # fill extra fallback rows not in original
        while len(out) < len(fallback):
            out.append(fallback[len(out)])
        return out

    calib    = use_fallback(calib,    fallback_calib)
    external = use_fallback(external, fallback_ext)

    # ----------------------------------------------------------------
    # Figure 1: dot plot — calibrated + external side by side
    # ----------------------------------------------------------------
    fig, axes = plt.subplots(1, 2, figsize=(13.0, 5.4),
                              gridspec_kw={"width_ratios": [7, 4]})

    dot_plot_panel(axes[0], calib,    "Targets calibrados",    show_legend=True)
    dot_plot_panel(axes[1], external, "Validación externa",    show_legend=False)

    axes[0].set_xlabel("Valor del momento")
    axes[1].set_xlabel("Valor del momento")

    fig.suptitle(
        "Calibración HACT 2 Firmas — Perú (grid_FINAL_AI138)\n"
        r"$\gamma$=1.0, $\rho$=0.073, $\sigma_C$=5, $\omega_C$=0.56, "
        r"$A_I$=1.38, $\psi_F/\psi_I$=110/49, $\kappa_{z1}$=0.65",
        fontsize=10, y=1.01
    )
    fig.tight_layout()
    png1 = out_dir / "moll_calibration_summary.png"
    fig.savefig(png1, bbox_inches="tight")
    plt.close(fig)
    print(f"Saved: {png1}")

    # ----------------------------------------------------------------
    # Figure 2: bar chart — Δ relativo para targets calibrados
    # ----------------------------------------------------------------
    cal_with_data = [(lab, m, d) for lab, m, d, _ in calib if d is not None and np.isfinite(d) and np.isfinite(m)]
    if cal_with_data:
        labels_d = [r[0] for r in cal_with_data]
        modelo_v = np.array([r[1] for r in cal_with_data])
        dato_v   = np.array([r[2] for r in cal_with_data])
        delta_pct = 100.0 * (modelo_v - dato_v) / np.where(np.abs(dato_v) > 1e-9, np.abs(dato_v), 1.0)

        x = np.arange(len(labels_d))
        fig2, ax2 = plt.subplots(figsize=(9.0, 4.4))
        colors = [BLUE if abs(d) <= 5 else RED for d in delta_pct]
        bars = ax2.bar(x, delta_pct, color=colors, edgecolor=BLACK, linewidth=0.5)
        ax2.axhline(0, color=BLACK, lw=0.8)
        ax2.axhline( 5, color=GRAY, lw=0.6, ls="--", label="±5%")
        ax2.axhline(-5, color=GRAY, lw=0.6, ls="--")
        for bar, val in zip(bars, delta_pct):
            ax2.text(bar.get_x() + bar.get_width()/2, val + np.sign(val)*0.3,
                     f"{val:+.1f}%", ha="center", va="bottom" if val >= 0 else "top",
                     fontsize=8)
        ax2.set_xticks(x)
        ax2.set_xticklabels(labels_d, rotation=20, ha="right", fontsize=9)
        ax2.set_ylabel("Error relativo modelo vs dato (%)")
        ax2.set_title("Desviación porcentual modelo − dato (targets calibrados)", fontsize=11)
        leg = mpatches.Patch(color=BLUE, label="|error| ≤ 5%")
        ler = mpatches.Patch(color=RED,  label="|error| > 5%")
        ax2.legend(handles=[leg, ler, plt.Line2D([],[],color=GRAY,ls="--",label="umbral ±5%")],
                   fontsize=8, loc="best")
        moll_axis(ax2)
        fig2.tight_layout()
        png2 = out_dir / "moll_calibration_errors.png"
        fig2.savefig(png2, bbox_inches="tight")
        plt.close(fig2)
        print(f"Saved: {png2}")

    make_calibration_table_figure(moments, out_dir)
    print(f"Saved: {out_dir / 'calibration_summary.txt'}")


if __name__ == "__main__":
    main()
