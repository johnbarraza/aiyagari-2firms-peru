from pathlib import Path
import argparse

import numpy as np
import matplotlib.pyplot as plt
from scipy.io import loadmat


SCRIPT_DIR = Path(__file__).resolve().parent

BLUE = "#0000ff"
RED = "#ff0000"
GRAY = "#707070"
GREEN = "#1f9d40"
BLACK = "#000000"


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
            "legend.frameon": True,
            "legend.edgecolor": BLACK,
            "savefig.facecolor": "white",
            "savefig.dpi": 300,
        }
    )


def moll_axis(ax):
    ax.tick_params(direction="in", top=True, right=True)
    for spine in ax.spines.values():
        spine.set_linewidth(0.8)


def annotate_stacked_percent(ax, x, bottom, values, total, color="white", min_height=0.045):
    total = np.maximum(np.asarray(total), 1e-12)
    for i, val in enumerate(values):
        share = val / total[i]
        if val < min_height:
            continue
        ax.text(
            x[i],
            bottom[i] + val / 2.0,
            f"{100 * share:.0f}%",
            ha="center",
            va="center",
            fontsize=8,
            color=color,
        )


def caption(fig, text):
    fig.text(0.5, 0.01, text, ha="center", va="bottom", fontsize=10, color=GRAY, fontstyle="italic")


def scalar(mat, name, default=np.nan):
    if name not in mat:
        return default
    arr = np.asarray(mat[name]).reshape(-1)
    if arr.size == 0:
        return default
    try:
        return float(arr[0])
    except Exception:
        return default


def matrix(mat, name, shape, default=0.0):
    if name not in mat:
        return np.full(shape, default)
    arr = np.asarray(mat[name])
    if arr.shape != shape:
        return np.full(shape, default)
    return arr


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


def weighted_mean(x, w):
    x = np.asarray(x)
    w = np.asarray(w)
    ok = np.isfinite(x) & np.isfinite(w) & (w > 0)
    if not np.any(ok):
        return np.nan
    return float(np.sum(x[ok] * w[ok]) / np.sum(w[ok]))


def weighted_sd(x, w):
    x = np.asarray(x)
    w = np.asarray(w)
    ok = np.isfinite(x) & np.isfinite(w) & (w > 0)
    if not np.any(ok):
        return np.nan
    mean = np.sum(x[ok] * w[ok]) / np.sum(w[ok])
    return float(np.sqrt(np.sum(w[ok] * (x[ok] - mean) ** 2) / np.sum(w[ok])))


def weighted_pdf(x, w, bins=70, xlim=None):
    x = np.asarray(x).reshape(-1)
    w = np.asarray(w).reshape(-1)
    ok = np.isfinite(x) & np.isfinite(w) & (w > 0)
    x = x[ok]
    w = w[ok]
    if x.size == 0:
        return np.array([]), np.array([])
    if xlim is None:
        lo, hi = weighted_quantile(x, w, [0.005, 0.995])
    else:
        lo, hi = xlim
    if not np.isfinite(lo) or not np.isfinite(hi) or hi <= lo:
        lo, hi = float(np.nanmin(x)), float(np.nanmax(x))
    edges = np.linspace(lo, hi, bins + 1)
    hist, edges = np.histogram(x, bins=edges, weights=w, density=True)
    mids = 0.5 * (edges[:-1] + edges[1:])
    return mids, hist


def load_model(mat_file):
    mat = loadmat(mat_file, squeeze_me=True, struct_as_record=False)
    a = np.asarray(mat["a"]).reshape(-1)
    z = np.asarray(mat["z"]).reshape(-1)
    g = np.asarray(mat["g"])
    c = np.asarray(mat["c"])
    ell_f = np.asarray(mat["ell_F"])
    ell_i = np.asarray(mat["ell_I"])
    da = scalar(mat, "da")
    p_i = scalar(mat, "p_I_star", scalar(mat, "p_I", 1.0))
    c_f, c_i, expenditure = ces_split_from_ceff(
        c,
        p_i,
        scalar(mat, "omega_C", 0.5),
        scalar(mat, "eta_C", 0.5),
        scalar(mat, "sigma_C", 1.0),
    )
    return mat, a, z, g, c, c_f, c_i, expenditure, ell_f, ell_i, da


