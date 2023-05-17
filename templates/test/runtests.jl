using Test
using ClimaPackageTemplateName
using Aqua

@testset "ClimaPackageTemplateName" begin
    @test 1 == 1
end

@testset "Aqua" begin
    @test Aqua.test_all(ClimaPackageTemplateName)
end
