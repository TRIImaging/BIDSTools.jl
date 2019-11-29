using BIDSTools
using Test
using DataStructures
using DataFrames

@testset "BIDSTools.jl" begin

    include("File.jl")
    include("Session.jl")
    include("Subject.jl")
    include("Layout.jl")

end