def income_components(mat, a, z, g, expenditure, ell_f, ell_i):
    i_count, n_z = g.shape
    aa = a[:, None] * np.ones((1, n_z))
    zz = np.ones((i_count, 1)) * z[None, :]

    w_f = scalar(mat, "w_F_star", scalar(mat, "w_F", 0.0))
    w_i_hh = scalar(mat, "w_I_household_star", scalar(mat, "w_I_star", scalar(mat, "w_I", 0.0)))
    theta = scalar(mat, "theta", 1.0)
    nu_i = scalar(mat, "nu_I", 1.0)
    tau = scalar(mat, "tau", 0.0)
    r_star = scalar(mat, "r_star", scalar(mat, "r_eq", 0.0))
    transfer = scalar(mat, "T_star", scalar(mat, "T_eq", scalar(mat, "T", 0.0)))
    pi_lump = scalar(mat, "Pi_lump_star", 0.0)
    if not np.isfinite(pi_lump):
        pi_lump = scalar(mat, "profit_I_star", 0.0)

    kappa = matrix(mat, "kappa_F_aa", g.shape, 0.0)
    q_inf = matrix(mat, "qq_informal", g.shape, 1.0)
    debt_spread = matrix(mat, "debt_spread_aa", g.shape, 0.0)

    formal = ((1.0 - tau) * w_f * zz - kappa) * ell_f
    informal = w_i_hh * theta * (zz**nu_i) * q_inf * ell_i
    capital = r_star * aa
    transfers = (transfer + pi_lump) * np.ones_like(g)
    debt_cost = -debt_spread * np.maximum(-aa, 0.0)
    net_income = formal + informal + capital + transfers + debt_cost
    savings = net_income - expenditure

    return {
        "formal": formal,
        "informal": informal,
        "capital": capital,
        "transfer": transfers,
        "debt_cost": debt_cost,
        "net_income": net_income,
        "savings": savings,
    }


def zoom_limits(a, g, da):
    w_a = np.maximum(np.sum(g, axis=1), 0.0) * da
    q = weighted_quantile(a, w_a, [0.01, 0.99])
    if np.any(~np.isfinite(q)) or q[1] <= q[0]:
        return float(np.min(a)), float(np.max(a))
    return float(q[0]), float(q[1])


def save_savings_wealth_figures(a, z, g, da, savings):
    j_low = 0
    j_mid = len(z) // 2
    j_high = len(z) - 1
    xlo, xhi = zoom_limits(a, g, da)

    fig, ax = plt.subplots(figsize=(7.6, 5.4))
    ax.plot(a, savings[:, j_low], color=BLUE, lw=2.1, label=f"s(a,z bajo={z[j_low]:.2f})")
    ax.plot(a, savings[:, j_high], color=RED, lw=2.1, ls="--", label=f"s(a,z alto={z[j_high]:.2f})")
    ax.axhline(0, color=BLACK, lw=0.8, ls=":")
    ax.axvline(0, color=BLACK, lw=0.8, ls=":")
    ax.set_xlim(xlo, xhi)
    ax.set_xlabel("Riqueza, a")
    ax.set_ylabel("Ahorro, s(a,z)")
    ax.legend(loc="best")
    moll_axis(ax)
    caption(fig, "Figura: politica de ahorro por productividad")
    fig.tight_layout(rect=[0.04, 0.08, 0.99, 0.98])
    savings_png = OUT_DIR / "moll_savings_policy.png"
    fig.savefig(savings_png)
    plt.close(fig)

    fig, ax = plt.subplots(figsize=(7.6, 5.4))
    for j, color, style, label in [
        (j_low, BLUE, "-", f"Densidad g(a | z bajo={z[j_low]:.2f})"),
        (j_mid, GRAY, "-", f"Densidad g(a | z mediano={z[j_mid]:.2f})"),
        (j_high, RED, "--", f"Densidad g(a | z alto={z[j_high]:.2f})"),
    ]:
        mass_j = np.sum(g[:, j]) * da
        density = g[:, j] / max(mass_j, 1e-12)
        density_display = density / max(np.nanmax(density), 1e-12)
        ax.plot(a, density_display, color=color, ls=style, lw=2.0, label=label)
    ax.axvline(0, color=BLACK, lw=0.8, ls=":")
    ax.set_xlim(xlo, xhi)
    ax.set_ylim(0, 1.05)
    ax.set_xlabel("Riqueza, a")
    ax.set_ylabel("Densidad condicional normalizada")
    ax.legend(loc="upper right", fontsize=8)
    moll_axis(ax)
    caption(fig, "Figura: distribucion estacionaria de riqueza por productividad")
    fig.tight_layout(rect=[0.04, 0.08, 0.99, 0.98])
    wealth_png = OUT_DIR / "moll_wealth_distribution_by_z.png"
    fig.savefig(wealth_png)
    plt.close(fig)

    return savings_png, wealth_png


