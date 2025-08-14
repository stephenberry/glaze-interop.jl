#include <iostream>
#include <string>

extern "C" {
    void test_string_param(const std::string& str) {
        std::cout << "Received string: '" << str << "'" << std::endl;
        std::cout << "String length: " << str.length() << std::endl;
    }
    
    void test_cstring_param(const char* str) {
        std::cout << "Received C string: '" << str << "'" << std::endl;
    }
}