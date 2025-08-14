# Library management for Glaze.jl

struct CppLibrary
    handle::Ptr{Cvoid}
    types::Dict{String, ConcreteTypeInfo}
    # Function pointer cache to avoid repeated dlsym calls
    function_cache::Dict{Symbol, Ptr{Cvoid}}
    
    function CppLibrary(path::String)
        handle = Libdl.dlopen(path)
        obj = new(handle, Dict{String, ConcreteTypeInfo}(), Dict{Symbol, Ptr{Cvoid}}())
        # Register this library for function caching
        _library_registry[handle] = obj
        return obj
    end
end

"""
    get_cached_function(lib::CppLibrary, symbol::Symbol) -> Ptr{Cvoid}

Get a cached function pointer, performing dlsym only if not already cached.
This provides significant performance improvement for repeated operations.
"""
@inline function get_cached_function(lib::CppLibrary, symbol::Symbol)
    get!(lib.function_cache, symbol) do
        Libdl.dlsym(lib.handle, symbol)
    end
end

# Global registry to map library handles to CppLibrary objects for caching
const _library_registry = Dict{Ptr{Cvoid}, CppLibrary}()

# For compatibility with code that uses Ptr{Cvoid} as lib handle
@inline function get_cached_function(lib_handle::Ptr{Cvoid}, symbol::Symbol)
    # Try to find the CppLibrary object for caching
    lib_obj = get(_library_registry, lib_handle, nothing)
    if lib_obj !== nothing
        return get_cached_function(lib_obj, symbol)
    else
        # Fallback to direct dlsym for raw handles when no CppLibrary object is found
        return Libdl.dlsym(lib_handle, symbol)
    end
end

"""
    load(path::String) -> CppLibrary

Load a C++ shared library and initialize the Glaze interface.

# Arguments
- `path`: Path to the shared library (.so, .dylib, or .dll file)

# Returns
- `CppLibrary`: Handle to the loaded library with type information

# Example
```julia
lib = Glaze.load("mylib.so")
```
"""
function load(path::String)
    CppLibrary(path)
end

function Base.getproperty(lib::CppLibrary, name::Symbol)
    if name in fieldnames(CppLibrary)
        return getfield(lib, name)
    end
    
    # Try to create an instance of the C++ type
    type_name = String(name)
    create_func = get_cached_function(lib, :glz_create_instance)
    ptr = ccall(create_func, Ptr{Cvoid}, (Cstring,), type_name)
    
    if ptr == C_NULL
        error("Type $type_name not found in library")
    end
    
    # Get type info
    info_func = get_cached_function(lib, :glz_get_type_info)
    info_ptr = ccall(info_func, Ptr{ConcreteTypeInfo}, (Cstring,), type_name)
    info = unsafe_load(info_ptr)
    
    # Create Julia wrapper type dynamically
    return CppStruct(ptr, info, lib.handle)
end

mutable struct CppStruct
    ptr::Ptr{Cvoid}
    info::ConcreteTypeInfo
    lib::Ptr{Cvoid}
    owned::Bool  # Whether Julia owns this instance
    
    function CppStruct(ptr::Ptr{Cvoid}, info::ConcreteTypeInfo, lib::Ptr{Cvoid}, owned::Bool=true)
        obj = new(ptr, info, lib, owned)
        if owned
            finalizer(obj) do x
                destroy_func = get_cached_function(x.lib, :glz_destroy_instance)
                ccall(destroy_func, Cvoid, (Cstring, Ptr{Cvoid}), 
                      unsafe_string(x.info.name), x.ptr)
            end
        end
        return obj
    end
end

function Base.getproperty(obj::CppStruct, name::Symbol)
    if name in (:ptr, :info, :lib, :owned)
        return getfield(obj, name)
    end
    
    # Find member
    info = getfield(obj, :info)
    # Iterate through MemberInfo structs
    for i in 0:(info.member_count-1)
        member_ptr = info.members + i * sizeof(MemberInfo)
        member = unsafe_load(member_ptr)
        if unsafe_string(member.name) == String(name)
            return get_member_value(obj, member)
        end
    end
    
    error("Member $name not found")
