### get julia sims ------------------------------------------

files <- list.files(path = "sim_data", full.names = TRUE)


file_sorting <- list.files(path = "sim_data") |> 
                  gsub(".csv", "", x = _) |> 
                  gsub("flow_t", "", x = _)

files_df <- data.frame(
  files = files,
  index = file_sorting
) |>
  dplyr::mutate(index = as.numeric(index)) |> dplyr::arrange(index)

flows <- lapply(files_df$files, read.csv)

# testing: 
# flows[[200]] |>
# as.matrix() |>
# image()

### shading --------------------------------
library(rayshader)
library(ggplot2)
library(dplyr)

max_tstep <- length(flows)

for (t in 1:max_tstep){
  
gg <- 
flows[[t]] |>
  mutate(
    x_id = row_number()
  ) |>
  tidyr::pivot_longer(-x_id, names_to = "y_id") |>
  mutate(
    x_id = as.numeric(x_id),
    y_id = as.numeric(gsub("x", "", y_id)),
    value = value * 10000
  ) |>
  filter(y_id > 35) |> # removing static area
  ggplot(aes(x = x_id, y = y_id, z = value)) +
  stat_summary_hex(fun = function(x) mean(x), bins = 50) + #26
  scale_fill_viridis_c(option = 15) + 
  theme_void() +
  theme(legend.position = "none")

phi_adj   <-  rnorm(n = 1, sd = 0.25) + t
theta_adj <-  rnorm(n = 1, sd = 0.25) + t
zoom_adj  <- - 0.001*t

plot_gg(gg, height=5, width=4.5, 
        phi   = 45  + phi_adj, 
        zoom  = 0.8 + zoom_adj, 
        theta = -60 + theta_adj, 
        background = "darkslategray")

render_snapshot(filename = paste0("render_data/", t, "_render.png"))

}

# create a video -----------------------------------------------------

render_files <- list.files("render_data", full.names = TRUE)


render_sorting <- list.files(path = "render_data") |> 
                  gsub(".png", "", x = _) |> 
                  gsub("_render", "", x = _)

render_df <- data.frame(
  files = render_files,
  index = render_sorting
) |>
  mutate(index = as.numeric(index)) |> arrange(index)


av::av_encode_video(render_df$files, 'output.mp4', framerate = 9)
utils::browseURL('output.mp4')