def save_time_use_figures(z, g, da, ell_f, ell_i, mat):
    h_bar = scalar(mat, "H_bar", 1.0)
    mean_f = np.zeros(len(z))
    mean_i = np.zeros(len(z))
    mean_o = np.zeros(len(z))
    for j in range(len(z)):
        mass_j = np.sum(g[:, j]) * da
        mean_f[j] = np.sum(g[:, j] * ell_f[:, j]) * da / max(mass_j, 1e-12)
        mean_i[j] = np.sum(g[:, j] * ell_i[:, j]) * da / max(mass_j, 1e-12)
        mean_o[j] = max(h_bar - mean_f[j] - mean_i[j], 0.0)

    x = np.arange(len(z))
    labels = [f"{val:.2f}" for val in z]

    fig, ax = plt.subplots(figsize=(10.8, 5.2))
    ax.bar(x, mean_f, color=BLUE, edgecolor=BLACK, linewidth=0.4, label="Formal")
    ax.bar(x, mean_i, bottom=mean_f, color=RED, edgecolor=BLACK, linewidth=0.4, label="Informal")
    ax.bar(x, mean_o, bottom=mean_f + mean_i, color=GRAY, edgecolor=BLACK, linewidth=0.4, label="Ocio")
    total_time = mean_f + mean_i + mean_o
    annotate_stacked_percent(ax, x, np.zeros_like(mean_f), mean_f, total_time, color="white")
    annotate_stacked_percent(ax, x, mean_f, mean_i, total_time, color="white")
    annotate_stacked_percent(ax, x, mean_f + mean_i, mean_o, total_time, color="black")
    ax.axhline(h_bar, color=BLACK, lw=0.8, ls=":")
    ax.set_xticks(x, labels, rotation=0)
    ax.set_xlabel("Productividad, z")
    ax.set_ylabel("Uso medio del tiempo")
    ax.legend(loc="best")
    moll_axis(ax)
    caption(fig, "Figura: uso del tiempo por productividad")
    fig.tight_layout(rect=[0.03, 0.08, 0.99, 0.98])
    png1 = OUT_DIR / "moll_time_use_by_z_with_leisure.png"
    fig.savefig(png1)
    plt.close(fig)

    worked = np.maximum(mean_f + mean_i, 1e-12)
    share_f = mean_f / worked
    share_i = mean_i / worked
    fig, ax = plt.subplots(figsize=(10.8, 5.2))
    ax.bar(x, share_f, color=BLUE, edgecolor=BLACK, linewidth=0.4, label="Formal")
    ax.bar(x, share_i, bottom=share_f, color=RED, edgecolor=BLACK, linewidth=0.4, label="Informal")
    one = np.ones_like(share_f)
    annotate_stacked_percent(ax, x, np.zeros_like(share_f), share_f, one, color="white")
    annotate_stacked_percent(ax, x, share_f, share_i, one, color="white")
    ax.set_ylim(0, 1.0)
    ax.set_xticks(x, labels, rotation=0)
    ax.set_xlabel("Productividad, z")
    ax.set_ylabel("Participacion de horas trabajadas")
    ax.legend(loc="best")
    moll_axis(ax)
    caption(fig, "Figura: composicion sectorial del trabajo por productividad, sin ocio")
    fig.tight_layout(rect=[0.03, 0.08, 0.99, 0.98])
    png2 = OUT_DIR / "moll_time_use_by_z_excluding_leisure.png"
    fig.savefig(png2)
    plt.close(fig)

    fig, ax = plt.subplots(figsize=(8.0, 5.2))
    ax.plot(z, share_f * 100, "-o", color=BLUE, lw=2.0, label="Formal")
    ax.plot(z, share_i * 100, "--s", color=RED, lw=2.0, label="Informal")
    ax.set_xlabel("Productividad, z")
    ax.set_ylabel("% de horas trabajadas")
    ax.set_ylim(0, 100)
    ax.legend(loc="best")
    moll_axis(ax)
    caption(fig, "Figura: tendencia sectorial del trabajo por productividad, sin ocio")
    fig.tight_layout(rect=[0.04, 0.08, 0.99, 0.98])
    png3 = OUT_DIR / "moll_time_use_by_z_trend.png"
    fig.savefig(png3)
    plt.close(fig)

    txt = OUT_DIR / "moll_time_use_by_z.txt"
    with txt.open("w", encoding="utf-8") as f:
        f.write(
            "z mean_ellF mean_ellI mean_leisure pct_formal_time pct_informal_time "
            "pct_leisure_time share_formal_worked share_informal_worked "
            "pct_formal_worked pct_informal_worked\n"
        )
        for j in range(len(z)):
            total_time_j = max(mean_f[j] + mean_i[j] + mean_o[j], 1e-12)
            f.write(
                f"{z[j]:.10f} {mean_f[j]:.10f} {mean_i[j]:.10f} {mean_o[j]:.10f} "
                f"{100*mean_f[j]/total_time_j:.6f} {100*mean_i[j]/total_time_j:.6f} "
                f"{100*mean_o[j]/total_time_j:.6f} {share_f[j]:.10f} {share_i[j]:.10f} "
                f"{100*share_f[j]:.6f} {100*share_i[j]:.6f}\n"
            )
    return png1, png2, png3, txt


