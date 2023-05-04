cd("/home/gonik/Documents/git/egonik-unlp/QuenchingLFP/out_data/MOF 2/O2/")
using DataFrames, CSV, LsqFit, Plots, StatsPlots, Unitful


model(t,p) = p[1] .+ p[2] * exp.(-t*p[3])
filename = "MOF 3 O2 300 700 nm 10 us Delta OD._1.csv"
data = CSV.File(filename) |> DataFrame
df = data[!,["t","460"]]
rename!(df, [:t, :ΔOD])
cutoff = Int(size(df)[1]*.1 ) + 35
dfc = df[cutoff:end, :]

@df dfc plot(:t, :ΔOD)

termino_independiente = 0
int_tiempo_0 = .0035
tau = 1500

parametros_iniciales = [termino_independiente, int_tiempo_0, 1/tau]

fit = curve_fit(model, dfc.t, dfc.ΔOD, parametros_iniciales)


# Plots.plot(dfc.t, fit.resid)

pred = model(dfc.t, fit.param)
resid = fit.resid
resultado = DataFrame(hcat(dfc.t, dfc.ΔOD, pred, resid), [:t,:y, :yhat, :residuales])

@df resultado plot(:t, :y, label = "y", alpha =.6 )
@df resultado plot!(:t, :yhat, label = "yhat" )
@df resultado plot!(:t, :residuales, label = "residuales", alpha = .24)

tau =( 1/fit.param[3])u"ns"


println("τ archivo $filename = $(uconvert(u"μs", tau))")
