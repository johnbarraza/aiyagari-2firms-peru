from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch, FancyBboxPatch


ROOT = Path(__file__).resolve().parent
OUT_DIR = ROOT / "output_graphs_ou_debtprem"
OUT_FILE = OUT_DIR / "ou_debtprem_market_dag.png"


COLORS = {
    "state": "#E8F1F2",
    "household": "#F7E8B8",
    "distribution": "#EADCF8",
    "aggregate": "#DFF0D8",
    "market": "#FAD7D7",
    "closure": "#D6E4FF",
    "ink": "#24323F",
    "muted": "#5B6875",
}


def draw_node(ax, key, label, xy, wh=(2.8, 1.02), face="#FFFFFF", edge="#455A64",
              fontsize=9.2, weight="normal"):
    x, y = xy
    w, h = wh
    box = FancyBboxPatch(
        (x - w / 2, y - h / 2),
        w,
        h,
        boxstyle="round,pad=0.035,rounding_size=0.08",
        linewidth=1.25,
        edgecolor=edge,
        facecolor=face,
        zorder=2,
    )
    ax.add_patch(box)
    ax.text(
        x,
        y,
        label,
        ha="center",
        va="center",
        fontsize=fontsize,
        color=COLORS["ink"],
        fontweight=weight,
        linespacing=1.18,
        zorder=3,
    )
    return {"key": key, "x": x, "y": y, "w": w, "h": h}


def edge_point(node, side):
    if side == "right":
        return node["x"] + node["w"] / 2, node["y"]
    if side == "left":
        return node["x"] - node["w"] / 2, node["y"]
    if side == "top":
        return node["x"], node["y"] + node["h"] / 2
    if side == "bottom":
        return node["x"], node["y"] - node["h"] / 2
    raise ValueError(side)


def draw_arrow(ax, src, dst, src_side="right", dst_side="left", label=None,
               rad=0.0, color=None, lw=1.35, ls="-", label_offset=(0, 0),
               mutation_scale=12):
    color = color or COLORS["muted"]
    start = edge_point(src, src_side)
    end = edge_point(dst, dst_side)
    arrow = FancyArrowPatch(
        start,
        end,
        arrowstyle="-|>",
        mutation_scale=mutation_scale,
        linewidth=lw,
        linestyle=ls,
        color=color,
        connectionstyle=f"arc3,rad={rad}",
        shrinkA=4,
        shrinkB=4,
        zorder=1,
    )
    ax.add_patch(arrow)
    if label:
        mx = (start[0] + end[0]) / 2 + label_offset[0]
        my = (start[1] + end[1]) / 2 + label_offset[1]
        ax.text(
            mx,
            my,
            label,
            ha="center",
            va="center",
            fontsize=7.6,
            color=color,
            bbox={"boxstyle": "round,pad=0.16", "fc": "white", "ec": "none", "alpha": 0.88},
            zorder=4,
        )