def save_income_decomposition(a, z, g, da, expenditure, comps):
    i_count, n_z = g.shape
    aa = a[:, None] * np.ones((1, n_z))
    weights = g * da
    qcuts = weighted_quantile(aa.reshape(-1), weights.reshape(-1), [0.2, 0.4, 0.6, 0.8])
    masks = [
        aa <= qcuts[0],
        (aa > qcuts[0]) & (aa <= qcuts[1]),
        (aa > qcuts[1]) & (aa <= qcuts[2]),
        (aa > qcuts[2]) & (aa <= qcuts[3]),
        aa > qcuts[3],
    ]

    names = ["Lab. formal", "Lab. informal", "Capital", "Transfer.", "Costo deuda"]
    keys = ["formal", "informal", "capital", "transfer", "debt_cost"]
    vals = np.zeros((5, len(keys)))
    net = np.zeros(5)
    exp_q = np.zeros(5)
    mass = np.zeros(5)
    for q, mask in enumerate(masks):
        wq = weights * mask
        mass[q] = np.sum(wq)
        for k, key in enumerate(keys):
            vals[q, k] = weighted_mean(comps[key], wq)
        net[q] = weighted_mean(comps["net_income"], wq)
        exp_q[q] = weighted_mean(expenditure, wq)

    fig, axes = plt.subplots(1, 2, figsize=(11.8, 5.2))
    x = np.arange(1, 6)
    ax = axes[0]
    bottom = np.zeros(5)
    colors = [BLUE, RED, GREEN, GRAY, "#8a4fb4"]
    for k in range(len(keys)):
        ax.bar(x, vals[:, k], bottom=bottom, color=colors[k], edgecolor=BLACK, linewidth=0.4, label=names[k])
        bottom += vals[:, k]
    ax.plot(x, net, color=BLACK, lw=1.8, marker="o", label="Ingreso neto")
    ax.set_xticks(x, [f"Q{q}" for q in x])
    ax.set_xlabel("Quintil de riqueza")
    ax.set_ylabel("Ingreso medio")
    ax.legend(loc="best", fontsize=8)
    moll_axis(ax)

    ax = axes[1]
    ax.plot(x, net, color=BLUE, lw=2.0, marker="o", label="Ingreso neto")
    ax.plot(x, exp_q, color=RED, lw=2.0, ls="--", marker="s", label="Gasto")
    ax.plot(x, net - exp_q, color=GREEN, lw=1.8, ls=":", marker="^", label="Ahorro")
    ax.axhline(0, color=BLACK, lw=0.8, ls=":")
    ax.set_xticks(x, [f"Q{q}" for q in x])
    ax.set_xlabel("Quintil de riqueza")
    ax.set_ylabel("Media dentro del quintil")
    ax.legend(loc="best")
    moll_axis(ax)
    caption(fig, "Figura: descomposicion del ingreso medio por quintil de riqueza")
    fig.tight_layout(rect=[0.03, 0.08, 0.99, 0.98])
    png = OUT_DIR / "moll_income_decomposition_by_wealth_quintile.png"
    fig.savefig(png)
    plt.close(fig)

    txt = OUT_DIR / "moll_income_decomposition_by_wealth_quintile.txt"
    with txt.open("w", encoding="utf-8") as f:
        f.write("q mass lab_formal lab_informal capital transfer debt_cost net_income expenditure saving\n")
        for q in range(5):
            f.write(
                f"{q+1} {mass[q]:.10f} {vals[q,0]:.10f} {vals[q,1]:.10f} {vals[q,2]:.10f} "
                f"{vals[q,3]:.10f} {vals[q,4]:.10f} {net[q]:.10f} {exp_q[q]:.10f} {net[q]-exp_q[q]:.10f}\n"
            )

    gross_positive = vals[:, 0] + vals[:, 1] + vals[:, 2] + vals[:, 3]
    denom = np.maximum(gross_positive, 1e-12)
    pct = 100.0 * vals[:, 0:4] / denom[:, None]
    debt_pct = 100.0 * vals[:, 4] / denom
    net_pct = 100.0 * net / denom

    fig, ax = plt.subplots(figsize=(8.8, 5.6))
    bottom = np.zeros(5)
    for k, name in enumerate(names[:4]):
        ax.bar(x, vals[:, k], bottom=bottom, color=colors[k], edgecolor=BLACK, linewidth=0.4, label=name)
        for i in range(5):
            if pct[i, k] >= 6 and vals[i, k] > 0:
                ax.text(
                    x[i],
                    bottom[i] + vals[i, k] / 2.0,
                    f"{pct[i, k]:.0f}%",
                    ha="center",
                    va="center",
                    fontsize=8,
                    color="white" if k in (0, 1) else "black",
                )
        bottom += vals[:, k]
    if np.any(vals[:, 4] < -1e-8):
        ax.plot(x, vals[:, 4], color="#8a4fb4", lw=1.8, marker="s", ls="--", label="Costo deuda")
    ax.plot(x, net, color=BLACK, lw=1.8, marker="o", label="Ingreso neto")
    ax.axhline(0, color=BLACK, lw=0.8, ls=":")
    ax.set_xticks(x, [f"Q{q}" for q in x])
    ax.set_xlabel("Quintil de riqueza")
    ax.set_ylabel("Ingreso medio")
    ax.set_ylim(min(-0.05, np.nanmin(vals[:, 4]) * 1.2), max(bottom) * 1.18)
    ax.legend(loc="upper left", fontsize=8, ncol=2)
    moll_axis(ax)
    caption(fig, "Figura: ingreso medio por quintil; porcentajes dentro de cada barra")
    fig.tight_layout(rect=[0.04, 0.08, 0.99, 0.98])
    pct_png = OUT_DIR / "moll_income_decomposition_percent_by_wealth_quintile.png"
    fig.savefig(pct_png)
    plt.close(fig)

    pct_txt = OUT_DIR / "moll_income_decomposition_percent_by_wealth_quintile.txt"
    with pct_txt.open("w", encoding="utf-8") as f:
        f.write("Percent income decomposition by wealth quintile\n")
        f.write("denominator=gross income = formal + informal + capital + transfer\n")
        f.write("q pct_formal pct_informal pct_capital pct_transfer pct_debt_cost pct_net_income\n")
        for q in range(5):
            f.write(
                f"{q+1} {pct[q,0]:.10f} {pct[q,1]:.10f} {pct[q,2]:.10f} "
                f"{pct[q,3]:.10f} {debt_pct[q]:.10f} {net_pct[q]:.10f}\n"
            )
    return png, txt, pct_png, pct_txt


