using Test
using Glaze
using Libdl

@testset "Generic Nested Struct Resolution" begin
    # Build the test library with correct extension for platform
    cd(@__DIR__)
    lib_name = if Sys.iswindows()
        "libgeneric_nested_test.dll"
    elseif Sys.isapple()
        "libgeneric_nested_test.dylib"
    else
        "libgeneric_nested_test.so"
    end
    
    # Determine appropriate C++ standard flag based on compiler
    # Clang 15 and earlier use c++2b for C++23 preview
    cxx_std = try
        # Check if we're using clang
        version_output = read(`g++ --version`, String)
        if occursin("clang", version_output)
            # Check clang version
            if occursin(r"clang version 1[0-5]\.", version_output)
                "c++2b"  # Clang 15 and earlier
            else
                "c++23"  # Clang 16+
            end
        else
            # Assume GCC which supports c++23
            "c++23"
        end
    catch
        # Fallback: try c++23 first, then c++2b if that fails
        "c++23"
    end
    
    # Try compilation with fallback for older compilers
    compile_cmd = `g++ -std=$cxx_std -shared -fPIC -o $lib_name 
                   test_generic_nested.cpp 
                   ../build/_deps/glaze-src/src/interop/interop.cpp
                   -I../build/_deps/glaze-src/include 
                   -DGLZ_EXPORTS`
    
    try
        run(compile_cmd)
    catch e
        # If c++23 failed, try c++2b (for older Clang)
        if cxx_std == "c++23"
            @warn "C++23 compilation failed, trying c++2b for older compiler support"
            compile_cmd_fallback = `g++ -std=c++2b -shared -fPIC -o $lib_name 
                                   test_generic_nested.cpp 
                                   ../build/_deps/glaze-src/src/interop/interop.cpp
                                   -I../build/_deps/glaze-src/include 
                                   -DGLZ_EXPORTS`
            run(compile_cmd_fallback)
        else
            rethrow(e)
        end
    end
    
    # Load the library
    lib = Glaze.load(lib_name)
    
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