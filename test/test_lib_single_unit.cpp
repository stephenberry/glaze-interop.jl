// Single compilation unit to avoid duplicate symbols from inline thread_local
// This file includes all test source files

// Include the Glaze interop headers first
#include <glaze/interop/interop.hpp>

// Then include test files
#include "test_structs_glaze_simple.cpp"
#include "test_all_types.cpp"
#include "test_nested_structs.cpp"
#include "test_vector_member_functions.cpp"
#include "test_variant_types.cpp"

// Include the variant animals demo
#include "variant_animals_demo.cpp"

// Include the interop implementation
#include "build/_deps/glaze-src/src/interop/interop.cpp"