"""
plot_ou_results.py
==================
Reemplazo Python de plot_ou_process_distributions.m y plot_results.m.

Genera las 23 figuras Moll-style que producía el plotter MATLAB:

  Riqueza / ahorro
  1.  moll_savings_policy
  2.  moll_wealth_distribution_by_z
  3.  moll_wealth_density_by_z_low_median_high

  Consumo
  4.  moll_consumption_policy
  5.  moll_consumption_labor_policy_by_wealth
  6.  moll_consumption_distribution
  7.  moll_consumption_components_distribution
  8.  moll_consumption_components_by_z
  9.  moll_consumption_components_distribution_by_z_groups

  Oferta laboral / tiempo
  10. moll_labor_policy_by_wealth
  11. moll_labor_supply_by_productivity
  12. moll_time_use_by_z_with_leisure
  13. moll_time_use_by_z_excluding_leisure

  Ingreso por quintil
  14. moll_income_decomposition_by_wealth_quintile
  15. moll_income_decomposition_percent_by_wealth_quintile

  Informalidad / deuda
  16. moll_informality_by_z
  17. moll_debt_probability_by_z
  18. moll_model_gasto_distribution_by_formality

  Desigualdad
  19. moll_lorenz_curves
  20. moll_debt_premium_inequality_by_z

  Proceso OU / equilibrio
  21. moll_ou_stationary_masses
  22. moll_conditional_moments_by_z
  23. moll_equilibrium_asset_market

Uso:
    python ploteo/plot_ou_results.py --mat-file outputs/stationary/<run>/results_<run>.mat
    python ploteo/plot_ou_results.py --mat-file <ruta>.mat --out-dir <dir_salida>
"""

from pathlib import Path
import argparse
import sys

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
from mpl_toolkits.mplot3d import Axes3D  # noqa: F401 (activates 3D projection)
from scipy.io import loadmat
from scipy.stats import gaussian_kde

# ---------------------------------------------------------------------------
# Paleta y estilo Moll
# ---------------------------------------------------------------------------
BLUE  = "#0000ff"
RED   = "#ff0000"
GREEN = "#1f9d40"
BLACK = "#000000"
GRAY  = "#707070"
ORANGE = "#e07000"


def setup_style():
    plt.rcParams.update({
        "figure.facecolor":  "white",
        "axes.facecolor":    "white",
        "axes.edgecolor":    BLACK,
        "axes.linewidth":    0.8,
        "axes.grid":         False,
        "font.family":       "Times New Roman",
        "font.size":         11,
        "legend.frameon":    False,
        "savefig.facecolor": "white",
        "savefig.dpi":       300,
    })


def moll_ax(ax):
    ax.tick_params(direction="in", top=False, right=False)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    for sp in ax.spines.values():
        sp.set_linewidth(0.8)


def caption(fig, text, y=0.005):
    fig.text(0.5, y, text, ha="center", va="bottom", fontsize=9,
             fontstyle="italic", color=GRAY)


def save(fig, path):
    fig.savefig(path, bbox_inches="tight", pad_inches=0.08)
    plt.close(fig)
    print(f"  saved: {path.name}")


def _normalize_pdf(pdf):
    peak = np.nanmax(pdf) if np.size(pdf) else np.nan
    return pdf / max(peak, 1e-12) if np.isfinite(peak) else pdf


# ---------------------------------------------------------------------------
# Helpers estadísticos
# ---------------------------------------------------------------------------

def weighted_quantile(x, w, probs):
    x = np.asarray(x, float).ravel()
    w = np.asarray(w, float).ravel()
    ok = np.isfinite(x) & np.isfinite(w) & (w > 0)
    if ok.sum() == 0:
        return np.full(np.size(probs), np.nan)
    x, w = x[ok], w[ok]
    order = np.argsort(x)
    x, w = x[order], w[order]
    cw = np.cumsum(w) / np.sum(w)
    return np.interp(probs, cw, x)


def weighted_pdf(x, w, n_pts=300):
    x = np.asarray(x, float).ravel()
    w = np.asarray(w, float).ravel()
    ok = np.isfinite(x) & np.isfinite(w) & (w > 0)
    x, w = x[ok], w[ok]
    if x.size < 3:
        return np.array([]), np.array([])
    try:
        kde = gaussian_kde(x, weights=w)
        xg = np.linspace(x.min(), x.max(), n_pts)
        return xg, kde(xg)
    except Exception:
        return np.array([]), np.array([])


def weighted_gini(x, w):
    x = np.asarray(x, float).ravel()
    w = np.asarray(w, float).ravel()
    ok = np.isfinite(x) & np.isfinite(w) & (w > 0) & (x >= 0)
    x, w = x[ok], w[ok]
    if x.size == 0:
        return np.nan
    order = np.argsort(x)
    x, w = x[order], w[order]
    w = w / w.sum()
    cum_pop = np.concatenate([[0.], np.cumsum(w)])
    cum_x   = np.concatenate([[0.], np.cumsum(w * x)])
    cum_x  /= max(cum_x[-1], 1e-12)
    return 1.0 - 2.0 * float(np.trapz(cum_x, cum_pop))


def lorenz_gini(x, w):
    x = np.asarray(x, float).ravel()
    w = np.asarray(w, float).ravel()
    ok = np.isfinite(x) & np.isfinite(w) & (w > 0)
    x, w = x[ok], w[ok]
    if x.size == 0:
        return np.array([0., 1.]), np.array([0., 1.]), np.nan
    order = np.argsort(x)
    x, w = x[order], w[order]
    w = w / w.sum()
    cum_pop = np.concatenate([[0.], np.cumsum(w)])
    cum_x   = np.concatenate([[0.], np.cumsum(w * x)])
    total   = cum_x[-1]
    lorenz  = cum_x / max(abs(total), 1e-12)
    gini = 1.0 - 2.0 * float(np.trapz(lorenz, cum_pop))
    return cum_pop, lorenz, gini


def quintile_masks(a_flat, w_flat, n=5):
    """Returns list of n boolean masks (quintiles by wealth)."""
    cuts = [i / n for i in range(1, n)]
    thresholds = weighted_quantile(a_flat, w_flat, cuts)
    masks = []
    for i in range(n):
        lo = thresholds[i - 1] if i > 0 else -np.inf
        hi = thresholds[i] if i < n - 1 else np.inf
        masks.append((a_flat >= lo) & (a_flat <= hi))
    return masks


# ---------------------------------------------------------------------------
# CES split
# ---------------------------------------------------------------------------

def ces_split(c_eff, p_i, omega_c, eta_c, sigma_c):
    c_eff = np.maximum(np.real(c_eff), 1e-12)
    xi    = (omega_c * p_i / max(1.0 - omega_c, 1e-12)) ** sigma_c
    kappa = (omega_c * xi**eta_c + (1.0 - omega_c)) ** (1.0 / eta_c)
    c_i   = c_eff / kappa
    c_f   = xi * c_i
    return c_f, c_i, c_f + p_i * c_i


# ---------------------------------------------------------------------------
# Carga del .mat
# ---------------------------------------------------------------------------

def sc(mat, *keys, default=np.nan):
    for k in keys:
        if k in mat:
            v = np.asarray(mat[k]).ravel()
            if v.size > 0:
                try:
                    return float(v[0])
                except Exception:
                    pass
    return default


def mx(mat, key, default=None):
    if key not in mat:
        return default
    return np.asarray(mat[key], float)


