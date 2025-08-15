# Vector types and operations for Glaze.jl

# Safe conversion from Csize_t to Int with bounds checking
function safe_csize_to_int(size::Csize_t)
    if size > typemax(Int)
        error("Vector size $size is too large for Julia Int type")
    elseif size == typemax(Csize_t) || (size & 0xFFFF000000000000) != 0
        # Check for obvious garbage values
        error("Vector size appears corrupted: $size (0x$(string(size, base=16)))")
    end
    return Int(size)
end

# Vector wrapper implementation for generic CppVector
function Base.length(v::CppVector)
    view_func = get_cached_function(v.lib, :glz_vector_view)
    view = ccall(view_func, VectorView, (Ptr{Cvoid}, Ptr{TypeDescriptor}), v.ptr, v.type_desc)
    return safe_csize_to_int(view.size)
end

function Base.size(v::CppVector)
    return (length(v),)
end

function Base.getindex(v::CppVector, i::Integer)
    @boundscheck 1 <= i <= length(v) || throw(BoundsError(v, i))
    view_func = get_cached_function(v.lib, :glz_vector_view)
    view = ccall(view_func, VectorView, (Ptr{Cvoid}, Ptr{TypeDescriptor}), v.ptr, v.type_desc)
    
    # Get element type from vector type descriptor
    td = unsafe_load(Ptr{ConcreteTypeDescriptor}(v.type_desc))
    if td.index != GLZ_TYPE_VECTOR
        error("Not a vector type descriptor")
    end
    # Extract VectorDesc from union data
    # Get pointer to the data field in the struct
    data_ptr = Ptr{UInt8}(v.type_desc) + fieldoffset(ConcreteTypeDescriptor, 2)
    element_ptr = unsafe_load(Ptr{Ptr{TypeDescriptor}}(data_ptr))
    
    # Cast data pointer to appropriate type and load
    T = julia_type_from_descriptor(element_ptr)
    typed_ptr = Ptr{T}(view.data)
    return unsafe_load(typed_ptr, i)
end

function Base.setindex!(v::CppVector, value, i::Integer)
    @boundscheck 1 <= i <= length(v) || throw(BoundsError(v, i))
    view_func = get_cached_function(v.lib, :glz_vector_view)
    view = ccall(view_func, VectorView, (Ptr{Cvoid}, Ptr{TypeDescriptor}), v.ptr, v.type_desc)
    
    # Get element type from vector type descriptor
    td = unsafe_load(Ptr{ConcreteTypeDescriptor}(v.type_desc))
    if td.index != GLZ_TYPE_VECTOR
        error("Not a vector type descriptor")
    end
    # Extract VectorDesc from union data
    # Get pointer to the data field in the struct
    data_ptr = Ptr{UInt8}(v.type_desc) + fieldoffset(ConcreteTypeDescriptor, 2)
    element_ptr = unsafe_load(Ptr{Ptr{TypeDescriptor}}(data_ptr))
    
    # Cast data pointer to appropriate type and store
    T = julia_type_from_descriptor(element_ptr)
    typed_ptr = Ptr{T}(view.data)
    unsafe_store!(typed_ptr, T(value), i)
    return value
end

# Fast iterator for CppVector that caches all necessary data
struct CppVectorIterator{T}
    data_ptr::Ptr{T}
    size::Int
end

# Create iterator with cached data
function Base.iterate(v::CppVector)
    # Get vector view once
    view_func = get_cached_function(v.lib, :glz_vector_view)
    view = ccall(view_func, VectorView, (Ptr{Cvoid}, Ptr{TypeDescriptor}), v.ptr, v.type_desc)
    
    # Return nothing for empty vectors
    view.size == 0 && return nothing
    
    # Get element type once
    td = unsafe_load(Ptr{ConcreteTypeDescriptor}(v.type_desc))
    if td.index != GLZ_TYPE_VECTOR
        error("Not a vector type descriptor")
    end
    data_ptr = Ptr{UInt8}(v.type_desc) + fieldoffset(ConcreteTypeDescriptor, 2)
    element_ptr = unsafe_load(Ptr{Ptr{TypeDescriptor}}(data_ptr))
    T = julia_type_from_descriptor(element_ptr)
    
    # Create iterator with cached data
    iter = CppVectorIterator{T}(Ptr{T}(view.data), safe_csize_to_int(view.size))
    
    # Return first element and iterator state
    return (unsafe_load(iter.data_ptr, 1), (iter, 2))
end

function Base.iterate(::CppVector, state::Tuple{CppVectorIterator{T}, Int}) where T
    iter, idx = state
    idx > iter.size && return nothing
    return (unsafe_load(iter.data_ptr, idx), (iter, idx + 1))
end

# Optimized iterations for specialized vector types
# CppVectorFloat32
function Base.iterate(v::CppVectorFloat32)
    view_func = get_cached_function(v.lib, :glz_vector_float32_view)
    view = ccall(view_func, VectorView, (Ptr{Cvoid},), v.ptr)
    view.size == 0 && return nothing
    
    iter = CppVectorIterator{Float32}(Ptr{Float32}(view.data), safe_csize_to_int(view.size))
    return (unsafe_load(iter.data_ptr, 1), (iter, 2))
end

# CppVectorFloat64
function Base.iterate(v::CppVectorFloat64)
    view_func = get_cached_function(v.lib, :glz_vector_float64_view)
    view = ccall(view_func, VectorView, (Ptr{Cvoid},), v.ptr)
    view.size == 0 && return nothing
    
    iter = CppVectorIterator{Float64}(Ptr{Float64}(view.data), safe_csize_to_int(view.size))
    return (unsafe_load(iter.data_ptr, 1), (iter, 2))
end

# CppVectorInt32
function Base.iterate(v::CppVectorInt32)
    view_func = get_cached_function(v.lib, :glz_vector_int32_view)
    view = ccall(view_func, VectorView, (Ptr{Cvoid},), v.ptr)
    view.size == 0 && return nothing
    
    iter = CppVectorIterator{Int32}(Ptr{Int32}(view.data), safe_csize_to_int(view.size))
    return (unsafe_load(iter.data_ptr, 1), (iter, 2))
end

# CppVectorComplexF32
function Base.iterate(v::CppVectorComplexF32)
    view_func = get_cached_function(v.lib, :glz_vector_complexf32_view)
    view = ccall(view_func, VectorView, (Ptr{Cvoid},), v.ptr)
    view.size == 0 && return nothing
    
    iter = CppVectorIterator{ComplexF32}(Ptr{ComplexF32}(view.data), safe_csize_to_int(view.size))
    return (unsafe_load(iter.data_ptr, 1), (iter, 2))
end

# CppVectorComplexF64
function Base.iterate(v::CppVectorComplexF64)
    view_func = get_cached_function(v.lib, :glz_vector_complexf64_view)
    view = ccall(view_func, VectorView, (Ptr{Cvoid},), v.ptr)
    view.size == 0 && return nothing
    
    iter = CppVectorIterator{ComplexF64}(Ptr{ComplexF64}(view.data), safe_csize_to_int(view.size))
    return (unsafe_load(iter.data_ptr, 1), (iter, 2))
end

# Shared iteration continuation for all typed vectors
function Base.iterate(v::Union{CppVectorFloat32, CppVectorFloat64, CppVectorInt32, CppVectorComplexF32, CppVectorComplexF64}, state::Tuple{CppVectorIterator{T}, Int}) where T
    iter, idx = state
    idx > iter.size && return nothing
    return (unsafe_load(iter.data_ptr, idx), (iter, idx + 1))
end

# Length methods for specialized vectors
function Base.length(v::CppVectorFloat32)
    view_func = get_cached_function(v.lib, :glz_vector_float32_view)
    view = ccall(view_func, VectorView, (Ptr{Cvoid},), v.ptr)
    return safe_csize_to_int(view.size)
end

function Base.length(v::CppVectorFloat64)
    view_func = get_cached_function(v.lib, :glz_vector_float64_view)
    view = ccall(view_func, VectorView, (Ptr{Cvoid},), v.ptr)
    return safe_csize_to_int(view.size)
end

function Base.length(v::CppVectorInt32)
    view_func = get_cached_function(v.lib, :glz_vector_int32_view)
    view = ccall(view_func, VectorView, (Ptr{Cvoid},), v.ptr)
    return safe_csize_to_int(view.size)
end

function Base.length(v::CppVectorComplexF32)
    view_func = get_cached_function(v.lib, :glz_vector_complexf32_view)
    view = ccall(view_func, VectorView, (Ptr{Cvoid},), v.ptr)
    return safe_csize_to_int(view.size)
end

function Base.length(v::CppVectorComplexF64)
    view_func = get_cached_function(v.lib, :glz_vector_complexf64_view)
    view = ccall(view_func, VectorView, (Ptr{Cvoid},), v.ptr)
    return safe_csize_to_int(view.size)
end

# Size methods
Base.size(v::Union{CppVectorFloat32, CppVectorFloat64, CppVectorInt32, CppVectorComplexF32, CppVectorComplexF64}) = (length(v),)

# Getindex methods for specialized vectors
function Base.getindex(v::CppVectorFloat32, i::Integer)
    @boundscheck 1 <= i <= length(v) || throw(BoundsError(v, i))
    view_func = get_cached_function(v.lib, :glz_vector_float32_view)
    view = ccall(view_func, VectorView, (Ptr{Cvoid},), v.ptr)
    return unsafe_load(Ptr{Float32}(view.data), i)
end

function Base.getindex(v::CppVectorFloat64, i::Integer)
    @boundscheck 1 <= i <= length(v) || throw(BoundsError(v, i))
    view_func = get_cached_function(v.lib, :glz_vector_float64_view)
    view = ccall(view_func, VectorView, (Ptr{Cvoid},), v.ptr)
    return unsafe_load(Ptr{Float64}(view.data), i)
end

function Base.getindex(v::CppVectorInt32, i::Integer)
    @boundscheck 1 <= i <= length(v) || throw(BoundsError(v, i))
    view_func = get_cached_function(v.lib, :glz_vector_int32_view)
    view = ccall(view_func, VectorView, (Ptr{Cvoid},), v.ptr)
    return unsafe_load(Ptr{Int32}(view.data), i)
end

function Base.getindex(v::CppVectorComplexF32, i::Integer)
    @boundscheck 1 <= i <= length(v) || throw(BoundsError(v, i))
    view_func = get_cached_function(v.lib, :glz_vector_complexf32_view)
    view = ccall(view_func, VectorView, (Ptr{Cvoid},), v.ptr)
    return unsafe_load(Ptr{ComplexF32}(view.data), i)
