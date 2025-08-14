#pragma once

#include <glaze/interop/interop.hpp>
#include <string>
#include <vector>
#include <complex>
#include <glaze/glaze.hpp>

// Nested struct for location information
struct Location {
    double latitude;
    double longitude;
    float altitude;
    std::string city;
};

// Define glz::meta for Location
template <>
struct glz::meta<Location> {
    using T = Location;
    static constexpr auto value = object(
        "latitude", &T::latitude,
        "longitude", &T::longitude,
        "altitude", &T::altitude,
        "city", &T::city
    );
};

// Nested struct for calibration data
struct CalibrationInfo {
    float offset;
    float scale;
    std::string last_calibrated;
    bool needs_calibration;
};

// Define glz::meta for CalibrationInfo
template <>
struct glz::meta<CalibrationInfo> {
    using T = CalibrationInfo;
    static constexpr auto value = object(
        "offset", &T::offset,
        "scale", &T::scale,
        "last_calibrated", &T::last_calibrated,
        "needs_calibration", &T::needs_calibration
    );
};

struct SensorData {
    std::string name;
    int id;
    float temperature;
    bool active;
    std::vector<float> measurements;
    std::vector<std::complex<float>> frequency_response;
    Location location;  // Nested struct
    CalibrationInfo calibration;  // Another nested struct
};

// Define glz::meta for SensorData
// This automatically provides all member information needed by Glaze
template <>
struct glz::meta<SensorData> {
    using T = SensorData;
    static constexpr auto value = object(
        "name", &T::name,
        "id", &T::id,
        "temperature", &T::temperature,
        "active", &T::active,
        "measurements", &T::measurements,
        "frequency_response", &T::frequency_response,
        "location", &T::location,  // Nested struct member
        "calibration", &T::calibration  // Another nested struct member
    );
};

// Global inline instance that can be accessed from Julia
inline SensorData global_sensor_data{
    "Global Temperature Sensor",  // name
    100,                         // id
    25.5f,                      // temperature
    true,                       // active
    {20.0f, 21.5f, 23.0f},     // measurements
    {{1.0f, 0.0f}, {0.0f, 1.0f}}, // frequency_response
    {37.7749, -122.4194, 52.0f, "San Francisco"}, // location
    {0.5f, 1.2f, "2024-01-15", false} // calibration
};

// Initialize function for the library
extern "C" {
    #ifdef _WIN32
        __declspec(dllexport)
    #else
        __attribute__((visibility("default")))
    #endif
    void init_example() {
        // Register the nested types first
        glz::register_type<Location>("Location");
        glz::register_type<CalibrationInfo>("CalibrationInfo");
        
        // Register the main type using glz::meta automatically
        glz::register_type<SensorData>("SensorData");
        
        // Register the global instance
        glz::register_instance("global_sensor", global_sensor_data);
    }
}