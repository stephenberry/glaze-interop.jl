# Building from Source

This guide covers building Glaze-interop.jl from source, including development setup and contribution preparation.

## Table of Contents

1. [Quick Setup](#quick-setup)
2. [Development Environment](#development-environment)
3. [Building the Package](#building-the-package)
4. [Running Tests](#running-tests)
5. [Development Workflow](#development-workflow)
6. [Platform-Specific Notes](#platform-specific-notes)

## Quick Setup

### Prerequisites

Ensure you have the required tools installed:

- **Julia** ≥ 1.6
- **C++23** compiler (GCC 12+, Clang 15+, MSVC 2022+)
- **CMake** ≥ 3.20
- **Git**

### Clone and Build

```bash
# Clone the repository
git clone https://github.com/stephenberry/glaze-interop.jl.git
cd glaze-interop.jl

# Quick test - this runs the full test suite
./run_tests.sh       # Unix/macOS
.\run_tests.bat     # Windows
```

If the tests pass, you have a working setup!

## Development Environment

### Julia Development Setup

```julia
# Start Julia in the project directory
julia --project=.

# Install dependencies
using Pkg
Pkg.instantiate()

# Enter development mode
Pkg.develop(PackageSpec(path="."))

# Load the package
using Glaze
```

### C++ Development Setup

The C++ interface is in the `cpp_interface/` directory:

```bash
cd cpp_interface
mkdir build && cd build

# Configure
cmake .. -DCMAKE_BUILD_TYPE=Debug

# Build
make -j$(nproc)  # Linux/macOS
cmake --build . --parallel  # Cross-platform
```

### IDE Setup

#### VS Code
Create `.vscode/settings.json`:
```json
{
    "julia.environmentPath": ".",
    "cmake.sourceDirectory": "${workspaceFolder}/cpp_interface",
    "cmake.buildDirectory": "${workspaceFolder}/cpp_interface/build",
    "C_Cpp.default.includePath": [
        "${workspaceFolder}/cpp_interface",
        "${workspaceFolder}/cpp_interface/build/_deps/glaze-src/include"
    ]
}
```

#### JetBrains IDEs
- Import as CMake project from `cpp_interface/`
- Set Julia project root to the main directory

## Building the Package

### Full Build Process

```bash
# 1. Build C++ interface
cd cpp_interface/build
cmake .. && make

# 2. Build test libraries  
cd ../../test
mkdir -p build && cd build
cmake .. && make

# 3. Run Julia tests
cd ../..
julia --project=. test/runtests.jl
```

### Build Configurations

#### Debug Build
```bash
cmake .. -DCMAKE_BUILD_TYPE=Debug -DCMAKE_CXX_FLAGS="-g -O0"
```

#### Release Build
```bash
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="-O3 -DNDEBUG"
```

#### With Address Sanitizer (Linux/macOS)
```bash
cmake .. -DCMAKE_BUILD_TYPE=Debug \
         -DCMAKE_CXX_FLAGS="-fsanitize=address -fno-omit-frame-pointer"
```

### Build Options

Available CMake options:

```bash
# Enable verbose output
cmake .. -DCMAKE_VERBOSE_MAKEFILE=ON

# Specify compiler
cmake .. -DCMAKE_CXX_COMPILER=g++-12

# Custom Glaze location
cmake .. -DGLAZE_ROOT=/path/to/glaze

# Disable tests
cmake .. -DBUILD_TESTING=OFF
```

## Running Tests

### Full Test Suite

```bash
# Using convenience scripts
./run_tests.sh         # Unix/macOS 
.\run_tests.bat       # Windows

# Manual Julia test run
julia --project=. test/runtests.jl

# With coverage
julia --project=. --code-coverage=user test/runtests.jl
```

### Individual Test Files

```bash
# Run specific test file
julia --project=. test/test_all_types.jl
julia --project=. test/test_shared_future.jl
julia --project=. test/test_member_functions.jl
```

### C++ Tests

```bash
# Build and run C++ unit tests (if available)
cd cpp_interface/build
make test

# Run ctest with verbose output
ctest --verbose
```

### Test Categories

The test suite is organized into categories:

- **Core Types** (`test_all_types.jl`): Basic type mapping
- **Nested Structures** (`test_nested_structs.jl`): Complex struct hierarchies  
- **Containers** (`test_complex_vectors.jl`): STL container support
- **Member Functions** (`test_member_functions*.jl`): Function calling
- **Async Operations** (`test_shared_future.jl`): std::shared_future support
- **Optional Types** (`test_optional.jl`): std::optional support
- **Pretty Printing** (`test_pretty_printing.jl`): Display formatting

### Performance Tests

```bash
# Run benchmarks
julia --project=. test/benchmarks/benchmark_iteration.jl

# Simple performance check
julia --project=. test/benchmarks/simple_iteration_benchmark.jl
```

## Development Workflow

### Making Changes

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Make Changes**
   - Edit source files in `src/`
   - Update C++ interface in `cpp_interface/` if needed
   - Add tests in `test/`

3. **Test Changes**
   ```bash
   ./run_tests.sh
   ```

4. **Update Documentation**
   - Update docstrings
   - Update relevant `.md` files
   - Add examples if needed

### Code Style

#### Julia Code Style
Follow [Julia Style Guide](https://docs.julialang.org/en/v1/manual/style-guide/):

```julia
# Good: Descriptive names, snake_case for variables
function create_cpp_wrapper(lib_path::String)
    library_handle = load_library(lib_path)
    return CppLibrary(library_handle)
end

# Use type annotations for clarity
function process_vector(vec::CppVector)::Vector{Float64}
    return collect(vec)
end
```

#### C++ Code Style
Follow project conventions:

```cpp
// Good: Clear naming, consistent formatting
struct DataProcessor {
    std::vector<double> input_data;
    std::vector<double> output_data;
    
    void process_data() {
        output_data.clear();
        output_data.reserve(input_data.size());
        
        for (const auto& value : input_data) {
            output_data.push_back(transform(value));
        }
    }
    
private:
    double transform(double value) const {
        return value * 2.0 + 1.0;
    }
};

// Reflection follows consistent pattern
template <>
struct glz::meta<DataProcessor> {
    using T = DataProcessor;
    static constexpr auto value = glz::object(
        "input_data", &T::input_data,
        "output_data", &T::output_data,
        "process_data", &T::process_data
    );
};
```

### Adding New Features

#### New Type Support

1. **C++ Side**:
   ```cpp
   // Add type descriptor support in glaze/interop/interop.hpp
   enum class GLZ_TYPE : uint8_t {
       // ... existing types
       MY_NEW_TYPE = N
   };
   
   struct glz_mynewtype_desc {
       // Type-specific fields
   };
   ```

2. **Julia Side**:
   ```julia
   # Add Julia wrapper type in src/Glaze.jl
   mutable struct CppMyNewType
       ptr::Ptr{Cvoid}
       lib::Ptr{Cvoid}
   end
   
   # Add type mapping and operations
   ```

3. **Tests**:
   ```julia
   # Add comprehensive tests
   @testset "My New Type" begin
       # Test creation, access, operations
   end
   ```

#### New Container Support

Follow the pattern of existing containers:

1. Add C++ descriptor struct
2. Add Julia wrapper type  
3. Implement array-like interface
4. Add comprehensive tests
5. Update documentation

### Debugging Development Issues

#### C++ Compilation Issues

```bash
# Verbose compilation
make VERBOSE=1

# Check preprocessor output
g++ -E -I../cpp_interface source.cpp > preprocessed.cpp

# Check template instantiations
g++ -ftemplate-backtrace-limit=0 ...
```

#### Julia Issues

```julia
# Debug mode
ENV["JULIA_DEBUG"] = "Glaze"

# Load with errors
using Revise  # For automatic reloading
includet("src/Glaze.jl")

# Check method dispatch
@which obj.method()

# Profile allocations
@allocated obj.operation()
```

### Documentation Updates

When adding features, update:

1. **API Reference** (`docs/api_reference.md`)
2. **Getting Started** (`docs/getting_started.md`) - if user-facing
3. **README.md** - if significant feature
4. **Examples** - add usage examples
5. **Tests** - ensure comprehensive coverage

## Platform-Specific Notes

### Linux

#### Dependencies
```bash
# Ubuntu/Debian
sudo apt install build-essential cmake git

# Fedora/RHEL  
sudo dnf install gcc-c++ cmake git

# Arch
sudo pacman -S base-devel cmake git
```

#### Troubleshooting
```bash
# Check GLIBC version compatibility
ldd --version

# Use older compiler for compatibility
export CXX=g++-11
cmake ..
```

### macOS

#### Dependencies
```bash
# Xcode command line tools
xcode-select --install

# Homebrew
brew install cmake git

# MacPorts
sudo port install cmake git
```

#### Architecture Issues
```bash
# Build for current architecture
cmake -DCMAKE_OSX_ARCHITECTURES=$(uname -m) ..

# Universal binary (if needed)
cmake -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64" ..
```

### Windows

#### Visual Studio Setup
- Install Visual Studio 2022 with C++ workload
- Ensure CMake tools are installed
- Use Developer Command Prompt

#### PowerShell Build
```powershell
# Configure
cmake .. -G "Visual Studio 17 2022" -A x64

# Build
cmake --build . --config Release

# Or use MSBuild directly
MSBuild.exe glaze.sln /p:Configuration=Release
```

#### MinGW/MSYS2
```bash
# Install dependencies
pacman -S mingw-w64-x86_64-gcc mingw-w64-x86_64-cmake

# Build
cmake .. -G "MinGW Makefiles"
make
```

## Continuous Integration

The project uses GitHub Actions for CI. Local CI simulation:

```bash
# Run the same tests as CI
./run_tests.sh

# Check formatting (if formatters are set up)
julia --project=. -e "using JuliaFormatter; format(\".\")"

# Check for common issues
julia --project=. -e "using Pkg; Pkg.test(coverage=true)"
```

### Adding New CI Tests

Edit `.github/workflows/ci.yml` to add new test configurations or platforms.

---

This building guide should help you set up a complete development environment for contributing to Glaze-interop.jl!