# Variant support for Glaze.jl - Julia-idiomatic interface

"""
    index(v::CppVariant) -> Int

Get the currently active alternative index (0-based) of the variant.

# Example
```julia
idx = index(variant)  # Returns 0, 1, 2, etc.
```
"""
function index(v::CppVariant)
    idx_func = get_cached_function(v.lib, :glz_variant_index)
    idx = ccall(idx_func, UInt64, (Ptr{Cvoid}, Ptr{TypeDescriptor}), v.ptr, v.type_desc)
    if idx == typemax(UInt64)  # Error indicator from C++
        error("Failed to get variant index")
    end
    return Int(idx)
end

"""
    Base.length(v::CppVariant) -> Int

Get the number of alternative types in the variant.
"""
function Base.length(v::CppVariant)
    if v.type_desc == C_NULL
        return 0
    end
    
    # Load the type descriptor and get the variant descriptor
    type_desc = unsafe_load(Ptr{ConcreteTypeDescriptor}(v.type_desc))
    if type_desc.index != GLZ_TYPE_VARIANT
        error("Type descriptor is not a variant")
    end
    
    # Access the variant descriptor
    variant_desc = unsafe_load(Ptr{VariantDesc}(Ptr{UInt8}(v.type_desc) + fieldoffset(ConcreteTypeDescriptor, 2)))
    return Int(variant_desc.count)
end

"""
    holds_alternative(v::CppVariant, index::Integer) -> Bool

Check if the variant currently holds the alternative at the given index.

# Arguments
- `v`: The variant to check
- `index`: 0-based index of the alternative to check

# Example
```julia
if holds_alternative(variant, 0)
    println("First alternative is active")
end
```
"""
function holds_alternative(v::CppVariant, index::Integer)
    if index < 0 || index >= length(v)
        throw(BoundsError("Variant index $index out of bounds [0, $(length(v)-1)]"))
    end
    
    holds_func = get_cached_function(v.lib, :glz_variant_holds_alternative)
    return ccall(holds_func, Bool, (Ptr{Cvoid}, Ptr{TypeDescriptor}, UInt64), 
                 v.ptr, v.type_desc, UInt64(index))
end

"""
    alternative_type(v::CppVariant, index::Integer) -> Ptr{TypeDescriptor}

Get the type descriptor for the alternative at the given index.

# Arguments
- `v`: The variant
- `index`: 0-based index of the alternative

# Returns
- Pointer to the type descriptor for the alternative type
"""
function alternative_type(v::CppVariant, index::Integer)
    if index < 0 || index >= length(v)
        throw(BoundsError("Variant index $index out of bounds [0, $(length(v)-1)]"))
    end
    
    type_func = get_cached_function(v.lib, :glz_variant_type_at_index)
    type_ptr = ccall(type_func, Ptr{TypeDescriptor}, (Ptr{TypeDescriptor}, UInt64), 
                     v.type_desc, UInt64(index))
    
    if type_ptr == C_NULL
        error("Failed to get alternative type at index $index")
    end
    
    return type_ptr
end

"""
    get_value(v::CppVariant)

Get the current value stored in the variant, converting it to the appropriate Julia type.

# Returns
The current value, with type determined by the active alternative.

# Example
```julia
val = get_value(variant)
if isa(val, String)
    println("Got string: ", val)
elseif isa(val, Int32)
    println("Got integer: ", val)
end
```
"""
function get_value(v::CppVariant)
    # Get pointer to the current value
    get_func = get_cached_function(v.lib, :glz_variant_get)
    value_ptr = ccall(get_func, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{TypeDescriptor}), 
                      v.ptr, v.type_desc)
    
    if value_ptr == C_NULL
        error("Failed to get variant value")
    end
    
    # Get the type of the current alternative
    current_idx = index(v)
    alt_type_desc = alternative_type(v, current_idx)
    
    # Convert based on type descriptor
    return convert_variant_value(value_ptr, alt_type_desc, v.lib)
end

