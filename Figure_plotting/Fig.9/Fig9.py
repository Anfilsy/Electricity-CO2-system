# -*- coding: utf-8 -*-
import glob
import zipfile
from pathlib import Path

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.patches import Patch


# ================================ Paths ================================ #

WDIR = Path(__file__).resolve().parent if "__file__" in globals() else Path.cwd()
ZIP_PATH = WDIR / "Cost_Breakdown.zip"
EXTRACT_DIR = WDIR / "Cost_Breakdown_extracted"
OUT_PNG = WDIR / "Cost_Breakdown.png"


# ================================ Scenario settings ================================ #

POLICY_ORDER_DISPLAY = ["ENDC", "GM2.0", "CN50"]
CASE_ORDER = ["Optimal", "OE+WC", "WE+OC", "OE+OC"]
CASE_DISPLAY = {
    "Optimal": "WE-WC",
    "OE+WC": "OE-WC",
    "WE+OC": "WE-OC",
    "OE+OC": "OE-OC",
}

# In the zip file, ENDC corresponds to MOD for display.
RAW_POLICY_TO_DISPLAY = {
    "CN50": "CN50",
    "GM2.0": "GM2.0",
    "MOD": "ENDC",
    }

LEFT_BAR_LABEL = "PS"
RIGHT_BAR_LABEL = "CS"

carbon_total_label = "CSC"
carbon_total_color = "#2E5075"


# ================================ Column definitions ================================ #

power_col_map = {
    "capx_fcs": "Fossil CapEx",
    "capx_nu": "Nuclear CapEx",
    "capx_bio": "Bio CapEx",
    "capx_hydo": "Hydro CapEx",
    "capx_fwd": "Offshore-wind CapEx",
    "capx_nwd": "Onshore-wind CapEx",
    "capx_pv": "PV CapEx",
    "capx_stg": "Storage CapEx",
    "capx_trans": "Power trans. CapEx",
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
    "om_trans": "Power trans. O&M",
    "imps": "Imports",
}

power_plot_cols = [
    "Fossil CapEx",
    "Nuclear CapEx",
    "Bio CapEx",
    "Hydro CapEx",
    "Offshore-wind CapEx",
    "Onshore-wind CapEx",
    "PV CapEx",
    "Storage CapEx",
    "Power trans. CapEx",
    "Fossil FCS",
    "Nuclear FCS",
    "Fossil O&M",
    "Nuclear O&M",
    "Bio O&M",
    "Hydro O&M",
    "VRE O&M",
    "Storage O&M",
    "Power trans. O&M",
    "Imports",
]

carbon_col_map = {
    "CCS Retrofit": "CCS Retrofit",
    "capx_dac": "DAC CapEx",
    "capx_comp": "Compression CapEx",
    "capx_storage": "CO$_2$ storage CapEx",
    "capx_trans": "CO$_2$ trans. CapEx",
    "fcs_dac": "DAC FCS",
    "om_dac": "DAC O&M",
    "om_comp": "Compression O&M",
    "om_storage": "CO$_2$ storage O&M",
    "om_trans": "CO$_2$ trans. O&M",
}

carbon_plot_cols = [
    "CCS Retrofit",
    "DAC CapEx",
    "Compression CapEx",
    "CO$_2$ storage CapEx",
    "CO$_2$ trans. CapEx",
    "DAC FCS",
    "DAC O&M",
    "Compression O&M",
    "CO$_2$ storage O&M",
    "CO$_2$ trans. O&M",
]


# ================================ Colors ================================ #

power_colors = {
    "Fossil CapEx": "#000000",
    "Nuclear CapEx": "#D48265",
    "Bio CapEx": "#2E8B57",
    "Hydro CapEx": "#1ABC9C",
    "Offshore-wind CapEx": "#61A0A8",
    "Onshore-wind CapEx": "#6D8346",
    "PV CapEx": "#F47920",
    "Storage CapEx": "#6930C3",
    "Power trans. CapEx": "#C71585",
    "Fossil FCS": "#546570",
    "Nuclear FCS": "#CA8622",
    "Fossil O&M": "#6E7074",
    "Nuclear O&M": "#BDA29A",
    "Bio O&M": "#8AB17D",
    "Hydro O&M": "#FF8FA3",
    "VRE O&M": "#60B37D",
    "Storage O&M": "#FAB27B",
    "Power trans. O&M": "#726930",
    "Imports": "#A85463",
}

