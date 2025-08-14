"""
    Glaze.jl

A high-performance Julia package for zero-copy interoperability with C++ data structures
using the Glaze reflection library.

# Features
- Zero-copy access to C++ objects
- Support for nested structures
- STL container compatibility (string, vector, map)
- Type-safe operations with compile-time checking

# Basic Usage
```julia
using Glaze

# Load a C++ library
lib = Glaze.load("mylib.so")

# Access a global instance
data = Glaze.get_instance(lib, "instance_name")

# Manipulate fields directly
data.field = value
```

See the package documentation for detailed usage examples.
"""
module Glaze

using Base: RefValue
using Libdl

# Include all modules in dependency order
include("types.jl")
include("library.jl")
include("vectors.jl")
include("variants.jl")
include("strings.jl")

end # module Glaze