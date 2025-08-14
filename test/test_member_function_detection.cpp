#include "test_member_functions.hpp"
#include <iostream>
#include <typeinfo>

// Test program to understand how Glaze handles member functions
int main() {
    Calculator calc;
    
    // Let's see what glz::reflect gives us
    using V = std::decay_t<Calculator>;
    static constexpr auto N = glz::reflect<V>::size;
    
    std::cout << "Calculator has " << N << " members in glz::meta" << std::endl;
    
    // Iterate through members
    glz::for_each<N>([&]<auto I>() {
        static constexpr auto key = glz::reflect<V>::keys[I];
        std::cout << "Member " << I << ": " << key.data() << std::endl;
        
        // Check the type of each member
        using MemberPtr = decltype(glz::get<I>(glz::reflect<V>::values));
        
        // Try to detect if it's a member function pointer
        if constexpr (std::is_member_function_pointer_v<MemberPtr>) {
            std::cout << "  -> This is a member function pointer!" << std::endl;
        } else if constexpr (std::is_member_object_pointer_v<MemberPtr>) {
            std::cout << "  -> This is a member object pointer" << std::endl;
        }
    });
    
    return 0;
}