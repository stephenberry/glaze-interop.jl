# Load Glaze module from parent directory
push!(LOAD_PATH, dirname(@__DIR__))
using Glaze
using Test
using Libdl

# Load the test library
test_dir = @__DIR__
build_dir = joinpath(test_dir, "build")
test_lib_path = joinpath(build_dir, Sys.iswindows() ? "test_lib.dll" : Sys.isapple() ? "libtest_lib.dylib" : "libtest_lib.so")

handle = Libdl.dlopen(test_lib_path)
init_func = Libdl.dlsym(handle, :init_test_types_complete)
ccall(init_func, Cvoid, ())

lib = Glaze.CppLibrary(test_lib_path)

# Get VectorProcessor
processor = lib.VectorProcessor

# Test findMinMax
test_vec = [3.5, -2.1, 8.7, 0.0, -5.5]
println("Input vector: ", test_vec)
println("Expected result: (-5.5, 8.7)")

# Call findMinMax
result = processor.findMinMax(test_vec)
println("Result: ", result)
println("Result type: ", typeof(result))

if result !== nothing
    println("Success! findMinMax returned: ", result)
    if result == (-5.5, 8.7)
        println("✓ Values match expected result")
    else
        println("✗ Values don't match expected result")
    end
else
    println("✗ findMinMax still returns nothing")
end

# Test with empty vector
empty_result = processor.findMinMax(Float64[])
println("\nEmpty vector result: ", empty_result)
println("Expected: (0.0, 0.0)")