end

function Base.setproperty!(obj::CppStruct, name::Symbol, value)
    if name in (:ptr, :info, :lib)
        error("Cannot set internal fields")
    end
    
    # Find member
    info = getfield(obj, :info)
    # Iterate through MemberInfo structs
    for i in 0:(info.member_count-1)
        member_ptr = info.members + i * sizeof(MemberInfo)
        member = unsafe_load(member_ptr)
        if unsafe_string(member.name) == String(name)
            set_member_value(obj, member, value)
            return value
        end
    end
    
    error("Member $name not found")
end

function get_member_value(obj::CppStruct, member::MemberInfo)
    # Check if this is a member function
    if member.kind == UInt8(MEMBER_FUNCTION)
        name = unsafe_string(member.name)
        # We need to store a pointer to the member info from the array, not create a new reference
        # Find the member in the members array to get its pointer
        info = getfield(obj, :info)
        
        member_ptr = C_NULL
        for i in 0:(info.member_count-1)
            test_ptr = info.members + i * sizeof(MemberInfo)
            m = unsafe_load(test_ptr)
            if m.name == member.name && m.kind == member.kind
                # Get pointer to this specific member in the array
                member_ptr = test_ptr
                break
            end
        end
        
        # Extract type name from the object's type info
        type_name = unsafe_string(obj.info.name)
        return CppMemberFunction(obj.ptr, member_ptr, obj.lib, name, type_name)
    end
    
    ptr = ccall(member.getter, Ptr{Cvoid}, (Ptr{Cvoid},), obj.ptr)
    
    # Load type descriptor
    if member.type == C_NULL
        error("Member has no type descriptor")
    end
    
    type_desc = unsafe_load(Ptr{ConcreteTypeDescriptor}(member.type))
    
    # Handle based on type descriptor kind
    if type_desc.index == GLZ_TYPE_PRIMITIVE
        # Extract just the first byte for PrimitiveDesc
        # Get PrimitiveDesc from the union data
        prim_desc = unsafe_load(Ptr{PrimitiveDesc}(Ptr{UInt8}(member.type) + fieldoffset(ConcreteTypeDescriptor, 2)))
        # Handle primitive types
        if prim_desc.kind == 1  # Bool
            return unsafe_load(Ptr{Bool}(ptr))
        elseif prim_desc.kind == 2  # I8
            return unsafe_load(Ptr{Int8}(ptr))
        elseif prim_desc.kind == 3  # I16
            return unsafe_load(Ptr{Int16}(ptr))
        elseif prim_desc.kind == 4  # I32
            return unsafe_load(Ptr{Int32}(ptr))
        elseif prim_desc.kind == 5  # I64
            return unsafe_load(Ptr{Int64}(ptr))
        elseif prim_desc.kind == 6  # U8
            return unsafe_load(Ptr{UInt8}(ptr))
        elseif prim_desc.kind == 7  # U16
            return unsafe_load(Ptr{UInt16}(ptr))
        elseif prim_desc.kind == 8  # U32
            return unsafe_load(Ptr{UInt32}(ptr))
        elseif prim_desc.kind == 9  # U64
            return unsafe_load(Ptr{UInt64}(ptr))
        elseif prim_desc.kind == 10  # F32
            return unsafe_load(Ptr{Float32}(ptr))
        elseif prim_desc.kind == 11  # F64
            return unsafe_load(Ptr{Float64}(ptr))
        else
            error("Unknown primitive type: $(prim_desc.kind)")
        end
    elseif type_desc.index == GLZ_TYPE_STRING
        return CppString(ptr, obj.lib)
    elseif type_desc.index == GLZ_TYPE_COMPLEX
        complex_desc = unsafe_load(Ptr{ComplexDesc}(Ptr{UInt8}(member.type) + fieldoffset(ConcreteTypeDescriptor, 2)))
        if complex_desc.kind == 0  # float
            return unsafe_load(Ptr{ComplexF32}(ptr))
        else  # double
            return unsafe_load(Ptr{ComplexF64}(ptr))
        end
    elseif type_desc.index == GLZ_TYPE_VECTOR
        # Check element type to return specialized vector if possible
        td = unsafe_load(Ptr{ConcreteTypeDescriptor}(member.type))
        data_ptr = Ptr{UInt8}(member.type) + fieldoffset(ConcreteTypeDescriptor, 2)
        element_ptr = unsafe_load(Ptr{Ptr{TypeDescriptor}}(data_ptr))
        
        # Get element type descriptor
        elem_td = unsafe_load(Ptr{ConcreteTypeDescriptor}(element_ptr))
        if elem_td.index == GLZ_TYPE_PRIMITIVE
            prim_desc = unsafe_load(Ptr{PrimitiveDesc}(Ptr{UInt8}(element_ptr) + fieldoffset(ConcreteTypeDescriptor, 2)))
            if prim_desc.kind == 10  # F32
                return CppVectorFloat32(ptr, obj.lib)
            elseif prim_desc.kind == 11  # F64
                return CppVectorFloat64(ptr, obj.lib)
            elseif prim_desc.kind == 4  # I32
                return CppVectorInt32(ptr, obj.lib)
            end
        elseif elem_td.index == GLZ_TYPE_COMPLEX
            complex_desc = unsafe_load(Ptr{ComplexDesc}(Ptr{UInt8}(element_ptr) + fieldoffset(ConcreteTypeDescriptor, 2)))
            if complex_desc.kind == 0  # float complex
                return CppVectorComplexF32(ptr, obj.lib)
            else  # double complex
                return CppVectorComplexF64(ptr, obj.lib)
            end
        end
        
        # Fall back to generic vector
        return CppVector(ptr, obj.lib, member.type)
    elseif type_desc.index == GLZ_TYPE_STRUCT
        # Handle nested struct - the data field contains the struct descriptor
        # Use unsafe_load to reinterpret the bytes
        GC.@preserve type_desc begin
            # Get pointer to the data field within the type descriptor
            data_ptr = Ptr{UInt8}(pointer_from_objref(type_desc)) + fieldoffset(ConcreteTypeDescriptor, 2)
            struct_desc_ptr = Ptr{StructDesc}(data_ptr)
            struct_desc = unsafe_load(struct_desc_ptr)
        end
        
        
        # If info is null, we need to find the type dynamically
        if struct_desc.info == C_NULL
            # Use type hash to resolve the type
            if struct_desc.type_hash != 0
                get_type_info_by_hash_func = get_cached_function(obj.lib, :glz_get_type_info_by_hash)
                info_ptr = ccall(get_type_info_by_hash_func, Ptr{ConcreteTypeInfo}, (UInt64,), struct_desc.type_hash)
                if info_ptr == C_NULL
                    error("Could not resolve nested struct type with hash $(struct_desc.type_hash)")
                end
                info = unsafe_load(info_ptr)
            else
                error("Nested struct has no type info and no type hash")
            end
        else
            info = unsafe_load(Ptr{ConcreteTypeInfo}(struct_desc.info))
        end
        
        return CppStruct(ptr, info, obj.lib, false)  # Not owned by Julia
    elseif type_desc.index == GLZ_TYPE_OPTIONAL
        # Handle optional type - extract the element type from OptionalDesc
        GC.@preserve type_desc begin
            # Get pointer to the data field within the type descriptor
            data_ptr = Ptr{UInt8}(pointer_from_objref(type_desc)) + fieldoffset(ConcreteTypeDescriptor, 2)
            optional_desc_ptr = Ptr{OptionalDesc}(data_ptr)
            optional_desc = unsafe_load(optional_desc_ptr)
        end
        
        # Create optional wrapper with element type information
        return create_optional_wrapper(ptr, obj.lib, optional_desc.element_type)
    elseif type_desc.index == GLZ_TYPE_VARIANT
        # Handle variant type - return variant wrapper
        return CppVariant(ptr, obj.lib, member.type)
    elseif type_desc.index == GLZ_TYPE_FUNCTION
        # This should not happen in get_member_value as we handle functions above
        error("Unexpected function type descriptor in data member access")
    else
        error("Unknown type kind: $(type_desc.index)")
    end
