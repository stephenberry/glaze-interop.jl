#include <glaze/interop/interop.hpp>
#include <iostream>

// Example showing the benefit of the three-enum type system
struct ExampleStruct {
    // Basic types - only need OuterType
    int32_t age;
    double weight;
    bool active;
    std::string name;
    
    // Vector types - need OuterType and ValueType
    std::vector<int32_t> scores;
    std::vector<double> measurements;
    std::vector<std::string> tags;
    
    // Complex types - OuterType is Complex, ValueType specifies F32/F64
    std::complex<float> position;
    std::vector<std::complex<double>> trajectory;
    
    // Map types - need all three: OuterType, KeyType, and ValueType
    std::unordered_map<std::string, int32_t> name_to_id;
    std::unordered_map<int32_t, std::vector<float>> id_to_data;
};

template <>
struct glz::meta<ExampleStruct> {
    using T = ExampleStruct;
    static constexpr auto value = object(
        "age", &T::age,
        "weight", &T::weight,
        "active", &T::active,
        "name", &T::name,
        "scores", &T::scores,
        "measurements", &T::measurements,
        "tags", &T::tags,
        "position", &T::position,
        "trajectory", &T::trajectory,
        "name_to_id", &T::name_to_id,
        "id_to_data", &T::id_to_data
    );
};

void demonstrate_type_decomposition() {
    std::cout << "Type System Demonstration:\n\n";
    
    // Basic types
    std::cout << "Basic Types (only OuterType used):\n";
    std::cout << "  int32_t: OuterType = I32\n";
    std::cout << "  double: OuterType = F64\n";
    std::cout << "  bool: OuterType = Bool\n";
    std::cout << "  string: OuterType = String\n\n";
    
    // Vector types
    std::cout << "Vector Types (OuterType + ValueType):\n";
    std::cout << "  vector<int32_t>: OuterType = Vector, ValueType = I32\n";
    std::cout << "  vector<double>: OuterType = Vector, ValueType = F64\n";
    std::cout << "  vector<string>: OuterType = Vector, ValueType = String\n\n";
    
    // Complex types
    std::cout << "Complex Types:\n";
    std::cout << "  complex<float>: OuterType = Complex, ValueType = ComplexF32\n";
    std::cout << "  vector<complex<double>>: OuterType = Vector, ValueType = ComplexF64\n\n";
    
    // Map types
    std::cout << "Map Types (all three used):\n";
    std::cout << "  unordered_map<string, int32_t>: OuterType = UnorderedMap, KeyType = String, ValueType = I32\n";
    std::cout << "  unordered_map<int32_t, vector<float>>: OuterType = UnorderedMap, KeyType = I32, ValueType = Vector\n";
    std::cout << "    (Note: Nested containers would need additional metadata)\n\n";
    
    std::cout << "Benefits of this system:\n";
    std::cout << "1. No need for separate TypeKind enums for every combination\n";
    std::cout << "2. Easy to add new container types (just add to OuterType)\n";
    std::cout << "3. Easy to add new value types (just add to ValueType)\n";
    std::cout << "4. Cleaner code with less duplication\n";
}

int main() {
    demonstrate_type_decomposition();
    
    // Register the type
    glz::register_type<ExampleStruct>("ExampleStruct");
    
    // Create and inspect an instance
    ExampleStruct example{
        .age = 25,
        .weight = 70.5,
        .active = true,
        .name = "John Doe",
        .scores = {100, 95, 87},
        .measurements = {1.5, 2.3, 3.7},
        .tags = {"fast", "reliable"},
        .position = {1.0f, 2.0f},
        .trajectory = {{0.0, 0.0}, {1.0, 1.0}, {2.0, 4.0}},
        .name_to_id = {{"Alice", 1}, {"Bob", 2}},
        .id_to_data = {{1, {1.1f, 2.2f}}, {2, {3.3f, 4.4f}}}
    };
    
    std::cout << "\nExample instance created successfully!\n";
    
    return 0;
}