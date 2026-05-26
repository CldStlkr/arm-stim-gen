#!/usr/bin/env python3
"""
Generate the README chart from measured data.

Left panel: Measured hazard density heatmap (strategy x hazard type).
  Runs N_TESTS for each strategy using the cpp generator, parses each .S
  with analyze.py, and aggregates average hazard counts per test.
  Color is column-normalized so each hazard's maximum rate = 1.0.

Right panel: ISS bug exposure rate bar chart (from coverage_report.txt data).
"""
import random
import subprocess
import sys
import tempfile
from collections import defaultdict
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

ROOT   = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets"
ASSETS.mkdir(exist_ok=True)

sys.path.insert(0, str(Path(__file__).resolve().parent))
from analyze import parse_asm, count_hazards, ALL_HAZARDS

STRATEGIES = [
    "random",
    "forwarding_stress",
    "load_use_stress",
    "store_to_load_forwarding",
    "branch_dense",
    "cache_line_split",
]

GENERATOR_BIN = ROOT / "generator" / "build" / "stim_gen"

N_TESTS = 200
COUNT   = 30

# ISS data from coverage_report.txt (1000-test batch runs)
ISS_STRATEGIES = ["load_use_stress", "store_to_load_forwarding"]
ISS_GENERATORS = ["cpp", "rust", "zig"]
ISS_EXPOSURE   = {
    "load_use_stress":          {"cpp": 92.0, "rust": 91.8, "zig": 91.7},
    "store_to_load_forwarding": {"cpp": 97.6, "rust": 97.7, "zig": 98.0},
}
GEN_COLORS = {"cpp": "#58a6ff", "rust": "#ff7b72", "zig": "#f0883e"}


def measure_hazard_matrix() -> np.ndarray:
    """
    Run N_TESTS per strategy, return float matrix[strategy_idx][hazard_idx]
    where each cell is the average hazard count per test.
    """
    matrix = np.zeros((len(STRATEGIES), len(ALL_HAZARDS)), dtype=float)

    with tempfile.TemporaryDirectory() as tmp_dir:
        asm = Path(tmp_dir) / "test.S"
        for si, strategy in enumerate(STRATEGIES):
            totals = defaultdict(int)
            valid  = 0
            for _ in range(N_TESTS):
                seed   = random.getrandbits(64)
                result = subprocess.run(
                    [str(GENERATOR_BIN), "--seed", str(seed),
                     "--count", str(COUNT), "--out", str(asm),
                     "--strategy", strategy],
                    capture_output=True,
                )
                if result.returncode != 0:
                    continue
                for k, v in count_hazards(parse_asm(asm)).items():
                    totals[k] += v
                valid += 1

            if valid > 0:
                for hi, h in enumerate(ALL_HAZARDS):
                    matrix[si][hi] = totals[h] / valid

    return matrix


