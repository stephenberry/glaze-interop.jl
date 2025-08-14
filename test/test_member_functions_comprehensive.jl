# Comprehensive but safer tests for member function support in Glaze.jl
# This version avoids patterns that cause segfaults

using Test
using Glaze

@testset "Comprehensive Member Function Tests" begin
    lib = test_lib_for_all_types
    
    @testset "Return Type Validation" begin
        calc = lib.Calculator
        calc.value = 7.5
        
        # Test bool return types
        isPositive_func = calc.isPositive
        result = isPositive_func()
        @test isa(result, Bool)
        @test result == true
        
        isGreaterThan_func = calc.isGreaterThan
        result = isGreaterThan_func(5.0)
        @test isa(result, Bool) 
        @test result == true
        
        result = isGreaterThan_func(10.0)
        @test isa(result, Bool)
        @test result == false
        
        # Test integer return types
        toInt_func = calc.toInt
        result = toInt_func()
        @test isa(result, Int32)
        @test result == 7
        
        # Test float return types
        getSquare_func = calc.getSquare
        result = getSquare_func()
        @test isa(result, Float64)
        @test result ≈ 56.25  # 7.5^2
        
        # Test double return that always returns zero
        getZero_func = calc.getZero
        result = getZero_func()
        @test isa(result, Float64)
        @test result == 0.0
        
        # Test void return (should return nothing)
        increment_func = calc.increment
        original_value = calc.value
        result = increment_func()
        @test result === nothing
        @test calc.value ≈ original_value + 1.0
        
        # Test string return
        describe_func = calc.describe
        result = describe_func()
        @test isa(result, String)
        @test occursin("Calculator", result)
        @test occursin(string(calc.value), result)
    end
    
    @testset "Parameter Type Handling" begin
        calc = lib.Calculator
        
        # Test boolean parameters
        calc.value = 10.0
        setSign_func = calc.setSign
        
        # Make positive number negative
        setSign_func(false)
        @test calc.value ≈ -10.0
        
        # Make negative number positive
        setSign_func(true) 
        @test calc.value ≈ 10.0
        
        # Test float parameters
        calc.value = 5.0
        addFloat_func = calc.addFloat
        result = addFloat_func(2.5f0)
        @test isa(result, Float32)
        @test result ≈ 7.5f0
        @test calc.value ≈ 7.5
    end
    
    @testset "Multiple Parameter Functions" begin
        calc = lib.Calculator
        calc.value = 2.0
        
        # Test 3-parameter function with mixed types
        complexOp_func = calc.complexOperation
        # complexOperation(int multiplier, float offset, bool negate)
        result = complexOp_func(3, 1.0f0, false)
        expected = 2.0 * 3 + 1.0  # 7.0
        @test isa(result, Float64)
        @test result ≈ expected
        @test calc.value ≈ expected
        
        # Test with negation
        calc.value = 4.0
        result = complexOp_func(2, 0.0f0, true) 
        expected = -(4.0 * 2 + 0.0)  # -8.0
        @test result ≈ expected
        @test calc.value ≈ expected
    end
    
    @testset "Function State Management" begin
        calc = lib.Calculator
        reset_func = calc.reset
        add_func = calc.add
        multiply_func = calc.multiply
        getValue_func = calc.getValue
        
        # Test function chaining
        reset_func()
        @test calc.value ≈ 0.0
        
        result = add_func(10.0)
        @test result ≈ 10.0
        @test calc.value ≈ 10.0
        
        result = multiply_func(3.0)
        @test result ≈ 30.0
        @test calc.value ≈ 30.0
        
        # Const function shouldn't change state
        result = getValue_func()
        @test result ≈ 30.0
        @test calc.value ≈ 30.0  # Unchanged
    end
    
    @testset "Type Conversion Edge Cases" begin
        calc = lib.Calculator
        calc.value = 0.0
        
        add_func = calc.add
        
        # Test integer to double conversion
        result = add_func(5)
        @test isa(result, Float64)
        @test result ≈ 5.0
        
        # Test Float32 to double conversion
        calc.value = 0.0
        result = add_func(3.5f0)
        @test isa(result, Float64)
        @test result ≈ 3.5
        
        # Test large numbers
        calc.value = 0.0
        result = add_func(1e6)
        @test isa(result, Float64)
        @test result ≈ 1e6
    end
    
    @testset "Member Function Object Properties" begin
        calc = lib.Calculator
        
        # Test basic function properties
        basic_functions = ["add", "multiply", "reset", "getValue", "setValue"]
        for func_name in basic_functions
            member_func = getproperty(calc, Symbol(func_name))
            @test isa(member_func, Glaze.CppMemberFunction)
            @test member_func.name == func_name
            @test member_func.obj_ptr == calc.ptr
            @test member_func.lib_handle == calc.lib
        end
        
        # Test extended function properties  
        extended_functions = ["isPositive", "toInt", "getSquare", "setSign", "increment"]
        for func_name in extended_functions
            member_func = getproperty(calc, Symbol(func_name))
            @test isa(member_func, Glaze.CppMemberFunction)
            @test member_func.name == func_name
            @test member_func.obj_ptr == calc.ptr
            @test member_func.lib_handle == calc.lib
        end
    end
    
    @testset "Multiple Object Independence" begin
        # Test that multiple calculator objects work independently
        calc1 = lib.Calculator
        calc2 = lib.Calculator
        
        calc1.value = 10.0
        calc2.value = 20.0
        
        add_func1 = calc1.add
        add_func2 = calc2.add
        
        # Verify functions point to different objects
        @test add_func1.obj_ptr != add_func2.obj_ptr
        
        # Test that operations affect correct objects
        result1 = add_func1(5.0)
        result2 = add_func2(3.0)
        
        @test result1 ≈ 15.0
        @test result2 ≈ 23.0
        @test calc1.value ≈ 15.0
        @test calc2.value ≈ 23.0
    end
    
    @testset "Const vs Non-Const Functions" begin
        calc = lib.Calculator
        calc.value = 42.0
        
        # Test const functions (don't modify state)
        const_functions = [calc.getValue, calc.isPositive, calc.getSquare, calc.getZero]
        original_value = calc.value
        
        for const_func in const_functions
            result = const_func()
            @test calc.value ≈ original_value  # Value should be unchanged
        end
        
        # Test non-const functions (do modify state)
        increment_func = calc.increment
        increment_func()
        @test calc.value ≈ original_value + 1.0  # Value changed
    end  
    
    @testset "Performance Consistency" begin
        calc = lib.Calculator
        calc.value = 0.0
        
        add_func = calc.add
        
        # Test that repeated calls work correctly
        for i in 1:10
            result = add_func(1.0)
            @test result ≈ Float64(i)
            @test calc.value ≈ Float64(i)
        end
        
        @test calc.value ≈ 10.0
    end
end