carbon_colors = {
    "CCS Retrofit": "#3f3f3fff",
    "DAC CapEx": "#AF7AA1",
    "Compression CapEx": "#40BAAE",
    "CO$_2$ storage CapEx": "#1F77B4",
    "CO$_2$ trans. CapEx": "#EE964B",
    "DAC FCS": "#4F5D75",
    "DAC O&M": "#8D99AE",
    "Compression O&M": "#93C572",
    "CO$_2$ storage O&M": "#915F6D",
    "CO$_2$ trans. O&M": "#70C2E0",
}


# ================================ Data utilities ================================ #

def extract_zip_if_needed() -> Path:
    if not ZIP_PATH.exists():
        raise FileNotFoundError(f"Missing input zip: {ZIP_PATH}")
    EXTRACT_DIR.mkdir(exist_ok=True)
    with zipfile.ZipFile(ZIP_PATH, "r") as zf:
        zf.extractall(EXTRACT_DIR)
    return EXTRACT_DIR


def _read_one_row_cost_table(xlsx_path: Path, sheet_name: str):
    df = pd.read_excel(xlsx_path, sheet_name=sheet_name)
    raw_policy = str(df.iloc[0, 0]).strip()
    case = str(df.iloc[0, 1]).strip()
    values = pd.to_numeric(df.iloc[0, 2:], errors="coerce").fillna(0.0)
    values.index = [str(c).strip() for c in df.columns[2:]]
    return raw_policy, case, values.astype(float)


def _prepare_power_row(xlsx_path: Path):
    raw_policy, case, raw = _read_one_row_cost_table(xlsx_path, "Power_Cost_Breakdown_bnUSD")
    renamed = raw.rename(index=power_col_map)
    row = pd.Series(0.0, index=power_plot_cols, dtype=float)

    for col in power_plot_cols:
        if col in renamed.index:
            row[col] += float(renamed.loc[col])

    row["VRE O&M"] = (
        float(renamed.get("Offshore-wind O&M", 0.0))
        + float(renamed.get("Onshore-wind O&M", 0.0))
        + float(renamed.get("PV O&M", 0.0))
    )
    return raw_policy, case, row


def _prepare_carbon_row(xlsx_path: Path):
    raw_policy, case, raw = _read_one_row_cost_table(xlsx_path, "Carbon_Cost_Breakdown_bnUSD")
    renamed = raw.rename(index=carbon_col_map)
    renamed = renamed.groupby(level=0).sum()
    row = pd.Series(0.0, index=carbon_plot_cols, dtype=float)

    for col in carbon_plot_cols:
        if col in renamed.index:
            row[col] += float(renamed.loc[col])
    return raw_policy, case, row


def load_cost_tables():
    extract_root = extract_zip_if_needed()
    xlsx_files = sorted(glob.glob(str(extract_root / "Cost_Breakdown" / "*" / "*.xlsx")))
    if not xlsx_files:
        xlsx_files = sorted(glob.glob(str(extract_root / "*" / "*.xlsx")))
    if not xlsx_files:
        raise FileNotFoundError("No cost breakdown xlsx files found after extracting zip.")

    power_rows = {}
    carbon_rows = {}

    for path_str in xlsx_files:
        path = Path(path_str)
        raw_policy_p, case_p, power = _prepare_power_row(path)
        raw_policy_c, case_c, carbon = _prepare_carbon_row(path)
        if raw_policy_p != raw_policy_c or case_p != case_c:
            raise ValueError(f"Policy/case mismatch between power and carbon sheets in {path}")
        policy = RAW_POLICY_TO_DISPLAY.get(raw_policy_p, raw_policy_p)
        key = (policy, case_p)
        power_rows[key] = power
        carbon_rows[key] = carbon

    ordered_keys = [(p, c) for p in POLICY_ORDER_DISPLAY for c in CASE_ORDER]
    missing = [k for k in ordered_keys if k not in power_rows]
    if missing:
        raise ValueError(f"Missing scenario files for: {missing}")

    power_df = pd.DataFrame(
        [power_rows[k] for k in ordered_keys],
        index=pd.MultiIndex.from_tuples(ordered_keys, names=["Policy", "Case"]),
    ).fillna(0.0)
    carbon_df = pd.DataFrame(
        [carbon_rows[k] for k in ordered_keys],
        index=pd.MultiIndex.from_tuples(ordered_keys, names=["Policy", "Case"]),
    ).fillna(0.0)

    power_df = power_df.loc[:, power_df.abs().sum(axis=0) > 1e-9]
    carbon_df = carbon_df.loc[:, carbon_df.abs().sum(axis=0) > 1e-9]
    return power_df, carbon_df


