#!/usr/bin/env julia

"""
Build all C++ examples in the examples directory.
"""

using Pkg

println("Building Glaze.jl examples...")

# Determine platform-specific settings
const IS_WINDOWS = Sys.iswindows()
const IS_MACOS = Sys.isapple()
const IS_LINUX = Sys.islinux()

# Get shared library extension
const DYLIB_EXT = IS_WINDOWS ? ".dll" : (IS_MACOS ? ".dylib" : ".so")

# Compiler settings
const CXX = get(ENV, "CXX", "g++")
const CXXFLAGS = [
    "-std=c++23",
    "-shared",
    "-fPIC",
    "-O2",
    "-I../test/build/_deps/glaze-src/include",
    "-DGLZ_EXPORTS"
]

# Find all C++ example files
cpp_files = filter(f -> endswith(f, "_example.cpp"), readdir("."))

# Build each example
for cpp_file in cpp_files
    base_name = replace(cpp_file, "_example.cpp" => "")
    output_file = base_name * DYLIB_EXT
    
    println("\nBuilding $cpp_file -> $output_file")
    
    cmd = `$CXX $CXXFLAGS -o $output_file $cpp_file`
    
    try
        run(cmd)
        println("✓ Successfully built $output_file")
    catch e
        println("✗ Failed to build $output_file")
        println("  Error: ", e)
    end
end

println("\n✅ Build complete!")
println("\nTo run examples:")
println("  julia --project=.. example_name.jl")