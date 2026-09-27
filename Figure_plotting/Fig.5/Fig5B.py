
from pathlib import Path
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap


# ================================ Paths ================================ #

WDIR = Path(__file__).resolve().parent if "__file__" in globals() else Path.cwd()

PV_POT_FILE = WDIR / "PV_potential_Prov.xlsx"
WT_POT_FILE = WDIR / "Onshore_potential_Prov.xlsx"
CAP_FILE = WDIR / "Fig_cn50_export.xlsx"

OUT_PNG = WDIR / "PV_WT_Potential_updated_v3.png"


# ================================ User controls ================================ #

YEARS = [2050, 2040, 2030]

# Province labels: use full English names and display them vertically.
X_LABEL_ROTATION = 90
X_LABEL_FONTSIZE = 13.5
Y_TICK_FONTSIZE = 10.8
AXIS_LABEL_FONTSIZE = 13.5
CBAR_TICK_FONTSIZE = 10.0
CBAR_LABEL_FONTSIZE = 14


PROVINCE_NAME_MAP = {
    "AH": "Anhui", "BJ": "Beijing", "CQ": "Chongqing", "FJ": "Fujian",
    "GD": "Guangdong", "GS": "Gansu", "GX": "Guangxi", "GZ": "Guizhou",
    "HA": "Henan", "HB": "Hubei", "HE": "Hebei", "HI": "Hainan",
    "HL": "Heilongjiang", "HN": "Hunan", "JL": "Jilin", "JS": "Jiangsu",
    "JX": "Jiangxi", "LN": "Liaoning",
    "MD": "Mengdong", "MX": "Mengxi",
    "NX": "Ningxia", "QH": "Qinghai", "SC": "Sichuan", "SD": "Shandong",
    "SH": "Shanghai", "SN": "Shaanxi", "SX": "Shanxi", "TJ": "Tianjin",
    "XJ": "Xinjiang", "XZ": "Tibet", "YN": "Yunnan", "ZJ": "Zhejiang",
}

# If True, province abbreviations are also shown under the upper PV panel.
# If False, province abbreviations are shown only under the lower wind panel,
# which is cleaner when there are many provinces.
SHOW_XLABELS_ON_TOP_PANEL = False

# Color maps:
# PV: warm orange-red; Wind: blue-green.
PV_CMAP = LinearSegmentedColormap.from_list(
    "pv_natural_clearer_low",
    ["#FFF1B8", "#F6D97A", "#ECB05F", "#D97C55", "#B4554A", "#7E2F3E"],
    N=256,
)

WT_CMAP = LinearSegmentedColormap.from_list(
    "wind_natural",
    ["#FFFDEB", "#DDE9A6", "#A9CF9B", "#6BB7A8", "#3D86A8", "#244C7A"],
    N=256,
)

# Ratio range. Since this is capacity/potential, the intended range is 0–1.
VMIN = 0.0
VMAX = 1.0

# Figure size. Increase width if province labels still look crowded.
FIGSIZE = (15.5, 5.8)
DPI = 600


# ================================ Data utilities ================================ #

def _require_file(path: Path):
    if not path.exists():
        raise FileNotFoundError(f"Missing required input file: {path}")


def load_potential(path: Path) -> pd.Series:
    """
    Read provincial potential table.

    The uploaded potential files have:
        row 0: header-like row
        column 0: province abbreviation
        column 2: potential value in GW
    """
    _require_file(path)

    raw = pd.read_excel(path, sheet_name=0, header=None)
    df = raw.iloc[1:, [0, 2]].copy()
    df.columns = ["Province", "Potential"]

    df["Province"] = df["Province"].astype(str).str.strip()
    df["Potential"] = pd.to_numeric(df["Potential"], errors="coerce")

    df = df.dropna(subset=["Province", "Potential"])
    df = df[df["Province"].ne("")]

    if df["Province"].duplicated().any():
        dup = df.loc[df["Province"].duplicated(), "Province"].tolist()
        raise ValueError(f"Duplicated province abbreviations in {path.name}: {dup}")

    return df.set_index("Province")["Potential"]


