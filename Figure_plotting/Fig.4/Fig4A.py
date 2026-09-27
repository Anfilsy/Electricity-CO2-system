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
        ip.run_line_magic("config", "InlineBackend.print_figure_kwargs = {'bbox_inches': None}")
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

# Tech_Geo.xlsx. Prefer current/script folder; if absent, fall back to original project path.
def resolve_file(filename, fallback_path):
    p0 = join(os.getcwd(), filename)
    if exists(p0):
        return p0
    p1 = join(wdir, filename)
    if exists(p1):
        return p1
    return fallback_path

Tech_Geo_path = resolve_file(
    "Tech_Geo.xlsx",
    r"D:\Research\China_E_C\Paper_Fig\Fig_4cases\Tech_Geo\Pref_50\CN50\Tech_Geo_CN50.xlsx"
)

out_dir = r"D:\Research\China_E_C\Paper_Fig\Fig_4cases\Tech_Geo\Pref_50\CN50"
os.makedirs(out_dir, exist_ok=True)
out_file = join(out_dir, "Coal_NG_50_Pref.png")


# =============================================================================
# 2. Read and project map layers
# =============================================================================

prov = gpd.read_file(prov_shp, encoding="utf-8")
prefecture = gpd.read_file(prefecture_shp, encoding="utf-8")
nine = gpd.read_file(nine_shp, encoding="utf-8")

# Read prefecture Chinese/GAMS mapping. The original notebook first extracted
# two columns, but the later merge needs the full table.
pref_map_full = pd.read_excel(prefecture_map_path)

# Project to EPSG:2343, same as original notebooks.
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
prefecture_2343 = prefecture_2343[~prefecture_2343["geometry"].is_empty].copy()

# South China Sea inset crop layers.
bbox_geo = box(106.5, 2.8, 123.0, 24.5)
bbox_2343 = gpd.GeoSeries([bbox_geo], crs=4326).to_crs(epsg=2343).iloc[0]
prefecture_crop = prefecture_2343[prefecture_2343.intersects(bbox_2343)].copy()
nine_crop = nine_2343[nine_2343.intersects(bbox_2343)].copy()


# =============================================================================
# 3. Common data utilities
# =============================================================================

# Province abbreviation -> GAMS province name.
prov_contrast = pd.read_excel(prov_contrast_path)
prov_contrast["Prov_short"] = prov_contrast["Prov_short"].astype(str).str.strip()
prov_contrast["Prov_name"] = prov_contrast["Prov_name"].astype(str).str.strip()

# Required columns in prefecture mapping.
required_cols = ["Province_CN", "Prefecture_CN", "GAMS_Province", "GAMS_Prefecture"]
missing_cols = [c for c in required_cols if c not in pref_map_full.columns]
if missing_cols:
    raise KeyError(f"prefecture_area_cn_pinyin_en.xlsx 缺少必要列：{missing_cols}")

pref_map_full = pref_map_full[required_cols].dropna().copy()
for c in required_cols:
    pref_map_full[c] = pref_map_full[c].astype(str).str.strip()

