#!/bin/bash

set -e  # Exit on error

echo "=== Glaze-interop.jl Test Suite ==="
echo "Platform: $(uname -s) $(uname -m)"
echo "Julia: $(julia --version)"
echo "CMake: $(cmake --version | head -n1)"

# Check for required tools
command -v cmake >/dev/null 2>&1 || { echo "Error: cmake is required but not installed."; exit 1; }
command -v julia >/dev/null 2>&1 || { echo "Error: julia is required but not installed."; exit 1; }

# Check compiler
if command -v g++ >/dev/null 2>&1; then
    echo "Compiler: $(g++ --version | head -n1)"
elif command -v clang++ >/dev/null 2>&1; then
    echo "Compiler: $(clang++ --version | head -n1)"
else
    echo "Warning: No C++ compiler found in PATH"
fi
echo "================================"

echo "Building Glaze interface library..."
cd cpp_interface
mkdir -p build
cd build
cmake ..
if [ $? -ne 0 ]; then
    echo "Failed to configure cpp_interface"
    exit 1
fi
cmake --build .
if [ $? -ne 0 ]; then
    echo "Failed to build cpp_interface"
    exit 1
fi
cd ../..

echo "Building test library..."
cd test
mkdir -p build
cd build
cmake ..
if [ $? -ne 0 ]; then
    echo "Failed to configure test library"
    exit 1
fi
cmake --build .
if [ $? -ne 0 ]; then
    echo "Failed to build test library"
    exit 1
fi
cd ../..

echo "Running Julia tests..."
julia --project=. test/runtests.jl
if [ $? -ne 0 ]; then
    echo "Julia tests failed"
    exit 1
fi

echo "================================"
echo "✅ All tests completed successfully!"
echo "================================"