end

function Base.getindex(v::CppVectorComplexF64, i::Integer)
    @boundscheck 1 <= i <= length(v) || throw(BoundsError(v, i))
    view_func = get_cached_function(v.lib, :glz_vector_complexf64_view)
    view = ccall(view_func, VectorView, (Ptr{Cvoid},), v.ptr)
    return unsafe_load(Ptr{ComplexF64}(view.data), i)
end

# setindex! methods for specialized vectors
function Base.setindex!(v::CppVectorFloat32, value, i::Integer)
    @boundscheck 1 <= i <= length(v) || throw(BoundsError(v, i))
    view_func = get_cached_function(v.lib, :glz_vector_float32_view)
    view = ccall(view_func, VectorView, (Ptr{Cvoid},), v.ptr)
    unsafe_store!(Ptr{Float32}(view.data), Float32(value), i)
    return value
end

function Base.setindex!(v::CppVectorFloat64, value, i::Integer)
    @boundscheck 1 <= i <= length(v) || throw(BoundsError(v, i))
    view_func = get_cached_function(v.lib, :glz_vector_float64_view)
    view = ccall(view_func, VectorView, (Ptr{Cvoid},), v.ptr)
    unsafe_store!(Ptr{Float64}(view.data), Float64(value), i)
    return value
end

function Base.setindex!(v::CppVectorInt32, value, i::Integer)
    @boundscheck 1 <= i <= length(v) || throw(BoundsError(v, i))
    view_func = get_cached_function(v.lib, :glz_vector_int32_view)
    view = ccall(view_func, VectorView, (Ptr{Cvoid},), v.ptr)
    unsafe_store!(Ptr{Int32}(view.data), Int32(value), i)
    return value
end

function Base.setindex!(v::CppVectorComplexF32, value, i::Integer)
    @boundscheck 1 <= i <= length(v) || throw(BoundsError(v, i))
    view_func = get_cached_function(v.lib, :glz_vector_complexf32_view)
    view = ccall(view_func, VectorView, (Ptr{Cvoid},), v.ptr)
    unsafe_store!(Ptr{ComplexF32}(view.data), ComplexF32(value), i)
    return value
end

function Base.setindex!(v::CppVectorComplexF64, value, i::Integer)
    @boundscheck 1 <= i <= length(v) || throw(BoundsError(v, i))
    view_func = get_cached_function(v.lib, :glz_vector_complexf64_view)
    view = ccall(view_func, VectorView, (Ptr{Cvoid},), v.ptr)
    unsafe_store!(Ptr{ComplexF64}(view.data), ComplexF64(value), i)
    return value
end

# Make all vector types act as AbstractVector
# This enables full array interface compatibility

# Generic CppVector as AbstractVector
Base.IndexStyle(::Type{<:CppVector}) = IndexLinear()
Base.IndexStyle(::Type{<:Union{CppVectorFloat32, CppVectorFloat64, CppVectorInt32, CppVectorComplexF32, CppVectorComplexF64}}) = IndexLinear()

# Make all vector types iterable
Base.IteratorSize(::Type{<:CppVector}) = Base.HasLength()
Base.IteratorEltype(::Type{<:CppVector}) = Base.HasEltype()
Base.IteratorSize(::Type{<:Union{CppVectorFloat32, CppVectorFloat64, CppVectorInt32, CppVectorComplexF32, CppVectorComplexF64}}) = Base.HasLength()
Base.IteratorEltype(::Type{<:Union{CppVectorFloat32, CppVectorFloat64, CppVectorInt32, CppVectorComplexF32, CppVectorComplexF64}}) = Base.HasEltype()

# Zero-copy array view wrapper
struct CppArrayView{T,N} <: AbstractArray{T,N}
    ptr::Ptr{T}
    dims::NTuple{N,Int}
    
    # Keep reference to parent to prevent GC
    parent::Any
    
    function CppArrayView{T,N}(ptr::Ptr{T}, dims::NTuple{N,Int}, parent) where {T,N}
        new{T,N}(ptr, dims, parent)
    end
end

# Constructor for 1D views from vectors
function CppArrayView(v::CppVectorFloat32)
    view_func = get_cached_function(v.lib, :glz_vector_float32_view)
    view = ccall(view_func, VectorView, (Ptr{Cvoid},), v.ptr)
    CppArrayView{Float32,1}(Ptr{Float32}(view.data), (safe_csize_to_int(view.size),), v)
end

function CppArrayView(v::CppVectorFloat64)
    view_func = get_cached_function(v.lib, :glz_vector_float64_view)
    view = ccall(view_func, VectorView, (Ptr{Cvoid},), v.ptr)
    CppArrayView{Float64,1}(Ptr{Float64}(view.data), (safe_csize_to_int(view.size),), v)
end

function CppArrayView(v::CppVectorInt32)
    view_func = get_cached_function(v.lib, :glz_vector_int32_view)
    view = ccall(view_func, VectorView, (Ptr{Cvoid},), v.ptr)
    CppArrayView{Int32,1}(Ptr{Int32}(view.data), (safe_csize_to_int(view.size),), v)
end

function CppArrayView(v::CppVectorComplexF32)
    view_func = get_cached_function(v.lib, :glz_vector_complexf32_view)
    view = ccall(view_func, VectorView, (Ptr{Cvoid},), v.ptr)
    CppArrayView{ComplexF32,1}(Ptr{ComplexF32}(view.data), (safe_csize_to_int(view.size),), v)
end

function CppArrayView(v::CppVectorComplexF64)
    view_func = get_cached_function(v.lib, :glz_vector_complexf64_view)
    view = ccall(view_func, VectorView, (Ptr{Cvoid},), v.ptr)
    CppArrayView{ComplexF64,1}(Ptr{ComplexF64}(view.data), (safe_csize_to_int(view.size),), v)
end

function CppArrayView(v::CppVector)
    view_func = get_cached_function(v.lib, :glz_vector_view)
    view = ccall(view_func, VectorView, (Ptr{Cvoid}, Ptr{TypeDescriptor}), v.ptr, v.type_desc)
    
    # Get element type
    T = eltype(v)
    CppArrayView{T,1}(Ptr{T}(view.data), (safe_csize_to_int(view.size),), v)
end

# AbstractArray interface for CppArrayView
Base.size(A::CppArrayView) = A.dims
Base.IndexStyle(::Type{<:CppArrayView}) = IndexLinear()

@inline function Base.getindex(A::CppArrayView{T}, i::Int) where T
    @boundscheck checkbounds(A, i)
    unsafe_load(A.ptr, i)
end

@inline function Base.setindex!(A::CppArrayView{T}, val, i::Int) where T
    @boundscheck checkbounds(A, i)
    unsafe_store!(A.ptr, convert(T, val), i)
    val
end

# Enable similar for creating new arrays
Base.similar(A::CppArrayView{T}) where T = Vector{T}(undef, size(A))
Base.similar(A::CppArrayView{T}, ::Type{S}) where {T,S} = Vector{S}(undef, size(A))
Base.similar(::CppArrayView{T}, dims::Dims) where T = Vector{T}(undef, dims)
Base.similar(::CppArrayView{T}, ::Type{S}, dims::Dims) where {T,S} = Vector{S}(undef, dims)

# Broadcasting support - CppArrayView acts like a regular array
Base.BroadcastStyle(::Type{<:CppArrayView}) = Broadcast.ArrayStyle{CppArrayView}()

# Resolve broadcast conflicts with other array types
function Base.BroadcastStyle(::Broadcast.ArrayStyle{CppArrayView}, ::Broadcast.DefaultArrayStyle{N}) where N
    Broadcast.DefaultArrayStyle{N}()
end

# Copy for broadcast
Base.copy(A::CppArrayView) = copy!(similar(A), A)

# Slicing support - create views that share memory
Base.view(A::CppArrayView{T,1}, inds::UnitRange{Int}) where T = begin
    @boundscheck checkbounds(A, inds)
    offset = first(inds) - 1
    len = length(inds)
    CppArrayView{T,1}(A.ptr + offset*sizeof(T), (len,), A.parent)
end

# Single element view
Base.view(A::CppArrayView{T,1}, i::Int) where T = begin
    @boundscheck checkbounds(A, i)
    CppArrayView{T,1}(A.ptr + (i-1)*sizeof(T), (1,), A.parent)
end

# Colon indexing
Base.view(A::CppArrayView, ::Colon) = A

# Make CppVector directly support common array operations
# Direct sum, mean, etc. without creating a view first
Base.sum(v::Union{CppVectorFloat32, CppVectorFloat64, CppVectorInt32, CppVectorComplexF32, CppVectorComplexF64}) = sum(array_view(v))
Base.maximum(v::Union{CppVectorFloat32, CppVectorFloat64, CppVectorInt32}) = maximum(array_view(v))
Base.minimum(v::Union{CppVectorFloat32, CppVectorFloat64, CppVectorInt32}) = minimum(array_view(v))

# Import Statistics functions if available
function __init__()
    # Try to extend Statistics functions if the package is loaded
    @eval begin
        if isdefined(Main, :Statistics)
            Statistics = Main.Statistics
            Statistics.mean(v::Union{CppVectorFloat32, CppVectorFloat64, CppVectorInt32, CppVectorComplexF32, CppVectorComplexF64}) = Statistics.mean(array_view(v))
            Statistics.std(v::Union{CppVectorFloat32, CppVectorFloat64, CppVectorInt32, CppVectorComplexF32, CppVectorComplexF64}) = Statistics.std(array_view(v))
            Statistics.var(v::Union{CppVectorFloat32, CppVectorFloat64, CppVectorInt32, CppVectorComplexF32, CppVectorComplexF64}) = Statistics.var(array_view(v))
        end
    end
end

# Pointer access for advanced usage
Base.pointer(A::CppArrayView) = A.ptr
Base.pointer(A::CppArrayView, i::Integer) = A.ptr + (i-1)*sizeof(eltype(A))

# Convert CppVector to array view automatically in many contexts
Base.convert(::Type{CppArrayView}, v::Union{CppVector, CppVectorFloat32, CppVectorFloat64, CppVectorInt32, CppVectorComplexF32, CppVectorComplexF64}) = CppArrayView(v)

