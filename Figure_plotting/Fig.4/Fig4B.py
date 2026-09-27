from pathlib import Path
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap


# ================================ Paths ================================ #

WDIR = Path(__file__).resolve().parent if "__file__" in globals() else Path.cwd()
CAP_FILE = WDIR / "Fig_cn50_export.xlsx"
OUT_PNG = WDIR / "Coal_CCS_Retrofit_updated.png"


# ================================ User controls ================================ #

# Display order: 2050 on top, 2030 at the bottom.
YEARS = [2050, 2045, 2040, 2035, 2030]

# Province labels: use full English names and display them vertically.
X_LABEL_ROTATION = 90
X_LABEL_FONTSIZE = 13
YEAR_FONTSIZE = 10.5
YLABEL_FONTSIZE = 13
CBAR_LABEL_FONTSIZE = 13
CBAR_TICK_FONTSIZE = 10

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

VMIN = 0.0
VMAX = 1.0

# Muted blue-purple palette for CCS retrofit share.
'''
CCS_CMAP = LinearSegmentedColormap.from_list(
    "ccs_retrofit_grey_blue",
    ["#F2F1ED", "#E0DDD8", "#C9C9C4", "#AEB9C2", "#7F9EB2", "#5C7D95"],
    N=256,
)
'''
CCS_CMAP = LinearSegmentedColormap.from_list(
    "ccs_retrofit_warm_grey",
    ["#F3F1EC", "#E3DDD3", "#CFC7BC", "#B2A79D", "#8F8178", "#6E625B"],
    N=256,
)

FIGSIZE = (12.8, 5.4)
DPI = 600


# ================================ Data utilities ================================ #

def _require_file(path: Path):
    if not path.exists():
        raise FileNotFoundError(f"Missing required input file: {path}")


def load_capacity_sheet(path: Path, sheet_name: str) -> pd.Series:
    """
    Read one capacity sheet from Fig_cn50_export.xlsx.

    Expected format:
        column 0: province abbreviation
        column 1: capacity in GW
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


def get_province_order() -> list[str]:
    """
    Use the union of provinces appearing in the coal-capacity sheets,
    preserving early-year sheet order.
    """
    provinces = []

    for year in [2030, 2035, 2040, 2045, 2050]:
        yy = str(year)[-2:]
        sheet_name = f"U_CO_acm{yy}"
        co = load_capacity_sheet(CAP_FILE, sheet_name)

        for prov in co.index.tolist():
            if prov not in provinces:
                provinces.append(prov)

    return provinces


def make_ccs_ratio_matrix(provinces: list[str]) -> pd.DataFrame:
    """
    Build a year x province matrix:
        retrofit ratio = U_CCS_acmYY / U_CO_acmYY

    If total coal capacity is zero or missing, ratio is set to zero.
    If CCS capacity is missing, it is treated as zero.
    """
    rows = []

    for year in YEARS:
        yy = str(year)[-2:]

        total_coal = load_capacity_sheet(CAP_FILE, f"U_CO_acm{yy}")
        retrofit_ccs = load_capacity_sheet(CAP_FILE, f"U_CCS_acm{yy}")

        denominator = total_coal.reindex(provinces).fillna(0.0)
        numerator = retrofit_ccs.reindex(provinces).fillna(0.0)

        ratio_values = np.divide(
            numerator.values,
            denominator.values,
            out=np.zeros_like(numerator.values, dtype=float),
            where=denominator.values > 0,
        )

        ratio = pd.Series(ratio_values, index=provinces)
        rows.append(ratio)

    ratio_df = pd.DataFrame(rows, index=YEARS, columns=provinces)

    over_one = ratio_df > 1.0 + 1e-9
    if over_one.any().any():
        print("Warning: some CCS retrofit ratios are greater than 1. "
              "They will be clipped only for color display.")

    return ratio_df


# ================================ Plotting ================================ #

def plot_heatmap(ax, data: pd.DataFrame):
    plot_data = data.clip(lower=VMIN, upper=VMAX).values

    im = ax.imshow(
        plot_data,
        aspect="equal",
        interpolation="nearest",
        cmap=CCS_CMAP,
        vmin=VMIN,
        vmax=VMAX,
    )

    n_years, n_prov = data.shape

    ax.set_yticks(np.arange(n_years))
    ax.set_yticklabels([str(y) for y in data.index], fontsize=YEAR_FONTSIZE)

    ax.set_xticks(np.arange(n_prov))
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

    ax.set_ylabel("Coal-iCC", fontsize=YLABEL_FONTSIZE)

    # White cell boundaries.
    ax.set_xticks(np.arange(-0.5, n_prov, 1), minor=True)
    ax.set_yticks(np.arange(-0.5, n_years, 1), minor=True)
    ax.grid(which="minor", color="white", linestyle="-", linewidth=0.45)
    ax.tick_params(which="minor", bottom=False, left=False)

    # Major ticks: all point inward.
    ax.tick_params(
        axis="x",
        which="major",
        bottom=True,
        labelbottom=True,
        direction="in",
        labelsize=X_LABEL_FONTSIZE,
        length=3.0,
        width=1.1,
        pad=5.0,
    )
    ax.tick_params(
        axis="y",
        which="major",
        direction="in",
        labelsize=YEAR_FONTSIZE,
        length=3.0,
        width=1.1,
    )

    for spine in ax.spines.values():
        spine.set_visible(False)

    return im


def main():
    provinces = get_province_order()
    ccs_ratio = make_ccs_ratio_matrix(provinces)

    plt.rcParams.update({
        "font.family": "DejaVu Sans",
        "font.sans-serif": ["DejaVu Sans"],
        "axes.unicode_minus": False,
        "xtick.direction": "in",
        "ytick.direction": "in",
    })

    fig, ax = plt.subplots(
        nrows=1,
        ncols=1,
        figsize=FIGSIZE,
        dpi=DPI,
    )

    im = plot_heatmap(ax, ccs_ratio)

    # Finalize the heatmap layout first. The colorbar is positioned only after
    # this step, so it follows the final heatmap position and does not overlap it.
    fig.subplots_adjust(
        left=0.070,
        right=0.945,
        top=0.950,
        bottom=0.390,
    )
    fig.canvas.draw()

    # Use an independent colorbar axes, as in PV_WT_Potential_cbar_fixed_axes.py.
    # This widens the colorbar without taking space from or resizing the heatmap.
    CBAR_GAP = 0.021
    CBAR_WIDTH = 0.015
    CBAR_HEIGHT_RATIO = 0.99

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
        "Retrofit ratio",
        fontsize=CBAR_LABEL_FONTSIZE,
        labelpad=10,
    )
    cbar.ax.tick_params(
        axis="y",
        which="major",
        direction="in",
        labelsize=CBAR_TICK_FONTSIZE,
        length=2.3,
        width=1.1,
    )

    # Remove the colorbar outline and all four axes spines.
    cbar.outline.set_visible(False)
    for spine in cbar.ax.spines.values():
        spine.set_visible(False)

    fig.savefig(OUT_PNG, dpi=DPI, bbox_inches="tight", pad_inches=0.1)
    plt.close(fig)

    print(f"Saved figure: {OUT_PNG}")


if __name__ == "__main__":
    main()
