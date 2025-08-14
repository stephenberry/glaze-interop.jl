#include <vector>
#include <chrono>
#include <iostream>
#include <numeric>
#include <cstdlib>
#include <cstring>

// Include Glaze headers
#include <glaze/glaze.hpp>

// Test struct with vector
struct BenchmarkStruct {
    std::vector<float> data;
};

// Register with Glaze
template <>
struct glz::meta<BenchmarkStruct> {
    using T = BenchmarkStruct;
    static constexpr auto value = object(
        "data", &T::data
    );
};

// Benchmark functions
extern "C" {
    // Create benchmark struct
    void* create_benchmark_struct(size_t size) {
        auto* obj = new BenchmarkStruct();
        obj->data.reserve(size);
        for (size_t i = 0; i < size; ++i) {
            obj->data.push_back(static_cast<float>(i) * 0.1f);
        }
        return obj;
    }
    
    // Destroy benchmark struct
    void destroy_benchmark_struct(void* ptr) {
        delete static_cast<BenchmarkStruct*>(ptr);
    }
    
    // C++ iteration benchmark - sum all elements
    double benchmark_cpp_iteration(void* ptr, int iterations) {
        auto* obj = static_cast<BenchmarkStruct*>(ptr);
        
        auto start = std::chrono::high_resolution_clock::now();
        
        float sum = 0.0f;
        for (int iter = 0; iter < iterations; ++iter) {
            sum = 0.0f;
            for (float val : obj->data) {
                sum += val;
            }
        }
        
        auto end = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start);
        
        // Prevent optimization
        if (sum < 0) std::cout << sum << std::endl;
        
        return static_cast<double>(duration.count()) / iterations;
    }
    
    // C++ iteration with index
    double benchmark_cpp_iteration_indexed(void* ptr, int iterations) {
        auto* obj = static_cast<BenchmarkStruct*>(ptr);
        
        auto start = std::chrono::high_resolution_clock::now();
        
        float sum = 0.0f;
        for (int iter = 0; iter < iterations; ++iter) {
            sum = 0.0f;
            for (size_t i = 0; i < obj->data.size(); ++i) {
                sum += obj->data[i];
            }
        }
        
        auto end = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start);
        
        // Prevent optimization
        if (sum < 0) std::cout << sum << std::endl;
        
        return static_cast<double>(duration.count()) / iterations;
    }
    
    // C++ iteration with raw pointer
    double benchmark_cpp_iteration_raw(void* ptr, int iterations) {
        auto* obj = static_cast<BenchmarkStruct*>(ptr);
        
        auto start = std::chrono::high_resolution_clock::now();
        
        float sum = 0.0f;
        const float* data = obj->data.data();
        const size_t size = obj->data.size();
        
        for (int iter = 0; iter < iterations; ++iter) {
            sum = 0.0f;
            for (size_t i = 0; i < size; ++i) {
                sum += data[i];
            }
        }
        
        auto end = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start);
        
        // Prevent optimization
        if (sum < 0) std::cout << sum << std::endl;
        
        return static_cast<double>(duration.count()) / iterations;
    }
    
    // Get Glaze type info
    const glz::detail::type_info* glz_get_type_info(const char* type_name) {
        if (std::strcmp(type_name, "BenchmarkStruct") == 0) {
            static const auto info = glz::reflect<BenchmarkStruct>::type_info();
            return &info;
        }
        return nullptr;
    }
    
    // Get instance
    void* glz_get_instance(const char* instance_name) {
        static BenchmarkStruct global_benchmark;
        if (std::strcmp(instance_name, "benchmark_struct") == 0) {
            return &global_benchmark;
        }
        return nullptr;
    }
    
    // Initialize the benchmark struct with data
    void init_benchmark_data(size_t size) {
        auto* obj = static_cast<BenchmarkStruct*>(glz_get_instance("benchmark_struct"));
        obj->data.clear();
        obj->data.reserve(size);
        for (size_t i = 0; i < size; ++i) {
            obj->data.push_back(static_cast<float>(i) * 0.1f);
        }
    }
}

// Main function for standalone testing
int main() {
    const size_t sizes[] = {100, 1000, 10000, 100000, 1000000};
    const int iterations = 1000;
    
    std::cout << "C++ std::vector<float> Iteration Benchmarks\n";
    std::cout << "==========================================\n\n";
    
    for (size_t size : sizes) {
        void* obj = create_benchmark_struct(size);
        
        double time_range = benchmark_cpp_iteration(obj, iterations);
        double time_index = benchmark_cpp_iteration_indexed(obj, iterations);
        double time_raw = benchmark_cpp_iteration_raw(obj, iterations);
        
        std::cout << "Size: " << size << " elements\n";
        std::cout << "  Range-based for: " << time_range << " ns\n";
        std::cout << "  Indexed access:  " << time_index << " ns\n";
        std::cout << "  Raw pointer:     " << time_raw << " ns\n";
        std::cout << "  Per element:     " << time_range / size << " ns\n\n";
        
        destroy_benchmark_struct(obj);
    }
    
    return 0;
}