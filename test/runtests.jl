
using Test
using RustToolChain: RustToolChain, cargo, rustc

@testset "RustToolChain" begin
    @test cargo() isa Cmd
    @test rustc() isa Cmd
end

@testset "cargo --version" begin
    @test success(`$(cargo()) --version`)
end

@testset "rustc --version" begin
    @test success(`$(rustc()) --version`)
end

@testset "rustc hello.rs" begin
    mktempdir() do dir
        cd(dir) do
            run(pipeline(`sh -lc "echo 'fn main(){println!(\"Hello, world!\");}' | $(rustc()) -o hello - && ./hello"`))
            @test success(`./hello`)
        end
    end
end

@testset "cargo run with examples/hello" begin
    cd(joinpath(pkgdir(RustToolChain), "examples", "hello")) do
        @test success(`$(cargo()) run`)
    end
end
