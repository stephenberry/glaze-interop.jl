#include "test_all_types.hpp"

// Global instances for testing with initial values
// Use static to ensure proper initialization order
static TestIntegerTypes global_integer_test{
    -128,    // i8_value
    -32768,  // i16_value  
    -2147483648, // i32_value
    -9223372036854775807LL - 1, // i64_value
    255,     // u8_value
    65535,   // u16_value
    4294967295U, // u32_value
    18446744073709551615ULL // u64_value
};

static TestFloatTypes global_float_test{
    3.14159f,    // f32_value
    2.71828      // f64_value
};

static TestBasicTypes global_basic_test{
    true,                // bool_value
    "Hello, Glaze!"      // string_value
};

static TestIntegerVectors global_int_vectors{
    {-128, -1, 0, 1, 127},         // vec_i8
    {-32768, -1, 0, 1, 32767},     // vec_i16
    {-100, -50, 0, 50, 100},        // vec_i32
    {-1000LL, -500LL, 0LL, 500LL, 1000LL}, // vec_i64
    {0, 1, 128, 254, 255},          // vec_u8
    {0, 1, 32768, 65534, 65535},    // vec_u16
    {0U, 1U, 100000U, 4294967294U}, // vec_u32
    {0ULL, 1ULL, 1000000ULL, 18446744073709551614ULL} // vec_u64
};

static TestFloatVectors global_float_vectors{
    {-1.0f, 0.0f, 1.0f, 3.14f, 2.71f},    // vec_f32
    {-1.0, 0.0, 1.0, 3.14159, 2.71828},   // vec_f64
    {{1.0f, 0.0f}, {0.0f, 1.0f}, {-1.0f, 0.0f}}, // vec_complex_f32
    {{1.0, 0.0}, {0.0, 1.0}, {-1.0, 0.0}}  // vec_complex_f64
};

// Register global instances
inline void register_all_test_instances() {
    glz::register_instance("global_integer_test", global_integer_test);
    glz::register_instance("global_float_test", global_float_test);
    glz::register_instance("global_basic_test", global_basic_test);
    glz::register_instance("global_int_vectors", global_int_vectors);
    glz::register_instance("global_float_vectors", global_float_vectors);
}

extern "C" {
    #ifdef _WIN32
        __declspec(dllexport)
    #else
        __attribute__((visibility("default")))
    #endif
    void init_all_test_types() {
        register_all_test_types();
    }
    
    #ifdef _WIN32
        __declspec(dllexport)
    #else
        __attribute__((visibility("default")))
    #endif
    void init_all_test_instances() {
        register_all_test_instances();
    }
}