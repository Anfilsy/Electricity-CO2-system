import os
from os.path import dirname, join, exists
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt


# ================================ Path setting ================================ #

wdir = dirname(__file__) if "__file__" in globals() else os.getcwd()

scenario_order = ["NDC", "ENDC", "GM2.0", "CN50"]
scenario_display = {
    "NDC": "NDC",
    "ENDC": "ENDC",
    "GM2.0": "GM2.0",
    "CN50": "CN50",
}

cost_files = {
    "NDC": join(wdir, "Cost_Breakdown_EC_NDC.xlsx"),
    "ENDC": join(wdir, "Cost_Breakdown_EC_ENDC.xlsx"),
    "GM2.0": join(wdir, "Cost_Breakdown_EC_GM2.0.xlsx"),
    "CN50": join(wdir, "Cost_Breakdown_EC_CN50.xlsx"),
}

metric_file = join(wdir, "LCOE_LCCR.xlsx")
out_png = join(wdir, "Cost_Breakdown_EC.png")

# Two bars in each scenario group.
left_bar_label = "PS"
right_bar_label = "CS"

# Aggregate all CO2 system components into this single segment on the TSC bar.
carbon_total_label = "CSC"
carbon_total_color = "#2E5075"


# ================================ Column definitions ================================ #

# Power_Cost_Breakdown_bnUSD raw columns -> plotting labels.
power_col_map = {
    "capx_fcs": "Fossil CapEx",
    "capx_nu": "Nuclear CapEx",
    "capx_bio": "Bio CapEx",
    "capx_hydo": "Hydro CapEx",
    "capx_fwd": "Offshore-wind CapEx",
    "capx_nwd": "Onshore-wind CapEx",
    "capx_pv": "PV CapEx",
    "capx_stg": "Storage CapEx",
    "capx_trans": "Trans. CapEx",
    "fcs_eg": "Fossil FCS",
    "fcs_nu": "Nuclear FCS",
    "om_fcs": "Fossil O&M",
    "om_nu": "Nuclear O&M",
    "om_bio": "Bio O&M",
    "om_hydo": "Hydro O&M",
    "om_fwd": "Offshore-wind O&M",
    "om_nwd": "Onshore-wind O&M",
    "om_pv": "PV O&M",
    "om_stg": "Storage O&M",
    "om_trans": "Trans. O&M",
    "imps": "Imports",
}

# Match the original plotting logic: merge wind/PV O&M into VRE O&M.
power_plot_cols = [
    "Fossil CapEx",
    "Nuclear CapEx",
    "Bio CapEx",
    "Hydro CapEx",
    "Offshore-wind CapEx",
    "Onshore-wind CapEx",
    "PV CapEx",
    "Storage CapEx",
    "Trans. CapEx",
    "Fossil FCS",
    "Nuclear FCS",
    "Fossil O&M",
    "Nuclear O&M",
    "Bio O&M",
    "Hydro O&M",
    "VRE O&M",
    "Storage O&M",
    "Trans. O&M",
    "Imports",
]

# Carbon_Cost_Breakdown_bnUSD raw columns -> plotting labels.
carbon_col_map = {
    "CCS Retrofit": "CCS Retrofit",
    "capx_dac": "DAC CapEx",
    "capx_comp": "Compression CapEx",
    "capx_storage": "CO$_2$ Storage CapEx",
    "capx_trans": "CO$_2$ Trans. CapEx",
    "fcs_dac": "DAC FCS",
    "om_dac": "DAC O&M",
    "om_comp": "Compression O&M",
    "om_storage": "CO$_2$ Storage O&M",
    "om_trans": "CO$_2$ Trans. O&M",
}

carbon_plot_cols = [
    "CCS Retrofit",
    "DAC CapEx",
    "Compression CapEx",
    "CO$_2$ Storage CapEx",
    "CO$_2$ Trans. CapEx",
    "DAC FCS",
    "DAC O&M",
    "Compression O&M",
    "CO$_2$ Storage O&M",
    "CO$_2$ Trans. O&M",
]


# ================================ Colors ================================ #