def load_mat(path):
    try:
        m = loadmat(str(path), squeeze_me=True, struct_as_record=False)
    except Exception as e:
        sys.exit(f"Error cargando {path}: {e}")

    a    = np.asarray(m["a"], float).ravel()
    z    = np.asarray(m["z"], float).ravel()
    g    = np.asarray(m["g"], float)
    c    = np.asarray(m["c"], float)
    da   = float(np.asarray(m["da"]).ravel()[0])

    ell_F = mx(m, "ell_F")
    ell_I = mx(m, "ell_I")

    p_i     = sc(m, "p_I_star", "p_I", default=1.0)
    omega_c = sc(m, "omega_C", default=np.nan)
    eta_c   = sc(m, "eta_C",   default=np.nan)
    sigma_c = sc(m, "sigma_C", default=np.nan)

    r_eq   = sc(m, "r_star", "r_eq", "r")
    w_F    = sc(m, "w_F_star", "w_F")
    w_I    = sc(m, "w_I_household_star", "w_I_star", "w_I")
    tau    = sc(m, "tau",  default=0.0)
    T_eq   = sc(m, "T_eq", "T_star", "T", default=0.0)
    theta  = sc(m, "theta", default=1.0)
    nu_I   = sc(m, "nu_I",  default=1.0)
    H_bar  = sc(m, "H_bar", default=1.0)
    Pi_lump = sc(m, "Pi_lump_star", "profit_I_star", default=0.0)

    rho_z   = sc(m, "rho_z_ar", default=np.nan)
    sd_z    = sc(m, "sd_logz_ar", default=np.nan)
    pi_z_ar = mx(m, "pi_z_ar")
    if pi_z_ar is not None:
        pi_z_ar = pi_z_ar.ravel()

    debt_spread_z  = mx(m, "debt_spread_z")
    debt_spread_aa = mx(m, "debt_spread_aa")
    kappa_F_aa     = mx(m, "kappa_F_aa")
    qq_informal    = mx(m, "qq_informal")

    r_grid   = mx(m, "r_grid")
    S_curve  = mx(m, "S")
    KD_curve = mx(m, "KD")
    if r_grid is not None:   r_grid   = r_grid.ravel()
    if S_curve is not None:  S_curve  = S_curve.ravel()
    if KD_curve is not None: KD_curve = KD_curve.ravel()

    # Extra calibration fields (read when available)
    rho_disc = sc(m, "rho",   default=np.nan)   # discount rate
    ga_val   = sc(m, "ga",    default=np.nan)   # CRRA (often not saved → nan)
    al_val   = sc(m, "al",    default=np.nan)   # capital share formal
    Y_F      = sc(m, "Y_F",   default=np.nan)
    Y_I      = sc(m, "Y_I",   default=np.nan)
    K_star   = sc(m, "K_star", default=np.nan)
    Gini_a_mat = sc(m, "Gini_a", default=np.nan)
    T4_model = sc(m, "T4_model", "T4_ratio", default=np.nan)
    T5_nom   = sc(m, "T5_nom",  default=np.nan)
    Tkz_m    = sc(m, "T_kappa_z_model", default=np.nan)
    Tgasto_m = sc(m, "Tgasto_tipo", "ratio_gasto_FI", default=np.nan)
    T1_net   = sc(m, "T1_wage_net", default=np.nan)
    psi_F_m  = sc(m, "psi_F",  default=np.nan)
    psi_I_m  = sc(m, "psi_I",  default=np.nan)
    kappa_z1_m = sc(m, "kappa_z1", default=np.nan)

    tag = path.stem
    return dict(
        a=a, z=z, g=g, c=c, da=da,
        ell_F=ell_F, ell_I=ell_I,
        p_i=p_i, omega_c=omega_c, eta_c=eta_c, sigma_c=sigma_c,
        r_eq=r_eq, w_F=w_F, w_I=w_I, tau=tau, T_eq=T_eq, Pi_lump=Pi_lump,
        theta=theta, nu_I=nu_I, H_bar=H_bar,
        rho_z=rho_z, sd_z=sd_z, pi_z_ar=pi_z_ar,
        debt_spread_z=debt_spread_z, debt_spread_aa=debt_spread_aa,
        kappa_F_aa=kappa_F_aa, qq_informal=qq_informal,
        r_grid=r_grid, S_curve=S_curve, KD_curve=KD_curve,
        rho_disc=rho_disc, ga_val=ga_val, al_val=al_val,
        Y_F=Y_F, Y_I=Y_I, K_star=K_star, Gini_a_mat=Gini_a_mat,
        T4_model=T4_model, T5_nom=T5_nom, Tkz_m=Tkz_m,
        Tgasto_m=Tgasto_m, T1_net=T1_net,
        psi_F_m=psi_F_m, psi_I_m=psi_I_m, kappa_z1_m=kappa_z1_m,
        tag=tag, mat_path=path,
    )


# ---------------------------------------------------------------------------
# Derivados
# ---------------------------------------------------------------------------

