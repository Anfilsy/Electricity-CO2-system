# %% [cell 0]
# -*- coding: utf-8 -*-
import os
import sys
import pandas as pd
import numpy as np
import geopandas as gpd
import matplotlib.pyplot as plt
import matplotlib
import matplotlib as mpl

from shapely.geometry import Polygon, MultiPolygon
from shapely.geometry import LineString, Point, box
from shapely.ops import split, unary_union

from mpl_toolkits.axes_grid1.inset_locator import inset_axes
from matplotlib.patches import Rectangle
from matplotlib.lines import Line2D
from matplotlib.patches import FancyArrowPatch
from matplotlib.patches import Wedge, Patch, Circle
import matplotlib.patheffects as pe

from matplotlib.colors import Normalize
from matplotlib import cm
from matplotlib.cm import ScalarMappable
from matplotlib.colors import Normalize, LinearSegmentedColormap

from matplotlib.offsetbox import AnchoredOffsetbox, VPacker, HPacker, TextArea, DrawingArea
from matplotlib.offsetbox import OffsetImage, AnnotationBbox
from matplotlib.backends.backend_agg import FigureCanvasAgg as FigureCanvas
import matplotlib.image as mpimg

mpl.rcParams['mathtext.default'] = 'regular'

# 中文到英文映射
ch_en_map = {
    "北京市": "Beijing", "天津市": "Tianjin", "上海市": "Shanghai", "重庆市": "Chongqing",
    "河北省": "Hebei", "山西省": "Shanxi", "内蒙古自治区": "Inner Mongolia", "辽宁省": "Liaoning",
    "吉林省": "Jilin", "黑龙江省": "Heilongjiang", "江苏省": "Jiangsu", "浙江省": "Zhejiang",
    "安徽省": "Anhui", "福建省": "Fujian", "江西省": "Jiangxi", "山东省": "Shandong",
    "河南省": "Henan", "湖北省": "Hubei", "湖南省": "Hunan", "广东省": "Guangdong",
    "广西壮族自治区": "Guangxi", "海南省": "Hainan", "四川省": "Sichuan", "贵州省": "Guizhou",
    "云南省": "Yunnan", "西藏自治区": "Tibet", "陕西省": "Shaanxi", "甘肃省": "Gansu",
    "青海省": "Qinghai", "宁夏回族自治区": "Ningxia", "新疆维吾尔自治区": "Sinkiang",
    "台湾省": "Taiwan", "香港特别行政区": "Hong Kong", "澳门特别行政区": "Macau"
}

# %% [cell 1]
# ======================================== 0. 控制台 UTF-8 & 字体 =====================================
if os.name == 'nt':
    os.system('chcp 65001 >nul')
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding='utf-8')

matplotlib.rcParams['font.family'] = 'sans-serif'
matplotlib.rcParams['font.sans-serif'] = ['Arial', 'SimHei']
matplotlib.rcParams['axes.unicode_minus'] = False

# —— 1. 路径设定 ——
prov_shp = r"D:\Research\China_E_C\Map\CN_Map\CN_Province.shp"
city_shp = r"D:\Research\China_E_C\Map\CN_Map_WGS1984\CN_Prefecture.shp"
nine_shp = r"D:\Research\China_E_C\Map\CN_Map\Jiu_Duan_Xian.shp"

out_dir = r"D:\Research\China_E_C\Paper_Fig\Fig_4cases\Tech_Geo\Prov_50"
os.makedirs(out_dir, exist_ok=True)

# 两个场景数据路径。每个工作簿同时包含 2030 年和 2050 年数据。
# 代码会优先读取当前工作目录下的同名 Excel；如果没有，再读取 out_dir 下的同名 Excel。
def resolve_excel_path(filename):
    p0 = os.path.join(os.getcwd(), filename)
    if os.path.exists(p0):
        return p0
    p1 = os.path.join(out_dir, filename)
    return p1

scenario_files = {
    "NDC": (
        resolve_excel_path("Geo_Prov_NDC.xlsx")
        if os.path.exists(resolve_excel_path("Geo_Prov_NDC.xlsx"))
        else resolve_excel_path("Geo_Prov_NDC(2).xlsx")
    ),
}

