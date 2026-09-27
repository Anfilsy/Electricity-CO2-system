# =========================================================
# Provincial annual power flow chord diagram
# Input : PFlow_CN50.xlsx
# Sheet : P_ELi_tt
# Output: Annual_Power_Flow_2050.png
# =========================================================

library(openxlsx)
library(circlize)
library(viridis)

# =========================================================
# 0. 用户参数
# =========================================================

file_path <- "PFlow_CN50.xlsx"
sheet_name <- "P_Flow_tt"
out_png <- "Annual_Power_Flow_2050.png"

# ---------------------------------------------------------
# 过滤参数
# ---------------------------------------------------------
# 单条省际传输量小于该值的 link 不画
# 如果图仍然太乱，可改为 30、40、50
min_link_flow <- 20

# 是否过滤总传输量很小的省份
filter_small_sector <- TRUE

# 省份总流量阈值：流出 + 流入
# 如果标签仍然重叠，可改为 60、80、100
min_sector_total <- 40

# ---------------------------------------------------------
# 内圈数字刻度字号
# ---------------------------------------------------------
# 只控制弦图数字刻度，不改变省份缩写字号。
# 可尝试 0.75、0.85、1.00、1.20。
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
viridis_colors <- viridis(length(zx))
grid_colors <- setNames(viridis_colors, zx)

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
# 第3列：传输电量 value
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
# 3. 过滤极小单条传输量
# =========================================================

raw <- raw[raw$value >= min_link_flow, ]

cat("过滤后剩余 link 数量：", nrow(raw), "\n")

if (nrow(raw) == 0) {
  stop("过滤后没有剩余 link。请降低 min_link_flow。")
}

# =========================================================
# 4. 构建省份传输矩阵
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
# 5. 过滤总流量很小的省份
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
  stop("矩阵转换后没有非零传输量。请降低过滤阈值。")
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

tiny_thr <- min_sector_total * 1.5
large_thr <- quantile(raw_w, probs = 0.70, na.rm = TRUE)

groupTiny <- regions[raw_w < tiny_thr]
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

chordDiagram(
  x = df_long,
  order = region_order,
  grid.col = grid_col_final,
  directional = 1,
  direction.type = c("diffHeight", "arrows"),
  link.arr.type = "big.arrow",
  annotationTrack = c("name", "grid")
)

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