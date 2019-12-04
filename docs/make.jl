include("../src/BIDSTools.jl")

using .BIDSTools
using Documenter, Example

makedocs(
    repo = "https://gitlab.com/triimaging/BIDSTools.jl/blob/{commit}{path}#{line}",
    sitename="BIDSTools.jl",
    modules = [BIDSTools],
    authors = "Darren Lukas, Chris Foster",
    pages = Any[
        "Home" => "index.md",
        "Module" => "module.md"
    ],
    format = Documenter.HTML(prettyurls = false),
    clean = false,
    doctest = true
)

deploydocs(
    repo = "github.com/TRIImaging/BIDSTools.jl.git",
    target = "build",
    push_preview = true
)