prov_contrast_path = r"D:\Research\China_E_C\Map\CN_Map_WGS1984\Prov_contrast.xlsx"
out_file = os.path.join(out_dir, "Cap_3050_Prov_NDC.png")

# %% [cell 2]
# ============================== 2. 读取 & 投影 ===============================
provinces = gpd.read_file(city_shp)

prov = gpd.read_file(prov_shp, encoding='utf-8')
nine = gpd.read_file(nine_shp, encoding='utf-8')

# 2.1 用于切分的地理 CRS
prov_geo = prov.to_crs(epsg=4326)

# 2.2 投影到 EPSG:2343，用于最终绘图
prov_2343 = prov.to_crs(epsg=2343)
nine_2343 = nine.to_crs(epsg=2343)

# 2.3 剔除小岛：沿用单图代码

def remove_small_islands(geom, min_area=5e9):
    if isinstance(geom, MultiPolygon):
        parts = [p for p in geom.geoms if p.area > min_area]
        if not parts:
            return geom
        return parts[0] if len(parts) == 1 else MultiPolygon(parts)
    return geom if geom.area > min_area else geom

prov_2343["geometry"] = prov_2343["geometry"].apply(
    lambda g: remove_small_islands(g, min_area=5e9)
)

# 南海 inset 裁剪图层：沿用单图代码
bbox_geo = box(106.5, 2.8, 123.0, 24.5)
bbox_2343 = gpd.GeoSeries([bbox_geo], crs=4326).to_crs(epsg=2343).iloc[0]

prov_crop = prov_2343[prov_2343.intersects(bbox_2343)]
nine_crop = nine_2343[nine_2343.intersects(bbox_2343)]

# %% [cell 3]
# ============================== 3. 基于地级市将内蒙古分为蒙西／蒙东两块 =================================
city = gpd.read_file(city_shp, encoding='utf-8').to_crs(epsg=2343)

im_city = city[city['省'] == "内蒙古自治区"].copy()

east_list = ["赤峰市", "通辽市", "兴安盟", "呼伦贝尔市"]
west_list = [c for c in im_city['市'].unique() if c not in east_list]

im_city['region'] = im_city['市'].apply(
    lambda s: 'W_InnerMongo' if s in west_list
    else ('E_InnerMongo' if s in east_list else None)
)

im_west = (
    im_city[im_city['region'] == "W_InnerMongo"]
    .dissolve(by='region')
    .reset_index()
)

im_east = (
    im_city[im_city['region'] == "E_InnerMongo"]
    .dissolve(by='region')
    .reset_index()
)

# %% [cell 4]
# ============================== 4. 底图、省份映射、色带和技术颜色 =================================
prov_contrast = pd.read_excel(prov_contrast_path)
prov_contrast["Prov_short"] = prov_contrast["Prov_short"].astype(str).str.strip()
prov_contrast["Prov_name"] = prov_contrast["Prov_name"].astype(str).str.strip()

# 中文省名转英文省名
ch_en_df = pd.DataFrame(
    list(ch_en_map.items()),
    columns=["province_cn", "province_en"]
)

prov_2343["province_cn"] = prov_2343["省"]

prov_base = prov_2343.merge(
    ch_en_df,
    on="province_cn",
    how="left"
)

mask_drop_im = prov_base["province_cn"].eq("内蒙古自治区")

prov_main = prov_base.loc[
    ~mask_drop_im,
    ["province_cn", "province_en", "geometry"]
].copy()

west_df = gpd.GeoDataFrame(
    {"province_cn": ["蒙西"], "province_en": ["W_InnerMongolia"]},
    geometry=im_west.geometry,
    crs=prov_2343.crs
)

east_df = gpd.GeoDataFrame(
    {"province_cn": ["蒙东"], "province_en": ["E_InnerMongolia"]},
    geometry=im_east.geometry,
    crs=prov_2343.crs
)

