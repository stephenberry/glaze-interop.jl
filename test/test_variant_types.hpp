#pragma once

#include <glaze/interop/interop.hpp>
#include <variant>
#include <string>
#include <vector>
#include <complex>
#include <optional>
#include <cstdint>

// Test structs to use in variants
struct Point2D {
    float x = 0.0f;
    float y = 0.0f;
    
    Point2D() = default;
    Point2D(float x_, float y_) : x(x_), y(y_) {}
    
    bool operator==(const Point2D& other) const {
        return x == other.x && y == other.y;
    }
};

struct Point3D {
    float x = 0.0f;
    float y = 0.0f;
    float z = 0.0f;
    
    Point3D() = default;
    Point3D(float x_, float y_, float z_) : x(x_), y(y_), z(z_) {}
    
    bool operator==(const Point3D& other) const {
        return x == other.x && y == other.y && z == other.z;
    }
};

struct Color {
    uint8_t r = 0;
    uint8_t g = 0;
    uint8_t b = 0;
    uint8_t a = 255;
    
    Color() = default;
    Color(uint8_t r_, uint8_t g_, uint8_t b_, uint8_t a_ = 255) : r(r_), g(g_), b(b_), a(a_) {}
    
    bool operator==(const Color& other) const {
        return r == other.r && g == other.g && b == other.b && a == other.a;
    }
};

struct Vehicle {
    std::string name;
    int wheels = 4;
    double max_speed = 0.0;
    
    Vehicle() = default;
    Vehicle(const std::string& name_, int wheels_, double speed_) 
        : name(name_), wheels(wheels_), max_speed(speed_) {}
    
    bool operator==(const Vehicle& other) const {
        return name == other.name && wheels == other.wheels && max_speed == other.max_speed;
    }
};

// Variant test types  
using SimpleVariant = std::variant<int, std::string, double>;
using GeometryVariant = std::variant<Point2D, Point3D, Color>;
using MixedVariant = std::variant<int, Point2D, std::string, Vehicle>;
using ComplexVariant = std::variant<
    int32_t,
    float,
    std::string,
    std::vector<int>,
    Point2D,
    Point3D,
    std::complex<float>
>;

// Test struct containing variants
struct VariantContainer {
    SimpleVariant simple_var;
    GeometryVariant geometry_var;
    MixedVariant mixed_var;
    ComplexVariant complex_var;
    std::optional<SimpleVariant> optional_var;
    
    // Constructor for easy initialization
    VariantContainer() {
        simple_var = 42;
        geometry_var = Point2D(1.0f, 2.0f);
        mixed_var = std::string("test");
        complex_var = Point2D(3.0f, 4.0f);
        optional_var = std::string("optional_content");
    }
    
    // Methods to manipulate variants
    void set_simple_to_int(int val) { simple_var = val; }
    void set_simple_to_double(double val) { simple_var = val; }
    void set_simple_to_string(const std::string& val) { simple_var = val; }
    
    int get_simple_index() const { return static_cast<int>(simple_var.index()); }
    int get_geometry_index() const { return static_cast<int>(geometry_var.index()); }
    int get_mixed_index() const { return static_cast<int>(mixed_var.index()); }
    int get_complex_index() const { return static_cast<int>(complex_var.index()); }
    
    // Set geometry variants
    void set_geometry_to_point2d(float x, float y) { geometry_var = Point2D(x, y); }
    void set_geometry_to_point3d(float x, float y, float z) { geometry_var = Point3D(x, y, z); }
    void set_geometry_to_color(uint8_t r, uint8_t g, uint8_t b, uint8_t a = 255) { 
        geometry_var = Color(r, g, b, a); 
    }
    
    // Set mixed variants
    void set_mixed_to_int(int val) { mixed_var = val; }
    void set_mixed_to_point2d(float x, float y) { mixed_var = Point2D(x, y); }
    void set_mixed_to_string(const std::string& val) { mixed_var = val; }
    void set_mixed_to_vehicle(const std::string& name, int wheels, double speed) {
        mixed_var = Vehicle(name, wheels, speed);
    }
    
    // Test variant with return value
    SimpleVariant get_simple_variant() const { return simple_var; }
    GeometryVariant get_geometry_variant() const { return geometry_var; }
    
    // Test variant parameter
    void set_simple_variant(const SimpleVariant& var) { simple_var = var; }
    void set_geometry_variant(const GeometryVariant& var) { geometry_var = var; }
    
    // Test optional variant
    bool has_optional_variant() const { return optional_var.has_value(); }
    void clear_optional_variant() { optional_var.reset(); }
    void set_optional_variant_to_int(int val) { optional_var = val; }
    void set_optional_variant_to_string(const std::string& val) { optional_var = val; }
};

// Global test instances
inline VariantContainer global_variant_container;

// Glaze metadata for all structs
template<>
struct glz::meta<Point2D> {
    using T = Point2D;
    static constexpr auto value = object(
        "x", &T::x,
        "y", &T::y
    );
};

template<>
struct glz::meta<Point3D> {
    using T = Point3D;
    static constexpr auto value = object(
        "x", &T::x,
        "y", &T::y,
        "z", &T::z
    );
};

template<>
struct glz::meta<Color> {
    using T = Color;
    static constexpr auto value = object(
        "r", &T::r,
        "g", &T::g,
        "b", &T::b,
        "a", &T::a
    );
};

template<>
struct glz::meta<Vehicle> {
    using T = Vehicle;
    static constexpr auto value = object(
        "name", &T::name,
        "wheels", &T::wheels,
        "max_speed", &T::max_speed
    );
};

template<>
struct glz::meta<VariantContainer> {
    using T = VariantContainer;
    static constexpr auto value = object(
        "simple_var", &T::simple_var,
        "geometry_var", &T::geometry_var,
        "mixed_var", &T::mixed_var,
        "complex_var", &T::complex_var,
        "optional_var", &T::optional_var,
        "set_simple_to_int", &T::set_simple_to_int,
        "set_simple_to_double", &T::set_simple_to_double,
        "set_simple_to_string", &T::set_simple_to_string,
        "get_simple_index", &T::get_simple_index,
        "get_geometry_index", &T::get_geometry_index,
        "get_mixed_index", &T::get_mixed_index,
        "get_complex_index", &T::get_complex_index,
        "set_geometry_to_point2d", &T::set_geometry_to_point2d,
        "set_geometry_to_point3d", &T::set_geometry_to_point3d,
        "set_geometry_to_color", &T::set_geometry_to_color,
        "set_mixed_to_int", &T::set_mixed_to_int,
        "set_mixed_to_point2d", &T::set_mixed_to_point2d,
        "set_mixed_to_string", &T::set_mixed_to_string,
        "set_mixed_to_vehicle", &T::set_mixed_to_vehicle,
        "get_simple_variant", &T::get_simple_variant,
        "get_geometry_variant", &T::get_geometry_variant,
        "set_simple_variant", &T::set_simple_variant,
        "set_geometry_variant", &T::set_geometry_variant,
        "has_optional_variant", &T::has_optional_variant,
        "clear_optional_variant", &T::clear_optional_variant,
        "set_optional_variant_to_int", &T::set_optional_variant_to_int,
        "set_optional_variant_to_string", &T::set_optional_variant_to_string
    );
};