def save_consumption_distribution(c, c_f, c_i, expenditure, p_i, g, da):
    weights = g.reshape(-1) * da
    x_eff = c.reshape(-1)
    x_exp = expenditure.reshape(-1)
    xlim = weighted_quantile(np.concatenate([x_eff, x_exp]), np.concatenate([weights, weights]), [0.005, 0.995])
    x_c, pdf_c = weighted_pdf(x_eff, weights, 70, xlim)
    x_e, pdf_e = weighted_pdf(x_exp, weights, 70, xlim)

    fig, ax = plt.subplots(figsize=(8.0, 5.4))
    ax.plot(x_c, pdf_c, "-", color=BLUE, lw=2.1, label="Consumo efectivo C")
    ax.plot(x_e, pdf_e, "--", color=RED, lw=2.1, label="Gasto X = c_F + p_I c_I")
    ax.set_xlabel("Consumo efectivo / gasto")
    ax.set_ylabel("Densidad estacionaria")
    ax.text(
        0.98,
        0.92,
        "C es el agregado CES que da utilidad.\nX es gasto monetario en bienes F e I.",
        ha="right",
        va="top",
        transform=ax.transAxes,
        fontsize=9,
    )
    ax.legend(loc="best")
    moll_axis(ax)
    caption(fig, "Figura: distribucion estacionaria de consumo efectivo y gasto")
    fig.tight_layout(rect=[0.04, 0.08, 0.99, 0.98])
    png = OUT_DIR / "moll_consumption_distribution.png"
    fig.savefig(png)
    plt.close(fig)

    txt = OUT_DIR / "moll_consumption_distribution.txt"
    with txt.open("w", encoding="utf-8") as f:
        f.write("Consumption distribution from HA model .mat\n")
        f.write("C_eff=consumption aggregator entering utility\n")
        f.write("expenditure=X=c_F+p_I*c_I, monetary spending on formal and informal goods\n")
        f.write("variable mean sd\n")
        for name, arr in [("C_eff", c), ("expenditure", expenditure), ("c_F", c_f), ("p_I_c_I", p_i * c_i)]:
            f.write(f"{name} {weighted_mean(arr, g * da):.10f} {weighted_sd(arr, g * da):.10f}\n")
    return png, txt