# ================================ Plotting ================================ #

def _positions():
    bar_width = 0.245
    within_pair_gap = 0.035
    pair_gap = 0.18
    policy_gap = 0.28

    tsc_x, cnc_x, pair_centers = [], [], []
    policy_spans = {}
    x = 0.0
    for policy in POLICY_ORDER_DISPLAY:
        first_center = None
        last_center = None
        for case in CASE_ORDER:
            tsc = x
            cnc = x + bar_width + within_pair_gap
            center = ((tsc + bar_width / 2.0) + (cnc + bar_width / 2.0)) / 2.0
            tsc_x.append(tsc)
            cnc_x.append(cnc)
            pair_centers.append(center)
            if first_center is None:
                first_center = center
            last_center = center
            x += 2 * bar_width + within_pair_gap + pair_gap
        policy_spans[policy] = (first_center, last_center)
        x += policy_gap
    return np.array(tsc_x), np.array(cnc_x), np.array(pair_centers), policy_spans, bar_width


def _nice_left_ylim(max_val: float):
    upper = np.ceil(max_val * 1.08 / 1000) * 1000 if max_val <= 10000 else np.ceil(max_val * 1.05 / 2000) * 2000
    step = 2000 if max_val <= 10000 else 4000
    ticks = np.arange(0, upper + 1e-9, step)
    return upper, ticks


def _nice_right_ylim(max_val: float, left_upper: float | None = None):
    scale_matched_upper = 0.0 if left_upper is None else left_upper * 0.03
    raw_upper = max(400, max_val * 1.12, scale_matched_upper)
    step = 50 if raw_upper <= 350 else 80
    upper = np.ceil(raw_upper / step) * step
    ticks = np.arange(0, upper + 1e-9, step)
    return upper, ticks


