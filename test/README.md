# Glaze.jl Test Suite

This directory contains the comprehensive test suite for Glaze.jl.

## Test Organization

### Core Tests (`runtests.jl`)
The main test runner that executes all test suites.

### Type System Tests
- `test_all_types.cpp/jl` - Tests for all supported C++ types
- `test_structs_glaze_simple.cpp/jl` - Simple struct tests
- `test_nested_structs.cpp/jl` - Nested structure tests
- `test_array_interface.jl` - Array view and interface tests
- `test_complex_vectors.jl` - Comprehensive complex vector tests

### Container Tests
- `test_map_types.hpp` - Map container type definitions (for future implementation)
- Vector and string tests integrated in `test_all_types`

### Subdirectories

#### `benchmarks/`
Performance benchmarking scripts:
- `benchmark_iteration.cpp/jl` - Iteration performance tests
- `simple_iteration_benchmark.jl` - Simple iteration benchmarks

#### `utils/`
Utility scripts for testing:
- `verify_julia_sizes.jl` - Ensures Julia struct sizes match C++
- `verify_struct_sizes.cpp` - C++ side size verification

#### `integration/`
Tests requiring separate build processes:
- `test_generic_nested.cpp/jl` - Generic nested type tests
- `CMakeLists_nested.txt` - Build configuration for nested tests
- `build_and_test_nested.sh` - Build script for nested tests

#### `build/`
CMake build artifacts and compiled libraries

## Running Tests

### All Tests
```bash
julia --project=.. runtests.jl
```

### Individual Test Sets
```julia
julia --project=.. -e 'include("test_all_types.jl")'
```

### C++ Build Tests
The C++ components are built automatically by the test scripts.

## Writing New Tests

1. Create test files following the naming convention `test_*.jl`
2. Add C++ components to `test_*.cpp` with corresponding headers
3. Include the new tests in `runtests.jl`
4. Ensure tests are self-contained and clean up after themselves

## Test Requirements

- Julia 1.6+
- C++23 compatible compiler
- CMake 3.20+
- Glaze C++ library (fetched automatically)