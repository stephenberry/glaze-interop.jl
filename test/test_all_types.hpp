#pragma once

#include <glaze/interop/interop.hpp>
#include <string>
#include <string_view>
#include <vector>
#include <complex>
#include <cstdint>

// Test struct with all integer types
struct TestIntegerTypes {
    int8_t i8_value;
    int16_t i16_value;
    int32_t i32_value;
    int64_t i64_value;
    uint8_t u8_value;
    uint16_t u16_value;
    uint32_t u32_value;
    uint64_t u64_value;
};

// Test struct with floating point types
struct TestFloatTypes {
    float f32_value;
    double f64_value;
};

// Test struct with basic types
struct TestBasicTypes {
    bool bool_value;
    std::string string_value;
    // Note: std::string_view requires special handling as it doesn't own data
};

// Test struct with all vector types for integers
struct TestIntegerVectors {
    std::vector<int8_t> vec_i8;
    std::vector<int16_t> vec_i16;
    std::vector<int32_t> vec_i32;
    std::vector<int64_t> vec_i64;
    std::vector<uint8_t> vec_u8;
    std::vector<uint16_t> vec_u16;
    std::vector<uint32_t> vec_u32;
    std::vector<uint64_t> vec_u64;
};

// Test struct with floating point vectors
struct TestFloatVectors {
    std::vector<float> vec_f32;
    std::vector<double> vec_f64;
    std::vector<std::complex<float>> vec_complex_f32;
    std::vector<std::complex<double>> vec_complex_f64;
};

// Combined test struct with all types
struct TestAllTypesComplete {
    // Integer types
    int8_t i8;
    int16_t i16;
    int32_t i32;
    int64_t i64;
    uint8_t u8;
    uint16_t u16;
    uint32_t u32;
    uint64_t u64;
    
    // Floating point types
    float f32;
    double f64;
    
    // Other basic types
    bool bool_val;
    std::string str;
    
    // Vector types
    std::vector<int8_t> vec_i8;
    std::vector<int16_t> vec_i16;
    std::vector<int32_t> vec_i32;
    std::vector<int64_t> vec_i64;
    std::vector<uint8_t> vec_u8;
    std::vector<uint16_t> vec_u16;
    std::vector<uint32_t> vec_u32;
    std::vector<uint64_t> vec_u64;
    std::vector<float> vec_f32;
    std::vector<double> vec_f64;
    std::vector<std::complex<float>> vec_complex_f32;
    std::vector<std::complex<double>> vec_complex_f64;
};

// Define glz::meta for all test structs
template <>
struct glz::meta<TestIntegerTypes> {
    using T = TestIntegerTypes;
    static constexpr auto value = object(
        "i8_value", &T::i8_value,
        "i16_value", &T::i16_value,
        "i32_value", &T::i32_value,
        "i64_value", &T::i64_value,
        "u8_value", &T::u8_value,
        "u16_value", &T::u16_value,
        "u32_value", &T::u32_value,
        "u64_value", &T::u64_value
    );
};

template <>
struct glz::meta<TestFloatTypes> {
    using T = TestFloatTypes;
    static constexpr auto value = object(
        "f32_value", &T::f32_value,
        "f64_value", &T::f64_value
    );
};

template <>
struct glz::meta<TestBasicTypes> {
    using T = TestBasicTypes;
    static constexpr auto value = object(
        "bool_value", &T::bool_value,
        "string_value", &T::string_value
    );
};

template <>
struct glz::meta<TestIntegerVectors> {
    using T = TestIntegerVectors;
    static constexpr auto value = object(
        "vec_i8", &T::vec_i8,
        "vec_i16", &T::vec_i16,
        "vec_i32", &T::vec_i32,
        "vec_i64", &T::vec_i64,
        "vec_u8", &T::vec_u8,
        "vec_u16", &T::vec_u16,
        "vec_u32", &T::vec_u32,
        "vec_u64", &T::vec_u64
    );
};

template <>
struct glz::meta<TestFloatVectors> {
    using T = TestFloatVectors;
    static constexpr auto value = object(
        "vec_f32", &T::vec_f32,
        "vec_f64", &T::vec_f64,
        "vec_complex_f32", &T::vec_complex_f32,
        "vec_complex_f64", &T::vec_complex_f64
    );
};

template <>
struct glz::meta<TestAllTypesComplete> {
    using T = TestAllTypesComplete;
    static constexpr auto value = object(
        "i8", &T::i8,
        "i16", &T::i16,
        "i32", &T::i32,
        "i64", &T::i64,
        "u8", &T::u8,
        "u16", &T::u16,
        "u32", &T::u32,
        "u64", &T::u64,
        "f32", &T::f32,
        "f64", &T::f64,
        "bool_val", &T::bool_val,
        "str", &T::str,
        "vec_i8", &T::vec_i8,
        "vec_i16", &T::vec_i16,
        "vec_i32", &T::vec_i32,
        "vec_i64", &T::vec_i64,
        "vec_u8", &T::vec_u8,
        "vec_u16", &T::vec_u16,
        "vec_u32", &T::vec_u32,
        "vec_u64", &T::vec_u64,
        "vec_f32", &T::vec_f32,
        "vec_f64", &T::vec_f64,
        "vec_complex_f32", &T::vec_complex_f32,
        "vec_complex_f64", &T::vec_complex_f64
    );
};


// Registration function
inline void register_all_test_types() {
    glz::register_type<TestIntegerTypes>("TestIntegerTypes");
    glz::register_type<TestFloatTypes>("TestFloatTypes");
    glz::register_type<TestBasicTypes>("TestBasicTypes");
    glz::register_type<TestIntegerVectors>("TestIntegerVectors");
    glz::register_type<TestFloatVectors>("TestFloatVectors");
    glz::register_type<TestAllTypesComplete>("TestAllTypesComplete");
}

// Declaration only - implementation in test_all_types.cpp
extern "C" void init_all_test_types();