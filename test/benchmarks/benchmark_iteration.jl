using BenchmarkTools
using Glaze
using Printf
using Statistics
using Libdl

# Build the benchmark library
function build_benchmark_lib()
    test_dir = @__DIR__
    build_dir = joinpath(test_dir, "build_benchmark")
    mkpath(build_dir)
    
    # Create CMakeLists.txt for benchmark
    cmake_content = """
    cmake_minimum_required(VERSION 3.14)
    project(benchmark_lib)
    
    set(CMAKE_CXX_STANDARD 20)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
    
    # Find Glaze
    find_package(glaze CONFIG REQUIRED)
    
    # Create benchmark library
    add_library(benchmark_lib SHARED 
        ../benchmark_iteration.cpp)
    
    target_link_libraries(benchmark_lib PRIVATE glaze::glaze)
    
    # Set output name
    set_target_properties(benchmark_lib PROPERTIES
        PREFIX "lib"
        OUTPUT_NAME "benchmark_lib")
    """
    
    write(joinpath(build_dir, "CMakeLists.txt"), cmake_content)
    
    # Build
    cd(build_dir) do
        run(`cmake .`)
        run(`cmake --build .`)
    end
    
    # Find the built library
    lib_name = if Sys.iswindows()
        "benchmark_lib.dll"
    elseif Sys.isapple()
        "libbenchmark_lib.dylib"
    else
        "libbenchmark_lib.so"
    end
    
    return joinpath(build_dir, lib_name)
end

# Benchmark functions

# Original slow iteration (simulated by using getindex in loop)
function iterate_slow(v)
    sum = 0.0f0
    n = length(v)
    for i in 1:n
        sum += v[i]
    end
    return sum
end

# New optimized iteration
function iterate_optimized(v)
    sum = 0.0f0
    for val in v
        sum += val
    end
    return sum
end

# Direct unsafe iteration (after getting view once)
function iterate_unsafe(v)
    view_func = Glaze.get_cached_function(v.lib, :glz_vector_view)
    view = ccall(view_func, Glaze.VectorView, (Ptr{Cvoid}, Ptr{Glaze.TypeDescriptor}), v.ptr, v.type_desc)
    
    sum = 0.0f0
    ptr = Ptr{Float32}(view.data)
    @inbounds for i in 1:view.size
        sum += unsafe_load(ptr, i)
    end
    return sum
end

# Native Julia vector for comparison
function iterate_julia(v::Vector{Float32})
    sum = 0.0f0
    for val in v
        sum += val
    end
    return sum
end