# Create an unsafe_wrap-like function for CppVector
"""
    array_view(v::CppVector)

Create a zero-copy array view of a CppVector that implements the full AbstractArray interface.
The view shares memory with the C++ vector and supports all standard array operations.

# Example
```julia
vec = my_cpp_object.float_data  # CppVectorFloat32
arr = array_view(vec)           # CppArrayView{Float32,1}

# Now use like any Julia array
sum(arr)
arr .= arr .* 2.0
maximum(arr)
```
"""
array_view(v::Union{CppVector, CppVectorFloat32, CppVectorFloat64, CppVectorInt32, CppVectorComplexF32, CppVectorComplexF64}) = CppArrayView(v)

# Element type methods
Base.eltype(::Type{CppVectorFloat32}) = Float32
Base.eltype(::Type{CppVectorFloat64}) = Float64
Base.eltype(::Type{CppVectorInt32}) = Int32
Base.eltype(::Type{CppVectorComplexF32}) = ComplexF32
Base.eltype(::Type{CppVectorComplexF64}) = ComplexF64
Base.eltype(v::CppVector) = begin
    # Get element type from vector type descriptor
    td = unsafe_load(Ptr{ConcreteTypeDescriptor}(v.type_desc))
    if td.index != GLZ_TYPE_VECTOR
        error("Not a vector type descriptor")
    end
    data_ptr = Ptr{UInt8}(v.type_desc) + fieldoffset(ConcreteTypeDescriptor, 2)
    element_ptr = unsafe_load(Ptr{Ptr{TypeDescriptor}}(data_ptr))
    return julia_type_from_descriptor(element_ptr)
end

# push! methods for specialized vectors
function Base.push!(v::CppVectorFloat32, value)
    push_func = get_cached_function(v.lib, :glz_vector_float32_push_back)
    val = Float32(value)
    ccall(push_func, Cvoid, (Ptr{Cvoid}, Cfloat), v.ptr, val)
    return v
end

function Base.push!(v::CppVectorFloat64, value)
    push_func = get_cached_function(v.lib, :glz_vector_float64_push_back)
    val = Float64(value)
    ccall(push_func, Cvoid, (Ptr{Cvoid}, Cdouble), v.ptr, val)
    return v
end

function Base.push!(v::CppVectorInt32, value)
    push_func = get_cached_function(v.lib, :glz_vector_int32_push_back)
    val = Int32(value)
    ccall(push_func, Cvoid, (Ptr{Cvoid}, Cint), v.ptr, val)
    return v
end

function Base.push!(v::CppVectorComplexF32, value)
    push_func = get_cached_function(v.lib, :glz_vector_complexf32_push_back)
    val = ComplexF32(value)
    ccall(push_func, Cvoid, (Ptr{Cvoid}, Cfloat, Cfloat), v.ptr, real(val), imag(val))
    return v
end

function Base.push!(v::CppVectorComplexF64, value)
    push_func = get_cached_function(v.lib, :glz_vector_complexf64_push_back)
    val = ComplexF64(value)
    ccall(push_func, Cvoid, (Ptr{Cvoid}, Cdouble, Cdouble), v.ptr, real(val), imag(val))
    return v
end

# resize! methods for specialized vectors
function Base.resize!(v::CppVectorFloat32, n::Integer)
    resize_func = get_cached_function(v.lib, :glz_vector_float32_resize)
    ccall(resize_func, Cvoid, (Ptr{Cvoid}, Csize_t), v.ptr, n)
    return v
end

function Base.resize!(v::CppVectorFloat64, n::Integer)
    resize_func = get_cached_function(v.lib, :glz_vector_float64_resize)
    ccall(resize_func, Cvoid, (Ptr{Cvoid}, Csize_t), v.ptr, n)
    return v
end

function Base.resize!(v::CppVectorInt32, n::Integer)
    resize_func = get_cached_function(v.lib, :glz_vector_int32_resize)
    ccall(resize_func, Cvoid, (Ptr{Cvoid}, Csize_t), v.ptr, n)
    return v
end

function Base.resize!(v::CppVectorComplexF32, n::Integer)
    resize_func = get_cached_function(v.lib, :glz_vector_complexf32_resize)
    ccall(resize_func, Cvoid, (Ptr{Cvoid}, Csize_t), v.ptr, n)
    return v
end

function Base.resize!(v::CppVectorComplexF64, n::Integer)
    resize_func = get_cached_function(v.lib, :glz_vector_complexf64_resize)
    ccall(resize_func, Cvoid, (Ptr{Cvoid}, Csize_t), v.ptr, n)
    return v
end

function Base.push!(v::CppVector, value)
    push_func = get_cached_function(v.lib, :glz_vector_push_back)
    
    # Get element type from vector type descriptor
    td = unsafe_load(Ptr{ConcreteTypeDescriptor}(v.type_desc))
    if td.index != GLZ_TYPE_VECTOR
        error("Not a vector type descriptor")
    end
    # Extract VectorDesc from union data
    # Get pointer to the data field in the struct
    data_ptr = Ptr{UInt8}(v.type_desc) + fieldoffset(ConcreteTypeDescriptor, 2)
    element_ptr = unsafe_load(Ptr{Ptr{TypeDescriptor}}(data_ptr))
    
    T = julia_type_from_descriptor(element_ptr)
    val = T(value)
    ccall(push_func, Cvoid, (Ptr{Cvoid}, Ptr{TypeDescriptor}, Ptr{Cvoid}), 
          v.ptr, v.type_desc, Ref(val))
    return v
end

function Base.resize!(v::CppVector, n::Integer)
    resize_func = get_cached_function(v.lib, :glz_vector_resize)
    ccall(resize_func, Cvoid, (Ptr{Cvoid}, Ptr{TypeDescriptor}, Csize_t), 
          v.ptr, v.type_desc, n)
    return v
end

"""
    get_instance(lib::CppLibrary, instance_name::String) -> CppStruct

Access a globally registered C++ instance by name.

# Arguments
- `lib`: The loaded C++ library
- `instance_name`: Name of the registered instance

# Returns
- `CppStruct`: Julia wrapper providing direct access to the C++ object

# Example
```julia
lib = Glaze.load("mylib.so")
person = Glaze.get_instance(lib, "global_person")
println(person.name)  # Direct field access
```
"""
function get_instance(lib::CppLibrary, instance_name::String)
    # Get instance pointer
    get_instance_func = get_cached_function(lib, :glz_get_instance)
    ptr = ccall(get_instance_func, Ptr{Cvoid}, (Cstring,), instance_name)
    if ptr == C_NULL
        error("Instance '$instance_name' not found")
    end
    
    # Get instance type name
    get_type_func = get_cached_function(lib, :glz_get_instance_type)
    type_name_ptr = ccall(get_type_func, Cstring, (Cstring,), instance_name)
    if type_name_ptr == C_NULL
        error("Could not get type for instance '$instance_name'")
    end
    type_name = unsafe_string(type_name_ptr)
    
    # Get type info
    info_func = get_cached_function(lib, :glz_get_type_info)
    info_ptr = ccall(info_func, Ptr{ConcreteTypeInfo}, (Cstring,), type_name)
    if info_ptr == C_NULL
        error("Type '$type_name' not registered")
    end
    info = unsafe_load(info_ptr)
    
    # Create a CppStruct that points to the existing instance (not owned by Julia)
    return CppStruct(ptr, info, lib.handle, false)
end

# CppOptional methods for std::optional<T> support
#
# Migration Guide:
# - Instead of `has_value(opt)`, use `!isnothing(opt)`
# - Instead of `!has_value(opt)`, use `isnothing(opt)`
# - Use `opt == nothing` to check if empty
# - Use `something(opt, default)` to get value with default
# - Use `length(opt)` to get 0 or 1
# - Use `Glaze.isempty(opt)` as an alternative empty check

# Internal function - users should use !isnothing(opt) instead
function _has_value(opt::CppOptional{T}) where T
    # Call the C++ interface function with element type descriptor
    has_value_func = get_cached_function(opt.lib, :glz_optional_has_value)
    return ccall(has_value_func, Bool, (Ptr{Cvoid}, Ptr{TypeDescriptor}), opt.ptr, opt.element_type_desc)
end

# Deprecated - use !isnothing(opt) instead
"""
    has_value(opt::CppOptional{T}) -> Bool

Check if the optional contains a value.

**Deprecated**: Use `!isnothing(opt)` instead for more idiomatic Julia code.

# Arguments
- `opt`: The CppOptional instance to check

# Returns
- `Bool`: true if the optional contains a value, false otherwise
"""
function has_value(opt::CppOptional{T}) where T
    Base.depwarn("`has_value(opt)` is deprecated. Use `!isnothing(opt)` for idiomatic Julia code.", :has_value)
    return _has_value(opt)
end

"""
    value(opt::CppOptional{T}) -> T

Get the value from the optional. Throws an error if the optional is empty.

# Arguments
- `opt`: The CppOptional instance

# Returns
- `T`: The contained value

# Throws
- `ErrorException`: If the optional is empty
"""
function value(opt::CppOptional{T}) where T
    if !_has_value(opt)
        error("Optional is empty - cannot get value")
    end
    
    # Get the value from the optional with element type descriptor
    get_value_func = get_cached_function(opt.lib, :glz_optional_get_value)
    value_ptr = ccall(get_value_func, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{TypeDescriptor}), opt.ptr, opt.element_type_desc)
    
    if value_ptr == C_NULL
        error("Failed to get value from optional")
    end
    
    # Load the value based on the type parameter
    # Note: This assumes the type T matches the actual optional element type
    if T == String
        # For strings, value_ptr points to a std::string object
        # Convert it properly using the string wrapper
        return String(CppString(value_ptr, opt.lib))
    else
        return unsafe_load(Ptr{T}(value_ptr))
    end
end

"""
    Base.isnothing(opt::CppOptional{T}) -> Bool

Check if the optional is empty (has no value).

This is the idiomatic Julia way to check if an optional is empty.
Use `!isnothing(opt)` to check if an optional has a value.

# Examples
```julia
if isnothing(opt)
    println("Optional is empty")
else
    println("Optional has value: ", value(opt))
end
```
"""
Base.isnothing(opt::CppOptional{T}) where T = !_has_value(opt)

"""
    Base.something(opt::CppOptional{T}, default) -> T

Get the value from the optional, or return the default if empty.

This is the idiomatic Julia way to handle optional values with defaults.

# Examples
```julia
# Get value or use default
result = something(opt, "default value")
```
"""
function Base.something(opt::CppOptional{T}, default) where T
    return _has_value(opt) ? value(opt) : default
end

# Support for equality comparisons with nothing
Base.:(==)(opt::CppOptional, ::Nothing) = isnothing(opt)
Base.:(==)(::Nothing, opt::CppOptional) = isnothing(opt)

