#pragma once

#include <glaze/interop/interop.hpp>
#include <string>
#include <cmath>

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
};

// Class with static member function
struct MathUtils {
    double x = 1.0;
    double y = 2.0;
    
    double distance() const {
        return std::sqrt(x * x + y * y);
    }
    
    void scale(double factor) {
        x *= factor;
        y *= factor;
    }
    
    static double staticAdd(double a, double b) {
        return a + b;
    }
};

// Define glz::meta for Calculator
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
        "describe", &T::describe
    );
};

// Define glz::meta for MathUtils
template <>
struct glz::meta<MathUtils> {
    using T = MathUtils;
    static constexpr auto value = object(
        "x", &T::x,
        "y", &T::y,
        "distance", &T::distance,
        "scale", &T::scale
    );
};

// Global instances for testing
inline Calculator global_calculator{42.0};
inline MathUtils global_math_utils{3.0, 4.0};

// Registration function
inline void register_member_function_types() {
    glz::register_type<Calculator>("Calculator");
    glz::register_type<MathUtils>("MathUtils");
    
    // Register global instances
    glz::register_instance("global_calculator", global_calculator);
    glz::register_instance("global_math_utils", global_math_utils);
}

extern "C" {
    #ifdef _WIN32
        __declspec(dllexport)
    #else
        __attribute__((visibility("default")))
    #endif
    void init_member_function_types() {
        register_member_function_types();
    }
}