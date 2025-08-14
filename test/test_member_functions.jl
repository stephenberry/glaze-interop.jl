# Test file for member function support in Glaze.jl
# This file tests the Julia wrapper's handling of C++ member functions

using Test
using Glaze

@testset "Member Function Support Tests" begin
    # Get the test library that should already be loaded
    lib = test_lib_for_all_types
    
    @testset "Calculator Struct Creation" begin
        # First check if Calculator type exists
        calc = try
            lib.Calculator
        catch e
            @test_skip "Calculator type not available in test library"
            return
        end
        
        @test isa(calc, Glaze.CppStruct)
        
        # Test setting and getting the value field
        calc.value = 10.0
        @test calc.value ≈ 10.0
    end
    
    @testset "Calculator Struct Access" begin
        # Test accessing global calculator instance
        calc = try
            Glaze.get_instance(lib, "global_calculator")
        catch e
            # If instance doesn't exist, create one
            calc = lib.Calculator
            calc.value = 42.0
            calc
        end
        
        @test isa(calc, Glaze.CppStruct)
        
        # Test accessing the value field (data member)
        @test calc.value ≈ 42.0
        
        # Test that accessing member functions now returns CppMemberFunction objects
        add_func = calc.add
        @test isa(add_func, Glaze.CppMemberFunction)
        @test add_func.name == "add"
        
        multiply_func = calc.multiply
        @test isa(multiply_func, Glaze.CppMemberFunction)
        @test multiply_func.name == "multiply"
        
        reset_func = calc.reset
        @test isa(reset_func, Glaze.CppMemberFunction)
        @test reset_func.name == "reset"
        
        # Test that calling member functions now works
        # Test add function - should modify calc.value and return result
        initial_value = calc.value
        result = add_func(5.0)
        @test isa(result, Float64)
        @test result ≈ initial_value + 5.0
        @test calc.value ≈ result  # Value should be updated
        
        # Test reset function - should set value to 0 and return nothing
        reset_result = reset_func()
        @test reset_result === nothing
        @test calc.value ≈ 0.0
    end
    
    @testset "Calculator Pretty Printing" begin
        calc = try
            Glaze.get_instance(lib, "global_calculator")
        catch e
            # Create a new instance if global doesn't exist
            c = lib.Calculator
            c.value = 42.0
            c
        end
        
        # Test that pretty printing skips member functions
        output = sprint(show, calc)
        
        # Should contain the struct name and value field
        @test occursin("Calculator", output)
        @test occursin("value", output)
        # The value might have changed during previous tests, so just check it's a number
        @test occursin(r"\d+\.?\d*", output)
        
        # Should NOT contain member function names
        @test !occursin("add", output)
        @test !occursin("multiply", output) 
        @test !occursin("reset", output)
        @test !occursin("getValue", output)
        @test !occursin("setValue", output)
        @test !occursin("compute", output)
        @test !occursin("describe", output)
    end
    
    @testset "Calculator Copy Operations" begin
        calc = try
            Glaze.get_instance(lib, "global_calculator") 
        catch e
            c = lib.Calculator
            c.value = 42.0
            c
        end
        calc_new = lib.Calculator
        
        # Copy should work and only copy data members
        copy!(calc_new, calc)
        
        # Verify value was copied
        @test calc_new.value ≈ calc.value
        
        # Test @assign macro with calculator
        calc_new2 = lib.Calculator
        calc_new2.value = 0.0  # Set to different value first
        Glaze.@assign calc_new2 = calc
        @test calc_new2.value ≈ calc.value
    end
    
    @testset "Setting Member Functions Should Fail" begin
        calc = try
            Glaze.get_instance(lib, "global_calculator") 
        catch e
            lib.Calculator
        end
        
        # Test that trying to set member functions fails with helpful error
        @test_throws ErrorException("Cannot set value of member function 'add'. Member functions are not modifiable.") calc.add = 5
        @test_throws ErrorException("Cannot set value of member function 'reset'. Member functions are not modifiable.") calc.reset = nothing
    end
    
    @testset "Member Function Objects" begin
        calc = try
            Glaze.get_instance(lib, "global_calculator") 
        catch e
            lib.Calculator
        end
        
        # Test that member functions return callable objects
        add_func = calc.add
        @test isa(add_func, Glaze.CppMemberFunction)
        @test add_func.name == "add"
        
        # Test pretty printing of member functions
        output = sprint(show, add_func)
        @test occursin("CppMemberFunction(add)", output)
        
        # Test that member functions have the right object pointer
        @test add_func.obj_ptr == calc.ptr
        @test add_func.lib_handle == calc.lib
    end
    
    @testset "Comprehensive Function Calling" begin
        calc = try
            Glaze.get_instance(lib, "global_calculator") 
        catch e
            c = lib.Calculator
            c.value = 10.0
            c
        end
        
        # Reset the calculator to a known state for consistent testing
        reset_func = calc.reset
        reset_func()
        @test calc.value ≈ 0.0
        
        # Now set to our test value
        calc.value = 10.0
        @test calc.value ≈ 10.0
        
        # Test various function signatures
        
        # Test add(double) -> double
        add_func = calc.add
        result = add_func(3.0)
        @test isa(result, Float64)
        @test result ≈ 13.0
        @test calc.value ≈ 13.0
        
        # Test multiply(double) -> double
        multiply_func = calc.multiply
        result = multiply_func(2.0)
        @test isa(result, Float64)
        @test result ≈ 26.0
        @test calc.value ≈ 26.0
        
        # Test getValue() -> double (const function)
        getValue_func = calc.getValue
        result = getValue_func()
        @test isa(result, Float64)
        @test result ≈ 26.0
        
        # Test setValue(double) -> void
        setValue_func = calc.setValue
        result = setValue_func(100.0)
        @test result === nothing
        @test calc.value ≈ 100.0
        
        # Test reset() -> void
        reset_func = calc.reset
        result = reset_func()
        @test result === nothing
        @test calc.value ≈ 0.0
        
        # Test compute(double, double, double) -> double (3 parameters)
        calc.value = 5.0  # Set base value
        compute_func = calc.compute
        result = compute_func(2.0, 3.0, 10.0)
        @test isa(result, Float64)
        # compute should return: a * value + b * value + c = 2*5 + 3*5 + 10 = 35
        @test result ≈ 35.0
        
        # Test different argument types (integers should work)
        # First reset to a known state
        setValue_func = calc.setValue
        setValue_func(0.0)
        @test calc.value ≈ 0.0
        
        add_result = add_func(7)  # Pass integer
        @test isa(add_result, Float64)
        @test add_result ≈ 7.0
    end
end