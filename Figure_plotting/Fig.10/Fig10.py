# -*- coding: utf-8 -*-
from pathlib import Path
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.patches import Patch
from matplotlib.lines import Line2D


# ================================ Paths ================================ #

WDIR = Path(__file__).resolve().parent if "__file__" in globals() else Path.cwd()
EC_FILE = WDIR / "EC_WO.xlsx"
OUT_PNG = WDIR / "Net_Tech_replotted_combined.png"


# ================================ Scenario settings ================================ #

POLICY_ORDER_DISPLAY = ["MOD", "GM2.0", "CN50"]
# Keep MOD as the internal data key because EC_WO.xlsx uses MOD,
# but display it as ENDC in the figure.
POLICY_DISPLAY_LABELS = {"MOD": "ENDC"}
CASE_ORDER = ["Optimal", "OE+WC", "WE+OC", "OE+OC"]
CASE_DISPLAY = {
    "Optimal": "WE-WC",
    "OE+WC": "OE-WC",
    "WE+OC": "WE-OC",
    "OE+OC": "OE-OC",
}


# ================================ Net settings ================================ #

net_power_cols = ["AC", "DC"]
net_carbon_cols = ["ProCN", "PreCN"]

net_power_colors = {
    "AC": "#5B7FA3",
    "DC": "#8FB9B1",
}

net_carbon_colors = {
    "ProCN": "#D39A6A",
    "PreCN": "#E0C36E",
}


# ================================ Tech settings ================================ #

tech_order = [
    "coal", "coics", "cocs",
    "gtcc", "gcics", "gccs",
    "hydo", "bio", "beccs", "nu",
    "fwd", "nwd", "pv",
    "phs", "lib4",
]

tech_colors = {
    "coal": "#000000",
    "coics": "#53566e",
    "cocs": "#C2C1C1",
    "gtcc": "#5a189a",
    "gcics": "#513ad1ff",
    "gccs": "#b197fc",
    "nu": "sienna",
    "hydo": "#1ABC9C",
    "bio": "seagreen",
    "beccs": "#00F5E0",
    "fwd": "#1f638e",
    "nwd": "#3C9FCA",
    "pv": "gold",
    "phs": "#C73FA3",
    "lib4": "#F08095",
}

tech_legend_names = {
    "coal": "Coal",
    "coics": "Coal-iCCS",
    "cocs": "Coal-CCS",
    "gtcc": "CCGT",
    "gcics": "CCGT-iCCS",
    "gccs": "CCGT-CCS",
    "nu": "Nuclear",
    "hydo": "Hydro",
    "bio": "Biomass",
    "beccs": "BECCS",
    "fwd": "Offshore-wind",
    "nwd": "Onshore-wind",
    "pv": "PV",
    "phs": "PHS",
    "lib4": "Battery",
}


# ================================ Data loading ================================ #

def load_net_tables():
    if not EC_FILE.exists():
        raise FileNotFoundError(f"Missing input file: {EC_FILE}")

    raw = pd.read_excel(EC_FILE, sheet_name="Net_km", header=None)
    df = raw.iloc[2:].copy()
    df.columns = ["Policy", "Case", "AC", "DC", "ProCN", "PreCN", "C_Flow", "P_Flow"]

    df["Policy"] = df["Policy"].ffill().astype(str).str.strip()
    df["Case"] = df["Case"].astype(str).str.strip()

    for col in net_power_cols + net_carbon_cols:
        df[col] = pd.to_numeric(df[col], errors="coerce").fillna(0.0)

    # Net_km stores AC/DC directly in TWkm, so no unit scaling is applied here.
    # Carbon-network values are kept in the same raw sheet units.

    ordered_index = pd.MultiIndex.from_product(
        [POLICY_ORDER_DISPLAY, CASE_ORDER], names=["Policy", "Case"]
    )

    df = df.set_index(["Policy", "Case"])
    missing = [idx for idx in ordered_index if idx not in df.index]
    if missing:
        raise ValueError(f"Missing scenarios in Net_km sheet: {missing}")

    power_df = df.loc[ordered_index, net_power_cols].copy()
    carbon_df = df.loc[ordered_index, net_carbon_cols].copy()

    power_df = power_df.loc[:, power_df.abs().sum(axis=0) > 1e-9]
    carbon_df = carbon_df.loc[:, carbon_df.abs().sum(axis=0) > 1e-9]
    return power_df, carbon_df


