#!/bin/bash

set -e  # Exit on error

echo "=== Debug Test Run ==="
echo "Julia version: $(julia --version)"
echo "Platform: $(uname -a)"
echo "========================"

# Enable core dumps
ulimit -c unlimited

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

echo "Running Julia tests with debug info..."

# Run tests with more verbose output
JULIA_DEBUG="Glaze" julia --project=. --trace-compile=stderr test/runtests.jl 2>&1 | tee test_output.log

if [ $? -eq 0 ]; then
    echo "All tests completed successfully!"
else
    echo "Tests failed with exit code $?"
    echo "Last 50 lines of output:"
    tail -50 test_output.log
    
    # Check for core dumps
    if ls core* 1> /dev/null 2>&1; then
        echo "Core dump found - analyzing..."
        for core in core*; do
            echo "Analyzing $core:"
            lldb -c "$core" --batch -o "bt all" -o "quit"
        done
    fi
    
    exit 1
fi