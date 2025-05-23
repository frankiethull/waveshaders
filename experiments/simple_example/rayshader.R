library(dplyr)
library(tidyr)
library(ggplot2)
library(rayshader)

# ggplot2 workflow ----------------------------------------------------------------

# julia output
laplace_df <- arrow::read_ipc_file("laplacian.arrow")

# matrix to a long df to test ggplot2 and plot_gg:
laplace_long_df <- laplace_df |>
                   mutate(
                     x_id = row_number()
                   ) |>
                    tidyr::pivot_longer(-x_id, names_to = "y_id", values_to = "z") |>
                    mutate(
                      y_id = gsub("x", "", y_id),
                      y_id = as.numeric(y_id)
                    )

# ggplot hex display:
gg <- 
laplace_long_df |>
    ggplot(aes(x = x_id, y = y_id, z = z)) +
  stat_summary_hex(fun = function(x) mean(x), bins = 45)  +
  scale_fill_viridis_c(option = 12) + 
  theme_void() +
  theme(legend.position = "none") #+ 
#  labs(subtitle = "hexagonal 2-d heatmap of laplacian matrix")


# saving the ggplot as png or as an object to load back into R 
saveRDS(gg, "gg.rds") # rds or qs idea
# or
ggsave("gg.png", gg)

# rayshader workflow --------------------------------------------------------------------

# ---------------------- METHOD 1 -----------------------
# @@@ 1) render via a ggplot2 saved as RDS @@@ ----

gg <- readRDS("gg.rds")

plot_gg(gg, height=5, width=4.5, 
  phi   = 25, 
  zoom  = 0.4, 
  theta = -140, 
  background = "salmon")

  # save 3d image snapshot via rds looks good 
render_snapshot(filename = "rayshader_v_rds.png")

# ---------------------- METHOD 2 -----------------------
# @@@ 2) render via extracting a height map from png @@@ -----
# this is probably not recommended but works as a 
# blend between the base rayshader methods and ggplot2

gg_png <- png::readPNG("gg.png")
gg_png_magick <- magick::image_read("gg.png")

gg_data <- 
  # a few ways to do this bit
gg_png_magick |>
  magick::image_quantize(colorspace = "gray") |>
  magick::image_transparent("white", fuzz = 20) |>
  magick::image_data() |>
  as.integer() |>
  as.data.frame() |>
  as.matrix() |>
  matrix(data = _, nrow = 999, ncol = 999)

plot_3d(gg_png, gg_data, zscale = 3, background = "salmon")
render_camera(theta=-140,  phi=25, zoom=0.4)

# rendered snapshot is suboptimal
render_snapshot(filename = "rayshader_v_png.png") 

# ---------------------- METHOD 3 -----------------------
# @@@ 3) render via original data + ggplot png @@@ ------
# pass julia sim directly to rayshader as height map,
# add the ggplot2 image as a visual layer 

elevation <- laplace_df |> as.matrix()
elevation <- matrix(elevation, nrow = 150, ncol = 150)
# elevation |> image()

plot_3d(gg_png, elevation, zscale = 3, background = "salmon")
render_camera(theta=-140,  phi=25, zoom=0.4)
render_snapshot(filename = "rayshader_v_data_and_png.png") 
