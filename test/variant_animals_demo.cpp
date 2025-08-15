#include "variant_animals_demo.hpp"

// Global instance of the zoo
Zoo global_zoo;

// Initialize the animals demo and register with Glaze
extern "C" __attribute__((visibility("default"))) void init_animals_demo() {
    // Register the global instance
    glz::register_instance("global_zoo", global_zoo);
}