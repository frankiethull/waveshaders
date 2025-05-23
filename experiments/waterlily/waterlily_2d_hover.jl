# https://github.com/WaterLily-jl/WaterLily-Examples/blob/main/examples/TwoD_Hover.jl
using WaterLily
using StaticArrays
# using Plots
# using CUDA
using DataFrames
using CSV
using Printf


function hover(L=2^6;Re=250,U=1,amp=π/4,ϵ=0.5,thk=2ϵ+√2)
    # Line segment SDF
    function sdf(x,t)
        y = x .- SA[0,clamp(x[2],-L/2,L/2)]
        √sum(abs2,y)-thk/2
    end
    # Oscillating motion and rotation
    function map(x,t)
        α = amp*cos(t*U/L); R = SA[cos(α) sin(α); -sin(α) cos(α)]
        R * (x - SA[3L-L*sin(t*U/L),4L])
    end
    Simulation((6L,6L),(0,0),L;U,ν=U*L/Re,body=AutoBody(sdf,map),ϵ)#,mem=CuArray)
end


# function run_hover(stop=25.)
#     sim = hover()
#     sim_step!(sim,π)

#     @time @gif for tᵢ in range(0.,stop;step=0.1)
#         println("tU/L=",round(tᵢ,digits=4))
#         sim_step!(sim,tᵢ)
#         @inside sim.flow.σ[I] = WaterLily.curl(3,I,sim.flow.u)*sim.L/sim.U
#         @inside sim.flow.σ[I] = ifelse(abs(sim.flow.σ[I])<0.001,0.0,sim.flow.σ[I])
#         flood(sim.flow.σ|>Array,shift=(-2,-1.5),clims=(-5,5), axis=([], false),
#               cfill=:seismic,legend=false,border=:none,size=(6*sim.L,6*sim.L))
#         body_plot!(sim)
#     end
# end

# run_hover()



function save_flow_as_csv(σ, t, folder)
    df = DataFrame(σ |> Array, :auto)
    filename = joinpath(folder, @sprintf("flow_t%.3f.csv", t))
    CSV.write(filename, df)
end

function run_hover(stop=25.)
    sim = hover()
    sim_step!(sim, π)

    folder = "sim_data"

    for tᵢ in range(0., stop; step=0.1)
        println("tU/L=", round(tᵢ, digits=4))
        sim_step!(sim, tᵢ)
        @inside sim.flow.σ[I] = WaterLily.curl(3,I,sim.flow.u)*sim.L/sim.U
        @inside sim.flow.σ[I] = ifelse(abs(sim.flow.σ[I])<0.001,0.0,sim.flow.σ[I])
        save_flow_as_csv(sim.flow.σ, tᵢ, folder)
    end
end

run_hover()