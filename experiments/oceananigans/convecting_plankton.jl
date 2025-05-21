# https://clima.github.io/OceananigansDocumentation/stable/literated/convecting_plankton/

using Oceananigans
using Oceananigans.Units: minutes, hour, hours, day

### The Grid

grid = RectilinearGrid(size=(64, 64), extent=(64, 64), halo=(3, 3), topology=(Periodic, Flat, Bounded))

### Boundary Conditions

buoyancy_flux(x, t, params) = params.initial_buoyancy_flux * exp(-t^4 / (24 * params.shut_off_time^4))

buoyancy_flux_parameters = (initial_buoyancy_flux = 1e-8, # m² s⁻³
                                    shut_off_time = 2hours)

buoyancy_flux_bc = FluxBoundaryCondition(buoyancy_flux, parameters = buoyancy_flux_parameters)

#### visualize flux
# using CairoMakie
# set_theme!(Theme(fontsize = 24, linewidth=2))

# times = range(0, 12hours, length=100)

# fig = Figure(size = (800, 300))
# ax = Axis(fig[1, 1]; xlabel = "Time (hours)", ylabel = "Surface buoyancy flux (m² s⁻³)")

# flux_time_series = [buoyancy_flux(0, t, buoyancy_flux_parameters) for t in times]
# lines!(ax, times ./ hour, flux_time_series)

# fig

#### initial condition

N² = 1e-4 # s⁻²

buoyancy_gradient_bc = GradientBoundaryCondition(N²)

buoyancy_bcs = FieldBoundaryConditions(top = buoyancy_flux_bc, bottom = buoyancy_gradient_bc)


### Phytoplankton dynamics: light-dependent growth and uniform mortality


growing_and_grazing(x, z, t, P, params) = (params.μ₀ * exp(z / params.λ) - params.m) * P

plankton_dynamics_parameters = (μ₀ = 1/day,   # surface growth rate
                                 λ = 5,       # sunlight attenuation length scale (m)
                                 m = 0.1/day) # mortality rate due to virus and zooplankton grazing

plankton_dynamics = Forcing(growing_and_grazing, field_dependencies = :P,
                            parameters = plankton_dynamics_parameters)

### The Model 

model = NonhydrostaticModel(; grid,
                            advection = UpwindBiased(order=5),
                            closure = ScalarDiffusivity(ν=1e-4, κ=1e-4),
                            coriolis = FPlane(f=1e-4),
                            tracers = (:b, :P), # P for Plankton
                            buoyancy = BuoyancyTracer(),
                            forcing = (; P=plankton_dynamics),
                            boundary_conditions = (; b=buoyancy_bcs))

### Initial Condition
mixed_layer_depth = 32 # m

stratification(z) = z < -mixed_layer_depth ? N² * z : - N² * mixed_layer_depth
noise(z) = 1e-4 * N² * grid.Lz * randn() * exp(z / 4)
initial_buoyancy(x, z) = stratification(z) + noise(z)

set!(model, b=initial_buoyancy, P=1)

### Simulation with adaptive time-stepping, logging, and output

simulation = Simulation(model, Δt=2minutes, stop_time=24hours)

conjure_time_step_wizard!(simulation, cfl=1.0, max_Δt=2minutes)

using Printf

progress(sim) = @printf("Iteration: %d, time: %s, Δt: %s\n",
                        iteration(sim), prettytime(sim), prettytime(sim.Δt))

add_callback!(simulation, progress, IterationInterval(100))


outputs = (w = model.velocities.w,
           P = model.tracers.P,
           avg_P = Average(model.tracers.P, dims=(1, 2)))

simulation.output_writers[:simple_output] =
    JLD2Writer(model, outputs,
               schedule = TimeInterval(20minutes),
               filename = "convecting_plankton.jld2",
               overwrite_existing = true)



run!(simulation)

# post sim parameter mining ----------------------
filepath = simulation.output_writers[:simple_output].filepath

w_timeseries = FieldTimeSeries(filepath, "w")
P_timeseries = FieldTimeSeries(filepath, "P")
avg_P_timeseries = FieldTimeSeries(filepath, "avg_P")

times = w_timeseries.times

# collect simulations for R ----------------------


using DataFrames
using CSV 
using CairoMakie

for i in 1:length(times)

p_m = @lift interior(P_timeseries[$i], :, 1, :)
 p_df = DataFrame(p_m, :auto)

 filenm = string("sim_steps/plankton_", i, "_.csv")
  CSV.write(filenm, p_df)
end