# Note: We can't extend === for custom types as it's a builtin function
# Users should use == or isnothing() for comparisons


# length returns 0 or 1 for optional types
Base.length(opt::CppOptional) = isnothing(opt) ? 0 : 1

# Define our own isempty function (can't extend Base.isempty for builtin)
"""
    isempty(opt::CppOptional) -> Bool

Check if the optional is empty (has no value).
Equivalent to `isnothing(opt)`.
"""
isempty(opt::CppOptional) = isnothing(opt)

"""
    set_value!(opt::CppOptional{T}, val::T) -> Nothing

Set the value of the optional. Creates the value if the optional is empty.

# Arguments
- `opt`: The CppOptional instance to set
- `val`: The value to set (must match the optional's element type)
"""
function set_value!(opt::CppOptional{T}, val::T) where T
    if T == String
        # For strings, use the special string setter function
        set_string_func = get_cached_function(opt.lib, :glz_optional_set_string_value)
        ccall(set_string_func, Cvoid, (Ptr{Cvoid}, Cstring, Csize_t), 
              opt.ptr, val, length(val))
    else
        # For other types, use the generic setter
        set_value_func = get_cached_function(opt.lib, :glz_optional_set_value)
        val_ref = Ref(val)
        ccall(set_value_func, Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{TypeDescriptor}), 
              opt.ptr, val_ref, opt.element_type_desc)
    end
    return nothing
end

"""
    reset!(opt::CppOptional{T}) -> Nothing

Reset the optional to empty state (remove any contained value).

# Arguments
- `opt`: The CppOptional instance to reset
"""
function reset!(opt::CppOptional{T}) where T
    # Reset the optional with element type descriptor
    reset_func = get_cached_function(opt.lib, :glz_optional_reset)
    ccall(reset_func, Cvoid, (Ptr{Cvoid}, Ptr{TypeDescriptor}), opt.ptr, opt.element_type_desc)
    return nothing
end

# Property access for optional fields in structs
function create_optional_wrapper(ptr::Ptr{Cvoid}, lib_handle::Ptr{Cvoid}, element_type_desc::Ptr{TypeDescriptor})
    # Determine the Julia type from the type descriptor
    if element_type_desc == C_NULL
        # For complex types where element descriptor might be null, 
        # default to Any type which can hold any value
        return CppOptional{Any}(ptr, lib_handle, element_type_desc)
    end
    
    desc = unsafe_load(Ptr{ConcreteTypeDescriptor}(element_type_desc))
    
    # Map type descriptor to Julia type with safer handling
    T = if desc.index == GLZ_TYPE_PRIMITIVE
        # Access the primitive description more carefully
        # The data field is a 24-byte union, we need the first byte for primitive kind
        prim_kind = desc.data[1]  # Direct access to the first byte
        if prim_kind == UInt8(1)  # Bool
            Bool
        elseif prim_kind == UInt8(4)  # I32 (int)
            Int32
        elseif prim_kind == UInt8(10)  # F32 (float)
            Float32
        elseif prim_kind == UInt8(11)  # F64 (double)
            Float64
        else
            Any  # Fallback for other primitive types
        end
    elseif desc.index == GLZ_TYPE_STRING
        String
    elseif desc.index == GLZ_TYPE_STRUCT
        Any  # For struct types, use Any since we don't have the Julia type mapping
    elseif desc.index == GLZ_TYPE_VECTOR
        Any  # For vector types, use Any
    else
        Any  # Fallback for complex types
    end
    
    return CppOptional{T}(ptr, lib_handle, element_type_desc)
end

# Helper function to destroy temporary C++ vectors
function destroy_temp_vector(vec_ptr::Ptr{Cvoid}, T::Type, lib_handle::Ptr{Cvoid})
    if T <: Integer
        # Int32 vector
        destroy_func = get_cached_function(lib_handle, :glz_destroy_vector)
        desc = create_vector_descriptor(create_primitive_descriptor(Int32))
        ccall(destroy_func, Cvoid, (Ptr{Cvoid}, Ptr{TypeDescriptor}), vec_ptr, desc)
    elseif T == Float32
        destroy_func = get_cached_function(lib_handle, :glz_destroy_vector)
        desc = create_vector_descriptor(create_primitive_descriptor(Float32))
        ccall(destroy_func, Cvoid, (Ptr{Cvoid}, Ptr{TypeDescriptor}), vec_ptr, desc)
    elseif T <: AbstractFloat
        destroy_func = get_cached_function(lib_handle, :glz_destroy_vector)
        desc = create_vector_descriptor(create_primitive_descriptor(Float64))
        ccall(destroy_func, Cvoid, (Ptr{Cvoid}, Ptr{TypeDescriptor}), vec_ptr, desc)
    elseif T <: AbstractString
        destroy_func = get_cached_function(lib_handle, :glz_destroy_vector)
        # Create string descriptor
        str_key = hash((GLZ_TYPE_STRING,))
        if !haskey(_descriptor_storage, str_key)
            str_desc = ConcreteTypeDescriptor(GLZ_TYPE_STRING, ntuple(i -> 0x00, 32))
            str_container = Ref(str_desc)
            _descriptor_storage[str_key] = str_container
        end
        str_ptr = Base.unsafe_convert(Ptr{ConcreteTypeDescriptor}, _descriptor_storage[str_key])
        desc = create_vector_descriptor(str_ptr)
        ccall(destroy_func, Cvoid, (Ptr{Cvoid}, Ptr{TypeDescriptor}), vec_ptr, desc)
    elseif T <: Complex{Float32}
        destroy_func = get_cached_function(lib_handle, :glz_destroy_vector)
        elem_desc = create_complex_descriptor(Float32)
        desc = create_vector_descriptor(elem_desc)
        ccall(destroy_func, Cvoid, (Ptr{Cvoid}, Ptr{TypeDescriptor}), vec_ptr, desc)
    end
end

# Helper function to extract vector data immediately before destruction
function extract_vector_data(vec_ptr::Ptr{Cvoid}, vec_type_desc_ptr::Ptr{TypeDescriptor}, lib_handle::Ptr{Cvoid})
    # Load the descriptors
    vec_desc_ptr = vec_type_desc_ptr + fieldoffset(ConcreteTypeDescriptor, 2)
    vec_desc = unsafe_load(Ptr{VectorDesc}(vec_desc_ptr))
    elem_type_desc = unsafe_load(Ptr{ConcreteTypeDescriptor}(vec_desc.element_type))
    
    if elem_type_desc.index == GLZ_TYPE_PRIMITIVE
        prim_desc_ptr = vec_desc.element_type + fieldoffset(ConcreteTypeDescriptor, 2)
        prim_desc = unsafe_load(Ptr{PrimitiveDesc}(prim_desc_ptr))
        
        if prim_desc.kind == 4  # Int32
            view_func = get_cached_function(lib_handle, :glz_vector_int32_view)
            vec_view = ccall(view_func, VectorView, (Ptr{Cvoid},), vec_ptr)
            result = Vector{Int32}(undef, vec_view.size)
            unsafe_copyto!(pointer(result), Ptr{Int32}(vec_view.data), vec_view.size)
            return result
        elseif prim_desc.kind == 10  # Float32
            view_func = get_cached_function(lib_handle, :glz_vector_float32_view)
            vec_view = ccall(view_func, VectorView, (Ptr{Cvoid},), vec_ptr)
            result = Vector{Float32}(undef, vec_view.size)
            unsafe_copyto!(pointer(result), Ptr{Float32}(vec_view.data), vec_view.size)
            return result
        elseif prim_desc.kind == 11  # Float64
            view_func = get_cached_function(lib_handle, :glz_vector_float64_view)
            vec_view = ccall(view_func, VectorView, (Ptr{Cvoid},), vec_ptr)
            result = Vector{Float64}(undef, vec_view.size)
            unsafe_copyto!(pointer(result), Ptr{Float64}(vec_view.data), vec_view.size)
            return result
        end
    elseif elem_type_desc.index == GLZ_TYPE_COMPLEX
        complex_desc_ptr = vec_desc.element_type + fieldoffset(ConcreteTypeDescriptor, 2)
        complex_desc = unsafe_load(Ptr{ComplexDesc}(complex_desc_ptr))
        
        if complex_desc.kind == 0  # ComplexF32
            view_func = get_cached_function(lib_handle, :glz_vector_complexf32_view)
            vec_view = ccall(view_func, VectorView, (Ptr{Cvoid},), vec_ptr)
            result = Vector{ComplexF32}(undef, vec_view.size)
            unsafe_copyto!(pointer(result), Ptr{ComplexF32}(vec_view.data), vec_view.size)
            return result
        else  # ComplexF64
            view_func = get_cached_function(lib_handle, :glz_vector_complexf64_view)
            vec_view = ccall(view_func, VectorView, (Ptr{Cvoid},), vec_ptr)
            result = Vector{ComplexF64}(undef, vec_view.size)
            unsafe_copyto!(pointer(result), Ptr{ComplexF64}(vec_view.data), vec_view.size)
            return result
        end
    elseif elem_type_desc.index == GLZ_TYPE_STRING
        # TODO: Handle string vectors
        return String[]
    end
    
    # Fallback
    return Int32[]
end

# extract_pair_data removed - pairs are now handled as structs with first/second members

