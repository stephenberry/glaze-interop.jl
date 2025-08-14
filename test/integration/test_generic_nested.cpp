#include "../../examples/example_struct.hpp"
#include <iostream>

// Another example with different nested structs to test genericity
struct Config {
    std::string name;
    int version;
};

struct Database {
    std::string connection_string;
    bool is_connected;
    Config config;  // Nested struct
};

// Global instance
inline Database test_database{
    "postgresql://localhost:5432/mydb",
    false,
    {"MyDB", 1}
};

extern "C" {
    __attribute__((visibility("default")))
    void init_generic_test() {
        // Register nested types first
        glz::register_type<Config>("Config");
        glz::register_type<Database>("Database");
        
        // Register instance
        glz::register_instance("test_database", test_database);
    }
}