library(dplyr)
library(tidyr)
library(ggplot2)
library(rayshader)


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
  theme(legend.position = "none")

gg + labs(subtitle = "hexagonal 2-d heatmap of laplacian matrix")


plot_gg(gg, height=5, width=4.5, 
  phi   = 25, 
  zoom  = 0.4, 
  theta = -140, 
  background = "salmon")

render_snapshot(filename = "rayshader_v1.png")

magick::image_read("rayshader_v1.png") |> 
  plot()