# Helper function to convert C++ vector results to Julia arrays
function convert_vector_result(vec_ptr::Ptr{Cvoid}, vec_type_desc_ptr::Ptr{TypeDescriptor}, lib_handle::Ptr{Cvoid})
    # Load the type descriptor
    vec_type_desc = unsafe_load(Ptr{ConcreteTypeDescriptor}(vec_type_desc_ptr))
    
    # Get the vector descriptor
    vec_desc_ptr = vec_type_desc_ptr + fieldoffset(ConcreteTypeDescriptor, 2)
    vec_desc = unsafe_load(Ptr{VectorDesc}(vec_desc_ptr))
    
    # Get element type
    elem_type_desc = unsafe_load(Ptr{ConcreteTypeDescriptor}(vec_desc.element_type))
    
    if elem_type_desc.index == GLZ_TYPE_PRIMITIVE
        prim_desc_ptr = vec_desc.element_type + fieldoffset(ConcreteTypeDescriptor, 2)
        prim_desc = unsafe_load(Ptr{PrimitiveDesc}(prim_desc_ptr))
        
        if prim_desc.kind == 4  # Int32
            # Use specialized int32 view function
            view_func_int32 = Libdl.dlsym(lib_handle, :glz_vector_int32_view)
            view_int32 = ccall(view_func_int32, VectorView, (Ptr{Cvoid},), vec_ptr)
            
            # Copy data to Julia array
            result = Vector{Int32}(undef, view_int32.size)
            unsafe_copyto!(pointer(result), Ptr{Int32}(view_int32.data), view_int32.size)
            return result
        elseif prim_desc.kind == 10  # Float32
            # Use specialized float32 view function
            view_func_float32 = Libdl.dlsym(lib_handle, :glz_vector_float32_view)
            view_float32 = ccall(view_func_float32, VectorView, (Ptr{Cvoid},), vec_ptr)
            
            result = Vector{Float32}(undef, view_float32.size)
            unsafe_copyto!(pointer(result), Ptr{Float32}(view_float32.data), view_float32.size)
            return result
        elseif prim_desc.kind == 11  # Float64
            # Use specialized float64 view function
            view_func_float64 = Libdl.dlsym(lib_handle, :glz_vector_float64_view)
            view_float64 = ccall(view_func_float64, VectorView, (Ptr{Cvoid},), vec_ptr)
            
            result = Vector{Float64}(undef, view_float64.size)
            unsafe_copyto!(pointer(result), Ptr{Float64}(view_float64.data), view_float64.size)
            return result
        end
    elseif elem_type_desc.index == GLZ_TYPE_STRING
        # Handle string vector
        result = String[]
        # TODO: Need specialized function to iterate through C++ string vector
        return result
    elseif elem_type_desc.index == GLZ_TYPE_COMPLEX
        complex_desc_ptr = vec_desc.element_type + fieldoffset(ConcreteTypeDescriptor, 2)
        complex_desc = unsafe_load(Ptr{ComplexDesc}(complex_desc_ptr))
        
        if complex_desc.kind == 0  # Float complex
            # Use specialized complex float32 view function
            view_func_cf32 = Libdl.dlsym(lib_handle, :glz_vector_complexf32_view)
            view_cf32 = ccall(view_func_cf32, VectorView, (Ptr{Cvoid},), vec_ptr)
            
            result = Vector{ComplexF32}(undef, view_cf32.size)
            unsafe_copyto!(pointer(result), Ptr{ComplexF32}(view_cf32.data), view_cf32.size)
            return result
        else  # Double complex
            # Use specialized complex float64 view function
            view_func_cf64 = Libdl.dlsym(lib_handle, :glz_vector_complexf64_view)
            view_cf64 = ccall(view_func_cf64, VectorView, (Ptr{Cvoid},), vec_ptr)
            
            result = Vector{ComplexF64}(undef, view_cf64.size)
            unsafe_copyto!(pointer(result), Ptr{ComplexF64}(view_cf64.data), view_cf64.size)
            return result
        end
    end
    
    # Fallback - return empty array
    return []
end

# Helper function to create temporary C++ string from Julia string
function create_temp_string(julia_str::AbstractString, lib_handle::Ptr{Cvoid})
    create_func = Libdl.dlsym(lib_handle, :glz_create_string)
    str_data = String(julia_str)  # Ensure it's a concrete String
    str_ptr = ccall(create_func, Ptr{Cvoid}, (Ptr{UInt8}, Csize_t), 
                    pointer(str_data), length(str_data))
    return str_ptr
end

# Helper function to create temporary C++ vectors from Julia arrays
function create_temp_vector(julia_vec::AbstractVector, lib_handle::Ptr{Cvoid})
    T = eltype(julia_vec)
    
    if T <: Integer
        # Convert to Int32 for C++ compatibility
        create_func = Libdl.dlsym(lib_handle, :glz_create_vector_int32)
        vec_ptr = ccall(create_func, Ptr{Cvoid}, ())
        
        # Copy data
        int32_data = Int32.(julia_vec)
        set_func = Libdl.dlsym(lib_handle, :glz_vector_int32_set_data)
        ccall(set_func, Cvoid, (Ptr{Cvoid}, Ptr{Int32}, Csize_t), 
              vec_ptr, int32_data, length(int32_data))
        
        return vec_ptr
    elseif T == Float32
        create_func = Libdl.dlsym(lib_handle, :glz_create_vector_float32)
        vec_ptr = ccall(create_func, Ptr{Cvoid}, ())
        
        set_func = Libdl.dlsym(lib_handle, :glz_vector_float32_set_data)
        ccall(set_func, Cvoid, (Ptr{Cvoid}, Ptr{Float32}, Csize_t), 
              vec_ptr, julia_vec, length(julia_vec))
        
        return vec_ptr
    elseif T <: AbstractFloat
        # Convert to Float64 for C++ compatibility
        create_func = Libdl.dlsym(lib_handle, :glz_create_vector_float64)
        vec_ptr = ccall(create_func, Ptr{Cvoid}, ())
        
        float64_data = Float64.(julia_vec)
        set_func = Libdl.dlsym(lib_handle, :glz_vector_float64_set_data)
        ccall(set_func, Cvoid, (Ptr{Cvoid}, Ptr{Float64}, Csize_t), 
              vec_ptr, float64_data, length(float64_data))
        
        return vec_ptr
    elseif T <: AbstractString
        create_func = Libdl.dlsym(lib_handle, :glz_create_vector_string)
        vec_ptr = ccall(create_func, Ptr{Cvoid}, ())
        
        push_func = Libdl.dlsym(lib_handle, :glz_vector_string_push_back)
        for str in julia_vec
            ccall(push_func, Cvoid, (Ptr{Cvoid}, Cstring, Csize_t), 
                  vec_ptr, str, length(str))
        end
        
        return vec_ptr
    elseif T <: Complex{Float32}
        # Create vector descriptor for complex float
        elem_desc = create_complex_descriptor(Float32)
        vec_desc = create_vector_descriptor(elem_desc)
        
        create_func = Libdl.dlsym(lib_handle, :glz_create_vector)
        vec_ptr = ccall(create_func, Ptr{Cvoid}, (Ptr{TypeDescriptor},), vec_desc)
        
        # Push complex values one by one
        push_func = Libdl.dlsym(lib_handle, :glz_vector_complexf32_push_back)
        for c in julia_vec
            ccall(push_func, Cvoid, (Ptr{Cvoid}, Cfloat, Cfloat), 
                  vec_ptr, real(c), imag(c))
        end
        
        return vec_ptr
    elseif T <: Complex{Float64}
        # Create vector descriptor for complex double
        elem_desc = create_complex_descriptor(Float64)
        vec_desc = create_vector_descriptor(elem_desc)
        
        create_func = Libdl.dlsym(lib_handle, :glz_create_vector)
        vec_ptr = ccall(create_func, Ptr{Cvoid}, (Ptr{TypeDescriptor},), vec_desc)
        
        # Push complex values one by one
        push_func = Libdl.dlsym(lib_handle, :glz_vector_complexf64_push_back)
        for c in julia_vec
            ccall(push_func, Cvoid, (Ptr{Cvoid}, Cdouble, Cdouble), 
                  vec_ptr, real(c), imag(c))
        end
        
        return vec_ptr
    else
        error("Unsupported vector element type: $T")
    end
end

# Helper to create type descriptors  
# Note: These descriptors need to be kept alive for the duration of their use
const _descriptor_storage = Dict{UInt64, Any}()

# Cache for vector sizes and alignments to avoid repeated FFI calls
const _vector_size_cache = Dict{Symbol, Tuple{Csize_t, Csize_t}}()

# Get size and alignment for a vector type
function get_vector_size_info(element_type::Symbol, lib_handle::Ptr{Cvoid})
    # Check cache first
    if haskey(_vector_size_cache, element_type)
        return _vector_size_cache[element_type]
    end
    
    # Query from C++
    sizeof_name = Symbol("glz_sizeof_vector_", element_type)
    alignof_name = Symbol("glz_alignof_vector_", element_type)
    
    sizeof_func = Libdl.dlsym(lib_handle, sizeof_name)
    alignof_func = Libdl.dlsym(lib_handle, alignof_name)
    
    vec_size = ccall(sizeof_func, Csize_t, ())
    vec_align = ccall(alignof_func, Csize_t, ())
    
    # Cache the result
    _vector_size_cache[element_type] = (vec_size, vec_align)
    
    return (vec_size, vec_align)
end

# Allocate properly aligned buffer for vector
function allocate_vector_buffer(element_type::Symbol, lib_handle::Ptr{Cvoid})
    vec_size, vec_align = get_vector_size_info(element_type, lib_handle)
    
    # Ensure we allocate enough for alignment
    # Use UInt8 array for byte-level control
    buffer = Vector{UInt8}(undef, vec_size + vec_align - 1)
    
    # Get aligned pointer within the buffer
    ptr = pointer(buffer)
    aligned_ptr = ptr + (vec_align - Int(ptr) % vec_align) % vec_align
    
    # Return buffer and aligned pointer
    # Buffer must be kept alive!
    return (buffer, aligned_ptr)
end

function create_primitive_descriptor(T::Type)
    # Create a unique key for this descriptor
    key = hash((GLZ_TYPE_PRIMITIVE, T))
    
    # Check if we already have this descriptor
    if haskey(_descriptor_storage, key)
        return Base.unsafe_convert(Ptr{ConcreteTypeDescriptor}, _descriptor_storage[key])
    end
    
    # Create new descriptor with proper initialization
    desc = ConcreteTypeDescriptor(GLZ_TYPE_PRIMITIVE, ntuple(i -> 0x00, 32))
    
    # Create and store primitive descriptor (now using UInt64)
    prim = PrimitiveDesc(UInt64(0))
    if T == Bool
        prim = PrimitiveDesc(UInt64(1))
    elseif T == Int32
        prim = PrimitiveDesc(UInt64(4))
    elseif T == Float32
        prim = PrimitiveDesc(UInt64(10))
    elseif T == Float64
        prim = PrimitiveDesc(UInt64(11))
    else
        error("Unsupported primitive type: $T")
    end
    
    # Store the descriptor in a stable location
    desc_container = Ref(desc)
    desc_ptr = Base.unsafe_convert(Ptr{ConcreteTypeDescriptor}, desc_container)
    prim_ptr = desc_ptr + fieldoffset(ConcreteTypeDescriptor, 2)
    unsafe_store!(Ptr{PrimitiveDesc}(prim_ptr), prim)
    
    # Keep the container alive
    _descriptor_storage[key] = desc_container
    
    return desc_ptr
end

