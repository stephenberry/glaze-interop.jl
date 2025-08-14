#include <glaze/interop/interop.hpp>
#include <vector>

// Multi-level nested structs example
struct Coordinate {
    double latitude;
    double longitude;
};

template <>
struct glz::meta<Coordinate> {
    using T = Coordinate;
    static constexpr auto value = object(&T::latitude, &T::longitude);
};

struct Building {
    std::string name;
    Coordinate location;
    int floors;
};

template <>
struct glz::meta<Building> {
    using T = Building;
    static constexpr auto value = object(&T::name, &T::location, &T::floors);
};

struct Company {
    std::string name;
    Building headquarters;
    std::vector<Building> branches;
    int employee_count;
};

template <>
struct glz::meta<Company> {
    using T = Company;
    static constexpr auto value = object(&T::name, &T::headquarters, &T::branches, &T::employee_count);
};

// Global instance for testing
inline Company tech_company{
    "TechCorp",
    {
        "Main HQ",
        {37.7749, -122.4194},  // San Francisco
        20
    },
    {
        {"East Branch", {40.7128, -74.0060}, 10},  // New York
        {"West Branch", {34.0522, -118.2437}, 8}   // Los Angeles
    },
    5000
};

extern "C" {
    __attribute__((visibility("default")))
    void init_complex_example() {
        // Register types - innermost types first
        glz::register_type<Coordinate>("Coordinate");
        glz::register_type<Building>("Building");
        glz::register_type<Company>("Company");
        
        // Register the instance
        glz::register_instance("tech_company", tech_company);
    }
}