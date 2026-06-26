from pathlib import Path
import argparse

import numpy as np
import matplotlib.pyplot as plt
from scipy.io import loadmat
from scipy.stats import gaussian_kde


SCRIPT_DIR = Path(__file__).resolve().parent

BLUE = "#0000ff"
RED = "#ff0000"
GRAY = "#707070"
BLACK = "#000000"


def ces_split_from_ceff(c_eff, p_i, omega_c, eta_c, sigma_c):
    c_eff = np.maximum(np.real(c_eff), 1e-12)
    xi = (omega_c * p_i / max(1.0 - omega_c, 1e-12)) ** sigma_c
    kappa = (omega_c * xi**eta_c + (1.0 - omega_c)) ** (1.0 / eta_c)
    c_i = c_eff / kappa
    c_f = xi * c_i
    expenditure = c_f + p_i * c_i
    return c_f, c_i, expenditure


def weighted_quantile(x, w, probs):
    x = np.asarray(x).reshape(-1)
    w = np.asarray(w).reshape(-1)
    ok = np.isfinite(x) & np.isfinite(w) & (w > 0)
    x = x[ok]
    w = w[ok]
    if x.size == 0:
        return np.full(np.size(probs), np.nan)
    order = np.argsort(x)
    x = x[order]
    w = w[order]
    cw = np.cumsum(w) / np.sum(w)
    return np.interp(probs, cw, x)


def weighted_stats(x, w):
    x = np.asarray(x).reshape(-1)
    w = np.asarray(w).reshape(-1)
    ok = np.isfinite(x) & np.isfinite(w) & (w > 0)
    x = x[ok]
    w = w[ok]
    if x.size == 0:
        return {"mass": 0.0, "mean": np.nan, "sd": np.nan, "p10": np.nan, "p50": np.nan, "p90": np.nan}
    mass = float(np.sum(w))
    wn = w / mass
    mean = float(np.sum(wn * x))
    sd = float(np.sqrt(np.sum(wn * (x - mean) ** 2)))
    p10, p50, p90 = weighted_quantile(x, w, [0.10, 0.50, 0.90])
    return {"mass": mass, "mean": mean, "sd": sd, "p10": p10, "p50": p50, "p90": p90}


def setup_style():
    plt.rcParams.update(
        {
            "figure.facecolor": "white",
            "axes.facecolor": "white",
            "axes.edgecolor": BLACK,
            "axes.linewidth": 0.8,
            "axes.grid": False,
            "font.family": "Times New Roman",
            "font.size": 12,
            "legend.frameon": False,
            "savefig.facecolor": "white",
            "savefig.dpi": 300,
        }
    )


def moll_axis(ax):
    ax.tick_params(direction="in", top=True, right=True)
    for spine in ax.spines.values():
        spine.set_linewidth(0.8)


def plot_group_density(ax, x, w, mask, color, title, xlim):
    xg = x[mask]
    wg = w[mask]
    ok = np.isfinite(xg) & np.isfinite(wg) & (wg > 0)
    xg = xg[ok]
    wg = wg[ok]
    if xg.size == 0:
        ax.text(0.5, 0.5, "Sin masa", ha="center", va="center", transform=ax.transAxes)
        ax.set_title(title, fontsize=12, fontweight="normal")
        ax.set_xlabel("Gasto del modelo")
        ax.set_ylabel("Densidad")
        ax.set_xlim(xlim)
        moll_axis(ax)
        return

    bins = np.linspace(xlim[0], xlim[1], 36)
    ax.hist(xg, bins=bins, weights=wg, density=True, color=color, alpha=0.35, edgecolor=color)

    x_plot = np.linspace(xlim[0], xlim[1], 250)
    try:
        kde = gaussian_kde(xg, weights=wg)
        ax.plot(x_plot, kde(x_plot), color=BLACK, lw=1.6, label="KDE ponderada")
    except Exception:
        pass

    stats = weighted_stats(xg, wg)
    ax.axvline(stats["p50"], color=BLACK, lw=1.0, ls=":")
    ax.set_title(title, fontsize=12, fontweight="normal")
    ax.set_xlabel("Gasto del modelo")
    ax.set_ylabel("Densidad")
    ax.text(
        0.98,
        0.92,
        f"media={stats['mean']:.3f}\ndesv.est.={stats['sd']:.3f}\nmediana={stats['p50']:.3f}\nfracción={100*stats['mass']:.1f}%",
        ha="right",
        va="top",
        transform=ax.transAxes,
        fontsize=9,
    )
    ax.set_xlim(xlim)
    moll_axis(ax)


