import os
import sys
from os.path import join, dirname, exists

import numpy as np
import pandas as pd
import geopandas as gpd
import matplotlib
import matplotlib.pyplot as plt
import matplotlib as mpl

from shapely.geometry import Polygon, MultiPolygon, box
from matplotlib.patches import Rectangle
from matplotlib.backends.backend_agg import FigureCanvasAgg as FigureCanvas


# =============================================================================
# 0. Basic settings
# =============================================================================

if os.name == "nt":
    os.system("chcp 65001 >nul")
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")

matplotlib.rcParams["font.family"] = "sans-serif"
matplotlib.rcParams["font.sans-serif"] = ["Arial", "SimHei", "DejaVu Sans"]
matplotlib.rcParams["axes.unicode_minus"] = False
mpl.rcParams["mathtext.default"] = "regular"

# Inline backend setting, only relevant when running in Jupyter.
try:
    from IPython import get_ipython

    ip = get_ipython()
    if ip is not None:
        ip.run_line_magic(
            "config",
            "InlineBackend.print_figure_kwargs = {'bbox_inches': None}"
        )
except Exception:
    pass


# =============================================================================
# 1. Path settings
# =============================================================================

# Main working directory. When running as a script, this is the script folder.
wdir = dirname(__file__) if "__file__" in globals() else os.getcwd()

# Map files. Keep these as in your original notebooks unless your local path changed.
prov_shp = r"D:\Research\China_E_C\Map\CN_Map\CN_Province.shp"
prefecture_shp = r"D:\Research\China_E_C\Map\CN_Map_WGS1984\CN_Prefecture.shp"
nine_shp = r"D:\Research\China_E_C\Map\CN_Map\Jiu_Duan_Xian.shp"
prefecture_map_path = r"D:\Research\China_E_C\Map\CN_Map_WGS1984\prefecture_area_cn_pinyin_en.xlsx"
prov_contrast_path = r"D:\Research\China_E_C\Map\CN_Map_WGS1984\Prov_contrast.xlsx"


def resolve_file(filenames, fallback_path):
    """Resolve the first existing filename in current/script folder."""
    if isinstance(filenames, str):
        filenames = [filenames]

    for filename in filenames:
        p0 = join(os.getcwd(), filename)
        if exists(p0):
            return p0

        p1 = join(wdir, filename)
        if exists(p1):
            return p1

    return fallback_path


Tech_Geo_path = resolve_file(
    ["Tech_Geo_CN50.xlsx", "Tech_Geo.xlsx"],
    r"D:\Research\China_E_C\Paper_Fig\Fig_4cases\Tech_Geo\Pref_50\CN50\Tech_Geo_CN50.xlsx"
)

out_dir = r"D:\Research\China_E_C\Paper_Fig\Fig_4cases\Tech_Geo\Pref_50\CN50"
os.makedirs(out_dir, exist_ok=True)
out_file = join(out_dir, "PV_WT_3050_Pref.png")


# =============================================================================
# 2. Read and project map layers
# =============================================================================

prov = gpd.read_file(prov_shp, encoding="utf-8")
prefecture = gpd.read_file(prefecture_shp, encoding="utf-8")
nine = gpd.read_file(nine_shp, encoding="utf-8")

# Read prefecture Chinese/GAMS mapping.
pref_map_full = pd.read_excel(prefecture_map_path)

# Project to EPSG:2343, same as the original code.
prov_2343 = prov.to_crs(epsg=2343)
prefecture_2343 = prefecture.to_crs(epsg=2343)
nine_2343 = nine.to_crs(epsg=2343)


def remove_small_islands(geom, min_area=5e9):
    if geom is None or geom.is_empty:
        return geom
    if isinstance(geom, MultiPolygon):
        parts = [p for p in geom.geoms if p.area > min_area]
        if not parts:
            return geom
        return parts[0] if len(parts) == 1 else MultiPolygon(parts)
    return geom if geom.area > min_area else geom


