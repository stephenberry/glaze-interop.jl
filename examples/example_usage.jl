using Glaze

# Build the example library first
# This would typically be done via CMake
# For now, showing the conceptual usage

# Load the shared library
lib = Glaze.load("libexample.so")  # or .dylib on macOS, .dll on Windows

# Initialize the types
ccall((:init_example, lib.handle), Cvoid, ())

# Create a C++ struct instance
sensor = lib.SensorData

# Direct memory manipulation - no copying!
sensor.name = "Temperature Sensor A"
sensor.id = 42
sensor.temperature = 23.5
sensor.active = true

# Working with std::vector<float> without copying
push!(sensor.measurements, 1.0)
push!(sensor.measurements, 2.5)
push!(sensor.measurements, 3.7)

# Direct indexing
sensor.measurements[2] = 2.8

# Resize vector
resize!(sensor.measurements, 10)

# Working with std::vector<std::complex<float>>
push!(sensor.frequency_response, 1.0 + 2.0im)
push!(sensor.frequency_response, 3.0 - 1.0im)

# Read values back
println("Sensor name: ", String(sensor.name))
println("Sensor ID: ", sensor.id)
println("Temperature: ", sensor.temperature)
println("Active: ", sensor.active)
println("Measurements: ", [sensor.measurements[i] for i in 1:length(sensor.measurements)])
println("First frequency response: ", sensor.frequency_response[1])