def save_consumption_components_distribution(c_f, c_i, expenditure, p_i, a, z, g, da):
    weights = g.reshape(-1) * da
    x_f = c_f.reshape(-1)
    x_i = (p_i * c_i).reshape(-1)
    xlim = weighted_quantile(np.concatenate([x_f, x_i]), np.concatenate([weights, weights]), [0.005, 0.995])
    xf, pdf_f = weighted_pdf(x_f, weights, 70, xlim)
    xi, pdf_i = weighted_pdf(x_i, weights, 70, xlim)

    fig, ax = plt.subplots(figsize=(8.0, 5.4))
    ax.plot(xf, pdf_f, "-", color=BLUE, lw=2.1, label="Gasto formal c_F")
    ax.plot(xi, pdf_i, "--", color=RED, lw=2.1, label="Gasto informal p_I c_I")
    ax.set_xlabel("Gasto por componente")
    ax.set_ylabel("Densidad estacionaria")
    ax.text(
        0.98,
        0.92,
        "Este grafico agrega todos los z.\nPara ver cambios por productividad,\nusa el grafico por z bajo/mediano/alto.",
        ha="right",
        va="top",
        transform=ax.transAxes,
        fontsize=9,
    )
    ax.legend(loc="best")
    moll_axis(ax)
    caption(fig, "Figura: distribucion agregada de componentes de gasto")
    fig.tight_layout(rect=[0.04, 0.08, 0.99, 0.98])
    png = OUT_DIR / "moll_consumption_components_distribution.png"
    fig.savefig(png)
    plt.close(fig)

    j_low, j_mid, j_high = 0, len(z) // 2, len(z) - 1
    component_ratio = c_f / np.maximum(p_i * c_i, 1e-12)
    ratio_mean = float(np.nanmean(component_ratio))
    ratio_sd = float(np.nanstd(component_ratio))
    fig, axes = plt.subplots(1, 3, figsize=(15.2, 5.0), sharey=True)
    for ax, j, title, color in [
        (axes[0], j_low, f"z bajo={z[j_low]:.2f}", BLUE),
        (axes[1], j_mid, f"z mediano={z[j_mid]:.2f}", GRAY),
        (axes[2], j_high, f"z alto={z[j_high]:.2f}", RED),
    ]:
        wj = g[:, j] * da
        xfj, pfj = weighted_pdf(c_f[:, j], wj, 55, xlim)
        xij, pij = weighted_pdf(p_i * c_i[:, j], wj, 55, xlim)
        pfj_display = pfj / max(np.nanmax(pfj), 1e-12)
        pij_display = pij / max(np.nanmax(pij), 1e-12)
        mean_f_j = weighted_mean(c_f[:, j], wj)
        mean_i_j = weighted_mean(p_i * c_i[:, j], wj)
        ax.plot(xfj, pfj_display, "-", color=BLUE, lw=1.9, label=f"c_F, media={mean_f_j:.2f}")
        ax.plot(xij, pij_display, "--", color=RED, lw=1.9, label=f"p_I c_I, media={mean_i_j:.2f}")
        ax.axvline(mean_f_j, color=BLUE, lw=0.8, ls=":", alpha=0.75)
        ax.axvline(mean_i_j, color=RED, lw=0.8, ls=":", alpha=0.75)
        ax.set_ylim(0, 1.05)
        ax.set_title(title, fontsize=12, fontweight="normal")
        ax.set_xlabel("Gasto por componente")
        ax.legend(loc="best", fontsize=8)
        moll_axis(ax)
    axes[0].set_ylabel("Densidad condicional normalizada")
    if ratio_sd < 1e-8 and np.isfinite(ratio_mean):
        note = f"Figura: componentes por productividad; c_F/(p_I c_I)={ratio_mean:.2f} constante por CES"
    else:
        note = "Figura: componentes de gasto por productividad; lineas verticales indican medias"
    caption(fig, note)
    fig.tight_layout(rect=[0.03, 0.08, 0.99, 0.98])
    byz_png = OUT_DIR / "moll_consumption_components_distribution_by_z_groups.png"
    fig.savefig(byz_png)
    plt.close(fig)

    return png, byz_png


