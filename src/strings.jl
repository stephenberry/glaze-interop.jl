# String wrapper and string operations

# String wrapper implementation
Base.String(s::CppString) = unsafe_string(ccall(get_cached_function(s.lib, :glz_string_c_str), 
                                                Ptr{UInt8}, (Ptr{Cvoid},), s.ptr))

# Required AbstractString interface
Base.length(s::CppString) = Int(ccall(get_cached_function(s.lib, :glz_string_size), Csize_t, (Ptr{Cvoid},), s.ptr))
Base.ncodeunits(s::CppString) = length(s)
Base.codeunit(s::CppString) = UInt8  # CppString uses UTF-8 encoding like Julia strings
Base.isvalid(s::CppString, i::Int) = 1 <= i <= ncodeunits(s)

# Efficient character access without full string conversion
function Base.codeunit(s::CppString, i::Int)
    @boundscheck checkbounds(s, i)
    c_str_ptr = ccall(get_cached_function(s.lib, :glz_string_c_str), Ptr{UInt8}, (Ptr{Cvoid},), s.ptr)
    unsafe_load(c_str_ptr, i)
end

# Iterator interface
Base.iterate(s::CppString, i::Int=1) = i > ncodeunits(s) ? nothing : (Char(codeunit(s, i)), i + 1)

# Indexing interface (required for AbstractString)
Base.getindex(s::CppString, i::Int) = Char(codeunit(s, i))
Base.getindex(s::CppString, r::UnitRange{Int}) = String(s)[r]

# String interpolation support
Base.string(s::CppString) = String(s)

# Display
Base.show(io::IO, s::CppString) = print(io, String(s))

# Equality (keep existing for compatibility, but AbstractString provides generic fallbacks)
Base.:(==)(s::CppString, str::AbstractString) = String(s) == str
Base.:(==)(str::AbstractString, s::CppString) = str == String(s)

# String operations that benefit from direct implementation
Base.startswith(s::CppString, prefix::AbstractString) = startswith(String(s), prefix)
Base.endswith(s::CppString, suffix::AbstractString) = endswith(String(s), suffix) 
Base.contains(s::CppString, substr::AbstractString) = contains(String(s), substr)

function Base.setindex!(s::CppString, value::AbstractString)
    set_func = get_cached_function(s.lib, :glz_string_set)
    ccall(set_func, Cvoid, (Ptr{Cvoid}, Cstring, Csize_t), 
          s.ptr, value, sizeof(value))
end

# Simplified copy function for CppStruct objects using property access
function Base.copy!(dest::CppStruct, src::CppStruct)
    # Deep copy all data from src CppStruct to dest CppStruct using property access
    
    # Verify both structs are of the same type
    src_type = unsafe_string(src.info.name)
    dest_type = unsafe_string(dest.info.name)
    
    if src_type != dest_type
        error("Cannot copy between different struct types: $src_type -> $dest_type")
    end
    
    # Get member names and copy using property access
    # This is simpler and more reliable than low-level type introspection
    src_members = unsafe_wrap(Array, src.info.members, src.info.member_count)
    
    for member in src_members
        # Skip member functions
        if member.kind == UInt8(MEMBER_FUNCTION)
            continue
        end
        
        member_name = Symbol(unsafe_string(member.name))
        
        # Get the source value using property access
        src_value = getproperty(src, member_name)
        
        # Copy based on the type of the source value
        if isa(src_value, CppString)
            # String: convert to Julia string and assign
            setproperty!(dest, member_name, String(src_value))
        elseif isa(src_value, CppStruct)
            # Nested struct: recursively copy
            dest_nested = getproperty(dest, member_name)
            copy!(dest_nested, src_value)
        elseif isa(src_value, Union{CppVectorInt32, CppVectorFloat32, CppVectorFloat64, CppVectorComplexF32, CppVectorComplexF64})
            # Vector: copy all elements
            dest_vec = getproperty(dest, member_name)
            resize!(dest_vec, length(src_value))
            for i in 1:length(src_value)
                dest_vec[i] = src_value[i]
            end
        elseif isa(src_value, CppOptional)
            # Optional: copy value if present, otherwise reset destination
            dest_opt = getproperty(dest, member_name)
            if !isnothing(src_value)
                # Copy the value from source to destination
                set_value!(dest_opt, value(src_value))
            else
                # Source is empty, so reset destination to empty
                reset!(dest_opt)
            end
        else
            # Primitive types: direct assignment
            setproperty!(dest, member_name, src_value)
        end
    end
    
    return dest
end

# Convenient macro for assignment syntax: @assign target_person = julia_person
macro assign(expr)
    if expr.head == :(=) && length(expr.args) == 2
        dest, src = expr.args
        return esc(:(copy!($dest, $src)))
    else
        error("@assign expects assignment syntax: @assign dest = src")
    end
end

# Alternative: create a custom assignment operator function
function assign!(dest::CppStruct, src::CppStruct)
    return copy!(dest, src)
end

# Helper to get Julia type from type descriptor
function julia_type_from_descriptor(type_desc::Ptr{TypeDescriptor})
    if type_desc == C_NULL
        error("Null type descriptor")
    end
    
    td = unsafe_load(Ptr{ConcreteTypeDescriptor}(type_desc))
    
    if td.index == GLZ_TYPE_PRIMITIVE
        prim_desc = unsafe_load(Ptr{PrimitiveDesc}(type_desc + fieldoffset(ConcreteTypeDescriptor, 2)))
        if prim_desc.kind == 1
            return Bool
        elseif prim_desc.kind == 2
            return Int8
        elseif prim_desc.kind == 3
            return Int16
        elseif prim_desc.kind == 4
            return Int32
        elseif prim_desc.kind == 5
            return Int64
        elseif prim_desc.kind == 6
            return UInt8
        elseif prim_desc.kind == 7
            return UInt16
        elseif prim_desc.kind == 8
            return UInt32
        elseif prim_desc.kind == 9
            return UInt64
        elseif prim_desc.kind == 10
            return Float32
        elseif prim_desc.kind == 11
            return Float64
        else
            error("Unknown primitive type: $(prim_desc.kind)")
        end
    elseif td.index == GLZ_TYPE_COMPLEX
        complex_desc = unsafe_load(Ptr{ComplexDesc}(type_desc + fieldoffset(ConcreteTypeDescriptor, 2)))
        return complex_desc.kind == 0 ? ComplexF32 : ComplexF64
    else
        error("Cannot get Julia type for type kind: $(td.index)")
    end
end