function create_complex_descriptor(T::Type)
    # Create a unique key for this descriptor
    key = hash((GLZ_TYPE_COMPLEX, T))
    
    # Check if we already have this descriptor
    if haskey(_descriptor_storage, key)
        return Base.unsafe_convert(Ptr{ConcreteTypeDescriptor}, _descriptor_storage[key])
    end
    
    desc = ConcreteTypeDescriptor(GLZ_TYPE_COMPLEX, ntuple(i -> 0x00, 32))
    
    complex_kind = T == Float32 ? UInt64(0) : UInt64(1)
    complex = ComplexDesc(complex_kind)
    
    # Store the descriptor in a stable location
    desc_container = Ref(desc)
    desc_ptr = Base.unsafe_convert(Ptr{ConcreteTypeDescriptor}, desc_container)
    complex_ptr = desc_ptr + fieldoffset(ConcreteTypeDescriptor, 2)
    unsafe_store!(Ptr{ComplexDesc}(complex_ptr), complex)
    
    # Keep the container alive
    _descriptor_storage[key] = desc_container
    
    return desc_ptr
end

function create_vector_descriptor(elem_type_ptr::Ptr{ConcreteTypeDescriptor})
    # Create a unique key for this descriptor
    key = hash((GLZ_TYPE_VECTOR, UInt64(elem_type_ptr)))
    
    # Check if we already have this descriptor
    if haskey(_descriptor_storage, key)
        return Base.unsafe_convert(Ptr{ConcreteTypeDescriptor}, _descriptor_storage[key])
    end
    
    desc = ConcreteTypeDescriptor(GLZ_TYPE_VECTOR, ntuple(i -> 0x00, 32))
    
    vec = VectorDesc(elem_type_ptr)
    
    # Store the descriptor in a stable location
    desc_container = Ref(desc)
    desc_ptr = Base.unsafe_convert(Ptr{ConcreteTypeDescriptor}, desc_container)
    vec_ptr = desc_ptr + fieldoffset(ConcreteTypeDescriptor, 2)
    unsafe_store!(Ptr{VectorDesc}(vec_ptr), vec)
    
    # Keep the container alive
    _descriptor_storage[key] = desc_container
    
    return desc_ptr
end


