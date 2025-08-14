# Getting Started with Glaze-interop.jl

This guide will walk you through setting up and using Glaze-interop.jl for the first time, from installation to building your first C++/Julia integration.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Your First Project](#your-first-project)
4. [Understanding the Basics](#understanding-the-basics)
5. [Common Patterns](#common-patterns)
6. [Next Steps](#next-steps)

## Prerequisites

Before starting, ensure you have:

### Required Software
- **Julia** ≥ 1.6 ([Download Julia](https://julialang.org/downloads/))
- **C++23 Compiler**:
  - GCC 12+ or Clang 15+ (Linux/macOS)
  - MSVC 2022+ (Windows)
- **CMake** ≥ 3.20 ([Download CMake](https://cmake.org/download/))

### Verify Your Setup
```bash
# Check Julia version
julia --version  # Should be ≥ 1.6

# Check C++ compiler
g++ --version    # Should support C++23
clang++ --version

# Check CMake
cmake --version  # Should be ≥ 3.20
```

## Installation

### Install Glaze-interop.jl

Open Julia and install the package:

```julia
using Pkg
Pkg.add(url="https://github.com/stephenberry/glaze-interop.jl")
```

### Verify Installation

```julia
using Glaze
println("Glaze-interop.jl successfully installed!")
```

## Your First Project

Let's create a simple project that demonstrates basic C++/Julia interoperability.

### Step 1: Create Project Structure

```bash
mkdir my_glaze_project
cd my_glaze_project
mkdir src
```

### Step 2: Define Your C++ Types

Create `src/calculator.hpp`:

```cpp
#pragma once
#include <glaze/interop/interop.hpp>
#include <vector>
#include <string>
#include <numeric>

struct Calculator {
    std::string name;
    std::vector<double> values;
    
    // Constructor
    Calculator(const std::string& calc_name = "DefaultCalculator") 
        : name(calc_name) {}
    
    // Member functions
    void add_value(double val) {
        values.push_back(val);
    }
    
    double sum() const {
        return std::accumulate(values.begin(), values.end(), 0.0);
    }
    
    double average() const {
        if (values.empty()) return 0.0;
        return sum() / values.size();
    }
    
    size_t count() const {
        return values.size();
    }
};

// Glaze reflection - tells Glaze about your struct
template <>
struct glz::meta<Calculator> {
    using T = Calculator;
    static constexpr auto value = glz::object(
        "name", &T::name,
        "values", &T::values,
        "add_value", &T::add_value,
        "sum", &T::sum,
        "average", &T::average,
        "count", &T::count
    );
};
```

### Step 3: Implement Your C++ Library

Create `src/calculator.cpp`:

```cpp
#include "calculator.hpp"

// Create global instances
Calculator global_calc("GlobalCalculator");
Calculator work_calc("WorkCalculator");

// Initialization function - called from Julia
extern "C" {
    void init_calculator() {
        // Register types with Glaze
        glz::register_type<Calculator>("Calculator");
        
        // Register global instances
        glz::register_instance("global_calc", global_calc);
        glz::register_instance("work_calc", work_calc);
        
        // Initialize with some test data
        global_calc.add_value(10.5);
        global_calc.add_value(20.3);
        global_calc.add_value(15.7);
        
        work_calc.add_value(5.0);
        work_calc.add_value(10.0);
    }
}
```

### Step 4: Build Your Library

Create a `CMakeLists.txt`:

```cmake
cmake_minimum_required(VERSION 3.20)
project(CalculatorDemo CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find Glaze
include(FetchContent)
FetchContent_Declare(
    glaze
    GIT_REPOSITORY https://github.com/stephenberry/glaze.git
    GIT_TAG main
)
FetchContent_MakeAvailable(glaze)

# Build your library (Glaze interop is header-only)
add_library(calculator_demo SHARED
    src/calculator.cpp
)

target_include_directories(calculator_demo PRIVATE 
    src
)

target_link_libraries(calculator_demo PUBLIC glaze::glaze)

# Platform-specific settings
set_target_properties(calculator_demo PROPERTIES
    POSITION_INDEPENDENT_CODE ON
    CXX_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN ON
)

if(WIN32)
    target_compile_definitions(calculator_demo PRIVATE GLZ_EXPORTS)
endif()
```

Build it:

```bash
mkdir build && cd build
cmake ..
make  # or: cmake --build . on Windows
```

### Step 5: Use from Julia

Create `demo.jl`:

```julia
using Glaze

# Load your compiled library
lib_path = "build/libcalculator_demo.so"  # Use .dll on Windows, .dylib on macOS
lib = Glaze.CppLibrary(lib_path)

# Initialize your types
ccall((:init_calculator, lib.handle), Cvoid, ())

# Access global instances
global_calc = Glaze.get_instance(lib, "global_calc")
work_calc = Glaze.get_instance(lib, "work_calc")

# Basic field access
println("Global calculator name: $(global_calc.name)")
println("Number of values: $(length(global_calc.values))")

# Access vector elements
println("Values: ")
for (i, val) in enumerate(global_calc.values)
    println("  [$i]: $val")
end

# Call member functions
println("Sum: $(global_calc.sum())")
println("Average: $(global_calc.average())")

# Modify data
println("\\nAdding new values...")
global_calc.add_value(25.5)
push!(global_calc.values, 30.0)  # Direct vector access

println("New sum: $(global_calc.sum())")
println("New average: $(global_calc.average())")
println("Total count: $(global_calc.count())")

# Create new instances
println("\\nCreating new calculator...")
my_calc = lib.Calculator
my_calc.name = "MyCalculator"
push!(my_calc.values, 100.0)
push!(my_calc.values, 200.0)
push!(my_calc.values, 300.0)

println("My calculator sum: $(my_calc.sum())")

# Pretty printing
println("\\nPretty printing:")
println(global_calc)
```

Run it:

```bash
julia demo.jl
```

Expected output:
```
Global calculator name: GlobalCalculator
Number of values: 3
Values: 
  [1]: 10.5
  [2]: 20.3
  [3]: 15.7

Sum: 46.5
Average: 15.5

Adding new values...
New sum: 102.0
New average: 20.4
Total count: 5

Creating new calculator...
My calculator sum: 600.0

Pretty printing:
Calculator {
  name: "GlobalCalculator",
  values: [10.5, 20.3, 15.7, 25.5, 30.0]
}
```

## Understanding the Basics

### 1. Glaze Reflection

The key to Glaze.jl is the reflection system. For every C++ struct you want to access from Julia, you need a `glz::meta` specialization:

```cpp
template <>
struct glz::meta<YourStruct> {
    using T = YourStruct;
    static constexpr auto value = glz::object(
        "field_name", &T::field_name,
        "method_name", &T::method_name
        // ... more fields and methods
    );
};
```

**Key Points:**
- This is **compile-time** reflection - no runtime overhead
- Field names in quotes become the Julia field names
- Both data members and member functions can be registered
- The order doesn't matter

### 2. Type Registration

In your initialization function, register your types:

```cpp
extern "C" {
    void init_my_types() {
        glz::register_type<MyStruct>("MyStruct");
        glz::register_instance("instance_name", my_instance);
    }
}
```

### 3. Julia Side Usage

From Julia:
1. Load library: `lib = Glaze.CppLibrary("path/to/lib.so")`
2. Initialize: `ccall((:init_function, lib.handle), Cvoid, ())`
3. Access instances: `obj = Glaze.get_instance(lib, "instance_name")`
4. Create new instances: `obj = lib.TypeName`

### 4. Data Access Patterns

```julia
# Direct field access (zero-copy)
obj.field = new_value

# Vector operations
push!(obj.vector_field, new_element)
obj.vector_field[1] = modified_value

# String operations (CppString supports full AbstractString interface)
obj.string_field == "comparison"
length(obj.string_field)
"Interpolation: $(obj.string_field)"

# Member function calls
result = obj.method_name(arg1, arg2)
```

## Common Patterns

### Pattern 1: Configuration Objects

```cpp
struct Config {
    std::string app_name;
    int max_connections;
    double timeout_seconds;
    std::vector<std::string> allowed_hosts;
    bool debug_mode;
};
```

```julia
config = lib.Config
config.app_name = "MyApp"
config.max_connections = 100
config.timeout_seconds = 30.0
push!(config.allowed_hosts, "localhost")
push!(config.allowed_hosts, "192.168.1.1")
config.debug_mode = true
```

### Pattern 2: Data Processing Pipeline

```cpp
struct DataProcessor {
    std::vector<double> input_data;
    std::vector<double> output_data;
    
    void process() {
        output_data.clear();
        for (double val : input_data) {
            output_data.push_back(val * 2.0 + 1.0);  // Example processing
        }
    }
    
    double get_average_output() const {
        if (output_data.empty()) return 0.0;
        double sum = std::accumulate(output_data.begin(), output_data.end(), 0.0);
        return sum / output_data.size();
    }
};
```

```julia
processor = lib.DataProcessor

# Load data from Julia
data = [1.0, 2.0, 3.0, 4.0, 5.0]
for val in data
    push!(processor.input_data, val)
end

# Process in C++
processor.process()

# Get results
avg = processor.get_average_output()
println("Average output: $avg")

# Access processed data
for val in processor.output_data
    println("Processed: $val")
end
```

### Pattern 3: Nested Structures

```cpp
struct Point {
    double x, y, z;
};

struct Geometry {
    std::string name;
    std::vector<Point> vertices;
    
    double total_distance() const {
        double dist = 0.0;
        for (size_t i = 1; i < vertices.size(); ++i) {
            double dx = vertices[i].x - vertices[i-1].x;
            double dy = vertices[i].y - vertices[i-1].y;
            double dz = vertices[i].z - vertices[i-1].z;
            dist += std::sqrt(dx*dx + dy*dy + dz*dz);
        }
        return dist;
    }
};
```

```julia
geom = lib.Geometry
geom.name = "Path"

# Add points
for i in 1:5
    point = lib.Point
    point.x = float(i)
    point.y = float(i^2)
    point.z = 0.0
    push!(geom.vertices, point)
end

# Calculate in C++
dist = geom.total_distance()
println("Total distance: $dist")

# Access nested data
for (i, vertex) in enumerate(geom.vertices)
    println("Point $i: ($(vertex.x), $(vertex.y), $(vertex.z))")
end
```

## Next Steps

Now that you've got the basics working, explore more advanced features:

### 1. **Advanced Types**
- Read [Type System Guide](type_system.md) for complex types
- Learn about `std::optional`, `std::complex`, `std::shared_future`

### 2. **Performance Optimization**
- Read [Advanced Usage](advanced_usage.md) for performance tips
- Learn about array interfaces and zero-copy operations

### 3. **Real Examples**
- Explore the [`examples/`](../examples/) directory
- Try the complex nested structure examples

### 4. **Integration Patterns**
- Learn about memory management best practices
- Understand lifetime and ownership patterns

### 5. **Troubleshooting**
- Read [Troubleshooting Guide](troubleshooting.md) for common issues
- Learn debugging techniques for C++/Julia interaction

## Quick Reference

### Essential Commands
```julia
# Library management
lib = Glaze.CppLibrary("path/to/lib.so")
ccall((:init_function, lib.handle), Cvoid, ())

# Instance access
instance = Glaze.get_instance(lib, "instance_name")
new_obj = lib.TypeName

# Data access
obj.field = value                    # Direct field access
push!(obj.vector_field, element)    # Vector operations  
result = obj.method(args...)         # Member function calls
```

### Build Commands
```bash
# CMake build
mkdir build && cd build
cmake .. && make

# Manual build
g++ -std=c++23 -shared -fPIC -o lib.so src.cpp -I/path/to/glaze/include
```

### Debugging Tips
```julia
# Check what types are available
println(keys(lib.types))

# Inspect an object
println(typeof(obj))
println(obj)  # Pretty printing

# Vector debugging
println("Length: $(length(obj.vector_field))")
println("Contents: $(collect(obj.vector_field))")
```

---

**🎉 Congratulations!** You now have a working Glaze-interop.jl setup. Start building your own C++/Julia integrations!