# Individual GAMS-city aliases used in your original notebooks.
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
    Build prefecture-level GeoDataFrame for one technology sheet.

    Parameters
    ----------
    sheet_name : str
        'U_CO_acm_pref50' or 'U_NG_acm_pref50'

    Returns
    -------
    plot_gdf : GeoDataFrame
        Columns: 省, 市, geometry, Value
    """
    cs_pref = pd.read_excel(
        Tech_Geo_path,
        sheet_name=sheet_name,
        header=None,
        names=["Prov_short", "GAMS_Prefecture", "Value"]
    )

    cs_pref["Prov_short"] = cs_pref["Prov_short"].astype(str).str.strip()
    cs_pref["GAMS_Prefecture"] = cs_pref["GAMS_Prefecture"].astype(str).str.strip()
    cs_pref["Value"] = pd.to_numeric(cs_pref["Value"], errors="coerce").fillna(0)

    cs_pref["GAMS_Prefecture"] = cs_pref.apply(
        lambda r: pref_alias.get((r["Prov_short"], r["GAMS_Prefecture"]), r["GAMS_Prefecture"]),
        axis=1
    )

    cs_pref = cs_pref.merge(
        prov_contrast[["Prov_short", "Prov_name"]],
        on="Prov_short",
        how="left"
    )

    # Inner Mongolia split is mapped back to the mapping table's InnerMongolia.
    cs_pref["GAMS_Province"] = cs_pref["Prov_name"].replace({
        "W_InnerMongolia": "InnerMongolia",
        "E_InnerMongolia": "InnerMongolia",
        "Inner Mongolia": "InnerMongolia",
    })

    unmatched_prov = cs_pref.loc[cs_pref["Prov_name"].isna(), "Prov_short"].unique()
    if len(unmatched_prov) > 0:
        print(f">>> {sheet_name}: 以下省份简称未在 Prov_contrast.xlsx 中匹配到：", unmatched_prov)

    cs_pref_map = cs_pref.merge(
        pref_map_full,
        on=["GAMS_Province", "GAMS_Prefecture"],
        how="left"
    )

    unmatched_pref = cs_pref_map[cs_pref_map["Prefecture_CN"].isna()].copy()
    print(f">>> {sheet_name}: 未匹配到中文地级市的记录数: {len(unmatched_pref)}")
    if len(unmatched_pref) > 0:
        print(
            unmatched_pref[
                ["Prov_short", "Prov_name", "GAMS_Province", "GAMS_Prefecture", "Value"]
            ].head(20).to_string(index=False)
        )

    pref_merged = prefecture_2343.merge(
        cs_pref_map[["Province_CN", "Prefecture_CN", "Value"]],
        left_on=["省", "市"],
        right_on=["Province_CN", "Prefecture_CN"],
        how="left"
    )

    plot_gdf = pref_merged[["省", "市", "geometry", "Value"]].copy()
    plot_gdf = gpd.GeoDataFrame(plot_gdf, geometry="geometry", crs=prefecture_2343.crs)

    plot_gdf["geometry"] = plot_gdf["geometry"].apply(
        lambda g: remove_small_parts(g, min_area=5e8)
    )
    plot_gdf = plot_gdf.dropna(subset=["geometry"]).copy()

    return plot_gdf


# =============================================================================
# 4. Common color scale: Coal and NG use the same 0-20 GW range
# =============================================================================

vmin = 0
vmax = 20  # Shared Coal/NG range, as requested.

norm = mpl.colors.Normalize(vmin=vmin, vmax=vmax)

orig_cmap = mpl.colormaps["copper_r"]
colors = orig_cmap(np.linspace(0, 1, 256))
colors[:, -1] = 0.8
cmap_alpha = mpl.colors.ListedColormap(colors)


# =============================================================================
# 5. Plotting functions
# =============================================================================

def draw_south_china_sea_inset_single(fig):
    """
    Draw South China Sea inset using the same absolute position logic as the
    reference 4-panel code. The map is first rendered as a complete single-map
    image and then cropped/composed, so the inset keeps its original relative
    relation with the main map and will not overlap Taiwan after拼图.
    """
    axins = fig.add_axes([0.78, 0.06, 0.18, 0.22])

    prefecture_crop.plot(
        ax=axins,
        facecolor="lightgrey",
        edgecolor="white",
        linewidth=0.6,
        zorder=1
    )

    nine_crop.plot(
        ax=axins,
        color="gray",
        linewidth=1.5,
        linestyle="--",
        zorder=2
    )

    minx_i, miny_i, maxx_i, maxy_i = bbox_2343.bounds
    axins.set_xlim(minx_i, maxx_i)
    axins.set_ylim(miny_i, maxy_i)
    axins.set_xticks([])
    axins.set_yticks([])
    axins.set_axis_off()

    rect = Rectangle(
        (0, 0), 1, 1,
        transform=axins.transAxes,
        fill=False,
        edgecolor="black",
        linewidth=0.8,
        zorder=10,
        clip_on=False
    )
    axins.add_patch(rect)

    return axins


def draw_one_map(ax, plot_gdf):
    """Draw one coal/NG prefecture-level map on a single-map canvas."""
    # Background: prefecture-level map.
    prefecture_2343.plot(
        ax=ax,
        facecolor="lightgrey",
        edgecolor="white",
        linewidth=0.6,
        zorder=1
    )

    ax.set_axis_off()

    # Fixed range based on province-level total bounds.
    minx, miny, maxx, maxy = prov_2343.total_bounds
    ax.set_xlim(minx, maxx)
    ax.set_ylim(miny, maxy)

    # Only draw cities with valid data; cities without data remain lightgrey.
    plot_gdf_valid = plot_gdf[plot_gdf["Value"].notna()].copy()

    plot_gdf_valid.plot(
        column="Value",
        cmap=cmap_alpha,
        norm=norm,
        linewidth=0,
        edgecolor="none",
        ax=ax,
        zorder=1.6
    )

    # Re-overlay prefecture boundaries.
    prefecture_2343.boundary.plot(
        ax=ax,
        edgecolor="white",
        linewidth=0.7,
        alpha=0.65,
        zorder=3.0
    )

    # Re-overlay province boundaries.
    prov_2343.boundary.plot(
        ax=ax,
        edgecolor="grey",
        linewidth=0.8,
        zorder=4.0
    )

    # Lock the map range again after plotting.
    ax.set_xlim(minx, maxx)
    ax.set_ylim(miny, maxy)
    ax.set_axis_off()


def render_one_panel_to_image(plot_gdf):
    """
    Render one complete single-map figure to RGBA array.

    This follows the reference-code strategy: first render each map independently,
    then crop and compose the rendered images. This avoids the inset being shifted
    by subplot compression and preserves the original map / inset proportion.
    """
    fig, ax = plt.subplots(figsize=(16, 10), constrained_layout=True, dpi=300)
    FigureCanvas(fig)
    fig.canvas.draw()

    draw_one_map(ax, plot_gdf)
    draw_south_china_sea_inset_single(fig)

    # Freeze layout and export to RGBA.
    try:
        fig.set_constrained_layout(False)
    except Exception:
        pass

    fig.canvas.draw()
    w, h = fig.canvas.get_width_height()
    arr = np.frombuffer(fig.canvas.buffer_rgba(), dtype=np.uint8).reshape(h, w, 4).copy()
    plt.close(fig)

    return arr


def crop_rgba_to_content(arr, pad=55, threshold=250):
    """
    Crop white margins from a rendered single-map image without changing the
    relative positions of the main map and South China Sea inset.
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


