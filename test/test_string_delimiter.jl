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

# Test joinStrings
strings = ["Hello", "World", "from", "Julia"]
println("Input strings: ", strings)

# Try with space delimiter
result = processor.joinStrings(strings, " ")
println("Result with ' ' delimiter: '", result, "'")
println("Expected: 'Hello World from Julia'")

# Try with comma delimiter
result2 = processor.joinStrings(strings, ", ")
println("\nResult with ', ' delimiter: '", result2, "'")
println("Expected: 'Hello, World, from, Julia'")

# Check the function object
joinStrings_func = processor.joinStrings
member = unsafe_load(joinStrings_func.member_info)
if member.type != C_NULL
    type_desc = unsafe_load(Ptr{Glaze.ConcreteTypeDescriptor}(member.type))
    if type_desc.index == Glaze.GLZ_TYPE_FUNCTION
        func_desc_ptr = member.type + fieldoffset(Glaze.ConcreteTypeDescriptor, 3)
        func_desc = unsafe_load(Ptr{Glaze.FunctionDesc}(func_desc_ptr))
        println("\nFunction has ", func_desc.param_count, " parameters")
        
        # Check parameter types
        if func_desc.param_count > 0 && func_desc.param_types != C_NULL
            param_ptrs = unsafe_wrap(Array, func_desc.param_types, func_desc.param_count)
            for (i, param_ptr) in enumerate(param_ptrs)
                if param_ptr != C_NULL
                    param_desc = unsafe_load(Ptr{Glaze.ConcreteTypeDescriptor}(param_ptr))
                    println("Parameter ", i, " type index: ", param_desc.index)
                end
            end
        end
    end
end