def load_capacity_sheet(path: Path, sheet_name: str) -> pd.Series:
    """
    Read one capacity sheet from Fig_cn50_export.xlsx.

    Expected format:
        column 0: province abbreviation
        column 1: installed capacity in GW
    """
    _require_file(path)

    df = pd.read_excel(path, sheet_name=sheet_name, header=None)
    df = df.iloc[:, [0, 1]].copy()
    df.columns = ["Province", "Capacity"]

    df["Province"] = df["Province"].astype(str).str.strip()
    df["Capacity"] = pd.to_numeric(df["Capacity"], errors="coerce").fillna(0.0)

    df = df[df["Province"].ne("")]

    if df["Province"].duplicated().any():
        dup = df.loc[df["Province"].duplicated(), "Province"].tolist()
        raise ValueError(f"Duplicated province abbreviations in sheet {sheet_name}: {dup}")

    return df.set_index("Province")["Capacity"]


def make_ratio_matrix(cap_prefix: str, potential: pd.Series, provinces: list[str]) -> pd.DataFrame:
    """
    Build a year x province matrix of installation factors.

    cap_prefix:
        "U_PV_acm" for PV
        "U_WT_acm" for wind
    """
    rows = []

    for year in YEARS:
        yy = str(year)[-2:]
        sheet_name = f"{cap_prefix}{yy}"

        cap = load_capacity_sheet(CAP_FILE, sheet_name)
        cap = cap.reindex(provinces).fillna(0.0)

        pot = potential.reindex(provinces)

        if pot.isna().any():
            missing = pot[pot.isna()].index.tolist()
            raise ValueError(f"Missing potential values for provinces: {missing}")

        if (pot <= 0).any():
            bad = pot[pot <= 0].index.tolist()
            raise ValueError(f"Non-positive potential values found for provinces: {bad}")

        ratio = cap / pot
        rows.append(ratio)

    ratio_df = pd.DataFrame(rows, index=YEARS, columns=provinces)

    # Keep raw ratios for calculation, but warn if ratios fall outside [0, 1].
    over_one = ratio_df > 1.0 + 1e-9
    if over_one.any().any():
        print(f"Warning: {cap_prefix} has ratio values greater than 1. "
              "They will be clipped only for color display.")

    return ratio_df


# ================================ Plotting utilities ================================ #

def plot_heatmap(ax, data: pd.DataFrame, cmap: str, ylabel: str, show_xlabels: bool):
    """
    Draw one heatmap panel.
    """
    plot_data = data.clip(lower=VMIN, upper=VMAX).values

    im = ax.imshow(
        plot_data,
        aspect="equal",
        interpolation="nearest",
        cmap=cmap,
        vmin=VMIN,
        vmax=VMAX,
    )

    n_years, n_prov = data.shape

    # Major ticks.
    ax.set_yticks(np.arange(n_years))
    ax.set_yticklabels(
        [str(y) for y in data.index],
        fontsize=Y_TICK_FONTSIZE,
    )

    ax.set_xticks(np.arange(n_prov))
    if show_xlabels:
        province_labels = [
            PROVINCE_NAME_MAP.get(str(code).strip(), str(code).strip())
            for code in data.columns
        ]
        ax.set_xticklabels(
            province_labels,
            rotation=X_LABEL_ROTATION,
            ha="right",
            va="center",
            rotation_mode="anchor",
            fontsize=X_LABEL_FONTSIZE,
        )
        # Push the vertical province labels farther below the heatmap so they do not overlap the color blocks.
        ax.tick_params(axis="x", which="major", pad=4.0)
    else:
        # Keep bottom tick marks on the upper panel, but do not show province labels.
        ax.set_xticklabels([])
        ax.tick_params(
            axis="x", which="major",
            bottom=True, labelbottom=False,
            direction="in", length=1.8, width=0.75,
            pad=2.0,
        )

    ax.tick_params(
    axis="x",
    which="major",
    direction="in",
    labelsize=X_LABEL_FONTSIZE,
    length=2.1,
    width=1.03,
)

    ax.tick_params(
    axis="y",
    which="major",
    direction="in",
    labelsize=Y_TICK_FONTSIZE,
    length=2.1,
    width=1.03,
)

    ax.set_ylabel(ylabel, fontsize=AXIS_LABEL_FONTSIZE)

    # White cell boundaries, similar to the reference figure.
    ax.set_xticks(np.arange(-0.5, n_prov, 1), minor=True)
    ax.set_yticks(np.arange(-0.5, n_years, 1), minor=True)
    ax.grid(which="minor", color="white", linestyle="-", linewidth=0.45)
    ax.tick_params(which="minor", bottom=False, left=False)

    # Clean frame.
    for spine in ax.spines.values():
        spine.set_visible(False)

    return im


