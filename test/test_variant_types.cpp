#include "test_variant_types.hpp"

// Initialize variant test types
extern "C" void init_variant_test_types() {
    // Register all the structs
    glz::register_type<Point2D>("Point2D");
    glz::register_type<Point3D>("Point3D");
    glz::register_type<Color>("Color");
    glz::register_type<Vehicle>("Vehicle");
    glz::register_type<VariantContainer>("VariantContainer");
    
    // Register variant types (this will enable variant support)
    // Note: The variant types will be automatically handled by the interop system
    
    // Register global instances
    glz::register_instance("global_variant_container", global_variant_container);
    
    // Initialize global instance with test data
    global_variant_container.simple_var = 100;
    global_variant_container.geometry_var = Point2D(10.0f, 20.0f);
    global_variant_container.mixed_var = Vehicle("TestCar", 4, 120.0);
    global_variant_container.complex_var = std::vector<int>{1, 2, 3, 4, 5};
    global_variant_container.optional_var = std::string("global_test");
}