# Based on the original Cost_Breakdown_Plots.py palette, extended for Bio/Hydro.
colors1 = {
    "Fossil CapEx": "#000000",
    "Nuclear CapEx": "#d48265",
    "Bio CapEx": "#2E8B57",
    "Hydro CapEx": "#1ABC9C",
    "Offshore-wind CapEx": "#61a0a8",
    "Onshore-wind CapEx": "#6d8346",
    "PV CapEx": "#f47920",
    "Storage CapEx": "#6930c3",
    "Trans. CapEx": "#C71585",
    "Fossil FCS": "#546570",
    "Nuclear FCS": "#ca8622",
    "Fossil O&M": "#6e7074",
    "Nuclear O&M": "#bda29a",
    "Bio O&M": "#8ab17d",
    "Hydro O&M": "#ff8fa3",
    "VRE O&M": "#60b37ddf",
    "Storage O&M": "#fab27b",
    "Trans. O&M": "#726930",
    "Imports": "#a85463",
}

# CO2 system colors analogous to the original hydrogen-network colors.
colors2 = {
    "CCS Retrofit": "#3f3f3fff",
    "DAC CapEx": "#AF7AA1",
    "Compression CapEx": "#40baaeff",
    "CO$_2$ Storage CapEx": "#1f77b4",
    "CO$_2$ Trans. CapEx": "#ee964b",
    "DAC FCS": "#546570",
    "DAC O&M": "#6e7074",
    "Compression O&M": "#93C572",
    "CO$_2$ Storage O&M": "#915F6D",
    "CO$_2$ Trans. O&M": "#70c2e0",
}


# ================================ Data utilities ================================ #

def _read_one_row_cost_table(xlsx_path, sheet_name):
    """Read a one-row cost breakdown sheet and return a Series indexed by raw columns."""
    df = pd.read_excel(xlsx_path, sheet_name=sheet_name)

    if df.empty or df.shape[1] < 2:
        return pd.Series(dtype=float)

    scenario_col = df.columns[0]
    df = df.set_index(scenario_col)
    df.index = df.index.astype(str).str.strip()

    # The uploaded workbook values are already bn USD. Do not scale them.
    df = df.apply(pd.to_numeric, errors="coerce").fillna(0.0)

    if df.empty:
        return pd.Series(dtype=float)

    return df.iloc[0]


def _prepare_power_row(xlsx_path):
    raw = _read_one_row_cost_table(xlsx_path, "Power_Cost_Breakdown_bnUSD")
    renamed = raw.rename(index=power_col_map)

    row = pd.Series(0.0, index=power_plot_cols, dtype=float)

    for col in power_plot_cols:
        if col in renamed.index:
            row[col] += float(renamed.loc[col])

    # Merge VRE O&M as in the original plotting script.
    row["VRE O&M"] = (
        float(renamed.get("Offshore-wind O&M", 0.0))
        + float(renamed.get("Onshore-wind O&M", 0.0))
        + float(renamed.get("PV O&M", 0.0))
    )

    return row


def _prepare_carbon_row(xlsx_path):
    raw = _read_one_row_cost_table(xlsx_path, "Carbon_Cost_Breakdown_bnUSD")
    renamed = raw.rename(index=carbon_col_map)

    # If capx_comp/capx_capture or om_comp/om_capture both appear, consolidate them.
    renamed = renamed.groupby(level=0).sum()

    row = pd.Series(0.0, index=carbon_plot_cols, dtype=float)

    for col in carbon_plot_cols:
        if col in renamed.index:
            row[col] += float(renamed.loc[col])

    return row


def load_cost_tables():
    ps_rows = []
    cc_rows = []

    for scen in scenario_order:
        path = cost_files[scen]
        if not exists(path):
            raise FileNotFoundError(f"Missing input file: {path}")

        ps_rows.append(_prepare_power_row(path))
        cc_rows.append(_prepare_carbon_row(path))

    ps_plot = pd.DataFrame(ps_rows, index=scenario_order).fillna(0.0)
    cc_plot = pd.DataFrame(cc_rows, index=scenario_order).fillna(0.0)

    # Keep original column order, but drop all-zero columns to avoid useless legend items.
    ps_plot = ps_plot.loc[:, ps_plot.abs().sum(axis=0) > 0]
    cc_plot = cc_plot.loc[:, cc_plot.abs().sum(axis=0) > 0]

    return ps_plot, cc_plot