"""
    set_value!(v::CppVariant, index::Integer, value)

Set the variant to hold the alternative at the given index with the specified value.

# Arguments
- `v`: The variant to modify
- `index`: 0-based index of the alternative to activate
- `value`: The value to set (must be compatible with the alternative type)

# Example
```julia
set_value!(variant, 0, Int32(42))      # Set to first alternative (int)
set_value!(variant, 1, "hello")        # Set to second alternative (string)
```
"""
function set_value!(v::CppVariant, index::Integer, value)
    if index < 0 || index >= length(v)
        throw(BoundsError("Variant index $index out of bounds [0, $(length(v)-1)]"))
    end
    
    # Get the type descriptor for the target alternative
    alt_type_desc = alternative_type(v, index)
    alt_type = unsafe_load(Ptr{ConcreteTypeDescriptor}(alt_type_desc))
    
    # Prepare the value based on its type
    value_ptr = prepare_variant_value(value, alt_type_desc, v.lib)
    
    try
        set_func = get_cached_function(v.lib, :glz_variant_set)
        success = ccall(set_func, Bool, (Ptr{Cvoid}, Ptr{TypeDescriptor}, UInt64, Ptr{Cvoid}), 
                       v.ptr, v.type_desc, UInt64(index), value_ptr)
        
        if !success
            error("Failed to set variant value at index $index")
        end
    finally
        # Clean up temporary value if needed
        cleanup_variant_value(value_ptr, alt_type_desc, v.lib)
    end
    
    return nothing
end