base_gdf = pd.concat(
    [prov_main, west_df, east_df],
    ignore_index=True
)

base_gdf = gpd.GeoDataFrame(
    base_gdf,
    geometry="geometry",
    crs=prov_2343.crs
)

# -----------------------------------------------------------------------------
# 两张子图（均为 CN50）共用一个 colorbar。范围由 CN50 在 2030/2050 年的
# 省级总装机自动计算，并向上取整到 100 GW。
# -----------------------------------------------------------------------------
PANEL_YEARS = (2030, 2050)

def calculate_shared_colorbar_range():
    maxima = []

    for scenario_name, scenario_path in scenario_files.items():
        for year in PANEL_YEARS:
            year_suffix = str(year)[-2:]
            sheet_name = f"U_EG_acm_tt{year_suffix}"

            df = pd.read_excel(
                scenario_path,
                sheet_name=sheet_name,
                header=None,
                names=["Prov_short", "Value"]
            )

            values = pd.to_numeric(df["Value"], errors="coerce")
            sheet_max = values.max()
            if pd.notna(sheet_max):
                maxima.append(float(sheet_max))
                print(
                    f">>> {scenario_name} {year} 省级总装机最大值: "
                    f"{float(sheet_max):.3f} GW"
                )

    if not maxima:
        raise ValueError("未能从 2030/2050 年省级总装机表中读取有效数据。")

    raw_max = max(maxima)
    rounded_max = max(100.0, np.ceil(raw_max / 100.0) * 100.0)
    return raw_max, rounded_max

vmin = 0.0
vmax = 1200
print(f">>> 两张子图统一 colorbar 范围: {vmin:.0f}–{vmax:.0f} GW")

norm = mpl.colors.Normalize(vmin=vmin, vmax=vmax)

# 地图颜色和透明度：完全沿用 Cap_3050_Prov 单图代码
orig_cmap = mpl.colormaps["YlGnBu"]   # YlGn
cmap_colors = orig_cmap(np.linspace(0, 1, 256))
cmap_colors[:, -1] = 0.45
cmap_alpha = mpl.colors.ListedColormap(cmap_colors)

# 饼图技术名称与颜色：与 Cap_Gen_4cases 保持一致
tech_alias = {
    "coal": "Coal",
    "coics": "Coal-iCCS",
    "coal-iccs": "Coal-iCCS",
    "coal_iccs": "Coal-iCCS",
    "coal+ccs": "Coal-iCCS",
    "coal-ccs": "Coal-iCCS",

    "gtcc": "CCGT",
    "ccgt": "CCGT",
    "gtcccs": "CCGT-CCS",
    "ccgt-ccs": "CCGT-CCS",

    "bio": "Biomass",
    "biopower": "Biomass",

    "hydo": "Hydro",
    "hydro": "Hydro",

    "nu": "Nuclear",
    "nuclear": "Nuclear",

    "fwd": "Offshore-wind",
    "offshore-wind": "Offshore-wind",

    "nwd": "Onshore-wind",
    "onshore-wind": "Onshore-wind",

    "pv": "PV",

    "phs": "PHS",
    "psh": "PHS",

    "lib4": "Battery",
    "battery": "Battery",
}

tech_order = [
    "Coal",
    "Coal-iCCS",
    "CCGT",
    "CCGT-CCS",
    "Hydro",
    "Biomass",
    "Nuclear",
    "Offshore-wind",
    "Onshore-wind",
    "PV",
    "PHS",
    "Battery",
]

tech_colors = {
    "Coal": "#000000",
    "Coal-iCCS": "#4a4e69",
    "CCGT": "#5a189a",
    "CCGT-CCS": "#8c6bb1",

    "Hydro": "#1ABC9C",
    "Biomass": "seagreen",
    "Nuclear": "sienna",

    "Offshore-wind": "#1f638e",
    "Onshore-wind": "#3C9FCA",
    "PV": "gold",

    "PHS": "#C73FA3",
    "Battery": "#F08095",
}

# %% [cell 5]
# ============================== 5. 单图绘制函数：先生成四张 2030/2050 原始单图，再拼图 =================================

