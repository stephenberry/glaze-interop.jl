#pragma once

#include <future>
#include <thread>
#include <chrono>
#include <iostream>
#include <glaze/interop/interop.hpp>
#include "test_structs_glaze_simple.hpp"  // For Person struct

struct FutureTest {
    // Simple async computation that returns a double
    std::shared_future<double> computeAsync(double value, int delay_ms) {
        return std::async(std::launch::async, [value, delay_ms]() {
            std::this_thread::sleep_for(std::chrono::milliseconds(delay_ms));
            return value * 2.0;
        }).share();
    }
    
    // Returns a ready future
    std::shared_future<int32_t> getReadyFuture(int32_t value) {
        std::promise<int32_t> promise;
        promise.set_value(value);
        return promise.get_future().share();
    }
    
    // Returns a future that produces a string
    std::shared_future<std::string> getStringAsync(const std::string& prefix, int delay_ms) {
        return std::async(std::launch::async, [prefix, delay_ms]() {
            std::this_thread::sleep_for(std::chrono::milliseconds(delay_ms));
            return prefix + " from future";
        }).share();
    }
    
    // Returns a future that produces a vector
    std::shared_future<std::vector<int32_t>> getVectorAsync(size_t size, int delay_ms) {
        return std::async(std::launch::async, [size, delay_ms]() {
            std::this_thread::sleep_for(std::chrono::milliseconds(delay_ms));
            std::vector<int32_t> result;
            result.reserve(size);
            for (size_t i = 0; i < size; ++i) {
                result.push_back(static_cast<int32_t>(i * i));
            }
            return result;
        }).share();
    }
    
    // Returns an invalid future
    std::shared_future<double> getInvalidFuture() {
        return std::shared_future<double>();
    }
    
    // Returns a future that produces a struct with vectors (using Person struct)
    std::shared_future<Person> getPersonAsync(const std::string& name, int age, int delay_ms) {
        return std::async(std::launch::async, [name, age, delay_ms]() {
            std::this_thread::sleep_for(std::chrono::milliseconds(delay_ms));
            
            Person result;
            result.name = name;
            result.age = age;
            
            // Set address
            result.address.street = "123 Future St";
            result.address.city = "Async City";
            result.address.zipcode = 12345;
            
            // Fill scores vector
            result.scores.clear();
            for (int i = 0; i < 5; ++i) {
                result.scores.push_back(i * 10 + age);
            }
            
            
            return result;
        }).share();
    }
};

// Glaze meta for FutureTest
template<>
struct glz::meta<FutureTest> {
    using T = FutureTest;
    static constexpr auto value = glz::object(
        "computeAsync", &T::computeAsync,
        "getReadyFuture", &T::getReadyFuture,
        "getStringAsync", &T::getStringAsync,
        "getVectorAsync", &T::getVectorAsync,
        "getInvalidFuture", &T::getInvalidFuture,
        "getPersonAsync", &T::getPersonAsync
    );
};

// Register the test type
inline void register_future_test_types() {
    glz::register_type<FutureTest>("FutureTest");
    // Person is already registered in test_structs_glaze_simple.cpp
}

// Global instance
inline FutureTest global_future_test;

// Register instances
inline void register_future_test_instances() {
    glz::register_instance("global_future_test", global_future_test);
}