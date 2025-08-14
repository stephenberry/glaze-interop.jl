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

# List all registered types
println("Checking registered types...")
get_type_info = Libdl.dlsym(lib.handle, :glz_get_type_info)

# Try some known types
test_types = [
    "SimpleStruct",
    "VectorProcessor", 
    "std::pair<double, double>",
    "std::pair<double,double>",  # Without space
    "pair<double, double>",       # Without std::
]

for type_name in test_types
    type_info_ptr = ccall(get_type_info, Ptr{Glaze.ConcreteTypeInfo}, (Cstring,), type_name)
    if type_info_ptr != C_NULL
        println("✓ Found: $type_name")
        type_info = unsafe_load(type_info_ptr)
        println("  Members: $(type_info.member_count)")
    else
        println("✗ Not found: $type_name")
    end
end