prov_2343["geometry"] = prov_2343["geometry"].buffer(0)
prov_2343["geometry"] = prov_2343["geometry"].apply(
    lambda g: remove_small_islands(g, min_area=5e9)
)

prefecture_2343["geometry"] = prefecture_2343["geometry"].buffer(0)
prefecture_2343 = prefecture_2343[
    ~prefecture_2343["geometry"].is_empty
].copy()

# South China Sea inset crop layers.
bbox_geo = box(106.5, 2.8, 123.0, 24.5)
bbox_2343 = gpd.GeoSeries([bbox_geo], crs=4326).to_crs(epsg=2343).iloc[0]
prefecture_crop = prefecture_2343[
    prefecture_2343.intersects(bbox_2343)
].copy()
nine_crop = nine_2343[nine_2343.intersects(bbox_2343)].copy()


# =============================================================================
# 3. Common data utilities
# =============================================================================

# Province abbreviation -> GAMS province name.
prov_contrast = pd.read_excel(prov_contrast_path)
prov_contrast["Prov_short"] = prov_contrast["Prov_short"].astype(str).str.strip()
prov_contrast["Prov_name"] = prov_contrast["Prov_name"].astype(str).str.strip()

# Required columns in prefecture mapping.
required_cols = [
    "Province_CN",
    "Prefecture_CN",
    "GAMS_Province",
    "GAMS_Prefecture",
]
missing_cols = [c for c in required_cols if c not in pref_map_full.columns]
if missing_cols:
    raise KeyError(
        f"prefecture_area_cn_pinyin_en.xlsx 缺少必要列：{missing_cols}"
    )

pref_map_full = pref_map_full[required_cols].dropna().copy()
for c in required_cols:
    pref_map_full[c] = pref_map_full[c].astype(str).str.strip()

# Individual GAMS-city aliases used in the original notebooks.
pref_alias = {
    ("JS", "Weian"): "Huaian",  # 江苏淮安
}


def remove_small_parts(geom, min_area=5e8):
    if geom is None or geom.is_empty:
        return None
    if isinstance(geom, MultiPolygon):
        parts = [p for p in geom.geoms if p.area > min_area]
        if len(parts) == 0:
            return None
        return parts[0] if len(parts) == 1 else MultiPolygon(parts)
    if isinstance(geom, Polygon):
        return geom if geom.area > min_area else None
    return geom


