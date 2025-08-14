#include "test_vector_member_functions.hpp"
#include "test_structs_glaze_simple.hpp"

// Register vector test types
void register_vector_test_types() {
    glz::register_type<VectorProcessor>("VectorProcessor");
    glz::register_type<VectorEdgeCases>("VectorEdgeCases");
    
    // Explicitly register pair type used by findMinMax
    // The automatic registration in create_type_descriptor might not work due to static initialization order
    glz::register_type<std::pair<double, double>>("std::pair<double, double>");
}

// Global instances are defined in test_structs_glaze_simple.hpp
// No need for extern declarations since they're inline in the header

// Register instances
void register_vector_test_instances() {
    glz::register_instance("global_vector_processor", global_vector_processor);
    glz::register_instance("global_vector_edge_cases", global_vector_edge_cases);
}