end

function set_member_value(obj::CppStruct, member::MemberInfo, value)
    # Check if this is a member function
    if member.kind == UInt8(MEMBER_FUNCTION)
        error("Cannot set value of member function '$(unsafe_string(member.name))'. Member functions are not modifiable.")
    end
    
    # Load type descriptor
    if member.type == C_NULL
        error("Member has no type descriptor")
    end
    
    type_desc = unsafe_load(Ptr{ConcreteTypeDescriptor}(member.type))
    
    # Handle based on type descriptor kind
    if type_desc.index == GLZ_TYPE_PRIMITIVE
        # Extract just the first byte for PrimitiveDesc
        # Get PrimitiveDesc from the union data
        prim_desc = unsafe_load(Ptr{PrimitiveDesc}(Ptr{UInt8}(member.type) + fieldoffset(ConcreteTypeDescriptor, 2)))
        # Handle primitive types
        if prim_desc.kind == 1  # Bool
            val = Bool(value)
            ccall(member.setter, Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), obj.ptr, Ref(val))
        elseif prim_desc.kind == 2  # I8
            val = Int8(value)
            ccall(member.setter, Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), obj.ptr, Ref(val))
        elseif prim_desc.kind == 3  # I16
            val = Int16(value)
            ccall(member.setter, Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), obj.ptr, Ref(val))
        elseif prim_desc.kind == 4  # I32
            val = Int32(value)
            ccall(member.setter, Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), obj.ptr, Ref(val))
        elseif prim_desc.kind == 5  # I64
            val = Int64(value)
            ccall(member.setter, Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), obj.ptr, Ref(val))
        elseif prim_desc.kind == 6  # U8
            val = UInt8(value)
            ccall(member.setter, Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), obj.ptr, Ref(val))
        elseif prim_desc.kind == 7  # U16
            val = UInt16(value)
            ccall(member.setter, Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), obj.ptr, Ref(val))
        elseif prim_desc.kind == 8  # U32
            val = UInt32(value)
            ccall(member.setter, Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), obj.ptr, Ref(val))
        elseif prim_desc.kind == 9  # U64
            val = UInt64(value)
            ccall(member.setter, Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), obj.ptr, Ref(val))
        elseif prim_desc.kind == 10  # F32
            val = Float32(value)
            ccall(member.setter, Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), obj.ptr, Ref(val))
        elseif prim_desc.kind == 11  # F64
            val = Float64(value)
            ccall(member.setter, Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), obj.ptr, Ref(val))
        else
            error("Unknown primitive type: $(prim_desc.kind)")
        end
    elseif type_desc.index == GLZ_TYPE_STRING
        # For strings, we need to call the C++ string assignment
        if isa(value, AbstractString)
            set_string_func = get_cached_function(obj.lib, :glz_string_set)
            ptr = ccall(member.getter, Ptr{Cvoid}, (Ptr{Cvoid},), obj.ptr)
            ccall(set_string_func, Cvoid, (Ptr{Cvoid}, Cstring, Csize_t), 
                  ptr, value, sizeof(value))
        else
            error("Value must be a string")
        end
    elseif type_desc.index == GLZ_TYPE_COMPLEX
        complex_desc = unsafe_load(Ptr{ComplexDesc}(Ptr{UInt8}(member.type) + fieldoffset(ConcreteTypeDescriptor, 2)))
        if complex_desc.kind == 0  # float
            val = ComplexF32(value)
            ccall(member.setter, Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), obj.ptr, Ref(val))
        else  # double
            val = ComplexF64(value)
            ccall(member.setter, Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), obj.ptr, Ref(val))
        end
    elseif type_desc.index == GLZ_TYPE_OPTIONAL
        # Handle optional type setting
        # For now, we'll implement basic support but note that this needs C++ interface functions
        error("Setting optional values is not yet implemented - requires C++ interface functions")
    elseif type_desc.index == GLZ_TYPE_VARIANT
        # Handle variant type setting
        error("Setting variant values directly is not yet implemented - use variant methods instead")
    else
        error("Setting type kind $(type_desc.index) not yet implemented")
    end
