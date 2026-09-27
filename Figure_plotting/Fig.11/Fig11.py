import os
from os.path import dirname, join, exists
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
from matplotlib.patches import Patch, Rectangle

FIGSIZE = (8.4, 4.8)
DPI = 300
LAYOUT = dict(left=0.12, right=0.70, top=0.85, bottom=0.23)
OUTER_AXIS_POSITION = 1.2


def finish_figure(fig, ax, ax2, ax3, output_png):
    # Identical axes rectangles; keep the original automatic label placement.
    fig.subplots_adjust(**LAYOUT)
    # Original labelpad values keep titles close to their own tick labels.
    # Adjust OUTER_AXIS_POSITION to change the gap between the right axes.
    fig.canvas.draw()
    print(f"Main plot size (pixels): {ax.bbox.width:.1f} x {ax.bbox.height:.1f}")
    # A fixed canvas preserves equal image and main-plot widths.
    with plt.rc_context({"savefig.bbox": None}):
        fig.savefig(output_png, dpi=DPI, bbox_inches=None, facecolor="white")
    plt.close(fig)
    print(f"Saved to: {output_png}")

def plot_electricity():
    # =========================
    # 1. Paths and data
    # =========================
    wdir = dirname(__file__) if "__file__" in globals() else os.getcwd()
    input_file = join(wdir, "E_Cost.xlsx")
    if not exists(input_file):
        input_file = join(wdir, "E_Cost(1).xlsx")
    output_png = join(wdir, "E_Cost_change.png")

    raw = pd.read_excel(input_file, sheet_name="Sheet1")
    raw.columns = ["Scenario", "System cost", "Carbon emission", "LCOE", "LCCR"]
    raw = raw[raw["Scenario"].notna()].copy()

    # Remove the units row and convert values to numeric.
    raw = raw[raw["Scenario"].astype(str).str.strip() != "M USD"].copy()
    raw["Scenario"] = raw["Scenario"].astype(str).str.strip()
    for col in ["System cost", "Carbon emission", "LCOE", "LCCR"]:
        raw[col] = pd.to_numeric(raw[col], errors="coerce")

    raw = raw.set_index("Scenario")

    # Required left-to-right order.
    scenario_order = ["HVRE", "LVRE", "HRS", "LRS", "HED", "LED"]
    base = raw.loc["CN50"]
    plot_df = raw.loc[scenario_order].copy()

    # Changes relative to CN50.
    plot_df["d_system_cost_bn"] = (
        plot_df["System cost"] - base["System cost"]
    ) / 1000.0  # M USD -> bn USD
    plot_df["d_LCCR"] = plot_df["LCCR"] - base["LCCR"]
    plot_df["d_LCOE"] = plot_df["LCOE"] - base["LCOE"]

    # =========================
    # 2. Plot style
    # =========================
    plt.rcParams.update({
        "font.family": "Arial",
        "font.size": 10,
        "axes.labelsize": 11,
        "xtick.labelsize": 10,
        "ytick.labelsize": 10,
        "legend.fontsize": 10,
        "axes.linewidth": 1.2,
        "xtick.major.width": 1.1,
        "ytick.major.width": 1.1,
    })

    bar_color = "#2F78B7"
    lcoe_color = "red"   # red dots for LCOE
    lccr_color = "blue"  # blue squares for LCCR

    # Compress the horizontal spacing between scenarios
    x_spacing = 0.6
    x = np.arange(len(plot_df)) * x_spacing

    # Reduce the total figure width
    fig, ax = plt.subplots(figsize=FIGSIZE, dpi=DPI)

    fig.patch.set_facecolor("white")

    # =========================
    # 3. Left axis: total system costs
    # =========================
    ax.bar(
        x,
        plot_df["d_system_cost_bn"],
        width=0.3,
        color=bar_color,
        edgecolor=bar_color,
        zorder=2,
    )
    ax.axhline(0, color="gray", linewidth=0.9, linestyle="--", zorder=1)
    ax.set_ylabel("Changes in TSC (bn USD)")
    ax.set_xticks(x)
    ax.set_xticklabels(plot_df.index)
    ax.margins(x=0.025)
    ax.spines["right"].set_visible(False)
    ax.spines["top"].set_linewidth(1.75)
    ax.spines["left"].set_linewidth(1.75)
    ax.spines["bottom"].set_linewidth(1.75)
    ax.tick_params(axis="both", direction="in")
    ax.tick_params(axis="x",direction="in", pad=6)
    ax.grid(False)

    left_vals = plot_df["d_system_cost_bn"].to_numpy()
    left_min = np.floor((left_vals.min() - 150) / 200) * 200
    left_max = np.ceil((left_vals.max() + 150) / 200) * 200
    ax.set_ylim(left_min, left_max)

    # =========================
    # 4. Two separated right axes
    # =========================
    # Red: electricity costs (LCOE)
    ax2 = ax.twinx()
    ax2.spines["right"].set_position(("axes", 1.00))
    ax2.spines["right"].set_color(lcoe_color)
    ax2.spines["right"].set_linewidth(1.75)
    ax2.spines["top"].set_visible(False)
    ax2.spines["left"].set_visible(False)
    ax2.tick_params(axis="y", colors=lcoe_color, direction="in", width=1.75, pad=4)
    ax2.set_ylabel(
        "Changes in LCOE (USD/MWh)",
        color=lcoe_color,
        labelpad=4,
    )
    ax2.scatter(
        x,
        plot_df["d_LCOE"],
        color=lcoe_color,
        s=34,
        marker="o",
        zorder=5,
    )
    y2 = plot_df["d_LCOE"].to_numpy()
    pad2 = max(0.15, 0.15 * np.ptp(y2)) if np.ptp(y2) > 0 else 0.5
    ax2.set_ylim(-6, 6)
    ax2.set_yticks(np.arange(-6, 6.1, 2))

    # Blue: decarbonization costs (LCCR)
    ax3 = ax.twinx()
    ax3.spines["right"].set_position(("axes", OUTER_AXIS_POSITION))
    ax3.spines["right"].set_color(lccr_color)
    ax3.spines["right"].set_linewidth(1.75)
    ax3.spines["top"].set_visible(False)
    ax3.spines["left"].set_visible(False)
    ax3.tick_params(axis="y", colors=lccr_color, direction="in", width=1.75, pad=4)
    ax3.set_ylabel(
        "Changes in LCCR (USD/tCO$_2$)",
        color=lccr_color,
        labelpad=2,
    )
    ax3.scatter(
        x,
        plot_df["d_LCCR"],
        color=lccr_color,
        s=34,
        marker="s",
        zorder=5,
    )
    y3 = plot_df["d_LCCR"].to_numpy()
    pad3 = max(5, 0.12 * np.ptp(y3)) if np.ptp(y3) > 0 else 10
    ax3.set_ylim(-100, 140)
    ax3.set_yticks(np.arange(-100, 141, 40))

    # =========================
    # 5. Legend and layout
    # =========================
    handles = [
        Patch(facecolor=bar_color, edgecolor=bar_color, label="TSC"),
        Line2D(
            [0], [0], marker="o", linestyle="none",
            markerfacecolor=lcoe_color, markeredgecolor=lcoe_color,
            markersize=5, label="LCOE",
        ),
        Line2D(
            [0], [0], marker="s", linestyle="none",
            markerfacecolor=lccr_color, markeredgecolor=lccr_color,
            markersize=5, label="LCCR",
        ),
    ]

    ax.legend(
        handles=handles,
        ncol=3,
        loc="upper left",
        bbox_to_anchor=(0.30, 1.165),
        frameon=False,
        handletextpad=0.5,
        columnspacing=1.6,
        fontsize=10.5
    )


    # Sensitivity categories aligned with the existing scenario order.
    sensitivity_groups = [(0, 2, 'Technology\ncost', '#E4EDF6'), (2, 4, 'Renewable\nresource', '#F8EBDD'), (4, 6, 'Electricity\ndemand', '#E4EFDF')]
    # Use midpoint boundaries; keep the original plot limits and data unchanged.
    _xmin, _xmax = ax.get_xlim()
    _edges = np.r_[_xmin, (x[:-1] + x[1:]) / 2.0, _xmax]
    for start, end, label, color in sensitivity_groups:
        left = (_edges[start] - _xmin) / (_xmax - _xmin)
        width = (_edges[end] - _edges[start]) / (_xmax - _xmin)
        ax.add_patch(Rectangle(
            (left, -0.255), width, 0.135, transform=ax.transAxes,
            facecolor=color, edgecolor="white", linewidth=0.6,
            clip_on=False,
        ))
        ax.text(
            left + width / 2, -0.1875, label, transform=ax.transAxes,
            ha="center", va="center", fontsize=11, fontfamily="Arial", color="#263445", clip_on=False,
        )

    finish_figure(fig, ax, ax2, ax3, output_png)


