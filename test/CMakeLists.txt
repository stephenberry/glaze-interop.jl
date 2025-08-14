cmake_minimum_required(VERSION 3.20)
project(GlazeTests CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Add debug flags for investigating segfaults
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g -O0 -fsanitize=address -fno-omit-frame-pointer")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fsanitize=address")
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -fsanitize=address")
endif()

# Find or fetch Glaze
include(FetchContent)
FetchContent_Declare(
    glaze
    GIT_REPOSITORY https://github.com/stephenberry/glaze.git
    GIT_TAG interop
)
FetchContent_MakeAvailable(glaze)

# Include the parent cpp_interface directory and Glaze headers
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/../cpp_interface
    ${glaze_SOURCE_DIR}/include
)

# Create a single compilation unit for all test files to avoid duplicate symbols
add_library(test_lib SHARED
    ${CMAKE_CURRENT_SOURCE_DIR}/test_lib_single_unit.cpp
)

target_compile_features(test_lib PUBLIC cxx_std_23)
target_link_libraries(test_lib PUBLIC glaze::glaze)
set_target_properties(test_lib PROPERTIES
    POSITION_INDEPENDENT_CODE ON
    CXX_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN ON
)

# Export symbols for C API
target_compile_definitions(test_lib PRIVATE GLZ_EXPORTS)