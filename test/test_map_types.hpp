#pragma once

#include <glaze/interop/interop.hpp>
#include <string>
#include <unordered_map>
#include <cstdint>

// Test struct with unordered_map members
struct TestMapTypes {
    std::unordered_map<std::string, int32_t> string_to_int;
    std::unordered_map<std::string, double> string_to_double;
    std::unordered_map<int32_t, std::string> int_to_string;
    std::unordered_map<std::string, std::vector<float>> string_to_vec_float;
};

// Define glz::meta for the test struct
template <>
struct glz::meta<TestMapTypes> {
    using T = TestMapTypes;
    static constexpr auto value = object(
        "string_to_int", &T::string_to_int,
        "string_to_double", &T::string_to_double,
        "int_to_string", &T::int_to_string,
        "string_to_vec_float", &T::string_to_vec_float
    );
};

// Registration function
inline void register_map_test_types() {
    glz::register_type<TestMapTypes>("TestMapTypes");
}

extern "C" {
    #ifdef _WIN32
        __declspec(dllexport)
    #else
        __attribute__((visibility("default")))
    #endif
    void init_map_test_types() {
        register_map_test_types();
    }
}