def load_metrics():
    if not exists(metric_file):
        raise FileNotFoundError(f"Missing metric file: {metric_file}")

    lcoe_raw = pd.read_excel(metric_file, sheet_name="LCOE", index_col=0)
    lccr_raw = pd.read_excel(metric_file, sheet_name="LCCR", index_col=0)

    # Remove the unit row whose index is NaN.
    lcoe_raw = lcoe_raw[lcoe_raw.index.notna()].copy()
    lccr_raw = lccr_raw[lccr_raw.index.notna()].copy()

    lcoe_raw.index = lcoe_raw.index.astype(str).str.strip()
    lccr_raw.index = lccr_raw.index.astype(str).str.strip()

    lcoe = pd.to_numeric(lcoe_raw["LCOE"], errors="coerce").reindex(scenario_order)
    lccr = pd.to_numeric(lccr_raw["LCCR"], errors="coerce").reindex(scenario_order)

    return lcoe.values, lccr.values


# ================================ Load data ================================ #

ps_plot, cc_plot = load_cost_tables()
LCOE, LCCR = load_metrics()

# These totals are printed as a basic check. ENDC carbon should be non-zero.
print("Power network totals, bn USD:")
print(ps_plot.sum(axis=1))
print("CO2 system totals, bn USD:")
print(cc_plot.sum(axis=1))
print("Power + CO2 system totals, bn USD:")
print(ps_plot.sum(axis=1) + cc_plot.sum(axis=1))
print("LCOE:", LCOE)
print("LCCR:", LCCR)


# ================================ Bar positions ================================ #

bar_width = 0.2
bar_gap = 0.03
group_gap = 0.3

ps_left = []
cc_left = []
group_centers = []

x = 0.0
for _ in scenario_order:
    ps_left.append(x)
    cc_left.append(x + bar_width + bar_gap)
    group_centers.append(x + bar_width)
    x += 2 * bar_width + group_gap

ps_left = np.array(ps_left)
cc_left = np.array(cc_left)

ps_center = ps_left + bar_width / 2
cc_center = cc_left + bar_width / 2


# ================================ Plot parameters ================================ #

plt.rcParams["font.family"] = "Arial"
plt.rcParams["font.sans-serif"] = ["Arial", "DejaVu Sans"]
plt.rcParams["lines.linewidth"] = 0.8
plt.rcParams["lines.markersize"] = 3
plt.rcParams["axes.linewidth"] = 1.2
plt.rcParams["axes.labelsize"] = 7
plt.rcParams["xtick.labelsize"] = 6
plt.rcParams["xtick.direction"] = "in"
plt.rcParams["xtick.major.size"] = 1
plt.rcParams["xtick.major.width"] = 0
plt.rcParams["ytick.labelsize"] = 6
plt.rcParams["ytick.direction"] = "in"
plt.rcParams["ytick.major.size"] = 1.8
plt.rcParams["ytick.major.width"] = 1.2
plt.rcParams["axes.titlesize"] = 6
plt.rcParams["axes.titlepad"] = 3
plt.rcParams["axes.unicode_minus"] = False

figw, figh = 8 / 2.52, 5 / 2.54
fig, ax1 = plt.subplots(figsize=(figw, figh))
ax2 = ax1.twinx()


# ================================ Bars ================================ #

# Left axis: total electricity-CO2 system cost.
# First stack the power-network cost components.
bottom_ps = np.zeros(len(ps_plot))
for col in ps_plot.columns:
    ax1.bar(
        ps_left,
        ps_plot[col].values,
        width=bar_width,
        bottom=bottom_ps,
        label=col,
        color=colors1.get(col, "#999999"),
        align="edge",
        zorder=3,
    )
    bottom_ps += ps_plot[col].values

# Aggregate all CO2 system components and add the total as one segment
# on top of each left TSC bar. The detailed CO2 system breakdown is still
# shown in the right CNC bar.
carbon_total = cc_plot.sum(axis=1).to_numpy(dtype=float)
ax1.bar(
    ps_left,
    carbon_total,
    width=bar_width,
    bottom=bottom_ps,
    label=carbon_total_label,
    color=carbon_total_color,
    align="edge",
    zorder=3,
)
bottom_ps += carbon_total

