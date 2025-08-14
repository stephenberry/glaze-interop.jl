#include <vector>
#include <cstdio>

extern "C" {
    // Simple test function that returns a vector
    void test_return_vector(void* result_buffer) {
        printf("test_return_vector called, buffer at: %p\n", result_buffer);
        
        // Construct vector in place
        std::vector<int>* vec = new(result_buffer) std::vector<int>{1, 2, 3};
        
        printf("Vector constructed, data at: %p, size: %zu\n", vec->data(), vec->size());
    }
    
    // Get view of a vector
    struct VectorView {
        void* data;
        size_t size;
        size_t capacity;
    };
    
    VectorView get_vector_view(void* vec_ptr) {
        auto* vec = static_cast<std::vector<int>*>(vec_ptr);
        return {vec->data(), vec->size(), vec->capacity()};
    }
}