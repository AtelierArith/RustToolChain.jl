using Test
using RustToolChain: RustToolChain

include(joinpath(pkgdir(RustToolChain), "gen", "rust_dist_targets.jl"))

@testset "Rust dist target filtering" begin
    manifest = """
    [pkg.rust.target.aarch64-apple-darwin]
    available = true

    [pkg.rust.target.x86_64-unknown-linux-musl]
    available = true

    [pkg.rust.target.armv7-unknown-linux-musleabihf]
    available = true
    """

    mappings = supported_platform_mappings(manifest)
    triplets = first.(mappings)

    @test "aarch64-apple-darwin" in triplets
    @test "x86_64-unknown-linux-musl" in triplets
    @test "armv7-unknown-linux-musleabihf" ∉ triplets
    @test "arm-unknown-linux-musleabihf" ∉ triplets
end
