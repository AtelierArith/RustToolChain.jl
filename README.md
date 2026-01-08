# RustToolChain.jl

[![CI](https://github.com/AtelierArith/RustToolChain.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/AtelierArith/RustToolChain.jl/actions/workflows/CI.yml)

RustToolChain.jl is a Julia package that provides Rust toolchains (especially `cargo`) using Julia's Artifacts system. You can build and run Rust projects directly from Julia without installing Rust on your system.

## Features

- 🦀 Provides Rust 1.92.0 toolchain
- 📦 Automatic download and management via Julia's Artifacts system
- 🖥️ Supports multiple platforms and architectures
- 🚀 Simple API to execute `cargo` commands

## Supported Platforms

- **Linux**: x86_64 (glibc, musl), aarch64 (glibc, musl), i686 (glibc, musl)
- **macOS**: x86_64, aarch64
- **Windows**: x86_64, aarch64

## Installation

```julia
using Pkg; Pkg.add("RustToolChain")
```

## Usage

### Basic Example

```julia
using RustToolChain: cargo

# Execute cargo command
run(`$(cargo()) --version`)

# Build a Rust project
run(`$(cargo()) build`)

# Run a Rust project
run(`$(cargo()) run`)
```

### Running Examples

This repository includes a simple example:

```sh
git clone https://github.com/AtelierArith/RustToolChain.jl.git
cd RustToolChain.jl
julia --project -e 'using Pkg; Pkg.instantiate()'
cd examples
julia --project run.jl
```

Or from the Julia REPL:

```julia
using Pkg
Pkg.activate("examples")
Pkg.instantiate()
include("examples/run.jl")
```

## API

### `cargo()`

Returns a command object for executing Rust's `cargo` command.

**Returns**: `Cmd` object (usable with Julia's backtick syntax)

**Examples**:
```julia
using RustToolChain: cargo

# Check cargo version
run(`$(cargo()) --version`)

# Create a new Rust project
run(`$(cargo()) new my_project`)

# Build project
run(`$(cargo()) build --release`)
```

## Internal Implementation

This package uses Julia's Artifacts system to automatically download and manage Rust toolchains. On first use, the appropriate Rust toolchain for your platform will be automatically downloaded.

## Development

### Project Structure

```
RustToolChain.jl/
├── src/
│   └── RustToolChain.jl           # Main Julia module
├── examples/
│   ├── hello/                      # Example Rust project
│   └── run.jl                      # Julia script demonstrating usage
├── gen/
│   └── generate_Artifacts_toml.jl  # Script to generate Artifacts.toml
├── test/
│   └── runtests.jl                 # Julia test script
├── .github/workflows/
│   ├── CI.yml                      # Continuous integration tests
│   └── bump-rust-stable.yml        # Auto-update Rust toolchain
├── Artifacts.toml                  # List of artifact dependencies
└── Project.toml                    # Julia package manifest
```

### Automatic Rust Toolchain Updates

This package automatically checks for new Rust stable releases and creates pull requests to update the toolchain.

**Automated Workflow:**
- Runs weekly (every Monday at 00:00 UTC)
- Fetches the latest Rust stable version from `https://static.rust-lang.org/dist/channel-rust-stable.toml`
- Regenerates `Artifacts.toml` with the new version
- Updates the version in `README.md`
- Creates a pull request if changes are detected

**Manual Update:**

You can manually regenerate `Artifacts.toml` for a specific Rust version:

```bash
julia --project=gen gen/generate_Artifacts_toml.jl <RUST_VERSION>

# Example:
julia --project=gen gen/generate_Artifacts_toml.jl 1.93.0
```

The script validates the version format (X.Y.Z) and provides clear error messages for invalid input.

## License

Please refer to the LICENSE file in the repository for license information.

## Author

- Satoshi Terasaki <terasakisatoshi.math@gmail.com>

## Related Links

- [Julia Artifacts Documentation](https://pkgdocs.julialang.org/v1/artifacts/)
- [Rust Official Website](https://www.rust-lang.org/)
- [Cargo Documentation](https://doc.rust-lang.org/cargo/)