# Helper function to convert variant value based on type descriptor
function convert_variant_value(ptr::Ptr{Cvoid}, type_desc::Ptr{TypeDescriptor}, lib::Ptr{Cvoid})
    if type_desc == C_NULL
        error("Null type descriptor in variant value conversion")
    end
    
    td = unsafe_load(Ptr{ConcreteTypeDescriptor}(type_desc))
    
    if td.index == GLZ_TYPE_PRIMITIVE
        prim_desc = unsafe_load(Ptr{PrimitiveDesc}(Ptr{UInt8}(type_desc) + fieldoffset(ConcreteTypeDescriptor, 2)))
        
        if prim_desc.kind == 1  # Bool
            return unsafe_load(Ptr{Bool}(ptr))
        elseif prim_desc.kind == 2  # Int8
            return unsafe_load(Ptr{Int8}(ptr))
        elseif prim_desc.kind == 3  # Int16
            return unsafe_load(Ptr{Int16}(ptr))
        elseif prim_desc.kind == 4  # Int32
            return unsafe_load(Ptr{Int32}(ptr))
        elseif prim_desc.kind == 5  # Int64
            return unsafe_load(Ptr{Int64}(ptr))
        elseif prim_desc.kind == 6  # UInt8
            return unsafe_load(Ptr{UInt8}(ptr))
        elseif prim_desc.kind == 7  # UInt16
            return unsafe_load(Ptr{UInt16}(ptr))
        elseif prim_desc.kind == 8  # UInt32
            return unsafe_load(Ptr{UInt32}(ptr))
        elseif prim_desc.kind == 9  # UInt64
            return unsafe_load(Ptr{UInt64}(ptr))
        elseif prim_desc.kind == 10  # Float32
            return unsafe_load(Ptr{Float32}(ptr))
        elseif prim_desc.kind == 11  # Float64
            return unsafe_load(Ptr{Float64}(ptr))
        else
            error("Unknown primitive type: $(prim_desc.kind)")
        end
    elseif td.index == GLZ_TYPE_STRING
        return CppString(ptr, lib)
    elseif td.index == GLZ_TYPE_COMPLEX
        complex_desc = unsafe_load(Ptr{ComplexDesc}(Ptr{UInt8}(type_desc) + fieldoffset(ConcreteTypeDescriptor, 2)))
        if complex_desc.kind == 0  # float
            return unsafe_load(Ptr{ComplexF32}(ptr))
        else  # double
            return unsafe_load(Ptr{ComplexF64}(ptr))
        end
    elseif td.index == GLZ_TYPE_VECTOR
        # Return a vector wrapper
        data_ptr = Ptr{UInt8}(type_desc) + fieldoffset(ConcreteTypeDescriptor, 2)
        element_ptr = unsafe_load(Ptr{Ptr{TypeDescriptor}}(data_ptr))
        
        elem_td = unsafe_load(Ptr{ConcreteTypeDescriptor}(element_ptr))
        if elem_td.index == GLZ_TYPE_PRIMITIVE
            prim_desc = unsafe_load(Ptr{PrimitiveDesc}(Ptr{UInt8}(element_ptr) + fieldoffset(ConcreteTypeDescriptor, 2)))
            if prim_desc.kind == 10  # F32
                return CppVectorFloat32(ptr, lib)
            elseif prim_desc.kind == 11  # F64
                return CppVectorFloat64(ptr, lib)
            elseif prim_desc.kind == 4  # I32
                return CppVectorInt32(ptr, lib)
            end
        elseif elem_td.index == GLZ_TYPE_COMPLEX
            complex_desc = unsafe_load(Ptr{ComplexDesc}(Ptr{UInt8}(element_ptr) + fieldoffset(ConcreteTypeDescriptor, 2)))
            if complex_desc.kind == 0  # float complex
                return CppVectorComplexF32(ptr, lib)
            else  # double complex
                return CppVectorComplexF64(ptr, lib)
            end
        end
        
        # Fall back to generic vector
        return CppVector(ptr, lib, type_desc)
    elseif td.index == GLZ_TYPE_STRUCT
        # Handle struct types
        struct_desc = unsafe_load(Ptr{StructDesc}(Ptr{UInt8}(type_desc) + fieldoffset(ConcreteTypeDescriptor, 2)))
        
        # Get type info
        if struct_desc.info == C_NULL
            # Try to resolve by hash
            if struct_desc.type_hash != 0
                get_type_info_by_hash_func = get_cached_function(lib, :glz_get_type_info_by_hash)
                info_ptr = ccall(get_type_info_by_hash_func, Ptr{ConcreteTypeInfo}, (UInt64,), struct_desc.type_hash)
                if info_ptr == C_NULL
                    error("Could not resolve struct type with hash $(struct_desc.type_hash)")
                end
                info = unsafe_load(info_ptr)
            else
                error("Struct has no type info and no type hash")
            end
        else
            info = unsafe_load(Ptr{ConcreteTypeInfo}(struct_desc.info))
        end
        
        return CppStruct(ptr, info, lib, false)  # Not owned by Julia
    elseif td.index == GLZ_TYPE_OPTIONAL
        optional_desc = unsafe_load(Ptr{OptionalDesc}(Ptr{UInt8}(type_desc) + fieldoffset(ConcreteTypeDescriptor, 2)))
        return create_optional_wrapper(ptr, lib, optional_desc.element_type)
    elseif td.index == GLZ_TYPE_VARIANT
        # Nested variant
        return CppVariant(ptr, lib, type_desc)
    else
        error("Unsupported variant alternative type: $(td.index)")
    end
end

# Helper to prepare a value for setting in a variant
function prepare_variant_value(value, type_desc::Ptr{TypeDescriptor}, lib::Ptr{Cvoid})
    td = unsafe_load(Ptr{ConcreteTypeDescriptor}(type_desc))
    
    if td.index == GLZ_TYPE_PRIMITIVE
        # For primitives, create a pointer to the value
        return Ref(value)
    elseif td.index == GLZ_TYPE_STRING
        # Create a temporary C++ string
        if isa(value, AbstractString)
            create_func = get_cached_function(lib, :glz_create_string)
            str_ptr = ccall(create_func, Ptr{Cvoid}, (Cstring, Csize_t), value, sizeof(value))
            return str_ptr
        else
            error("Expected string value for string alternative")
        end
    elseif td.index == GLZ_TYPE_VECTOR
        # Handle vector values - would need to create temporary vector
        error("Setting vector values in variants not yet implemented")
    elseif td.index == GLZ_TYPE_STRUCT
        # Handle struct values
        if isa(value, CppStruct)
            return value.ptr
        else
            error("Expected CppStruct value for struct alternative")
        end
    else
        error("Setting variant alternative type $(td.index) not yet implemented")
    end