def read_total_capacity(scenario_path, year):
    df_cs = pd.read_excel(
        scenario_path,
        sheet_name=f"U_EG_acm_tt{str(year)[-2:]}",
        header=None,
        names=["Prov_short", "Value"]
    )

    df_cs["Prov_short"] = df_cs["Prov_short"].astype(str).str.strip()
    df_cs["Value"] = pd.to_numeric(df_cs["Value"], errors="coerce").fillna(0)

    df_total = (
        df_cs
        .merge(prov_contrast[["Prov_name", "Prov_short"]], on="Prov_short", how="left")
        .rename(columns={"Prov_name": "province_en"})
    )

    unmatched = df_total.loc[df_total["province_en"].isna(), "Prov_short"].unique()
    if len(unmatched) > 0:
        print(f"{os.path.basename(scenario_path)} 以下省份简称未在 Prov_contrast.xlsx 中匹配到：", unmatched)

    return df_total


def build_plot_gdf(scenario_path, year):
    df_total = read_total_capacity(scenario_path, year)

    plot_gdf = base_gdf.merge(
        df_total[["province_en", "Value"]],
        on="province_en",
        how="left"
    )

    plot_gdf = gpd.GeoDataFrame(
        plot_gdf,
        geometry="geometry",
        crs=base_gdf.crs
    )

    return plot_gdf


def read_technology_capacity(scenario_path, year):
    df_tech = pd.read_excel(
        scenario_path,
        sheet_name=f"U_EG_acm_Prov{str(year)[-2:]}",
        header=None,
        names=["Technology_raw", "Prov_short", "Value"]
    )

    df_tech["Technology_raw"] = df_tech["Technology_raw"].astype(str).str.strip().str.lower()
    df_tech["Prov_short"] = df_tech["Prov_short"].astype(str).str.strip()
    df_tech["Value"] = pd.to_numeric(df_tech["Value"], errors="coerce").fillna(0)
    df_tech = df_tech[df_tech["Value"] > 0].copy()

    df_tech["Technology"] = df_tech["Technology_raw"].map(tech_alias)
    df_tech["Technology"] = df_tech["Technology"].fillna(df_tech["Technology_raw"])

    df_tech = df_tech.merge(
        prov_contrast[["Prov_short", "Prov_name"]],
        on="Prov_short",
        how="left"
    ).rename(columns={"Prov_name": "province_en"})

    unmatched = df_tech.loc[df_tech["province_en"].isna(), "Prov_short"].unique()
    if len(unmatched) > 0:
        print(f"{os.path.basename(scenario_path)} 以下省份简称未匹配到 province_en：", unmatched)

    df_tech = df_tech[df_tech["province_en"].notna()].copy()
    return df_tech


def collect_global_tech_present(panel_specs):
    """收集 NDC/CN50 在 2030/2050 四张子图中实际出现的全部技术。"""
    all_tech = set()

    for scenario_name, year in panel_specs:
        scenario_path = scenario_files[scenario_name]
        df_tech = pd.read_excel(
            scenario_path,
            sheet_name=f"U_EG_acm_Prov{str(year)[-2:]}",
            header=None,
            names=["Technology_raw", "Prov_short", "Value"]
        )

        # 仅将正装机技术放入总图例，避免零值技术进入图例。
        values = pd.to_numeric(df_tech["Value"], errors="coerce").fillna(0)
        df_tech = df_tech.loc[values > 0].copy()

        tech = (
            df_tech["Technology_raw"]
            .astype(str)
            .str.strip()
            .str.lower()
            .map(tech_alias)
        )

        tech = tech.fillna(
            df_tech["Technology_raw"]
            .astype(str)
            .str.strip()
            .str.lower()
        )

        all_tech.update(set(tech))

    tech_present = [t for t in tech_order if t in all_tech]
    other_techs = sorted(all_tech - set(tech_present))

    for t in other_techs:
        tech_colors[t] = "#999999"

    return tech_present + other_techs


