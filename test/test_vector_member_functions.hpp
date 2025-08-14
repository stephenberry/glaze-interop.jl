#pragma once

#include <glaze/glaze.hpp>
#include <glaze/interop/interop.hpp>
#include <vector>
#include <algorithm>
#include <numeric>
#include <complex>
#include <string>
#include <sstream>
#include <cmath>

// Struct with member functions that accept and return vectors of various types
struct VectorProcessor {
    double scale_factor = 1.0;
    
    // Sum all elements in an integer vector
    int sumIntegers(const std::vector<int>& values) {
        return std::accumulate(values.begin(), values.end(), 0);
    }
    
    // Average of float vector
    float averageFloats(const std::vector<float>& values) {
        if (values.empty()) return 0.0f;
        float sum = std::accumulate(values.begin(), values.end(), 0.0f);
        return sum / values.size();
    }
    
    // Scale all doubles in vector by scale_factor
    std::vector<double> scaleDoubles(const std::vector<double>& values) {
        std::vector<double> result;
        result.reserve(values.size());
        for (double v : values) {
            result.push_back(v * scale_factor);
        }
        return result;
    }
    
    // Concatenate strings with delimiter
    std::string joinStrings(const std::vector<std::string>& strings, const std::string& delimiter) {
        if (strings.empty()) return "";
        std::stringstream ss;
        for (size_t i = 0; i < strings.size(); ++i) {
            if (i > 0) ss << delimiter;
            ss << strings[i];
        }
        return ss.str();
    }
    
    // Process complex numbers - compute magnitudes
    std::vector<float> complexMagnitudes(const std::vector<std::complex<float>>& values) {
        std::vector<float> mags;
        mags.reserve(values.size());
        for (const auto& c : values) {
            mags.push_back(std::abs(c));
        }
        return mags;
    }
    
    // Find min and max in double vector
    std::pair<double, double> findMinMax(const std::vector<double>& values) {
        if (values.empty()) return {0.0, 0.0};
        auto [min_it, max_it] = std::minmax_element(values.begin(), values.end());
        return {*min_it, *max_it};
    }
    
    // Count elements matching condition
    int countGreaterThan(const std::vector<double>& values, double threshold) {
        return std::count_if(values.begin(), values.end(), 
                           [threshold](double v) { return v > threshold; });
    }
    
    // Dot product of two vectors
    double dotProduct(const std::vector<double>& a, const std::vector<double>& b) {
        if (a.size() != b.size()) return 0.0;
        double result = 0.0;
        for (size_t i = 0; i < a.size(); ++i) {
            result += a[i] * b[i];
        }
        return result;
    }
    
    // Element-wise operations on vectors
    std::vector<double> elementWiseAdd(const std::vector<double>& a, const std::vector<double>& b) {
        size_t size = std::min(a.size(), b.size());
        std::vector<double> result;
        result.reserve(size);
        for (size_t i = 0; i < size; ++i) {
            result.push_back(a[i] + b[i]);
        }
        return result;
    }
    
    // Filter vector based on condition
    std::vector<int> filterPositive(const std::vector<int>& values) {
        std::vector<int> result;
        std::copy_if(values.begin(), values.end(), std::back_inserter(result),
                    [](int v) { return v > 0; });
        return result;
    }
    
    // Reverse a vector (modifies internal state based on result)
    std::vector<float> reverseAndScale(std::vector<float> values) {
        std::reverse(values.begin(), values.end());
        for (auto& v : values) {
            v *= scale_factor;
        }
        // Update scale factor based on size
        if (!values.empty()) {
            scale_factor = 1.0 + (1.0 / values.size());
        }
        return values;
    }
    