def load_tech_table():
    if not EC_FILE.exists():
        raise FileNotFoundError(f"Missing input file: {EC_FILE}")

    raw = pd.read_excel(EC_FILE, sheet_name="Tech", header=None)
    df = raw.iloc[1:].copy()
    df.columns = ["Policy", "Case"] + list(raw.iloc[0, 2:].astype(str).str.strip())

    df["Policy"] = df["Policy"].ffill().astype(str).str.strip()
    df["Case"] = df["Case"].astype(str).str.strip()

    for tech in tech_order:
        if tech not in df.columns:
            df[tech] = 0.0
        df[tech] = pd.to_numeric(df[tech], errors="coerce").fillna(0.0)

    ordered_index = pd.MultiIndex.from_product(
        [POLICY_ORDER_DISPLAY, CASE_ORDER], names=["Policy", "Case"]
    )

    df = df.set_index(["Policy", "Case"])
    missing = [idx for idx in ordered_index if idx not in df.index]
    if missing:
        raise ValueError(f"Missing scenarios in Tech sheet: {missing}")

    tech_df = df.loc[ordered_index, tech_order].copy()
    tech_df = tech_df.loc[:, tech_df.abs().sum(axis=0) > 1e-9]
    return tech_df


# ================================ Position helpers ================================ #

def pair_positions():
    bar_width = 0.245
    within_pair_gap = 0.035
    pair_gap = 0.18
    policy_gap = 0.28

    left_x, right_x, pair_centers = [], [], []
    policy_spans = {}
    x = 0.0

    for policy in POLICY_ORDER_DISPLAY:
        first_center = None
        last_center = None

        for _case in CASE_ORDER:
            lx = x
            rx = x + bar_width + within_pair_gap
            center = ((lx + bar_width / 2.0) + (rx + bar_width / 2.0)) / 2.0

            left_x.append(lx)
            right_x.append(rx)
            pair_centers.append(center)

            if first_center is None:
                first_center = center
            last_center = center

            x += 2 * bar_width + within_pair_gap + pair_gap

        policy_spans[policy] = (first_center, last_center)
        x += policy_gap

    return np.array(left_x), np.array(right_x), np.array(pair_centers), policy_spans, bar_width


def single_positions():
    bar_width = 0.35
    case_gap = 0.32
    policy_gap = 0.55

    bar_x, case_centers = [], []
    policy_spans = {}
    x = 0.0

    for policy in POLICY_ORDER_DISPLAY:
        first_center = None
        last_center = None

        for _case in CASE_ORDER:
            bx = x
            center = bx + bar_width / 2.0

            bar_x.append(bx)
            case_centers.append(center)

            if first_center is None:
                first_center = center
            last_center = center

            x += bar_width + case_gap

        policy_spans[policy] = (first_center, last_center)
        x += policy_gap

    return np.array(bar_x), np.array(case_centers), policy_spans, bar_width


# ================================ Axis helpers ================================ #

def nice_capacity_ylim(max_val, axis_type):
    """Return a rounded upper bound and about five major ticks."""
    if max_val <= 0:
        return 1.0, np.array([0.0, 1.0])

    target_intervals = 5
    raw_step = max_val * 1.08 / target_intervals
    magnitude = 10 ** np.floor(np.log10(raw_step))
    normalized = raw_step / magnitude

    if normalized <= 1:
        nice_normalized = 1
    elif normalized <= 2:
        nice_normalized = 2
    elif normalized <= 2.5:
        nice_normalized = 2.5
    elif normalized <= 5:
        nice_normalized = 5
    else:
        nice_normalized = 10

    step = nice_normalized * magnitude
    upper = np.ceil(max_val * 1.08 / step) * step
    ticks = np.arange(0, upper + step * 0.5, step)
    return upper, ticks


def nice_tech_ylim(max_val):
    if max_val <= 0:
        return 1.0, np.array([0.0, 1.0])

    if max_val <= 8000:
        step = 1000
    elif max_val <= 12000:
        step = 2000
    else:
        step = 5000

    upper = np.ceil(max_val * 1.08 / step) * step
    ticks = np.arange(0, upper + 1e-9, step)
    return upper, ticks


def apply_axis_style(ax):
    ax.grid(axis="y", linestyle="--", linewidth=0.6, alpha=0.32, zorder=0)
    ax.set_axisbelow(True)

    for spine in ax.spines.values():
        spine.set_visible(True)
        spine.set_linewidth(2)
        spine.set_color("black")

    ax.tick_params(axis="y", direction="in", length=3, width=1.5)
    ax.tick_params(axis="x", which="both", bottom=False, top=False, length=0)

# ================================ Lower label helpers ================================ #