# Right axis: CO2 system cost only. This bar is kept unchanged.
bottom_cc = np.zeros(len(cc_plot))
for col in cc_plot.columns:
    ax2.bar(
        cc_left,
        cc_plot[col].values,
        width=bar_width,
        bottom=bottom_cc,
        label=col,
        color=colors2.get(col, "#999999"),
        align="edge",
        zorder=3,
    )
    bottom_cc += cc_plot[col].values


# ================================ Axes ================================ #

xticks = np.array([v for pair in zip(ps_center, cc_center) for v in pair])
xticklabels = [left_bar_label, right_bar_label] * len(scenario_order)

ax1.set_xticks(xticks)
ax1.set_xticklabels(xticklabels)

for xc, scen in zip(group_centers, scenario_order):
    ax1.text(
        xc,
        -0.08,
        scenario_display[scen],
        transform=ax1.get_xaxis_transform(),
        ha="center",
        va="top",
        fontsize=7,
    )

ax1.set_ylabel("TSC (2025 bn USD)")
ax2.set_ylabel("CSC (2025 bn USD)")

ps_max = float(np.nanmax(bottom_ps)) if len(bottom_ps) else 1.0
cc_max = float(np.nanmax(bottom_cc)) if len(bottom_cc) else 1.0

# Keep clean rounded upper limit for the power-network cost axis.
# CO2 system cost axis is fixed as requested: 0-240, interval 40.
ax1.set_ylim(0, np.ceil(ps_max * 1.08 / 500) * 500 if ps_max > 0 else 1)
ax2.set_ylim(0, 240)
ax2.set_yticks(np.arange(0, 240 + 1e-9, 40))
ax2.spines["right"].set_bounds(0, 240)
ax2.margins(y=0)

ax1.grid(axis="y", linestyle="--", alpha=0.4, linewidth=0.6, zorder=0)


# ================================ LCOE and LCCR axes ================================ #

# LCOE
col3 = "red"
ax3 = ax1.twinx()
ax3.spines.right.set_position(("axes", 1.16))
P3 = ax3.scatter(ps_center, LCOE, label="LCOE", color=col3, marker="o")
ax3.set_ylabel("LCOE (USD/MWh)", color=col3)
ax3.tick_params(axis="y", colors=col3)
ax3.spines.right.set_color(col3)

# Fixed LCOE axis: 16.0-20.0, interval 0.5.
ax3.set_ylim(16.5, 20.5)
ax3.set_yticks(np.arange(16.5, 20.5 + 1e-9, 0.5))
ax3.spines["right"].set_bounds(16.5, 20.5)
ax3.margins(y=0)

# LCCR
col4 = "blue"
ax4 = ax1.twinx()
ax4.spines.right.set_position(("axes", 1.32))
P4 = ax4.scatter(ps_center, LCCR, label="LCCR", color=col4, marker="s")
ax4.set_ylabel("LCCR (USD/tCO$_2$)", color=col4)
ax4.tick_params(axis="y", colors=col4)
ax4.spines.right.set_color(col4)

# Keep the visible axes closed at the specified upper and lower bounds.
for _ax in [ax1, ax2, ax3, ax4]:
    _ax.spines["top"].set_visible(True)
    _ax.spines["bottom"].set_visible(True)

# Fixed LCCR axis: -10.0-60.0. Interval is set to 10 for readability.
ax4.set_ylim(0, 120)
ax4.set_yticks(np.arange(0, 120 + 1e-9, 20))
ax4.spines["right"].set_bounds(0, 120)
ax4.margins(y=0)


# ================================ Legend ================================ #

handles1, labels1 = ax1.get_legend_handles_labels()
handles2, labels2 = ax2.get_legend_handles_labels()
handles3, labels3 = ax3.get_legend_handles_labels()
handles4, labels4 = ax4.get_legend_handles_labels()

ax1.legend(
    handles1 + handles2 + handles3 + handles4,
    labels1 + labels2 + labels3 + labels4,
    ncol=5,
    loc="upper center",
    bbox_to_anchor=(0.65, 1.39),
    frameon=False,
    fontsize=5,
    labelspacing=0.52,
)


# ================================ Save ================================ #

fig.subplots_adjust(
    top=1,
    bottom=0,
    left=0,
    right=1,
    hspace=0.0,
    wspace=0.0,
)

fig.savefig(
    fname=out_png,
    dpi=900,
    bbox_inches="tight",
    pad_inches=0.04,
)

print("Saved figure:", out_png)

plt.show()
