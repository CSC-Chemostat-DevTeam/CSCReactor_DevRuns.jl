@time begin
    using CSCReactor_jlOs
    using CSCReactor_jlOs: _logfile
    using CairoMakie
    using DataFrames
    using CSV
end

# ---.-.- ...- -- .--- . .- .-. . ..- .--.-
include("0.utils.jl")
include("0.ch.configs.jl")

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
let
    datdir = joinpath(@__DIR__, "CHALK")

    _pwds = 10:10:250
    _ratio = (1, length(_pwds))
    f = Figure(; size = _ratio .* 300)
    for (i, pwd) in enumerate(_pwds)
        ax = Axis(f[i,1]; 
            title = string(pwd), 
            # limits = (nothing, nothing, -1, 20.0),
            xlabel = "conc", ylabel = "led1/led2", 
            aspect = 1.0
        )
        for fn in readdir(datdir; join = true)
            endswith(fn, ".csv") || continue
            global df = CSV.read(fn, DataFrame)
            df = df[df.LASER_PWMS .== pwd, :]
            isempty(df) && continue
            # df.CONC[1] > 0.4 && continue
            scatter!(ax, 
                df.CONC, 
                # log10.(df.LED2_VALS ./ df.LED1_VALS);
                df.LED1_VALS ./ df.LED2_VALS;
                # colormap = :viridis,
                colorrange = 0:255,
                color = pwd/250
            )
        end
    end
    f
end