# Main benchmark function
function run_benchmarks()
    println("Building benchmark library...")
    lib_path = build_benchmark_lib()
    
    println("Loading library...")
    lib = Glaze.load(lib_path)
    
    # Sizes to test
    sizes = [100, 1000, 10000, 100000, 1000000]
    
    println("\nJulia vs C++ std::vector<float> Iteration Benchmarks")
    println("====================================================\n")
    
    for size in sizes
        println("Size: $size elements")
        println("-" ^ 40)
        
        # Initialize C++ vector
        init_func = dlsym(lib.handle, :init_benchmark_data)
        ccall(init_func, Cvoid, (Csize_t,), size)
        
        # Get the benchmark struct
        benchmark_struct = Glaze.get_instance(lib, "benchmark_struct")
        cpp_vector = benchmark_struct.data
        
        # Create equivalent Julia vector
        julia_vector = Float32[i * 0.1f0 for i in 0:(size-1)]
        
        # Verify correctness
        sum_expected = sum(julia_vector)
        @assert abs(iterate_optimized(cpp_vector) - sum_expected) < 1e-3 "Optimized iteration incorrect"
        @assert abs(iterate_unsafe(cpp_vector) - sum_expected) < 1e-3 "Unsafe iteration incorrect"
        
        # Run benchmarks
        println("\nJulia Benchmarks:")
        
        # Native Julia vector
        b_julia = @benchmark iterate_julia($julia_vector) samples=1000
        time_julia = median(b_julia).time
        println("  Native Vector{Float32}:     $(round(time_julia, digits=2)) ns ($(round(time_julia/size, digits=3)) ns/elem)")
        
        # Unsafe CppVector iteration
        b_unsafe = @benchmark iterate_unsafe($cpp_vector) samples=1000
        time_unsafe = median(b_unsafe).time
        println("  CppVector (unsafe):         $(round(time_unsafe, digits=2)) ns ($(round(time_unsafe/size, digits=3)) ns/elem)")
        
        # Optimized CppVector iteration
        b_optimized = @benchmark iterate_optimized($cpp_vector) samples=1000
        time_optimized = median(b_optimized).time
        println("  CppVector (optimized):      $(round(time_optimized, digits=2)) ns ($(round(time_optimized/size, digits=3)) ns/elem)")
        
        # Slow CppVector iteration (only for smaller sizes)
        if size <= 10000
            b_slow = @benchmark iterate_slow($cpp_vector) samples=100
            time_slow = median(b_slow).time
            println("  CppVector (slow/indexed):   $(round(time_slow, digits=2)) ns ($(round(time_slow/size, digits=3)) ns/elem)")
            println("  Speedup: $(round(time_slow/time_optimized, digits=2))x")
        end
        
        # C++ benchmarks
        println("\nC++ Benchmarks:")
        cpp_iter_func = dlsym(lib.handle, :benchmark_cpp_iteration)
        cpp_index_func = dlsym(lib.handle, :benchmark_cpp_iteration_indexed)
        cpp_raw_func = dlsym(lib.handle, :benchmark_cpp_iteration_raw)
        
        # Get pointer to the C++ object
        create_func = dlsym(lib.handle, :create_benchmark_struct)
        cpp_obj = ccall(create_func, Ptr{Cvoid}, (Csize_t,), size)
        
        time_cpp_range = ccall(cpp_iter_func, Cdouble, (Ptr{Cvoid}, Cint), cpp_obj, 1000)
        time_cpp_index = ccall(cpp_index_func, Cdouble, (Ptr{Cvoid}, Cint), cpp_obj, 1000)
        time_cpp_raw = ccall(cpp_raw_func, Cdouble, (Ptr{Cvoid}, Cint), cpp_obj, 1000)
        
        println("  Range-based for:            $(round(time_cpp_range, digits=2)) ns ($(round(time_cpp_range/size, digits=3)) ns/elem)")
        println("  Indexed access:             $(round(time_cpp_index, digits=2)) ns ($(round(time_cpp_index/size, digits=3)) ns/elem)")
        println("  Raw pointer:                $(round(time_cpp_raw, digits=2)) ns ($(round(time_cpp_raw/size, digits=3)) ns/elem)")
        
        # Clean up
        destroy_func = dlsym(lib.handle, :destroy_benchmark_struct)
        ccall(destroy_func, Cvoid, (Ptr{Cvoid},), cpp_obj)
        
        # Performance comparison
        println("\nPerformance Comparison:")
        println("  Julia native vs C++ range-based: $(round(time_julia/time_cpp_range, digits=2))x")
        println("  CppVector optimized vs C++ range-based: $(round(time_optimized/time_cpp_range, digits=2))x")
        println("  CppVector unsafe vs C++ raw pointer: $(round(time_unsafe/time_cpp_raw, digits=2))x")
        println("  CppVector optimized vs Julia native: $(round(time_optimized/time_julia, digits=2))x")
        
        println("\n" * "="^60 * "\n")
    end
end

# Additional micro-benchmarks for specific operations
function micro_benchmarks()
    println("\nMicro-benchmarks for CppVector operations")
    println("=========================================\n")
    
    # Build and load if not already done
    lib_path = build_benchmark_lib()
    lib = Glaze.load(lib_path)
    
    # Test vector of size 10000
    init_func = dlsym(lib.handle, :init_benchmark_data)
    ccall(init_func, Cvoid, (Csize_t,), 10000)
    benchmark_struct = Glaze.get_instance(lib, "benchmark_struct")
    v = benchmark_struct.data
    
    println("Vector size: 10000")
    println("Testing individual operations:\n")
    
    # Benchmark length()
    b_length = @benchmark length($v) samples=10000
    println("length():        $(round(median(b_length).time, digits=2)) ns")
    
    # Benchmark getindex
    b_getindex = @benchmark $v[5000] samples=10000
    println("getindex[5000]:  $(round(median(b_getindex).time, digits=2)) ns")
    
    # Benchmark first iteration step
    b_first = @benchmark Base.iterate($v) samples=10000
    println("iterate(v):      $(round(median(b_first).time, digits=2)) ns")
    
    # Create iterator state for next step
    _, state = Base.iterate(v)
    b_next = @benchmark Base.iterate($v, $state) samples=10000
    println("iterate(v, s):   $(round(median(b_next).time, digits=2)) ns")
end

# Run all benchmarks
if abspath(PROGRAM_FILE) == @__FILE__
    run_benchmarks()
    micro_benchmarks()
end