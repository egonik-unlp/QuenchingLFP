include("master.jl")
using .LFPExperiment, StatsBase, JLD
const hdir = pwd()
path = joinpath(hdir,"val")
if !isdir("val")
	mkdir(path)
end
experiments = build_experiments("out_data/config.toml")

rexp = sample(experiments)
println("Chosen exp = $(rexp.material) $(rexp.treatment)")
A, I, T = rexp.ind, rexp.I, rexp.tau
params_test = [A, I, T]
LFPExperiment.fit(rexp)
rtb = rexp.treatment
params_ref = rexp.fit.param
res = Vector{Any}()
data = Dict()
for multiplier ∈ .1:.1:10
	println("$multiplier => ")
	base_params = params_test * multiplier
	rexp.ind, rexp.I, rexp.tau = base_params
	rexp.treatment = "$(rtb)_val_$multiplier"
	LFPExperiment.fit(rexp)
	LFPExperiment.plot(rexp; dir = path)
	data[multiplier] = rexp.fit.param
end

@save "$path/dataval.jld" data