def add_pair_case_policy_labels(
    ax,
    pair_centers,
    policy_spans,
    y_case=-0.105,
    y_policy=-0.332,
):
    cases_repeated = CASE_ORDER * len(POLICY_ORDER_DISPLAY)

    for xc, case in zip(pair_centers, cases_repeated):
        ax.text(
            xc, y_case, CASE_DISPLAY.get(case, case),
            transform=ax.get_xaxis_transform(),
            ha="center", va="top",
            fontsize=9.5,
            rotation=35,
        )

    # Show only the policy labels; the former bracket lines are intentionally removed.
    for policy, (x0, x1) in policy_spans.items():
        ax.text(
            (x0 + x1) / 2.0, y_policy, POLICY_DISPLAY_LABELS.get(policy, policy),
            transform=ax.get_xaxis_transform(),
            ha="center", va="top",
            fontsize=12,
            fontweight="semibold",
        )

    policy_bounds = list(policy_spans.values())
    for i in range(len(policy_bounds) - 1):
        sep = (policy_bounds[i][1] + policy_bounds[i + 1][0]) / 2.0
        ax.axvline(sep, color="#BFBFBF", lw=0.6, ymin=0, ymax=0.985, zorder=1)


def add_single_case_policy_labels(ax, case_centers, policy_spans):
    cases_repeated = CASE_ORDER * len(POLICY_ORDER_DISPLAY)

    for xc, case in zip(case_centers, cases_repeated):
        ax.text(
            xc, -0.060, CASE_DISPLAY.get(case, case),
            transform=ax.get_xaxis_transform(),
            ha="center", va="top",
            fontsize=9.5,
            rotation=35,
        )

    # Show only the policy labels; the former bracket lines are intentionally removed.
    for policy, (x0, x1) in policy_spans.items():
        ax.text(
            (x0 + x1) / 2.0, -0.285, POLICY_DISPLAY_LABELS.get(policy, policy),
            transform=ax.get_xaxis_transform(),
            ha="center", va="top",
            fontsize=12,
            fontweight="semibold",
        )

    policy_bounds = list(policy_spans.values())
    for i in range(len(policy_bounds) - 1):
        sep = (policy_bounds[i][1] + policy_bounds[i + 1][0]) / 2.0
        ax.axvline(sep, color="#BFBFBF", lw=0.6, ymin=0, ymax=0.985, zorder=1)


# ================================ Panel plotting ================================ #

def draw_net_panel(fig, ax1, power_df, carbon_df):
    ordered_index = pd.MultiIndex.from_product(
        [POLICY_ORDER_DISPLAY, CASE_ORDER], names=["Policy", "Case"]
    )
    power_df = power_df.reindex(ordered_index).fillna(0.0)
    carbon_df = carbon_df.reindex(ordered_index).fillna(0.0)

    ax2 = ax1.twinx()

    left_x, right_x, pair_centers, policy_spans, bar_width = pair_positions()
    x_all = np.ravel(np.column_stack([left_x, right_x]))
    labels_all = [label for _ in range(len(left_x)) for label in ["ETN", "CTN"]]

    bottom_power = np.zeros(len(power_df))
    power_handles = []

    for col in power_df.columns:
        vals = power_df[col].values.astype(float)
        if np.allclose(vals, 0):
            continue

        ax1.bar(
            left_x, vals, width=bar_width, bottom=bottom_power,
            color=net_power_colors.get(col, "#999999"),
            edgecolor="none", linewidth=0, align="edge", zorder=3,
        )
        bottom_power += vals

        power_handles.append(
            Patch(facecolor=net_power_colors.get(col, "#999999"), edgecolor="none", label=col)
        )

    bottom_carbon = np.zeros(len(carbon_df))
    carbon_handles = []

    for col in carbon_df.columns:
        vals = carbon_df[col].values.astype(float)
        if np.allclose(vals, 0):
            continue

        ax2.bar(
            right_x, vals, width=bar_width, bottom=bottom_carbon,
            color=net_carbon_colors.get(col, "#999999"),
            edgecolor="none", linewidth=0, align="edge", zorder=3,
        )
        bottom_carbon += vals

        carbon_handles.append(
            Patch(facecolor=net_carbon_colors.get(col, "#999999"), edgecolor="none", label=col)
        )

    left_upper, left_ticks = nice_capacity_ylim(float(np.nanmax(bottom_power)), "power")
    right_upper, right_ticks = nice_capacity_ylim(float(np.nanmax(bottom_carbon)), "carbon")

    ax1.set_ylim(0, left_upper)
    ax1.set_yticks(left_ticks)
    ax2.set_ylim(0, right_upper)
    ax2.set_yticks(right_ticks)

    ax1.set_ylabel("Electricity network scale (TW km)", labelpad=4, fontsize=10)
    ax2.set_ylabel("CO$_2$ network scale (GtCO$_2$ yr$^{-1}$ km)", labelpad=7, fontsize=10)

    ax1.set_xticks(x_all + bar_width / 2.0)
    ax1.set_xticklabels(labels_all, rotation=0, va="top", fontsize=8)
    ax1.set_xlim(left_x.min() - 0.28, right_x.max() + bar_width + 0.28)

    apply_axis_style(ax1)

    for ax in [ax1, ax2]:
        ax.spines["top"].set_visible(True)
        ax.tick_params(axis="y", direction="in", length=3, width=1.5)

    # PTN、CTN 文字由 ax1 显示，但不显示 x 轴刻度线
    ax1.tick_params(
    axis="x",
    which="both",
    bottom=False,
    top=False,
    length=0,
    labelbottom=True
    )