end

# Pretty printing for CppStruct
function Base.show(io::IO, obj::CppStruct)
    # Get type name
    type_name = unsafe_string(obj.info.name)
    
    # Get member count
    member_count = obj.info.member_count
    
    # Check if we should use compact or pretty printing
    compact = get(io, :compact, false)
    indent_level = get(io, :indent, 0)
    
    if compact || member_count == 0
        # Compact mode: single line
        print(io, type_name, "(")
        first = true
        for i in 0:(member_count-1)
            member_ptr = obj.info.members + i * sizeof(MemberInfo)
            member = unsafe_load(member_ptr)
            
            # Skip member functions
            if member.kind == UInt8(MEMBER_FUNCTION)
                continue
            end
            
            !first && print(io, ", ")
            first = false
            
            member_name = unsafe_string(member.name)
            member_value = get_member_value(obj, member)
            print(io, member_name, "=")
            show_member_value(io, member_value, true)
        end
        print(io, ")")
    else
        # Pretty print mode: multi-line with indentation
        println(io, type_name, " {")
        
        # Create IO context with increased indentation
        nested_io = IOContext(io, :indent => indent_level + 2)
        
        for i in 0:(member_count-1)
            member_ptr = obj.info.members + i * sizeof(MemberInfo)
            member = unsafe_load(member_ptr)
            
            # Skip member functions
            if member.kind == UInt8(MEMBER_FUNCTION)
                continue
            end
            
            # Print indentation
            print(io, " " ^ (indent_level + 2))
            
            # Get member name and value
            member_name = unsafe_string(member.name)
            member_value = get_member_value(obj, member)
            
            # Print member name
            print(io, member_name, ": ")
            
            # Show member value with appropriate formatting
            show_member_value(nested_io, member_value, false)
            
            println(io)
        end
        
        print(io, " " ^ indent_level, "}")
    end
