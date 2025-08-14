# Type definitions and descriptors for Glaze.jl
using Base: RefValue

# Type descriptor kinds
const TypeKind = UInt64
const GLZ_TYPE_PRIMITIVE = UInt64(0)
const GLZ_TYPE_STRING = UInt64(1)
const GLZ_TYPE_VECTOR = UInt64(2)
const GLZ_TYPE_MAP = UInt64(3)
const GLZ_TYPE_COMPLEX = UInt64(4)
const GLZ_TYPE_STRUCT = UInt64(5)
const GLZ_TYPE_OPTIONAL = UInt64(6)
const GLZ_TYPE_FUNCTION = UInt64(7)
const GLZ_TYPE_SHARED_FUTURE = UInt64(8)
const GLZ_TYPE_VARIANT = UInt64(9)

# Member kinds (matching C++ MemberKind enum)
@enum MemberKind::UInt8 begin
    DATA_MEMBER = 0
    MEMBER_FUNCTION = 1
end

# Forward declarations
abstract type TypeDescriptor end
abstract type TypeInfo end

# Structs for type descriptor components
struct PrimitiveDesc
    kind::UInt64  # Now uint64_t in C++ for alignment
end

struct StringDesc
    is_view::UInt8  # 0 for string, 1 for string_view
    padding::NTuple{7, UInt8}  # Padding to 8 bytes for alignment
end

struct VectorDesc
    element_type::Ptr{TypeDescriptor}
end

struct MapDesc
    key_type::Ptr{TypeDescriptor}
    value_type::Ptr{TypeDescriptor}
end

struct ComplexDesc
    kind::UInt64  # 0 for float, 1 for double (now uint64_t for alignment)
end

struct OptionalDesc
    element_type::Ptr{TypeDescriptor}
end

struct StructDesc
    type_name::Ptr{UInt8}
    info::Ptr{TypeInfo}
    type_hash::UInt64  # C++ size_t is 64-bit on 64-bit systems
end

struct FunctionDesc
    is_const::UInt8
    param_count::UInt8
    padding::NTuple{6, UInt8}  # Explicit padding to align to 8 bytes
    param_types::Ptr{Ptr{TypeDescriptor}}
    return_type::Ptr{TypeDescriptor}
    function_ptr::Ptr{Cvoid}
end

# PairDesc removed - pairs are now handled as structs

struct SharedFutureDesc
    value_type::Ptr{TypeDescriptor}
end

struct VariantDesc
    count::UInt64                           # Number of alternative types
    current_index::UInt64                   # Currently active alternative (runtime use)
    alternatives::Ptr{Ptr{TypeDescriptor}}  # Array of type descriptors for each alternative
end

# The actual type descriptor definition with union
# C++ struct is now 40 bytes (8 for index + 32 for union)
# Largest union member is glz_function_desc at 32 bytes
mutable struct ConcreteTypeDescriptor <: TypeDescriptor
    index::TypeKind  # UInt64 (8 bytes)
    data::NTuple{32, UInt8}  # Union data (32 bytes for largest member)
end

# MemberInfo struct - matches C++ layout with explicit padding (48 bytes total)
struct MemberInfo
    name::Ptr{UInt8}          # offset 0
    type::Ptr{TypeDescriptor}  # offset 8
    getter::Ptr{Cvoid}         # offset 16
    setter::Ptr{Cvoid}         # offset 24
    kind::UInt8                # offset 32
    padding::NTuple{7, UInt8}  # offset 33 - explicit padding to align next pointer
    function_ptr::Ptr{Cvoid}   # offset 40
end

struct ConcreteTypeInfo <: TypeInfo
    name::Ptr{UInt8}
    size::Csize_t
    member_count::Csize_t
    members::Ptr{MemberInfo}
end

# Generic vector view structure - matches C++ glz_vector
struct VectorView
    data::Ptr{Cvoid}  # void* in C++
    size::Csize_t
    capacity::Csize_t
end

struct StringView
    data::Ptr{UInt8}
    size::Csize_t
    capacity::Csize_t
end

mutable struct CppString <: AbstractString
    ptr::Ptr{Cvoid}
    lib::Ptr{Cvoid}
end

