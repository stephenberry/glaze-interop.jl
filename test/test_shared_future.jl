push!(LOAD_PATH, dirname(@__DIR__))
using Glaze
using Test
using Libdl

# Check if running standalone or as part of test suite
if !@isdefined(test_lib_for_all_types)
    # Running standalone - need to load library
    test_dir = @__DIR__
    build_dir = joinpath(test_dir, "build")
    test_lib_path = joinpath(build_dir, Sys.iswindows() ? "test_lib.dll" : Sys.isapple() ? "libtest_lib.dylib" : "libtest_lib.so")

    handle = Libdl.dlopen(test_lib_path)
    init_func = Libdl.dlsym(handle, :init_test_types_complete)
    ccall(init_func, Cvoid, ())

    lib = Glaze.CppLibrary(test_lib_path)
else
    # Running as part of test suite - use shared library
    lib = test_lib_for_all_types
end

@testset "Shared Future Support" begin
    future_test = get_instance(lib, "global_future_test")
    
    @testset "Ready Future" begin
        # Get a ready future
        future = future_test.getReadyFuture(Int32(42))
        
        @test isa(future, Glaze.CppSharedFuture)
        @test isvalid(future)
        @test isready(future)
        
        # Get the value
        value = get(future)
        @test value == 42
        @test isa(value, Int32)
    end
    
    @testset "Async Computation" begin
        # Start an async computation with 50ms delay
        future = future_test.computeAsync(3.14, 50)
        
        @test isa(future, Glaze.CppSharedFuture)
        @test isvalid(future)
        
        # Initially might not be ready
        initial_ready = isready(future)
        
        # Wait for it
        wait(future)
        
        # Now it should be ready
        @test isready(future)
        
        # Get the value
        value = get(future)
        @test value ≈ 6.28
        @test isa(value, Float64)
    end
    
    @testset "String Future" begin
        # Get a string future with 10ms delay
        future = future_test.getStringAsync("Hello", 10)
        
        @test isa(future, Glaze.CppSharedFuture)
        @test isvalid(future)
        
        # Wait and get
        wait(future)
        value = get(future)
        
        @test value == "Hello from future"
        @test isa(value, String)
    end
    
    @testset "Vector Future" begin
        # Get a vector future with 10ms delay
        future = future_test.getVectorAsync(5, 10)
        
        @test isa(future, Glaze.CppSharedFuture)
        @test isvalid(future)
        
        # Wait and get
        wait(future)
        value = get(future)
        
        @test value == Int32[0, 1, 4, 9, 16]
        @test isa(value, Vector{Int32})
    end
    
    @testset "Invalid Future" begin
        # Get an invalid future
        future = future_test.getInvalidFuture()
        
        @test isa(future, Glaze.CppSharedFuture)
        @test !isvalid(future)
        
        # Getting from invalid future should error
        @test_throws ErrorException get(future)
    end
    
    @testset "Pretty Printing" begin
        ready_future = future_test.getReadyFuture(Int32(1))
        @test occursin("ready", string(ready_future))
        
        invalid_future = future_test.getInvalidFuture()
        @test occursin("invalid", string(invalid_future))
        
        # Test pending state
        slow_future = future_test.computeAsync(1.0, 1000)  # 1 second delay
        if !isready(slow_future)
            @test occursin("pending", string(slow_future))
        end
    end
    
    @testset "Struct with Vectors Future" begin
        # Get a future that returns a Person struct containing vectors
        future = future_test.getPersonAsync("John Doe", 30, 10)
        
        @test isa(future, Glaze.CppSharedFuture)
        @test isvalid(future)
        
        # Wait and get the struct
        wait(future)
        value = get(future)
        
        # Test that it's a CppStruct
        @test isa(value, Glaze.CppStruct)
        
        # Test the struct fields have correct values
        @test value.name == "John Doe"
        @test value.age == 30
        @test isa(value.address, Glaze.CppStruct)
        @test isa(value.scores, Union{Glaze.CppVector, Glaze.CppVectorInt32})
        
        # Test the nested address struct
        @test value.address.street == "123 Future St"
        @test value.address.city == "Async City"
        @test value.address.zipcode == 12345
        
        # Test the scores vector field
        @test length(value.scores) == 5
        @test collect(value.scores) == Int32[30, 40, 50, 60, 70]
    end
end