end

# Helper function to show member values with appropriate formatting
function show_member_value(io::IO, value, compact::Bool)
    if isa(value, CppString)
        # Show strings with quotes, properly escaped
        str = String(value)
        print(io, "\"", replace(str, "\"" => "\\\""), "\"")
    elseif isa(value, Union{CppVector, CppVectorFloat32, CppVectorFloat64, CppVectorInt32, CppVectorComplexF32, CppVectorComplexF64})
        # Show vectors with their content
        if compact || length(value) <= 10
            # Compact vector display
            print(io, "[")
            for (j, val) in enumerate(value)
                j > 1 && print(io, ", ")
                if j > 10
                    print(io, "...")
                    break
                end
                show(IOContext(io, :compact => true), val)
            end
            print(io, "]")
        else
            # Multi-line vector display for large vectors
            println(io, "[")
            indent_level = get(io, :indent, 0)
            for (j, val) in enumerate(value)
                print(io, " " ^ (indent_level + 2))
                show(IOContext(io, :compact => true), val)
                j < length(value) && print(io, ",")
                println(io)
            end
            print(io, " " ^ indent_level, "]")
        end
    elseif isa(value, CppStruct)
        # Nested struct - use show with proper context
        show(IOContext(io, :compact => compact), value)
    elseif isa(value, CppVariant)
        # Variant - use show with proper context
        show(IOContext(io, :compact => compact), value)
    else
        # Default printing for primitive types
        show(io, value)
    end
end