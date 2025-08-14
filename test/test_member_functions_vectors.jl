# Test file for member functions that accept and return vectors
# Tests various vector types: Int32, Float32, Float64, Complex, String

using Test
push!(LOAD_PATH, dirname(@__DIR__))
using Glaze
using Libdl

@testset "Member Functions with Vector Parameters" begin
    # Get library handle - either from runtests.jl or load it directly
    lib = if isdefined(Main, :test_lib_for_all_types)
        test_lib_for_all_types
    else
        # Running standalone - load the library
        test_dir = @__DIR__
        build_dir = joinpath(test_dir, "build")
        test_lib_path = joinpath(build_dir, Sys.iswindows() ? "test_lib.dll" : Sys.isapple() ? "libtest_lib.dylib" : "libtest_lib.so")
        
        # Initialize types first
        handle = Libdl.dlopen(test_lib_path)
        init_func = Libdl.dlsym(handle, :init_test_types_complete)
        ccall(init_func, Cvoid, ())
        
        Glaze.CppLibrary(test_lib_path)
    end
    
    @testset "VectorProcessor Basic Operations" begin
        processor = lib.VectorProcessor
        processor.scale_factor = 2.0
        
        @testset "Integer Vector Operations" begin
            # Test sumIntegers
            int_vec = Int32[1, 2, 3, 4, 5]
            sum_result = processor.sumIntegers(int_vec)
            @test sum_result == 15
            @test isa(sum_result, Int32)
            
            # Test with empty vector
            empty_int_vec = Int32[]
            @test processor.sumIntegers(empty_int_vec) == 0
            
            # Test filterPositive
            mixed_vec = Int32[-2, -1, 0, 1, 2, 3]
            positive_vec = processor.filterPositive(mixed_vec)
            @test positive_vec == Int32[1, 2, 3]
            @test length(positive_vec) == 3
            
            # Test normalizeIntegers
            norm_input = Int32[10, -20, 30, -40]
            norm_result = processor.normalizeIntegers(norm_input)
            @test isa(norm_result, Vector{Float32})
            @test length(norm_result) == 4
            @test norm_result ≈ Float32[0.25, -0.5, 0.75, -1.0]
        end
        
        @testset "Float Vector Operations" begin
            # Test averageFloats
            float_vec = Float32[1.0, 2.0, 3.0, 4.0]
            avg = processor.averageFloats(float_vec)
            @test avg ≈ 2.5f0
            @test isa(avg, Float32)
            
            # Test with empty vector
            @test processor.averageFloats(Float32[]) == 0.0f0
            
            # Test reverseAndScale
            original_scale = processor.scale_factor
            input_vec = Float32[1.0, 2.0, 3.0]
            reversed = processor.reverseAndScale(input_vec)
            @test reversed ≈ Float32[6.0, 4.0, 2.0]  # reversed and scaled by 2.0
            @test processor.scale_factor ≈ 1.0 + (1.0 / 3.0)  # scale updated
        end
        
        @testset "Double Vector Operations" begin
            # Reset scale factor
            processor.scale_factor = 3.0
            
            # Test scaleDoubles
            double_vec = [1.0, 2.0, 3.0, 4.0]
            scaled = processor.scaleDoubles(double_vec)
            @test scaled ≈ [3.0, 6.0, 9.0, 12.0]
            @test isa(scaled, Vector{Float64})
            
            # Test findMinMax
            test_vec = [3.5, -2.1, 8.7, 0.0, -5.5]
            min_max = processor.findMinMax(test_vec)
            @test min_max == (-5.5, 8.7)
            
            # Test with empty vector
            empty_min_max = processor.findMinMax(Float64[])
            @test empty_min_max == (0.0, 0.0)
            
            # Test countGreaterThan
            count_vec = [1.0, 2.0, 3.0, 4.0, 5.0]
            count = processor.countGreaterThan(count_vec, 3.0)
            @test count == 2
            @test isa(count, Int32)
            
            # Test allPositive
            @test processor.allPositive([1.0, 2.0, 3.0]) == true
            @test processor.allPositive([1.0, -2.0, 3.0]) == false
            @test processor.allPositive(Float64[]) == true  # vacuous truth
        end
        
        @testset "String Vector Operations" begin
            # Test joinStrings
            strings = ["Hello", "World", "from", "Julia"]
            joined = processor.joinStrings(strings, " ")
            @test joined == "Hello World from Julia"
            @test isa(joined, String)
            
            # Test with different delimiter
            joined_comma = processor.joinStrings(strings, ", ")
            @test joined_comma == "Hello, World, from, Julia"
            
            # Test with empty vector
            @test processor.joinStrings(String[], " ") == ""
            
            # Test with single element
            @test processor.joinStrings(["Solo"], " | ") == "Solo"
        end
        
        @testset "Complex Vector Operations" begin
            # Test complexMagnitudes
            complex_vec = [complex(3.0f0, 4.0f0), complex(5.0f0, 12.0f0), complex(0.0f0, 1.0f0)]
            mags = processor.complexMagnitudes(complex_vec)
            @test mags ≈ Float32[5.0, 13.0, 1.0]
            @test isa(mags, Vector{Float32})
            
            # Test with empty vector
            empty_mags = processor.complexMagnitudes(ComplexF32[])
            @test empty_mags == Float32[]
        end
        
        @testset "Multi-Vector Operations" begin
            # Test dotProduct
            a = [1.0, 2.0, 3.0]
            b = [4.0, 5.0, 6.0]
            dot = processor.dotProduct(a, b)
            @test dot ≈ 32.0  # 1*4 + 2*5 + 3*6
            
            # Test mismatched sizes
            @test processor.dotProduct([1.0, 2.0], [1.0, 2.0, 3.0]) == 0.0
            
            # Test elementWiseAdd
            sum_vec = processor.elementWiseAdd(a, b)
            @test sum_vec ≈ [5.0, 7.0, 9.0]
            
            # Test with different sizes (takes minimum)
            c = [1.0, 2.0]
            partial_sum = processor.elementWiseAdd(a, c)
            @test length(partial_sum) == 2
            @test partial_sum ≈ [2.0, 4.0]
            
            # Test computeWeightedSum
            values = [10.0, 20.0, 30.0]
            weights = [0.1, 0.3, 0.6]
            weighted = processor.computeWeightedSum(values, weights)
            @test weighted ≈ 1.0 + 6.0 + 18.0  # 25.0
        end
        
        @testset "Void Functions with Vector Parameters" begin
            # Test updateScaleFromVector
            processor.scale_factor = 1.0
            processor.updateScaleFromVector([2.0, 4.0, 6.0])
            @test processor.scale_factor ≈ 4.0  # average of vector
            
            # Test with empty vector (should not change scale)
            processor.scale_factor = 5.0
            processor.updateScaleFromVector(Float64[])
            @test processor.scale_factor ≈ 5.0
        end
        
        @testset "Complex Multi-Parameter Function" begin
            # Test processData
            ids = Int32[100, 50, 200, 25, 150]
            names = ["Alice", "Bob", "Charlie", "David", "Eve"]
            result = processor.processData(ids, names, 75.0)
            
            @test occursin("Processing 5 items", result)
            @test occursin("threshold 75", result)
            @test occursin("Alice(100)", result)
            @test occursin("Charlie(200)", result)
            @test occursin("Eve(150)", result)
            @test !occursin("Bob", result)  # 50 < 75
            @test !occursin("David", result)  # 25 < 75
            
            # Test with mismatched sizes
            short_names = ["Only", "Two"]
            result2 = processor.processData(ids, short_names, 50.0)
            @test occursin("Only(100)", result2)
            @test !occursin("Charlie", result2)  # beyond names array
        end
    end
    
    @testset "VectorEdgeCases Operations" begin
        edge = lib.VectorEdgeCases
        
        @testset "Empty Vector Handling" begin
            # Test describeVector
            @test edge.describeVector(Float64[]) == "Empty vector"
            @test edge.describeVector([1.0, 2.0, 3.0]) == "Vector with 3 elements"
            
            # Test getEmptyVector
            empty = edge.getEmptyVector()
            @test isa(empty, Vector{Int32})
            @test length(empty) == 0
        end
        
        @testset "Large Vector Operations" begin
            # Create large vector
            large_vec = collect(1.0:1000.0)
            sum_result = edge.sumLargeVector(large_vec)
            @test sum_result ≈ 500500.0  # sum of 1 to 1000
            
            # Test with very large vector
            very_large = collect(1.0:10000.0)
            very_large_sum = edge.sumLargeVector(very_large)
            @test very_large_sum ≈ 50005000.0
        end
        
        @testset "Matrix Creation" begin
            # Note: This returns vector of vectors, which may need special handling
            # depending on how Julia interprets nested C++ vectors
            # For now, we'll test if the function can be called without error
            result = edge.createMatrix(3, 4, 5)
            # The actual test would depend on how nested vectors are returned
        end
    end
    
    @testset "Type Safety and Error Handling" begin
        processor = lib.VectorProcessor
        
        # Test that functions properly handle Julia vector types
        # Julia Int defaults to Int64, but function expects Int32
        julia_ints = [1, 2, 3]  # These are Int64
        int32_vec = Int32.(julia_ints)  # Convert to Int32
        
        @test processor.sumIntegers(int32_vec) == 6
        
        # Test Float32 vs Float64 conversions
        julia_floats = [1.0, 2.0, 3.0]  # These are Float64
        float32_vec = Float32.(julia_floats)
        
        @test processor.averageFloats(float32_vec) ≈ 2.0f0
    end
    
    @testset "Performance with Different Vector Sizes" begin
        processor = lib.VectorProcessor
        
        # Test various vector sizes
        sizes = [0, 1, 10, 100, 1000]
        
        for n in sizes
            vec = collect(Float64, 1:n)
            
            # These should all work without error
            if n > 0
                result = processor.scaleDoubles(vec)
                @test length(result) == n
                
                min_max = processor.findMinMax(vec)
                @test min_max[1] ≈ 1.0
                @test min_max[2] ≈ Float64(n)
            end
        end
    end
end