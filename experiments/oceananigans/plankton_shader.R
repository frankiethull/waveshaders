### get julia sims ------------------------------------------

files <- list.files(path = "sim_steps", full.names = TRUE)

file_sorting <- list.files(path = "sim_steps") |> 
                  gsub("_.csv", "", x = _) |> 
                  gsub("plankton_", "", x = _)

files_df <- data.frame(
  files = files,
  index = file_sorting
) |>
  dplyr::mutate(index = as.numeric(index)) |> dplyr::arrange(index)

fields <- lapply(files_df$files, read.csv)

# testing: 
# fields[[10]] |>
#  as.matrix() |>
#  image()

### shading --------------------------------
library(rayshader)
library(ggplot2)
library(dplyr)

max_tstep <- length(fields)

for (t in 1:max_tstep){
  
gg <- 
fields[[t]] |>
  mutate(
    x_id = row_number()
  ) |>
  tidyr::pivot_longer(-x_id, names_to = "y_id") |>
  mutate(
    x_id = as.numeric(x_id),
    y_id = as.numeric(gsub("x", "", y_id)),
    value = value **3
  ) |>
  filter(y_id > 35) |> # removing static area
  ggplot(aes(x = x_id, y = y_id, z = value)) +
  stat_summary_hex(fun = function(x) mean(x), bins = 24) + #26
  scale_fill_viridis_c(option = 13) + 
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

render_snapshot(filename = paste0("render_steps/", t, "_render.png"))

}

# create a video -----------------------------------------------------

render_files <- list.files("render_steps", full.names = TRUE)


render_sorting <- list.files(path = "render_steps") |> 
                  gsub(".png", "", x = _) |> 
                  gsub("_render", "", x = _)

render_df <- data.frame(
  files = render_files,
  index = render_sorting
) |>
  mutate(index = as.numeric(index)) |> arrange(index)


av::av_encode_video(render_df$files, 'output.mp4', framerate = 9)
utils::browseURL('output.mp4')
