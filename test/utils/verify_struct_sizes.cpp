#include <glaze/interop/interop.hpp>
#include <iostream>
#include <cstddef>

int main() {
    std::cout << "C++ struct sizes and offsets:\n\n";
    
    std::cout << "glz_type_descriptor:\n";
    std::cout << "  sizeof: " << sizeof(glz_type_descriptor) << std::endl;
    std::cout << "  index offset: " << offsetof(glz_type_descriptor, index) << std::endl;
    std::cout << "  padding offset: " << offsetof(glz_type_descriptor, padding) << std::endl;
    std::cout << "  data offset: " << offsetof(glz_type_descriptor, data) << std::endl;
    
    std::cout << "\nglz_struct_desc:\n";
    std::cout << "  sizeof: " << sizeof(glz_struct_desc) << std::endl;
    std::cout << "  type_name offset: " << offsetof(glz_struct_desc, type_name) << std::endl;
    std::cout << "  info offset: " << offsetof(glz_struct_desc, info) << std::endl;
    std::cout << "  type_hash offset: " << offsetof(glz_struct_desc, type_hash) << std::endl;
    
    std::cout << "\nglz_member_info:\n";
    std::cout << "  sizeof: " << sizeof(glz_member_info) << std::endl;
    std::cout << "  name offset: " << offsetof(glz_member_info, name) << std::endl;
    std::cout << "  type offset: " << offsetof(glz_member_info, type) << std::endl;
    std::cout << "  getter offset: " << offsetof(glz_member_info, getter) << std::endl;
    std::cout << "  setter offset: " << offsetof(glz_member_info, setter) << std::endl;
    
    std::cout << "\nUnion member sizes:\n";
    std::cout << "  primitive: " << sizeof(glz_primitive_desc) << std::endl;
    std::cout << "  string: " << sizeof(glz_string_desc) << std::endl;
    std::cout << "  vector: " << sizeof(glz_vector_desc) << std::endl;
    std::cout << "  map: " << sizeof(glz_map_desc) << std::endl;
    std::cout << "  complex: " << sizeof(glz_complex_desc) << std::endl;
    std::cout << "  struct: " << sizeof(glz_struct_desc) << std::endl;
    
    return 0;
}