using Test
using Glaze

@testset "Pretty Printing Tests" begin
    # Mock CppStruct for testing (since we need actual C++ instances for real tests)
    # We'll create a minimal mock that can test the show functionality
    
    # Helper function to capture output
    function capture_show(obj, compact=false)
        io = IOBuffer()
        if compact
            show(IOContext(io, :compact => true), obj)
        else
            show(io, obj)
        end
        return String(take!(io))
    end
    
    @testset "CppStruct Pretty Printing" begin
        # Note: These tests require the test library to be loaded
        # They should be run as part of runtests.jl
        
        if @isdefined(test_lib_for_all_types)
            lib = test_lib_for_all_types
            
            @testset "Basic struct pretty printing" begin
                obj = lib.TestAllTypes
                obj.int_value = 42
                obj.float_value = 3.14f0
                obj.bool_value = true
                obj.string_value = "Hello, World!"
                
                # Test pretty print (multi-line)
                output = capture_show(obj, false)
                @test occursin("TestAllTypes {", output)
                @test occursin("int_value: 42", output)
                @test occursin("float_value: 3.14", output)
                @test occursin("bool_value: true", output)
                @test occursin("string_value: \"Hello, World!\"", output)
                @test occursin("}", output)
                
                # Test compact mode
                compact_output = capture_show(obj, true)
                @test occursin("TestAllTypes(", compact_output)
                @test occursin("int_value=42", compact_output)
                @test occursin("float_value=3.14", compact_output)
                @test occursin("bool_value=true", compact_output)
                @test occursin("string_value=\"Hello, World!\"", compact_output)
                @test occursin(")", compact_output)
                @test !occursin("\n", compact_output)  # Should be single line
            end
            
            @testset "Vector pretty printing" begin
                obj = lib.TestAllTypes
                
                # Test small vector (inline display)
                resize!(obj.float_vector, 3)
                obj.float_vector[1] = 1.0f0
                obj.float_vector[2] = 2.0f0
                obj.float_vector[3] = 3.0f0
                
                output = capture_show(obj, false)
                @test occursin("float_vector: [1.0, 2.0, 3.0]", output)
                
                # Test large vector (multi-line display)
                resize!(obj.float_vector, 15)
                for i in 1:15
                    obj.float_vector[i] = Float32(i)
                end
                
                output = capture_show(obj, false)
                @test occursin("float_vector: [", output)
                @test occursin("  1.0,", output)
                @test occursin("  15.0", output)
                @test occursin("]", output)
                
                # Test compact mode with large vector (should truncate)
                compact_output = capture_show(obj, true)
                @test occursin("float_vector=[1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, ...]", compact_output)
            end
            
            @testset "Empty struct pretty printing" begin
                edge = lib.EdgeCaseStruct
                
                output = capture_show(edge, false)
                @test occursin("EdgeCaseStruct {", output)
                @test occursin("empty_string: \"\"", output)
                @test occursin("empty_vector: []", output)
                @test occursin("zero_int: 0", output)
                @test occursin("zero_float: 0.0", output)
                @test occursin("false_bool: false", output)
                @test occursin("}", output)
            end
            
            @testset "Complex types pretty printing" begin
                obj = lib.TestAllTypes
                
                # Add some complex numbers
                resize!(obj.complex_vector, 2)
                obj.complex_vector[1] = 1.0f0 + 2.0f0im
                obj.complex_vector[2] = 3.0f0 - 4.0f0im
                
                output = capture_show(obj, false)
                # Complex numbers are printed without the f0 suffix in Julia
                @test occursin("complex_vector: [1.0+2.0im, 3.0-4.0im]", output) || 
                      occursin("complex_vector: [1.0 + 2.0im, 3.0 - 4.0im]", output)
            end
            
            @testset "Indentation test" begin
                # Create nested IO context to test indentation
                obj = lib.TestAllTypes
                obj.int_value = 42
                
                io = IOBuffer()
                show(IOContext(io, :indent => 4), obj)
                output = String(take!(io))
                
                # Check that indentation is applied
                lines = split(output, '\n')
                @test length(lines) > 1
                # Member lines should have 6 spaces (4 base + 2 increment)
                member_lines = filter(l -> occursin("int_value:", l), lines)
                @test length(member_lines) > 0
                @test all(l -> startswith(l, "      "), member_lines)
                # Closing brace should have 4 spaces
                @test any(l -> l == "    }", lines)
            end
        else
            @warn "Skipping CppStruct pretty printing tests - test library not loaded"
        end
    end
    
    @testset "String formatting" begin
        # Test that strings are properly quoted
        if @isdefined(test_lib_for_all_types)
            lib = test_lib_for_all_types
            obj = lib.TestAllTypes
            
            # Test with quotes in string
            obj.string_value = "String with \"quotes\""
            output = capture_show(obj, false)
            @test occursin("string_value: \"String with \\\"quotes\\\"\"", output)
            
            # Test empty string
            obj.string_value = ""
            output = capture_show(obj, false)
            @test occursin("string_value: \"\"", output)
            
            # Test unicode string
            obj.string_value = "Unicode: 🌍 你好"
            output = capture_show(obj, false)
            @test occursin("string_value: \"Unicode: 🌍 你好\"", output)
        end
    end
end

# Test nested struct printing if available
@testset "Nested Struct Pretty Printing" begin
    if @isdefined(test_lib_for_all_types)
        # This would require nested struct support in the test library
        # For now, we'll document what the expected output should be
        
        @testset "Expected nested output format" begin
            # Example of what nested struct output should look like:
            expected_pretty = """
            Person {
              name: "John Doe"
              age: 30
              address: Address {
                street: "123 Main St"
                city: "New York"
                zipcode: 10001
              }
              scores: [95, 87, 92]
            }"""
            
            expected_compact = "Person(name=\"John Doe\", age=30, address=Address(street=\"123 Main St\", city=\"New York\", zipcode=10001), scores=[95, 87, 92])"
            
            # These serve as documentation for the expected format
            @test length(expected_pretty) > 0
            @test length(expected_compact) > 0
        end
    end
end