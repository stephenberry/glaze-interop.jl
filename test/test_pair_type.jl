using Glaze
using Test
using Libdl

# Compile-only test to check std::pair type descriptor
println("Running std::pair type descriptor test...")

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

# Try to call findMinMax with a simple test
test_vec = [1.0, 2.0, 3.0]
println("Calling findMinMax with: ", test_vec)

try
    result = processor.findMinMax(test_vec)
    println("Result type: ", typeof(result))
    println("Result value: ", result)
    
    if result === nothing
        println("Function returned nothing - checking member info...")
        
        # Get member function directly
        findMinMax_func = processor.findMinMax
        println("Function object: ", findMinMax_func)
        println("Function member_info: ", findMinMax_func.member_info)
        
        # Check the type descriptor
        member = unsafe_load(findMinMax_func.member_info)
        if member.type != C_NULL
            type_desc = unsafe_load(Ptr{Glaze.ConcreteTypeDescriptor}(member.type))
            println("Member type index: ", type_desc.index)
            println("Type indices: FUNCTION=", Glaze.GLZ_TYPE_FUNCTION)
            
            if type_desc.index == Glaze.GLZ_TYPE_FUNCTION
                func_desc_ptr = member.type + fieldoffset(Glaze.ConcreteTypeDescriptor, 3)
                func_desc = unsafe_load(Ptr{Glaze.FunctionDesc}(func_desc_ptr))
                
                println("Return type ptr: ", func_desc.return_type)
                if func_desc.return_type != C_NULL
                    return_desc = unsafe_load(Ptr{Glaze.ConcreteTypeDescriptor}(func_desc.return_type))
                    println("Return type index: ", return_desc.index)
                    println("Expected indices: PRIMITIVE=", Glaze.GLZ_TYPE_PRIMITIVE, 
                            ", STRING=", Glaze.GLZ_TYPE_STRING,
                            ", VECTOR=", Glaze.GLZ_TYPE_VECTOR,
                            ", STRUCT=", Glaze.GLZ_TYPE_STRUCT,
                            ", MAP=", Glaze.GLZ_TYPE_MAP,
                            ", COMPLEX=", Glaze.GLZ_TYPE_COMPLEX,
                            ", OPTIONAL=", Glaze.GLZ_TYPE_OPTIONAL,
                            ", FUNCTION=", Glaze.GLZ_TYPE_FUNCTION)
                else
                    println("Return type is NULL!")
                end
            end
        end
    end
catch e
    println("Error: ", e)
    rethrow(e)
end