# Make CppMemberFunction callable
function (func::CppMemberFunction)(args...)
    # Load the member info to get function signature
    member = unsafe_load(func.member_info)
    
    if member.kind != 1  # Must be a member function
        error("Invalid member function call")
    end
    
    if member.type == C_NULL || unsafe_load(Ptr{ConcreteTypeDescriptor}(member.type)).index != GLZ_TYPE_FUNCTION
        error("Invalid function type descriptor")
    end
    
    # Get function descriptor to determine return type
    type_desc = unsafe_load(Ptr{ConcreteTypeDescriptor}(member.type))
    # The function descriptor is in the data union, which starts after index
    func_desc_ptr = Ptr{FunctionDesc}(member.type + fieldoffset(ConcreteTypeDescriptor, 2))
    
    # Load the FunctionDesc struct directly (now properly aligned with padding)
    func_desc = unsafe_load(func_desc_ptr)
    
    
    
    # Determine return type from the function descriptor
    return_type_desc = if func_desc.return_type != C_NULL
        unsafe_load(Ptr{ConcreteTypeDescriptor}(func_desc.return_type))
    else
        # Return type descriptor is null - this happens for unsupported types
        nothing
    end
    
    # Check that we have the right number of arguments
    if length(args) != func_desc.param_count
        error("Function $(func.name) expects $(func_desc.param_count) arguments, got $(length(args))")
    end
    
    # Prepare arguments array
    if length(args) > 0
        # Convert Julia arguments to C-compatible form
        c_args = Vector{Ptr{Cvoid}}(undef, length(args))
        arg_storage = []  # Keep references to prevent GC
        
        # Get parameter types from function descriptor
        if func_desc.param_types == C_NULL
            error("Function $(func.name) has null parameter types but expects $(func_desc.param_count) arguments")
        end
        param_types = unsafe_wrap(Array, func_desc.param_types, func_desc.param_count)
        
        for (i, arg) in enumerate(args)
            # Get expected parameter type
            if i > length(param_types)
                error("Parameter index $(i) out of range for function $(func.name)")
            end
            param_type_ptr = param_types[i]
            if param_type_ptr == C_NULL
                error("Parameter $(i) of function $(func.name) has null type descriptor")
            end
            
            param_type_desc = unsafe_load(Ptr{ConcreteTypeDescriptor}(param_type_ptr))
            
            # Convert based on expected type
            if param_type_desc.index == GLZ_TYPE_PRIMITIVE
                prim_desc = unsafe_load(Ptr{PrimitiveDesc}(Ptr{UInt8}(param_type_ptr) + fieldoffset(ConcreteTypeDescriptor, 2)))
                
                if prim_desc.kind == 1 && isa(arg, Bool)  # Bool
                    c_val = Ref{Bool}(arg)
                    push!(arg_storage, c_val)
                    c_args[i] = Ptr{Cvoid}(pointer_from_objref(c_val))
                elseif prim_desc.kind == 4 && isa(arg, Integer)  # Int32
                    c_val = Ref{Int32}(Int32(arg))
                    push!(arg_storage, c_val)
                    c_args[i] = Ptr{Cvoid}(pointer_from_objref(c_val))
                elseif prim_desc.kind == 5 && isa(arg, Integer)  # Int64  
                    c_val = Ref{Int64}(Int64(arg))
                    push!(arg_storage, c_val)
                    c_args[i] = Ptr{Cvoid}(pointer_from_objref(c_val))
                elseif prim_desc.kind == 10 && isa(arg, Number)  # Float32 - accept any number
                    c_val = Ref{Float32}(Float32(arg))
                    push!(arg_storage, c_val)
                    c_args[i] = Ptr{Cvoid}(pointer_from_objref(c_val))
                elseif prim_desc.kind == 11 && isa(arg, Number)  # Float64 - accept any number
                    c_val = Ref{Float64}(Float64(arg))
                    push!(arg_storage, c_val)
                    c_args[i] = Ptr{Cvoid}(pointer_from_objref(c_val))
                elseif prim_desc.kind == 6 && isa(arg, Integer)  # UInt8
                    c_val = Ref{UInt8}(UInt8(arg))
                    push!(arg_storage, c_val)
                    c_args[i] = Ptr{Cvoid}(pointer_from_objref(c_val))
                elseif prim_desc.kind == 7 && isa(arg, Integer)  # UInt16
                    c_val = Ref{UInt16}(UInt16(arg))
                    push!(arg_storage, c_val)
                    c_args[i] = Ptr{Cvoid}(pointer_from_objref(c_val))
                elseif prim_desc.kind == 8 && isa(arg, Integer)  # UInt32
                    c_val = Ref{UInt32}(UInt32(arg))
                    push!(arg_storage, c_val)
                    c_args[i] = Ptr{Cvoid}(pointer_from_objref(c_val))
                elseif prim_desc.kind == 9 && isa(arg, Integer)  # UInt64/size_t
                    c_val = Ref{UInt64}(UInt64(arg))
                    push!(arg_storage, c_val)
                    c_args[i] = Ptr{Cvoid}(pointer_from_objref(c_val))
                else
                    error("Cannot convert argument $(i) of type $(typeof(arg)) to expected primitive type $(prim_desc.kind)")
                end
            elseif param_type_desc.index == GLZ_TYPE_STRING && isa(arg, AbstractString)
                # Create temporary std::string
                create_func = Libdl.dlsym(func.lib_handle, :glz_create_string)
                str_ptr = ccall(create_func, Ptr{Cvoid}, (Cstring, Csize_t), arg, length(arg))
                push!(arg_storage, str_ptr)
                c_args[i] = str_ptr
            elseif param_type_desc.index == GLZ_TYPE_VECTOR && isa(arg, AbstractVector)
                # Handle vector parameters
                vec_ptr = create_temp_vector(arg, func.lib_handle)
                push!(arg_storage, vec_ptr)  # Store to prevent GC and for cleanup
                c_args[i] = vec_ptr
            elseif param_type_desc.index == GLZ_TYPE_VARIANT && isa(arg, CppVariant)
                # Handle variant parameters - pass the variant pointer directly
                c_args[i] = arg.ptr
            else
                error("Cannot convert argument $(i) of type $(typeof(arg)) to expected C++ type (index=$(param_type_desc.index))")
            end
        end
        
        # Allocate result buffer based on return type
        result_buffer, result_type = if return_type_desc === nothing
            # Void return
            (C_NULL, Nothing)
        elseif return_type_desc.index == GLZ_TYPE_PRIMITIVE
            prim_desc = unsafe_load(Ptr{PrimitiveDesc}(Ptr{UInt8}(func_desc.return_type) + fieldoffset(ConcreteTypeDescriptor, 2)))
            if prim_desc.kind == 1  # bool
                (Ref{Bool}(false), Bool)
            elseif prim_desc.kind == 4  # int32
                (Ref{Int32}(0), Int32)
            elseif prim_desc.kind == 10  # float
                (Ref{Float32}(0.0f0), Float32)
            elseif prim_desc.kind == 11  # double
                (Ref{Float64}(0.0), Float64)
            else
                (Ref{Float64}(0.0), Float64)  # Default fallback
            end
        elseif return_type_desc.index == GLZ_TYPE_STRING
            # String return - allocate space for std::string
            buffer = Vector{UInt8}(undef, 256)  # Allocate space for string object
            (pointer(buffer), String)
        elseif return_type_desc.index == GLZ_TYPE_VECTOR
            # Vector return - determine element type and allocate properly
            vec_desc_ptr = func_desc.return_type + fieldoffset(ConcreteTypeDescriptor, 2)
            vec_desc = unsafe_load(Ptr{VectorDesc}(vec_desc_ptr))
            elem_type_desc = unsafe_load(Ptr{ConcreteTypeDescriptor}(vec_desc.element_type))
            
            # Determine element type symbol for size query
            elem_symbol = if elem_type_desc.index == GLZ_TYPE_PRIMITIVE
                prim_desc_ptr = vec_desc.element_type + fieldoffset(ConcreteTypeDescriptor, 2)
                prim_desc = unsafe_load(Ptr{PrimitiveDesc}(prim_desc_ptr))
                
                if prim_desc.kind == 4  # Int32
                    :int32
                elseif prim_desc.kind == 10  # Float32
                    :float32
                elseif prim_desc.kind == 11  # Float64
                    :float64
                else
                    :int32  # Fallback
                end
            elseif elem_type_desc.index == GLZ_TYPE_STRING
                :string
            elseif elem_type_desc.index == GLZ_TYPE_COMPLEX
                complex_desc_ptr = vec_desc.element_type + fieldoffset(ConcreteTypeDescriptor, 2)
                complex_desc = unsafe_load(Ptr{ComplexDesc}(complex_desc_ptr))
                complex_desc.kind == 0 ? :complexf32 : :complexf64
            else
                :int32  # Fallback
            end
            
            # Allocate properly sized and aligned buffer
            vec_buffer, aligned_ptr = allocate_vector_buffer(elem_symbol, func.lib_handle)
            # Store buffer in the higher scope to keep it alive
            buffer = vec_buffer
            (aligned_ptr, :vector)
        elseif return_type_desc.index == GLZ_TYPE_STRUCT
            # Check if this is a std::pair by examining the struct
            struct_desc_ptr = func_desc.return_type + fieldoffset(ConcreteTypeDescriptor, 2)
            struct_desc = unsafe_load(Ptr{StructDesc}(struct_desc_ptr))
            
            # Allocate buffer for struct return
            buffer = Vector{UInt8}(undef, 32)  # 32 bytes should be enough for most pairs
            (pointer(buffer), :struct)
        elseif return_type_desc.index == GLZ_TYPE_VARIANT
            # Allocate buffer for variant return
            buffer = Vector{UInt8}(undef, 64)  # Allocate space for variant
            # Ensure 16-byte alignment
            aligned_ptr = Ptr{UInt8}(div(UInt(pointer(buffer)) + 15, 16) * 16)
            (aligned_ptr, :variant)
        elseif return_type_desc.index == GLZ_TYPE_SHARED_FUTURE
            # Allocate buffer for shared_future (needs more space and alignment)
            buffer = Vector{UInt8}(undef, 64)  # Larger buffer for shared_future
            # Ensure 16-byte alignment
            aligned_ptr = Ptr{UInt8}(div(UInt(pointer(buffer)) + 15, 16) * 16)
            (aligned_ptr, :shared_future)
        else
            (Ref{Float64}(0.0), Float64)  # Default fallback
        end
        
        # Call the C++ function with type name
        call_func = Libdl.dlsym(func.lib_handle, :glz_call_member_function_with_type)
        result_ptr = ccall(call_func, Ptr{Cvoid}, 
                          (Ptr{Cvoid}, Cstring, Ptr{MemberInfo}, Ptr{Ptr{Cvoid}}, Ptr{Cvoid}),
                          func.obj_ptr, func.type_name, func.member_info, c_args, result_buffer)
        
        # Clean up temporary objects
        for (i, stored) in enumerate(arg_storage)
            if isa(stored, Ptr{Cvoid})
                if isa(args[i], AbstractVector)
                    # This is a temporary vector that needs cleanup
                    destroy_temp_vector(stored, eltype(args[i]), func.lib_handle)
                elseif isa(args[i], AbstractString)
                    # This is a temporary string that needs cleanup
                    destroy_func = Libdl.dlsym(func.lib_handle, :glz_destroy_string)
                    ccall(destroy_func, Cvoid, (Ptr{Cvoid},), stored)
                end
            end
        end
        
        if result_ptr != C_NULL && result_type != Nothing
            # Return the result based on type
            if result_type == String
                # For string results, call the string C API to get the result
                string_func = Libdl.dlsym(func.lib_handle, :glz_string_c_str)
                c_str = ccall(string_func, Ptr{UInt8}, (Ptr{Cvoid},), result_ptr)
                return unsafe_string(c_str)
            elseif result_type == :vector && return_type_desc.index == GLZ_TYPE_VECTOR
                # The result_buffer contains the vector object constructed via placement new
                # Extract data immediately before it goes out of scope
                return extract_vector_data(result_ptr, func_desc.return_type, func.lib_handle)
            elseif result_type == :struct && return_type_desc.index == GLZ_TYPE_STRUCT
                # Handle struct returns - check if it's a pair
                struct_desc_ptr = func_desc.return_type + fieldoffset(ConcreteTypeDescriptor, 2)
                struct_desc = unsafe_load(Ptr{StructDesc}(struct_desc_ptr))
                
                # Try to get type info
                type_info_ptr = struct_desc.info
                
                # If info is null but we have a type name, try to look it up
                if type_info_ptr == C_NULL && struct_desc.type_name != C_NULL
                    type_name = unsafe_string(struct_desc.type_name)
                    get_type_info = Libdl.dlsym(func.lib_handle, :glz_get_type_info)
                    type_info_ptr = ccall(get_type_info, Ptr{ConcreteTypeInfo}, (Cstring,), type_name)
                end
                
                if type_info_ptr != C_NULL
                    type_info = unsafe_load(type_info_ptr)
                    if type_info.member_count == 2
                        # Check member names to see if this is a pair
                        # Read MemberInfo structs
                        member1 = unsafe_load(type_info.members, 1)
                        member2 = unsafe_load(type_info.members, 2)
                        name1 = unsafe_string(member1.name)
                        name2 = unsafe_string(member2.name)
                        
                        if name1 == "first" && name2 == "second"
                            # This is a pair - extract values
                            first_ptr = ccall(member1.getter, Ptr{Cvoid}, (Ptr{Cvoid},), result_ptr)
                            second_ptr = ccall(member2.getter, Ptr{Cvoid}, (Ptr{Cvoid},), result_ptr)
                            
                            # For now, assume doubles (for findMinMax)
                            first_val = unsafe_load(Ptr{Float64}(first_ptr))
                            second_val = unsafe_load(Ptr{Float64}(second_ptr))
                            return (first_val, second_val)
                        end
                    end
                end
                
                # Not a pair or couldn't extract - return nothing for now
                return nothing
            elseif result_type == :variant && return_type_desc.index == GLZ_TYPE_VARIANT
                # Return a CppVariant wrapper
                return CppVariant(result_ptr, func.lib_handle, func_desc.return_type)
            elseif result_type == :shared_future && return_type_desc.index == GLZ_TYPE_SHARED_FUTURE
                # Extract the shared_future descriptor
                future_desc_ptr = func_desc.return_type + fieldoffset(ConcreteTypeDescriptor, 2)
                future_desc = unsafe_load(Ptr{SharedFutureDesc}(future_desc_ptr))
                
                # Return a CppSharedFuture wrapper
                return CppSharedFuture(result_ptr, func.lib_handle)
            else
                return result_buffer[]
            end
        else
            # Function returns void or failed
            return nothing
        end
    else
        # No arguments - call directly with same return type logic
        return_type_desc = if func_desc.return_type != C_NULL
            unsafe_load(Ptr{ConcreteTypeDescriptor}(func_desc.return_type))
        else
            nothing
        end
        
        result_buffer, result_type = if return_type_desc === nothing
            # Void return
            (C_NULL, Nothing)
        elseif return_type_desc.index == GLZ_TYPE_PRIMITIVE
            prim_desc = unsafe_load(Ptr{PrimitiveDesc}(Ptr{UInt8}(func_desc.return_type) + fieldoffset(ConcreteTypeDescriptor, 2)))
            if prim_desc.kind == 1  # bool
                (Ref{Bool}(false), Bool)
            elseif prim_desc.kind == 4  # int32
                (Ref{Int32}(0), Int32)
            elseif prim_desc.kind == 10  # float
                (Ref{Float32}(0.0f0), Float32)
            elseif prim_desc.kind == 11  # double
                (Ref{Float64}(0.0), Float64)
            else
                (Ref{Float64}(0.0), Float64)  # Default fallback
            end
        elseif return_type_desc.index == GLZ_TYPE_STRING
            # String return
            buffer = Vector{UInt8}(undef, 256)
            (pointer(buffer), String)
        elseif return_type_desc.index == GLZ_TYPE_VECTOR
            # Vector return - determine element type and allocate properly
            vec_desc_ptr = func_desc.return_type + fieldoffset(ConcreteTypeDescriptor, 2)
            vec_desc = unsafe_load(Ptr{VectorDesc}(vec_desc_ptr))
            elem_type_desc = unsafe_load(Ptr{ConcreteTypeDescriptor}(vec_desc.element_type))
            
            # Determine element type symbol for size query
            elem_symbol = if elem_type_desc.index == GLZ_TYPE_PRIMITIVE
                prim_desc_ptr = vec_desc.element_type + fieldoffset(ConcreteTypeDescriptor, 2)
                prim_desc = unsafe_load(Ptr{PrimitiveDesc}(prim_desc_ptr))
                
                if prim_desc.kind == 4  # Int32
                    :int32
                elseif prim_desc.kind == 10  # Float32
                    :float32
                elseif prim_desc.kind == 11  # Float64
                    :float64
                else
                    :int32  # Fallback
                end
            elseif elem_type_desc.index == GLZ_TYPE_STRING
                :string
            elseif elem_type_desc.index == GLZ_TYPE_COMPLEX
                complex_desc_ptr = vec_desc.element_type + fieldoffset(ConcreteTypeDescriptor, 2)
                complex_desc = unsafe_load(Ptr{ComplexDesc}(complex_desc_ptr))
                complex_desc.kind == 0 ? :complexf32 : :complexf64
            else
                :int32  # Fallback
            end
            
            # Allocate properly sized and aligned buffer
            vec_buffer, aligned_ptr = allocate_vector_buffer(elem_symbol, func.lib_handle)
            # Store buffer in the higher scope to keep it alive
            buffer = vec_buffer
            (aligned_ptr, :vector)
        elseif return_type_desc.index == GLZ_TYPE_STRUCT
            # Check if this is a std::pair by examining the struct
            struct_desc_ptr = func_desc.return_type + fieldoffset(ConcreteTypeDescriptor, 2)
            struct_desc = unsafe_load(Ptr{StructDesc}(struct_desc_ptr))
            
            # Allocate buffer for struct return
            buffer = Vector{UInt8}(undef, 32)  # 32 bytes should be enough for most pairs
            (pointer(buffer), :struct)
        elseif return_type_desc.index == GLZ_TYPE_VARIANT
            # Allocate buffer for variant return
            buffer = Vector{UInt8}(undef, 64)  # Allocate space for variant
            # Ensure 16-byte alignment
            aligned_ptr = Ptr{UInt8}(div(UInt(pointer(buffer)) + 15, 16) * 16)
            (aligned_ptr, :variant)
        elseif return_type_desc.index == GLZ_TYPE_SHARED_FUTURE
            # Allocate buffer for shared_future (needs more space and alignment)
            buffer = Vector{UInt8}(undef, 64)  # Larger buffer for shared_future
            # Ensure 16-byte alignment
            aligned_ptr = Ptr{UInt8}(div(UInt(pointer(buffer)) + 15, 16) * 16)
            (aligned_ptr, :shared_future)
        else
            (Ref{Float64}(0.0), Float64)  # Default fallback
        end
        
        call_func = Libdl.dlsym(func.lib_handle, :glz_call_member_function_with_type)
        result_ptr = ccall(call_func, Ptr{Cvoid},
                          (Ptr{Cvoid}, Cstring, Ptr{MemberInfo}, Ptr{Ptr{Cvoid}}, Ptr{Cvoid}),
                          func.obj_ptr, func.type_name, func.member_info, C_NULL, result_buffer)
        
        if result_ptr != C_NULL && result_type != Nothing
            if result_type == String
                string_func = Libdl.dlsym(func.lib_handle, :glz_string_c_str)
                c_str = ccall(string_func, Ptr{UInt8}, (Ptr{Cvoid},), result_ptr)
                return unsafe_string(c_str)
            elseif result_type == :vector && return_type_desc.index == GLZ_TYPE_VECTOR
                # The result_buffer contains the vector object constructed via placement new
                # Extract data immediately before it goes out of scope
                return extract_vector_data(result_ptr, func_desc.return_type, func.lib_handle)
            elseif result_type == :struct && return_type_desc.index == GLZ_TYPE_STRUCT
                # Handle struct returns - check if it's a pair
                struct_desc_ptr = func_desc.return_type + fieldoffset(ConcreteTypeDescriptor, 2)
                struct_desc = unsafe_load(Ptr{StructDesc}(struct_desc_ptr))
                
                # Try to get type info
                type_info_ptr = struct_desc.info
                
                # If info is null but we have a type name, try to look it up
                if type_info_ptr == C_NULL && struct_desc.type_name != C_NULL
                    type_name = unsafe_string(struct_desc.type_name)
                    get_type_info = Libdl.dlsym(func.lib_handle, :glz_get_type_info)
                    type_info_ptr = ccall(get_type_info, Ptr{ConcreteTypeInfo}, (Cstring,), type_name)
                end
                
                if type_info_ptr != C_NULL
                    type_info = unsafe_load(type_info_ptr)
                    if type_info.member_count == 2
                        # Check member names to see if this is a pair
                        # Read MemberInfo structs
                        member1 = unsafe_load(type_info.members, 1)
                        member2 = unsafe_load(type_info.members, 2)
                        name1 = unsafe_string(member1.name)
                        name2 = unsafe_string(member2.name)
                        
                        if name1 == "first" && name2 == "second"
                            # This is a pair - extract values
                            first_ptr = ccall(member1.getter, Ptr{Cvoid}, (Ptr{Cvoid},), result_ptr)
                            second_ptr = ccall(member2.getter, Ptr{Cvoid}, (Ptr{Cvoid},), result_ptr)
                            
                            # For now, assume doubles (for findMinMax)
                            first_val = unsafe_load(Ptr{Float64}(first_ptr))
                            second_val = unsafe_load(Ptr{Float64}(second_ptr))
                            return (first_val, second_val)
                        end
                    end
                end
                
                # Not a pair or couldn't extract - return nothing for now
                return nothing
            elseif result_type == :variant && return_type_desc.index == GLZ_TYPE_VARIANT
                # Return a CppVariant wrapper
                return CppVariant(result_ptr, func.lib_handle, func_desc.return_type)
            elseif result_type == :shared_future && return_type_desc.index == GLZ_TYPE_SHARED_FUTURE
                # Extract the shared_future descriptor
                future_desc_ptr = func_desc.return_type + fieldoffset(ConcreteTypeDescriptor, 2)
                future_desc = unsafe_load(Ptr{SharedFutureDesc}(future_desc_ptr))
                
                # Return a CppSharedFuture wrapper
                return CppSharedFuture(result_ptr, func.lib_handle)
            else
                return result_buffer[]
            end
        else
            return nothing
        end
    end