def build_prefecture_value_gdf(sheet_name):
    """
    Build a prefecture-level GeoDataFrame from one technology/year sheet.

    Examples
    --------
    U_PV_acm_pref50
    U_WT_acm_pref50
    U_PV_acm_pref30
    U_WT_acm_pref30
    """
    cs_pref = pd.read_excel(
        Tech_Geo_path,
        sheet_name=sheet_name,
        header=None,
        names=["Prov_short", "GAMS_Prefecture", "Value"],
    )

    cs_pref["Prov_short"] = cs_pref["Prov_short"].astype(str).str.strip()
    cs_pref["GAMS_Prefecture"] = (
        cs_pref["GAMS_Prefecture"].astype(str).str.strip()
    )
    cs_pref["Value"] = pd.to_numeric(
        cs_pref["Value"], errors="coerce"
    ).fillna(0)

    cs_pref["GAMS_Prefecture"] = cs_pref.apply(
        lambda r: pref_alias.get(
            (r["Prov_short"], r["GAMS_Prefecture"]),
            r["GAMS_Prefecture"],
        ),
        axis=1,
    )

    cs_pref = cs_pref.merge(
        prov_contrast[["Prov_short", "Prov_name"]],
        on="Prov_short",
        how="left",
    )

    # Inner Mongolia split is mapped back to the mapping table's InnerMongolia.
    cs_pref["GAMS_Province"] = cs_pref["Prov_name"].replace(
        {
            "W_InnerMongolia": "InnerMongolia",
            "E_InnerMongolia": "InnerMongolia",
            "Inner Mongolia": "InnerMongolia",
        }
    )

    unmatched_prov = cs_pref.loc[
        cs_pref["Prov_name"].isna(), "Prov_short"
    ].unique()
    if len(unmatched_prov) > 0:
        print(
            f">>> {sheet_name}: 以下省份简称未在 Prov_contrast.xlsx 中匹配到：",
            unmatched_prov,
        )

    cs_pref_map = cs_pref.merge(
        pref_map_full,
        on=["GAMS_Province", "GAMS_Prefecture"],
        how="left",
    )

    unmatched_pref = cs_pref_map[
        cs_pref_map["Prefecture_CN"].isna()
    ].copy()
    print(
        f">>> {sheet_name}: 未匹配到中文地级市的记录数: {len(unmatched_pref)}"
    )
    if len(unmatched_pref) > 0:
        print(
            unmatched_pref[
                [
                    "Prov_short",
                    "Prov_name",
                    "GAMS_Province",
                    "GAMS_Prefecture",
                    "Value",
                ]
            ]
            .head(20)
            .to_string(index=False)
        )

    pref_merged = prefecture_2343.merge(
        cs_pref_map[["Province_CN", "Prefecture_CN", "Value"]],
        left_on=["省", "市"],
        right_on=["Province_CN", "Prefecture_CN"],
        how="left",
    )

    plot_gdf = pref_merged[["省", "市", "geometry", "Value"]].copy()
    plot_gdf = gpd.GeoDataFrame(
        plot_gdf,
        geometry="geometry",
        crs=prefecture_2343.crs,
    )

    plot_gdf["geometry"] = plot_gdf["geometry"].apply(
        lambda g: remove_small_parts(g, min_area=5e8)
    )
    plot_gdf = plot_gdf.dropna(subset=["geometry"]).copy()

    return plot_gdf


# =============================================================================
# 4. Common color scale: exactly retain the original 0-400 GW scale
# =============================================================================

vmin = 0
vmax = 400

# Capacity knots in GW. These are real data values shown on the colorbar.
value_knots = np.array(
    [0, 20, 40, 60, 80, 120, 180, 260, 320, 400],
    dtype=float,
)

# Corresponding positions in the colormap.
color_knots = np.array(
    [0.00, 0.18, 0.32, 0.45, 0.55, 0.68, 0.78, 0.88, 0.96, 1.00],
    dtype=float,
)


def forward_norm(x):
    return np.interp(np.asarray(x, dtype=float), value_knots, color_knots)


def inverse_norm(y):
    return np.interp(np.asarray(y, dtype=float), color_knots, value_knots)


norm = mpl.colors.FuncNorm(
    (forward_norm, inverse_norm),
    vmin=vmin,
    vmax=vmax,
)

# Keep the original viridis_r sampling and alpha.
orig_cmap = mpl.colormaps["viridis_r"]
cmap_pos = np.concatenate(
    [
        np.linspace(0.00, 0.20, 65, endpoint=False),
        np.linspace(0.20, 0.45, 85, endpoint=False),
        np.linspace(0.45, 0.70, 55, endpoint=False),
        np.linspace(0.70, 1.00, 51),
    ]
)
colors = orig_cmap(cmap_pos)
colors[:, -1] = 0.6
cmap_alpha = mpl.colors.ListedColormap(colors)


# =============================================================================
# 5. Plotting functions
# =============================================================================


