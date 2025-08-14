#pragma once

#include <glaze/interop/interop.hpp>
#include <string>
#include <vector>
#include <complex>
#include <optional>
#include <cstddef>
#include <cmath>
#include "test_vector_member_functions.hpp"

// Address struct for nested testing
struct Address {
    std::string street;
    std::string city;
    int zipcode;
};

// Person struct for construction and assignment testing
struct Person {
    std::string name;
    int age;
    Address address;
    std::vector<int> scores;
};

// Test struct with all supported types
struct TestAllTypes {
    int int_value;
    float float_value;
    bool bool_value;
    std::string string_value;
    std::vector<float> float_vector;
    std::vector<std::complex<float>> complex_vector;
};

// Test struct for edge cases
struct EdgeCaseStruct {
    std::string empty_string;
    std::vector<float> empty_vector;
    int zero_int;
    float zero_float;
    bool false_bool;
};

// Test struct for large data
struct LargeDataStruct {
    std::vector<float> large_vector;
    std::string long_string;
    std::vector<std::complex<float>> complex_data;
};

// Test struct with optional fields
struct OptionalTestStruct {
    std::optional<int> opt_int;
    std::optional<std::string> opt_string;
    std::optional<float> opt_float;
    std::optional<bool> opt_bool;
    std::string required_field;
};

// Test struct with nested optional structs
struct OptionalNestedStruct {
    std::optional<Address> opt_address;
    std::string name;
    std::optional<std::vector<int>> opt_scores;
};

// Simple calculator class to test member functions
struct Calculator {
    double value = 0.0;
    
    // Member functions with different signatures
    double add(double x) {
        value += x;
        return value;
    }
    
    double multiply(double x) {
        value *= x;
        return value;
    }
    
    void reset() {
        value = 0.0;
    }
    
    double getValue() const {
        return value;
    }
    
    void setValue(double v) {
        value = v;
    }
    
    // Function that takes multiple parameters
    double compute(double a, double b, double c) {
        return a * value + b * value + c;
    }
    
    // Function that returns a string
    std::string describe() const {
        return "Calculator with value: " + std::to_string(value);
    }
    
    // Additional functions for comprehensive testing
    
    // Function returning bool
    bool isPositive() const {
        return value > 0.0;
    }
    
    // Function returning bool with parameter
    bool isGreaterThan(double threshold) const {
        return value > threshold;
    }
    
    // Function with integer parameters and return
    int toInt() const {
        return static_cast<int>(value);
    }
    
    // Function with float parameters
    float addFloat(float x) {
        value += static_cast<double>(x);
        return static_cast<float>(value);
    }
    
    // Function with no parameters returning different types
    double getSquare() const {
        return value * value;
    }
    
    // Function that takes boolean parameter
    void setSign(bool positive) {
        if (positive) {
            value = std::abs(value);
        } else {
            value = -std::abs(value);
        }
    }
    
    // Function with mixed parameter types
    double complexOperation(int multiplier, float offset, bool negate) {
        double result = value * multiplier + offset;
        if (negate) result = -result;
        value = result;
        return result;
    }
    
    // Function that returns zero (edge case)
    double getZero() const {
        return 0.0;
    }
    
    // Function that modifies but doesn't return the modified value
    void increment() {
        value += 1.0;
    }
    
    // Function that takes the same type it returns
    double doubleOperation(double input) {
        double result = input * 2.0;
        value = result;
        return result;
    }
};

// Since the Glaze auto-registration is complex, let's use a hybrid approach
// Define glz::meta for serialization purposes if needed

// Address struct meta
template <>
struct glz::meta<Address> {
    using T = Address;
    static constexpr auto value = object(
        "street", &T::street,
        "city", &T::city,
        "zipcode", &T::zipcode
    );
};

// Person struct meta
template <>
struct glz::meta<Person> {
    using T = Person;
    static constexpr auto value = object(
        "name", &T::name,
        "age", &T::age,
        "address", &T::address,
        "scores", &T::scores
    );
};

template <>
struct glz::meta<TestAllTypes> {
    using T = TestAllTypes;
    static constexpr auto value = object(
        "int_value", &T::int_value,
        "float_value", &T::float_value,
        "bool_value", &T::bool_value,
        "string_value", &T::string_value,
        "float_vector", &T::float_vector,
        "complex_vector", &T::complex_vector
    );
};

template <>
struct glz::meta<EdgeCaseStruct> {
    using T = EdgeCaseStruct;
    static constexpr auto value = object(
        "empty_string", &T::empty_string,
        "empty_vector", &T::empty_vector,
        "zero_int", &T::zero_int,
        "zero_float", &T::zero_float,
        "false_bool", &T::false_bool
    );
};

template <>
struct glz::meta<LargeDataStruct> {
    using T = LargeDataStruct;
    static constexpr auto value = object(
        "large_vector", &T::large_vector,
        "long_string", &T::long_string,
        "complex_data", &T::complex_data
    );
};

template <>
struct glz::meta<OptionalTestStruct> {
    using T = OptionalTestStruct;
    static constexpr auto value = object(
        "opt_int", &T::opt_int,
        "opt_string", &T::opt_string,
        "opt_float", &T::opt_float,
        "opt_bool", &T::opt_bool,
        "required_field", &T::required_field
    );
};

