#include <glaze/interop/interop.hpp>
#include <iostream>

// Example of nested structs
struct Address {
    std::string street;
    std::string city;
    int zip_code;
};
// Let Glaze reflection handle registration

struct Person {
    std::string name;
    int age;
    Address home_address;  // Nested struct
};
// Let Glaze reflection handle registration

// Global instance for testing
inline Person example_person{
    "John Doe",
    30,
    {"123 Main St", "Anytown", 12345}
};

extern "C" {
    __attribute__((visibility("default")))
    void init_nested_example() {
        // Register types - nested types must be registered first
        glz::register_type<Address>("Address");
        glz::register_type<Person>("Person");
        
        // Register the instance
        glz::register_instance("example_person", example_person);
        
        std::cout << "Registered Person and Address types successfully!" << std::endl;
    }
}