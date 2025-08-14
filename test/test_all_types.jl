# This file is included from runtests.jl and uses the already loaded lib
@testset "All Types Tests" begin
    # Types are already initialized by runtests.jl via init_test_types_complete
    # No need to re-initialize here
    
    @testset "Integer Types" begin
        # Create instance
        obj = lib.TestIntegerTypes
        
        # Test initial values
        @test obj.i8_value == 0
        @test obj.i16_value == 0
        @test obj.i32_value == 0
        @test obj.i64_value == 0
        @test obj.u8_value == 0
        @test obj.u16_value == 0
        @test obj.u32_value == 0
        @test obj.u64_value == 0
        
        # Test setting values
        obj.i8_value = -128
        @test obj.i8_value == -128
        obj.i8_value = 127
        @test obj.i8_value == 127
        
        obj.i16_value = -32768
        @test obj.i16_value == -32768
        obj.i16_value = 32767
        @test obj.i16_value == 32767
        
        obj.i32_value = -2147483648
        @test obj.i32_value == -2147483648
        obj.i32_value = 2147483647
        @test obj.i32_value == 2147483647
        
        obj.i64_value = -9223372036854775808
        @test obj.i64_value == -9223372036854775808
        obj.i64_value = 9223372036854775807
        @test obj.i64_value == 9223372036854775807
        
        obj.u8_value = 0
        @test obj.u8_value == 0
        obj.u8_value = 255
        @test obj.u8_value == 255
        
        obj.u16_value = 0
        @test obj.u16_value == 0
        obj.u16_value = 65535
        @test obj.u16_value == 65535
        
        obj.u32_value = 0
        @test obj.u32_value == 0
        obj.u32_value = 4294967295
        @test obj.u32_value == 4294967295
        
        obj.u64_value = 0
        @test obj.u64_value == 0
        obj.u64_value = 18446744073709551615
        @test obj.u64_value == 18446744073709551615
    end
    
    @testset "Float Types" begin
        obj = lib.TestFloatTypes
        
        # Test initial values
        @test obj.f32_value == 0.0f0
        @test obj.f64_value == 0.0
        
        # Test setting values
        obj.f32_value = 3.14159f0
        @test obj.f32_value ≈ 3.14159f0
        
        obj.f64_value = 2.71828
        @test obj.f64_value ≈ 2.71828
        
        # Test special values
        obj.f32_value = Inf32
        @test isinf(obj.f32_value)
        
        obj.f32_value = -Inf32
        @test isinf(obj.f32_value) && obj.f32_value < 0
        
        obj.f64_value = Inf64
        @test isinf(obj.f64_value)
        
        obj.f64_value = -Inf64
        @test isinf(obj.f64_value) && obj.f64_value < 0
    end
    
    @testset "Basic Types" begin
        obj = lib.TestBasicTypes
        
        # Test bool
        @test obj.bool_value == false
        obj.bool_value = true
        @test obj.bool_value == true
        obj.bool_value = false
        @test obj.bool_value == false
        
        # Test string
        @test obj.string_value == ""
        obj.string_value[] = "Hello, World!"
        @test obj.string_value == "Hello, World!"
        
        obj.string_value[] = "Unicode: αβγδε 中文"
        @test obj.string_value == "Unicode: αβγδε 中文"
    end
    
    @testset "Integer Vector Types" begin
        obj = lib.TestIntegerVectors
        
        # Test vec_i8
        @test length(obj.vec_i8) == 0
        resize!(obj.vec_i8, 3)
        @test length(obj.vec_i8) == 3
        obj.vec_i8[1] = -128
        obj.vec_i8[2] = 0
        obj.vec_i8[3] = 127
        @test obj.vec_i8[1] == -128
        @test obj.vec_i8[2] == 0
        @test obj.vec_i8[3] == 127
        push!(obj.vec_i8, 100)
        @test length(obj.vec_i8) == 4
        @test obj.vec_i8[4] == 100
        
        # Test vec_i16
        resize!(obj.vec_i16, 2)
        obj.vec_i16[1] = -32768
        obj.vec_i16[2] = 32767
        @test obj.vec_i16[1] == -32768
        @test obj.vec_i16[2] == 32767
        
        # Test vec_i32
        resize!(obj.vec_i32, 2)
        obj.vec_i32[1] = typemin(Int32)
        obj.vec_i32[2] = typemax(Int32)
        @test obj.vec_i32[1] == typemin(Int32)
        @test obj.vec_i32[2] == typemax(Int32)
        
        # Test vec_i64
        resize!(obj.vec_i64, 2)
        obj.vec_i64[1] = typemin(Int64)
        obj.vec_i64[2] = typemax(Int64)
        @test obj.vec_i64[1] == typemin(Int64)
        @test obj.vec_i64[2] == typemax(Int64)
        
        # Test unsigned vectors
        resize!(obj.vec_u8, 2)
        obj.vec_u8[1] = 0
        obj.vec_u8[2] = 255
        @test obj.vec_u8[1] == 0
        @test obj.vec_u8[2] == 255
        
        resize!(obj.vec_u16, 2)
        obj.vec_u16[1] = 0
        obj.vec_u16[2] = 65535
        @test obj.vec_u16[1] == 0
        @test obj.vec_u16[2] == 65535
        
        resize!(obj.vec_u32, 2)
        obj.vec_u32[1] = 0
        obj.vec_u32[2] = typemax(UInt32)
        @test obj.vec_u32[1] == 0
        @test obj.vec_u32[2] == typemax(UInt32)
        
        resize!(obj.vec_u64, 2)
        obj.vec_u64[1] = 0
        obj.vec_u64[2] = typemax(UInt64)
        @test obj.vec_u64[1] == 0
        @test obj.vec_u64[2] == typemax(UInt64)
    end
    
    @testset "Float Vector Types" begin
        obj = lib.TestFloatVectors
        
        # Test vec_f32
        @test length(obj.vec_f32) == 0
        resize!(obj.vec_f32, 3)
        obj.vec_f32[1] = -1.0f0
        obj.vec_f32[2] = 0.0f0
        obj.vec_f32[3] = 1.0f0
        @test obj.vec_f32[1] == -1.0f0
        @test obj.vec_f32[2] == 0.0f0
        @test obj.vec_f32[3] == 1.0f0
        push!(obj.vec_f32, 3.14f0)
        @test obj.vec_f32[4] ≈ 3.14f0
        
        # Test vec_f64
        resize!(obj.vec_f64, 3)
        obj.vec_f64[1] = -1.0
        obj.vec_f64[2] = 0.0
        obj.vec_f64[3] = 1.0
        @test obj.vec_f64[1] == -1.0
        @test obj.vec_f64[2] == 0.0
        @test obj.vec_f64[3] == 1.0
        push!(obj.vec_f64, π)
        @test obj.vec_f64[4] ≈ π
        
        # Test vec_complex_f32
        resize!(obj.vec_complex_f32, 2)
        obj.vec_complex_f32[1] = 1.0f0 + 2.0f0im
        obj.vec_complex_f32[2] = -3.0f0 - 4.0f0im
        @test obj.vec_complex_f32[1] == 1.0f0 + 2.0f0im
        @test obj.vec_complex_f32[2] == -3.0f0 - 4.0f0im
        push!(obj.vec_complex_f32, 0.0f0 + 1.0f0im)
        @test obj.vec_complex_f32[3] == 0.0f0 + 1.0f0im
        
        # Test vec_complex_f64
        resize!(obj.vec_complex_f64, 2)
        obj.vec_complex_f64[1] = 1.0 + 2.0im
        obj.vec_complex_f64[2] = -3.0 - 4.0im
        @test obj.vec_complex_f64[1] == 1.0 + 2.0im
        @test obj.vec_complex_f64[2] == -3.0 - 4.0im
        push!(obj.vec_complex_f64, 0.0 + 1.0im)
        @test obj.vec_complex_f64[3] == 0.0 + 1.0im
    end
    
    @testset "Global Instances" begin
        # Test global integer instance
        global_int = Glaze.get_instance(lib, "global_integer_test")
        @test global_int.i8_value == -128
        @test global_int.u8_value == 255
        @test global_int.i16_value == -32768
        @test global_int.u16_value == 65535
        @test global_int.i32_value == typemin(Int32)
        @test global_int.u32_value == typemax(UInt32)
        @test global_int.i64_value == typemin(Int64)
        @test global_int.u64_value == typemax(UInt64)
        
        # Test global float instance
        global_float = Glaze.get_instance(lib, "global_float_test")
        @test global_float.f32_value ≈ 3.14159f0
        @test global_float.f64_value ≈ 2.71828
        
        # Test global basic instance
        global_basic = Glaze.get_instance(lib, "global_basic_test")
        @test global_basic.bool_value == true
        @test global_basic.string_value == "Hello, Glaze!"
        
        # Test global integer vectors
        global_int_vecs = Glaze.get_instance(lib, "global_int_vectors")
        @test length(global_int_vecs.vec_i8) == 5
        @test global_int_vecs.vec_i8[1] == -128
        @test global_int_vecs.vec_i8[5] == 127
        @test length(global_int_vecs.vec_u8) == 5
        @test global_int_vecs.vec_u8[1] == 0
        @test global_int_vecs.vec_u8[5] == 255
        
        # Test global float vectors
        global_float_vecs = Glaze.get_instance(lib, "global_float_vectors")
        @test length(global_float_vecs.vec_f32) == 5
        @test global_float_vecs.vec_f32[1] == -1.0f0
        @test global_float_vecs.vec_f32[4] ≈ 3.14f0
        @test length(global_float_vecs.vec_complex_f32) == 3
        @test global_float_vecs.vec_complex_f32[1] == 1.0f0 + 0.0f0im
        @test global_float_vecs.vec_complex_f32[2] == 0.0f0 + 1.0f0im
    end
    
    @testset "Complete Type Struct" begin
        obj = lib.TestAllTypesComplete
        
        # Test all integer types
        obj.i8 = -50
        @test obj.i8 == -50
        obj.i16 = -5000
        @test obj.i16 == -5000
        obj.i32 = -500000
        @test obj.i32 == -500000
        obj.i64 = -5000000000
        @test obj.i64 == -5000000000
        
        obj.u8 = 50
        @test obj.u8 == 50
        obj.u16 = 5000
        @test obj.u16 == 5000
        obj.u32 = 500000
        @test obj.u32 == 500000
        obj.u64 = 5000000000
        @test obj.u64 == 5000000000
        
        # Test float types
        obj.f32 = 1.23f0
        @test obj.f32 ≈ 1.23f0
        obj.f64 = 4.56
        @test obj.f64 ≈ 4.56
        
        # Test bool and string
        obj.bool_val = true
        @test obj.bool_val == true
        obj.str[] = "Complete test"
        @test obj.str == "Complete test"
        
        # Test some vectors
        resize!(obj.vec_i32, 3)
        obj.vec_i32[1] = -1
        obj.vec_i32[2] = 0
        obj.vec_i32[3] = 1
        @test obj.vec_i32[1] == -1
        @test obj.vec_i32[2] == 0
        @test obj.vec_i32[3] == 1
        
        resize!(obj.vec_f64, 2)
        obj.vec_f64[1] = 1.414
        obj.vec_f64[2] = 1.732
        @test obj.vec_f64[1] ≈ 1.414
        @test obj.vec_f64[2] ≈ 1.732
    end
end