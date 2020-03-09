using Documenter, KernelOps

makedocs(
    modules = [KernelOps],
    format = Documenter.HTML(; prettyurls = get(ENV, "CI", nothing) == "true"),
    authors = "Francesco Alemanno",
    sitename = "KernelOps.jl",
    pages = Any["index.md"]
    # strict = true,
    # clean = true,
    # checkdocs = :exports,
)

deploydocs(
    repo = "github.com/francescoalemanno/KernelOps.jl.git",
    push_preview = true
)