def plot_cost_breakdown(power_df: pd.DataFrame, carbon_df: pd.DataFrame, out_png: Path):
    ordered_index = pd.MultiIndex.from_product([POLICY_ORDER_DISPLAY, CASE_ORDER], names=["Policy", "Case"])
    power_df = power_df.reindex(ordered_index).fillna(0.0)
    carbon_df = carbon_df.reindex(ordered_index).fillna(0.0)

    tsc_x, cnc_x, pair_centers, policy_spans, bar_width = _positions()
    x_all = np.ravel(np.column_stack([tsc_x, cnc_x]))
    labels_all = [label for _ in range(len(tsc_x)) for label in [LEFT_BAR_LABEL, RIGHT_BAR_LABEL]]

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

    fig, ax1 = plt.subplots(figsize=(12.2, 6.0))
    ax2 = ax1.twinx()

    bottom_total = np.zeros(len(power_df))
    power_legend_handles = []
    for col in power_df.columns:
        vals = power_df[col].values.astype(float)
        if np.allclose(vals, 0):
            continue
        ax1.bar(
            tsc_x, vals, width=bar_width, bottom=bottom_total,
            color=power_colors.get(col, "#999999"), edgecolor="none",
            linewidth=0, align="edge", zorder=3, label=col,
        )
        bottom_total += vals
        power_legend_handles.append(Patch(facecolor=power_colors.get(col, "#999999"), edgecolor="none", label=col))

    # Aggregate CO2 system costs into one CSC segment on each left bar.
    carbon_total = carbon_df.sum(axis=1).to_numpy(dtype=float)
    ax1.bar(
        tsc_x, carbon_total, width=bar_width, bottom=bottom_total,
        color=carbon_total_color, edgecolor="none",
        linewidth=0, align="edge", zorder=3, label=carbon_total_label,
    )
    bottom_total += carbon_total
    power_legend_handles.append(
        Patch(facecolor=carbon_total_color, edgecolor="none", label=carbon_total_label)
    )

    bottom_carbon = np.zeros(len(carbon_df))
    carbon_legend_handles = []
    for col in carbon_df.columns:
        vals = carbon_df[col].values.astype(float)
        if np.allclose(vals, 0):
            continue
        ax2.bar(
            cnc_x, vals, width=bar_width, bottom=bottom_carbon,
            color=carbon_colors.get(col, "#999999"), edgecolor="none",
            linewidth=0, align="edge", zorder=3, label=col,
        )
        bottom_carbon += vals
        carbon_legend_handles.append(Patch(facecolor=carbon_colors.get(col, "#999999"), edgecolor="none", label=col))

    left_upper, left_ticks = _nice_left_ylim(float(np.nanmax(bottom_total)))
    right_upper, right_ticks = _nice_right_ylim(float(np.nanmax(bottom_carbon)), left_upper)
    ax1.set_ylim(0, left_upper)
    ax1.set_yticks(left_ticks)
    ax2.set_ylim(0, right_upper)
    ax2.set_yticks(right_ticks)

    ax1.set_ylabel("TSC (2025 bn USD)", labelpad=4, fontsize=10)
    ax2.set_ylabel("CSC (2025 bn USD)", labelpad=7, fontsize=10)
    ax1.grid(axis="y", linestyle="--", linewidth=0.6, alpha=0.32, zorder=0)
    ax1.set_axisbelow(True)

    ax1.set_xticks(x_all + bar_width / 2.0)
    ax1.set_xticklabels(labels_all, rotation=0, va="top", fontsize=8)

    cases_repeated = CASE_ORDER * len(POLICY_ORDER_DISPLAY)
    for xc, case in zip(pair_centers, cases_repeated):
        ax1.text(
            xc, -0.092, CASE_DISPLAY.get(case, case), transform=ax1.get_xaxis_transform(),
            ha="center", va="top", fontsize=9.5, rotation=35,
        )

    # Show policy names only; remove the bracket-like group lines.
    for policy, (x0, x1) in policy_spans.items():
        ax1.text(
            (x0 + x1) / 2.0, -0.27, policy,
            transform=ax1.get_xaxis_transform(),
            ha="center", va="top", fontsize=12, fontweight="semibold",
        )

    policy_bounds = list(policy_spans.values())
    for i in range(len(policy_bounds) - 1):
        sep = (policy_bounds[i][1] + policy_bounds[i + 1][0]) / 2.0
        ax1.axvline(sep, color="#BFBFBF", lw=0.6, ymin=0, ymax=0.985, zorder=1)

    ax1.set_xlim(tsc_x.min() - 0.28, cnc_x.max() + bar_width + 0.28)

    for ax in [ax1, ax2]:
        ax.spines["top"].set_visible(True)
        ax.tick_params(axis="y", direction="in", length=3, width=1.5)

    # Keep x-axis tick marks unchanged.
    ax1.tick_params(axis="x", length=3, width=1.5)
    ax1.spines["right"].set_visible(False)
    ax2.spines["left"].set_visible(False)

    handles = power_legend_handles + carbon_legend_handles
    labels = [h.get_label() for h in handles]
    ax1.legend(
        handles, labels,
        ncol=7, loc="upper center", bbox_to_anchor=(0.5, 1.4),
        frameon=False, columnspacing=1.6, labelspacing=1.1,
        handletextpad=0.8, handlelength=2.2, handleheight=1.0,
        borderaxespad=0.2,
    )

    fig.subplots_adjust(left=0.075, right=0.88, bottom=0.255, top=0.72)
    fig.savefig(out_png, dpi=900, bbox_inches="tight", pad_inches=0.06)
    plt.close(fig)


# ================================ Main ================================ #

def main():
    power_df, carbon_df = load_cost_tables()
    plot_cost_breakdown(power_df, carbon_df, OUT_PNG)
    print(f"Saved PNG: {OUT_PNG}")


if __name__ == "__main__":
    main()