def parse_args():
    parser = argparse.ArgumentParser(description="Genera distribucion de gasto del modelo por formalidad.")
    parser.add_argument("--mat-file", required=True, help="Ruta al archivo .mat de resultados.")
    parser.add_argument("--out-dir", default=None, help="Directorio de salida (default: mismo dir que --mat-file/plots_moll).")
    return parser.parse_args()


def main():
    global OUT_DIR
    args = parse_args()
    mat_file = Path(args.mat_file).resolve()
    out_dir_arg = args.out_dir if args.out_dir is not None else str(mat_file.parent / "plots_moll")
    OUT_DIR = Path(out_dir_arg).resolve()
    setup_style()
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    mat = loadmat(mat_file, squeeze_me=True, struct_as_record=False)
    c = np.asarray(mat["c"])
    g = np.asarray(mat["g"])
    ell_f = np.asarray(mat["ell_F"])
    ell_i = np.asarray(mat["ell_I"])
    da = float(np.asarray(mat["da"]).reshape(-1)[0])
    p_i = float(np.asarray(mat.get("p_I_star", mat["p_I"])).reshape(-1)[0])
    omega_c = float(np.asarray(mat["omega_C"]).reshape(-1)[0])
    eta_c = float(np.asarray(mat["eta_C"]).reshape(-1)[0])
    sigma_c = float(np.asarray(mat["sigma_C"]).reshape(-1)[0])

    c_f, c_i, expenditure = ces_split_from_ceff(c, p_i, omega_c, eta_c, sigma_c)
    weights = (g * da).reshape(-1)
    weights = weights / max(float(np.sum(weights)), 1e-12)
    x = expenditure.reshape(-1)
    formal = (ell_f.reshape(-1) >= ell_i.reshape(-1))
    informal = ~formal
    total = np.ones_like(formal, dtype=bool)

    x_hi = weighted_quantile(x, weights, [0.995])[0]
    x_lo = max(0.0, weighted_quantile(x, weights, [0.001])[0])
    if not np.isfinite(x_hi) or x_hi <= x_lo:
        x_lo, x_hi = float(np.nanmin(x)), float(np.nanmax(x))
    xlim = (x_lo, x_hi)

    fig, axes = plt.subplots(1, 3, figsize=(15.0, 5.0), sharey=True)
    plot_group_density(axes[0], x, weights, formal, BLUE, "Formal dominante", xlim)
    plot_group_density(axes[1], x, weights, informal, RED, "Informal dominante", xlim)
    plot_group_density(axes[2], x, weights, total, GRAY, "Total", xlim)
    fig.text(
        0.5,
        0.01,
        "Figura: distribucion del gasto del modelo por formalidad dominante, desde el .mat de agentes heterogeneos",
        ha="center",
        va="bottom",
        fontsize=10,
        color=GRAY,
        fontstyle="italic",
    )
    fig.tight_layout(rect=[0.03, 0.10, 0.99, 0.98])

    png = OUT_DIR / "moll_model_gasto_distribution_by_formality.png"
    fig.savefig(png)
    plt.close(fig)

    txt = OUT_DIR / "moll_model_gasto_distribution_by_formality.txt"
    with txt.open("w", encoding="utf-8") as f:
        f.write("Model gasto distribution by dominant formality\n")
        f.write(f"source_mat={mat_file}\n")
        f.write("variable=expenditure=c_F+p_I*c_I reconstructed from C_eff using ces_split_from_Ceff_v10\n")
        f.write("classification=Formal if ell_F>=ell_I; Informal if ell_I>ell_F\n")
        f.write("group mass mean sd p10 p50 p90\n")
        for name, mask in [("formal_dominant", formal), ("informal_dominant", informal), ("total", total)]:
            st = weighted_stats(x[mask], weights[mask])
            f.write(
                f"{name} {st['mass']:.10f} {st['mean']:.10f} {st['sd']:.10f} "
                f"{st['p10']:.10f} {st['p50']:.10f} {st['p90']:.10f}\n"
            )
    print(png)
    print(txt)


if __name__ == "__main__":
    main()
