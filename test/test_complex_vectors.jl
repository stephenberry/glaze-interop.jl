using Test
using Glaze
using Libdl
using Statistics

@testset "Complex Vector Tests" begin
    # This test assumes the test library has been built
    # and contains vectors of complex numbers
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
        
        @testset "Complex Float32 Vector" begin
            obj = lib.TestAllTypes
            
            # Test that complex_vector is recognized as CppVectorComplexF32
            @test isa(obj.complex_vector, Glaze.CppVectorComplexF32)
            
            # Test basic operations
            resize!(obj.complex_vector, 5)
            @test length(obj.complex_vector) == 5
            
            # Set values
            obj.complex_vector[1] = 1.0f0 + 2.0f0im
            obj.complex_vector[2] = 3.0f0 - 4.0f0im
            obj.complex_vector[3] = 0.0f0 + 1.0f0im
            obj.complex_vector[4] = -1.0f0 - 2.0f0im
            obj.complex_vector[5] = 5.0f0 + 0.0f0im
            
            # Test getindex
            @test obj.complex_vector[1] ≈ ComplexF32(1.0f0 + 2.0f0im)
            @test obj.complex_vector[2] ≈ ComplexF32(3.0f0 - 4.0f0im)
            @test obj.complex_vector[5] ≈ ComplexF32(5.0f0 + 0.0f0im)
            
            # Test iteration
            values = ComplexF32[]
            for val in obj.complex_vector
                push!(values, val)
            end
            @test length(values) == 5
            @test values[1] ≈ ComplexF32(1.0f0 + 2.0f0im)
            
            # Test push!
            push!(obj.complex_vector, 10.0f0 + 10.0f0im)
            @test length(obj.complex_vector) == 6
            @test obj.complex_vector[6] ≈ ComplexF32(10.0f0 + 10.0f0im)
            
            # Test array view
            arr = array_view(obj.complex_vector)
            @test isa(arr, Glaze.CppArrayView{ComplexF32,1})
            @test length(arr) == 6
            @test arr[1] ≈ ComplexF32(1.0f0 + 2.0f0im)
            
            # Test array operations
            @test sum(arr) ≈ ComplexF32(18.0f0 + 7.0f0im)
            
            # Test broadcasting
            arr .= arr .* 2
            @test arr[1] ≈ ComplexF32(2.0f0 + 4.0f0im)
            @test obj.complex_vector[1] ≈ ComplexF32(2.0f0 + 4.0f0im)  # Verify it modified original
            
            # Test slicing
            sub = view(arr, 2:4)
            @test length(sub) == 3
            @test sub[1] ≈ ComplexF32(6.0f0 - 8.0f0im)
        end
        
        @testset "Complex Float64 Vector" begin
            # Create a hypothetical complex64 vector test
            # Note: This assumes the test library has a double complex vector
            # If not available, we can still test the type functionality
            
            # Test type traits
            @test eltype(Glaze.CppVectorComplexF64) == ComplexF64
            @test Base.IteratorSize(Glaze.CppVectorComplexF64) == Base.HasLength()
            @test Base.IndexStyle(Glaze.CppVectorComplexF64) == IndexLinear()
        end
        
        @testset "Performance" begin
            obj = lib.TestAllTypes
            
            # Create a larger complex vector
            n = 10000
            resize!(obj.complex_vector, n)
            for i in 1:n
                obj.complex_vector[i] = ComplexF32(sin(i/100), cos(i/100))
            end
            
            # Test iteration performance
            function sum_complex_iter(v)
                s = ComplexF32(0)
                for val in v
                    s += val
                end
                return s
            end
            
            # Time the optimized iteration
            t = @elapsed for _ in 1:100
                s = sum_complex_iter(obj.complex_vector)
            end
            
            println("Complex vector iteration ($(n) elements, 100 iterations): $(round(t*1000, digits=2)) ms")
            
            # Test array view performance
            arr = array_view(obj.complex_vector)
            t_arr = @elapsed for _ in 1:100
                s = sum(arr)
            end
            
            println("Complex array view sum ($(n) elements, 100 iterations): $(round(t_arr*1000, digits=2)) ms")
            
            # They should be comparable
            @test t_arr / t < 2.0  # Array view shouldn't be more than 2x slower
        end
        
        @testset "Edge Cases" begin
            obj = lib.TestAllTypes
            
            # Empty vector
            resize!(obj.complex_vector, 0)
            @test length(obj.complex_vector) == 0
            @test isempty(obj.complex_vector)
            
            # Single element
            push!(obj.complex_vector, 1.0f0 + 1.0f0im)
            @test length(obj.complex_vector) == 1
            @test obj.complex_vector[1] ≈ ComplexF32(1.0f0 + 1.0f0im)
            
            # Pure real/imaginary
            obj.complex_vector[1] = 5.0f0 + 0.0f0im  # Pure real
            @test real(obj.complex_vector[1]) == 5.0f0
            @test imag(obj.complex_vector[1]) == 0.0f0
            
            push!(obj.complex_vector, 0.0f0 + 3.0f0im)  # Pure imaginary
            @test real(obj.complex_vector[2]) == 0.0f0
            @test imag(obj.complex_vector[2]) == 3.0f0
        end
        
    else
        @warn "Test library not found. Skipping complex vector tests."
    end
end