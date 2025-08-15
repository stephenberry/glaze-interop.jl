# Focused diagnostic test to identify the exact point of corruption
# This test specifically targets the issue seen in test_iteration_performance.jl

# For standalone testing
if !@isdefined(Test)
    using Test
    using Glaze
    using Libdl
    
    test_lib_path = joinpath(@__DIR__, "build", Sys.isapple() ? "libtest_lib.dylib" : "libtest_lib.so")
    const lib = Glaze.CppLibrary(test_lib_path)
    const init_func = Libdl.dlsym(lib.handle, :init_test_types_complete)
    ccall(init_func, Cvoid, ())
end

@testset "Vector Corruption Diagnostic" begin
    println("\n=== Vector Corruption Diagnostic ===")
    
    # Use LargeDataStruct like in the failing test
    data = lib.LargeDataStruct
    vec = data.large_vector
    
    # Helper function to check vector state
    function check_vector_state(vec, label)
        view_func = Glaze.get_cached_function(vec.lib, :glz_vector_float32_view)
        view = ccall(view_func, Glaze.VectorView, (Ptr{Cvoid},), vec.ptr)
        
        println("\n$label:")
        println("  vec.ptr = $(vec.ptr) (0x$(string(UInt(vec.ptr), base=16)))")
        println("  view.data = $(view.data) (0x$(string(UInt(view.data), base=16)))")
        println("  view.size = $(view.size) (0x$(string(view.size, base=16)))")
        println("  view.capacity = $(view.capacity) (0x$(string(view.capacity, base=16)))")
        
        # Check if size looks corrupted
        if view.size > 1_000_000_000
            println("  WARNING: Size appears corrupted!")
            # Try to interpret as signed
            signed_size = reinterpret(Int64, view.size)
            println("  As signed int64: $signed_size")
        end
        
        return view
    end
    
    # Step 1: Initial resize
    println("\nStep 1: Resize to 100")
    resize!(vec, 100)
    view1 = check_vector_state(vec, "After resize(100)")
    @test view1.size == 100
    
    # Step 2: Fill with data
    println("\nStep 2: Fill with test data")
    for i in 1:100
        vec[i] = Float32(i * 0.5)
    end
    view2 = check_vector_state(vec, "After filling")
    @test view2.size == 100
    
    # Step 3: Test iteration
    println("\nStep 3: Test iteration")
    sum_iter = 0.0f0
    count = 0
    for val in vec
        sum_iter += val
        count += 1
    end
    println("  Iterated $count elements, sum = $sum_iter")
    view3 = check_vector_state(vec, "After iteration")
    @test count == 100
    @test view3.size == 100
    
    # Step 4: Test Julia's sum function (this is where it fails)
    println("\nStep 4: Test Julia's sum function")
    view4a = check_vector_state(vec, "Before sum()")
    
    # Try to call sum and catch any errors
    try
        result = sum(vec)
        println("  sum(vec) = $result")
        view4b = check_vector_state(vec, "After successful sum()")
    catch e
        println("  ERROR in sum(): $e")
        view4b = check_vector_state(vec, "After failed sum()")
        
        # Try to understand what went wrong
        if occursin("Vector size", string(e))
            println("\n  Detailed error analysis:")
            println("  Exception type: $(typeof(e))")
            
            # Try to get the length directly
            try
                len = length(vec)
                println("  length(vec) returned: $len")
            catch e2
                println("  length(vec) also failed: $e2")
            end
            
            # Check if we can still iterate
            try
                iter_count = 0
                for _ in vec
                    iter_count += 1
                    if iter_count > 200
                        println("  Iteration still works but stopping at 200 for safety")
                        break
                    end
                end
                println("  Can still iterate: counted $iter_count elements")
            catch e3
                println("  Iteration now fails: $e3")
            end
        end
    end
    
    # Step 5: Test with comprehension (this also failed in the original test)
    println("\nStep 5: Test comprehension")
    view5a = check_vector_state(vec, "Before comprehension")
    
    try
        filtered = [x for x in vec if x > 25.0f0]
        println("  Comprehension succeeded, got $(length(filtered)) elements")
        view5b = check_vector_state(vec, "After successful comprehension")
    catch e
        println("  ERROR in comprehension: $e")
        view5b = check_vector_state(vec, "After failed comprehension")
    end
    
    # Step 6: Try to understand if this is specific to LargeDataStruct
    println("\nStep 6: Test with different struct")
    data2 = lib.TestAllTypes
    vec2 = data2.float_vector
    
    resize!(vec2, 50)
    for i in 1:50
        vec2[i] = Float32(i)
    end
    
    view6 = check_vector_state(vec2, "TestAllTypes.float_vector after setup")
    
    try
        result2 = sum(vec2)
        println("  sum(vec2) = $result2 (SUCCESS)")
    catch e
        println("  ERROR: sum(vec2) also failed: $e")
    end
    
    # Step 7: Check if the issue is with the specific vector instance
    println("\nStep 7: Re-check original vector")
    view7 = check_vector_state(vec, "Final check of original vector")
    
    # Try to manually check memory around the vector
    println("\nStep 8: Memory inspection")
    println("  vec object fields:")
    println("    ptr: $(vec.ptr)")
    println("    lib: $(vec.lib)")
    println("  Type of vec: $(typeof(vec))")
    
    # Check if creating a new reference helps
    println("\nStep 9: Create new reference to same vector")
    data_new = lib.LargeDataStruct
    vec_new = data_new.large_vector
    view9 = check_vector_state(vec_new, "New reference to same vector")
    
    println("\n=== End of Vector Corruption Diagnostic ===")
end