def make_chart(matrix: np.ndarray) -> None:
    DARK_BG  = "#161b22"
    BORDER   = "#30363d"
    TICK_COL = "#8b949e"
    TEXT_COL = "#e6edf3"

    fig, (ax_heat, ax_bar) = plt.subplots(
        1, 2, figsize=(14, 5.5),
        gridspec_kw={"width_ratios": [1.6, 1]},
    )
    fig.patch.set_facecolor("#0d1117")

    for ax in (ax_heat, ax_bar):
        ax.set_facecolor(DARK_BG)
        ax.spines[:].set_color(BORDER)
        ax.tick_params(colors=TICK_COL)
        ax.xaxis.label.set_color(TICK_COL)
        ax.yaxis.label.set_color(TICK_COL)
        ax.title.set_color(TEXT_COL)

    # --- left: measured hazard density heatmap ---
    col_max         = matrix.max(axis=0)
    col_max[col_max == 0] = 1
    norm_matrix     = matrix / col_max

    im = ax_heat.imshow(norm_matrix, cmap=plt.cm.YlOrRd, vmin=0, vmax=1, aspect="auto")

    x_labels = ["RawChain", "Load\nUse", "Store\nToLoad", "Branch\nDense", "Cache\nLineSplit"]
    y_labels  = [s.replace("_", "_\n") for s in STRATEGIES]

    ax_heat.set_xticks(range(len(ALL_HAZARDS)))
    ax_heat.set_yticks(range(len(STRATEGIES)))
    ax_heat.set_xticklabels(x_labels,  fontsize=9,   color=TICK_COL)
    ax_heat.set_yticklabels(y_labels,  fontsize=8.5, color=TICK_COL)
    ax_heat.set_title(
        f"Measured Hazard Density  (avg count / test, {N_TESTS} tests each, column-normalized)",
        fontsize=9.5, color=TEXT_COL,
    )

    for si in range(len(STRATEGIES)):
        for hi in range(len(ALL_HAZARDS)):
            raw  = matrix[si][hi]
            norm = norm_matrix[si][hi]
            if raw < 0.05:
                continue
            fg = TEXT_COL if norm > 0.5 else "#0d1117"
            ax_heat.text(
                hi, si, f"{raw:.1f}",
                ha="center", va="center",
                fontsize=8.5, color=fg,
                fontweight="bold" if norm > 0.8 else "normal",
            )

    cb = fig.colorbar(im, ax=ax_heat, fraction=0.025, pad=0.03)
    cb.ax.tick_params(colors=TICK_COL, labelsize=8)
    cb.outline.set_edgecolor(BORDER)
    cb.set_label("normalized per hazard column", color=TICK_COL, fontsize=8)

    # --- right: ISS exposure rate bar chart ---
    X     = np.arange(len(ISS_STRATEGIES))
    BAR_W = 0.25

    for i, gen in enumerate(ISS_GENERATORS):
        vals   = [ISS_EXPOSURE[s][gen] for s in ISS_STRATEGIES]
        offset = (i - 1) * BAR_W
        bars   = ax_bar.bar(X + offset, vals, BAR_W, label=gen,
                            color=GEN_COLORS[gen], zorder=3, alpha=0.92)
        for bar, v in zip(bars, vals):
            ax_bar.text(
                bar.get_x() + bar.get_width() / 2, v + 0.4,
                f"{v:.1f}", ha="center", va="bottom",
                fontsize=7.5, color=TEXT_COL,
            )

    ax_bar.set_ylim(85, 101)
    ax_bar.set_xticks(X)
    ax_bar.set_xticklabels([s.replace("_", "_\n") for s in ISS_STRATEGIES], fontsize=9)
    ax_bar.set_ylabel("Bug exposure rate (%)", color=TICK_COL)
    ax_bar.set_title("ISS Differential: Bug Exposure\n(1 000 tests each)", fontsize=10)
    ax_bar.legend(framealpha=0, labelcolor=TEXT_COL, fontsize=9)
    ax_bar.grid(axis="y", color="#21262d", linewidth=0.8, zorder=0)

    fig.suptitle("arm-stim-gen  |  AArch64 Stimulus Generator",
                 fontsize=13, color=TEXT_COL, y=1.02)

    plt.tight_layout()
    out = ASSETS / "overview.png"
    plt.savefig(out, dpi=160, bbox_inches="tight", facecolor=fig.get_facecolor())
    print(f"Saved {out}")


def main() -> None:
    if not GENERATOR_BIN.exists():
        print(f"Error: cpp generator not found at {GENERATOR_BIN}")
        print("Build with: cmake --build generator/build")
        sys.exit(1)

    print(f"Measuring ({N_TESTS} tests x {len(STRATEGIES)} strategies, count={COUNT})...", flush=True)
    matrix = measure_hazard_matrix()

    print(f"\n{'Strategy':<28} " + "  ".join(f"{h:<14}" for h in ALL_HAZARDS))
    for si, strategy in enumerate(STRATEGIES):
        vals = "  ".join(f"{matrix[si][hi]:<14.2f}" for hi in range(len(ALL_HAZARDS)))
        print(f"{strategy:<28} {vals}")

    make_chart(matrix)


if __name__ == "__main__":
    main()
