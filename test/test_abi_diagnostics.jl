# Diagnostic tests to identify potential ABI issues or memory corruption causes
# This file is included by runtests.jl, so lib is already defined

@testset "ABI Diagnostic Tests" begin
    # Check basic type sizes to ensure compatibility
    @testset "Type Size Compatibility" begin
        # Check that Julia and C++ agree on basic type sizes
        @test sizeof(Csize_t) == sizeof(UInt64) || sizeof(Csize_t) == sizeof(UInt32)
        @test sizeof(Ptr{Cvoid}) == sizeof(UInt64) || sizeof(Ptr{Cvoid}) == sizeof(UInt32)
        
        println("\n=== Type Size Information ===")
        println("Julia sizeof(Csize_t) = $(sizeof(Csize_t))")
        println("Julia sizeof(Ptr{Cvoid}) = $(sizeof(Ptr{Cvoid}))")
        println("Julia sizeof(Float32) = $(sizeof(Float32))")
        println("Julia sizeof(Float64) = $(sizeof(Float64))")
        println("Julia sizeof(Int32) = $(sizeof(Int32))")
        println("Julia sizeof(ComplexF32) = $(sizeof(ComplexF32))")
        
        # Check VectorView struct layout
        @test sizeof(Glaze.VectorView) == 3 * sizeof(Ptr{Cvoid})  # data + size + capacity
        println("Julia sizeof(VectorView) = $(sizeof(Glaze.VectorView))")
        println("Julia fieldoffsets(VectorView) = $(fieldoffset.((Glaze.VectorView,), 1:3))")
        
        # Check platform info
        println("\n=== Platform Information ===")
        println("Julia version: $(VERSION)")
        println("Word size: $(Sys.WORD_SIZE)")
        println("OS: $(Sys.KERNEL) ($(Sys.MACHINE))")
        println("CPU: $(Sys.CPU_NAME)")
    end
    
    @testset "Memory Pattern Tests" begin
        data = lib.LargeDataStruct
        vec = data.large_vector
        
        # Test 1: Resize to small size and check memory pattern
        println("\n=== Test 1: Small resize ===")
        resize!(vec, 10)
        
        # Fill with known pattern
        for i in 1:10
            vec[i] = Float32(i * 1.1)
        end
        
        # Get view and check data pointer
        view_func = Glaze.get_cached_function(vec.lib, :glz_vector_float32_view)
        view1 = ccall(view_func, Glaze.VectorView, (Ptr{Cvoid},), vec.ptr)
        
        println("After resize(10):")
        println("  view.data = $(view1.data) (0x$(string(UInt(view1.data), base=16)))")
        println("  view.size = $(view1.size)")
        println("  view.capacity = $(view1.capacity)")
        
        # Verify we can read the data
        errors = 0
        for i in 1:10
            val = unsafe_load(Ptr{Float32}(view1.data), i)
            expected = Float32(i * 1.1)
            if !(val ≈ expected)
                println("  ERROR: vec[$i] = $val, expected $expected")
                errors += 1
            end
        end
        @test errors == 0
        
        # Test 2: Resize to force reallocation
        println("\n=== Test 2: Large resize (force reallocation) ===")
        old_capacity = view1.capacity
        resize!(vec, 1000)
        
        view2 = ccall(view_func, Glaze.VectorView, (Ptr{Cvoid},), vec.ptr)
        println("After resize(1000):")
        println("  view.data = $(view2.data) (0x$(string(UInt(view2.data), base=16)))")
        println("  view.size = $(view2.size)")
        println("  view.capacity = $(view2.capacity)")
        println("  Data pointer changed: $(view1.data != view2.data)")
        println("  Capacity increased: $(view2.capacity >= 1000)")
        
        # Fill new data
        for i in 1:1000
            vec[i] = Float32(i * 0.01)
        end
        
        # Verify first 10 elements
        println("First 10 elements after resize and fill:")
        for i in 1:10
            val = unsafe_load(Ptr{Float32}(view2.data), i)
            println("  vec[$i] = $val")
        end
        
        # Test 3: Resize back down
        println("\n=== Test 3: Resize back down ===")
        resize!(vec, 50)
        view3 = ccall(view_func, Glaze.VectorView, (Ptr{Cvoid},), vec.ptr)
        
        println("After resize(50):")
        println("  view.data = $(view3.data) (0x$(string(UInt(view3.data), base=16)))")
        println("  view.size = $(view3.size)")
        println("  view.capacity = $(view3.capacity)")
        println("  Data pointer same as before: $(view2.data == view3.data)")
        
        # Verify we can still access elements
        access_errors = 0
        for i in 1:50
            try
                val = unsafe_load(Ptr{Float32}(view3.data), i)
                if isnan(val) || isinf(val)
                    println("  ERROR: vec[$i] is NaN or Inf")
                    access_errors += 1
                end
            catch e
                println("  ERROR accessing vec[$i]: $e")
                access_errors += 1
            end
        end
        @test access_errors == 0
    end
    
    @testset "Iterator Memory Safety" begin
        data = lib.LargeDataStruct
        vec = data.large_vector
        
        println("\n=== Iterator Memory Safety Test ===")
        
        # Resize and fill
        resize!(vec, 100)
        for i in 1:100
            vec[i] = Float32(i)
        end
        
        # Get initial view
        view_func = Glaze.get_cached_function(vec.lib, :glz_vector_float32_view)
        view_before = ccall(view_func, Glaze.VectorView, (Ptr{Cvoid},), vec.ptr)
        
        println("Before iteration:")
        println("  data pointer: $(view_before.data) (0x$(string(UInt(view_before.data), base=16)))")
        println("  size: $(view_before.size)")
        
        # Start iteration
        iter_state = iterate(vec)
        @test iter_state !== nothing
        val1, state1 = iter_state
        
        # Check what the iterator state looks like
        println("Iterator state type: $(typeof(state1))")
        if isa(state1, Tuple) && length(state1) >= 2
            iter_obj = state1[1]
            if isdefined(iter_obj, :data_ptr)
                println("  Iterator data_ptr: $(iter_obj.data_ptr) (0x$(string(UInt(iter_obj.data_ptr), base=16)))")
            end
            if isdefined(iter_obj, :size)
                println("  Iterator size: $(iter_obj.size)")
            end
        end
        
        # Get view during iteration
        view_during = ccall(view_func, Glaze.VectorView, (Ptr{Cvoid},), vec.ptr)
        println("During iteration (after first element):")
        println("  data pointer: $(view_during.data) (0x$(string(UInt(view_during.data), base=16)))")
        println("  size: $(view_during.size)")
        println("  Pointers match: $(view_before.data == view_during.data)")
        
        # Continue iteration for a few elements
        iter_errors = 0
        for i in 2:10
            iter_state = iterate(vec, state1)
            if iter_state === nothing
                println("  ERROR: Iterator ended early at element $i")
                iter_errors += 1
                break
            end
            val, state1 = iter_state
        end
        
        # Complete iteration
        count = 10
        while iter_state !== nothing
            iter_state = iterate(vec, state1)
            if iter_state !== nothing
                val, state1 = iter_state
                count += 1
            end
        end
        
        println("  Total elements iterated: $count")
        @test count == 100
        @test iter_errors == 0
    end
    
    @testset "Direct Memory Access Patterns" begin
        data = lib.LargeDataStruct
        vec = data.large_vector
        
        println("\n=== Direct Memory Access Test ===")
        
        # Test with size that previously caused issues
        n = 10000
        println("Resizing vector to $n elements...")
        resize!(vec, n)
        
        # Get view
        view_func = Glaze.get_cached_function(vec.lib, :glz_vector_float32_view)
        view = ccall(view_func, Glaze.VectorView, (Ptr{Cvoid},), vec.ptr)
        
        println("Vector with $n elements:")
        println("  size from view: $(view.size)")
        println("  capacity from view: $(view.capacity)")
        println("  size == n: $(view.size == n)")
        
        # Test writing pattern
        println("Writing test pattern...")
        write_errors = 0
        for i in 1:min(100, n)
            try
                vec[i] = Float32(i * 0.1)
            catch e
                write_errors += 1
                println("  ERROR writing at index $i: $e")
                break
            end
        end
        @test write_errors == 0
        
        # Test reading back through direct memory access
        println("Reading back through direct pointer access...")
        data_ptr = Ptr{Float32}(view.data)
        
        sum_direct = 0.0f0
        read_errors = 0
        for i in 1:min(100, n)
            try
                val = unsafe_load(data_ptr, i)
                expected = Float32(i * 0.1)
                if isnan(val) || isinf(val)
                    read_errors += 1
                    println("  ERROR at index $i: got NaN or Inf")
                elseif abs(val - expected) > 0.001
                    read_errors += 1
                    println("  ERROR at index $i: got $val, expected $expected")
                else
                    sum_direct += val
                end
            catch e
                read_errors += 1
                println("  ERROR at index $i: $(e)")
                println("  Stopping direct access test")
                break
            end
        end
        
        println("  Sum of first 100 elements (direct): $sum_direct")
        println("  Read errors encountered: $read_errors")
        @test read_errors == 0
        
        # Test iteration on large vector
        println("Testing iteration on large vector...")
        iter_sum = 0.0f0
        iter_count = 0
        iter_errors = 0
        
        try
            for val in vec
                if iter_count < 100
                    iter_sum += val
                end
                iter_count += 1
                if iter_count > n + 100  # Safety check
                    println("  ERROR: Iterator returned more than $n elements!")
                    iter_errors += 1
                    break
                end
            end
        catch e
            iter_errors += 1
            println("  ERROR during iteration at element $(iter_count + 1): $(e)")
            println("  Exception type: $(typeof(e))")
            
            # Try to get more diagnostic info
            if iter_count == 0
                println("  Failed on first iteration")
            else
                println("  Successfully iterated $iter_count elements before failure")
            end
        end
        
        println("  Iterated elements: $iter_count")
        println("  Sum from iteration (first 100): $iter_sum")
        println("  Iteration errors: $iter_errors")
        
        @test iter_count == n
        @test iter_errors == 0
        if read_errors == 0 && iter_errors == 0
            @test abs(iter_sum - sum_direct) < 0.001
        end
    end
    
    @testset "Memory Alignment Check" begin
        data = lib.LargeDataStruct
        vec = data.large_vector
        
        println("\n=== Memory Alignment Test ===")
        
        resize!(vec, 1000)
        view_func = Glaze.get_cached_function(vec.lib, :glz_vector_float32_view)
        view = ccall(view_func, Glaze.VectorView, (Ptr{Cvoid},), vec.ptr)
        
        # Check alignment of data pointer
        data_addr = UInt(view.data)
        println("Data pointer address: 0x$(string(data_addr, base=16))")
        println("  Aligned to 4 bytes (Float32): $(data_addr % 4 == 0)")
        println("  Aligned to 8 bytes: $(data_addr % 8 == 0)")
        println("  Aligned to 16 bytes: $(data_addr % 16 == 0)")
        println("  Aligned to 32 bytes: $(data_addr % 32 == 0)")
        println("  Aligned to 64 bytes: $(data_addr % 64 == 0)")
        
        # Most allocators align to at least sizeof(type)
        @test data_addr % sizeof(Float32) == 0
        
        # Check if pointer looks valid (not obviously corrupted)
        # On 64-bit systems, heap pointers typically have certain patterns
        if Sys.WORD_SIZE == 64
            # Check if pointer is in reasonable range (not kernel space, not null region)
            @test data_addr > 0x10000  # Not in first 64KB (null pointer region)
            @test data_addr < 0x0001000000000000  # Not in kernel space (varies by OS)
            println("  Pointer appears to be in valid heap range")
        end
    end
    
    @testset "Stress Test Small Resizes" begin
        data = lib.LargeDataStruct
        vec = data.large_vector
        
        println("\n=== Stress Test: Multiple Small Resizes ===")
        
        # Do many small resizes to see if we accumulate any corruption
        sizes = [10, 50, 20, 100, 30, 200, 40, 500, 10, 1000, 5]
        
        for (idx, size) in enumerate(sizes)
            resize!(vec, size)
            
            # Fill with pattern
            for i in 1:size
                vec[i] = Float32(idx + i * 0.01)
            end
            
            # Verify we can read back
            sum_val = 0.0f0
            errors = 0
            for i in 1:size
                try
                    val = vec[i]
                    if isnan(val) || isinf(val)
                        errors += 1
                    else
                        sum_val += val
                    end
                catch e
                    errors += 1
                    println("  Error at size=$size, index=$i: $e")
                    break
                end
            end
            
            if errors > 0
                println("  Resize #$idx to size $size: $errors errors")
            end
            @test errors == 0
        end
        
        println("  Completed $(length(sizes)) resize operations successfully")
    end
end

println("\n=== ABI Diagnostic Tests Complete ===")