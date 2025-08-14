#include <iostream>
#include <utility>
#include <cstring>
#include "glaze/glaze.hpp"

int main() {
    constexpr auto name = glz::name_v<std::pair<double, double>>;
    std::cout << "String view: '" << name << "'" << std::endl;
    std::cout << "Size: " << name.size() << std::endl;
    std::cout << "Data pointer: " << (void*)name.data() << std::endl;
    
    // Check if null terminated
    const char* ptr = name.data();
    size_t len = std::strlen(ptr);
    std::cout << "strlen: " << len << std::endl;
    std::cout << "Matches size? " << (len == name.size() ? "yes" : "no") << std::endl;
    
    // Print each character
    std::cout << "Characters: ";
    for (size_t i = 0; i <= name.size(); ++i) {
        char c = ptr[i];
        if (c == '\0') {
            std::cout << "\\0";
        } else if (c >= 32 && c <= 126) {
            std::cout << c;
        } else {
            std::cout << "\\x" << std::hex << (int)(unsigned char)c << std::dec;
        }
    }
    std::cout << std::endl;
    
    return 0;
}