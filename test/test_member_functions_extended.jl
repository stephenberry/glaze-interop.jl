# Extended test file for comprehensive member function support in Glaze.jl
# This file tests a wide variety of member function scenarios

using Test
using Glaze

@testset "Extended Member Function Tests" begin
    # Get the test library that should already be loaded
    lib = test_lib_for_all_types
    
    @testset "Return Type Variety Tests" begin
        calc = try
            Glaze.get_instance(lib, "global_calculator")
        catch e
            c = lib.Calculator
            c.value = 5.0
            c
        end
        
        # Reset to known state
        reset_func = calc.reset
        reset_func()
        calc.value = 5.0
        
        # Test bool return type with no parameters
        isPositive_func = calc.isPositive
        @test isa(isPositive_func, Glaze.CppMemberFunction)
        result = isPositive_func()
        @test isa(result, Bool)
        @test result == true  # 5.0 is positive
        
        # Test bool return type with parameters
        isGreaterThan_func = calc.isGreaterThan
        result1 = isGreaterThan_func(3.0)
        @test isa(result1, Bool)
        @test result1 == true  # 5.0 > 3.0
        
        result2 = isGreaterThan_func(10.0)
        @test isa(result2, Bool)
        @test result2 == false  # 5.0 < 10.0
        
        # Test int return type
        toInt_func = calc.toInt
        result = toInt_func()
        @test isa(result, Int32)
        @test result == 5
        
        # Test float return type
        addFloat_func = calc.addFloat
        result = addFloat_func(2.5f0)
        @test isa(result, Float32)
        @test result ≈ 7.5f0
        @test calc.value ≈ 7.5  # Value should be updated
        
        # Test string return type (already tested in basic tests)
        describe_func = calc.describe
        result = describe_func()
        @test isa(result, String)
        @test occursin("7.5", result)
    end
    
    @testset "Parameter Type Variety Tests" begin
        calc = lib.Calculator
        calc.value = 10.0
        
        # Test boolean parameter
        setSign_func = calc.setSign
        # Test making positive number negative
        setSign_func(false)  # Make negative
        @test calc.value ≈ -10.0
        
        # Test making negative number positive  
        setSign_func(true)   # Make positive
        @test calc.value ≈ 10.0
        
        # Test mixed parameter types (int, float, bool)
        complexOp_func = calc.complexOperation
        # complexOperation(int multiplier, float offset, bool negate)
        # result = value * multiplier + offset, then negate if needed
        result = complexOp_func(2, 5.0f0, false)
        @test isa(result, Float64)
        expected = 10.0 * 2 + 5.0  # 25.0
        @test result ≈ expected
        @test calc.value ≈ expected
        
        # Test with negation
        calc.value = 3.0
        result = complexOp_func(4, 2.0f0, true)
        expected = -(3.0 * 4 + 2.0)  # -(14.0) = -14.0
        @test result ≈ expected
        @test calc.value ≈ expected
    end
    
    @testset "Edge Case Function Tests" begin
        calc = lib.Calculator
        calc.value = 42.0
        
        # Test function that always returns zero
        getZero_func = calc.getZero
        result = getZero_func()
        @test isa(result, Float64)
        @test result == 0.0
        @test calc.value ≈ 42.0  # Original value unchanged
        
        # Test function that modifies without returning the value
        increment_func = calc.increment
        original_value = calc.value
        result = increment_func()
        @test result === nothing  # void return
        @test calc.value ≈ original_value + 1.0
        
        # Test function returning computed value different from stored value
        getSquare_func = calc.getSquare
        calc.value = 6.0
        result = getSquare_func()
        @test isa(result, Float64)
        @test result ≈ 36.0  # 6^2
        @test calc.value ≈ 6.0  # Original value unchanged
        
        # Test function that takes same type it returns
        doubleOp_func = calc.doubleOperation
        result = doubleOp_func(7.0)
        @test isa(result, Float64)
        @test result ≈ 14.0  # 7.0 * 2
        @test calc.value ≈ 14.0  # Value updated to result
    end
    
    @testset "Type Conversion Tests" begin
        calc = lib.Calculator
        calc.value = 0.0
        
        # Test automatic type conversion from Julia types
        add_func = calc.add
        
        # Integer to double conversion
        result = add_func(5)  # Pass Int64
        @test isa(result, Float64)
        @test result ≈ 5.0
        
        # Float32 to double conversion  
        result = add_func(3.5f0)  # Pass Float32
        @test isa(result, Float64)
        @test result ≈ 8.5
        
        # Test boolean parameters
        setSign_func = calc.setSign
        setSign_func(1)  # Should convert to true
        @test calc.value ≈ 8.5  # Positive, so no change
        
        setSign_func(0)  # Should convert to false
        @test calc.value ≈ -8.5  # Made negative
    end
    
    @testset "Function Chaining Tests" begin
        calc = lib.Calculator
        reset_func = calc.reset
        add_func = calc.add
        multiply_func = calc.multiply
        getValue_func = calc.getValue
        
        # Test function chaining - reset, add, multiply, get
        reset_func()
        @test calc.value ≈ 0.0
        
        add_func(10.0)
        @test calc.value ≈ 10.0
        
        multiply_func(3.0)
        @test calc.value ≈ 30.0
        
        final_value = getValue_func()
        @test final_value ≈ 30.0
        @test calc.value ≈ 30.0
    end
    
    @testset "Const vs Non-Const Function Tests" begin
        calc = lib.Calculator
        calc.value = 15.0
        
        # Test const functions (shouldn't modify state)
        getValue_func = calc.getValue  # const function
        isPositive_func = calc.isPositive  # const function  
        getSquare_func = calc.getSquare  # const function
        
        original_value = calc.value
        
        # Call const functions multiple times
        for _ in 1:3
            @test getValue_func() ≈ original_value
            @test isPositive_func() == true
            @test getSquare_func() ≈ original_value^2
            @test calc.value ≈ original_value  # Value unchanged
        end
        
        # Test non-const functions (should modify state)
        increment_func = calc.increment  # non-const function
        increment_func()
        @test calc.value ≈ original_value + 1.0
        
        add_func = calc.add  # non-const function
        add_func(5.0)
        @test calc.value ≈ original_value + 1.0 + 5.0
    end
    
    @testset "Multiple Parameter Function Tests" begin
        calc = lib.Calculator
        calc.value = 2.0
        
        # Test 3-parameter function
        compute_func = calc.compute
        # compute(a, b, c) = a * value + b * value + c
        result = compute_func(3.0, 4.0, 5.0)
        expected = 3.0 * 2.0 + 4.0 * 2.0 + 5.0  # 6 + 8 + 5 = 19
        @test result ≈ expected
        
        # Test mixed type 3-parameter function
        complexOp_func = calc.complexOperation
        # complexOperation(int, float, bool)
        calc.value = 1.0
        result = complexOp_func(10, 0.5f0, false)
        expected = 1.0 * 10 + 0.5  # 10.5
        @test result ≈ expected
        @test calc.value ≈ expected
    end
    
    @testset "Error Handling Tests" begin
        calc = lib.Calculator
        
        # Test accessing non-existent function
        @test_throws ErrorException calc.nonExistentFunction
        
        # Test calling function with wrong number of arguments
        add_func = calc.add
        @test_throws MethodError add_func()  # Too few arguments
        @test_throws MethodError add_func(1.0, 2.0)  # Too many arguments
        
        # Test calling with completely wrong argument types (should still work due to conversion)
        # But test that the conversion works reasonably
        result = add_func("5")  # String should convert to number
        @test isa(result, Float64)
    end
    
    @testset "Performance and Stress Tests" begin
        calc = lib.Calculator
        reset_func = calc.reset
        add_func = calc.add
        getValue_func = calc.getValue
        
        reset_func()
        
        # Test calling functions many times
        n_iterations = 1000
        
        # Time multiple function calls
        start_time = time()
        for i in 1:n_iterations
            add_func(0.001)
        end
        end_time = time()
        
        @test calc.value ≈ n_iterations * 0.001
        
        # Test that function calls are reasonably fast
        avg_time_per_call = (end_time - start_time) / n_iterations
        @test avg_time_per_call < 0.001  # Less than 1ms per call
        
        # Test interleaved function calls
        reset_func()
        for i in 1:100
            add_func(1.0)
            current = getValue_func()
            @test current ≈ i
        end
    end
    
    @testset "Member Function Object Properties" begin
        calc = lib.Calculator
        
        # Test that all member functions have correct properties
        function_names = [
            "add", "multiply", "reset", "getValue", "setValue", "compute", "describe",
            "isPositive", "isGreaterThan", "toInt", "addFloat", "getSquare", 
            "setSign", "complexOperation", "getZero", "increment", "doubleOperation"
        ]
        
        for func_name in function_names
            member_func = getproperty(calc, Symbol(func_name))
            @test isa(member_func, Glaze.CppMemberFunction)
            @test member_func.name == func_name
            @test member_func.obj_ptr == calc.ptr
            @test member_func.lib_handle == calc.lib
            
            # Test string representation
            func_str = string(member_func)
            @test occursin("CppMemberFunction", func_str)
            @test occursin(func_name, func_str)
        end
    end
end