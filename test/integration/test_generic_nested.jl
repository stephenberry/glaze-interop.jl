using Test
using Glaze
using Libdl

@testset "Generic Nested Struct Resolution" begin
    # Build the test library
    cd(@__DIR__)
    run(`g++ -std=c++23 -shared -fPIC -o libgeneric_nested_test.dylib 
         test_generic_nested.cpp 
         ../build/_deps/glaze-src/src/interop/interop.cpp
         -I../build/_deps/glaze-src/include 
         -DGLZ_EXPORTS`)
    
    # Load the library
    lib = Glaze.load("libgeneric_nested_test.dylib")
    
    # Initialize
    init_func = dlsym(lib.handle, :init_generic_test)
    ccall(init_func, Cvoid, ())
    
    # Get the database instance
    db = Glaze.get_instance(lib, "test_database")
    
    @test db.connection_string == "postgresql://localhost:5432/mydb"
    @test db.is_connected == false
    
    # Test nested struct access - this should work with generic type resolution
    @test db.config.name == "MyDB"
    @test db.config.version == 1
    
    # Modify nested struct
    db.config.version = 2
    @test db.config.version == 2
    
    println("✓ Generic nested struct resolution working correctly!")
end