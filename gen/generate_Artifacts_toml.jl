using Base.BinaryPlatforms: Platform
using ArtifactUtils
using Pkg.Artifacts

const RUST_VERSION = "1.91.0"
const ARTIFACTS_TOML = joinpath(dirname(@__DIR__), "Artifacts.toml")
const ARTIFACT_NAME = "RustToolChain"

# Rust triplet から Julia Platform へのマッピング
# (triplet, (arch, os, libc?))
# Rust 1.91.0 で利用可能なすべてのプラットフォーム
const PLATFORM_MAPPINGS = [
    # Apple platforms
    ("aarch64-apple-darwin", ("aarch64", "macos", nothing)),
    ("x86_64-apple-darwin", ("x86_64", "macos", nothing)),

    # Linux - GNU libc
    ("aarch64-unknown-linux-gnu", ("aarch64", "linux", "gnu")),
    ("x86_64-unknown-linux-gnu", ("x86_64", "linux", "gnu")),
    ("i686-unknown-linux-gnu", ("i686", "linux", "gnu")),
    ("arm-unknown-linux-gnueabi", ("armv7l", "linux", "gnu")),
    ("arm-unknown-linux-gnueabihf", ("armv7l", "linux", "gnu")),
    ("armv7-unknown-linux-gnueabihf", ("armv7l", "linux", "gnu")),
    ("powerpc-unknown-linux-gnu", ("powerpc64le", "linux", "gnu")),
    ("powerpc64-unknown-linux-gnu", ("powerpc64le", "linux", "gnu")),
    ("powerpc64le-unknown-linux-gnu", ("powerpc64le", "linux", "gnu")),
    ("riscv64gc-unknown-linux-gnu", ("riscv64", "linux", "gnu")),
    ("s390x-unknown-linux-gnu", ("s390x", "linux", "gnu")),
    ("loongarch64-unknown-linux-gnu", ("loongarch64", "linux", "gnu")),

    # Linux - musl libc
    ("aarch64-unknown-linux-musl", ("aarch64", "linux", "musl")),
    ("x86_64-unknown-linux-musl", ("x86_64", "linux", "musl")),
    ("loongarch64-unknown-linux-musl", ("loongarch64", "linux", "musl")),

    # Windows - MSVC
    ("x86_64-pc-windows-msvc", ("x86_64", "windows", nothing)),
    ("aarch64-pc-windows-msvc", ("aarch64", "windows", nothing)),
    ("i686-pc-windows-msvc", ("i686", "windows", nothing)),

    # Windows - GNU
    ("x86_64-pc-windows-gnu", ("x86_64", "windows", nothing)),
    ("i686-pc-windows-gnu", ("i686", "windows", nothing)),

    # Windows - GNU LLVM
    ("aarch64-pc-windows-gnullvm", ("aarch64", "windows", nothing)),

    # FreeBSD
    ("x86_64-unknown-freebsd", ("x86_64", "freebsd", nothing)),
]

function rust_triplet_to_platform(triplet::String)
    for (rust_triplet, (arch, os, libc)) in PLATFORM_MAPPINGS
        if rust_triplet == triplet
            if libc === nothing
                return Platform(arch, os)
            else
                return Platform(arch, os; libc=libc)
            end
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