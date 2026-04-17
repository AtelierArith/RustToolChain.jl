using Base.BinaryPlatforms: Platform
using Downloads
using TOML

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
    ("x86_64-unknown-linux-musl", Platform("x86_64", "linux"; libc="musl")),
    ("aarch64-unknown-linux-musl", Platform("aarch64", "linux"; libc="musl")),

    # FreeBSD
    ("x86_64-unknown-freebsd", Platform("x86_64", "freebsd")),

    # Windows
    ("i686-pc-windows-msvc", Platform("i686", "windows")),
    ("x86_64-pc-windows-msvc", Platform("x86_64", "windows")),
]

function validate_version(version::AbstractString)::Bool
    return match(r"^\d+\.\d+\.\d+$", version) !== nothing
end

function rust_channel_manifest_url(version::AbstractString)::String
    return "https://static.rust-lang.org/dist/channel-rust-$(version).toml"
end

function available_rust_targets(manifest_text::AbstractString)::Set{String}
    parsed = TOML.parse(manifest_text)
    pkg = get(parsed, "pkg", Dict{String, Any}())
    rust = get(pkg, "rust", Dict{String, Any}())
    targets = get(rust, "target", Dict{String, Any}())

    return Set(
        String(triplet) for (triplet, metadata) in pairs(targets)
        if get(metadata, "available", false)
    )
end

function supported_platform_mappings(manifest_text::AbstractString)
    available_targets = available_rust_targets(manifest_text)
    return [
        (triplet, platform) for (triplet, platform) in PLATFORM_MAPPINGS
        if triplet in available_targets
    ]
end

function supported_platform_mappings_for_version(version::AbstractString)
    validate_version(version) || error(
        "Invalid Rust version format: '$version'. Expected format: X.Y.Z (e.g., 1.92.0)",
    )

    manifest_text = read(Downloads.download(rust_channel_manifest_url(version)), String)
    return supported_platform_mappings(manifest_text)
end
