cmake_minimum_required(VERSION 3.14)
project(benchmark_lib)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find Glaze
find_package(glaze CONFIG REQUIRED)

# Create benchmark library
add_library(benchmark_lib SHARED 
    ../benchmark_iteration.cpp)

target_link_libraries(benchmark_lib PRIVATE glaze::glaze)

# Set output name
set_target_properties(benchmark_lib PROPERTIES
    PREFIX "lib"
    OUTPUT_NAME "benchmark_lib")