def plot_carbon():
    # =========================
    # 1. Paths and data
    # =========================
    wdir = dirname(__file__) if "__file__" in globals() else os.getcwd()


    def resolve_input_file():
        """Prefer the standard project filename, while supporting the uploaded copy."""
        candidates = [
            join(wdir, "C_Cost.xlsx"),
            join(wdir, "C_Cost(3).xlsx"),
        ]
        for path in candidates:
            if exists(path):
                return path
        raise FileNotFoundError(
            "Cannot find C_Cost.xlsx or C_Cost(3).xlsx in the script directory."
        )


    input_file = resolve_input_file()
    output_png = join(wdir, "C_Cost_change.png")

    raw = pd.read_excel(input_file, sheet_name="Sheet1")

    # The workbook contains four columns in this order:
    # Scenario, system cost, provincial-network metric, prefectural-network metric.
    if raw.shape[1] != 4:
        raise ValueError(
            f"Sheet1 must contain exactly 4 columns, but {raw.shape[1]} were found."
        )

    raw.columns = ["Scenario", "System cost", "CNet_Prov", "CNet_Pref"]
    raw = raw[raw["Scenario"].notna()].copy()

    # Remove the units row and convert values to numeric.
    raw = raw[raw["Scenario"].astype(str).str.strip() != "M USD"].copy()
    raw["Scenario"] = raw["Scenario"].astype(str).str.strip()
    for col in ["System cost", "CNet_Prov", "CNet_Pref"]:
        raw[col] = pd.to_numeric(raw[col], errors="coerce")

    raw = raw.set_index("Scenario")

    # Six carbon-network sensitivity scenarios, left to right.
    scenario_order = ["HCS", "LCS", "HCT", "LCT", "HCC", "LCC"]

    required_rows = ["CN50"] + scenario_order
    missing_rows = [row for row in required_rows if row not in raw.index]
    if missing_rows:
        raise KeyError(f"The following required scenarios are missing from Sheet1: {missing_rows}")

    base = raw.loc["CN50"]
    plot_df = raw.loc[scenario_order].copy()

    # Changes relative to CN50.
    plot_df["d_system_cost_bn"] = (
        plot_df["System cost"] - base["System cost"]
    ) / 1000.0  # M USD -> bn USD
    plot_df["d_CNet_Prov"] = plot_df["CNet_Prov"] - base["CNet_Prov"]
    plot_df["d_CNet_Pref"] = plot_df["CNet_Pref"] - base["CNet_Pref"]

    print("Changes relative to CN50:")
    print(plot_df[["d_system_cost_bn", "d_CNet_Prov", "d_CNet_Pref"]].round(4))

    # =========================
    # 2. Plot style
    # =========================
    # All structural and visual settings follow plot_E_Cost_change.py.
    plt.rcParams.update({
        "font.family": "Arial",
        "font.size": 10,
        "axes.labelsize": 11,
        "xtick.labelsize": 10,
        "ytick.labelsize": 10,
        "legend.fontsize": 10,
        "axes.linewidth": 1.2,
        "xtick.major.width": 1.1,
        "ytick.major.width": 1.1,
    })

    bar_color = "#459B92"
    prov_color = "#D97722"  # orange provincial-network markers
    pref_color = "#7654A3"  # purple prefectural-network markers

    # Same horizontal spacing as the E-cost figure.
    x_spacing = 0.6
    x = np.arange(len(plot_df)) * x_spacing

    # Same canvas size as the E-cost figure.
    fig, ax = plt.subplots(figsize=FIGSIZE, dpi=DPI)
    fig.patch.set_facecolor("white")

    # =========================
    # 3. Left axis: carbon-network costs
    # =========================
    ax.bar(
        x,
        plot_df["d_system_cost_bn"],
        width=0.3,
        color=bar_color,
        edgecolor=bar_color,
        zorder=2,
    )
    ax.axhline(0, color="gray", linewidth=0.9, linestyle="--", zorder=1)
    ax.set_ylabel("Changes in CSC (bn USD)")
    ax.set_xticks(x)
    ax.set_xticklabels(plot_df.index)
    ax.margins(x=0.025)

    ax.spines["right"].set_visible(False)
    ax.spines["top"].set_linewidth(1.75)
    ax.spines["left"].set_linewidth(1.75)
    ax.spines["bottom"].set_linewidth(1.75)

    ax.tick_params(axis="both", direction="in")
    ax.tick_params(axis="x", direction="in", pad=6)
    ax.grid(False)

    # Fixed range suitable for the six C-cost sensitivity scenarios.
    ax.set_ylim(-15, 15)
    ax.set_yticks(np.arange(-15, 15.1, 5))

    # =========================
    # 4. Two separated right axes
    # =========================
    # Orange: provincial network capacity-distance
    ax2 = ax.twinx()
    ax2.spines["right"].set_position(("axes", 1.00))
    ax2.spines["right"].set_color(prov_color)
    ax2.spines["right"].set_linewidth(1.75)
    ax2.spines["top"].set_visible(False)
    ax2.spines["left"].set_visible(False)
    ax2.tick_params(
        axis="y",
        colors=prov_color,
        direction="in",
        width=1.75,
        pad=4,
    )
    ax2.set_ylabel(
        "Changes in provincial\nnetwork scale (GtCO$_2$ yr$^{-1}$ km)",
        color=prov_color,
        labelpad=4,
    )
    ax2.scatter(
        x,
        plot_df["d_CNet_Prov"],
        color=prov_color,
        s=34,
        marker="o",
        zorder=5,
    )

    # Updated range to include all six scenarios, including LCC.
    ax2.set_ylim(-40, 120)
    ax2.set_yticks(np.arange(-40, 120.1, 20))

    # Purple: prefectural network capacity-distance
    ax3 = ax.twinx()
    ax3.spines["right"].set_position(("axes", OUTER_AXIS_POSITION))
    ax3.spines["right"].set_color(pref_color)
    ax3.spines["right"].set_linewidth(1.75)
    ax3.spines["top"].set_visible(False)
    ax3.spines["left"].set_visible(False)
    ax3.tick_params(
        axis="y",
        colors=pref_color,
        direction="in",
        width=1.75,
        pad=4,
    )
    ax3.set_ylabel(
        "Changes in prefectural\nnetwork scale (GtCO$_2$ yr$^{-1}$ km)",
        color=pref_color,
        labelpad=2,
    )
    ax3.scatter(
        x,
        plot_df["d_CNet_Pref"],
        color=pref_color,
        s=34,
        marker="s",
        zorder=5,
    )
    ax3.set_ylim(-15, 15)
    ax3.set_yticks(np.arange(-15, 15.1, 5))

    # =========================
    # 5. Legend and layout
    # =========================
    handles = [
        Patch(
            facecolor=bar_color,
            edgecolor=bar_color,
            label="CSC",
        ),
        Line2D(
            [0], [0],
            marker="o",
            linestyle="none",
            markerfacecolor=prov_color,
            markeredgecolor=prov_color,
            markersize=5,
            label="Provincial Network",
        ),
        Line2D(
            [0], [0],
            marker="s",
            linestyle="none",
            markerfacecolor=pref_color,
            markeredgecolor=pref_color,
            markersize=5,
            label="Prefectural Network",
        ),
    ]

    ax.legend(
        handles=handles,
        ncol=3,
        loc="upper left",
        bbox_to_anchor=(0.145, 1.165),
        frameon=False,
        handletextpad=0.5,
        columnspacing=1.6,
        fontsize=10.5,
    )


    # Sensitivity categories aligned with the existing scenario order.
    sensitivity_groups = [(0, 2, 'CO$_2$ storage\npotential', '#E4EDF6'), (2, 4, 'CO$_2$ transport\ncost', '#F8EBDD'), (4, 6, 'CO$_2$ capture\ncost', '#E4EFDF')]
    # Use midpoint boundaries; keep the original plot limits and data unchanged.
    _xmin, _xmax = ax.get_xlim()
    _edges = np.r_[_xmin, (x[:-1] + x[1:]) / 2.0, _xmax]
    for start, end, label, color in sensitivity_groups:
        left = (_edges[start] - _xmin) / (_xmax - _xmin)
        width = (_edges[end] - _edges[start]) / (_xmax - _xmin)
        ax.add_patch(Rectangle(
            (left, -0.255), width, 0.135, transform=ax.transAxes,
            facecolor=color, edgecolor="white", linewidth=0.6,
            clip_on=False,
        ))
        ax.text(
            left + width / 2, -0.1875, label, transform=ax.transAxes,
            ha="center", va="center", fontsize=11, fontfamily="Arial", color="#263445", clip_on=False,
        )

    finish_figure(fig, ax, ax2, ax3, output_png)


if __name__ == "__main__":
    plot_electricity()
    plot_carbon()
