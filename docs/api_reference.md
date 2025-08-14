# Glaze.jl API Reference

Complete reference for all public APIs in Glaze.jl.

## Table of Contents

1. [Core Types](#core-types)
2. [Library Management](#library-management)
3. [Instance Management](#instance-management)
4. [Container Types](#container-types)
5. [String Types](#string-types)
6. [Optional Types](#optional-types)
7. [Variant Types](#variant-types)
8. [Async Types](#async-types)
9. [Member Functions](#member-functions)
10. [Utility Functions](#utility-functions)
11. [Macros](#macros)

## Core Types

### `CppLibrary`

Represents a loaded C++ shared library.

```julia
CppLibrary(path::String)
```

**Arguments:**
- `path`: Path to the shared library (.so, .dll, .dylib)

**Fields:**
- `handle::Ptr{Cvoid}`: Handle to the loaded library
- `path::String`: Path to the library file

**Example:**
```julia
lib = Glaze.CppLibrary("./mylib.so")
```

### `CppStruct`

Wrapper for C++ struct instances accessed from Julia.

**Fields:**
- `ptr::Ptr{Cvoid}`: Pointer to the C++ object
- `info::ConcreteTypeInfo`: Type information
- `lib::Ptr{Cvoid}`: Library handle
- `owned::Bool`: Whether Julia owns the memory

**Note:** Typically created through `get_instance()` or `lib.TypeName`, not directly constructed.

## Library Management

### `CppLibrary`

```julia
CppLibrary(library_path::String) -> CppLibrary
```

Load a C++ shared library and create a library wrapper.

**Arguments:**
- `library_path`: Path to the shared library

**Returns:** `CppLibrary` instance

**Example:**
```julia
lib = Glaze.CppLibrary("./build/libmyproject.so")

# Initialize types (call your init function)
ccall((:init_my_types, lib.handle), Cvoid, ())
```

### Property Access on CppLibrary

Access registered C++ types as properties:

```julia
lib.TypeName  # Creates new instance of TypeName
```

**Example:**
```julia
person = lib.Person      # Creates new Person instance
calc = lib.Calculator    # Creates new Calculator instance
```

## Instance Management

### `get_instance`

```julia
get_instance(lib::CppLibrary, instance_name::String) -> CppStruct
```

Get a registered global C++ instance.

**Arguments:**
- `lib`: The loaded library
- `instance_name`: Name of the registered instance

**Returns:** `CppStruct` wrapper for the C++ instance

**Example:**
```julia
global_config = Glaze.get_instance(lib, "global_config")
```

### Field Access

Access and modify C++ struct fields directly:

```julia
# Get field value
value = obj.field_name

# Set field value  
obj.field_name = new_value
```

**Supported Field Types:**
- Primitive types: `bool`, `int8`, `int16`, `int32`, `int64`, `uint8`, `uint16`, `uint32`, `uint64`, `float32`, `float64`
- Strings: `CppString`
- Vectors: `CppVector`, `CppVectorFloat32`, `CppVectorFloat64`, etc.
- Nested structs: `CppStruct`
- Complex numbers: `Complex{Float32}`, `Complex{Float64}`
- Optional types: `CppOptional`
- Member functions: `CppMemberFunction`

## Container Types

### `CppVector`

Julia wrapper for `std::vector<T>`.

**Array-like Interface:**
```julia
# Length
length(vec)

# Element access
vec[i]                    # Get element (1-indexed)
vec[i] = value           # Set element

# Iteration
for element in vec
    println(element)
end

# Modification
push!(vec, element)      # Add element
resize!(vec, new_size)   # Resize vector

# Collection
collect(vec)             # Convert to Julia Array
```

**Specialized Vector Types:**
- `CppVectorFloat32` - `std::vector<float>`
- `CppVectorFloat64` - `std::vector<double>`  
- `CppVectorInt32` - `std::vector<int32_t>`
- `CppVectorComplexF32` - `std::vector<std::complex<float>>`
- `CppVectorComplexF64` - `std::vector<std::complex<double>>`

**Example:**
```julia
# Access C++ std::vector<double>
data_vec = obj.data_points
println("Length: $(length(data_vec))")

# Add elements
push!(data_vec, 3.14)
push!(data_vec, 2.71)

# Modify elements
data_vec[1] = 1.41

# Iterate
for (i, val) in enumerate(data_vec)
    println("[$i]: $val")
end
```

### `CppArrayView`

Read-only view into C++ array data.

```julia
array_view(cpp_vector) -> CppArrayView
```

Provides zero-copy read access to underlying C++ memory.

**Interface:**
```julia
# Length
length(view)

# Element access (read-only)
view[i]

# Iteration
for element in view
    println(element)
end

# Conversion
collect(view)  # Copy to Julia Array
```

**Example:**
```julia
view = array_view(obj.large_dataset)
sum_val = sum(view)  # Efficient summation without copying
```

## String Types

### `CppString`

Julia wrapper for `std::string` that inherits from `AbstractString`.

**AbstractString Interface:**
All standard Julia string operations work:

```julia
# Length and indexing
length(str)              # String length
str[i]                   # Character at position i (1-indexed)  
str[range]               # Substring

# Comparisons
str == "other"           # Equality
str != "other"           # Inequality

# String operations
startswith(str, prefix)   # Check prefix
endswith(str, suffix)     # Check suffix
contains(str, substr)     # Check substring

# Case operations
uppercase(str)           # Convert to uppercase
lowercase(str)           # Convert to lowercase

# Iteration
for char in str
    println(char)
end

# String interpolation
"Hello $(str)!"          # Works naturally

# Conversion
String(str)              # Convert to Julia String
```

**Modification:**
```julia
# Assignment (modifies C++ string)
obj.string_field = "new value"

# Direct assignment to CppString
cpp_str[] = "new value"  # Using setindex!
```

**Example:**
```julia
person = get_instance(lib, "person")

# All of these work naturally:
if person.name == "Alice"
    println("Hello $(person.name)!")
    println("Name length: $(length(person.name))")
    
    if startswith(person.name, "Al")
        person.name = uppercase(person.name)
    end
end
```

## Optional Types

### `CppOptional{T}`

Julia wrapper for `std::optional<T>`.

**Methods:**

#### `hasvalue`
```julia
hasvalue(opt::CppOptional) -> Bool
```
Check if the optional contains a value.

#### `value`
```julia
value(opt::CppOptional{T}) -> T
```
Extract the value from the optional. Throws if no value present.

#### `set_value!`
```julia
set_value!(opt::CppOptional, val)
```
Set the optional to contain the given value.

#### `reset!`
```julia
reset!(opt::CppOptional)
```
Clear the optional (set to no value).

**Example:**
```julia
config = get_instance(lib, "config")

# Check if optional field has value
if hasvalue(config.optional_timeout)
    timeout = value(config.optional_timeout)
    println("Timeout: $timeout seconds")
else
    println("No timeout specified")
end

# Set optional value
set_value!(config.optional_timeout, 30.0)

# Clear optional
reset!(config.optional_timeout)
```

## Variant Types

### `CppVariant`

Julia wrapper for C++ `std::variant<Ts...>` types, providing type-safe access to variant values.

**Fields:**
- `ptr::Ptr{Cvoid}`: Pointer to the C++ variant object
- `lib::Ptr{Cvoid}`: Library handle
- `type_desc::Ptr{TypeDescriptor}`: Type descriptor for the variant

**Note:** Direct variant operations are currently accessed through C++ member functions. The variant wrapper ensures type safety and proper memory management.

**Common Usage Pattern:**

Since direct Julia variant operations are not yet fully implemented, variants are typically accessed through C++ member functions:

```julia
# C++ std::variant<int, double, std::string>
container = lib.VariantContainer

# Set to different types via member functions
container.set_simple_to_int(42)
index = container.get_simple_index()  # Returns 0 (first alternative)

container.set_simple_to_double(3.14159)
index = container.get_simple_index()  # Returns 1 (second alternative)

container.set_simple_to_string("hello")
index = container.get_simple_index()  # Returns 2 (third alternative)

# Access the variant object itself
variant = container.simple_var
@test isa(variant, Glaze.CppVariant)
```

**Example with Struct Types:**

```julia
# C++ std::variant<Point2D, Point3D, Color>
container.set_geometry_to_point2d(1.5f0, 2.5f0)
container.set_geometry_to_point3d(1.0f0, 2.0f0, 3.0f0)
container.set_geometry_to_color(UInt8(255), UInt8(128), UInt8(64))

# Check current type
current_type = container.get_geometry_index()
```

## Async Types

### `CppSharedFuture`

Julia wrapper for `std::shared_future<T>`.

**Methods:**

#### `isready`
```julia
isready(future::CppSharedFuture) -> Bool
```
Check if the future result is ready.

#### `isvalid`
```julia
isvalid(future::CppSharedFuture) -> Bool
```
Check if the future is valid.

#### `wait`
```julia
wait(future::CppSharedFuture)
```
Wait for the future to complete (blocking).

#### `get`
```julia
get(future::CppSharedFuture) -> T
```
Get the result value. Blocks if not ready. Returns zero-copy access to the result.

**Example:**
```julia
# C++ function returns std::shared_future<Person>
future = service.getPersonAsync("Alice", 30, 1000)  # 1 second delay

# Non-blocking check
if isready(future)
    person = get(future)
    println("Got person: $(person.name)")
else
    println("Still computing...")
    
    # Wait for completion
    wait(future)
    person = get(future)
    println("Person ready: $(person.name)")
end
```

## Member Functions

### `CppMemberFunction`

Wrapper for C++ member functions that can be called from Julia.

**Fields:**
- `name::String`: Function name
- `obj_ptr::Ptr{Cvoid}`: Pointer to the C++ object
- `lib_handle::Ptr{Cvoid}`: Library handle

**Calling:**
```julia
# Direct call
result = obj.method_name(arg1, arg2, ...)

# Or access function object first
func = obj.method_name
result = func(arg1, arg2, ...)
```

**Parameter Type Detection:**
Function parameters are automatically converted based on the C++ function signature:
- Julia `Int` → C++ `int32_t`, `int64_t` (as appropriate)
- Julia `Float64` → C++ `double`
- Julia `Float32` → C++ `float`
- Julia `String` → C++ `const char*`
- Julia `Bool` → C++ `bool`

**Example:**
```julia
calculator = get_instance(lib, "calculator") 

# Call member functions
result = calculator.add(5.0, 3.0)
calculator.reset()
average = calculator.get_average()

# Access function object
add_func = calculator.add
result = add_func(10.0, 20.0)
```

## Utility Functions

### `copy!`
```julia
copy!(dest::CppStruct, src::CppStruct)
```
Deep copy all data members from source to destination struct.

**Example:**
```julia
person1 = lib.Person
person2 = lib.Person

person1.name = "Alice"
person1.age = 30

copy!(person2, person1)  # person2 now has same data
```

### Pretty Printing

All Glaze.jl types support Julia's pretty printing:

```julia
# Automatic pretty printing
println(obj)

# Custom formatting
show(io, obj)
```

**Output Format:**
```julia
StructName {
  field1: value1,
  field2: value2,
  nested_field: NestedStruct {
    nested_value: 42
  },
  vector_field: [1.0, 2.0, 3.0]
}
```

## Macros

### `@assign`

```julia
Glaze.@assign dest = src
```

Syntactic sugar for `copy!(dest, src)`.

**Example:**
```julia
person1 = lib.Person
person2 = lib.Person

person1.name = "Bob"
Glaze.@assign person2 = person1  # Equivalent to copy!(person2, person1)
```

## Type Conversion Reference

### C++ to Julia Type Mapping

| C++ Type | Julia Type | Notes |
|----------|------------|-------|
| `bool` | `Bool` | Direct mapping |
| `int8_t` | `Int8` | Direct mapping |
| `int16_t` | `Int16` | Direct mapping |
| `int32_t` | `Int32` | Direct mapping |
| `int64_t` | `Int64` | Direct mapping |
| `uint8_t` | `UInt8` | Direct mapping |
| `uint16_t` | `UInt16` | Direct mapping |
| `uint32_t` | `UInt32` | Direct mapping |
| `uint64_t` | `UInt64` | Direct mapping |
| `float` | `Float32` | Direct mapping |
| `double` | `Float64` | Direct mapping |
| `std::string` | `CppString <: AbstractString` | Full string interface |
| `std::vector<T>` | `CppVector` | Array-like interface |
| `std::complex<float>` | `Complex{Float32}` | Native Julia complex |
| `std::complex<double>` | `Complex{Float64}` | Native Julia complex |
| `std::optional<T>` | `CppOptional{T}` | Optional wrapper |
| `std::shared_future<T>` | `CppSharedFuture` | Async wrapper |
| User structs | `CppStruct` | Reflection-based access |
| Member functions | `CppMemberFunction` | Callable wrapper |

### Function Parameter Conversion

When calling C++ member functions, Julia values are automatically converted:

| Julia Input | C++ Parameter Types (accepted) |
|-------------|--------------------------------|
| `Int64` | `int8_t`, `int16_t`, `int32_t`, `int64_t`, `float`, `double` |
| `Float64` | `float`, `double` |
| `Float32` | `float` |
| `String` | `const char*`, `std::string`, `std::string_view` |
| `Bool` | `bool` |

## Error Handling

### Common Exceptions

- **`ErrorException`**: General Glaze.jl errors
- **`BoundsError`**: Array/vector index out of bounds
- **`ArgumentError`**: Invalid function arguments
- **`SystemError`**: Library loading failures

### Error Messages

Glaze.jl provides descriptive error messages:

```julia
# Example errors:
"Cannot set value of member function 'compute'. Member functions are not modifiable."
"Index 5 is out of bounds for vector of length 3"
"Could not find type info for type hash: 12345"
"Invalid shared_future"
```

## Performance Notes

### Zero-Copy Operations
- Field access: Direct memory access, ~5ns
- Vector element access: Direct memory access, ~10ns  
- String operations: Minimal overhead, ~20ns

### Memory Management
- C++ owns all memory
- Julia holds references only
- No garbage collection of C++ objects
- Automatic bounds checking on containers

### Best Practices
- Use `array_view()` for read-only access to large datasets
- Prefer member function calls over repeated field access in loops
- Cache `CppMemberFunction` objects when calling repeatedly

---

This API reference covers all public interfaces in Glaze.jl. For usage examples and patterns, see the [Getting Started Guide](getting_started.md) and [Advanced Usage](advanced_usage.md).