def derive(d):
    a, z, g, c, da = d["a"], d["z"], d["g"], d["c"], d["da"]
    I, Ns = g.shape

    aa = np.outer(a, np.ones(Ns))
    zz = np.outer(np.ones(I), z)

    p_i, omega_c, eta_c, sigma_c = d["p_i"], d["omega_c"], d["eta_c"], d["sigma_c"]
    if np.all(np.isfinite([p_i, omega_c, eta_c, sigma_c])):
        c_F, c_I, exp_cons = ces_split(c, p_i, omega_c, eta_c, sigma_c)
    else:
        c_F = c.copy(); c_I = np.zeros_like(c); exp_cons = c.copy()

    w_all    = np.maximum((g * da).ravel(), 0.0)
    g_marg_a = g.sum(axis=1)
    cdf_a    = np.cumsum(g_marg_a) * da

    zoom_lo = float(weighted_quantile(a, g_marg_a * da, [0.01])[0])
    zoom_hi = float(weighted_quantile(a, g_marg_a * da, [0.99])[0])
    if not (np.isfinite(zoom_lo) and np.isfinite(zoom_hi) and zoom_hi > zoom_lo):
        zoom_lo, zoom_hi = float(a.min()), float(a.max())

    j_low  = 0
    j_mid  = max(0, (Ns - 1) // 2)
    j_high = Ns - 1

    mass_z = np.maximum(g.sum(axis=0) * da, 1e-12)

    mean_a_by_z   = np.array([(g[:, j] * da * a).sum() / mass_z[j]           for j in range(Ns)])
    mean_exp_by_z = np.array([(g[:, j] * da * exp_cons[:, j]).sum() / mass_z[j] for j in range(Ns)])
    mean_cF_by_z  = np.array([(g[:, j] * da * c_F[:, j]).sum() / mass_z[j]   for j in range(Ns)])
    mean_pIcI_by_z = np.array([(g[:, j] * da * (p_i * c_I[:, j])).sum() / mass_z[j] for j in range(Ns)])
    denom_j = np.maximum(mean_cF_by_z + mean_pIcI_by_z, 1e-12)
    share_cF_by_z   = mean_cF_by_z / denom_j
    share_pIcI_by_z = mean_pIcI_by_z / denom_j

    mass_debt_by_z = np.array(
        [(g[:, j] * da * (a < 0)).sum() / mass_z[j] for j in range(Ns)])
    mean_a_debt_by_z = np.full(Ns, np.nan)
    for j in range(Ns):
        neg = a < 0
        wj  = g[neg, j] * da
        tot = wj.sum()
        if tot > 1e-12:
            mean_a_debt_by_z[j] = (a[neg] * wj).sum() / tot

    # Gini dentro de cada z
    gini_C_by_z   = np.array([weighted_gini(c[:, j],       g[:, j] * da) for j in range(Ns)])
    gini_exp_by_z = np.array([weighted_gini(exp_cons[:, j], g[:, j] * da) for j in range(Ns)])

    ell_F = d["ell_F"]
    ell_I = d["ell_I"]
    if ell_F is not None and ell_I is not None:
        tot_work = ell_F + ell_I
        denom_work = np.maximum(tot_work, 1e-12)
        form_share_by_z = np.array([
            (g[:, j] * da * ell_F[:, j]).sum() / mass_z[j] /
            max((g[:, j] * da * denom_work[:, j]).sum() / mass_z[j], 1e-12)
            for j in range(Ns)])
        mean_ellF_by_z = np.array([(g[:, j] * da * ell_F[:, j]).sum() / mass_z[j] for j in range(Ns)])
        mean_ellI_by_z = np.array([(g[:, j] * da * ell_I[:, j]).sum() / mass_z[j] for j in range(Ns)])

        # Ahorro (adot)
        kappa = d["kappa_F_aa"] if d["kappa_F_aa"] is not None else np.zeros((I, Ns))
        qq    = d["qq_informal"] if d["qq_informal"] is not None else np.ones((I, Ns))
        ds    = d["debt_spread_aa"] if d["debt_spread_aa"] is not None else np.zeros((I, Ns))
        if np.isfinite(d["w_F"]) and np.isfinite(d["w_I"]) and np.isfinite(d["r_eq"]):
            inc_F = ((1 - d["tau"]) * d["w_F"] * zz - kappa) * ell_F
            inc_I = d["w_I"] * d["theta"] * (zz ** d["nu_I"]) * qq * ell_I
            adot  = (inc_F + inc_I + d["r_eq"] * aa
                     - ds * np.maximum(-aa, 0)
                     + d["T_eq"] + d["Pi_lump"] - exp_cons)
            income_formal   = inc_F
            income_informal = inc_I
        else:
            adot = income_formal = income_informal = None
        income_assets   = d["r_eq"] * aa if np.isfinite(d["r_eq"]) else np.zeros((I, Ns))
        income_transfer = d["T_eq"] * np.ones((I, Ns))
    else:
        ell_F = ell_I = None
        form_share_by_z = np.full(Ns, np.nan)
        mean_ellF_by_z = mean_ellI_by_z = np.full(Ns, np.nan)
        adot = income_formal = income_informal = None
        income_assets   = np.zeros((I, Ns))
        income_transfer = d["T_eq"] * np.ones((I, Ns))

    d.update(dict(
        aa=aa, zz=zz, I=I, Ns=Ns,
        c_F=c_F, c_I=c_I, exp_cons=exp_cons,
        w_all=w_all, g_marg_a=g_marg_a, cdf_a=cdf_a,
        zoom_lo=zoom_lo, zoom_hi=zoom_hi,
        j_low=j_low, j_mid=j_mid, j_high=j_high,
        mass_z=mass_z,
        mean_a_by_z=mean_a_by_z, mean_exp_by_z=mean_exp_by_z,
        mean_cF_by_z=mean_cF_by_z, mean_pIcI_by_z=mean_pIcI_by_z,
        share_cF_by_z=share_cF_by_z, share_pIcI_by_z=share_pIcI_by_z,
        mass_debt_by_z=mass_debt_by_z, mean_a_debt_by_z=mean_a_debt_by_z,
        gini_C_by_z=gini_C_by_z, gini_exp_by_z=gini_exp_by_z,
        form_share_by_z=form_share_by_z,
        mean_ellF_by_z=mean_ellF_by_z, mean_ellI_by_z=mean_ellI_by_z,
        ell_F=ell_F, ell_I=ell_I, adot=adot,
        income_formal=income_formal, income_informal=income_informal,
        income_assets=income_assets, income_transfer=income_transfer,
    ))
    return d


# ---------------------------------------------------------------------------
# Estilo por z-state
# ---------------------------------------------------------------------------

def z_style(j, Ns):
    if j == 0:
        return BLUE, "-", 2.0
    elif j == Ns - 1:
        return RED, "--", 2.0
    else:
        return GRAY, ":", 1.4


def z_label(j, z, Ns):
    if j == 0:
        return f"$z_{{\\min}}={z[j]:.2f}$"
    elif j == Ns - 1:
        return f"$z_{{\\max}}={z[j]:.2f}$"
    else:
        return f"$z_{{\\rm med}}={z[j]:.2f}$"


# ===========================================================================
# FIGURAS
# ===========================================================================

# 1. Política de ahorro
def fig_savings_policy(d, out):
    if d["adot"] is None:
        return
    a, z, adot, Ns = d["a"], d["z"], d["adot"], d["Ns"]
    fig, ax = plt.subplots(figsize=(7, 5))
    for j in [d["j_low"], d["j_high"]]:
        col, ls, lw = z_style(j, Ns)
        ax.plot(a, adot[:, j], ls, color=col, lw=lw, label=z_label(j, z, Ns))
    ax.axhline(0, color=BLACK, lw=0.8, ls="--")
    ax.axvline(0, color=BLACK, lw=0.8, ls="--")
    ax.set_xlim(d["zoom_lo"], d["zoom_hi"])
    ax.set_xlabel("Riqueza, $a$")
    ax.set_ylabel("Ahorro, $s_j(a)$")
    ax.legend()
    moll_ax(ax)
    caption(fig, "Figura: política de ahorro por productividad")
    save(fig, out / "moll_savings_policy.png")


# 2. Distribución de riqueza por z (2 estados extremos)
def fig_wealth_distribution(d, out):
    a, z, g, da, Ns = d["a"], d["z"], d["g"], d["da"], d["Ns"]
    fig, ax = plt.subplots(figsize=(7, 5))
    for j in [d["j_low"], d["j_high"]]:
        col, ls, lw = z_style(j, Ns)
        mass_j = (g[:, j] * da).sum()
        pdf_j  = g[:, j] / max(mass_j * da, 1e-12)
        ax.plot(a, pdf_j, ls, color=col, lw=lw, label=z_label(j, z, Ns))
    ax.axvline(0, color=BLACK, lw=0.8, ls="--")
    ax.set_xlim(d["zoom_lo"], d["zoom_hi"])
    ax.set_xlabel("Riqueza neta, $a$")
    ax.set_ylabel("Densidades, $g_j(a)$")
    ax.legend()
    moll_ax(ax)
    caption(fig, "Figura: distribución de riqueza por productividad")
    save(fig, out / "moll_wealth_distribution_by_z.png")


# 3. Densidad de riqueza: bajo / medio / alto z
def fig_wealth_density_3groups(d, out):
    a, z, g, da, Ns = d["a"], d["z"], d["g"], d["da"], d["Ns"]
    groups = [
        (d["j_low"],  z_label(d["j_low"],  z, Ns), BLUE,  "-"),
        (d["j_mid"],  z_label(d["j_mid"],  z, Ns), GRAY,  ":"),
        (d["j_high"], z_label(d["j_high"], z, Ns), RED,  "--"),
    ]
    fig, ax = plt.subplots(figsize=(7, 5))
    for j, lbl, col, ls in groups:
        mass_j = (g[:, j] * da).sum()
        if mass_j < 1e-12:
            continue
        pdf_j  = g[:, j] / (mass_j * da)
        ax.plot(a, pdf_j, ls, color=col, lw=1.8, label=lbl)
    ax.axvline(0, color=BLACK, lw=0.8, ls="--")
    ax.set_xlim(d["zoom_lo"], d["zoom_hi"])
    ax.set_xlabel("Riqueza neta, $a$")
    ax.set_ylabel("Densidad normalizada $g(a|z)$")
    ax.legend()
    moll_ax(ax)
    caption(fig, "Densidad de riqueza normalizada para z bajo, medio y alto")
    save(fig, out / "moll_wealth_density_by_z_low_median_high.png")


# 3b. Densidad marginal de riqueza (suma sobre todos los z)
def fig_wealth_density_marginal(d, out):
    a, g, da = d["a"], d["g"], d["da"]
    g_marg = g.sum(axis=1) * da          # mass per a-point (sum over z, ×da for each z)
    g_marg_norm = g_marg / (g_marg.sum() * da)  # normalize to density integrating to 1

    fig, ax = plt.subplots(figsize=(7, 5))
    ax.fill_between(a, g_marg_norm, alpha=0.20, color=BLUE)
    ax.plot(a, g_marg_norm, "-", color=BLUE, lw=2.0, label="Densidad marginal $g(a)$")
    ax.axvline(0, color=BLACK, lw=0.8, ls="--")
    ax.set_xlim(d["zoom_lo"], d["zoom_hi"])
    ax.set_xlabel("Riqueza neta, $a$")
    ax.set_ylabel("Densidad $g(a) = \\int g(a,z)\\,dz$")
    ax.legend()
    moll_ax(ax)
    caption(fig, "Distribución marginal de riqueza (integrada sobre productividad)")
    save(fig, out / "moll_wealth_density_marginal.png")


# 3c. Superficie 3D de densidad f(a,z) — equivalente a Moll surf(a,z,g')
def fig_density_surface_3d(d, out):
    a, z, g, da = d["a"], d["z"], d["g"], d["da"]
    # Crop to p1–p99 wealth range for readability
    lo_idx = max(0,    int(np.searchsorted(a, d["zoom_lo"])))
    hi_idx = min(len(a), int(np.searchsorted(a, d["zoom_hi"])) + 1)
    a_cut = a[lo_idx:hi_idx]
    g_cut = g[lo_idx:hi_idx, :]

    AA, ZZ = np.meshgrid(a_cut, z, indexing="ij")

    fig = plt.figure(figsize=(9, 6))
    ax  = fig.add_subplot(111, projection="3d")
    ax.plot_surface(AA, ZZ, g_cut, cmap="Blues", edgecolor="none", alpha=0.85)
    ax.set_xlabel("Riqueza, $a$", labelpad=8)
    ax.set_ylabel("Productividad, $z$", labelpad=8)
    ax.set_zlabel("Densidad $g(a,z)$", labelpad=8)
    ax.view_init(elev=25, azim=225)
    ax.set_title("Distribución conjunta de riqueza y productividad", fontsize=11)
    fig.tight_layout()
    save(fig, out / "moll_density_surface_3d.png")


# 3d. Superficie 3D de política de ahorro s(a,z) — equivalente a Moll surf(a,z,ss')
def fig_savings_surface_3d(d, out):
    if d["adot"] is None:
        return
    a, z, adot = d["a"], d["z"], d["adot"]
    lo_idx = max(0,    int(np.searchsorted(a, d["zoom_lo"])))
    hi_idx = min(len(a), int(np.searchsorted(a, d["zoom_hi"])) + 1)
    a_cut    = a[lo_idx:hi_idx]
    adot_cut = adot[lo_idx:hi_idx, :]

    AA, ZZ = np.meshgrid(a_cut, z, indexing="ij")

    fig = plt.figure(figsize=(9, 6))
    ax  = fig.add_subplot(111, projection="3d")
    ax.plot_surface(AA, ZZ, adot_cut, cmap="RdBu_r", edgecolor="none", alpha=0.85)
    ax.set_xlabel("Riqueza, $a$", labelpad=8)
    ax.set_ylabel("Productividad, $z$", labelpad=8)
    ax.set_zlabel("Ahorro $s(a,z)$", labelpad=8)
    ax.view_init(elev=25, azim=225)
    ax.set_title("Política de ahorro $s(a,z)$ — superficie 3D", fontsize=11)
    fig.tight_layout()
    save(fig, out / "moll_savings_surface_3d.png")


# 4. Política de consumo: c efectivo y gasto
def fig_consumption_policy(d, out):
    a, z, c, exp_cons, Ns = d["a"], d["z"], d["c"], d["exp_cons"], d["Ns"]
    fig, axes = plt.subplots(1, 2, figsize=(11, 5))
    for j in [d["j_low"], d["j_high"]]:
        col, ls, lw = z_style(j, Ns)
        lbl = z_label(j, z, Ns)
        axes[0].plot(a, c[:, j],        ls, color=col, lw=lw, label=lbl)
        axes[1].plot(a, exp_cons[:, j], ls, color=col, lw=lw, label=lbl)
    for ax, ylbl in zip(axes, ["Consumo efectivo CES, $c(a,z)$",
                                "Gasto monetario, $c_F + p_I c_I$"]):
        ax.set_xlim(d["zoom_lo"], d["zoom_hi"])
        ax.set_xlabel("Riqueza, $a$")
        ax.set_ylabel(ylbl)
        ax.legend(loc="upper left")
        moll_ax(ax)
    caption(fig, "Consumo efectivo CES (izq) y gasto monetario (der) por riqueza")
    fig.tight_layout()
    save(fig, out / "moll_consumption_policy.png")


# 5. Consumo + oferta laboral total por riqueza
def fig_consumption_labor_policy(d, out):
    if d["ell_F"] is None:
        return
    a, z, c, ell_F, ell_I, Ns = d["a"], d["z"], d["c"], d["ell_F"], d["ell_I"], d["Ns"]
    fig, axes = plt.subplots(1, 2, figsize=(11, 5))
    for j in [d["j_low"], d["j_high"]]:
        col, ls, lw = z_style(j, Ns)
        lbl = z_label(j, z, Ns)
        axes[0].plot(a, c[:, j],                    ls, color=col, lw=lw, label=lbl)
        axes[1].plot(a, ell_F[:, j] + ell_I[:, j], ls, color=col, lw=lw, label=lbl)
    axes[0].set_xlabel("Riqueza, $a$"); axes[0].set_ylabel("Consumo efectivo")
    axes[1].set_xlabel("Riqueza, $a$"); axes[1].set_ylabel("Horas totales $\\ell_F + \\ell_I$")
    for ax in axes:
        ax.set_xlim(d["zoom_lo"], d["zoom_hi"])
        ax.legend()
        moll_ax(ax)
    caption(fig, "Políticas de consumo y oferta laboral total por riqueza")
    fig.tight_layout()
    save(fig, out / "moll_consumption_labor_policy_by_wealth.png")


# 6. Distribución de consumo y gasto (global)
def fig_consumption_distribution(d, out):
    c, exp_cons, w_all = d["c"], d["exp_cons"], d["w_all"]
    xC, pdfC = weighted_pdf(c.ravel(),        w_all)
    xE, pdfE = weighted_pdf(exp_cons.ravel(), w_all)
    fig, ax = plt.subplots(figsize=(7, 5))
    if xC.size: ax.plot(xC, pdfC, "-",  color=BLUE, lw=2.0, label="Consumo efectivo $C$")
    if xE.size: ax.plot(xE, pdfE, "--", color=RED,  lw=2.0, label="Gasto $c_F + p_I c_I$")
    ax.set_xlabel("Consumo / gasto")
    ax.set_ylabel("Densidad ponderada")
    ax.legend()
    moll_ax(ax)
    caption(fig, "Distribución estacionaria de consumo y gasto")
    save(fig, out / "moll_consumption_distribution.png")


# 7. Distribución de componentes c_F y p_I*c_I (global)
def fig_consumption_components_dist(d, out):
    c_F, c_I, w_all = d["c_F"], d["c_I"], d["w_all"]
    p_i = d["p_i"]
    xF, pdfF = weighted_pdf(c_F.ravel(),         w_all)
    xI, pdfI = weighted_pdf((p_i * c_I).ravel(), w_all)
    fig, ax = plt.subplots(figsize=(7, 5))
    if xF.size: ax.plot(xF, pdfF, "-",  color=BLUE, lw=2.0, label="$c_F$")
    if xI.size: ax.plot(xI, pdfI, "--", color=RED,  lw=2.0, label="$p_I c_I$")
    ax.set_xlabel("Gasto por componente")
    ax.set_ylabel("Densidad ponderada")
    ax.legend()
    moll_ax(ax)
    caption(fig, "Distribución de componentes de consumo formal e informal")
    save(fig, out / "moll_consumption_components_distribution.png")


# 8. Componentes de consumo por z (medias condicionales)
def fig_consumption_components_by_z(d, out):
    z = d["z"]
    fig, axes = plt.subplots(1, 2, figsize=(11, 5))
    axes[0].plot(z, d["mean_cF_by_z"],    "-o",  color=BLUE, lw=2.0, ms=5, label="Consumo formal $c_F$")
    axes[0].plot(z, d["mean_pIcI_by_z"],  "--s", color=RED,  lw=2.0, ms=5, label="Gasto informal $p_I c_I$")
    axes[0].set_xlabel("Productividad, $z$")
    axes[0].set_ylabel("Media condicional por $z$")
    axes[0].legend(loc="upper left")
    moll_ax(axes[0])

    axes[1].plot(z, d["share_cF_by_z"],    "-o",  color=BLUE, lw=2.0, ms=5, label="Participación formal")
    axes[1].plot(z, d["share_pIcI_by_z"],  "--s", color=RED,  lw=2.0, ms=5, label="Participación informal")
    axes[1].set_ylim(0, 1)
    axes[1].set_xlabel("Productividad, $z$")
    axes[1].set_ylabel("Participación en el gasto total")
    axes[1].legend()
    moll_ax(axes[1])

    caption(fig, "Consumo formal e informal por productividad OU")
    fig.tight_layout()
    save(fig, out / "moll_consumption_components_by_z.png")


# 9. Distribución de componentes por grupos z (bajo/medio/alto)
def fig_consumption_components_by_z_groups(d, out):
    a, z, g, da = d["a"], d["z"], d["g"], d["da"]
    c_F, c_I, p_i = d["c_F"], d["c_I"], d["p_i"]
    Ns = d["Ns"]
    groups = [
        (d["j_low"],  z_label(d["j_low"],  z, Ns), BLUE),
        (d["j_mid"],  z_label(d["j_mid"],  z, Ns), GRAY),
        (d["j_high"], z_label(d["j_high"], z, Ns), RED),
    ]
    all_w = np.tile(g * da, 2).ravel()
    all_x = np.concatenate([c_F.ravel(), (p_i * c_I).ravel()])
    xlo, xhi = weighted_quantile(all_x, all_w, [0.001, 0.999])
    if not (np.isfinite(xlo) and np.isfinite(xhi) and xhi > xlo):
        xlo, xhi = float(np.nanmin(all_x)), float(np.nanmax(all_x))
    ratio = c_F / np.maximum(p_i * c_I, 1e-12)
    ratio_mean = float(np.nanmean(ratio))
    ratio_sd = float(np.nanstd(ratio))

    fig, axes = plt.subplots(1, 3, figsize=(15.5, 5.2), sharex=True, sharey=True)
    legend_handles = None
    legend_labels = None
    for ax, (j, lbl, col) in zip(axes, groups):
        w_j = g[:, j] * da
        xF, pdfF = weighted_pdf(c_F[:, j],         w_j)
        xI, pdfI = weighted_pdf((p_i * c_I[:, j]), w_j)
        if xF.size:
            ax.plot(xF, _normalize_pdf(pdfF), "-", color=BLUE, lw=1.8, label="$c_F$")
        if xI.size:
            ax.plot(xI, _normalize_pdf(pdfI), "--", color=RED, lw=1.8, label="$p_I c_I$")
        # marcar la media
        mean_cF   = (g[:, j] * da * c_F[:, j]).sum() / max(w_j.sum(), 1e-12)
        mean_pIcI = (g[:, j] * da * p_i * c_I[:, j]).sum() / max(w_j.sum(), 1e-12)
        ax.axvline(mean_cF,   color=BLUE, lw=0.8, ls=":", alpha=0.75)
        ax.axvline(mean_pIcI, color=RED, lw=0.8, ls=":", alpha=0.75)
        ax.set_title(f"{lbl}\nmedia c_F={mean_cF:.2f}; p_I c_I={mean_pIcI:.2f}", fontsize=9)
        ax.set_xlabel("Gasto por componente")
        ax.set_xlim(xlo, xhi)
        moll_ax(ax)
        if legend_handles is None:
            legend_handles, legend_labels = ax.get_legend_handles_labels()
    caption(fig, "Distribución de c_F y p_I·c_I condicional en grupo z (bajo/medio/alto)")
    fig.texts.clear()
    axes[0].set_ylabel("Densidad condicional normalizada")
    if legend_handles:
        fig.legend(
            legend_handles, legend_labels,
            loc="upper center", bbox_to_anchor=(0.5, 0.97),
            ncol=2, fontsize=9, frameon=False,
        )
    if ratio_sd < 1e-8 and np.isfinite(ratio_mean):
        note = f"CES homotetico: c_F/(p_I c_I)={ratio_mean:.2f} constante; ejes comunes muestran la escala."
    else:
        note = "Distribucion condicional por grupo z; ejes comunes para comparar niveles."
    caption(fig, note)
    fig.tight_layout(rect=[0.03, 0.10, 0.99, 0.88])
    save(fig, out / "moll_consumption_components_distribution_by_z_groups.png")


# 10. Política laboral: ell_F y ell_I por riqueza
def fig_labor_policy(d, out):
    if d["ell_F"] is None:
        return
    a, z, ell_F, ell_I, Ns = d["a"], d["z"], d["ell_F"], d["ell_I"], d["Ns"]
    fig, axes = plt.subplots(1, 2, figsize=(11, 5))
    for j in [d["j_low"], d["j_high"]]:
        col, ls, lw = z_style(j, Ns)
        lbl = z_label(j, z, Ns)
        axes[0].plot(a, ell_F[:, j], ls, color=col, lw=lw, label=lbl)
        axes[1].plot(a, ell_I[:, j], ls, color=col, lw=lw, label=lbl)
    for ax, ylbl in zip(axes, ["Horas formales $\\ell_F(a,z)$",
                                "Horas informales $\\ell_I(a,z)$"]):
        ax.set_xlim(d["zoom_lo"], d["zoom_hi"])
        ax.set_xlabel("Riqueza, $a$")
        ax.set_ylabel(ylbl)
        ax.legend()
        moll_ax(ax)
    caption(fig, "Políticas laborales por riqueza: z bajo (azul) y z alto (rojo)")
    fig.tight_layout()
    save(fig, out / "moll_labor_policy_by_wealth.png")


# 11. Oferta laboral por productividad (medias condicionales)
def fig_labor_by_productivity(d, out):
    if d["ell_F"] is None:
        return
    z = d["z"]
    ellF, ellI = d["mean_ellF_by_z"], d["mean_ellI_by_z"]
    tot = ellF + ellI
    fig, axes = plt.subplots(1, 2, figsize=(11, 5))
    axes[0].plot(z, ellF + ellI, "-o",  color=BLACK, lw=1.8, ms=5, label="Horas totales")
    axes[0].plot(z, ellF,        "-o",  color=BLUE,  lw=1.8, ms=5, label="Horas formales")
    axes[0].plot(z, ellI,        "--s", color=RED,   lw=1.8, ms=5, label="Horas informales")
    axes[0].set_xlabel("Productividad, $z$")
    axes[0].set_ylabel("Horas promedio $E[\\ell|z]$")
    axes[0].legend()
    moll_ax(axes[0])

    # Panel derecho: horas totales contra riqueza para z bajo/med/alto
    a, g, da, ell_F, ell_I = d["a"], d["g"], d["da"], d["ell_F"], d["ell_I"]
    Ns = d["Ns"]
    for j in [d["j_low"], d["j_mid"], d["j_high"]]:
        col, ls, lw = z_style(j, d["Ns"])
        axes[1].plot(a, ell_F[:, j] + ell_I[:, j], ls, color=col, lw=lw, label=z_label(j, z, Ns))
    axes[1].set_xlim(d["zoom_lo"], d["zoom_hi"])
    axes[1].set_xlabel("Riqueza, $a$")
    axes[1].set_ylabel("Horas totales elegidas")
    axes[1].legend()
    moll_ax(axes[1])

    caption(fig, "Oferta laboral total y composición por productividad OU")
    fig.tight_layout()
    save(fig, out / "moll_labor_supply_by_productivity.png")


# 12. Uso del tiempo por z: con ocio
def fig_time_use_with_leisure(d, out):
    if d["ell_F"] is None:
        return
    z, Ns = d["z"], d["Ns"]
    H_bar  = d["H_bar"]
    ellF_z = d["mean_ellF_by_z"]
    ellI_z = d["mean_ellI_by_z"]
    leisure_z = np.maximum(H_bar - ellF_z - ellI_z, 0.0)
    total_z   = np.maximum(ellF_z + ellI_z + leisure_z, 1e-12)
    # Porcentajes
    pct_F  = 100 * ellF_z    / total_z
    pct_I  = 100 * ellI_z    / total_z
    pct_L  = 100 * leisure_z / total_z

    x = np.arange(Ns)
    fig, ax = plt.subplots(figsize=(max(7, Ns * 0.55), 5))
    # Orden MATLAB: Formal (abajo, azul), Informal (medio, rojo), Ocio (arriba, gris)
    ax.bar(x, pct_F,                   color=BLUE, alpha=0.9, label="Formal")
    ax.bar(x, pct_I, bottom=pct_F,     color=RED,  alpha=0.9, label="Informal")
    ax.bar(x, pct_L, bottom=pct_F+pct_I, color=GRAY, alpha=0.75, label="Ocio")

    # Anotaciones % dentro de cada segmento
    for i in range(Ns):
        segs = [(0,          pct_F[i], "white"),
                (pct_F[i],  pct_I[i], "white"),
                (pct_F[i]+pct_I[i], pct_L[i], BLACK)]
        for bot, h, col in segs:
            if h > 4:
                ax.text(i, bot + h/2, f"{h:.0f}%", ha="center", va="center",
                        fontsize=7 if Ns > 15 else 9, color=col)

    ax.set_xticks(x)
    ax.set_xticklabels([f"{v:.2f}" for v in z], fontsize=7 if Ns > 15 else 9, rotation=45)
    ax.set_xlabel("Productividad, $z$")
    ax.set_ylabel("Uso medio del tiempo")
    ax.set_ylim(0, 100)
    ax.legend(loc="upper right")
    moll_ax(ax)
    caption(fig, "Figura: uso del tiempo por productividad")
    fig.tight_layout()
    save(fig, out / "moll_time_use_by_z_with_leisure.png")


# 12b. Tendencia de uso del tiempo vs z (líneas — compacto para Nz grande)
def fig_time_use_trend(d, out):
    if d["ell_F"] is None:
        return
    z, Ns = d["z"], d["Ns"]
    H_bar  = d["H_bar"]
    ellF_z = d["mean_ellF_by_z"]
    ellI_z = d["mean_ellI_by_z"]
    leisure_z = np.maximum(H_bar - ellF_z - ellI_z, 0.0)
    total_z   = np.maximum(ellF_z + ellI_z + leisure_z, 1e-12)
    pct_F = 100 * ellF_z    / total_z
    pct_I = 100 * ellI_z    / total_z
    pct_L = 100 * leisure_z / total_z
    work_tot = np.maximum(ellF_z + ellI_z, 1e-12)
    pct_Fw = 100 * ellF_z / work_tot
    pct_Iw = 100 * ellI_z / work_tot

    fig, axes = plt.subplots(1, 2, figsize=(12, 5))

    # Panel izq: con ocio
    axes[0].plot(z, pct_L, "-",  color=GRAY,  lw=2.0, label="Ocio")
    axes[0].plot(z, pct_I, "--", color=RED,   lw=2.0, label="Informal")
    axes[0].plot(z, pct_F, ":",  color=BLUE,  lw=2.0, label="Formal")
    axes[0].set_xlabel("Productividad, $z$")
    axes[0].set_ylabel("% del tiempo disponible")
    axes[0].set_ylim(0, 100)
    axes[0].set_title("Con ocio", fontsize=10)
    axes[0].legend()
    moll_ax(axes[0])

    # Panel der: sin ocio (solo horas trabajadas)
    axes[1].plot(z, pct_Iw, "--", color=RED,  lw=2.0, label="Informal")
    axes[1].plot(z, pct_Fw, "-",  color=BLUE, lw=2.0, label="Formal")
    axes[1].set_xlabel("Productividad, $z$")
    axes[1].set_ylabel("% del tiempo trabajado")
    axes[1].set_ylim(0, 100)
    axes[1].set_title("Sin ocio (sorting sectorial)", fontsize=10)
    axes[1].legend()
    moll_ax(axes[1])

    caption(fig, "Tendencia de uso del tiempo por productividad OU (izq: con ocio, der: sin ocio)")
    fig.tight_layout()
    save(fig, out / "moll_time_use_trend_by_z.png")


# 13. Uso del tiempo por z: sin ocio
def fig_time_use_without_leisure(d, out):
    if d["ell_F"] is None:
        return
    z, Ns = d["z"], d["Ns"]
    ellF_z = d["mean_ellF_by_z"]
    ellI_z = d["mean_ellI_by_z"]
    work_total = np.maximum(ellF_z + ellI_z, 1e-12)
    pct_F = 100 * ellF_z / work_total
    pct_I = 100 * ellI_z / work_total

    x = np.arange(Ns)
    fig, ax = plt.subplots(figsize=(max(7, Ns * 0.55), 5))
    ax.bar(x, pct_I, color=RED,  alpha=0.85, label="Informal")
    ax.bar(x, pct_F, bottom=pct_I, color=BLUE, alpha=0.85, label="Formal")
    ax.set_xticks(x)
    ax.set_xticklabels([f"{v:.2f}" for v in z], fontsize=8, rotation=45)
    ax.set_xlabel("Estado de productividad, $z$")
    ax.set_ylabel("% del tiempo trabajado")
    ax.set_ylim(0, 100)
    ax.legend(loc="upper right")
    moll_ax(ax)
    caption(fig, "Sorting sectorial (sin ocio): % formal e informal por z")
    fig.tight_layout()
    save(fig, out / "moll_time_use_by_z_excluding_leisure.png")


# 14. Descomposición de ingreso por quintil de riqueza (niveles) — 2 paneles
def fig_income_quintile_levels(d, out):
    if d["income_formal"] is None:
        return
    aa_flat = d["aa"].ravel()
    w_flat  = d["w_all"]
    q_masks = quintile_masks(aa_flat, w_flat, n=5)
    qlabels = ["Q1", "Q2", "Q3", "Q4", "Q5"]

    inc_F  = d["income_formal"].ravel()
    inc_I  = d["income_informal"].ravel()
    inc_ra = d["income_assets"].ravel()
    inc_T  = d["income_transfer"].ravel()
    exp_c  = d["exp_cons"].ravel()

    def qmean(v, m): return (v[m] * w_flat[m]).sum() / max(w_flat[m].sum(), 1e-12)

    Q_F   = np.array([qmean(inc_F,  m) for m in q_masks])
    Q_I   = np.array([qmean(inc_I,  m) for m in q_masks])
    Q_ra  = np.array([qmean(inc_ra, m) for m in q_masks])
    Q_T   = np.array([qmean(inc_T,  m) for m in q_masks])
    Q_net = Q_F + Q_I + Q_ra + Q_T
    Q_exp = np.array([qmean(exp_c,  m) for m in q_masks])
    Q_sav = Q_net - Q_exp

    x = np.arange(5)
    fig, axes = plt.subplots(1, 2, figsize=(14, 5))

    # Panel izq: barras apiladas (Lab. formal, Lab. informal, Capital, Transfer.)
    # Orden MATLAB: formal(azul), informal(rojo), capital(verde), transfer(gris)
    axes[0].bar(x, Q_F,  color=BLUE,  alpha=0.9, label="Lab. formal")
    axes[0].bar(x, Q_I,  bottom=Q_F,                        color=RED,   alpha=0.9, label="Lab. informal")
    axes[0].bar(x, Q_ra, bottom=Q_F + Q_I,                  color=GREEN, alpha=0.9, label="Capital")
    axes[0].bar(x, Q_T,  bottom=Q_F + Q_I + Q_ra,           color=GRAY,  alpha=0.9, label="Transfer.")
    axes[0].plot(x, Q_net, "-o", color=BLACK, lw=1.6, ms=5, label="Ingreso neto")
    axes[0].set_xticks(x); axes[0].set_xticklabels(qlabels)
    axes[0].set_xlabel("Quintil de riqueza")
    axes[0].set_ylabel("Ingreso medio")
    axes[0].legend(loc="upper left", fontsize=8)
    moll_ax(axes[0])

    # Panel der: líneas ingreso neto / gasto / ahorro
    axes[1].plot(x, Q_net, "-o",  color=BLUE,  lw=2.0, ms=5, label="Ingreso neto")
    axes[1].plot(x, Q_exp, "--s", color=RED,   lw=2.0, ms=5, label="Gasto")
    axes[1].plot(x, Q_sav, ":^",  color=GREEN, lw=1.8, ms=5, label="Ahorro")
    axes[1].axhline(0, color=BLACK, lw=0.6, ls="--")
    axes[1].set_xticks(x); axes[1].set_xticklabels(qlabels)
    axes[1].set_xlabel("Quintil de riqueza")
    axes[1].set_ylabel("Media dentro del quintil")
    axes[1].legend(fontsize=8)
    moll_ax(axes[1])

    caption(fig, "Figura: descomposición del ingreso medio por quintil de riqueza")
    fig.tight_layout()
    save(fig, out / "moll_income_decomposition_by_wealth_quintile.png")


# 15. Descomposición de ingreso por quintil (porcentajes apilados)
def fig_income_quintile_pct(d, out):
    if d["income_formal"] is None:
        return
    aa_flat = d["aa"].ravel()
    w_flat  = d["w_all"]
    q_masks = quintile_masks(aa_flat, w_flat, n=5)
    qlabels = ["Q1", "Q2", "Q3", "Q4", "Q5"]

    inc_F  = d["income_formal"].ravel()
    inc_I  = d["income_informal"].ravel()
    inc_ra = d["income_assets"].ravel()
    inc_T  = d["income_transfer"].ravel()

    Q_F  = np.array([(inc_F[m]  * w_flat[m]).sum() / max(w_flat[m].sum(), 1e-12) for m in q_masks])
    Q_I  = np.array([(inc_I[m]  * w_flat[m]).sum() / max(w_flat[m].sum(), 1e-12) for m in q_masks])
    Q_ra = np.array([(inc_ra[m] * w_flat[m]).sum() / max(w_flat[m].sum(), 1e-12) for m in q_masks])
    Q_T  = np.array([(inc_T[m]  * w_flat[m]).sum() / max(w_flat[m].sum(), 1e-12) for m in q_masks])
    tot  = np.maximum(Q_F + Q_I + Q_ra + Q_T, 1e-12)

    pF  = 100 * Q_F  / tot
    pI  = 100 * Q_I  / tot
    pra = 100 * Q_ra / tot
    pT  = 100 * Q_T  / tot

    x = np.arange(5)
    fig, ax = plt.subplots(figsize=(8, 5))
    ax.bar(x, pF,  color=BLUE,  alpha=0.9, label="Formal")
    ax.bar(x, pI,  bottom=pF,                color=RED,   alpha=0.9, label="Informal")
    ax.bar(x, pra, bottom=pF + pI,           color=GRAY,  alpha=0.9, label="Capital")
    ax.bar(x, pT,  bottom=pF + pI + pra,     color=GREEN, alpha=0.9, label="Transferencia")

    # Anotaciones porcentaje dentro de cada barra
    for i in range(5):
        bots = [0, pF[i], pF[i]+pI[i], pF[i]+pI[i]+pra[i]]
        vals = [pF[i], pI[i], pra[i], pT[i]]
        for bot, val in zip(bots, vals):
            if val > 4:
                ax.text(i, bot + val/2, f"{val:.0f}%", ha="center", va="center",
                        fontsize=8, color="white", fontweight="bold")

    ax.set_xticks(x); ax.set_xticklabels(qlabels)
    ax.set_xlabel("Quintil de riqueza")
    ax.set_ylabel("% del ingreso total")
    ax.set_ylim(0, 100)
    ax.legend(loc="upper right")
    moll_ax(ax)
    caption(fig, "Composición del ingreso (%) por quintil de riqueza")
    fig.tight_layout()
    save(fig, out / "moll_income_decomposition_percent_by_wealth_quintile.png")


# 16. Informalidad por z (margen intensivo)
def fig_informality_by_z(d, out):
    if d["ell_F"] is None:
        return
    z = d["z"]
    form  = d["form_share_by_z"]
    infor = 1.0 - form
    fig, ax = plt.subplots(figsize=(8.2, 5.2))
    ax.plot(z, infor, "-s",  color=RED,  lw=2.0, ms=5, label="Horas informales / totales")
    ax.plot(z, form,  "-o",  color=BLUE, lw=2.0, ms=5, label="Horas formales / totales")
    ax.set_ylim(0, 1)
    ax.set_xlabel("Productividad, $z$")
    ax.set_ylabel("Participación de horas")
    ax.legend(
        loc="lower center", bbox_to_anchor=(0.5, 1.02),
        ncol=2, fontsize=9, frameon=False,
    )
    moll_ax(ax)
    caption(fig, "Informalidad en margen intensivo por productividad OU")
    fig.tight_layout(rect=[0.06, 0.12, 0.99, 0.86])
    save(fig, out / "moll_informality_by_z.png")


# 17. Deuda por z
def fig_debt_by_z(d, out):
    z = d["z"]
    fig, axes = plt.subplots(1, 2, figsize=(11, 5))
    axes[0].plot(z, d["mass_debt_by_z"], "--s", color=RED, lw=2.0, ms=5)
    axes[0].set_ylim(0, min(1.0, max(0.05, 1.15 * d["mass_debt_by_z"].max())))
    axes[0].set_xlabel("Productividad, $z$")
    axes[0].set_ylabel("$\\Pr(a < 0 \\mid z)$")
    axes[0].set_title("Fracción en deuda por $z$", fontsize=10)
    moll_ax(axes[0])

    axes[1].plot(z, d["mean_a_debt_by_z"], "--s", color=BLUE, lw=2.0, ms=5)
    axes[1].set_xlabel("Productividad, $z$")
    axes[1].set_ylabel("$E[a \\mid a < 0, z]$")
    axes[1].set_title("Deuda media condicional por $z$", fontsize=10)
    moll_ax(axes[1])

    caption(fig, "Endeudamiento por productividad: fracción y deuda media condicional")
    fig.tight_layout()
    save(fig, out / "moll_debt_probability_by_z.png")


# 18. Distribución de gasto por formalidad dominante
def fig_gasto_by_formality(d, out):
    if d["ell_F"] is None:
        return
    exp_cons, ell_F, ell_I, w_all = d["exp_cons"], d["ell_F"], d["ell_I"], d["w_all"]
    x = exp_cons.ravel()
    formal   = (ell_F.ravel() >= ell_I.ravel())
    informal = ~formal

    def wstats(xv, wv):
        wv = np.maximum(wv, 0)
        tot = wv.sum()
        if tot < 1e-12 or xv.size == 0:
            return np.nan, np.nan, np.nan, 0.0
        wn  = wv / tot
        mu  = float((xv * wn).sum())
        sd  = float(np.sqrt(((xv - mu)**2 * wn).sum()))
        med = float(weighted_quantile(xv, wv, [0.5])[0])
        frac = float(tot / max(w_all.sum(), 1e-12))
        return mu, sd, med, frac

    fig, axes = plt.subplots(1, 3, figsize=(14, 5), sharey=True)
    groups = [(formal, BLUE, "Formal dominante"),
              (informal, RED, "Informal dominante"),
              (np.ones_like(formal, bool), GRAY, "Total")]
    for ax, (mask, col, ttl) in zip(axes, groups):
        xm, wm = x[mask], w_all[mask]
        xg, pg = weighted_pdf(xm, wm)
        if xg.size:
            ax.fill_between(xg, pg, alpha=0.3, color=col)
            ax.plot(xg, pg, color=BLACK, lw=1.6)
        mu, sd, med, frac = wstats(xm, wm)
        if np.isfinite(mu):
            ax.axvline(mu,  color=BLACK, lw=1.2, ls="-",  label=f"Media={mu:.3f}")
            ax.axvline(med, color=col,   lw=1.0, ls="--", label=f"Mediana={med:.3f}")
        # Caja de estadísticas
        stats_txt = (f"media={mu:.3f}\ndesv.est.={sd:.3f}\n"
                     f"mediana={med:.3f}\nfracción={100*frac:.1f}%")
        ax.text(0.97, 0.97, stats_txt, transform=ax.transAxes,
                ha="right", va="top", fontsize=8,
                bbox=dict(boxstyle="round,pad=0.3", facecolor="white", alpha=0.7))
        ax.set_xlabel("Gasto $c_F + p_I c_I$")
        ax.set_ylabel("Densidad")
        ax.set_title(ttl, fontsize=10)
        moll_ax(ax)
    caption(fig, "Distribución del gasto por sector dominante (ℓ_F≥ℓ_I vs ℓ_I>ℓ_F)")
    fig.tight_layout()
    save(fig, out / "moll_model_gasto_distribution_by_formality.png")


# 19. Curvas de Lorenz y Gini
def fig_lorenz(d, out):
    exp_cons, w_all = d["exp_cons"], d["w_all"]
    aa_flat = d["aa"].ravel()
    pop_a, lorenz_a, gini_a = lorenz_gini(aa_flat, w_all)
    pop_c, lorenz_c, gini_c = lorenz_gini(exp_cons.ravel(), w_all)

    fig, ax = plt.subplots(figsize=(7, 5.5))
    ax.plot([0, 1], [0, 1], ":", color=GRAY, lw=1.2, label="45°")
    ax.plot(pop_a, lorenz_a, "-",  color=BLUE, lw=2.0, label=f"Riqueza neta, Gini={gini_a:.3f}")
    ax.plot(pop_c, lorenz_c, "--", color=RED,  lw=2.0, label=f"Gasto, Gini={gini_c:.3f}")
    ax.set_xlim(0, 1); ax.set_ylim(0, 1)
    ax.set_xlabel("Población acumulada")
    ax.set_ylabel("Participación acumulada")
    ax.legend(loc="upper left")
    moll_ax(ax)
    caption(fig, "Curvas de Lorenz y coeficientes de Gini")
    save(fig, out / "moll_lorenz_curves.png")

    with (out / "moll_lorenz_curves.txt").open("w", encoding="utf-8") as f:
        f.write(f"Gini_riqueza_neta={gini_a:.10f}\n")
        f.write(f"Gini_gasto={gini_c:.10f}\n")

    return gini_a, gini_c


# 20. Prima de deuda + desigualdad por z
def fig_debt_premium_inequality(d, out):
    z = d["z"]
    dspread = d.get("debt_spread_z")
    if dspread is None:
        dspread = np.zeros(d["Ns"])

    fig, axes = plt.subplots(1, 2, figsize=(11, 5))
    axes[0].plot(z, 100 * dspread, "--s", color=RED, lw=2.0, ms=5, label="Prima de deuda")
    axes[0].set_xlabel("Productividad, $z$")
    axes[0].set_ylabel("Prima sobre deuda (p.p.)")
    axes[0].legend()
    moll_ax(axes[0])

    axes[1].plot(z, d["gini_C_by_z"],   "-o",  color=BLUE, lw=2.0, ms=5, label="Gini consumo efectivo")
    axes[1].plot(z, d["gini_exp_by_z"], "--s", color=RED,  lw=2.0, ms=5, label="Gini gasto")
    vmax = max(np.nanmax(d["gini_C_by_z"]), np.nanmax(d["gini_exp_by_z"]))
    if np.isfinite(vmax) and vmax > 0:
        axes[1].set_ylim(0, 1.15 * vmax)
    axes[1].set_xlabel("Productividad, $z$")
    axes[1].set_ylabel("Desigualdad dentro de cada $z$")
    axes[1].legend()
    moll_ax(axes[1])

    caption(fig, "Prima de deuda y gradiente de desigualdad por productividad")
    fig.tight_layout()
    save(fig, out / "moll_debt_premium_inequality_by_z.png")


# 21. Masas OU vs KFE
def fig_ou_masses(d, out):
    z, g, da, Ns = d["z"], d["g"], d["da"], d["Ns"]
    mass_model = g.sum(axis=0) * da
    mass_model /= max(mass_model.sum(), 1e-12)
    pi_z_ar = d["pi_z_ar"]
    if pi_z_ar is None:
        pi_z_ar = mass_model.copy()

    fig, ax = plt.subplots(figsize=(max(7, Ns * 0.55), 5))
    x = np.arange(1, Ns + 1)
    ax.bar(x, pi_z_ar, 0.58, color=BLUE, alpha=0.8, label="Masa ergódica OU")
    ax.plot(x, mass_model, "s", color=RED, mfc="white", mew=1.8, ms=6, label="Masa KFE modelo")
    ax.set_xticks(x)
    ax.set_xticklabels([f"{v:.2f}" for v in z], fontsize=8, rotation=45)
    ax.set_xlabel("Estado de productividad, $z$")
    ax.set_ylabel("Masa")
    if np.isfinite(d["rho_z"]) and np.isfinite(d["sd_z"]):
        ax.text(0.02, 0.95, f"$\\rho={d['rho_z']:.3f}$,  $\\sigma(\\log z)={d['sd_z']:.3f}$",
                transform=ax.transAxes, va="top", fontsize=10)
    ax.legend()
    moll_ax(ax)
    caption(fig, "Masa estacionaria del proceso Ornstein-Uhlenbeck discretizado")
    fig.tight_layout()
    save(fig, out / "moll_ou_stationary_masses.png")


# 22. Momentos condicionales por z
def fig_conditional_moments(d, out):
    z = d["z"]
    fig, axes = plt.subplots(1, 2, figsize=(11, 5))
    axes[0].plot(z, d["mean_a_by_z"],   "-o", color=BLUE, lw=2.0, ms=5)
    axes[0].set_xlabel("Productividad, $z$")
    axes[0].set_ylabel("Activos promedio, $E[a|z]$")
    moll_ax(axes[0])

    axes[1].plot(z, d["mean_exp_by_z"], "--s", color=RED, lw=2.0, ms=5)
    axes[1].set_xlabel("Productividad, $z$")
    axes[1].set_ylabel("Gasto promedio, $E[c_F + p_I c_I | z]$")
    moll_ax(axes[1])

    caption(fig, "Activos y gasto promedio condicionales en productividad OU")
    fig.tight_layout()
    save(fig, out / "moll_conditional_moments_by_z.png")


# 23. Equilibrio: S(r) y KD(r)
def fig_equilibrium(d, out):
    if d["r_grid"] is None or d["S_curve"] is None or d["KD_curve"] is None:
        return
    r, S, KD = d["r_grid"], d["S_curve"], d["KD_curve"]
    fig, ax = plt.subplots(figsize=(7, 5))
    ax.plot(r, S,  "-",  color=BLUE, lw=2.0, label="Oferta de activos $S(r)$")
    ax.plot(r, KD, "--", color=RED,  lw=2.0, label="Demanda de capital $K^D(r)$")
    ax.set_xlabel("Tasa de interés, $r$")
    ax.set_ylabel("Nivel agregado")
    ax.legend()
    moll_ax(ax)
    caption(fig, "Equilibrio estacionario en el mercado de activos")
    save(fig, out / "moll_equilibrium_asset_market.png")


# ---------------------------------------------------------------------------
# Calibration table helper
# ---------------------------------------------------------------------------

def _load_calib_struct(d):
    """Return calib MATLAB struct from calib_<tag>.mat next to results .mat, or None."""
    mat_path = d.get("mat_path")
    if mat_path is None:
        return None
    tag = mat_path.stem.replace("results_", "")
    calib_path = mat_path.parent / f"calib_{tag}.mat"
    if not calib_path.exists():
        return None
    try:
        m = loadmat(str(calib_path), squeeze_me=True, struct_as_record=False)
        return m.get("calib", None)
    except Exception:
        return None


def _csf(c, field, default=np.nan):
    """Safe scalar getter from calib struct."""
    if c is None:
        return default
    try:
        v = getattr(c, field)
        return float(np.asarray(v).ravel()[0])
    except Exception:
        return default


def fig_calibration_table(d, out):
    """
    Figura 24 — tabla de calibración con 3 paneles:
      Panel A: Parámetros fijos (con fuentes)
      Panel B: Parámetros calibrados → targets
      Panel C: Momentos Modelo vs. Datos
    """
    # ---- valores del equilibrio (results .mat tiene todo) ----
    r_star   = d["r_eq"]
    p_I      = d["p_i"]
    w_F_star = d["w_F"]
    w_I_star = d["w_I"]

    Y_F = d.get("Y_F", np.nan)
    Y_I = d.get("Y_I", np.nan)
    K_star = d.get("K_star", np.nan)
    Y_total = Y_F + Y_I if (np.isfinite(Y_F) and np.isfinite(Y_I)) else np.nan
    KY_ratio = K_star / Y_total if (np.isfinite(K_star) and np.isfinite(Y_total) and Y_total > 0) else np.nan

    # ---- momentos desde results .mat ----
    T4      = d.get("T4_model", np.nan)
    T5      = d.get("T5_nom",   np.nan)
    Tkz_m   = d.get("Tkz_m",   np.nan)
    Tgasto  = d.get("Tgasto_m", np.nan)
    T1_net  = d.get("T1_net",   np.nan)
    gini_a  = d.get("Gini_a_mat", np.nan)
    if not np.isfinite(gini_a):
        gini_a = weighted_gini(d["aa"].ravel(), d["w_all"])

    # ---- parámetros calibrados desde results .mat ----
    rho_disc = d.get("rho_disc", np.nan)
    ga_val   = d.get("ga_val",   np.nan)
    if not np.isfinite(ga_val):
        ga_val = 1.0   # conocido del setenv HA_IE_GA=1.0 (sesión 2026-06-25)
    psi_F    = d.get("psi_F_m",    np.nan)
    psi_I    = d.get("psi_I_m",    np.nan)
    kappa_z1 = d.get("kappa_z1_m", np.nan)
    omega_C  = d.get("omega_c",    np.nan)
    A_I      = d.get("al_val",     np.nan)   # al_val es al_formal; A_I viene de calib
    # A_I: buscar en calib struct como fallback
    c = _load_calib_struct(d)
    A_I = _csf(c, "A_I", np.nan)

    # fallbacks from d if calib struct missing
    def _fmt(v, dec=3):
        return f"{v:.{dec}f}" if np.isfinite(v) else "n/d"

    # -----------------------------------------------------------------------
    # Layout: 3 axes side-by-side in a wide figure
    # Left: Panel A (fixed params) — full height
    # Top-right: Panel B (calibrated)
    # Bottom-right: Panel C (moments)
    # -----------------------------------------------------------------------
    HDARK  = "#1a365d"   # header background
    HTEXT  = "white"
    ROW_A  = "#ebf4ff"   # alternating row light
    ROW_B  = "white"
    BORDER = "#a0aec0"

    def _draw_table(ax, header, rows, col_ws=None):
        ax.set_xlim(0, 1)
        ax.set_ylim(0, 1)
        ax.set_axis_off()
        n_cols = len(header)
        n_rows = len(rows) + 1

        row_h  = 1.0 / n_rows
        if col_ws is None:
            col_ws = [1.0 / n_cols] * n_cols

        xs = [0.0]
        for w in col_ws[:-1]:
            xs.append(xs[-1] + w)

        def _cell(ax_, x_, y_, w_, h_, text, bg, txt_color="black",
                  bold=False, fontsize=8.5, align="left"):
            from matplotlib.patches import FancyBboxPatch
            ax_.add_patch(plt.Rectangle((x_, y_), w_, h_,
                                        facecolor=bg, edgecolor=BORDER,
                                        linewidth=0.5, transform=ax_.transData,
                                        clip_on=False))
            pad = 0.012
            ha = "left" if align == "left" else "center"
            ax_.text(x_ + (pad if align == "left" else w_/2),
                     y_ + h_ / 2, text,
                     va="center", ha=ha,
                     fontsize=fontsize, color=txt_color,
                     fontweight="bold" if bold else "normal",
                     transform=ax_.transData, clip_on=False)

        # header row
        y_top = 1.0 - row_h
        for j, (hdr, x_, w_) in enumerate(zip(header, xs, col_ws)):
            _cell(ax, x_, y_top, w_, row_h, hdr, HDARK, HTEXT,
                  bold=True, fontsize=8.8, align="center")

        # data rows
        for i, row in enumerate(rows):
            y_ = y_top - (i + 1) * row_h
            bg = ROW_A if i % 2 == 0 else ROW_B
            for j, (cell_txt, x_, w_) in enumerate(zip(row, xs, col_ws)):
                _cell(ax, x_, y_, w_, row_h, str(cell_txt), bg,
                      fontsize=8.3, align="left")

    # -- Panel A: Parámetros fijos --
    hdr_A = ["Parámetro", "Símbolo", "Valor", "Fuente"]
    rows_A = [
        ["Capital share formal",      "α_F",   "0.636", "Céspedes et al. (2014, BCRP REE-28)"],
        ["Capital share informal",    "α_I",   "0.118", "Göbel et al. (2013, BCRP WP)"],
        ["Labor share informal",      "β_I",   "0.605", "Göbel et al. (2013, BCRP WP)"],
        ["Depreciación",              "δ",     "0.10",  "Castillo & Rojas (2014, BCRP REE-28)"],
        ["Impuesto sobre renta",      "τ",     "0.18",  "Galindo et al. (2024, BCRP DT-005)"],
        ["Frisch elasticidad",        "φ",     "0.38",  "Céspedes & Rendón (2012, BCRP WP)"],
        ["Persistencia z (anual)",    "ρ_z",   "0.861", "Hong (2022, J. Int. Econ.)"],
        ["Desv. estándar log z",      "σ_z",   "0.544", "Hong (2022, J. Int. Econ.)"],
        ["PTF formal (numéraire)",    "A_F",   "1.00",  "Normalización"],
        ["Tiempo disponible",         "H̄",    "1.00",  "Normalización"],
    ]

    # -- Panel B: Parámetros calibrados --
    hdr_B = ["Descripción", "Símbolo", "Valor", "Target / canal"]
    rows_B = [
        ["CRRA",                   "γ",    _fmt(ga_val, 1),   "Gini riqueza ≥ 0.40"],
        ["Descuento",              "ρ",    _fmt(rho_disc, 3), "K/Y = 2.73 (PWT 11.0)"],
        ["Peso formal CES",        "ω_C",  _fmt(omega_C, 2),  "p_I < 1 (bien inf. más barato)"],
        ["PTF informal",           "A_I",  _fmt(A_I, 2),      "T5 = 0.190 (PBI informal)"],
        ["Desutilidad formal",     "ψ_F",  _fmt(psi_F, 0),    "T4 = 0.557 (horas informales)"],
        ["Desutilidad informal",   "ψ_I",  _fmt(psi_I, 0),    "T4 = 0.557 (horas informales)"],
        ["Barrera formal (z)",     "κ_z",  _fmt(kappa_z1, 2), "Tkz = 0.386 (gap formalidad)"],
    ]

    # -- Panel C: Momentos modelo vs. datos --
    hdr_C = ["Momento", "Descripción", "Modelo", "Datos", "Fuente"]
    rows_C = [
        ["T4",    "Horas informales / total",    _fmt(T4, 3),    "0.557",  "INEI, Cuenta Satélite 2021"],
        ["T5",    "PBI informal / total (nom.)", _fmt(T5, 3),    "0.190",  "INEI, Cuenta Satélite 2021"],
        ["Tkz",   "Gap formalidad z₁ ↔ z₇",    _fmt(Tkz_m, 3), "0.386",  "ENAHO (años educ.)"],
        ["Tgasto","Gasto promedio F / I",        _fmt(Tgasto, 3),"1.913",  "ENAHO 2015-2019"],
        ["T1",    "Brecha salarial neta",        _fmt(T1_net, 2), "~2.30", "BCR (Galindo 2024)"],
        ["Gini_a","Gini riqueza",                _fmt(gini_a, 3), "≥0.40", "Literatura HA"],
        ["K/Y",   "Capital-producto",            _fmt(KY_ratio, 2),"2.73", "PWT 11.0, Perú 2019"],
        ["p_I",   "Precio bien informal",        _fmt(p_I, 3),    "<1.00", "Restricción económica"],
    ]

    # ---- Figure layout ----
    fig = plt.figure(figsize=(16, 10))
    fig.patch.set_facecolor("white")

    # title
    run_tag = d.get("tag", "").replace("results_", "")
    fig.suptitle(f"Calibración del modelo  ·  {run_tag}",
                 fontsize=12, fontweight="bold", y=0.98, color="#1a202c")

    # Panel A: left column, full height (0.01–0.94 in y)
    ax_A = fig.add_axes([0.01, 0.01, 0.40, 0.91])
    ax_A.text(0.5, 1.02, "A. Parámetros fijos", transform=ax_A.transAxes,
              ha="center", fontsize=10, fontweight="bold", color="#2d3748")
    _draw_table(ax_A, hdr_A, rows_A, col_ws=[0.36, 0.10, 0.08, 0.46])

    # Panel B: top-right
    ax_B = fig.add_axes([0.43, 0.52, 0.56, 0.39])
    ax_B.text(0.5, 1.05, "B. Parámetros calibrados", transform=ax_B.transAxes,
              ha="center", fontsize=10, fontweight="bold", color="#2d3748")
    _draw_table(ax_B, hdr_B, rows_B, col_ws=[0.30, 0.10, 0.10, 0.50])

    # Panel C: bottom-right
    ax_C = fig.add_axes([0.43, 0.01, 0.56, 0.47])
    ax_C.text(0.5, 1.04, "C. Momentos: Modelo vs. Datos", transform=ax_C.transAxes,
              ha="center", fontsize=10, fontweight="bold", color="#2d3748")
    _draw_table(ax_C, hdr_C, rows_C, col_ws=[0.09, 0.30, 0.10, 0.10, 0.41])

    save(fig, out / "moll_calibration_table.png")


# ---------------------------------------------------------------------------
# Resumen texto
# ---------------------------------------------------------------------------

def write_summary(d, gini_a, gini_c, out):
    lines = [
        f"run_tag={d['tag']}",
        f"r_eq={d['r_eq']:.6f}",
        f"w_F={d['w_F']:.6f}",
        f"w_I={d['w_I']:.6f}",
        f"Gini_wealth={gini_a:.6f}",
        f"Gini_expenditure={gini_c:.6f}",
        f"rho_z_ar={d['rho_z']:.6f}",
        f"sd_logz_ar={d['sd_z']:.6f}",
    ]
    with (out / "run_summary.txt").open("w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def parse_args():
    p = argparse.ArgumentParser(description="Python plotter — 23 figuras Moll para modelo ARz+debtprem.")
    p.add_argument("--mat-file", required=True, help="Ruta al .mat de resultados.")
    p.add_argument("--out-dir",  default=None,
                   help="Directorio de salida (default: <carpeta_mat>/plots_python/).")
    return p.parse_args()


def main():
    args = parse_args()
    mat_path = Path(args.mat_file).resolve()
    if not mat_path.exists():
        sys.exit(f"Archivo no encontrado: {mat_path}")

    out = Path(args.out_dir).resolve() if args.out_dir else mat_path.parent / "plots_python"
    out.mkdir(parents=True, exist_ok=True)

    print(f"Cargando {mat_path.name} ...")
    d = load_mat(mat_path)
    print(f"  z grid: {d['z'].size} nodos, a grid: {d['a'].size} puntos")
    d = derive(d)
    setup_style()
    print(f"Generando figuras en {out} ...")

    fig_savings_policy(d, out)            # 1
    fig_wealth_distribution(d, out)       # 2
    fig_wealth_density_3groups(d, out)    # 3
    fig_wealth_density_marginal(d, out)   # 3b
    fig_density_surface_3d(d, out)        # 3c
    fig_savings_surface_3d(d, out)        # 3d
    fig_consumption_policy(d, out)        # 4
    fig_consumption_labor_policy(d, out)  # 5
    fig_consumption_distribution(d, out)  # 6
    fig_consumption_components_dist(d, out)      # 7
    fig_consumption_components_by_z(d, out)      # 8
    fig_consumption_components_by_z_groups(d, out) # 9
    fig_labor_policy(d, out)              # 10
    fig_labor_by_productivity(d, out)     # 11
    fig_time_use_with_leisure(d, out)     # 12
    fig_time_use_trend(d, out)            # 12b
    fig_time_use_without_leisure(d, out)  # 13
    fig_income_quintile_levels(d, out)    # 14
    fig_income_quintile_pct(d, out)       # 15
    fig_informality_by_z(d, out)          # 16
    fig_debt_by_z(d, out)                 # 17
    fig_gasto_by_formality(d, out)        # 18
    gini_a, gini_c = fig_lorenz(d, out)  # 19
    fig_debt_premium_inequality(d, out)   # 20
    fig_ou_masses(d, out)                 # 21
    fig_conditional_moments(d, out)       # 22
    fig_equilibrium(d, out)               # 23
    fig_calibration_table(d, out)         # 24

    write_summary(d, gini_a, gini_c, out)
    n = len(list(out.glob("*.png")))
    print(f"\nListo. {n} figuras en:\n  {out}")


if __name__ == "__main__":
    main()