# =============================================================================
# 6. Build data and draw combined figure
# =============================================================================

coal_gdf = build_prefecture_value_gdf("U_CO_acm_pref50")
ng_gdf = build_prefecture_value_gdf("U_NG_acm_pref50")

print(">>> Coal max capacity:", coal_gdf["Value"].max())
print(">>> NG max capacity:", ng_gdf["Value"].max())

print(">>> 正在渲染 Coal 单图 ...")
coal_img = crop_rgba_to_content(render_one_panel_to_image(coal_gdf), pad=55, threshold=250)
print(">>> 正在渲染 NG 单图 ...")
ng_img = crop_rgba_to_content(render_one_panel_to_image(ng_gdf), pad=55, threshold=250)

# One row, two columns, one shared colorbar. No top legend and no A/B labels.
fig_w = 24
fig_h = 8.8
fig = plt.figure(figsize=(fig_w, fig_h), dpi=300)
FigureCanvas(fig)
fig.canvas.draw()

# Use the cropped single-map image aspect ratio to avoid stretching.
img_h, img_w = ng_img.shape[:2]
img_aspect = img_w / img_h

# Layout style follows Cap_50_Prov_4cases_fixed_v4.py:
# small left margin, very small column gap, and colorbar close to the maps.
left_margin = 0.004
right_map_limit = 0.900
col_gap = 0.002
bottom_margin = 0.030
top_map_limit = 0.980

max_cell_w = (right_map_limit - left_margin - col_gap) / 2
max_cell_h = top_map_limit - bottom_margin

cell_w = max_cell_w
cell_h = cell_w * fig_w / (img_aspect * fig_h)

if cell_h > max_cell_h:
    cell_h = max_cell_h
    cell_w = cell_h * img_aspect * fig_h / fig_w

left_1 = left_margin
left_2 = left_1 + cell_w + col_gap
bottom = bottom_margin + (max_cell_h - cell_h) / 2

left_panel = [left_1, bottom, cell_w, cell_h]
right_panel = [left_2, bottom, cell_w, cell_h]

ax_coal = fig.add_axes(left_panel)
ax_coal.imshow(coal_img)
ax_coal.set_aspect("equal")
ax_coal.set_axis_off()

ax_ng = fig.add_axes(right_panel)
ax_ng.imshow(ng_img)
ax_ng.set_aspect("equal")
ax_ng.set_axis_off()

# Shared colorbar, using 0-20 GW range.
sm = mpl.cm.ScalarMappable(norm=norm, cmap=cmap_alpha)
sm._A = []

right_edge = right_panel[0] + right_panel[2]
cbar_gap = 0.022
cbar_w = 0.018
cbar_h = cell_h * 0.75
cbar_y = bottom + (cell_h - cbar_h) / 2
cbar_x = right_edge + cbar_gap

cax = fig.add_axes([cbar_x, cbar_y, cbar_w, cbar_h])
cbar = plt.colorbar(
    sm,
    cax=cax,
    orientation="vertical",
    ticks=np.arange(0, vmax + 1e-9, 4)
)
cbar.ax.patch.set_facecolor("lightgrey")
cbar.outline.set_edgecolor("none")
cax.tick_params(axis="y", direction="in", labelsize=18, width=1.85, length=4.3)
cbar.set_label("Capacity (GW)", fontsize=22, labelpad=10)


# =============================================================================
# 7. Save
# =============================================================================

fig.savefig(
    out_file,
    dpi=600,
    bbox_inches="tight",
    pad_inches=0.04
)

print(f"图片已保存到: {out_file}")
plt.show()
