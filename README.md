# RustToolChains.jl

[![CI](https://github.com/AtelierArith/RustToolChains.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/AtelierArith/RustToolChains.jl/actions/workflows/CI.yml)

RustToolChains.jl is a Julia package that provides Rust toolchains (especially `cargo`) using Julia's Artifacts system. You can build and run Rust projects directly from Julia without installing Rust on your system.

## Features

- 🦀 Provides Rust 1.91.0 toolchain
- 📦 Automatic download and management via Julia's Artifacts system
- 🖥️ Supports multiple platforms and architectures
- 🚀 Simple API to execute `cargo` commands

## Supported Platforms

- **Linux**: x86_64 (glibc, musl), aarch64 (glibc, musl), i686 (glibc, musl)
- **macOS**: x86_64, aarch64
- **Windows**: x86_64, aarch64

## Installation

```julia
using Pkg
Pkg.add("RustToolChains")
```

Or, to use the development version:

```julia
using Pkg
Pkg.add(url="https://github.com/AtelierArith/RustToolChains.jl.git")
```

## Usage

### Basic Example

```julia
using RustToolChains: cargo

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
git clone https://github.com/AtelierArith/RustToolChains.jl.git
cd RustToolChains.jl
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
using RustToolChains: cargo

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
RustToolChains.jl/
├── src/
│   └── RustToolChains.jl           # Main Julia module
├── examples/
│   ├── hello/                      # Example Rust project
│   └── run.jl                      # Julia script demonstrating usage
├── gen/
│   └── generate_Artifacts_toml.jl  # Script to generate Artifacts.toml
├── test/
│   └── runtests.jl                 # Julia test script
├── Artifacts.toml                  # List of artifact dependencies
└── Project.toml                    # Julia package manifest
```

## License

Please refer to the LICENSE file in the repository for license information.

## Contributing

Pull requests and issue reports are welcome. Please refer to CONTRIBUTING.md in the repository for contribution guidelines.

## Author

- Satoshi Terasaki <terasakisatoshi.math@gmail.com>

## Related Links

- [Julia Artifacts Documentation](https://pkgdocs.julialang.org/v1/artifacts/)
- [Rust Official Website](https://www.rust-lang.org/)
- [Cargo Documentation](https://doc.rust-lang.org/cargo/)
