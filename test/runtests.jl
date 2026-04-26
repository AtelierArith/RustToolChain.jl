
using Test
using RustToolChain: RustToolChain, cargo, rustc

include("generator_platforms.jl")

@testset "RustToolChain" begin
    @test cargo() isa Cmd
    @test rustc() isa Cmd
end

@testset "unpacked dist installer" begin
    mktempdir() do dir
        rust_dir = joinpath(dir, "rust-test")
        cargo_exe = "cargo" * RustToolChain.EXE_EXT
        rustc_exe = "rustc" * RustToolChain.EXE_EXT

        mkpath(joinpath(rust_dir, "cargo", "bin"))
        mkpath(joinpath(rust_dir, "rustc", "bin"))
        write(joinpath(rust_dir, "components"), "cargo\nrustc\n")
        write(joinpath(rust_dir, "cargo", "bin", cargo_exe), "")
        write(joinpath(rust_dir, "rustc", "bin", rustc_exe), "")

        prefix = joinpath(rust_dir, "prefix")
        RustToolChain._install_from_unpacked_dist!(rust_dir, prefix)

        @test isfile(joinpath(prefix, "bin", cargo_exe))
        @test isfile(joinpath(prefix, "bin", rustc_exe))
    end
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
            src = """
            fn main() {
                println!("Hello, world!");
            }
            """
            # Choose the executable filename depending on OS
            exe = Sys.iswindows() ? "hello.exe" : "hello"

            # Write the rust source file
            open("hello.rs", "w") do f
                write(f, src)
            end

            # Compile the rust source file
            run(`$(rustc()) hello.rs -o $exe`)

            # Run the produced executable
            if Sys.iswindows()
                # On Windows, use `Cmd` directly to launch
                run(`$exe`)
                @test success(`$exe`)
            else
                run(`./$exe`)
                @test success(`./$exe`)
            end
        end
    end
end

@testset "cargo run with examples/hello" begin
    cd(joinpath(pkgdir(RustToolChain), "examples", "hello")) do
        @test success(`$(cargo()) run`)
    end
end
