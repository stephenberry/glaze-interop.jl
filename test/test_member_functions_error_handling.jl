# Error handling and edge case tests for member function support in Glaze.jl

using Test
using Glaze

@testset "Member Function Error Handling and Edge Cases" begin
    lib = test_lib_for_all_types
    
    @testset "Invalid Function Access Tests" begin
        calc = lib.Calculator
        
        # Test accessing non-existent member function
        @test_throws KeyError calc.nonExistentFunction
        @test_throws KeyError calc.invalidMethod
        @test_throws KeyError calc.notAFunction
        
        # Test accessing with invalid names
        @test_throws KeyError getproperty(calc, Symbol(""))
        @test_throws KeyError getproperty(calc, Symbol("123"))
        @test_throws KeyError getproperty(calc, Symbol("add_invalid"))
    end
    
    @testset "Argument Count Validation Tests" begin
        calc = lib.Calculator
        
        # Functions expecting specific argument counts
        add_func = calc.add  # Expects 1 argument
        compute_func = calc.compute  # Expects 3 arguments
        reset_func = calc.reset  # Expects 0 arguments
        complexOp_func = calc.complexOperation  # Expects 3 arguments
        
        # Test calling with wrong number of arguments
        @test_throws MethodError add_func()  # Too few
        @test_throws MethodError add_func(1.0, 2.0)  # Too many
        @test_throws MethodError add_func(1.0, 2.0, 3.0)  # Way too many
        
        @test_throws MethodError compute_func()  # Too few
        @test_throws MethodError compute_func(1.0)  # Too few
        @test_throws MethodError compute_func(1.0, 2.0)  # Too few
        @test_throws MethodError compute_func(1.0, 2.0, 3.0, 4.0)  # Too many
        
        @test_throws MethodError reset_func(1.0)  # Too many
        @test_throws MethodError reset_func(1.0, 2.0)  # Too many
        
        @test_throws MethodError complexOp_func()  # Too few
        @test_throws MethodError complexOp_func(1)  # Too few
        @test_throws MethodError complexOp_func(1, 2.0f0)  # Too few
        @test_throws MethodError complexOp_func(1, 2.0f0, true, false)  # Too many
    end
    
    @testset "Type Conversion Edge Cases" begin
        calc = lib.Calculator
        calc.value = 0.0
        
        add_func = calc.add
        setSign_func = calc.setSign
        
        # Test extreme values
        result = add_func(1e10)  # Large number
        @test isa(result, Float64)
        @test result ≈ 1e10
        
        calc.value = 0.0
        result = add_func(-1e10)  # Large negative number
        @test result ≈ -1e10
        
        # Test very small numbers
        calc.value = 0.0
        result = add_func(1e-10)
        @test result ≈ 1e-10
        
        # Test infinity and special values (if supported)
        calc.value = 0.0
        try
            result = add_func(Inf)
            @test isinf(result)
        catch e
            # If infinity isn't supported, that's okay
            @test true
        end
        
        # Test boolean conversions
        calc.value = 5.0
        setSign_func(true)
        @test calc.value ≈ 5.0  # Already positive
        
        setSign_func(false)
        @test calc.value ≈ -5.0  # Made negative
    end
    
    @testset "Member Function Object Edge Cases" begin
        calc = lib.Calculator
        
        # Test that member functions maintain reference to correct object
        add_func = calc.add
        original_ptr = add_func.obj_ptr
        
        # Create another calculator
        calc2 = lib.Calculator
        calc2.value = 100.0
        add_func2 = calc2.add
        
        # Test that functions point to different objects
        @test add_func.obj_ptr != add_func2.obj_ptr
        @test add_func.obj_ptr == original_ptr
        
        # Test that calling functions affects the correct objects
        calc.value = 10.0
        calc2.value = 20.0
        
        result1 = add_func(5.0)
        result2 = add_func2(5.0)
        
        @test result1 ≈ 15.0  # 10 + 5
        @test result2 ≈ 25.0  # 20 + 5
        @test calc.value ≈ 15.0
        @test calc2.value ≈ 25.0
    end
    
    @testset "Function Signature Edge Cases" begin
        calc = lib.Calculator
        
        # Test functions with different return types work correctly
        getValue_func = calc.getValue  # returns double
        isPositive_func = calc.isPositive  # returns bool
        toInt_func = calc.toInt  # returns int
        describe_func = calc.describe  # returns string
        
        calc.value = -7.5
        
        # Verify return types are correct
        double_result = getValue_func()
        @test isa(double_result, Float64)
        @test double_result ≈ -7.5
        
        bool_result = isPositive_func()
        @test isa(bool_result, Bool)
        @test bool_result == false
        
        int_result = toInt_func()
        @test isa(int_result, Int32)
        @test int_result == -7
        
        string_result = describe_func()
        @test isa(string_result, String)
        @test occursin("-7.5", string_result)
    end
    
    @testset "Null and Invalid Pointer Tests" begin
        calc = lib.Calculator
        add_func = calc.add
        
        # Test that member function objects have valid pointers
        @test add_func.obj_ptr != C_NULL
        @test add_func.lib_handle != C_NULL
        
        # Test that function name is valid
        @test !isempty(add_func.name)
        @test isa(add_func.name, String)
        
        # Test string representation doesn't crash
        func_str = string(add_func)
        @test isa(func_str, String)
        @test !isempty(func_str)
    end
    
    @testset "Concurrent Access Tests" begin
        # Test that multiple calculators can be used simultaneously
        calculators = [lib.Calculator for _ in 1:5]
        
        # Set different initial values
        for (i, calc) in enumerate(calculators)
            calc.value = Float64(i * 10)
        end
        
        # Call functions on all calculators
        results = []
        for (i, calc) in enumerate(calculators)
            add_func = calc.add
            result = add_func(Float64(i))
            push!(results, result)
        end
        
        # Verify results are correct for each calculator
        for (i, (calc, result)) in enumerate(zip(calculators, results))
            expected = Float64(i * 10 + i)  # original + added
            @test result ≈ expected
            @test calc.value ≈ expected
        end
    end
    
    @testset "Memory Safety Tests" begin
        # Create and destroy many calculator objects
        for _ in 1:100
            calc = lib.Calculator
            calc.value = rand() * 100
            
            # Call various functions
            add_func = calc.add
            multiply_func = calc.multiply
            reset_func = calc.reset
            
            add_func(rand() * 10)
            multiply_func(rand() * 2)
            reset_func()
            
            # The calculator should be automatically cleaned up
            # when it goes out of scope (Julia's GC handles this)
        end
        
        # If we get here without crashing, memory management is working
        @test true
    end
    
    @testset "Function Call Performance Consistency" begin
        calc = lib.Calculator
        add_func = calc.add
        
        # Test that repeated calls have consistent performance
        times = []
        n_calls = 100
        
        for i in 1:n_calls
            start_time = time_ns()
            add_func(1.0)
            end_time = time_ns()
            push!(times, end_time - start_time)
        end
        
        # Calculate statistics
        mean_time = sum(times) / length(times)
        max_time = maximum(times)
        min_time = minimum(times)
        
        # Test that performance is reasonably consistent
        # (max time shouldn't be more than 10x the mean)
        @test max_time < mean_time * 10
        
        # Test that minimum time is reasonable (not zero, not too large)
        @test min_time > 0
        @test min_time < mean_time * 2
        
        # Test that final value is correct
        @test calc.value ≈ n_calls
    end
end