def main():
    pv_potential = load_potential(PV_POT_FILE)
    wt_potential = load_potential(WT_POT_FILE)

    # Use the province order from the PV potential table.
    # The uploaded wind potential and capacity sheets use the same abbreviations.
    provinces = pv_potential.index.tolist()

    # Safety check: wind potential should contain the same provinces.
    missing_in_wind = sorted(set(provinces) - set(wt_potential.index))
    if missing_in_wind:
        raise ValueError(f"These PV provinces are missing in wind potential table: {missing_in_wind}")

    pv_ratio = make_ratio_matrix("U_PV_acm", pv_potential, provinces)
    wt_ratio = make_ratio_matrix("U_WT_acm", wt_potential, provinces)

    plt.rcParams.update({
        "font.family": "DejaVu Sans",
        "font.sans-serif": ["DejaVu Sans"],
        "axes.unicode_minus": False,
        "xtick.direction": "in",
        "ytick.direction": "in",
    })

    fig, axes = plt.subplots(
        nrows=2,
        ncols=1,
        figsize=FIGSIZE,
        dpi=DPI,
        sharex=True,
        gridspec_kw={
            "height_ratios": [1, 1],
            "hspace": 0.14,
        },
    )

    im_pv = plot_heatmap(
        axes[0],
        pv_ratio,
        PV_CMAP,
        ylabel="Solar PV",
        show_xlabels=SHOW_XLABELS_ON_TOP_PANEL,
    )

    im_wt = plot_heatmap(
        axes[1],
        wt_ratio,
        WT_CMAP,
        ylabel="Wind power",
        show_xlabels=True,
    )

    # Compact margins with enough room for horizontal province abbreviations.
    # Apply the final subplot layout BEFORE creating the colorbars so that the
    # manually positioned colorbar axes do not resize either heatmap panel.
    fig.subplots_adjust(
        left=0.055,
        right=0.955,
        top=0.965,
        bottom=0.47,
    )

    # Colorbars on the right side of each panel.
    # Do not use fraction=... here: fig.colorbar(..., ax=axes[i]) steals space
    # from the heatmap axes, so increasing fraction changes the panel proportions.
    # Instead, create independent colorbar axes with a fixed figure-coordinate
    # width. This makes the bars wider while preserving the heatmap dimensions.
    CBAR_GAP = 0.012
    CBAR_WIDTH = 0.014
    CBAR_HEIGHT_RATIO = 0.99

    def add_fixed_colorbar(fig, ax, im):
        pos = ax.get_position()
        cbar_height = pos.height * CBAR_HEIGHT_RATIO
        cbar_bottom = pos.y0 + (pos.height - cbar_height) / 2
        cax = fig.add_axes([
            pos.x1 + CBAR_GAP,
            cbar_bottom,
            CBAR_WIDTH,
            cbar_height,
        ])

        cbar = fig.colorbar(im, cax=cax)
        cbar.set_label(
            "Utilization\nfactor",
            fontsize=CBAR_LABEL_FONTSIZE,
            labelpad=10,
        )
        cbar.ax.tick_params(
            axis="y", which="major",
            direction="in",
            labelsize=CBAR_TICK_FONTSIZE,
            length=1.9,
            width=1.05,
        )

        # Remove the colorbar outline and all axis spines.
        cbar.outline.set_visible(False)
        for spine in cbar.ax.spines.values():
            spine.set_visible(False)

        return cbar

    cbar_pv = add_fixed_colorbar(fig, axes[0], im_pv)
    cbar_wt = add_fixed_colorbar(fig, axes[1], im_wt)

    fig.savefig(OUT_PNG, dpi=DPI, bbox_inches="tight", pad_inches=0.1)
    plt.close(fig)

    print(f"Saved figure: {OUT_PNG}")


if __name__ == "__main__":
    main()
