push!(LOAD_PATH, dirname(@__DIR__))
using Glaze
using Libdl

# Load the test library
test_dir = @__DIR__
build_dir = joinpath(test_dir, "build")
test_lib_path = joinpath(build_dir, Sys.iswindows() ? "test_lib.dll" : Sys.isapple() ? "libtest_lib.dylib" : "libtest_lib.so")

handle = Libdl.dlopen(test_lib_path)
init_func = Libdl.dlsym(handle, :init_test_types_complete)
ccall(init_func, Cvoid, ())

lib = Glaze.CppLibrary(test_lib_path)

# Get the test instance
future_test = get_instance(lib, "global_future_test")

println("Got future_test: ", future_test)

# Try calling getReadyFuture
println("\nCalling getReadyFuture(42)...")
try
    value_to_pass = Int32(42)
    println("Passing value: ", value_to_pass, " (type: ", typeof(value_to_pass), ")")
    future = future_test.getReadyFuture(value_to_pass)
    println("Got future: ", future)
    println("Is valid: ", isvalid(future))
    println("Is ready: ", isready(future))
    
    if isvalid(future) && isready(future)
        println("Getting value...")
        value = get(future)
        println("Value: ", value)
        println("Type: ", typeof(value))
    end
catch e
    println("Error: ", e)
    showerror(stdout, e, catch_backtrace())
end