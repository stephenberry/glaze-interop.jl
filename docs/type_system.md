# Glaze.jl Type System

## Overview

The Glaze.jl type system uses a three-enumeration approach to describe types, which significantly reduces code duplication and makes the system more extensible.

## The Three Enumerations

### 1. OuterType
The main type category:
- `None` - No type
- `Bool` - Boolean
- `I8`, `I16`, `I32`, `I64` - Signed integers
- `U8`, `U16`, `U32`, `U64` - Unsigned integers
- `F32`, `F64` - Floating point
- `String`, `StringView` - String types
- `Vector` - Vector container
- `UnorderedMap` - Hash map container (planned, not yet implemented)
- `Complex` - Complex number

### 2. KeyType
Used only for map types to specify the key type:
- `None` - Not a map
- `String`, `StringView` - String keys
- `I32`, `I64` - Signed integer keys
- `U32`, `U64` - Unsigned integer keys

### 3. ValueType
Used for containers to specify the element type:
- `None` - Not a container
- All basic types (Bool, I8-I64, U8-U64, F32, F64)
- `String`, `StringView`
- `ComplexF32`, `ComplexF64` - Complex number types

## Examples

### Basic Types
```cpp
int32_t value;        // OuterType=I32, KeyType=None, ValueType=None
double value;         // OuterType=F64, KeyType=None, ValueType=None
bool flag;            // OuterType=Bool, KeyType=None, ValueType=None
std::string name;     // OuterType=String, KeyType=None, ValueType=None
```

### Vector Types
```cpp
std::vector<int32_t> nums;     // OuterType=Vector, KeyType=None, ValueType=I32
std::vector<double> values;    // OuterType=Vector, KeyType=None, ValueType=F64
std::vector<std::string> tags; // OuterType=Vector, KeyType=None, ValueType=String
```

### Complex Types
```cpp
std::complex<float> c1;        // OuterType=Complex, KeyType=None, ValueType=ComplexF32
std::complex<double> c2;       // OuterType=Complex, KeyType=None, ValueType=ComplexF64
std::vector<std::complex<float>> cv; // OuterType=Vector, KeyType=None, ValueType=ComplexF32
```

### Map Types
```cpp
std::unordered_map<std::string, int32_t> lookup;  
// OuterType=UnorderedMap, KeyType=String, ValueType=I32

std::unordered_map<int32_t, double> data;         
// OuterType=UnorderedMap, KeyType=I32, ValueType=F64
```

## Benefits

1. **Reduced Code Duplication**: Instead of having separate enums like `VectorI8`, `VectorI16`, etc., we have one `Vector` OuterType with different ValueTypes.

2. **Easy Extension**: Adding a new container type only requires adding one OuterType enum value. Adding support for a new element type only requires adding one ValueType enum value.

3. **Clear Structure**: The three-part system clearly separates concerns:
   - What kind of type is it? (OuterType)
   - If it's a map, what's the key? (KeyType)
   - If it's a container, what does it contain? (ValueType)

4. **Type Safety**: The C++ template system ensures type decomposition is done at compile time with no runtime overhead.

## Implementation Details

The type decomposition is handled by the `TypeDecomposer` template struct:

```cpp
template<typename T>
struct TypeDecomposer {
    static constexpr OuterType outer = /* determined by specialization */;
    static constexpr KeyType key = /* determined by specialization */;
    static constexpr ValueType value = /* determined by specialization */;
};
```

Specializations exist for all supported types, and the system can be easily extended by adding new specializations.