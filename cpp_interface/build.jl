using Pkg

const build_dir = joinpath(@__DIR__, "build")

# Create build directory
mkpath(build_dir)

# Run CMake
cd(build_dir) do
    run(`cmake ..`)
    run(`cmake --build .`)
end

println("Glaze build completed successfully!")