#!/bin/bash

set -e  # Exit on error

echo "Building Glaze interface library..."
cd cpp_interface
mkdir -p build
cd build
cmake ..
cmake --build .
cd ../..

echo "Building test library..."
cd test
mkdir -p build
cd build
cmake ..
cmake --build .
cd ../..

echo "Running Julia tests..."
julia --project=. test/runtests.jl

echo "All tests completed successfully!"