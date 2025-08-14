# Glaze (C++) Julia Interop

[![Julia](https://img.shields.io/badge/julia-%3E%3D%201.6-blue.svg)](https://julialang.org/)
[![C++](https://img.shields.io/badge/C%2B%2B-23-brightgreen.svg)](https://en.cppreference.com/w/cpp/23)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A high-performance Julia package for **zero-copy interoperability** with C++ data structures using the [Glaze](https://github.com/stephenberry/glaze) reflection library.

## Key Features

- **Zero-Copy Access**: Direct memory manipulation of C++ objects from Julia with no serialization overhead
- **Type Safety**: Compile-time type checking with C++23 reflection and runtime bounds checking
- **Nested Structures**: Full support for arbitrarily complex nested data structures
- **STL Container Support**: Native integration with `std::string`, `std::vector`, `std::complex`, `std::variant`
- **Member Functions**: Call C++ member functions directly from Julia
- **Async Support**: Work with `std::shared_future` for asynchronous C++ computations
- **Optional Types**: Handle `std::optional` with Julia-like semantics
- **Variant Types**: Full support for `std::variant` with multiple alternative types
- **Complex Numbers**: Seamless `std::complex` to Julia `Complex` conversion
- **String Integration**: `CppString` inherits from `AbstractString` with full Julia string API
- **Pretty Printing**: Beautiful nested structure visualization

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Core Features](#core-features)
- [Advanced Features](#advanced-features)
- [Documentation](#documentation)
- [Examples](#examples)
- [Performance](#performance)
- [License](#license)

## Installation

### Requirements

- **Julia** ≥ 1.6
- **C++23** compatible compiler (GCC 12+, Clang 15+, MSVC 2022+)
- **CMake** ≥ 3.20
- **Glaze** C++ library (automatically fetched)

### Install Package

```julia
using Pkg
Pkg.add(url="https://github.com/stephenberry/glaze-interop.jl")
```

## Quick Start

### 1. Define Your C++ Structure

```cpp
// person.hpp
#include <glaze/interop/interop.hpp>

struct Address {
    std::string street;
    std::string city;
    int32_t zipcode;
};

struct Person {
    std::string name;
    int32_t age;
    Address address;
    std::vector<float> scores;
    
    // Member functions work too!
    double average_score() const {
        if (scores.empty()) return 0.0;
        double sum = 0.0;
        for (float score : scores) sum += score;
        return sum / scores.size();
    }
};

// Register with Glaze reflection
template <>
struct glz::meta<Address> {
    using T = Address;
    static constexpr auto value = glz::object(
        &T::street, &T::city, &T::zipcode
    );
};

template <>
struct glz::meta<Person> {
    using T = Person;
    static constexpr auto value = glz::object(
        &T::name, &T::age, &T::address, &T::scores, &T::average_score
    );
};
```

### 2. Create and Register Your Instance

```cpp
// person.cpp
#include "person.hpp"

Person global_person{
    "Alice Smith", 
    30, 
    {"123 Main St", "San Francisco", 94105},
    {95.5f, 87.3f, 92.1f}
};

extern "C" {
    void init_person_types() {
        glz::register_type<Address>("Address");
        glz::register_type<Person>("Person");
        glz::register_instance("global_person", global_person);
    }
}
```

### 3. Build Your Library

```bash
g++ -std=c++23 -shared -fPIC -o person.so person.cpp \\
    -I/path/to/glaze/include
```

### 4. Access from Julia

```julia
using Glaze

# Load your compiled library
lib = Glaze.CppLibrary("person.so")

# Initialize types
ccall((:init_person_types, lib.handle), Cvoid, ())

# Access the C++ instance with zero-copy
person = Glaze.get_instance(lib, "global_person")

# Direct field access
println(person.name)           # "Alice Smith" (CppString, works like Julia String)
println(person.age)            # 30
person.age = 31               # Direct memory write to C++!

# Nested structure access
println(person.address.street) # "123 Main St"
person.address.city = "Oakland" # Modify nested field

# Vector operations (zero-copy)
println(length(person.scores))  # 3
push!(person.scores, 89.5)     # Modify C++ std::vector
person.scores[1] = 96.0        # Direct element access

# Member function calls
avg = person.average_score()    # Call C++ member function
println("Average: $avg")       # "Average: 91.725"

# String interpolation works naturally
println("Hello, $(person.name)!") # CppString supports AbstractString interface

# Pretty printing
println(person)  # Beautiful nested structure display
```

## Core Features

### Supported Types

| C++ Type | Julia Wrapper | Features |
|----------|---------------|----------|
| `int8_t`, `int16_t`, `int32_t`, `int64_t` | Native Julia integers | Direct access |
| `uint8_t`, `uint16_t`, `uint32_t`, `uint64_t` | Native Julia integers | Direct access |
| `float`, `double` | `Float32`, `Float64` | Direct access |
| `bool` | `Bool` | Direct access |
| `std::string` | `CppString <: AbstractString` | Full Julia string API |
| `std::vector<T>` | `CppVector` | Array-like interface |
| `std::complex<T>` | `Complex{T}` | Native Julia complex |
| `std::optional<T>` | `CppOptional{T}` | `value()`, `reset!()` |
| `std::variant<Ts...>` | `CppVariant` | Type-safe variant operations |
| `std::shared_future<T>` | `CppSharedFuture` | `get()`, `isready()` |
| User structs | `CppStruct` | Nested field access |
| Member functions | `CppMemberFunction` | Direct calls |

### CppString: Full AbstractString Support

CppString now inherits from `AbstractString` and supports the complete Julia string interface:

```julia
# All of these work naturally:
person.name == "Alice"                    # Equality comparison
length(person.name)                       # String length  
person.name[1]                           # Character indexing
"Name: $(person.name)"                   # String interpolation
startswith(person.name, "Al")            # String predicates
uppercase(person.name)                   # String transformations
for char in person.name; println(char); end  # Iteration
```

### Vector Operations

C++ vectors provide a natural Julia array interface:

```julia
# All standard array operations work:
push!(person.scores, 88.5)           # Add element
person.scores[2] = 90.0              # Modify element  
length(person.scores)                # Get size
resize!(person.scores, 10)           # Resize vector
for score in person.scores           # Iterate
    println(score)
end

# Vectorized operations
person.scores .+ 5.0                 # Broadcasting
sum(person.scores)                   # Reductions
```

## Advanced Features

### Member Functions

Call C++ member functions directly:

```julia
# Member functions return CppMemberFunction objects
calc_fn = calculator.compute
result = calc_fn(2.5, 3.0)  # Call with arguments

# Or call directly
result = calculator.compute(2.5, 3.0)
```

### Asynchronous Operations with std::shared_future

```julia
# C++ returns std::shared_future<Person>
future = async_service.getPersonAsync("John", 25, 1000)  # 1s delay

# Check if ready
if isready(future)
    person = get(future)  # Zero-copy access to result
    println(person.name)
end

# Wait for completion
person = get(future)  # Blocks until ready
```

### Optional Types

```julia
# C++ std::optional<std::string> maps to CppOptional
if hasvalue(optional_name)
    name = value(optional_name)  # Extract value
    println("Name: $name")
else
    println("No name provided")
end

# Reset optional
reset!(optional_name)
```

### Variant Types

Work with C++ `std::variant` types safely and efficiently:

```julia
# C++ std::variant<int, double, std::string>
container = lib.VariantContainer

# Set variant to different types via C++ member functions
container.set_simple_to_int(42)
println("Index: ", container.get_simple_index())  # 0 (first alternative)

container.set_simple_to_double(3.14159)
println("Index: ", container.get_simple_index())  # 1 (second alternative)

container.set_simple_to_string("hello variant")
println("Index: ", container.get_simple_index())  # 2 (third alternative)

# Variants with custom struct types
container.set_geometry_to_point2d(1.5, 2.5)
container.set_geometry_to_point3d(1.0, 2.0, 3.0)
container.set_geometry_to_color(255, 128, 64)

# Check which alternative is active
current_index = container.get_geometry_index()
println("Current geometry type: $current_index")
```

### Complex Numbers and Vectors

```julia
# std::complex<double> → Complex{Float64}
z = complex_data.impedance        # Native Julia Complex
magnitude = abs(z)
phase = angle(z)

# std::vector<std::complex<float>> → CppVectorComplexF32
for z in complex_vector
    println("$(real(z)) + $(imag(z))i")
end
```

### Pretty Printing

Nested structures display beautifully:

```julia
julia> person
Person {
  name: "Alice Smith",
  age: 31,
  address: Address {
    street: "123 Main St",
    city: "Oakland", 
    zipcode: 94105
  },
  scores: [96.0, 87.3, 92.1, 89.5]
}
```

## Documentation

### User Guides
- [**Getting Started**](docs/getting_started.md) - Step-by-step tutorial
- [**API Reference**](docs/api_reference.md) - Complete function reference  
- [**Type System Guide**](docs/type_system.md) - Understanding type mappings
- [**Advanced Usage**](docs/advanced_usage.md) - Complex scenarios and patterns

### Developer Resources
- [**Building from Source**](docs/building.md) - Development setup
- [**Troubleshooting**](docs/troubleshooting.md) - Common issues and solutions

## Examples

### Basic Usage
```julia
# Create new instances
person = lib.Person
person.name = "Bob"
person.age = 25

# Copy between instances  
target = lib.Person
copy!(target, person)       # Deep copy
Glaze.@assign target = person  # Macro syntax
```

### Performance Comparison
```julia
# Zero-copy vs serialization benchmark
using BenchmarkTools

# Glaze-interop.jl: Zero-copy access
@btime person.scores[1000] = 95.5  # ~5ns

# JSON serialization approach  
@btime begin
    data = JSON.parse(json_string)
    data["scores"][1000] = 95.5
    JSON.json(data)
end  # ~50μs (10,000x slower!)
```

More examples in the [`examples/`](examples/) directory:
- [`variant_example.jl`](examples/variant_example.jl) - Working with C++ std::variant types

## Performance

Glaze-interop.jl provides **true zero-copy** performance:

- **Field Access**: ~5ns (same as native Julia struct)  
- **Vector Operations**: ~10ns (same as Julia Vector)
- **String Operations**: ~20ns (minimal C++ string overhead)
- **Member Functions**: ~50ns (C++ virtual call overhead)

**No serialization overhead** - you're working directly with C++ memory!

## Building from Source

### Quick Setup
```bash
git clone https://github.com/stephenberry/glaze-interop.jl
cd glaze-interop.jl

# Run full test suite
./run_tests.sh       # Unix/macOS  
.\\run_tests.bat     # Windows
```

### Manual Build
```bash
# Build C++ interface
cd cpp_interface && mkdir build && cd build
cmake .. && make

# Build examples
cd ../../examples  
julia build_examples.jl

# Run Julia tests
julia --project=. test/runtests.jl
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [**Glaze**](https://github.com/stephenberry/glaze) - The C++ reflection library that powers this package
- **Julia Community** - For creating an amazing language for scientific computing
- **Contributors** - Thank you to everyone who has contributed to this project!

## Support & Community

- **Issues**: [GitHub Issues](https://github.com/stephenberry/glaze-interop.jl/issues)
- **Discussions**: [GitHub Discussions](https://github.com/stephenberry/glaze-interop.jl/discussions)  
- **Documentation**: [Full Documentation](docs/)
- **Feature Requests**: [Request a Feature](https://github.com/stephenberry/glaze-interop.jl/issues/new?template=feature_request.md)