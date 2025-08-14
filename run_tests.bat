@echo off
setlocal enabledelayedexpansion

echo Building Glaze interface library...
cd cpp_interface
if not exist build mkdir build
cd build
cmake .. -G "Visual Studio 17 2022" -A x64
if %errorlevel% neq 0 (
    echo Failed to configure cpp_interface
    exit /b %errorlevel%
)
cmake --build . --config Release
if %errorlevel% neq 0 (
    echo Failed to build cpp_interface  
    exit /b %errorlevel%
)
cd ..\..

echo Building test library...
cd test
if not exist build mkdir build
cd build
cmake .. -G "Visual Studio 17 2022" -A x64
if %errorlevel% neq 0 (
    echo Failed to configure test library
    exit /b %errorlevel%
)
cmake --build . --config Release
if %errorlevel% neq 0 (
    echo Failed to build test library
    exit /b %errorlevel%
)
cd ..\..

echo Running Julia tests...
julia --project=. test\runtests.jl
if %errorlevel% neq 0 (
    echo Julia tests failed
    exit /b %errorlevel%
)

echo All tests completed successfully!