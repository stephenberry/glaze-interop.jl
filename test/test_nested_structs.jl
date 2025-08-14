using Test
using Glaze

@testset "Nested Struct Tests" begin
    # The test library is already loaded by runtests.jl
    # and the init_nested_types function should be called
    
    # Get the test library handle from the parent scope
    lib = Main.test_lib_for_all_types
    
    # Initialize nested types if not already done
    init_nested_func = dlsym(lib.handle, :init_nested_types)
    ccall(init_nested_func, Cvoid, ())
    
    @testset "Basic Nested Struct Access" begin
        # Create a Line instance
        line = lib.Line
        
        # Test accessing nested Point structs
        line.start.x = 1.0f0
        line.start.y = 2.0f0
        line.end.x = 4.0f0
        line.end.y = 6.0f0
        line.length = 5.0f0
        
        @test line.start.x ≈ 1.0f0
        @test line.start.y ≈ 2.0f0
        @test line.end.x ≈ 4.0f0
        @test line.end.y ≈ 6.0f0
        @test line.length ≈ 5.0f0
    end
    
    @testset "Nested Struct Modifications" begin
        line = lib.Line
        
        # Modify start point
        line.start.x = 10.0f0
        line.start.y = 20.0f0
        
        # Verify changes persisted
        @test line.start.x ≈ 10.0f0
        @test line.start.y ≈ 20.0f0
        
        # Modify end point
        line.end.x = 30.0f0
        line.end.y = 40.0f0
        
        @test line.end.x ≈ 30.0f0
        @test line.end.y ≈ 40.0f0
        
        # Calculate and update length
        dx = line.end.x - line.start.x
        dy = line.end.y - line.start.y
        line.length = sqrt(dx^2 + dy^2)
        
        @test line.length ≈ sqrt(20^2 + 20^2)
    end
    
    @testset "Independent Nested Structs" begin
        line1 = lib.Line
        line2 = lib.Line
        
        # Set different values
        line1.start.x = 0.0f0
        line1.start.y = 0.0f0
        line2.start.x = 100.0f0
        line2.start.y = 100.0f0
        
        # Verify they are independent
        @test line1.start.x ≈ 0.0f0
        @test line2.start.x ≈ 100.0f0
        @test line1.start.y ≈ 0.0f0
        @test line2.start.y ≈ 100.0f0
    end
    
    @testset "Registered Instance Access" begin
        # Get the registered test_line instance
        test_line = Glaze.get_instance(lib, "test_line")
        
        # Verify initial values (3-4-5 triangle)
        @test test_line.start.x ≈ 0.0f0
        @test test_line.start.y ≈ 0.0f0
        @test test_line.end.x ≈ 3.0f0
        @test test_line.end.y ≈ 4.0f0
        @test test_line.length ≈ 5.0f0
        
        # Modify the registered instance
        test_line.start.x = 1.0f0
        test_line.start.y = 1.0f0
        test_line.end.x = 4.0f0
        test_line.end.y = 5.0f0
        
        # Calculate new length
        dx = test_line.end.x - test_line.start.x
        dy = test_line.end.y - test_line.start.y
        test_line.length = sqrt(dx^2 + dy^2)
        
        @test test_line.length ≈ 5.0f0  # Still a 3-4-5 triangle
        
        # Get the instance again to verify persistence
        test_line2 = Glaze.get_instance(lib, "test_line")
        @test test_line2.start.x ≈ 1.0f0
        @test test_line2.start.y ≈ 1.0f0
        @test test_line2.end.x ≈ 4.0f0
        @test test_line2.end.y ≈ 5.0f0
        @test test_line2.length ≈ 5.0f0
    end
end