using Base.BinaryPlatforms: Platform
using ArtifactUtils
using Pkg.Artifacts

const RUST_VERSION = "1.92.0"
const ARTIFACTS_TOML = joinpath(dirname(@__DIR__), "Artifacts.toml")
const ARTIFACT_NAME = "RustToolChain"

# Rust triplet から Julia Platform へのマッピング
const PLATFORM_MAPPINGS = [
    # Apple platforms
    ("aarch64-apple-darwin", Platform("aarch64", "macos")),
    ("x86_64-apple-darwin", Platform("x86_64", "macos")),

    # Linux - GNU libc
    ("i686-unknown-linux-gnu", Platform("i686", "linux")),
    ("x86_64-unknown-linux-gnu", Platform("x86_64", "linux")),
    ("aarch64-unknown-linux-gnu", Platform("aarch64", "linux")),
    ("arm-unknown-linux-gnueabihf", Platform("armv6l", "linux")),
    ("armv7-unknown-linux-gnueabihf", Platform("armv7l", "linux")),
    ("powerpc64le-unknown-linux-gnu", Platform("powerpc64le", "linux")),
    ("riscv64gc-unknown-linux-gnu", Platform("riscv64", "linux")),

    # Linux - musl libc
    # ("i686-unknown-linux-musl", Platform("i686", "linux"; libc="musl")),
    ("x86_64-unknown-linux-musl", Platform("x86_64", "linux"; libc="musl")),
    ("aarch64-unknown-linux-musl", Platform("aarch64", "linux"; libc="musl")),
    ("arm-unknown-linux-musleabihf", Platform("armv6l", "linux"; libc="musl")),
    ("armv7-unknown-linux-musleabihf", Platform("armv7l", "linux"; libc="musl")),

    # FreeBSD
    ("x86_64-unknown-freebsd", Platform("x86_64", "freebsd")),
    # ("aarch64-unknown-freebsd", Platform("aarch64", "freebsd")),

    # Windows
    ("i686-pc-windows-msvc", Platform("i686", "windows")),
    ("x86_64-pc-windows-msvc", Platform("x86_64", "windows")),
]

function rust_triplet_to_platform(triplet::String)
    for (rust_triplet, platform) in PLATFORM_MAPPINGS
        if rust_triplet == triplet
            return platform
        end
    end
    error("Unknown platform triplet: $triplet")
end

function add_rust_toolchain_for_platform(triplet::String)
    url = "https://static.rust-lang.org/dist/rust-$(RUST_VERSION)-$(triplet).tar.gz"
    platform = rust_triplet_to_platform(triplet)

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
for (triplet, _) in PLATFORM_MAPPINGS
    try
        add_rust_toolchain_for_platform(triplet)
    catch e
        @warn "Failed to add platform $triplet" exception=(e, catch_backtrace())
    end
end

@info "Finished adding Rust toolchains to $ARTIFACTS_TOML"