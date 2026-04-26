module RustToolChain

const ARTIFACTS_TOML = joinpath(pkgdir(@__MODULE__), "Artifacts.toml")
const EXE_EXT = Sys.iswindows() ? ".exe" : ""
const REQUIRED_TOOLS = ("cargo", "rustc")
const WINDOWS_REQUIRED_TOOLS = ("cargo", "rustc", "rustfmt", "clippy-driver")
const DIST_METADATA_FILES = Set((
    "components",
    "install.sh",
    "manifest.in",
    "rust-installer-version",
    "uninstall.sh",
))

export cargo, rustc

using Downloads: download
using Pkg.Artifacts: artifact_hash, artifact_meta, artifact_path, ensure_artifact_installed
using Scratch: @get_scratch!

function _toolchain_prefix_ready(prefix::AbstractString)
    return all(tool -> isfile(joinpath(prefix, "bin", tool * EXE_EXT)), REQUIRED_TOOLS)
end

function _copy_tree!(src::AbstractString, dst::AbstractString)
    if isdir(src)
        mkpath(dst)
        for name in readdir(src)
            _copy_tree!(joinpath(src, name), joinpath(dst, name))
        end
    else
        mkpath(dirname(dst))
        cp(src, dst; force=true)
    end
    return nothing
end

function _dist_components(rust_dir::AbstractString)
    components_file = joinpath(rust_dir, "components")
    if isfile(components_file)
        return filter(!isempty, strip.(readlines(components_file)))
    end

    return filter(name -> isdir(joinpath(rust_dir, name)), readdir(rust_dir))
end

function _install_from_unpacked_dist!(rust_dir::AbstractString, prefix::AbstractString)
    mkpath(prefix)

    for component in _dist_components(rust_dir)
        component_dir = joinpath(rust_dir, component)
        isdir(component_dir) || continue

        for name in readdir(component_dir)
            name in DIST_METADATA_FILES && continue
            _copy_tree!(joinpath(component_dir, name), joinpath(prefix, name))
        end
    end

    _toolchain_prefix_ready(prefix) || error(
        "Rust toolchain artifact was installed to $prefix, but cargo/rustc were not found",
    )

    return prefix
end

function _rust_version_from_artifact_metadata()
    meta = artifact_meta("RustToolChain", ARTIFACTS_TOML)
    downloads = get(meta, "download", [])
    isempty(downloads) && error("RustToolChain artifact metadata does not contain a download URL")

    url = get(first(downloads), "url", "")
    matched = match(r"rust-(\d+\.\d+\.\d+)-", url)
    matched === nothing && error("Could not determine Rust version from artifact URL: $url")
    return matched.captures[1]
end

function _windows_rustup_init_url()
    arch = Sys.ARCH === :aarch64 ? "aarch64" : "x86_64"
    return "https://win.rustup.rs/$arch"
end

function _windows_host_triple()
    arch = Sys.ARCH === :aarch64 ? "aarch64" : "x86_64"
    return "$arch-pc-windows-msvc"
end

function _windows_rustup_env(toolchain::AbstractString)
    scratch = @get_scratch!("rustup-windows")
    rustup_home = joinpath(scratch, "rustup")
    cargo_home = joinpath(scratch, "cargo")

    env = copy(ENV)
    env["RUSTUP_HOME"] = rustup_home
    env["CARGO_HOME"] = cargo_home
    env["RUSTUP_TOOLCHAIN"] = toolchain

    return scratch, rustup_home, cargo_home, env
end

function _windows_rustup_toolchain_ready(
    rustup_home::AbstractString,
    cargo_home::AbstractString,
    toolchain::AbstractString,
)
    toolchain_dir = joinpath(rustup_home, "toolchains", "$toolchain-$(_windows_host_triple())")
    return isdir(toolchain_dir) &&
           all(tool -> isfile(joinpath(cargo_home, "bin", tool * ".exe")), WINDOWS_REQUIRED_TOOLS)
end

function _ensure_windows_rust_toolchain_installed()
    toolchain = _rust_version_from_artifact_metadata()
    scratch, rustup_home, cargo_home, env = _windows_rustup_env(toolchain)
    rustup_path = joinpath(cargo_home, "bin", "rustup.exe")

    if !isfile(rustup_path)
        mkpath(scratch)
        rustup_init = joinpath(scratch, "rustup-init.exe")
        @info "Downloading rustup-init for isolated Windows Rust toolchain" url = _windows_rustup_init_url()
        download(_windows_rustup_init_url(), rustup_init)
        run(setenv(`$rustup_init --default-toolchain none --no-modify-path -y`, env))
    end

    if !_windows_rustup_toolchain_ready(rustup_home, cargo_home, toolchain)
        @info "Installing isolated Windows Rust toolchain" toolchain profile = "complete"
        run(setenv(`$rustup_path toolchain install $toolchain --profile complete --no-self-update`, env))
        run(setenv(`$rustup_path default $toolchain`, env))
    end

    _windows_rustup_toolchain_ready(rustup_home, cargo_home, toolchain) || error(
        "Windows Rust toolchain installation completed, but cargo/rustc were not found in $cargo_home",
    )

    return cargo_home, env
