cmake_minimum_required(VERSION 3.20)
project(GlazeInterface CXX)

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

# Since Glaze interop is now header-only, we just need to provide the headers
# This CMakeLists.txt is kept for compatibility but doesn't build a library anymore
add_library(glaze_interface INTERFACE)
target_link_libraries(glaze_interface INTERFACE glaze::glaze)
target_include_directories(glaze_interface INTERFACE 
    ${glaze_SOURCE_DIR}/include
)