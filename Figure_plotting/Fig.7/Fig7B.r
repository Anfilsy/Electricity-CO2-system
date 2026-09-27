# =========================================================
# Provincial C-flow chord diagram
# Input : CFlow_CN50.xlsx
# Sheet : C_Flow_tt
# Output: Annual_C_Flow_2050.png
# =========================================================

library(openxlsx)
library(circlize)
library(viridis)

# =========================================================
# 0. 用户参数
# =========================================================

file_path <- "Stage_3_CFlow.xlsx"
sheet_name <- "CFlow_50"
out_png <- "Annual_C_Flow_2050.png"

# ---------------------------------------------------------
# 本图数据量较少，先不做过滤
# ---------------------------------------------------------
min_link_flow <- 0
filter_small_sector <- FALSE
min_sector_total <- 0

axis_number_cex <- 0.55

# ---------------------------------------------------------
# 省份顺序
# ---------------------------------------------------------
zx <- c(
  "BJ", "TJ", "HE", "SX", "MD",
  "LN", "JL", "HL",
  "SH", "JS", "ZJ", "AH", "FJ", "JX", "SD",
  "HA", "HB", "HN",
  "GD", "GX", "HI",
  "CQ", "SC", "GZ", "YN", "XZ",
  "SN", "GS", "QH", "NX", "XJ",
  "MX"
)

# ---------------------------------------------------------
# 颜色
# ---------------------------------------------------------
yg_colors <- colorRampPalette(c(
  "#F6E945",  # 明亮黄色
  "#8BD646",  # 鲜绿
  "#287D8E",  # 蓝绿
  "#4B176D"   # 少量深紫，用于少数扇区对比
))(length(zx))

grid_colors <- setNames(yg_colors, zx)

grid_colors <- setNames(yg_colors, zx)

# =========================================================
# 1. 检查文件和 sheet
# =========================================================

if (!file.exists(file_path)) {
  stop(paste0("找不到输入文件：", file_path))
}

sheets <- openxlsx::getSheetNames(file_path)

if (!(sheet_name %in% sheets)) {
  stop(paste0(
    "找不到工作表：", sheet_name,
    "\n当前 Excel 中的工作表包括：",
    paste(sheets, collapse = ", ")
  ))
}

# =========================================================
# 2. 读取数据
# 表格结构要求：
# 第1列：送端省份 from
# 第2列：受端省份 to
# 第3列：流量 value
# =========================================================

raw <- openxlsx::read.xlsx(
  xlsxFile = file_path,
  sheet = sheet_name,
  colNames = FALSE
)

raw <- raw[, 1:3]
colnames(raw) <- c("from", "to", "value")

raw$from <- trimws(as.character(raw$from))
raw$to <- trimws(as.character(raw$to))
raw$value <- suppressWarnings(as.numeric(raw$value))

# 删除空行、非数值行、零值行
raw <- raw[
  !is.na(raw$from) &
    !is.na(raw$to) &
    !is.na(raw$value) &
    raw$from != "" &
    raw$to != "" &
    raw$value != 0,
]

# 如果存在负值，自动反转方向
neg_idx <- raw$value < 0

if (any(neg_idx)) {
  tmp_from <- raw$from[neg_idx]
  raw$from[neg_idx] <- raw$to[neg_idx]
  raw$to[neg_idx] <- tmp_from
  raw$value[neg_idx] <- abs(raw$value[neg_idx])
}

# =========================================================
# 3. 不过滤 link，仅保留所有非零流量
# =========================================================

raw <- raw[raw$value >= min_link_flow, ]

cat("当前 link 数量：", nrow(raw), "\n")

if (nrow(raw) == 0) {
  stop("没有可绘制的 link。请检查数据。")
}

# =========================================================
# 4. 构建省份流量矩阵
# =========================================================

regions_all <- zx[zx %in% union(raw$from, raw$to)]

if (length(regions_all) == 0) {
  stop("没有识别到 zx 中定义的省份缩写。请检查 Excel 中省份名称是否与 zx 一致。")
}

mat <- matrix(
  0,
  nrow = length(regions_all),
  ncol = length(regions_all),
  dimnames = list(regions_all, regions_all)
)

for (i in seq_len(nrow(raw))) {
  f <- raw$from[i]
  t <- raw$to[i]
  v <- raw$value[i]
  
  if (f %in% regions_all && t %in% regions_all) {
    mat[f, t] <- mat[f, t] + v
  }
}