end

# Helper to clean up temporary values
function cleanup_variant_value(value_ptr, type_desc::Ptr{TypeDescriptor}, lib::Ptr{Cvoid})
    td = unsafe_load(Ptr{ConcreteTypeDescriptor}(type_desc))
    
    if td.index == GLZ_TYPE_STRING && value_ptr != C_NULL
        # Destroy temporary string
        destroy_func = get_cached_function(lib, :glz_destroy_string)
        ccall(destroy_func, Cvoid, (Ptr{Cvoid},), value_ptr)
    end
    # Other types don't need cleanup
end

# Pretty printing for variants
function Base.show(io::IO, v::CppVariant)
    compact = get(io, :compact, false)
    
    try
        current_idx = index(v)
        n_alts = length(v)
        
        if compact
            # Compact mode: VariantType(index=0, value=...)
            val = get_value(v)
            print(io, "Variant(index=", current_idx, ", value=")
            show(IOContext(io, :compact => true), val)
            print(io, ")")
        else
            # Detailed mode
            println(io, "CppVariant {")
            println(io, "  alternatives: ", n_alts)
            println(io, "  active: ", current_idx)
            print(io, "  value: ")
            
            val = get_value(v)
            show(IOContext(io, :compact => false, :indent => 2), val)
            
            println(io)
            print(io, "}")
        end
    catch e
        # Fallback if we can't access the variant
        print(io, "CppVariant(<inaccessible>)")
    end
end

# Equality comparison
function Base.:(==)(v1::CppVariant, v2::CppVariant)
    # Variants are equal if they hold the same alternative and the values are equal
    idx1 = index(v1)
    idx2 = index(v2)
    
    if idx1 != idx2
        return false
    end
    
    # Compare values
    val1 = get_value(v1)
    val2 = get_value(v2)
    
    return val1 == val2
end

# Check if variant is in a valid state (for optional<variant> scenarios)
function Base.isvalid(v::CppVariant)
    try
        index(v)
        return true
    catch
        return false
    end
end

# =============================================================================
# Julia-idiomatic interface extensions
# =============================================================================

"""
    tryget(v::CppVariant, ::Type{T}) -> Union{Some{T}, Nothing}

Safely attempt to get the variant value as type T.
Returns Some(value) if successful, Nothing if the variant doesn't hold type T.

# Example
```julia
result = tryget(variant, Int32)
if result isa Some
    println("Got integer: ", something(result))
else
    println("Variant doesn't contain an Int32")
end
```
"""
function tryget(v::CppVariant, ::Type{T}) where T
    try
        val = get_value(v)
        if isa(val, T)
            return Some(val)
        else
            return nothing
        end
    catch
        return nothing
    end
end

"""
    tryget(f::Function, v::CppVariant, ::Type{T})

Apply function f to the variant value if it's of type T, otherwise return nothing.

# Example
```julia
result = tryget(variant, String) do str
    uppercase(str)
end
```
"""
function tryget(f::Function, v::CppVariant, ::Type{T}) where T
    result = tryget(v, T)
    result === nothing ? nothing : Some(f(something(result)))
end

"""
    Base.convert(::Type{T}, v::CppVariant) where {T <: Union}

Convert a variant to a Julia Union type containing all possible alternatives.
"""
function Base.convert(::Type{T}, v::CppVariant) where {T <: Union}
    val = get_value(v)
    # Check if the value is compatible with the Union type
    if isa(val, T)
        return val
    else
        # Try to convert to one of the Union types
        union_types = Base.uniontypes(T)
        for U in union_types
            try
                return convert(U, val)
            catch MethodError
                continue
            end
        end
        error("Variant value $(typeof(val)) is not compatible with $T")
    end
end