def build_pie_map_gdf(scenario_path, year, plot_gdf, tech_present):
    df_tech = read_technology_capacity(scenario_path, year)

    pie_df = (
        df_tech
        .groupby(["province_en", "Technology"], as_index=False)["Value"]
        .sum()
    )

    pie_wide = (
        pie_df
        .pivot_table(
            index="province_en",
            columns="Technology",
            values="Value",
            aggfunc="sum",
            fill_value=0
        )
        .reset_index()
    )

    for t in tech_present:
        if t not in pie_wide.columns:
            pie_wide[t] = 0.0

    pie_wide["Total_pie"] = pie_wide[tech_present].sum(axis=1)
    pie_wide = pie_wide[pie_wide["Total_pie"] > 0].copy()

    pie_map_gdf = plot_gdf[["province_cn", "province_en", "geometry"]].copy()

    pie_map_gdf = gpd.GeoDataFrame(
        pie_map_gdf,
        geometry="geometry",
        crs=plot_gdf.crs
    )

    pie_map_gdf = pie_map_gdf.merge(
        pie_wide,
        on="province_en",
        how="left"
    )

    pie_map_gdf = pie_map_gdf[
        pie_map_gdf["Total_pie"].notna()
        & (pie_map_gdf["Total_pie"] > 0)
    ].copy()

    return pie_map_gdf


def get_largest_polygon(geom):
    if geom is None or geom.is_empty:
        return None

    if isinstance(geom, MultiPolygon):
        parts = list(geom.geoms)
        if len(parts) == 0:
            return None
        return max(parts, key=lambda p: p.area)

    return geom


def get_pie_center(geom, province_name=None):
    main_geom = get_largest_polygon(geom)

    if main_geom is None or main_geom.is_empty:
        return None

    centroid_point = main_geom.centroid

    if main_geom.contains(centroid_point) or main_geom.touches(centroid_point):
        return centroid_point

    if province_name is not None:
        print(f">>> {province_name} 的 centroid 不在多边形内部，已使用 representative_point()。")

    return main_geom.representative_point()


def calc_scaled_radius(total_value, total_min, total_max, r_min, r_max):
    """
    半径按 sqrt(total) 缩放。
    注意：这里只在当前场景内部缩放，不做四张子图全局缩放。
    """
    if total_max <= total_min:
        return 0.5 * (r_min + r_max)

    t = (
        np.sqrt(total_value) - np.sqrt(total_min)
    ) / (
        np.sqrt(total_max) - np.sqrt(total_min)
    )

    t = np.clip(t, 0, 1)
    return r_min + t * (r_max - r_min)


def draw_pie_on_map(ax, x, y, values, colors_for_pie, radius, start_angle=90):
    total = np.sum(values)
    if total <= 0:
        return

    # 阴影：沿用上一版确定的效果
    shadow_dx = radius * 0.10
    shadow_dy = -radius * 0.10

    shadow = Circle(
        (x + shadow_dx, y + shadow_dy),
        radius=radius * 1.02,
        facecolor="black",
        edgecolor="none",
        alpha=0.18,
        zorder=6,
        clip_on=False
    )
    try:
        shadow.set_in_layout(False)
    except Exception:
        pass
    ax.add_patch(shadow)

    shadow_soft = Circle(
        (x + shadow_dx * 1.15, y + shadow_dy * 1.15),
        radius=radius * 1.08,
        facecolor="black",
        edgecolor="none",
        alpha=0.08,
        zorder=5,
        clip_on=False
    )
    try:
        shadow_soft.set_in_layout(False)
    except Exception:
        pass
    ax.add_patch(shadow_soft)

    angle = start_angle
    for v, color in zip(values, colors_for_pie):
        if v <= 0:
            continue

        frac = v / total
        theta1 = angle
        theta2 = angle - frac * 360

        wedge = Wedge(
            center=(x, y),
            r=radius,
            theta1=theta2,
            theta2=theta1,
            facecolor=color,
            edgecolor="grey",
            linewidth=0.35,
            zorder=8,
            clip_on=False
        )

        wedge.set_path_effects([
            pe.withStroke(linewidth=0.45, foreground="grey")
        ])

        try:
            wedge.set_in_layout(False)
        except Exception:
            pass

        ax.add_patch(wedge)
        angle = theta2

    circle = Circle(
        (x, y),
        radius=radius,
        facecolor="none",
        edgecolor="grey",
        linewidth=0.45,
        zorder=9,
        clip_on=False
    )
    try:
        circle.set_in_layout(False)
    except Exception:
        pass
    ax.add_patch(circle)