end

"""
    ensure_rust_toolchain_installed()

Ensures that the Rust toolchain artifact is installed and available.
If not already installed, downloads and installs the Rust toolchain artifact.
Returns the installation prefix directory containing the Rust binaries.
"""
function ensure_rust_toolchain_installed()
    if Sys.iswindows()
        cargo_home, _ = _ensure_windows_rust_toolchain_installed()
        return cargo_home
    end

    ensure_artifact_installed("RustToolChain", ARTIFACTS_TOML)
    toolchain_dir = artifact_path(artifact_hash("RustToolChain", ARTIFACTS_TOML))
    # The Rust toolchain is unpacked inside a rust-*-*/ directory
    rust_dirs = filter(x -> startswith(x, "rust-"), readdir(toolchain_dir))
    isempty(rust_dirs) && error("Could not find rust-* directory in artifact")
    rust_dir = first(rust_dirs)
    prefix = joinpath(toolchain_dir, rust_dir, "prefix")

    if _toolchain_prefix_ready(prefix)
        return prefix
    elseif Sys.iswindows()
        return _install_from_unpacked_dist!(joinpath(toolchain_dir, rust_dir), prefix)
    else
        run(`bash $(joinpath(toolchain_dir, rust_dir, "install.sh")) --prefix=$(prefix) --disable-ldconfig`)
        _toolchain_prefix_ready(prefix) || error(
            "Rust toolchain installer completed, but cargo/rustc were not found in $prefix",
        )
        return prefix
    end
end

"""
    cargo_cmd_from_artifacts()

Get the cargo executable command from Julia's Artifacts system.
Downloads and installs the Rust toolchain if not already present.
"""
function cargo_cmd_from_artifacts()
    if Sys.iswindows()
        cargo_home, env = _ensure_windows_rust_toolchain_installed()
        cargo_path = joinpath(cargo_home, "bin", "cargo.exe")
        return setenv(`$cargo_path`, env)
    end

    prefix = ensure_rust_toolchain_installed()
    cargo_path = joinpath(prefix, "bin", "cargo" * EXE_EXT)
    @assert isfile(cargo_path) "Cargo executable not found at $cargo_path"

    env = copy(ENV)
    env["RUSTC"] = joinpath(prefix, "bin", "rustc" * EXE_EXT)
    return setenv(`$cargo_path`, env)
end

"""
    rustc_exe_cmd_from_artifacts()

Get the rustc executable command from Julia's Artifacts system.
Downloads and installs the Rust toolchain if not already present.
"""
function rustc_cmd_from_artifacts()
    if Sys.iswindows()
        cargo_home, env = _ensure_windows_rust_toolchain_installed()
        rustc_path = joinpath(cargo_home, "bin", "rustc.exe")
        return setenv(`$rustc_path`, env)
    end

    prefix = ensure_rust_toolchain_installed()
    rustc_path = joinpath(prefix, "bin", "rustc" * EXE_EXT)
    return `$rustc_path --sysroot $(prefix)`
end

"""
    cargo()

Get a command object for executing Rust's cargo command.
First checks if cargo is available in the system PATH.
If not found, uses the cargo from Julia's Artifacts system.

# Returns
- `Cmd` object (usable with Julia's backtick syntax)

# Examples
```julia
using RustToolChain: cargo

# Check cargo version
run(`\$(cargo()) --version`)

# Build a project
run(`\$(cargo()) build`)
```
"""
function cargo()
    # Try to use system cargo first (case A)
    system_cargo = Sys.which("cargo")
    if system_cargo !== nothing
        return `$system_cargo`
    end

    # Fall back to Artifacts cargo (case B)
    return cargo_cmd_from_artifacts()
end

"""
    rustc()

Get a command object for executing Rust's rustc compiler.
First checks if rustc is available in the system PATH.
If not found, uses the rustc from Julia's Artifacts system.

# Returns
- `Cmd` object (usable with Julia's backtick syntax)

# Examples
```julia
using RustToolChain: rustc

# Check rustc version
run(`\$(rustc()) --version`)

# Compile a Rust file
run(`\$(rustc()) main.rs`)
```
"""
function rustc()
    # Try to use system rustc first (case A)
    system_rustc = Sys.which("rustc")
    if system_rustc !== nothing
        return `$system_rustc`
    end

    # Fall back to Artifacts rustc (case B)
    return rustc_cmd_from_artifacts()
end

end # module RustToolChain
