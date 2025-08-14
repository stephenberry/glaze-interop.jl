# Test file for std::optional<T> support in Glaze.jl
# This file tests the Julia wrapper for C++ std::optional types

using Test
using Glaze

@testset "std::optional<T> Support Tests" begin
    # Get the test library that should already be loaded
    lib = test_lib_for_all_types
    
    @testset "Basic Optional Type Access" begin
        # Test accessing global instance with optional values
        opt_with_values = Glaze.get_instance(lib, "global_optional_with_values")
        
        @test isa(opt_with_values, Glaze.CppStruct)
        
        # Test accessing the required field (non-optional)
        @test opt_with_values.required_field == "required field value"
        
        # Test accessing optional fields that have values
        opt_int_field = opt_with_values.opt_int
        @test isa(opt_int_field, Glaze.CppOptional)
        
        # Test idiomatic Julia way to check for value
        @test !isnothing(opt_int_field)
        @test opt_int_field != nothing
        @test !Glaze.Glaze.isempty(opt_int_field)
        @test length(opt_int_field) == 1
        
        # Test getting the value
        val = Glaze.value(opt_int_field)
        @test val == 42
        
        # Test optional string field
        opt_string_field = opt_with_values.opt_string
        @test isa(opt_string_field, Glaze.CppOptional)
        @test !isnothing(opt_string_field)
        @test Glaze.value(opt_string_field) == "test string"
        
        # Test optional float field  
        opt_float_field = opt_with_values.opt_float
        @test isa(opt_float_field, Glaze.CppOptional)
        @test !isnothing(opt_float_field)
        @test Glaze.value(opt_float_field) ≈ 3.14f0
        
        # Test optional bool field
        opt_bool_field = opt_with_values.opt_bool
        @test isa(opt_bool_field, Glaze.CppOptional)
        @test !isnothing(opt_bool_field)
        @test Glaze.value(opt_bool_field) == true
    end
    
    @testset "Empty Optional Fields" begin
        # Test accessing global instance with empty optional values
        opt_empty = Glaze.get_instance(lib, "global_optional_empty")
        
        @test isa(opt_empty, Glaze.CppStruct)
        
        # Test accessing the required field (non-optional)
        @test opt_empty.required_field == "only required field"
        
        # Test accessing optional fields that are empty
        opt_int_field = opt_empty.opt_int
        @test isa(opt_int_field, Glaze.CppOptional)
        
        # Test that getting value from empty optional throws error
        @test_throws Exception Glaze.value(opt_int_field)
        
        # Test idiomatic ways to check empty optionals
        @test isnothing(opt_int_field)
        @test opt_int_field == nothing
        # Note: === can't be extended for custom types, use == or isnothing
        @test Glaze.isempty(opt_int_field)
        @test length(opt_int_field) == 0
        
        # Verify other empty optional fields
        @test isa(opt_empty.opt_string, Glaze.CppOptional)
        @test isnothing(opt_empty.opt_string)
        
        @test isa(opt_empty.opt_float, Glaze.CppOptional)
        @test isnothing(opt_empty.opt_float)
        
        @test isa(opt_empty.opt_bool, Glaze.CppOptional)
        @test isnothing(opt_empty.opt_bool)
    end
    
    @testset "Nested Optional Structs" begin
        # Test nested struct with optional fields
        nested_with_values = Glaze.get_instance(lib, "global_optional_nested_with_values")
        
        @test isa(nested_with_values, Glaze.CppStruct)
        @test nested_with_values.name == "Nested Test"
        
        # Test optional address field (nested struct)
        opt_address = nested_with_values.opt_address
        @test isa(opt_address, Glaze.CppOptional)
        
        # Test optional vector field
        opt_scores = nested_with_values.opt_scores
        @test isa(opt_scores, Glaze.CppOptional)
        
        # Test nested struct with empty optionals
        nested_empty = Glaze.get_instance(lib, "global_optional_nested_empty")
        
        @test isa(nested_empty, Glaze.CppStruct)
        @test nested_empty.name == "Empty Nested Test"
        
        # Test that optional wrapper types are correctly created
        @test isa(nested_empty.opt_address, Glaze.CppOptional)
        @test isa(nested_empty.opt_scores, Glaze.CppOptional)
    end
    
    @testset "Optional Type Construction" begin
        # Test creating new instances with optional fields
        opt_struct = lib.OptionalTestStruct
        
        @test isa(opt_struct, Glaze.CppStruct)
        
        # Verify that optional fields are properly wrapped
        @test isa(opt_struct.opt_int, Glaze.CppOptional)
        @test isa(opt_struct.opt_string, Glaze.CppOptional)
        @test isa(opt_struct.opt_float, Glaze.CppOptional)
        @test isa(opt_struct.opt_bool, Glaze.CppOptional)
        
        # Required field should be accessible
        opt_struct.required_field = "test value"
        @test opt_struct.required_field == "test value"
        
        # Test that optional fields start empty for new instances
        @test isnothing(opt_struct.opt_int)
        @test isnothing(opt_struct.opt_string)
        @test isnothing(opt_struct.opt_float)
        @test isnothing(opt_struct.opt_bool)
    end
    
    @testset "Optional Pretty Printing" begin
        # Test that optional fields display properly in pretty printing
        opt_with_values = Glaze.get_instance(lib, "global_optional_with_values")
        
        # Capture the pretty printing output
        output = sprint(show, opt_with_values)
        
        # Verify that the output contains expected structure
        @test occursin("OptionalTestStruct", output)
        @test occursin("opt_int:", output)
        @test occursin("opt_string:", output)
        @test occursin("opt_float:", output)
        @test occursin("opt_bool:", output)
        @test occursin("required_field:", output)
        @test occursin("required field value", output)
        
        # Test empty optionals pretty printing
        opt_empty = Glaze.get_instance(lib, "global_optional_empty")
        output_empty = sprint(show, opt_empty)
        
        @test occursin("OptionalTestStruct", output_empty)
        @test occursin("only required field", output_empty)
    end
    
    @testset "Optional in Copy Operations" begin
        # Test that copy! function handles optional fields appropriately
        opt_src = Glaze.get_instance(lib, "global_optional_with_values")
        opt_dest = lib.OptionalTestStruct
        
        # Copy from source to destination
        copy!(opt_dest, opt_src)
        
        # Verify that non-optional fields are copied
        @test opt_dest.required_field == String(opt_src.required_field)
        
        # Test @assign macro with optionals
        opt_dest2 = lib.OptionalTestStruct
        Glaze.@assign opt_dest2 = opt_src
        @test opt_dest2.required_field == String(opt_src.required_field)
        
        # Now verify that optional values are also copied
        @test !isnothing(opt_dest.opt_int)
        @test Glaze.value(opt_dest.opt_int) == 42
        @test !isnothing(opt_dest.opt_string)
        @test Glaze.value(opt_dest.opt_string) == "test string"
    end
    
    @testset "Optional Value Setting and Resetting" begin
        # Test setting values in empty optionals
        opt_empty = Glaze.get_instance(lib, "global_optional_empty")
        opt_int = opt_empty.opt_int
        
        # Initially should be empty
        @test isnothing(opt_int)
        
        # Set a value
        Glaze.set_value!(opt_int, Int32(777))
        @test !isnothing(opt_int)
        @test Glaze.value(opt_int) == 777
        
        # Reset to empty
        Glaze.reset!(opt_int)
        @test isnothing(opt_int)
        @test_throws Exception Glaze.value(opt_int)
        
        # Test with different types
        opt_float = opt_empty.opt_float
        @test isnothing(opt_float)
        Glaze.set_value!(opt_float, Float32(3.14))
        @test !isnothing(opt_float)
        @test Glaze.value(opt_float) ≈ 3.14f0
        
        # Test with bool
        opt_bool = opt_empty.opt_bool
        @test isnothing(opt_bool)
        Glaze.set_value!(opt_bool, true)
        @test !isnothing(opt_bool)
        @test Glaze.value(opt_bool) == true
        
        # Reset bool
        Glaze.reset!(opt_bool)
        @test isnothing(opt_bool)
        
        # Test with string
        opt_string = opt_empty.opt_string
        @test isnothing(opt_string)
        Glaze.set_value!(opt_string, "hello optional")
        @test !isnothing(opt_string)
        @test Glaze.value(opt_string) == "hello optional"
        
        # Reset string
        Glaze.reset!(opt_string)
        @test isnothing(opt_string)
    end
    
    @testset "Error Handling for Optionals" begin
        # Test various error conditions with optionals
        opt_empty = Glaze.get_instance(lib, "global_optional_empty")
        
        # Test getting value from empty optional (should throw)
        @test_throws Exception Glaze.value(opt_empty.opt_int)
        
        # Test that optional wrapper types are created correctly
        @test isa(opt_empty.opt_int, Glaze.CppOptional)
        @test isa(opt_empty.opt_string, Glaze.CppOptional)
        @test isa(opt_empty.opt_float, Glaze.CppOptional)
        @test isa(opt_empty.opt_bool, Glaze.CppOptional)
        
        # Test idiomatic Julia functions work
        @test isnothing(opt_empty.opt_int)
        @test opt_empty.opt_int == nothing
        @test Glaze.isempty(opt_empty.opt_int)
        @test Glaze.something(opt_empty.opt_int, 42) == 42
    end
    
    @testset "Idiomatic Julia Interface" begin
        # Test all the idiomatic Julia features
        opt_with_values = Glaze.get_instance(lib, "global_optional_with_values")
        opt_empty = Glaze.get_instance(lib, "global_optional_empty")
        
        # Test with value present
        opt_int = opt_with_values.opt_int
        @test !isnothing(opt_int)
        @test !(opt_int == nothing)
        @test !Glaze.isempty(opt_int)
        @test length(opt_int) == 1
        @test something(opt_int, 999) == 42
        
        # Test with empty optional
        empty_int = opt_empty.opt_int
        @test isnothing(empty_int)
        @test empty_int == nothing
        @test Glaze.isempty(empty_int)
        @test length(empty_int) == 0
        @test something(empty_int, 999) == 999
        
        # Test that deprecated has_value still works but warns
        @test_deprecated Glaze.has_value(opt_int)
    end
    
    @testset "Optional Value Copying" begin
        # Test copying between objects with optional fields
        # Create new instances to avoid state from previous tests
        src = lib.OptionalTestStruct
        dst = lib.OptionalTestStruct
        
        # Set up source with values
        Glaze.set_value!(src.opt_int, Int32(42))
        Glaze.set_value!(src.opt_string, "test string")
        Glaze.set_value!(src.opt_float, 3.14f0)
        Glaze.set_value!(src.opt_bool, true)
        src.required_field = "source required"
        
        # Verify initial state
        @test !isnothing(src.opt_int)
        @test Glaze.value(src.opt_int) == 42
        @test isnothing(dst.opt_int)
        
        # Copy from source to destination
        Glaze.copy!(dst, src)
        
        # Verify the copy worked
        @test !isnothing(dst.opt_int)
        @test Glaze.value(dst.opt_int) == 42
        @test !isnothing(dst.opt_string)
        @test Glaze.value(dst.opt_string) == "test string"
        @test !isnothing(dst.opt_float)
        @test Glaze.value(dst.opt_float) ≈ 3.14f0
        @test !isnothing(dst.opt_bool)
        @test Glaze.value(dst.opt_bool) == true
        
        # Test copying empty optionals
        empty_src = lib.OptionalTestStruct  # Create fresh instance with empty optionals
        full_dst = lib.OptionalTestStruct
        
        # Set up full destination
        Glaze.set_value!(full_dst.opt_int, Int32(100))
        Glaze.set_value!(full_dst.opt_string, "will be cleared")
        Glaze.set_value!(full_dst.opt_float, 1.0f0)
        Glaze.set_value!(full_dst.opt_bool, false)
        
        # Verify initial state
        @test isnothing(empty_src.opt_int)
        @test !isnothing(full_dst.opt_int)
        
        # Copy empty optionals to full destination
        Glaze.copy!(full_dst, empty_src)
        
        # Verify optionals were reset to empty
        @test isnothing(full_dst.opt_int)
        @test isnothing(full_dst.opt_string)
        @test isnothing(full_dst.opt_float)
        @test isnothing(full_dst.opt_bool)
    end
    
    @testset "Optional set_value! and reset!" begin
        opt_obj = lib.OptionalTestStruct  # Create fresh instance
        
        # Test setting values on empty optionals
        @test isnothing(opt_obj.opt_int)
        Glaze.set_value!(opt_obj.opt_int, Int32(123))
        @test !isnothing(opt_obj.opt_int)
        @test Glaze.value(opt_obj.opt_int) == 123
        
        # Test setting string values
        @test isnothing(opt_obj.opt_string)
        Glaze.set_value!(opt_obj.opt_string, "Hello, World!")
        @test !isnothing(opt_obj.opt_string)
        @test Glaze.value(opt_obj.opt_string) == "Hello, World!"
        
        # Test setting float values
        @test isnothing(opt_obj.opt_float)
        Glaze.set_value!(opt_obj.opt_float, 2.718f0)
        @test !isnothing(opt_obj.opt_float)
        @test Glaze.value(opt_obj.opt_float) ≈ 2.718f0
        
        # Test resetting optionals
        @test !isnothing(opt_obj.opt_int)
        Glaze.reset!(opt_obj.opt_int)
        @test isnothing(opt_obj.opt_int)
        
        @test !isnothing(opt_obj.opt_string)
        Glaze.reset!(opt_obj.opt_string)
        @test isnothing(opt_obj.opt_string)
    end
end