def draw_section(ax, title, x0, x1, y0=-1.15, y1=7.9):
    ax.axvspan(x0, x1, ymin=0.06, ymax=0.92, color="#F7F9FB", alpha=0.55, zorder=0)
    ax.text(
        (x0 + x1) / 2,
        y1,
        title,
        ha="center",
        va="bottom",
        fontsize=10.5,
        color=COLORS["muted"],
        fontweight="bold",
    )


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    fig, ax = plt.subplots(figsize=(18, 10), dpi=220)
    fig.patch.set_facecolor("white")
    ax.set_facecolor("white")
    ax.set_xlim(0, 19.5)
    ax.set_ylim(-1.3, 8.4)
    ax.axis("off")

    draw_section(ax, "Estados y fricciones", 0.25, 4.0)
    draw_section(ax, "Problema del hogar", 4.0, 7.3)
    draw_section(ax, "Distribucion", 7.3, 10.0)
    draw_section(ax, "Agregados", 10.0, 12.9)
    draw_section(ax, "Firmas, gobierno y cierres", 12.9, 17.75)

    ax.text(
        9.75,
        8.22,
        "Modelo OU con prima z: interaccion de variables y cierre de mercados",
        ha="center",
        va="center",
        fontsize=18,
        color=COLORS["ink"],
        fontweight="bold",
    )
    ax.text(
        9.75,
        7.78,
        "Lectura: las flechas solidas son efectos dentro de una iteracion; las flechas punteadas son ajustes de equilibrio general.",
        ha="center",
        va="center",
        fontsize=9.5,
        color=COLORS["muted"],
    )

    nodes = {}
    nodes["ou"] = draw_node(
        ax,
        "ou",
        "Proceso OU de productividad\nx = log z\nQz, piz, E[z]=1",
        (2.0, 6.45),
        face=COLORS["state"],
        weight="bold",
    )
    nodes["asset"] = draw_node(
        ax,
        "asset",
        "Activos del hogar\na en [amin, amax]\nrestriccion de deuda",
        (2.0, 4.95),
        face=COLORS["state"],
    )
    nodes["prem"] = draw_node(
        ax,
        "prem",
        "Prima z sobre deuda\nspread(z)=chi*low(z)^eta\ncosto: spread(z)*max(-a,0)",
        (2.0, 3.25),
        wh=(3.18, 1.16),
        face=COLORS["state"],
    )

    nodes["prices"] = draw_node(
        ax,
        "prices",
        "Precios y transferencias\nr, wF, wI, pI, T, PiI",
        (5.35, 6.2),
        wh=(3.02, 1.0),
        face=COLORS["closure"],
        weight="bold",
    )
    nodes["hjb"] = draw_node(
        ax,
        "hjb",
        "HJB del hogar\nelige cF, cI, ellF, ellI\nadot = ingreso - gasto\n       - prima de deuda",
        (5.35, 4.35),
        wh=(3.25, 1.28),
        face=COLORS["household"],
        fontsize=8.5,
        weight="bold",
    )
    nodes["policies"] = draw_node(
        ax,
        "policies",
        "Politicas individuales\nconsumo, horas y ahorro\npor estado (a,z)",
        (5.35, 2.55),
        wh=(3.0, 1.02),
        face=COLORS["household"],
    )

    nodes["kfe"] = draw_node(
        ax,
        "kfe",
        "KFE / Fokker-Planck\nA'(politicas,Qz) g = 0\n=> g(a,z)",
        (8.65, 4.35),
        wh=(2.95, 1.25),
        face=COLORS["distribution"],
        weight="bold",
    )

    nodes["aggregates"] = draw_node(
        ax,
        "aggregates",
        "Agregados desde g(a,z)\nKs, LF, LI, CF, CI\nmasa de deuda y primas pagadas",
        (11.85, 4.35),
        wh=(3.05, 1.35),
        face=COLORS["aggregate"],
        weight="bold",
    )

    nodes["formal"] = draw_node(
        ax,
        "formal",
        "Firma formal\nYF=AF K^alpha LF^(1-alpha)\ndemanda K y salario wF",
        (14.85, 6.35),
        wh=(3.25, 1.15),
        face=COLORS["market"],
    )
    nodes["informal"] = draw_node(
        ax,
        "informal",
        "Firma informal\nYI=AI KI^alphaI LI^betaI\nwI y PiI",
        (14.85, 4.55),
        wh=(3.25, 1.15),
        face=COLORS["market"],
    )
    nodes["gov"] = draw_node(
        ax,
        "gov",
        "Gobierno\nrecauda tau*wF*LF\nrebate T",
        (14.85, 2.78),
        wh=(3.0, 1.0),
        face=COLORS["market"],
    )
    nodes["asset_clear"] = draw_node(
        ax,
        "asset_clear",
        "Cierre capital/activos\nS(r) = KD(r)\najusta r",
        (18.05, 6.35),
        wh=(2.45, 1.04),
        face=COLORS["closure"],
        weight="bold",
    )
    nodes["goods_clear"] = draw_node(
        ax,
        "goods_clear",
        "Cierre bien informal\nCI = YI\najusta pI",
        (18.05, 4.55),
        wh=(2.45, 1.04),
        face=COLORS["closure"],
        weight="bold",
    )

    # Main within-iteration flow.
    draw_arrow(ax, nodes["ou"], nodes["hjb"], "right", "left", "z y Qz", rad=-0.06)
    draw_arrow(ax, nodes["asset"], nodes["hjb"], "right", "left", "a", rad=0.0)
    draw_arrow(ax, nodes["prem"], nodes["hjb"], "right", "left", "costo deuda", rad=0.08)
    draw_arrow(ax, nodes["prices"], nodes["hjb"], "bottom", "top", "precios dados")
    draw_arrow(ax, nodes["hjb"], nodes["policies"], "bottom", "top")
    draw_arrow(ax, nodes["policies"], nodes["kfe"], "right", "left", "A de transicion")
    draw_arrow(ax, nodes["ou"], nodes["kfe"], "right", "top", "shocks z", rad=-0.28, label_offset=(-0.15, 0.34))
    draw_arrow(ax, nodes["kfe"], nodes["aggregates"], "right", "left", "integrar sobre g")
    draw_arrow(ax, nodes["policies"], nodes["aggregates"], "right", "left", "politicas", rad=-0.12, label_offset=(-0.06, -0.35))

    # Markets.
    draw_arrow(ax, nodes["aggregates"], nodes["formal"], "right", "left", "Ks, LF", rad=0.08)
    draw_arrow(ax, nodes["aggregates"], nodes["informal"], "right", "left", "LI, CI", rad=0.0)
    draw_arrow(ax, nodes["aggregates"], nodes["gov"], "right", "left", "base fiscal", rad=-0.08)
    draw_arrow(ax, nodes["formal"], nodes["asset_clear"], "right", "left", "K_D, w_F")
    draw_arrow(ax, nodes["informal"], nodes["goods_clear"], "right", "left", "Y_I")
    draw_arrow(ax, nodes["gov"], nodes["prices"], "top", "right", "T", rad=0.36, color="#7A5A00", label_offset=(0.2, 0.12))
    draw_arrow(ax, nodes["informal"], nodes["prices"], "top", "right", "wI, PiI", rad=0.24, color="#7A5A00", label_offset=(0.45, 0.24))
    draw_arrow(ax, nodes["formal"], nodes["prices"], "top", "right", "wF", rad=0.18, color="#7A5A00", label_offset=(0.25, 0.42))

    # Equilibrium feedback.
    draw_arrow(
        ax,
        nodes["asset_clear"],
        nodes["prices"],
        "left",
        "top",
        "biseccion en r",
        rad=0.12,
        color="#2F5597",
        lw=1.5,
        ls="--",
        label_offset=(-0.45, 0.28),
    )
    draw_arrow(
        ax,
        nodes["goods_clear"],
        nodes["prices"],
        "left",
        "right",
        "biseccion en pI",
        rad=-0.18,
        color="#2F5597",
        lw=1.5,
        ls="--",
        label_offset=(-0.15, -0.34),
    )
    draw_arrow(
        ax,
        nodes["aggregates"],
        nodes["asset_clear"],
        "top",
        "bottom",
        "S(r)",
        rad=-0.08,
        color="#2F5597",
        lw=1.3,
        ls="--",
        label_offset=(0.0, 0.22),
    )
    draw_arrow(
        ax,
        nodes["aggregates"],
        nodes["goods_clear"],
        "right",
        "left",
        "CI",
        rad=-0.12,
        color="#2F5597",
        lw=1.3,
        ls="--",
        label_offset=(0.1, -0.34),
    )

    # Mechanism callout.
    callout = FancyBboxPatch(
        (0.8, -0.92),
        17.9,
        0.72,
        boxstyle="round,pad=0.04,rounding_size=0.08",
        linewidth=1.0,
        edgecolor="#AAB4BE",
        facecolor="#FBFCFD",
        zorder=2,
    )
    ax.add_patch(callout)
    ax.text(
        9.75,
        -0.46,
        "Mecanismo: z bajo y deuda elevan la prima efectiva, reducen ingreso disponible y alteran horas/ahorro.\n"
        "Las politicas cambian g(a,z), y los agregados obligan a reajustar r y pI hasta cerrar activos e informal.",
        ha="center",
        va="center",
        fontsize=9.2,
        color=COLORS["ink"],
    )

    fig.savefig(OUT_FILE, bbox_inches="tight", facecolor="white")
    print(OUT_FILE)


if __name__ == "__main__":
    main()
