# Troubleshooting Guide

This guide helps diagnose and resolve common issues when using Glaze-interop.jl.

## Table of Contents

1. [Installation Issues](#installation-issues)
2. [Build Problems](#build-problems)
3. [Runtime Errors](#runtime-errors)
4. [Performance Issues](#performance-issues)
5. [Type System Issues](#type-system-issues)
6. [Memory Problems](#memory-problems)
7. [Platform-Specific Issues](#platform-specific-issues)

## Installation Issues

### Julia Version Compatibility

**Problem:** Package fails to install with Julia version errors.

**Solution:**
```julia
# Check Julia version
julia --version  # Must be ≥ 1.6

# If too old, upgrade Julia
# Download from https://julialang.org/downloads/
```

### Missing C++ Compiler

**Problem:** CMake or compilation fails with "compiler not found".

**Solutions:**

**Linux:**
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install build-essential cmake

# Fedora/RHEL
sudo dnf install gcc-c++ cmake

# Check version
g++ --version  # Should be ≥ 12 for C++23
```

**macOS:**
```bash
# Install Xcode command line tools
xcode-select --install

# Or install via Homebrew
brew install gcc cmake

# Check version
g++ --version
clang++ --version
```

**Windows:**
```powershell
# Install Visual Studio 2022 with C++ tools
# Or install Visual Studio Build Tools 2022
# Ensure C++23 support is enabled
```

### Package Installation Failures

**Problem:** `Pkg.add(url="...")` fails.

**Solutions:**
```julia
# Clear package cache
using Pkg
Pkg.gc()

# Update registry
Pkg.update()

# Install with verbose output
Pkg.add(url="https://github.com/stephenberry/glaze-interop.jl", verbose=true)

# If still failing, try development mode
Pkg.develop(url="https://github.com/stephenberry/glaze-interop.jl")
```

## Build Problems

### CMake Configuration Errors

**Problem:** CMake fails to configure the build.

**Common Errors and Solutions:**

#### Missing Glaze Library
```
CMake Error: Could not find a package configuration file provided by "glaze"
```

**Solution:** Ensure FetchContent is properly configured:
```cmake
include(FetchContent)
FetchContent_Declare(
    glaze
    GIT_REPOSITORY https://github.com/stephenberry/glaze.git
    GIT_TAG main
)
FetchContent_MakeAvailable(glaze)
```

#### Wrong C++ Standard
```
CMake Error: Feature cxx_std_23 is not supported
```

**Solution:** Update CMake and compiler:
```cmake
cmake_minimum_required(VERSION 3.20)
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Check compiler support
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS "12")
        message(FATAL_ERROR "GCC 12 or higher required")
    endif()
endif()
```

#### Glaze Interop Header Not Found
```
CMake Error: Could not find glaze/interop/interop.hpp
```

**Solution:** Install Glaze properly:
```cmake
# Use FetchContent to get Glaze
include(FetchContent)
FetchContent_Declare(
    glaze
    GIT_REPOSITORY https://github.com/stephenberry/glaze.git
    GIT_TAG main
)
FetchContent_MakeAvailable(glaze)

# Link your target to glaze
target_link_libraries(your_target PRIVATE glaze::glaze)
```

### Compilation Errors

**Problem:** C++ compilation fails.

#### Template/Concept Errors
```cpp
error: no matching function for call to 'object'
```

**Solution:** Check your `glz::meta` specialization:
```cpp
// Correct format
template <>
struct glz::meta<YourStruct> {
    using T = YourStruct;
    static constexpr auto value = glz::object(
        "field1", &T::field1,
        "field2", &T::field2
        // Note: No trailing comma on last entry
    );
};
```

#### Missing Includes
```cpp
error: 'std::string' has not been declared
```

**Solution:** Add required includes:
```cpp
#include <glaze/interop/interop.hpp>  // Must be first
#include <string>
#include <vector>
#include <complex>
#include <optional>
#include <future>
```

#### Symbol Visibility Issues (Linux/macOS)
```
undefined reference to `glz_create_instance`
```

**Solution:** Check library settings:
```cmake
set_target_properties(your_lib PROPERTIES
    POSITION_INDEPENDENT_CODE ON
    CXX_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN ON
)

# Ensure C interface is exported
target_compile_definitions(your_lib PRIVATE GLZ_EXPORTS)
```

### Linking Problems

**Problem:** Linking fails with undefined symbols.

**Solutions:**
```cmake
# Ensure all required libraries are linked
target_link_libraries(your_lib PUBLIC 
    glaze::glaze
    pthread  # Often needed for std::async
)

# On some systems, need explicit libdl
if(UNIX AND NOT APPLE)
    target_link_libraries(your_lib PUBLIC dl)
endif()
```

## Runtime Errors

### Library Loading Failures

#### Library Not Found
```julia
ERROR: could not load library "mylib.so"
LoadError: dlopen: cannot open shared object file
```

**Solutions:**
```julia
# Check file exists
isfile("mylib.so")

# Use absolute path
lib_path = abspath("./build/libmylib.so")
lib = Glaze.CppLibrary(lib_path)

# Check library dependencies (Linux)
# $ ldd mylib.so

# Check library dependencies (macOS)
# $ otool -L mylib.dylib
```

#### Missing Shared Libraries
```
LoadError: dlopen: libglaze.so.1: cannot open shared object file
```

**Solutions:**
```bash
# Linux: Add to LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/path/to/glaze/lib:$LD_LIBRARY_PATH

# macOS: Add to DYLD_LIBRARY_PATH  
export DYLD_LIBRARY_PATH=/path/to/glaze/lib:$DYLD_LIBRARY_PATH

# Or install system-wide
sudo cp libglaze.so /usr/local/lib/
sudo ldconfig  # Linux only
```

### Initialization Errors

#### Init Function Not Found
```julia
ERROR: could not load symbol "init_my_types"
UndefVarError: init_my_types not defined
```

**Solutions:**
```cpp
// Ensure proper C linkage
extern "C" {
    void init_my_types() {  // Exact name used in Julia
        // initialization code
    }
}
```

```julia
# Check symbol exists
using Libdl
lib_handle = dlopen("mylib.so")
dlsym(lib_handle, :init_my_types)  # Should not error
```

#### Registration Failures
```julia
ERROR: Type registration failed
```

**Solutions:**
```cpp
// Check registration order - register dependencies first
extern "C" {
    void init_my_types() {
        // Register base types first
        glz::register_type<Address>("Address");
        glz::register_type<Person>("Person");  // Depends on Address
        
        // Then register instances
        glz::register_instance("global_person", global_person);
    }
}
```

### Type Access Errors

#### Instance Not Found
```julia
ERROR: Instance 'my_instance' not found
```

**Solutions:**
```julia
# Check instance was registered
ccall((:init_my_types, lib.handle), Cvoid, ())  # Must call first

# Check exact name spelling
instance = Glaze.get_instance(lib, "exact_registered_name")

# List all registered instances (if you have debugging)
# This would need custom C++ debugging function
```

#### Type Not Found
```julia
ERROR: Type 'MyStruct' not found
```

**Solutions:**
```cpp
// Ensure type is registered
glz::register_type<MyStruct>("MyStruct");  // Exact name used in Julia

// Check meta specialization exists
template <>
struct glz::meta<MyStruct> {
    // Must be present and correct
};
```

### Memory Access Errors

#### Segmentation Faults
```
signal (11): Segmentation fault
```

**Debugging Steps:**
```julia
# Enable debug mode
ENV["JULIA_DEBUG"] = "Glaze"

# Check object validity
isvalid(obj)  # For CppSharedFuture
obj.ptr != C_NULL  # For other objects

# Use smaller test cases
# Check bounds on vector access
1 <= index <= length(vector)
```

#### Null Pointer Errors
```julia
ERROR: NULL pointer dereference
```

**Solutions:**
```julia
# Check object initialization
obj = lib.MyType
if obj.ptr == C_NULL
    error("Object not properly initialized")
end

# Check nested object access
if obj.nested_field.ptr != C_NULL
    # Safe to access
    value = obj.nested_field.some_value
end
```

## Performance Issues

### Slow Field Access

**Problem:** Field access is unexpectedly slow.

**Solutions:**
```julia
# Profile field access
using BenchmarkTools
@btime obj.field  # Should be ~5ns

# Check for unnecessary conversions
# Bad: String conversion in loop
for i in 1:1000
    s = String(obj.string_field)  # Unnecessary conversion
end

# Good: Direct CppString operations  
for i in 1:1000
    len = length(obj.string_field)  # Direct CppString operation
end
```

### Slow Vector Operations

**Problem:** Vector operations are slow.

**Solutions:**
```julia
# Use array views for read-only access
view = array_view(obj.large_vector)
result = sum(view)  # Zero-copy operation

# Batch vector modifications
resize!(obj.vector, final_size)  # Single resize
for (i, val) in enumerate(data)
    obj.vector[i] = val  # Direct assignment
end

# Avoid repeated push! for large datasets
# Bad:
for val in large_data
    push!(obj.vector, val)  # Many reallocations
end

# Good:
resize!(obj.vector, length(large_data))
for (i, val) in enumerate(large_data)
    obj.vector[i] = val
end
```

### Memory Allocation Issues

**Problem:** Unexpected memory allocations.

**Debugging:**
```julia
# Check allocations
@allocated obj.field           # Should be 0
@allocated obj.method()        # Should be minimal
@allocated collect(obj.vector) # Shows copy allocation

# Find allocation sources
using Profile
@profile begin
    for i in 1:1000
        # Your code here
    end
end
Profile.print()
```

## Type System Issues

### String Conversion Problems

**Problem:** String operations don't work as expected.

**Solutions:**
```julia
# CppString supports AbstractString interface
cpp_str = obj.name
if cpp_str == "expected"  # Direct comparison works
    println("Found: $(cpp_str)")  # String interpolation works
end

# If you need Julia String:
julia_str = String(cpp_str)

# Check string encoding issues
if !isvalid(cpp_str)
    @warn "Invalid UTF-8 in C++ string"
end
```

### Vector Type Mismatches

**Problem:** Vector operations fail with type errors.

**Solutions:**
```julia
# Check vector element type
vec = obj.data_vector
@show typeof(vec)  # Shows CppVectorFloat64, etc.

# Handle different vector types
if isa(vec, Union{CppVector, CppVectorFloat64})
    # Compatible operations
elseif isa(vec, CppVectorInt32)
    # Integer-specific operations
end

# Convert if necessary
julia_array = collect(vec)  # Always works but copies data
```

### Complex Number Issues

**Problem:** Complex number operations fail.

**Solutions:**
```julia
# C++ std::complex maps to Julia Complex
z = obj.impedance  # std::complex<double> -> Complex{Float64}
@show typeof(z)    # Complex{Float64}

# All Julia complex operations work
magnitude = abs(z)
phase = angle(z)
real_part = real(z)
imag_part = imag(z)

# Complex vectors
for z in obj.complex_vector
    println("$(real(z)) + $(imag(z))i")
end
```

## Memory Problems

### Memory Leaks

**Problem:** Memory usage grows over time.

**Debugging:**
```julia
# Monitor memory usage
function monitor_memory()
    initial = Base.gc_live_bytes()
    
    # Your operations here
    for i in 1:1000
        obj = lib.MyType
        # ... operations
    end
    
    GC.gc()  # Force garbage collection
    final = Base.gc_live_bytes()
    println("Memory delta: $(final - initial) bytes")
end

# Check for retained references
obj = nothing  # Clear references
GC.gc()       # Allow cleanup
```

### Dangling Pointers

**Problem:** Access to freed C++ objects.

**Prevention:**
```julia
# Keep parent objects alive
struct SafeWrapper
    lib::CppLibrary      # Keep library loaded
    parent::CppStruct    # Keep parent alive
    child::CppStruct     # Child object
end

# Don't store nested objects without parent
# Bad:
function get_nested()
    obj = lib.MyType
    return obj.nested_field  # Dangerous - parent may be freed
end

# Good:
function get_nested()
    obj = lib.MyType
    nested = obj.nested_field
    return (obj, nested)  # Keep parent alive
end
```

## Platform-Specific Issues

### Windows Issues

#### Missing MSVC Runtime
```
ERROR: LoadError: The specified module could not be found
```

**Solution:**
```powershell
# Install Visual C++ Redistributable
# Download from Microsoft website

# Or use static linking
# In CMakeLists.txt:
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /MT")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} /MTd")
```

#### Path Issues
```julia
# Use forward slashes or escaped backslashes
lib_path = "C:/Users/Name/project/build/lib.dll"  # Good
lib_path = "C:\\Users\\Name\\project\\build\\lib.dll"  # Good
lib_path = "C:\Users\Name\project\build\lib.dll"  # Bad - escape issues
```

### macOS Issues

#### Code Signing
```
ERROR: dlopen: code signature invalid
```

**Solution:**
```bash
# Sign the library
codesign -s - mylib.dylib

# Or disable code signing requirement
export DYLD_LIBRARY_PATH=/path/to/lib:$DYLD_LIBRARY_PATH
```

#### Architecture Mismatches
```
ERROR: dlopen: architecture mismatch
```

**Solution:**
```bash
# Check architectures
file mylib.dylib
lipo -info mylib.dylib

# Build for current architecture
cmake -DCMAKE_OSX_ARCHITECTURES=$(uname -m) ..
```

### Linux Issues

#### GLIBC Version
```
ERROR: version `GLIBC_2.34' not found
```

**Solution:**
```bash
# Check GLIBC version
ldd --version

# Build on compatible system or use older compiler
# Or statically link standard library
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -static-libgcc -static-libstdc++")
```

## Getting Help

### Diagnostic Information

When reporting issues, include:

```julia
# Julia version and platform
println("Julia: ", VERSION)
println("Platform: ", Sys.MACHINE)

# Package information
using Pkg
Pkg.status("Glaze")

# Library information
lib = Glaze.CppLibrary("your_lib.so")
println("Library loaded successfully")

# Error reproduction
try
    # Minimal code that reproduces the error
    obj = Glaze.get_instance(lib, "test_obj")
    result = obj.problematic_operation()
catch e
    @error "Error occurred" exception=(e, catch_backtrace())
end
```

### Minimal Reproduction

Create a minimal example:

```cpp
// minimal.cpp
#include <glaze/interop/interop.hpp>

struct SimpleStruct {
    int value = 42;
};

template<>
struct glz::meta<SimpleStruct> {
    using T = SimpleStruct;
    static constexpr auto value = glz::object("value", &T::value);
};

SimpleStruct global_simple;

extern "C" {
    void init_simple() {
        glz::register_type<SimpleStruct>("SimpleStruct");
        glz::register_instance("global_simple", global_simple);
    }
}
```

```julia
# minimal.jl
using Glaze
lib = Glaze.CppLibrary("minimal.so")
ccall((:init_simple, lib.handle), Cvoid, ())
obj = Glaze.get_instance(lib, "global_simple")
println(obj.value)  # Should print 42
```

### Community Resources

- **GitHub Issues**: Report bugs with full diagnostic info
- **GitHub Discussions**: Ask questions and share solutions  
- **Julia Discourse**: General Julia/C++ interop discussions
- **Stack Overflow**: Tag questions with `glaze-interop.jl` and `julia`

---

If your issue isn't covered here, please open a GitHub issue with a minimal reproduction case and full diagnostic information.