#include "test_structs_glaze_simple.hpp"
#include "test_shared_future.hpp"
#include "test_all_types.hpp"
// Map types are not yet supported in Glaze.jl
// #include "test_map_types.hpp"

// Forward declaration for function from test_all_types.cpp
extern "C" void init_all_test_instances();

// Forward declarations for vector test functions
void register_vector_test_types();
void register_vector_test_instances();

// Forward declaration for variant test functions
extern "C" void init_variant_test_types();

// Modified init_test_types to initialize everything
extern "C" {
    #ifdef _WIN32
        __declspec(dllexport)
    #else
        __attribute__((visibility("default")))
    #endif
    void init_test_types_complete() {
        // Initialize simple types
        register_test_types();
        
        // Initialize comprehensive types from test_all_types.hpp
        register_all_test_types();
        
        // Initialize vector test types
        register_vector_test_types();
        
        // Initialize shared_future test types
        register_future_test_types();
        
        // Initialize variant test types
        init_variant_test_types();
        
        // Map test types are not yet supported in Glaze.jl
        // register_map_test_types();
        
        // Initialize all instances via the C interface
        init_all_test_instances();
        
        // Initialize vector test instances
        register_vector_test_instances();
        
        // Initialize shared_future test instances
        register_future_test_instances();
    }
}