def draw_south_china_sea_inset_single(fig):
    """
    Draw the South China Sea inset using the same absolute position logic as
    the original single-map rendering code.
    """
    axins = fig.add_axes([0.78, 0.06, 0.18, 0.22])

    prefecture_crop.plot(
        ax=axins,
        facecolor="lightgrey",
        edgecolor="white",
        linewidth=0.6,
        zorder=1,
    )

    nine_crop.plot(
        ax=axins,
        color="gray",
        linewidth=1.5,
        linestyle="--",
        zorder=2,
    )

    minx_i, miny_i, maxx_i, maxy_i = bbox_2343.bounds
    axins.set_xlim(minx_i, maxx_i)
    axins.set_ylim(miny_i, maxy_i)
    axins.set_xticks([])
    axins.set_yticks([])
    axins.set_axis_off()

    rect = Rectangle(
        (0, 0),
        1,
        1,
        transform=axins.transAxes,
        fill=False,
        edgecolor="black",
        linewidth=0.8,
        zorder=10,
        clip_on=False,
    )
    axins.add_patch(rect)

    return axins


def draw_one_map(ax, plot_gdf):
    """Draw one prefecture-level map on a single-map canvas."""
    prefecture_2343.plot(
        ax=ax,
        facecolor="lightgrey",
        edgecolor="white",
        linewidth=0.6,
        zorder=1,
    )

    ax.set_axis_off()

    minx, miny, maxx, maxy = prov_2343.total_bounds
    ax.set_xlim(minx, maxx)
    ax.set_ylim(miny, maxy)

    # Cities without data remain light grey.
    plot_gdf_valid = plot_gdf[plot_gdf["Value"].notna()].copy()

    plot_gdf_valid.plot(
        column="Value",
        cmap=cmap_alpha,
        norm=norm,
        linewidth=0,
        edgecolor="none",
        ax=ax,
        zorder=1.6,
    )

    prefecture_2343.boundary.plot(
        ax=ax,
        edgecolor="white",
        linewidth=0.7,
        alpha=0.65,
        zorder=3.0,
    )

    prov_2343.boundary.plot(
        ax=ax,
        edgecolor="grey",
        linewidth=0.8,
        zorder=4.0,
    )

    ax.set_xlim(minx, maxx)
    ax.set_ylim(miny, maxy)
    ax.set_axis_off()


def render_one_panel_to_image(plot_gdf):
    """
    Render one complete single-map figure to an RGBA array.

    All four maps use exactly the same single-panel rendering process, so their
    map extent, inset location, line widths and internal proportions are equal.
    """
    fig, ax = plt.subplots(
        figsize=(16, 10),
        constrained_layout=True,
        dpi=300,
    )
    FigureCanvas(fig)
    fig.canvas.draw()

    draw_one_map(ax, plot_gdf)
    draw_south_china_sea_inset_single(fig)

    try:
        fig.set_constrained_layout(False)
    except Exception:
        pass

    fig.canvas.draw()
    w, h = fig.canvas.get_width_height()
    arr = (
        np.frombuffer(fig.canvas.buffer_rgba(), dtype=np.uint8)
        .reshape(h, w, 4)
        .copy()
    )
    plt.close(fig)

    return arr


def crop_rgba_to_content(arr, pad=55, threshold=250):
    """
    Crop white margins without changing the relative positions of the main map
    and the South China Sea inset.
    """
    rgb = arr[:, :, :3]
    alpha = arr[:, :, 3]
    mask = (alpha > 0) & np.any(rgb < threshold, axis=2)

    if not np.any(mask):
        return arr

    ys, xs = np.where(mask)
    y0, y1 = ys.min(), ys.max() + 1
    x0, x1 = xs.min(), xs.max() + 1

    h, w = arr.shape[:2]
    y0 = max(0, y0 - pad)
    y1 = min(h, y1 + pad)
    x0 = max(0, x0 - pad)
    x1 = min(w, x1 + pad)

    return arr[y0:y1, x0:x1, :]


def add_image_panel(fig, panel_rect, image):
    """Add one rendered map image to an explicitly positioned panel."""
    ax = fig.add_axes(panel_rect)
    ax.imshow(image)
    ax.set_aspect("equal")
    ax.set_axis_off()
    return ax


