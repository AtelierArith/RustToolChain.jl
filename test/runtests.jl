
using Test
using RustToolChains: RustToolChains, cargo, rustc

@testset "RustToolChains" begin
    @test cargo() isa Cmd
    @test rustc() isa Cmd
end

@testset "cargo --version" begin
    @test success(`$(cargo()) --version`)
end

@testset "rustc --version" begin
    @test success(`$(rustc()) --version`)
end

@testset "cargo run with examples/hello" begin
    cd(joinpath(pkgdir(RustToolChains), "examples", "hello")) do
        @test success(`$(cargo()) run`)
    end
end