"""
    alternative_types(v::CppVariant) -> Vector{Type}

Get a vector of Julia types that this variant can hold.
Note: This returns a best-effort mapping to Julia types based on the C++ type descriptors.
"""
function alternative_types(v::CppVariant)
    types = Type[]
    n = length(v)
    for i in 0:(n-1)
        type_desc = alternative_type(v, i)
        julia_type = cpp_type_to_julia_type(type_desc)
        push!(types, julia_type)
    end
    return types
end

# Helper function to map C++ type descriptors to Julia types
function cpp_type_to_julia_type(type_desc::Ptr{TypeDescriptor})
    if type_desc == C_NULL
        return Any
    end
    
    td = unsafe_load(Ptr{ConcreteTypeDescriptor}(type_desc))
    
    if td.index == GLZ_TYPE_PRIMITIVE
        prim_desc = unsafe_load(Ptr{PrimitiveDesc}(Ptr{UInt8}(type_desc) + fieldoffset(ConcreteTypeDescriptor, 2)))
        return primitive_kind_to_julia_type(prim_desc.kind)
    elseif td.index == GLZ_TYPE_STRING
        return String
    elseif td.index == GLZ_TYPE_COMPLEX
        complex_desc = unsafe_load(Ptr{ComplexDesc}(Ptr{UInt8}(type_desc) + fieldoffset(ConcreteTypeDescriptor, 2)))
        return complex_desc.kind == 0 ? ComplexF32 : ComplexF64
    elseif td.index == GLZ_TYPE_VECTOR
        return Vector
    elseif td.index == GLZ_TYPE_STRUCT
        return CppStruct
    elseif td.index == GLZ_TYPE_OPTIONAL
        return CppOptional
    elseif td.index == GLZ_TYPE_VARIANT
        return CppVariant
    else
        return Any
    end
end

function primitive_kind_to_julia_type(kind::UInt64)
    if kind == 1
        return Bool
    elseif kind == 2
        return Int8
    elseif kind == 3
        return Int16
    elseif kind == 4
        return Int32
    elseif kind == 5
        return Int64
    elseif kind == 6
        return UInt8
    elseif kind == 7
        return UInt16
    elseif kind == 8
        return UInt32
    elseif kind == 9
        return UInt64
    elseif kind == 10
        return Float32
    elseif kind == 11
        return Float64
    else
        return Any
    end
end

"""
    match_variant(variant, type_cases...)

Simple pattern matching for variants. Returns the result for the first matching type.

# Example
```julia
result = match_variant(variant,
    Int32 => x -> "integer: \$x",
    String => x -> "string: \$x",
    _ => x -> "other: \$x"
)
```
"""
function match_variant(variant::CppVariant, cases...)
    val = get_value(variant)
    
    for case in cases
        if case isa Pair
            pattern, action = case
            if pattern === :_ || pattern === Any
                return action(val)
            elseif isa(val, pattern)
                return action(val)
            end
        end
    end
    
    return nothing
end

"""
    variant_union_type(v::CppVariant)

Return a Union type representing all possible types this variant can hold.
"""
function variant_union_type(v::CppVariant)
    types = alternative_types(v)
    if Base.isempty(types)
        return Union{}
    elseif length(types) == 1
        return types[1]
    else
        return Union{types...}
    end
end

# Implement iteration interface for exploring variant alternatives
"""
    alternatives(v::CppVariant)

Return an iterator over the alternative types and their indices.
"""
function alternatives(v::CppVariant)
    VariantAlternatives(v)
end

struct VariantAlternatives
    variant::CppVariant
end

Base.length(va::VariantAlternatives) = length(va.variant)

function Base.iterate(va::VariantAlternatives, state::Int = 0)
    if state >= length(va.variant)
        return nothing
    end
    
    type_desc = alternative_type(va.variant, state)
    julia_type = cpp_type_to_julia_type(type_desc)
    
    return (state => julia_type, state + 1)
end

# More idiomatic accessors
"""
    current_type(v::CppVariant) -> Type

Get the Julia type of the currently active alternative.
"""
function current_type(v::CppVariant)
    idx = index(v)
    type_desc = alternative_type(v, idx)
    return cpp_type_to_julia_type(type_desc)