# =============================================================================
# 6. Build the four datasets and render four map images
# =============================================================================

pv30_gdf = build_prefecture_value_gdf("U_PV_acm_pref30")
wt30_gdf = build_prefecture_value_gdf("U_WT_acm_pref30")
pv50_gdf = build_prefecture_value_gdf("U_PV_acm_pref50")
wt50_gdf = build_prefecture_value_gdf("U_WT_acm_pref50")

pv30_gdf.loc[pv30_gdf["Value"] < 0.5, "Value"] = np.nan
pv50_gdf.loc[pv50_gdf["Value"] < 0.5, "Value"] = np.nan
wt50_gdf.loc[wt50_gdf["Value"] < 0.5, "Value"] = np.nan
wt30_gdf.loc[wt30_gdf["Value"] < 0.5, "Value"] = np.nan

print(">>> PV 2030 max capacity:", pv30_gdf["Value"].max())
print(">>> WT 2030 max capacity:", wt30_gdf["Value"].max())
print(">>> PV 2050 max capacity:", pv50_gdf["Value"].max())
print(">>> WT 2050 max capacity:", wt50_gdf["Value"].max())

print(">>> 正在渲染 PV 2030 单图 ...")
pv30_img = crop_rgba_to_content(
    render_one_panel_to_image(pv30_gdf),
    pad=55,
    threshold=250,
)

print(">>> 正在渲染 WT 2030 单图 ...")
wt30_img = crop_rgba_to_content(
    render_one_panel_to_image(wt30_gdf),
    pad=55,
    threshold=250,
)

print(">>> 正在渲染 PV 2050 单图 ...")
pv50_img = crop_rgba_to_content(
    render_one_panel_to_image(pv50_gdf),
    pad=55,
    threshold=250,
)

print(">>> 正在渲染 WT 2050 单图 ...")
wt50_img = crop_rgba_to_content(
    render_one_panel_to_image(wt50_gdf),
    pad=55,
    threshold=250,
)


# =============================================================================
# 7. Two-row composition while preserving the original 2050 panel geometry
# =============================================================================

# -----------------------------------------------------------------------------
# The following values are the ORIGINAL one-row figure settings. They are kept
# unchanged and first used to recover the exact physical panel size/position of
# the two 2050 maps.
# -----------------------------------------------------------------------------
base_fig_w = 24.0
base_fig_h = 8.8

left_margin = 0.004
right_map_limit = 0.900
col_gap = 0.002
bottom_margin = 0.030
top_map_limit = 0.980

# Use the same reference image as the original code.
img_h, img_w = wt50_img.shape[:2]
img_aspect = img_w / img_h

max_cell_w = (right_map_limit - left_margin - col_gap) / 2
max_cell_h = top_map_limit - bottom_margin

# These are the original normalized panel dimensions on the 24 x 8.8 canvas.
cell_w_old = max_cell_w
cell_h_old = cell_w_old * base_fig_w / (img_aspect * base_fig_h)

if cell_h_old > max_cell_h:
    cell_h_old = max_cell_h
    cell_w_old = cell_h_old * img_aspect * base_fig_h / base_fig_w

left_1_old = left_margin
left_2_old = left_1_old + cell_w_old + col_gap
bottom_old = bottom_margin + (max_cell_h - cell_h_old) / 2

# Convert the original normalized geometry to physical inches.
# Because the new figure width remains 24 inches, all horizontal positions and
# widths remain exactly unchanged.
panel_w_in = cell_w_old * base_fig_w
panel_h_in = cell_h_old * base_fig_h
left_1_in = left_1_old * base_fig_w
left_2_in = left_2_old * base_fig_w
bottom_margin_in = bottom_old * base_fig_h
top_margin_in = base_fig_h - (bottom_old + cell_h_old) * base_fig_h

# Small physical gap between the two rows. Change only this value if you need
# the lower row slightly closer to or farther from the upper row.
row_gap_in = 0.12

