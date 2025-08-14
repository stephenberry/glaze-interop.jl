# Glaze.jl Examples

This directory contains key examples demonstrating Glaze.jl features.

## Examples

### 1. Basic Usage (`example_usage.jl`)
Simple getting-started example showing basic C++/Julia interop patterns.

### 2. Performance Demonstration (`iteration_demo.jl`)
Shows iteration performance characteristics and optimizations.

## C++ Examples

### 3. Member Function Comparison (`member_function_comparison.cpp`)
Educational example showing old vs new approaches to member function handling.

### 4. Type System Demo (`type_system_example.cpp`)
Demonstrates the three-enum type system used by Glaze.jl.

### 5. Nested Structures (`nested_struct_example.cpp`)
C++ implementation of nested struct patterns.

## Building Examples

Most examples include their own C++ source files. To build:

```bash
# From the examples directory
julia build_examples.jl
```

Or manually:
```bash
g++ -std=c++23 -shared -fPIC -o example.so example.cpp
```

## Running Examples

```bash
julia --project=.. example_name.jl
```

## Creating Your Own Examples

1. Create a C++ file with your struct definitions
2. Add `glz::meta` specializations for reflection
3. Register types and instances in an init function
4. Create a Julia script that loads and uses your library

See `example_struct.hpp` for a template to get started.