# =========================================================
# 5. 不过滤小省份
# =========================================================

if (filter_small_sector) {
  
  sector_total <- rowSums(mat, na.rm = TRUE) + colSums(mat, na.rm = TRUE)
  keep_sector <- names(sector_total[sector_total >= min_sector_total])
  
  if (length(keep_sector) == 0) {
    stop("过滤后没有剩余省份。请降低 min_sector_total。")
  }
  
  mat <- mat[keep_sector, keep_sector, drop = FALSE]
  
  cat("过滤后剩余省份数量：", length(keep_sector), "\n")
}

# =========================================================
# 6. 转换为 chordDiagram 使用的长表
# =========================================================

df_long <- as.data.frame(as.table(mat))
colnames(df_long) <- c("from", "to", "value")

df_long$from <- as.character(df_long$from)
df_long$to <- as.character(df_long$to)
df_long$value <- as.numeric(df_long$value)

df_long <- df_long[df_long$value != 0, ]

if (nrow(df_long) == 0) {
  stop("矩阵转换后没有非零流量。请检查数据。")
}

# =========================================================
# 7. 计算各省份总流量，用于重排顺序
# =========================================================

regions <- zx[zx %in% union(df_long$from, df_long$to)]

raw_w <- setNames(numeric(length(regions)), regions)

for (r in regions) {
  if (r %in% rownames(mat)) {
    raw_w[r] <- raw_w[r] + sum(mat[r, ], na.rm = TRUE)
  }
  
  if (r %in% colnames(mat)) {
    raw_w[r] <- raw_w[r] + sum(mat[, r], na.rm = TRUE)
  }
}

cat("---- 各省份流入 + 流出总量 ----\n")
print(round(raw_w, 2))

# =========================================================
# 8. 重排省份顺序
# 目的：把小扇区穿插在较大扇区之间，减少标签扎堆
# =========================================================

tiny_thr <- quantile(raw_w, probs = 0.30, na.rm = TRUE)
large_thr <- quantile(raw_w, probs = 0.70, na.rm = TRUE)

groupTiny <- regions[raw_w <= tiny_thr]
groupLarge <- regions[raw_w >= large_thr]
groupMid <- setdiff(regions, c(groupTiny, groupLarge))

tiny_q <- groupTiny

region_order <- character(0)

for (sec in regions) {
  
  if (sec %in% groupTiny) {
    next
  }
  
  region_order <- c(region_order, sec)
  
  if (sec %in% c(groupLarge, groupMid) && length(tiny_q) > 0) {
    region_order <- c(region_order, tiny_q[1])
    tiny_q <- tiny_q[-1]
  }
}

if (length(tiny_q) > 0) {
  region_order <- c(region_order, tiny_q)
}

region_order <- unique(region_order)
region_order <- region_order[region_order %in% regions]

grid_col_final <- grid_colors[region_order]

cat("最终省份顺序：", paste(region_order, collapse = ", "), "\n")

# =========================================================
# 9. 输出 PNG
# 不输出 PDF，不加标题
# =========================================================

png(
  filename = out_png,
  width = 2500,
  height = 2500,
  res = 900,
  bg = "white"
)

par(
  cex = 0.55,
  lwd = 0.8
)

par(
  oma = c(0.5, 0.5, 0.5, 0.5),
  mar = c(0.1, 0.1, 0.1, 0.1)
)

circos.clear()

# 保留默认省份缩写和扇区色带，但关闭默认数字轴。
# 随后仅重新绘制数字刻度，因此省份缩写字号仍由 par(cex = 0.55) 控制。
chordDiagram(
  x = df_long,
  order = region_order,
  grid.col = grid_col_final,
  directional = 1,
  direction.type = c("diffHeight", "arrows"),
  link.arr.type = "big.arrow",
  annotationTrack = c("name", "grid")
)

# chordDiagram 完成后，最内侧的注释轨道是 grid track。
# 在该轨道上逐个扇区重新绘制数字轴，只调整数字标签字号。
grid_track_index <- max(get.all.track.index())

for (sec in get.all.sector.index()) {
  circos.axis(
    h = "top",
    sector.index = sec,
    track.index = grid_track_index,
    labels.cex = axis_number_cex
  )
}

dev.off()

circos.clear()

cat("PNG 已输出：", out_png, "\n")