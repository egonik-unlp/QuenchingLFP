
module LFPExperiment
using Parameters, TOML, LsqFit, CSV, DataFrames, Plots, StatsPlots, Unitful

export fit, plot, build_experiments

@with_kw mutable struct ExperimentData
        material::Union{Nothing,String} = nothing
        treatment::Union{Nothing,String} = nothing
        foldername::Union{Nothing,String} = nothing
        filename::Union{Nothing,String} = nothing
        correccion::Union{Nothing,Int64} = nothing
        ind::Union{Nothing,Number} = nothing
        I::Union{Nothing,Float64} = nothing
        tau::Union{Nothing,Number} = nothing
        table::Union{Nothing,DataFrame} = nothing
        fit::Union{Nothing,LsqFit.LsqFitResult} = nothing
end

const model(t, p) = p[1] .+ p[2] * exp.(-t * p[3])

function ExperimentData(d::Dict{String,Any})
        e = ExperimentData()
        for fieldname ∈ Symbol.(keys(d))
                setfield!(e, fieldname, d[string(fieldname)])
        end
        e
end

function build_experiments(toml_filepath::String)
        experiments = Vector{ExperimentData}()
        experiments_data = TOML.parsefile(toml_filepath)
        exp_dict = Dict()
        for (mof, experiment_set) ∈ pairs(experiments_data)
                exp_dict["material"] = mof
                for (treatment_name, treatment_data) ∈ pairs(experiment_set)
                        exp_dict["treatment"] = treatment_name
                        merge!(treatment_data, exp_dict)
                        println(treatment_data)
                        exp = ExperimentData(treatment_data)
                        push!(experiments, exp)
                end
        end
        experiments
end


function fit(exp::ExperimentData)
        cd(exp.foldername)
        data = CSV.File(exp.filename) |> DataFrame
        df = data[!, ["t", "460"]]
        rename!(df, [:t, :ΔOD])
        cutoff = Int(size(df)[1] * 0.1) + 20
        exp.table = df[cutoff:end, :]

        termino_independiente = exp.ind
        int_tiempo_0 = exp.I
        tau = exp.tau
        parametros_iniciales = [termino_independiente, int_tiempo_0, 1 / tau]

        exp.fit = curve_fit(model, exp.table.t, exp.table.ΔOD, parametros_iniciales)
        exp.ind, exp.I, exp.tau = exp.fit.param
        tau = tau * u"ns"

        println("τ archivo $(exp.filename) = $(uconvert(u"μs", tau))")

        # dfc, fit
end
function plot(exp::ExperimentData; dir = ".")
	p = Plots.plot()

        pred = model(exp.table.t, exp.fit.param)
        resid = exp.fit.resid
        resultado = DataFrame(hcat(exp.table.t, exp.table.ΔOD, pred, resid), [:t, :y, :yhat, :residuales])

        @df resultado plot!(:t, :y, label="y", alpha=0.6)
        @df resultado plot!(:t, :yhat, label="yhat")
        @df resultado plot!(:t, :residuales, label="residuales", alpha=0.24)
        filename = "plot_$(exp.material)_$(exp.treatment).png"
	filepath = joinpath(dir, filename)
	savefig(p,filepath)
        p
end
end
	