def render_one_scenario_to_image(scenario_path, year, tech_present):
    """
    先按单图逻辑生成一张完整地图，再转换为 RGBA 图像数组。
    这样四图拼接时不会改变每张地图内部的比例、位置和南海 inset 关系。
    """
    fig, ax = plt.subplots(figsize=(16, 10), constrained_layout=True, dpi=300)
    FigureCanvas(fig)
    fig.canvas.draw()

    # 3.1 主图：省界背景，沿用单图代码
    prov_2343.plot(
        ax=ax,
        facecolor="lightgrey",
        edgecolor='white',
        linewidth=0.8,
        zorder=1
    )
    ax.set_axis_off()

    # 3.2 九段线 inset：沿用单图相对位置
    axins = fig.add_axes([0.78, 0.06, 0.18, 0.22])

    prov_crop.plot(
        ax=axins,
        facecolor="lightgrey",
        edgecolor='white',
        linewidth=0.8,
        zorder=1
    )

    nine_crop.plot(
        ax=axins,
        color='gray',
        linewidth=1.5,
        linestyle='--',
        zorder=2
    )

    minx, miny, maxx, maxy = bbox_2343.bounds
    axins.set_xlim(minx, maxx)
    axins.set_ylim(miny, maxy)
    axins.set_xticks([])
    axins.set_yticks([])

    rect = Rectangle(
        (0, 0),
        1,
        1,
        transform=axins.transAxes,
        fill=False,
        edgecolor='black',
        linewidth=0.8
    )
    axins.add_patch(rect)
    ax.axis('off')

    # 5. 当前场景底色：颜色和透明度严格沿用单图代码
    plot_gdf = build_plot_gdf(scenario_path, year)

    plot_gdf.plot(
        column="Value",
        cmap=cmap_alpha,
        norm=norm,
        linewidth=0.5,
        edgecolor="white",
        ax=ax,
        zorder=1,
    )

    # 6.0 冻结当前地图布局与显示范围：沿用单图逻辑
    orig_xlim = ax.get_xlim()
    orig_ylim = ax.get_ylim()
    orig_axes_pos = {_ax: _ax.get_position().frozen() for _ax in fig.axes}

    try:
        fig.set_constrained_layout(False)
    except Exception:
        pass

    # 6.4 饼图数据
    pie_map_gdf = build_pie_map_gdf(
        scenario_path=scenario_path,
        year=year,
        plot_gdf=plot_gdf,
        tech_present=tech_present
    )

    # 6.6 饼图大小和位置：位置偏移完全使用 Cap_3050_Prov 单图代码
    x0, x1 = orig_xlim
    y0, y1 = orig_ylim
    map_width = x1 - x0
    map_height = y1 - y0

    # 饼图大小：保留上一版确定的“按当前场景总装机缩放 + 统一 1.1 倍”逻辑；不做四张子图全局缩放。
    scale_pie_by_total = True
    radius_min = map_width * 0.010 * 1.1
    radius_max = map_width * 0.028 * 1.1

    # 关键：这些偏移值直接来自当前 Cap_3050_Prov 单图代码，不再改动。
    # 正 x：向右；负 x：向左；正 y：向上；负 y：向下。
    pie_offsets = {
        "Beijing":           ( 0.010 * map_width,  0.010 * map_height),
        "Tianjin":           ( 0.018 * map_width,  0.002 * map_height),
        "Hebei":             (-0.006 * map_width, -0.006 * map_height),

        "Shanghai":          ( 0.008 * map_width, -0.004 * map_height),
        "Jiangsu":           ( 0.002 * map_width, -0.003 * map_height),

        "W_InnerMongolia":   ( 0.000 * map_width, -0.006 * map_height),
        "E_InnerMongolia":   ( 0.004 * map_width,  0.004 * map_height),
    }

    total_min = pie_map_gdf["Total_pie"].min()
    total_max = pie_map_gdf["Total_pie"].max()

    for _, row in pie_map_gdf.iterrows():
        geom = row.geometry
        if geom is None or geom.is_empty:
            continue

        p = get_pie_center(geom, province_name=row["province_en"])
        if p is None:
            continue

        x, y = p.x, p.y
        dx, dy = pie_offsets.get(row["province_en"], (0, 0))
        x += dx
        y += dy

        values = row[tech_present].astype(float).values
        colors_for_pie = [tech_colors[t] for t in tech_present]

        if scale_pie_by_total and total_max > total_min:
            r = calc_scaled_radius(
                total_value=row["Total_pie"],
                total_min=total_min,
                total_max=total_max,
                r_min=radius_min,
                r_max=radius_max
            )
        else:
            r = 0.5 * (radius_min + radius_max)

        # 边界保护：与当前单图代码一致，避免饼图跑出主图范围。
        pad = r * 1.08
        x = np.clip(x, x0 + pad, x1 - pad)
        y = np.clip(y, y0 + pad, y1 - pad)

        draw_pie_on_map(
            ax=ax,
            x=x,
            y=y,
            values=values,
            colors_for_pie=colors_for_pie,
            radius=r,
            start_angle=90
        )

    ax.set_xlim(orig_xlim)
    ax.set_ylim(orig_ylim)
    ax.set_axis_off()

    for _ax, _pos in orig_axes_pos.items():
        try:
            _ax.set_position(_pos)
        except Exception:
            pass

    # 转为 RGBA 数组，随后关闭单图 figure
    fig.canvas.draw()
    w, h = fig.canvas.get_width_height()
    arr = np.frombuffer(fig.canvas.buffer_rgba(), dtype=np.uint8).reshape(h, w, 4).copy()
    plt.close(fig)

    return arr