def save_wealth_density_by_z(a, z, g, da):
    j_low = 0
    j_mid = len(z) // 2
    j_high = len(z) - 1
    w_a = np.maximum(np.sum(g, axis=1), 0.0) * da
    xlo, xhi = weighted_quantile(a, w_a, [0.005, 0.995])
    if not np.isfinite(xlo) or not np.isfinite(xhi) or xhi <= xlo:
        xlo, xhi = zoom_limits(a, g, da)

    series = []
    total_density = np.sum(g, axis=1) / max(np.nanmax(np.sum(g, axis=1)), 1e-12)
    series.append((total_density, BLACK, "-", "Total", weighted_mean(a, w_a)))
    for j, color, style, label in [
        (j_low, BLUE, "-", f"z bajo={z[j_low]:.2f}"),
        (j_mid, GRAY, "-", f"z mediano={z[j_mid]:.2f}"),
        (j_high, RED, "--", f"z alto={z[j_high]:.2f}"),
    ]:
        mass_j = np.sum(g[:, j]) * da
        density = g[:, j] / max(mass_j, 1e-12)
        density = density / max(np.nanmax(density), 1e-12)
        series.append((density, color, style, label, weighted_mean(a, g[:, j] * da)))

    fig, ax = plt.subplots(figsize=(8.2, 5.4))
    for density, color, style, label, mean_a in series:
        ax.plot(a, density, color=color, ls=style, lw=2.0, label=label)
        if np.isfinite(mean_a):
            ax.axvline(mean_a, color=color, ls=":", lw=0.8, alpha=0.65)
    ax.set_xlim(float(xlo), float(xhi))
    ax.set_ylim(0, 1.05)
    ax.set_xlabel("Riqueza, a")
    ax.set_ylabel("Densidad condicional normalizada")
    ax.legend(loc="best")
    moll_axis(ax)
    caption(fig, "Figura: densidad de riqueza por productividad; lineas verticales indican medias")
    fig.tight_layout(rect=[0.04, 0.08, 0.99, 0.98])
    png = OUT_DIR / "moll_wealth_density_by_z_low_median_high.png"
    fig.savefig(png)
    plt.close(fig)
    return png


