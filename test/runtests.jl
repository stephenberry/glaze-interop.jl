using Test
using Glaze
using Libdl

# Build test library first
test_dir = @__DIR__
build_dir = joinpath(test_dir, "build")
mkpath(build_dir)

# Build the test library
cd(build_dir) do
    run(`cmake ..`)
    run(`cmake --build .`)
end

# Find the built test library
test_lib_name = if Sys.iswindows()
    "test_lib.dll"
elseif Sys.isapple()
    "libtest_lib.dylib"
else
    "libtest_lib.so"
end

const test_lib_path = joinpath(build_dir, test_lib_name)

# Create CppLibrary first (this loads the library)
const lib = Glaze.CppLibrary(test_lib_path)

# Initialize test types - use the complete initialization that includes all types
const init_func = Libdl.dlsym(lib.handle, :init_test_types_complete)
ccall(init_func, Cvoid, ())

# Export lib for test_all_types.jl to use
global test_lib_for_all_types = lib

@testset "Glaze.jl Tests" begin
    # Include all test files
    include("test_all_types.jl")
    
    # Include nested struct tests
    include("test_nested_structs.jl")
    
    # Include pretty printing tests
    include("test_pretty_printing.jl")
    
    # Include variant tests
    include("test_variants.jl")
    
    # Include array interface tests
    include("test_array_interface.jl")
    
    # Include comprehensive complex vector tests
    include("test_complex_vectors.jl")
    
    # Include Person construction and assignment tests
    include("test_person_construction.jl")
    
    # Include std::optional support tests
    include("test_optional.jl")
    
    # Include member function tests
    include("test_member_functions.jl")
    
    # Include comprehensive member function tests (safer version)
    include("test_member_functions_comprehensive.jl")
    
    # Include vector member function tests
    include("test_member_functions_vectors.jl")
    
    # Include shared future tests
    include("test_shared_future.jl")
    
    # Include new tests for examples coverage
    include("test_complex_nested.jl")
    # Map types are not yet implemented in Glaze.jl (test_maps.jl)
    
    # Run ABI diagnostic tests before iteration performance tests
    # This helps identify any memory/ABI issues early
    include("test_abi_diagnostics.jl")
    
    include("test_iteration_performance.jl")
    
    # Run generic nested struct tests separately as they need their own build
    @testset "Generic Nested Tests" begin
        include("integration/test_generic_nested.jl")
    end
    
    @testset "Basic Type Tests" begin
        # Create TestAllTypes instance
        obj = lib.TestAllTypes
        
        @testset "Integer operations" begin
            obj.int_value = 42
            @test obj.int_value == 42
            
            obj.int_value = -123
            @test obj.int_value == -123
            
            obj.int_value = typemax(Int32)
            @test obj.int_value == typemax(Int32)
        end
        
        @testset "Float operations" begin
            obj.float_value = 3.14f0
            @test obj.float_value ≈ 3.14f0
            
            obj.float_value = -2.718f0
            @test obj.float_value ≈ -2.718f0
            
            obj.float_value = 0.0f0
            @test obj.float_value == 0.0f0
        end
        
        @testset "Bool operations" begin
            obj.bool_value = true
            @test obj.bool_value == true
            
            obj.bool_value = false
            @test obj.bool_value == false
        end
        
        @testset "String operations" begin
            obj.string_value = "Hello, World!"
            @test obj.string_value == "Hello, World!"
            
            obj.string_value = ""
            @test obj.string_value == ""
            
            obj.string_value = "Unicode: 你好世界 🌍"
            @test obj.string_value == "Unicode: 你好世界 🌍"
        end
        
        @testset "Vector<float> operations" begin
            # Test empty vector
            @test length(obj.float_vector) == 0
            
            # Push elements
            push!(obj.float_vector, 1.0f0)
            push!(obj.float_vector, 2.0f0)
            push!(obj.float_vector, 3.0f0)
            @test length(obj.float_vector) == 3
            
            # Test indexing
            @test obj.float_vector[1] ≈ 1.0f0
            @test obj.float_vector[2] ≈ 2.0f0
            @test obj.float_vector[3] ≈ 3.0f0
            
            # Test modification
            obj.float_vector[2] = 5.0f0
            @test obj.float_vector[2] ≈ 5.0f0
            
            # Test resize
            resize!(obj.float_vector, 5)
            @test length(obj.float_vector) == 5
            
            # Test bounds checking
            @test_throws BoundsError obj.float_vector[0]
            @test_throws BoundsError obj.float_vector[6]
        end
        
        @testset "Vector<complex<float>> operations" begin
            # Test empty vector
            @test length(obj.complex_vector) == 0
            
            # Push complex numbers
            push!(obj.complex_vector, 1.0f0 + 2.0f0im)
            push!(obj.complex_vector, 3.0f0 - 4.0f0im)
            @test length(obj.complex_vector) == 2
            
            # Test indexing
            @test obj.complex_vector[1] ≈ ComplexF32(1.0f0 + 2.0f0im)
            @test obj.complex_vector[2] ≈ ComplexF32(3.0f0 - 4.0f0im)
            
            # Test modification
            obj.complex_vector[1] = 5.0f0 + 6.0f0im
            @test obj.complex_vector[1] ≈ ComplexF32(5.0f0 + 6.0f0im)
            
            # Test resize
            resize!(obj.complex_vector, 4)
            @test length(obj.complex_vector) == 4
        end
    end
    
    @testset "Edge Case Tests" begin
        edge = lib.EdgeCaseStruct
        
        @test edge.empty_string == ""
        @test length(edge.empty_vector) == 0
        @test edge.zero_int == 0
        @test edge.zero_float == 0.0f0
        @test edge.false_bool == false
        
        # Modify and test
        edge.empty_string = "not empty anymore"
        @test edge.empty_string == "not empty anymore"
        
        push!(edge.empty_vector, 1.0f0)
        @test length(edge.empty_vector) == 1
        @test edge.empty_vector[1] ≈ 1.0f0
    end
    
    @testset "Large Data Tests" begin
        large = lib.LargeDataStruct
        
        # Create large vector
        n = 10000
        resize!(large.large_vector, n)
        for i in 1:n
            large.large_vector[i] = Float32(i)
        end
        
        # Verify data integrity
        @test length(large.large_vector) == n
        @test large.large_vector[1] == 1.0f0
        @test large.large_vector[n÷2] == Float32(n÷2)
        @test large.large_vector[n] == Float32(n)
        
        # Test large string
        large_str = repeat("a", 1000)
        large.long_string = large_str
        @test large.long_string == large_str
        
        # Test complex vector with pattern
        resize!(large.complex_data, 100)
        for i in 1:100
            large.complex_data[i] = ComplexF32(i, -i)
        end
        
        @test length(large.complex_data) == 100
        @test large.complex_data[50] ≈ ComplexF32(50, -50)
    end
    
    @testset "Memory Safety Tests" begin
        # Test multiple objects don't interfere
        obj1 = lib.TestAllTypes
        obj2 = lib.TestAllTypes
        
        obj1.int_value = 100
        obj2.int_value = 200
        
        @test obj1.int_value == 100
        @test obj2.int_value == 200
        
        # Test string independence
        obj1.string_value = "obj1"
        obj2.string_value = "obj2"
        
        @test obj1.string_value == "obj1"
        @test obj2.string_value == "obj2"
        
        # Test vector independence
        push!(obj1.float_vector, 1.0f0)
        push!(obj2.float_vector, 2.0f0)
        push!(obj2.float_vector, 3.0f0)
        
        @test length(obj1.float_vector) == 1
        @test length(obj2.float_vector) == 2
    end
    
    @testset "Zero-copy verification" begin
        # This test verifies that we're actually manipulating C++ memory
        obj = lib.TestAllTypes
        
        # Set up a vector
        resize!(obj.float_vector, 3)
        obj.float_vector[1] = 1.0f0
        obj.float_vector[2] = 2.0f0
        obj.float_vector[3] = 3.0f0
        
        # Get another reference to the same object
        # (In a real scenario, this would be through another C++ function)
        obj2 = lib.TestAllTypes
        
        # Since obj and obj2 are different Julia objects pointing to different C++ objects,
        # they should be independent
        @test length(obj2.float_vector) == 0  # New object starts empty
    end
    
    @testset "Global Instance Access" begin
        # Test accessing global instances
        global_test = Glaze.get_instance(lib, "global_test")
        @test global_test.int_value == 42
        @test global_test.float_value ≈ 3.14f0
        @test global_test.bool_value == true
        @test global_test.string_value == "Global test string"
        @test length(global_test.float_vector) == 3
        @test global_test.float_vector[1] == 1.0f0
        @test global_test.float_vector[2] == 2.0f0
        @test global_test.float_vector[3] == 3.0f0
        @test length(global_test.complex_vector) == 2
        @test global_test.complex_vector[1] ≈ ComplexF32(1.0f0, 1.0f0)
        @test global_test.complex_vector[2] ≈ ComplexF32(2.0f0, -1.0f0)
        
        # Test modifying global instance
        global_test.int_value = 100
        @test global_test.int_value == 100
        
        global_test.string_value = "Modified string"
        @test global_test.string_value == "Modified string"
        
        push!(global_test.float_vector, 4.0f0)
        @test length(global_test.float_vector) == 4
        @test global_test.float_vector[4] == 4.0f0
        
        # Test edge case global instance
        global_edge = Glaze.get_instance(lib, "global_edge")
        @test global_edge.empty_string == ""
        @test length(global_edge.empty_vector) == 0
        @test global_edge.zero_int == 0
        @test global_edge.zero_float == 0.0f0
        @test global_edge.false_bool == false
        
        # Test that changes persist (get the same instance again)
        global_test2 = Glaze.get_instance(lib, "global_test")
        @test global_test2.int_value == 100  # Should see the modified value
        @test global_test2.string_value == "Modified string"
        @test length(global_test2.float_vector) == 4
        
        # Test error for non-existent instance
        @test_throws ErrorException Glaze.get_instance(lib, "non_existent")
    end
end

println("All tests passed!")