template <>
struct glz::meta<OptionalNestedStruct> {
    using T = OptionalNestedStruct;
    static constexpr auto value = object(
        "opt_address", &T::opt_address,
        "name", &T::name,
        "opt_scores", &T::opt_scores
    );
};

// Define glz::meta for Calculator - including member functions
template <>
struct glz::meta<Calculator> {
    using T = Calculator;
    static constexpr auto value = object(
        "value", &T::value,
        "add", &T::add,
        "multiply", &T::multiply,
        "reset", &T::reset,
        "getValue", &T::getValue,
        "setValue", &T::setValue,
        "compute", &T::compute,
        "describe", &T::describe,
        "isPositive", &T::isPositive,
        "isGreaterThan", &T::isGreaterThan,
        "toInt", &T::toInt,
        "addFloat", &T::addFloat,
        "getSquare", &T::getSquare,
        "setSign", &T::setSign,
        "complexOperation", &T::complexOperation,
        "getZero", &T::getZero,
        "increment", &T::increment,
        "doubleOperation", &T::doubleOperation
    );
};

// Global instances for testing
inline TestAllTypes global_test_instance{
    42,                        // int_value
    3.14f,                     // float_value
    true,                      // bool_value
    "Global test string",      // string_value
    {1.0f, 2.0f, 3.0f},       // float_vector
    {{1.0f, 1.0f}, {2.0f, -1.0f}} // complex_vector
};

inline EdgeCaseStruct global_edge_case{
    "",                        // empty_string
    {},                        // empty_vector
    0,                         // zero_int
    0.0f,                      // zero_float
    false                      // false_bool
};

// Global Person instance for testing
inline Person global_person{
    "John Doe",                                    // name
    30,                                           // age
    {"123 Main St", "New York", 10001},          // address
    {95, 87, 92}                                 // scores
};

// Global Person instance for assignment testing (initially empty)
inline Person global_person_target{
    "",                                          // name
    0,                                           // age
    {"", "", 0},                                 // address
    {}                                           // scores
};

// Global OptionalTestStruct instances for testing
inline OptionalTestStruct global_optional_with_values{
    42,                                          // opt_int has value
    std::string("test string"),                  // opt_string has value
    3.14f,                                       // opt_float has value
    true,                                        // opt_bool has value
    "required field value"                       // required_field
};

inline OptionalTestStruct global_optional_empty{
    std::nullopt,                                // opt_int is empty
    std::nullopt,                                // opt_string is empty
    std::nullopt,                                // opt_float is empty
    std::nullopt,                                // opt_bool is empty
    "only required field"                        // required_field
};

// Global OptionalNestedStruct instances for testing
inline OptionalNestedStruct global_optional_nested_with_values{
    Address{"456 Optional St", "Optional City", 54321}, // opt_address has value
    "Nested Test",                               // name
    std::vector<int>{10, 20, 30}                // opt_scores has value
};

inline OptionalNestedStruct global_optional_nested_empty{
    std::nullopt,                                // opt_address is empty
    "Empty Nested Test",                         // name
    std::nullopt                                 // opt_scores is empty
};

// Global Calculator instance for testing
inline Calculator global_calculator{42.0};

// Global VectorProcessor instance for testing
inline VectorProcessor global_vector_processor{2.0};  // scale_factor = 2.0

// Global VectorEdgeCases instance for testing  
inline VectorEdgeCases global_vector_edge_cases;

// Manual function invokers are no longer needed!
// The MemberFunctionAccessor template automatically generates
// type-erased invoker functions at compile time.

// Registration function using automatic extraction from glz::meta
inline void register_test_types() {
    // Register all types using glz::meta automatically
    glz::register_type<Address>("Address");
    glz::register_type<Person>("Person");
    glz::register_type<TestAllTypes>("TestAllTypes");
    glz::register_type<EdgeCaseStruct>("EdgeCaseStruct");
    glz::register_type<LargeDataStruct>("LargeDataStruct");
    glz::register_type<OptionalTestStruct>("OptionalTestStruct");
    glz::register_type<OptionalNestedStruct>("OptionalNestedStruct");
    glz::register_type<Calculator>("Calculator");
    glz::register_type<VectorProcessor>("VectorProcessor");
    glz::register_type<VectorEdgeCases>("VectorEdgeCases");
    
    // Register global instances
    glz::register_instance("global_person", global_person);
    glz::register_instance("global_person_target", global_person_target);
    glz::register_instance("global_test", global_test_instance);
    glz::register_instance("global_edge", global_edge_case);
    glz::register_instance("global_optional_with_values", global_optional_with_values);
    glz::register_instance("global_optional_empty", global_optional_empty);
    glz::register_instance("global_optional_nested_with_values", global_optional_nested_with_values);
    glz::register_instance("global_optional_nested_empty", global_optional_nested_empty);
    glz::register_instance("global_calculator", global_calculator);
    glz::register_instance("global_vector_processor", global_vector_processor);
    glz::register_instance("global_vector_edge_cases", global_vector_edge_cases);
    
    // Function invokers are automatically generated by the MemberFunctionAccessor template!
    // No manual registration needed - just having the functions in glz::meta is enough.
}

extern "C" {
    #ifdef _WIN32
        __declspec(dllexport)
    #else
        __attribute__((visibility("default")))
    #endif
    void init_test_types() {
        register_test_types();
    }
}