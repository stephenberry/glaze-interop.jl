#include <glaze/interop/interop.hpp>

// Simple nested struct example
struct Point {
    float x;
    float y;
};

struct Line {
    Point start;
    Point end;
    float length;
};

// Global instance for testing
inline Line test_line{
    {0.0f, 0.0f},    // start point
    {3.0f, 4.0f},    // end point
    5.0f             // length (3-4-5 triangle)
};

extern "C" {
    #ifdef _WIN32
        __declspec(dllexport)
    #else
        __attribute__((visibility("default")))
    #endif
    void init_nested_types() {
        glz::register_type<Point>("Point");
        glz::register_type<Line>("Line");
        
        // Register the test instance
        glz::register_instance("test_line", test_line);
    }
}