"""
    CppSharedFuture

Julia wrapper for C++ std::shared_future. Provides access to asynchronous values
computed in C++ code.

# Fields
- `ptr`: Pointer to the C++ shared_future object
- `value_type`: Type descriptor for the future's value type
- `lib_handle`: Handle to the C++ library

# Usage
```julia
future = get_future_returning_function()
if is_ready(future)
    value = get(future)
end
```
"""
mutable struct CppSharedFuture
    ptr::Ptr{Cvoid}
    lib_handle::Ptr{Cvoid}
    
    function CppSharedFuture(ptr::Ptr{Cvoid}, lib_handle::Ptr{Cvoid})
        obj = new(ptr, lib_handle)
        # Register finalizer to clean up the heap-allocated shared_future
        finalizer(obj) do future
            if future.ptr != C_NULL
                func = Libdl.dlsym(future.lib_handle, :glz_shared_future_destroy)
                ccall(func, Cvoid, (Ptr{Cvoid}, Ptr{TypeDescriptor}), future.ptr, C_NULL)
            end
        end
        return obj
    end
end

"""
    CppMemberFunction

Julia wrapper for C++ member function pointers. This type represents a callable
member function that can be invoked with appropriate arguments.

# Usage

```julia
# Assuming obj is a CppStruct with member functions
result = obj.add(5.0)  # Calls the 'add' member function with argument 5.0
obj.reset()            # Calls the 'reset' member function with no arguments
```
"""
mutable struct CppMemberFunction
    obj_ptr::Ptr{Cvoid}
    member_info::Ptr{MemberInfo}
    lib_handle::Ptr{Cvoid}
    name::String
    type_name::String
end

"""
    CppOptional{T}

Julia wrapper for C++ std::optional<T> types.

# Idiomatic Usage

```julia
# Check if optional is empty
if isnothing(opt)
    println("Optional is empty")
end

# Check if optional has a value
if !isnothing(opt)
    println("Value: ", value(opt))
end

# Compare with nothing (use == not ===)
if opt == nothing
    println("Optional is empty")
end

# Get value with default
result = something(opt, "default")

# Check if empty (container-style)  
if isempty(opt)
    println("No value present")
end

# Get length (0 or 1)
n = length(opt)

# Get the contained value (throws if empty)
val = value(opt)
```

# Fields
- `ptr`: Pointer to the C++ std::optional object
- `lib`: Handle to the library containing the optional
- `element_type_desc`: Type descriptor for the contained type
"""
mutable struct CppOptional{T}
    ptr::Ptr{Cvoid}
    lib::Ptr{Cvoid}
    element_type_desc::Ptr{TypeDescriptor}
end

# Generic vector wrapper type
mutable struct CppVector
    ptr::Ptr{Cvoid}
    lib::Ptr{Cvoid}
    type_desc::Ptr{TypeDescriptor}
end

# Specialized vector types for common cases
mutable struct CppVectorFloat32
    ptr::Ptr{Cvoid}
    lib::Ptr{Cvoid}
end

mutable struct CppVectorFloat64
    ptr::Ptr{Cvoid}
    lib::Ptr{Cvoid}
end

mutable struct CppVectorInt32
    ptr::Ptr{Cvoid}
    lib::Ptr{Cvoid}
end

mutable struct CppVectorComplexF32
    ptr::Ptr{Cvoid}
    lib::Ptr{Cvoid}
end

mutable struct CppVectorComplexF64
    ptr::Ptr{Cvoid}
    lib::Ptr{Cvoid}
end

"""
    CppVariant

Julia wrapper for C++ std::variant types. Represents a type-safe union that can
hold one value from a fixed set of alternative types.

# Fields
- `ptr`: Pointer to the C++ std::variant object
- `lib`: Handle to the library containing the variant
- `type_desc`: Type descriptor containing variant metadata

# Usage
```julia
# Get the currently active alternative index (0-based)
idx = index(variant)

# Get the current value
val = get_value(variant)

# Set the variant to a specific alternative
set_value!(variant, 1, "string value")

# Check if a specific alternative is active
if holds_alternative(variant, 0)
    println("First alternative is active")
end
```
"""
mutable struct CppVariant
    ptr::Ptr{Cvoid}
    lib::Ptr{Cvoid}
    type_desc::Ptr{TypeDescriptor}
end

# Helper to get type descriptor data
function get_type_desc_data(desc::Ptr{TypeDescriptor}, ::Type{T}) where T
    if desc == C_NULL
        return nothing
    end
    td = unsafe_load(Ptr{ConcreteTypeDescriptor}(desc))
    return reinterpret(T, td.data)
end