# %% [cell 6]
# ============================== 6. 生成 CN50 的 2030/2050 两张单图并进行 1×2 拼接 =================================
# 左：2030 CN50；右：2050 CN50
panel_specs = [
    ("NDC", 2030),
    ("NDC", 2050),
]

tech_present = collect_global_tech_present(panel_specs)
print(">>> 两张子图共同图例包含技术：", tech_present)

panel_order = [f"{scenario}_{year}" for scenario, year in panel_specs]
scenario_images = {}


def crop_rgba_to_content(arr, pad=50, threshold=250):
    """
    裁掉单图渲染结果四周的白色空白，但不改变图中地图、饼图、南海 inset 的相对比例和位置。
    作用只是减少每张子图图片自身右侧/左侧留白，从而压缩两列之间的空白。
    """
    rgb = arr[:, :, :3]
    alpha = arr[:, :, 3]

    # 非白色区域：地图、饼图、南海 inset、阴影、边界线都会被保留。
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


for scenario_name, year in panel_specs:
    panel_key = f"{scenario_name}_{year}"
    print(f">>> 正在渲染 {year} {scenario_name} 单图 ...")
    img = render_one_scenario_to_image(
        scenario_path=scenario_files[scenario_name],
        year=year,
        tech_present=tech_present
    )
    scenario_images[panel_key] = crop_rgba_to_content(
        img, pad=55, threshold=250
    )

# 拼图：只保留 CN50 2030（左）和 CN50 2050（右）。
# 要求：左右位置完全不动，因此仍沿用原 2×2 图第一行左右两图的横向位置与宽度；
# 删除下面一行后，相应缩短整张图高度，并缩短 colorbar 长度。
fig_w_old = 24
fig_h_old = 15.5

# 横向参数完全沿用原 2×2 图
left_margin = 0.004
right_map_limit = 0.900
col_gap = 0.002
row_gap = 0.006
bottom_margin = 0.025
top_map_limit = 0.885

