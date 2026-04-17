using ArtifactUtils
using Pkg.Artifacts

include(joinpath(@__DIR__, "rust_dist_targets.jl"))

const RUST_VERSION = if length(ARGS) > 0
    strip(ARGS[1])
else
    error("Usage: julia generate_Artifacts_toml.jl <RUST_VERSION>\nExample: julia generate_Artifacts_toml.jl 1.92.0")
end
const ARTIFACTS_TOML = joinpath(dirname(@__DIR__), "Artifacts.toml")
const ARTIFACT_NAME = "RustToolChain"

# バージョン形式の検証
if !validate_version(RUST_VERSION)
    error("Invalid Rust version format: '$RUST_VERSION'. Expected format: X.Y.Z (e.g., 1.92.0)")
end

@info "Generating Artifacts.toml for Rust $RUST_VERSION"

const SUPPORTED_PLATFORM_MAPPINGS = supported_platform_mappings_for_version(RUST_VERSION)

if isempty(SUPPORTED_PLATFORM_MAPPINGS)
    error("No supported Rust installer targets found for Rust $RUST_VERSION")
end

const SKIPPED_PLATFORM_TRIPLETS = [
    triplet for (triplet, _) in PLATFORM_MAPPINGS
    if triplet ∉ Set(first.(SUPPORTED_PLATFORM_MAPPINGS))
]

if !isempty(SKIPPED_PLATFORM_TRIPLETS)
    @warn "Skipping targets missing from Rust distribution manifest" version=RUST_VERSION triplets=SKIPPED_PLATFORM_TRIPLETS
end

function add_rust_toolchain_for_platform(triplet::String, platform)
    url = "https://static.rust-lang.org/dist/rust-$(RUST_VERSION)-$(triplet).tar.gz"

    @info "Adding Rust toolchain for $triplet" platform url

    add_artifact!(
        ARTIFACTS_TOML,
        ARTIFACT_NAME,
        url;
        platform=platform,
        lazy=true,
        force=true,
        clear=true,
    )
end

# すべてのプラットフォームを追加
for (triplet, platform) in SUPPORTED_PLATFORM_MAPPINGS
    try
        add_rust_toolchain_for_platform(triplet, platform)
    catch e
        @warn "Failed to add platform $triplet" exception=(e, catch_backtrace())
    end
end

@info "Finished adding Rust toolchains to $ARTIFACTS_TOML"
