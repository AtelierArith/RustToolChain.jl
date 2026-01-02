module RustToolChains

const ARTIFACTS_TOML = joinpath(pkgdir(@__MODULE__), "Artifacts.toml")
const EXE_EXT = Sys.iswindows() ? ".exe" : ""

export cargo, rustc

using Pkg.Artifacts: ensure_artifact_installed, artifact_path, artifact_hash

"""
    cargo_exe_path_from_artifacts()

Get the cargo executable path from Julia's Artifacts system.
Downloads and installs the Rust toolchain if not already present.
"""
function cargo_exe_path_from_artifacts()
    ensure_artifact_installed("RustToolChain", ARTIFACTS_TOML)
    toolchain_dir = artifact_path(artifact_hash("RustToolChain", ARTIFACTS_TOML))
    # The Rust toolchain is unpacked inside a rust-*-*/ directory
    rust_dirs = filter(x -> startswith(x, "rust-"), readdir(toolchain_dir))
    isempty(rust_dirs) && error("Could not find rust-* directory in artifact")
    rust_dir = first(rust_dirs)
    return joinpath(toolchain_dir, rust_dir, "cargo", "bin", "cargo" * EXE_EXT)
end

"""
    rustc_exe_path_from_artifacts()

Get the rustc executable path from Julia's Artifacts system.
Downloads and installs the Rust toolchain if not already present.
"""
function rustc_exe_path_from_artifacts()
    ensure_artifact_installed("RustToolChain", ARTIFACTS_TOML)
    toolchain_dir = artifact_path(artifact_hash("RustToolChain", ARTIFACTS_TOML))
    # The Rust toolchain is unpacked inside a rust-*-*/ directory
    rust_dirs = filter(x -> startswith(x, "rust-"), readdir(toolchain_dir))
    isempty(rust_dirs) && error("Could not find rust-* directory in artifact")
    rust_dir = first(rust_dirs)
    return joinpath(toolchain_dir, rust_dir, "rustc", "bin", "rustc" * EXE_EXT)
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
using RustToolChains: cargo

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
    cargo_exe = cargo_exe_path_from_artifacts()
    return `$cargo_exe`
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
using RustToolChains: rustc

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
    rustc_exe = rustc_exe_path_from_artifacts()
    return `$rustc_exe`
end

end # module RustToolChains