end

"""
    is_active(v::CppVariant, ::Type{T}) -> Bool

Check if the variant currently holds a value of type T.
"""
function is_active(v::CppVariant, ::Type{T}) where T
    val = get_value(v)
    return isa(val, T)
end

# =============================================================================
# Symbolic indexing support
# =============================================================================

"""
    type_symbol_to_type(symbol::Symbol) -> Type

Convert a type symbol to its corresponding Julia type.
"""
function type_symbol_to_type(symbol::Symbol)
    type_map = Dict(
        :int => Int32,
        :int8 => Int8,
        :int16 => Int16,
        :int32 => Int32,
        :int64 => Int64,
        :uint => UInt32,
        :uint8 => UInt8,
        :uint16 => UInt16,
        :uint32 => UInt32,
        :uint64 => UInt64,
        :float => Float32,
        :float32 => Float32,
        :float64 => Float64,
        :double => Float64,
        :bool => Bool,
        :string => String,
        :str => String,
        :complex => Complex,
        :complexf32 => ComplexF32,
        :complexf64 => ComplexF64,
        :vector => Vector,
        :struct => CppStruct,
        :optional => CppOptional,
        :variant => CppVariant
    )
    
    return get(type_map, symbol, Any)
end

"""
    find_alternative_index(v::CppVariant, target_type::Type) -> Union{Int, Nothing}

Find the index of the first alternative that matches the target type.
Returns the 0-based index, or nothing if not found.
"""
function find_alternative_index(v::CppVariant, target_type::Type)
    types = alternative_types(v)
    for (i, alt_type) in enumerate(types)
        if alt_type == target_type
            return i - 1  # Convert to 0-based
        end
    end
    return nothing
end

"""
    Base.getindex(v::CppVariant, symbol::Symbol)

Get variant value by type symbol. Throws an error if the variant doesn't currently hold that type.

# Example
```julia
# If variant currently holds a string
str_value = variant[:string]  # or variant[:str]
int_value = variant[:int32]   # would throw if not currently int
```
"""
function Base.getindex(v::CppVariant, symbol::Symbol)
    target_type = type_symbol_to_type(symbol)
    val = get_value(v)
    if isa(val, target_type)
        return val
    else
        error("Variant currently holds $(typeof(val)), not $(target_type) (symbol: :$(symbol))")
    end
end

"""
    Base.setindex!(v::CppVariant, value, symbol::Symbol)

Set variant value by type symbol.

# Example
```julia
variant[:int32] = 42
variant[:string] = "hello"
```
"""
function Base.setindex!(v::CppVariant, value, symbol::Symbol)
    target_type = type_symbol_to_type(symbol)
    
    # Find the appropriate alternative index
    alt_idx = find_alternative_index(v, target_type)
    if alt_idx === nothing
        available_types = alternative_types(v)
        error("Variant does not support type $(target_type) (symbol: :$(symbol)). Available types: $(available_types)")
    end
    
    # Convert value if necessary
    converted_value = isa(value, target_type) ? value : convert(target_type, value)
    
    set_value!(v, alt_idx, converted_value)
    return converted_value
end

"""
    hastype(v::CppVariant, symbol::Symbol) -> Bool

Check if the variant supports the given type symbol.

# Example
```julia
if hastype(variant, :string)
    println("This variant can hold strings")
end
```
"""
function hastype(v::CppVariant, symbol::Symbol)
    target_type = type_symbol_to_type(symbol)
    return find_alternative_index(v, target_type) !== nothing
end

"""
    tryget(v::CppVariant, symbol::Symbol) -> Union{Some{T}, Nothing}

Safely attempt to get the variant value by type symbol.

# Example
```julia
result = tryget(variant, :string)
if result isa Some
    println("Got string: ", something(result))
end
```
"""
function tryget(v::CppVariant, symbol::Symbol)
    target_type = type_symbol_to_type(symbol)
    return tryget(v, target_type)
end