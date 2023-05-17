#=
julia --project
using Revise; include("test/runtests.jl")
=#
using Test
using ClimaPackageTemplates
using Pkg
import ClimaPackageTemplates as CPT

function make_and_cd(f)
    mktempdir() do dir
        cd(dir) do
            f(dir)
        end
    end
end

@testset "ClimaPackageTemplates" begin
    make_and_cd() do dir
        Pkg.generate("MyPackage")
        cd("MyPackage") do
            CPT.make_package(; pkg_dir=pwd(), pkgname="MyPackage.jl")
        end
    end
end