    // Process mixed types - take int vector, return float vector
    std::vector<float> normalizeIntegers(const std::vector<int>& values) {
        if (values.empty()) return {};
        
        // Find max absolute value
        int max_abs = 0;
        for (int v : values) {
            max_abs = std::max(max_abs, std::abs(v));
        }
        
        if (max_abs == 0) return std::vector<float>(values.size(), 0.0f);
        
        // Normalize
        std::vector<float> result;
        result.reserve(values.size());
        for (int v : values) {
            result.push_back(static_cast<float>(v) / max_abs);
        }
        return result;
    }
    
    // Void function that modifies internal state based on vector
    void updateScaleFromVector(const std::vector<double>& values) {
        if (!values.empty()) {
            double sum = std::accumulate(values.begin(), values.end(), 0.0);
            scale_factor = sum / values.size();
        }
    }
    
    // Const member function with vector parameter
    bool allPositive(const std::vector<double>& values) const {
        return std::all_of(values.begin(), values.end(), 
                          [](double v) { return v > 0.0; });
    }
    
    // Function that takes multiple vector parameters
    double computeWeightedSum(const std::vector<double>& values, 
                            const std::vector<double>& weights) {
        if (values.size() != weights.size() || values.empty()) return 0.0;
        
        double sum = 0.0;
        for (size_t i = 0; i < values.size(); ++i) {
            sum += values[i] * weights[i];
        }
        return sum;
    }
    
    // Complex function with multiple parameters including vectors
    std::string processData(const std::vector<int>& ids,
                          const std::vector<std::string>& names,
                          double threshold) {
        std::stringstream result;
        result << "Processing " << ids.size() << " items with threshold " << threshold << ": ";
        
        size_t count = std::min(ids.size(), names.size());
        for (size_t i = 0; i < count; ++i) {
            if (ids[i] > threshold) {
                result << names[i] << "(" << ids[i] << ") ";
            }
        }
        
        return result.str();
    }
};

// Additional test struct for edge cases
struct VectorEdgeCases {
    // Handle empty vector
    std::string describeVector(const std::vector<double>& vec) {
        if (vec.empty()) return "Empty vector";
        return "Vector with " + std::to_string(vec.size()) + " elements";
    }
    
    // Return empty vector
    std::vector<int> getEmptyVector() {
        return {};
    }
    
    // Large vector processing
    double sumLargeVector(const std::vector<double>& vec) {
        // Can handle vectors of any size
        return std::accumulate(vec.begin(), vec.end(), 0.0);
    }
    
    // Nested vector operations
    std::vector<std::vector<int>> createMatrix(int rows, int cols, int value) {
        return std::vector<std::vector<int>>(rows, std::vector<int>(cols, value));
    }
};

// Register types with Glaze using template specialization
namespace glz {

template <>
struct meta<VectorProcessor> {
    using T = VectorProcessor;
    static constexpr auto value = glz::object(
        "scale_factor", &T::scale_factor,
        "sumIntegers", &T::sumIntegers,
        "averageFloats", &T::averageFloats,
        "scaleDoubles", &T::scaleDoubles,
        "joinStrings", &T::joinStrings,
        "complexMagnitudes", &T::complexMagnitudes,
        "findMinMax", &T::findMinMax,
        "countGreaterThan", &T::countGreaterThan,
        "dotProduct", &T::dotProduct,
        "elementWiseAdd", &T::elementWiseAdd,
        "filterPositive", &T::filterPositive,
        "reverseAndScale", &T::reverseAndScale,
        "normalizeIntegers", &T::normalizeIntegers,
        "updateScaleFromVector", &T::updateScaleFromVector,
        "allPositive", &T::allPositive,
        "computeWeightedSum", &T::computeWeightedSum,
        "processData", &T::processData
    );
};

template <>
struct meta<VectorEdgeCases> {
    using T = VectorEdgeCases;
    static constexpr auto value = glz::object(
        "describeVector", &T::describeVector,
        "getEmptyVector", &T::getEmptyVector,
        "sumLargeVector", &T::sumLargeVector,
        "createMatrix", &T::createMatrix
    );
};

}  // namespace glz