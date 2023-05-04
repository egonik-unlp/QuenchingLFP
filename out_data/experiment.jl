using DataFrames
const homedir = pwd()
	include("master.jl")
	using .LFPExperiment
	# export run()
	function run()
		experiments = build_experiments("out_data/config.toml")
		fit.(experiments)
		plot.(experiments; dir = homedir )
		tabla_resumen = Vector{NamedTuple}()
		for experiment ∈ experiments
			_, I, tau = experiment.fit.param
			material = experiment.material
			treatment = experiment.treatment
			exp_d = (material = material, treatment = treatment,  I = I, tau_en_mus= tau * 1e5)
			push!(tabla_resumen, exp_d)
		end
		DataFrame(tabla_resumen)
	end
datos = run()