from __future__ import annotations

import argparse
import csv
import math
from pathlib import Path

import matplotlib.pyplot as plt


MOMENTS = [
    "r_star",
    "K_star",
    "p_I",
    "T4_ratio",
    "T5_nom",
    "T_kappa_z_model",
    "T6_model",
    "mass_debt",
    "T1_wage_net",
    "T1_wage_gross",
]


def parse_metadata(path: Path) -> dict[str, str]:
    out: dict[str, str] = {}
    section = ""
    for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw.strip()
        if not line:
            continue
        if line.startswith("[") and line.endswith("]"):
            section = line.strip("[]")
            continue
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip()
        out[key] = value
        if section:
            out[f"{section}.{key}"] = value
    return out


def to_float(value: str | None) -> float:
    if value is None or value == "":
        return math.nan
    try:
        return float(value)
    except ValueError:
        return math.nan


def collect_runs(root: Path, prefix: str) -> list[dict[str, object]]:
    runs: list[dict[str, object]] = []
    for meta in sorted(root.glob(f"{prefix}*/run_metadata.txt")):
        rec = parse_metadata(meta)
        tag = rec.get("run_tag") or meta.parent.name
        row: dict[str, object] = {
            "run_tag": tag,
            "path": str(meta.parent),
            "fast_debug": rec.get("fast_debug", rec.get("core.FAST_DEBUG_RUN", "")),
            "elapsed_sec": to_float(rec.get("total_elapsed")),
            "I": to_float(rec.get("core.I", rec.get("I"))),
            "Nz": to_float(rec.get("core.Nz_ar", rec.get("Nz_ar"))),
        }
        for moment in MOMENTS:
            row[moment] = to_float(rec.get(f"moments.{moment}", rec.get(moment)))
        runs.append(row)
    return runs


def add_errors(rows: list[dict[str, object]], benchmark_tag: str) -> None:
    bench = next((r for r in rows if r["run_tag"] == benchmark_tag), None)
    if bench is None:
        for row in rows:
            row["benchmark"] = benchmark_tag
            row["mean_abs_pct_error"] = math.nan
        return

    for row in rows:
        errs = []
        for moment in MOMENTS:
            x = float(row[moment])
            b = float(bench[moment])
            if not math.isfinite(x) or not math.isfinite(b):
                row[f"absdiff_{moment}"] = math.nan
                row[f"pctdiff_{moment}"] = math.nan
                continue
            absdiff = abs(x - b)
            denom = max(abs(b), 1e-8)
            pctdiff = 100.0 * absdiff / denom
            row[f"absdiff_{moment}"] = absdiff
            row[f"pctdiff_{moment}"] = pctdiff
            errs.append(pctdiff)
        row["benchmark"] = benchmark_tag
        row["mean_abs_pct_error"] = sum(errs) / len(errs) if errs else math.nan


def write_csv(rows: list[dict[str, object]], path: Path) -> None:
    fields = [
        "run_tag",
        "benchmark",
        "fast_debug",
        "elapsed_sec",
        "I",
        "Nz",
        "mean_abs_pct_error",
        *MOMENTS,
        *[f"pctdiff_{m}" for m in MOMENTS],
        "path",
    ]
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fields, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def plot_tradeoff(rows: list[dict[str, object]], path: Path) -> None:
    usable = [
        r
        for r in rows
        if math.isfinite(float(r["elapsed_sec"])) and math.isfinite(float(r["mean_abs_pct_error"]))
    ]
    if not usable:
        return
    plt.rcParams.update({"figure.facecolor": "white", "axes.facecolor": "white", "font.size": 10})
    fig, ax = plt.subplots(figsize=(8.5, 5.2))
    for row in usable:
        x = float(row["elapsed_sec"]) / 60.0
        y = float(row["mean_abs_pct_error"])
        fast = str(row.get("fast_debug", "")).lower()
        color = "#1f77b4" if fast in {"true", "1"} else "#d62728"
        marker = "o" if fast in {"true", "1"} else "s"
        ax.scatter(x, y, color=color, marker=marker, s=55)
        ax.annotate(str(row["run_tag"]).replace("tradeoff_", ""), (x, y), xytext=(4, 4), textcoords="offset points", fontsize=8)
    ax.set_xlabel("Tiempo de corrida, minutos")
    ax.set_ylabel("Error medio porcentual vs benchmark")
    ax.set_title("Tradeoff velocidad vs precision numerica")
    ax.grid(True, alpha=0.25)
    fig.tight_layout()
    fig.savefig(path, dpi=220)
    plt.close(fig)


def main() -> None:
    parser = argparse.ArgumentParser(description="Summarize OU debt-premium speed/accuracy tradeoff runs.")
    parser.add_argument("--root", required=True, help="Output root containing tradeoff_* run folders.")
    parser.add_argument("--prefix", default="tradeoff_", help="Run folder prefix.")
    parser.add_argument("--benchmark", required=True, help="Run tag used as benchmark.")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    rows = collect_runs(root, args.prefix)
    if not rows:
        raise SystemExit(f"No run_metadata.txt files found under {root} with prefix {args.prefix}")
    add_errors(rows, args.benchmark)

    csv_path = root / f"tradeoff_summary_vs_{args.benchmark}.csv"
    png_path = root / f"tradeoff_speed_accuracy_vs_{args.benchmark}.png"
    write_csv(rows, csv_path)
    plot_tradeoff(rows, png_path)

    print(f"Wrote {csv_path}")
    if png_path.exists():
        print(f"Wrote {png_path}")
    print("\nTop rows:")
    for row in sorted(rows, key=lambda r: (float(r.get("mean_abs_pct_error", math.inf)), float(r.get("elapsed_sec", math.inf))))[:8]:
        print(
            f"{row['run_tag']}: elapsed={float(row['elapsed_sec'])/60:.2f} min, "
            f"Nz={row['Nz']}, I={row['I']}, fast={row['fast_debug']}, "
            f"err={row['mean_abs_pct_error']:.4g}%"
        )


if __name__ == "__main__":
    main()