# Add a second row downward, while retaining the original top margin and the
# original lower margin. Thus the 2050 row keeps its original physical size and
# distance from the top edge.
fig_w = base_fig_w
fig_h = (
    top_margin_in
    + panel_h_in
    + row_gap_in
    + panel_h_in
    + bottom_margin_in
)

fig = plt.figure(figsize=(fig_w, fig_h), dpi=300)
FigureCanvas(fig)
fig.canvas.draw()

# Physical y-positions in the enlarged canvas.
bottom_30_in = bottom_margin_in
bottom_50_in = bottom_30_in + panel_h_in + row_gap_in

# Convert physical-inch geometry to normalized figure coordinates.
panel_w = panel_w_in / fig_w
panel_h = panel_h_in / fig_h
left_1 = left_1_in / fig_w
left_2 = left_2_in / fig_w
bottom_30 = bottom_30_in / fig_h
bottom_50 = bottom_50_in / fig_h

# Top row panel positions
left_panel_top = [left_1, bottom_50, panel_w, panel_h]
right_panel_top = [left_2, bottom_50, panel_w, panel_h]

# Bottom row panel positions
left_panel_bottom = [left_1, bottom_30, panel_w, panel_h]
right_panel_bottom = [left_2, bottom_30, panel_w, panel_h]

# Put 2030 on the top row
add_image_panel(fig, left_panel_top, pv30_img)
add_image_panel(fig, right_panel_top, wt30_img)

# Put 2050 on the bottom row
add_image_panel(fig, left_panel_bottom, pv50_img)
add_image_panel(fig, right_panel_bottom, wt50_img)



# =============================================================================
# 8. Shared extended colorbar
# =============================================================================

# Preserve the original colorbar x-position and width exactly in physical units.
right_edge_old = left_2_old + cell_w_old
cbar_gap_old = 0.022
cbar_w_old = 0.018

right_edge_in = right_edge_old * base_fig_w
cbar_gap_in = cbar_gap_old * base_fig_w
cbar_w_in = cbar_w_old * base_fig_w
cbar_x_in = right_edge_in + cbar_gap_in

# Extend the colorbar to 75% of the complete two-row map block and center it
# vertically. The color range remains strictly 0-400 GW.
map_block_bottom_in = bottom_30_in
map_block_h_in = 2 * panel_h_in + row_gap_in
cbar_h_in = map_block_h_in * 0.75
cbar_y_in = map_block_bottom_in + (map_block_h_in - cbar_h_in) / 2

cbar_x = cbar_x_in / fig_w
cbar_y = cbar_y_in / fig_h
cbar_w = cbar_w_in / fig_w
cbar_h = cbar_h_in / fig_h

cax = fig.add_axes([cbar_x, cbar_y, cbar_w, cbar_h])

# Build a vertical data-value gradient with linear data coordinates.
_gradient_values = np.linspace(vmin, vmax, 4096).reshape(-1, 1)

cax.imshow(
    _gradient_values,
    cmap=cmap_alpha,
    norm=norm,
    origin="lower",
    aspect="auto",
    extent=[0, 1, vmin, vmax],
)

# Retain the original range and tick values.
cax.set_ylim(vmin, vmax)
cax.set_yticks(np.arange(0, vmax + 1, 50))
cax.set_xticks([])

cax.yaxis.tick_right()
cax.yaxis.set_label_position("right")
cax.tick_params(
    axis="y",
    direction="in",
    labelsize=18,
    width=1.88,
    length=4.3,
)

for spine in cax.spines.values():
    spine.set_visible(False)

cax.set_ylabel("Capacity (GW)", fontsize=22, labelpad=10)


# =============================================================================
# 9. Save
# =============================================================================

fig.savefig(
    out_file,
    dpi=600,
    bbox_inches="tight",
    pad_inches=0.04,
)

print(f"图片已保存到: {out_file}")
plt.show()