end

# Pretty printing for member functions
function Base.show(io::IO, func::CppMemberFunction)
    # Load member info to get function signature details
    member = unsafe_load(func.member_info)
    
    if member.type != C_NULL && unsafe_load(Ptr{ConcreteTypeDescriptor}(member.type)).index == GLZ_TYPE_FUNCTION
        print(io, "CppMemberFunction($(func.name))")
    else
        print(io, "CppMemberFunction($(func.name)) [invalid]")
    end
end

export CppLibrary, load, get_instance, array_view, CppArrayView, CppOptional, value, set_value!, reset!, CppMemberFunction, CppSharedFuture,
       CppVariant, index, length, holds_alternative, alternative_type, get_value, set_value!,
       tryget, match_variant, alternative_types, alternatives, current_type, is_active, hastype, variant_union_type

# SharedFuture support functions
"""
    is_ready(future::CppSharedFuture) -> Bool

Check if the shared_future has a value ready without blocking.
"""
function Base.isready(future::CppSharedFuture)
    is_ready_func = Libdl.dlsym(future.lib_handle, :glz_shared_future_is_ready)
    return ccall(is_ready_func, Bool, (Ptr{Cvoid},), future.ptr)
end

"""
    wait(future::CppSharedFuture)

Block until the shared_future has a value ready.
"""
function Base.wait(future::CppSharedFuture)
    wait_func = Libdl.dlsym(future.lib_handle, :glz_shared_future_wait)
    ccall(wait_func, Cvoid, (Ptr{Cvoid},), future.ptr)
end

"""
    isvalid(future::CppSharedFuture) -> Bool

Check if the shared_future refers to a valid asynchronous state.
"""
function Base.isvalid(future::CppSharedFuture)
    valid_func = Libdl.dlsym(future.lib_handle, :glz_shared_future_valid)
    return ccall(valid_func, Bool, (Ptr{Cvoid},), future.ptr)
end

"""
    get(future::CppSharedFuture)

Get the value from the shared_future. This will block if the value is not ready.
Returns the value converted to the appropriate Julia type.
"""
function Base.get(future::CppSharedFuture)
    if !isvalid(future)
        error("Invalid shared_future")
    end
    
    # Get the value type descriptor from the wrapper
    get_type_func = Libdl.dlsym(future.lib_handle, :glz_shared_future_get_value_type)
    value_type_ptr = ccall(get_type_func, Ptr{TypeDescriptor}, (Ptr{Cvoid},), future.ptr)
    
    if value_type_ptr == C_NULL
        error("Failed to get value type from shared_future")
    end
    
    # Get the value through C API
    get_func = Libdl.dlsym(future.lib_handle, :glz_shared_future_get)
    value_ptr = ccall(get_func, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{TypeDescriptor}), 
                     future.ptr, value_type_ptr)
    
    if value_ptr == C_NULL
        error("Failed to get value from shared_future")
    end
    
    # Extract the value based on type descriptor
    value_type_desc = unsafe_load(Ptr{ConcreteTypeDescriptor}(value_type_ptr))
    
    if value_type_desc.index == GLZ_TYPE_PRIMITIVE
        prim_desc_ptr = value_type_ptr + fieldoffset(ConcreteTypeDescriptor, 2)
        prim_desc = unsafe_load(Ptr{PrimitiveDesc}(prim_desc_ptr))
        
        # Load the value and free the allocated memory
        value = if prim_desc.kind == 1  # bool
            val = unsafe_load(Ptr{Bool}(value_ptr))
            Libc.free(value_ptr)
            val
        elseif prim_desc.kind == 4  # int32
            val = unsafe_load(Ptr{Int32}(value_ptr))
            Libc.free(value_ptr)
            val
        elseif prim_desc.kind == 10  # float
            val = unsafe_load(Ptr{Float32}(value_ptr))
            Libc.free(value_ptr)
            val
        elseif prim_desc.kind == 11  # double
            val = unsafe_load(Ptr{Float64}(value_ptr))
            Libc.free(value_ptr)
            val
        else
            Libc.free(value_ptr)
            error("Unsupported primitive type kind: $(prim_desc.kind)")
        end
        
        return value
    elseif value_type_desc.index == GLZ_TYPE_STRING
        # For strings, value_ptr points to a std::string
        string_view_func = Libdl.dlsym(future.lib_handle, :glz_string_view)
        str_view = ccall(string_view_func, StringView, (Ptr{Cvoid},), value_ptr)
        result = unsafe_string(str_view.data, str_view.size)
        # Note: The string is in thread_local storage, don't free
        return result
    elseif value_type_desc.index == GLZ_TYPE_VECTOR
        # For vectors, extract the data
        return extract_vector_data(value_ptr, value_type_ptr, future.lib_handle)
    elseif value_type_desc.index == GLZ_TYPE_STRUCT
        # For struct types, the value_ptr points to a heap-allocated struct
        # Create a CppStruct wrapper
        # The struct descriptor is packed, so read fields manually
        struct_desc_ptr = Ptr{UInt8}(value_type_ptr) + fieldoffset(ConcreteTypeDescriptor, 2)
        
        # struct_desc has type_name (pointer), info (pointer), and type_hash (uint64)
        # Read info pointer (second field, at offset 8)
        info_ptr_addr = struct_desc_ptr + 8
        info_ptr = unsafe_load(Ptr{Ptr{ConcreteTypeInfo}}(info_ptr_addr))
        
        if info_ptr == C_NULL
            # If info pointer is null, try to get it using the type hash
            # Read type hash (third field, at offset 16)
            type_hash_addr = struct_desc_ptr + 16
            type_hash = unsafe_load(Ptr{UInt64}(type_hash_addr))
            
            # Get type info by hash
            get_type_info_by_hash_func = Libdl.dlsym(future.lib_handle, :glz_get_type_info_by_hash)
            info_ptr = ccall(get_type_info_by_hash_func, Ptr{ConcreteTypeInfo}, (Csize_t,), type_hash)
            
            if info_ptr == C_NULL
                error("Could not find type info for type hash: $type_hash")
            end
        end
        
        info = unsafe_load(info_ptr)
        return CppStruct(value_ptr, info, future.lib_handle, true)  # owned=true since it's heap allocated
    else
        error("Unsupported shared_future value type: $(value_type_desc.index)")
    end
end

# Pretty printing
function Base.show(io::IO, future::CppSharedFuture)
    if isvalid(future)
        if isready(future)
            print(io, "CppSharedFuture(ready)")
        else
            print(io, "CppSharedFuture(pending)")
        end
    else
        print(io, "CppSharedFuture(invalid)")
    end
end