def save_equilibrium_asset_market(mat):
    required = ["r_grid", "S", "KD"]
    if any(name not in mat for name in required):
        return None
    r = np.asarray(mat["r_grid"]).reshape(-1)
    s = np.asarray(mat["S"]).reshape(-1)
    kd = np.asarray(mat["KD"]).reshape(-1)
    ok = np.isfinite(r) & np.isfinite(s) & np.isfinite(kd)
    r, s, kd = r[ok], s[ok], kd[ok]
    if r.size < 2:
        return None
    order = np.argsort(r)
    r, s, kd = r[order], s[order], kd[order]
    r_star = scalar(mat, "r_star", np.nan)
    k_star = scalar(mat, "K_star", np.nan)

    fig, ax = plt.subplots(figsize=(7.6, 5.6))
    ax.plot(r, s, color=BLUE, lw=2.2, label="Oferta de activos S(r)")
    ax.plot(r, kd, color=RED, lw=2.2, ls="--", label="Demanda de capital K^D(r)")
    if np.isfinite(r_star):
        ax.axvline(r_star, color=BLACK, lw=0.9, ls=":", label=f"r*={r_star:.4f}")
    if np.isfinite(k_star):
        ax.axhline(k_star, color=GRAY, lw=0.9, ls=":", label=f"K*={k_star:.3f}")
    ax.set_xlabel("Tasa de interes, r")
    ax.set_ylabel("Nivel agregado")
    ax.legend(loc="best")
    moll_axis(ax)
    caption(fig, "Figura: equilibrio estacionario en el mercado de activos")
    fig.tight_layout(rect=[0.04, 0.08, 0.98, 0.98])
    png = OUT_DIR / "moll_equilibrium_asset_market.png"
    fig.savefig(png)
    plt.close(fig)
    return png


def parse_args():
    parser = argparse.ArgumentParser(description="Genera figuras estilo Moll desde un .mat del modelo HA.")
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
    mat, a, z, g, c, c_f, c_i, expenditure, ell_f, ell_i, da = load_model(mat_file)
    comps = income_components(mat, a, z, g, expenditure, ell_f, ell_i)

    outputs = [
        *save_savings_wealth_figures(a, z, g, da, comps["savings"]),
        *save_consumption_distribution(c, c_f, c_i, expenditure, scalar(mat, "p_I_star", scalar(mat, "p_I", 1.0)), g, da),
        *save_consumption_components_distribution(c_f, c_i, expenditure, scalar(mat, "p_I_star", scalar(mat, "p_I", 1.0)), a, z, g, da),
        *save_time_use_figures(z, g, da, ell_f, ell_i, mat),
        *save_income_decomposition(a, z, g, da, expenditure, comps),
        save_wealth_density_by_z(a, z, g, da),
        save_equilibrium_asset_market(mat),
    ]
    outputs = [out for out in outputs if out is not None]

    readme = OUT_DIR / "moll_model_mechanism_figures_README.txt"
    with readme.open("w", encoding="utf-8") as f:
        f.write("Additional Moll-style figures generated from the HA model .mat file.\n")
        f.write(f"source_mat={mat_file}\n")
        f.write("s(a,z)=net income minus expenditure, where expenditure=c_F+p_I*c_I.\n")
        f.write("g(a,z)=stationary density/mass of agents over wealth and productivity states.\n")
        f.write("C_eff is the CES consumption aggregator; expenditure is X=c_F+p_I*c_I.\n")
        f.write("Time use uses stationary weights g(a,z)*da conditional on each z.\n")
        f.write("Income quintiles are wealth quintiles computed from the stationary distribution.\n\n")
        for out in outputs:
            f.write(f"{out}\n")
    outputs.append(readme)

    print("Generated:")
    for out in outputs:
        print(f"  {out}")


if __name__ == "__main__":
    main()