# ax2 是重复坐标轴，不显示任何 x 轴元素
    ax2.tick_params(
    axis="x",
    which="both",
    bottom=False,
    top=False,
    length=0,
    labelbottom=False
    )

    ax1.spines["right"].set_visible(False)
    ax2.spines["left"].set_visible(False)
    ax2.spines["bottom"].set_visible(False)

    add_pair_case_policy_labels(ax1, pair_centers, policy_spans)

    handles = power_handles + carbon_handles

    fig.legend(
        handles, [h.get_label() for h in handles],
        ncol=4,
        loc="upper center",
        bbox_to_anchor=(0.48, 0.844),
        frameon=False,
        columnspacing=2.3,
        labelspacing=1.1,
        handletextpad=0.8,
        handlelength=2.3,
        handleheight=1.0,
        borderaxespad=0.2,
        fontsize=9.9,
    )


def draw_tech_panel(fig, ax, tech_df):
    ordered_index = pd.MultiIndex.from_product(
        [POLICY_ORDER_DISPLAY, CASE_ORDER], names=["Policy", "Case"]
    )
    tech_df = tech_df.reindex(ordered_index).fillna(0.0)

    bar_x, case_centers, policy_spans, bar_width = single_positions()

    bottom = np.zeros(len(tech_df))
    handles = []

    for tech in tech_df.columns:
        vals = tech_df[tech].values.astype(float)
        if np.allclose(vals, 0):
            continue

        ax.bar(
            bar_x, vals, width=bar_width, bottom=bottom,
            color=tech_colors.get(tech, "#999999"),
            edgecolor="none", linewidth=0, align="edge", zorder=3,
        )
        bottom += vals

        handles.append(
            Patch(
                facecolor=tech_colors.get(tech, "#999999"),
                edgecolor="none",
                label=tech_legend_names.get(tech, tech),
            )
        )

    y_upper, y_ticks = nice_tech_ylim(float(np.nanmax(bottom)))

    ax.set_ylim(0, y_upper)
    ax.set_yticks(y_ticks)
    ax.set_ylabel("Installed capacity (GW)", labelpad=4, fontsize=10)

    ax.set_xticks(case_centers)
    ax.set_xticklabels([""] * len(case_centers))
    ax.tick_params(axis="x", length=0)
    ax.set_xlim(bar_x.min() - 0.35, bar_x.max() + bar_width + 0.35)

    apply_axis_style(ax)
    add_single_case_policy_labels(ax, case_centers, policy_spans)

    fig.legend(
        handles, [h.get_label() for h in handles],
        ncol=6,
        loc="upper center",
        bbox_to_anchor=(0.48, 0.452),
        frameon=False,
        columnspacing=2.0,
        labelspacing=1.0,
        handletextpad=0.65,
        handlelength=2.3,
        handleheight=1.0,
        borderaxespad=0.2,
        fontsize=9.9,
    )


# ================================ Main figure ================================ #

def make_combined_figure():
    net_power, net_carbon = load_net_tables()
    tech_df = load_tech_table()

    plt.rcParams.update({
        "font.family": "DejaVu Sans",
        "font.sans-serif": ["DejaVu Sans"],
        "axes.linewidth": 2,
        "axes.labelsize": 9.5,
        "xtick.labelsize": 8,
        "ytick.labelsize": 9,
        "legend.fontsize": 8,
        "ytick.direction": "in",
        "xtick.direction": "in",
        "xtick.bottom": False,
        "xtick.top": False,
        "xtick.major.width": 0,
        "ytick.major.width": 2,
        "xtick.major.size": 0,
        "ytick.major.size": 0.3,
        "axes.unicode_minus": False,
    })

    # Manual layout: both axes share exactly the same plotting-area width and height.
    fig = plt.figure(figsize=(12.2, 9.4), dpi=600)

    left = 0.075
    width = 0.805
    height = 0.235

    # The second coordinate controls the vertical position of each subplot.
    # Larger value = subplot moves upward.
    ax_net = fig.add_axes([left, 0.568, width, height])
    ax_tech = fig.add_axes([left, 0.148, width, height])

    draw_net_panel(fig, ax_net, net_power, net_carbon)
    draw_tech_panel(fig, ax_tech, tech_df)


    # Crop outer whitespace uniformly on all four sides.
    fig.savefig(
        OUT_PNG,
        dpi=600,
        facecolor="white",
        bbox_inches="tight",
        pad_inches=0.22,
    )
    plt.close(fig)


if __name__ == "__main__":
    make_combined_figure()
    print(f"Saved PNG: {OUT_PNG}")