# 先用原 2×2 图的公式计算出“上排单图”的实际宽高
img0 = scenario_images["NDC_2050"]
img_h, img_w = img0.shape[:2]
img_aspect = img_w / img_h

max_cell_w = (right_map_limit - left_margin - col_gap) / 2
max_cell_h = (top_map_limit - bottom_margin - row_gap) / 2

cell_w_old = max_cell_w
cell_h_old = cell_w_old * fig_w_old / (img_aspect * fig_h_old)

if cell_h_old > max_cell_h:
    cell_h_old = max_cell_h
    cell_w_old = cell_h_old * img_aspect * fig_h_old / fig_w_old

left_1 = left_margin
left_2 = left_1 + cell_w_old + col_gap
bottom_2_old = bottom_margin
bottom_1_old = bottom_2_old + cell_h_old + row_gap

# 保留原来上排单图的物理尺寸与横向位置，只裁掉下排。
panel_w_in = cell_w_old * fig_w_old
panel_h_in = cell_h_old * fig_h_old

# 顶部留白保持与原图一致；底部沿用原最下边距
top_margin_in = fig_h_old - (bottom_1_old + cell_h_old) * fig_h_old
bottom_margin_in = bottom_margin * fig_h_old

# 新图高度 = 顶部留白 + 一排地图 + 底部留白
fig_w = fig_w_old
fig_h = top_margin_in + panel_h_in + bottom_margin_in

fig = plt.figure(figsize=(fig_w, fig_h), dpi=300)

# 归一化后的单排位置
panel_w = panel_w_in / fig_w
panel_h = panel_h_in / fig_h
bottom_single = bottom_margin_in / fig_h

cell_positions = {
    "NDC_2030": [left_1, bottom_single, panel_w, panel_h],
    "NDC_2050": [left_2, bottom_single, panel_w, panel_h],
}

panel_order = ["NDC_2030", "NDC_2050"]

for panel_key in panel_order:
    ax_img = fig.add_axes(cell_positions[panel_key])
    ax_img.imshow(scenario_images[panel_key])
    ax_img.set_aspect("equal")
    ax_img.set_axis_off()

# 顶部统一技术图例：位置保持不变
legend_handles = [
    Patch(
        facecolor=tech_colors[t],
        edgecolor="none",
        label=t
    )
    for t in tech_present
]

fig.legend(
    handles=legend_handles,
    loc="upper center",
    bbox_to_anchor=(0.425, 0.945),
    ncol=6,
    frameon=False,
    fontsize=20,
    handlelength=2.2,
    handletextpad=0.65,
    columnspacing=2.2,
    labelspacing=0.9,
)

# 右侧统一 colorbar：x 位置和宽度保持不变，只按单排地图缩短长度
sm = mpl.cm.ScalarMappable(norm=norm, cmap=cmap_alpha)
sm._A = []

cbar_x = 0.77
cbar_w = 0.018
cbar_h_in = panel_h_in * 0.78
cbar_y_in = bottom_margin_in + (panel_h_in - cbar_h_in) / 2 + 0.3

cbar_y = cbar_y_in / fig_h
cbar_h = cbar_h_in / fig_h

cax = fig.add_axes([cbar_x, cbar_y, cbar_w, cbar_h])

cbar = plt.colorbar(
    sm,
    cax=cax,
    orientation="vertical"
)

cbar.ax.patch.set_facecolor("lightgrey")
cbar.outline.set_edgecolor("none")
cbar.ax.tick_params(labelsize=18, direction="in", length=4, width=2)

cbar_tick_step = 100.0 if vmax < 1200 else 200.0
cbar.set_ticks(np.arange(vmin, vmax + 0.5 * cbar_tick_step, cbar_tick_step))
cbar.set_label("Capacity (GW)", fontsize=24, labelpad=12)

# %% [cell 7]
# ============================== 7. 保存图片 =================================
fig.savefig(
    out_file,
    dpi=600,
    bbox_inches="tight",
    pad_inches=0.04
)

print(f"图片已保存到: {out_file}")

from IPython.display import Image, display
display(Image(filename=out_file))

