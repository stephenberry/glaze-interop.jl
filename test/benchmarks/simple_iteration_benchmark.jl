using Glaze
using Test
using Statistics
using Libdl

# Simple timing function
function time_iteration(f, n::Int)
    times = Float64[]
    for _ in 1:n
        t0 = time_ns()
        f()
        push!(times, (time_ns() - t0) / 1e6)  # Convert to ms
    end
    return median(times)
end

# Test with the existing test library
@testset "Iteration Performance" begin
    # Assuming test library is already built (from runtests.jl)
    test_dir = @__DIR__
    build_dir = joinpath(test_dir, "build")
    
    test_lib_name = if Sys.iswindows()
        "test_lib.dll"
    elseif Sys.isapple()
        "libtest_lib.dylib"
    else
        "libtest_lib.so"
    end
    
    test_lib_path = joinpath(build_dir, test_lib_name)
    
    if isfile(test_lib_path)
        # Load and initialize the library
        lib_handle = Libdl.dlopen(test_lib_path)
        init_func = Libdl.dlsym(lib_handle, :init_test_types)
        ccall(init_func, Cvoid, ())
        
        lib = Glaze.CppLibrary(test_lib_path)
        
        # Create a test object with a float vector
        obj = lib.TestAllTypes
        
        # Test different vector sizes
        sizes = [100, 1000, 10000]
        
        println("\nIteration Performance Comparison")
        println("================================")
        
        for size in sizes
            # Get the float vector
            vec = obj.float_vector
            println("Vector type: $(typeof(vec)), initial length: $(length(vec))")
            
            # Resize vector and fill with data
            resize!(vec, size)
            println("After resize: length = $(length(vec))")
            
            for i in 1:size
                vec[i] = Float32(i) * 0.1f0
            end
            
            # Test indexed iteration (old/slow way)
            function iterate_indexed()
                sum = 0.0f0
                n = length(vec)
                for i in 1:n
                    sum += vec[i]
                end
                return sum
            end
            
            # Test optimized iteration
            function iterate_optimized()
                sum = 0.0f0
                for val in vec
                    sum += val
                end
                return sum
            end
            
            # Verify both methods give same result
            sum1 = iterate_indexed()
            sum2 = iterate_optimized()
            @test abs(sum1 - sum2) < 1e-3
            
            # Time both methods
            time_indexed = time_iteration(iterate_indexed, 100)
            time_optimized = time_iteration(iterate_optimized, 100)
            
            speedup = time_indexed / time_optimized
            
            println("\nSize: $size elements")
            println("  Indexed iteration:    $(round(time_indexed, digits=3)) ms")
            println("  Optimized iteration:  $(round(time_optimized, digits=3)) ms")
            println("  Speedup:             $(round(speedup, digits=1))x")
            
            # Test that optimized is significantly faster
            @test time_optimized < time_indexed
        end
        
        # Test specialized vector types
        println("\n\nSpecialized Vector Type Test")
        println("=============================")
        
        # The float_vector should return a CppVectorFloat32
        vec = obj.float_vector
        println("Vector type: $(typeof(vec))")
        
        if isa(vec, Glaze.CppVectorFloat32)
            println("✓ Specialized CppVectorFloat32 type detected")
            println("  This provides optimal iteration performance")
        else
            println("  Generic CppVector type (still optimized)")
        end
        
    else
        @warn "Test library not found. Run the main test suite first to build it."
    end
end

println("\nNote: For comprehensive benchmarks with detailed timing, install BenchmarkTools:")
println("  import Pkg; Pkg.add(\"BenchmarkTools\")")
println("  julia test/benchmark_iteration.jl")