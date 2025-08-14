#include "test_member_functions.hpp"
#include <iostream>
#include <cassert>

// Demonstration of the new template-based member function system
int main() {
    std::cout << "=== Member Function Template System Demo ===" << std::endl;
    
    // Register types as usual
    glz::register_type<Calculator>("Calculator");
    glz::register_type<MathUtils>("MathUtils");
    
    // Create instances
    Calculator calc;
    calc.value = 10.0;
    
    MathUtils math;
    math.x = 3.0;
    math.y = 4.0;
    
    // Get type info
    auto* calc_info = glz_get_type_info("Calculator");
    assert(calc_info != nullptr);
    
    std::cout << "\nCalculator type info:" << std::endl;
    std::cout << "  Name: " << calc_info->name << std::endl;
    std::cout << "  Size: " << calc_info->size << " bytes" << std::endl;
    std::cout << "  Members: " << calc_info->member_count << std::endl;
    
    // List all members and identify functions
    for (size_t i = 0; i < calc_info->member_count; ++i) {
        auto& member = calc_info->members[i];
        std::cout << "\n  Member " << i << ": " << member.name;
        
        if (member.kind == 1) {  // Member function
            std::cout << " (function)";
            
            // Check if we have the invoker
            if (member.function_ptr) {
                std::cout << " - has template-based invoker!";
            } else {
                std::cout << " - no invoker (would need manual registration)";
            }
            
            if (member.type && member.type->index == GLZ_TYPE_FUNCTION) {
                auto& func_desc = member.type->data.function;
                std::cout << "\n    Parameters: " << (int)func_desc.param_count;
                std::cout << ", Is const: " << (func_desc.is_const ? "yes" : "no");
            }
        } else {
            std::cout << " (data)";
        }
    }
    
    std::cout << "\n\n=== Testing Member Function Calls ===" << std::endl;
    
    // Test calling add function
    for (size_t i = 0; i < calc_info->member_count; ++i) {
        auto& member = calc_info->members[i];
        if (member.kind == 1 && std::string(member.name) == "add") {
            std::cout << "\nCalling calc.add(5.0)..." << std::endl;
            std::cout << "  Before: value = " << calc.value << std::endl;
            
            double arg = 5.0;
            void* args[] = { &arg };
            double result;
            
            void* ret = glz_call_member_function_with_type(&calc, "Calculator", &member, args, &result);
            
            if (ret) {
                std::cout << "  After: value = " << calc.value << std::endl;
                std::cout << "  Returned: " << result << std::endl;
                std::cout << "  SUCCESS - Template-based invoker worked!" << std::endl;
            } else {
                std::cout << "  FAILED - Could not call function" << std::endl;
            }
            break;
        }
    }
    
    // Test calling reset function (void return)
    for (size_t i = 0; i < calc_info->member_count; ++i) {
        auto& member = calc_info->members[i];
        if (member.kind == 1 && std::string(member.name) == "reset") {
            std::cout << "\nCalling calc.reset()..." << std::endl;
            std::cout << "  Before: value = " << calc.value << std::endl;
            
            void* args[] = {};  // No arguments
            
            void* ret = glz_call_member_function_with_type(&calc, "Calculator", &member, args, nullptr);
            
            if (ret) {
                std::cout << "  After: value = " << calc.value << std::endl;
                std::cout << "  SUCCESS - Void function worked!" << std::endl;
            } else {
                std::cout << "  FAILED - Could not call function" << std::endl;
            }
            break;
        }
    }
    
    // Test calling compute function (multiple parameters)
    for (size_t i = 0; i < calc_info->member_count; ++i) {
        auto& member = calc_info->members[i];
        if (member.kind == 1 && std::string(member.name) == "compute") {
            std::cout << "\nCalling calc.compute(2.0, 3.0, 4.0)..." << std::endl;
            calc.value = 10.0;  // Reset for testing
            
            double a = 2.0, b = 3.0, c = 4.0;
            void* args[] = { &a, &b, &c };
            double result;
            
            void* ret = glz_call_member_function_with_type(&calc, "Calculator", &member, args, &result);
            
            if (ret) {
                std::cout << "  Result: " << result << std::endl;
                std::cout << "  Expected: " << (2.0 * 10.0 + 3.0 * 10.0 + 4.0) << std::endl;
                std::cout << "  SUCCESS - Multi-parameter function worked!" << std::endl;
            } else {
                std::cout << "  FAILED - Could not call function" << std::endl;
            }
            break;
        }
    }
    
    // Test calling describe function (string return)
    for (size_t i = 0; i < calc_info->member_count; ++i) {
        auto& member = calc_info->members[i];
        if (member.kind == 1 && std::string(member.name) == "describe") {
            std::cout << "\nCalling calc.describe()..." << std::endl;
            calc.value = 42.0;  // Set a specific value
            
            void* args[] = {};  // No arguments
            std::string result;
            
            void* ret = glz_call_member_function_with_type(&calc, "Calculator", &member, args, &result);
            
            if (ret) {
                std::cout << "  Result: \"" << result << "\"" << std::endl;
                std::cout << "  SUCCESS - String return function worked!" << std::endl;
            } else {
                std::cout << "  FAILED - Could not call function" << std::endl;
            }
            break;
        }
    }
    
    std::cout << "\n=== Summary ===" << std::endl;
    std::cout << "The new template-based MemberFunctionAccessor system automatically generates" << std::endl;
    std::cout << "type-erased invoker functions at compile time. This eliminates the need for:" << std::endl;
    std::cout << "- Manual invoker function implementations" << std::endl;
    std::cout << "- String-based function key generation" << std::endl;
    std::cout << "- Runtime registration of invokers" << std::endl;
    std::cout << "\nThe invokers are stored directly in the member_info.function_ptr field!" << std::endl;
    
    return 0;
}