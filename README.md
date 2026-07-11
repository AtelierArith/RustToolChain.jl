# RustToolChain.jl

[![CI](https://github.com/AtelierArith/RustToolChain.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/AtelierArith/RustToolChain.jl/actions/workflows/CI.yml)

RustToolChain.jl is a Julia package that provides Rust toolchains (especially `cargo`) using Julia's Artifacts system. You can build and run Rust projects directly from Julia without installing Rust on your system.

## Features

- 🦀 Provides Rust 1.96.1 toolchain
- 📦 Automatic download and management via Julia's Artifacts system
- 🖥️ Supports multiple platforms and architectures
- 🚀 Simple API to execute `cargo` commands

## Supported Platforms

- **Linux**: x86_64 (glibc, musl), aarch64 (glibc, musl), i686 (glibc, musl)
- **macOS**: x86_64, aarch64
- **Windows**: x86_64

### Preparation (Windows users only)

RustToolChain.jl installs an isolated Rust toolchain (`cargo`, `rustc`, and related tools) for you.
It does **not** provide a C/C++ linker or the Windows SDK.

On Windows this package uses the `x86_64-pc-windows-msvc` target, so linking still requires Microsoft's **MSVC build tools** (for example `link.exe`) and a Windows SDK.
Install these **once** on the machine before building Rust projects.

#### Option A: winget (recommended)

Open **PowerShell or Command Prompt as Administrator**, then run:

```ps
winget install -e --id Microsoft.VisualStudio.2022.BuildTools `
  --accept-source-agreements `
  --accept-package-agreements `
  --override "--wait --passive --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
```

| Flag / value | Purpose |
| --- | --- |
| `Microsoft.VisualStudio.2022.BuildTools` | Installs [Visual Studio 2022 Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/) (no full IDE) |
| `Microsoft.VisualStudio.Workload.VCTools` | Adds the C++ build tools workload (MSVC + linker) |
| `--includeRecommended` | Pulls in recommended components, including a Windows SDK |
| `--wait --passive` | Runs a non-interactive install and waits until it finishes |

Notes:

- The same command can also add the C++ workload if Build Tools are already installed without it (`winget install` + `--override` modifies the existing product).
- After installation, open a **new** terminal (or reboot if tools are still not found) so environment variables are refreshed.
- Use of Microsoft C++ Build Tools requires a valid Visual Studio license (Community is free for many use cases).

#### Option B: Visual Studio Installer (GUI)

1. Download [Build Tools for Visual Studio](https://visualstudio.microsoft.com/visual-cpp-build-tools/)
2. Run the installer
3. Select the **Desktop development with C++** workload
4. Complete the install

#### Why this is required

Without MSVC build tools, `cargo build` typically fails with errors such as:

```text
note: the msvc targets depend on the msvc linker but `link.exe` was not found
```

RustToolChain.jl cannot work around this: the MSVC linker and Windows SDK are host system components, not part of the Rust distribution that this package downloads.

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

This package uses Julia's Artifacts system to automatically download and manage Rust toolchains on Unix-like platforms. On first use, the appropriate Rust toolchain for your platform will be automatically downloaded.

The `cargo()` and `rustc()` functions return commands that use the isolated Windows toolchain when no system `cargo` or `rustc` is available.

### Note for Windows Users

Windows uses a different installation path. Instead of installing the large Rust distribution tarball through Julia Artifacts, RustToolChain.jl downloads `rustup-init.exe` from `https://win.rustup.rs` and installs the Rust version recorded in `Artifacts.toml` with `rustup toolchain install --profile default`. The installation is isolated under this package's Julia scratchspace by setting package-local `RUSTUP_HOME` and `CARGO_HOME` directories. It does not modify the user's `PATH` or the user's existing Rust installation.


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

**Note on CI for auto-generated PRs:**

PRs created by the GitHub Actions workflow may not start the `pull_request` CI jobs automatically. If the required checks are still missing, trigger CI by pushing an empty commit to the PR branch:

```bash
gh pr checkout <PR_NUMBER>
git commit --allow-empty -m "Trigger CI for PR #<PR_NUMBER>"
git push
```

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
