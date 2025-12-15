
using Test
using RustToolChains: RustToolChains, cargo

@testset "RustToolChains" begin
    @test cargo() isa Cmd
end

@testset "cargo --version" begin
    @test success(`$(cargo()) --version`)
end

@testset "cargo run with examples/hello" begin
    cd(joinpath(pkgdir(RustToolChains), "examples", "hello")) do
        @test success(`$(cargo()) run`)
    end
end
