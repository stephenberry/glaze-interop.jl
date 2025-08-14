#include <glaze/interop/interop.hpp>
#include <iostream>

// Example class
struct MathOperations {
    double accumulator = 0.0;
    
    double add(double x) {
        accumulator += x;
        return accumulator;
    }
    
    double multiply(double x) {
        accumulator *= x;
        return accumulator;
    }
    
    void clear() {
        accumulator = 0.0;
    }
};

// Define glz::meta
template <>
struct glz::meta<MathOperations> {
    using T = MathOperations;
    static constexpr auto value = object(
        "accumulator", &T::accumulator,
        "add", &T::add,
        "multiply", &T::multiply,
        "clear", &T::clear
    );
};

// ============================================================================
// OLD WAY: Manual invoker functions (no longer needed!)
// ============================================================================

// You would have needed to write these for EACH member function:
/*
void* MathOperations_add_invoker(void* obj, void** args, void* result_buffer) {
    auto* math = static_cast<MathOperations*>(obj);
    double x = *static_cast<double*>(args[0]);
    double result = math->add(x);
    if (result_buffer) {
        *static_cast<double*>(result_buffer) = result;
    }
    return result_buffer;
}

void* MathOperations_multiply_invoker(void* obj, void** args, void* result_buffer) {
    auto* math = static_cast<MathOperations*>(obj);
    double x = *static_cast<double*>(args[0]);
    double result = math->multiply(x);
    if (result_buffer) {
        *static_cast<double*>(result_buffer) = result;
    }
    return result_buffer;
}

void* MathOperations_clear_invoker(void* obj, void** args, void* result_buffer) {
    auto* math = static_cast<MathOperations*>(obj);
    math->clear();
    return result_buffer;
}

// Then register each one manually:
void register_old_way() {
    glz_register_function_invoker("MathOperations::add(10)->10", MathOperations_add_invoker);
    glz_register_function_invoker("MathOperations::multiply(10)->10", MathOperations_multiply_invoker);
    glz_register_function_invoker("MathOperations::clear()->void", MathOperations_clear_invoker);
}
*/

// ============================================================================
// NEW WAY: Automatic with MemberFunctionAccessor template
// ============================================================================

void demonstrate_new_way() {
    std::cout << "=== MemberFunctionAccessor Template Demo ===" << std::endl;
    std::cout << "\nWith the new template system, you just need to:" << std::endl;
    std::cout << "1. Define your class with member functions" << std::endl;
    std::cout << "2. Add them to glz::meta" << std::endl;
    std::cout << "3. Register the type - DONE!" << std::endl;
    std::cout << "\nNo manual invoker functions needed!" << std::endl;
    
    // Register type - invokers are generated automatically
    glz::register_type<MathOperations>("MathOperations");
    
    // Create instance and test
    MathOperations math;
    math.accumulator = 10.0;
    
    auto* type_info = glz_get_type_info("MathOperations");
    
    std::cout << "\nType '" << type_info->name << "' has " << type_info->member_count << " members:" << std::endl;
    
    for (size_t i = 0; i < type_info->member_count; ++i) {
        auto& member = type_info->members[i];
        std::cout << "  - " << member.name;
        
        if (member.kind == 1) {  // Member function
            std::cout << " (function)";
            if (member.function_ptr) {
                std::cout << " ✓ Has auto-generated invoker!";
            }
        } else {
            std::cout << " (data)";
        }
        std::cout << std::endl;
    }
    
    // Test calling the functions
    std::cout << "\nTesting function calls:" << std::endl;
    std::cout << "Initial accumulator: " << math.accumulator << std::endl;
    
    // Call add(5.0)
    for (size_t i = 0; i < type_info->member_count; ++i) {
        if (type_info->members[i].kind == 1 && 
            std::string(type_info->members[i].name) == "add") {
            
            double arg = 5.0;
            void* args[] = { &arg };
            double result;
            
            glz_call_member_function_with_type(&math, "MathOperations", 
                                             &type_info->members[i], args, &result);
            
            std::cout << "After add(5.0): " << result << std::endl;
            break;
        }
    }
    
    // Call multiply(2.0)
    for (size_t i = 0; i < type_info->member_count; ++i) {
        if (type_info->members[i].kind == 1 && 
            std::string(type_info->members[i].name) == "multiply") {
            
            double arg = 2.0;
            void* args[] = { &arg };
            double result;
            
            glz_call_member_function_with_type(&math, "MathOperations", 
                                             &type_info->members[i], args, &result);
            
            std::cout << "After multiply(2.0): " << result << std::endl;
            break;
        }
    }
    
    // Call clear()
    for (size_t i = 0; i < type_info->member_count; ++i) {
        if (type_info->members[i].kind == 1 && 
            std::string(type_info->members[i].name) == "clear") {
            
            void* args[] = {};
            
            glz_call_member_function_with_type(&math, "MathOperations", 
                                             &type_info->members[i], args, nullptr);
            
            std::cout << "After clear(): " << math.accumulator << std::endl;
            break;
        }
    }
}

int main() {
    demonstrate_new_way();
    
    std::cout << "\n=== Summary ===" << std::endl;
    std::cout << "The MemberFunctionAccessor template eliminates hundreds of lines" << std::endl;
    std::cout << "of boilerplate code by generating invokers at compile time!" << std::endl;
    
    return 0;
}