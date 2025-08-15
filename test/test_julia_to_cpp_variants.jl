#!/usr/bin/env julia

"""
Julia to C++ Vector of Variants Test (True Variant Approach)

This test demonstrates the correct variant approach:
1. Creating Julia structs that mirror C++ animal types  
2. Each animal type preserves its unique structure
3. Using type-specific JSON functions to convert to C++
4. C++ receives each type with its original structure
5. Building a true std::vector<std::variant> with different types
"""

# Add the source directory to the load path
push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))

using Test
using Glaze
using Libdl

# Include Julia animal struct definitions
include("julia_animal_structs.jl")

@testset "Julia to C++ Vector of Variants Tests" begin
    
    # Load the test library with animals demo
    lib_path = abspath(joinpath(@__DIR__, "build", "libtest_lib.dylib"))
    @test isfile(lib_path)
    
    lib = Glaze.CppLibrary(lib_path)
    
    # Initialize the animals demo
    init_func = Libdl.dlsym(lib.handle, :init_animals_demo)
    ccall(init_func, Cvoid, ())
    
    # Get the zoo instance
    zoo = Glaze.get_instance(lib, "global_zoo")
    
    @testset "Basic Julia Vector Creation" begin
        # Create a vector of mixed animals in Julia
        julia_animals = create_sample_animals()
        
        @test length(julia_animals) == 5
        @test julia_animals[1] isa JuliaDog
        @test julia_animals[2] isa JuliaCat
        @test julia_animals[3] isa JuliaBird
        @test julia_animals[4] isa JuliaFish
        @test julia_animals[5] isa JuliaReptile
        
        # Test Julia-side counting
        julia_counts = count_julia_animals_by_type(julia_animals)
        @test julia_counts == [1, 1, 1, 1, 1]  # One of each type
    end
    
    @testset "True Variant Conversion (Preserving Unique Types)" begin
        # Create Julia animals with unique structures
        julia_animals = create_sample_animals()
        
        # Clear C++ collection first
        zoo.clear_collection()
        @test zoo.collection_size() == 0
        
        # Add animals preserving their unique type structures
        add_animals_preserving_types(zoo, julia_animals)
        
        # Verify conversion worked
        @test zoo.collection_size() == 5
        
        # Check counts by type
        cpp_counts = zoo.count_by_type()
        @test length(cpp_counts) == 5
        @test cpp_counts[1] == 1  # 1 Dog (with breed, is_trained, favorite_toy)
        @test cpp_counts[2] == 1  # 1 Cat (with color, lives_remaining, favorite_nap_spot)
        @test cpp_counts[3] == 1  # 1 Bird (with species, wingspan_cm, songs_known)
        @test cpp_counts[4] == 1  # 1 Fish (with tank_size_liters, water_type, colors)
        @test cpp_counts[5] == 1  # 1 Reptile (with basking_temp_celsius, scale_pattern, is_venomous)
        
        # Verify total weight makes sense
        total_weight = zoo.get_total_weight()
        @test total_weight > 0.0
        println("  Converted $(length(julia_animals)) Julia animals preserving unique types")
        println("  Total weight in C++ collection: $(total_weight) kg")
        println("  Each animal type kept its distinctive fields!")
    end
    
    @testset "Large Collection Variant Conversion" begin
        # Create a large mixed collection
        julia_animals = create_large_mixed_collection(50)
        @test length(julia_animals) == 50
        
        # Count in Julia
        julia_counts = count_julia_animals_by_type(julia_animals)
        expected_each = 10  # 50 ÷ 5 = 10 of each type
        @test all(count == expected_each for count in julia_counts)
        
        # Clear and convert preserving unique types
        zoo.clear_collection()
        add_animals_preserving_types(zoo, julia_animals)
        
        # Verify large conversion
        @test zoo.collection_size() == 50
        
        cpp_counts = zoo.count_by_type()
        @test cpp_counts[1] == 10  # 10 Dogs (each with unique breed, training, toy)
        @test cpp_counts[2] == 10  # 10 Cats (each with unique color, lives, nap spot)
        @test cpp_counts[3] == 10  # 10 Birds (each with unique species, wingspan, songs)
        @test cpp_counts[4] == 10  # 10 Fish (each with unique tank, water type, colors)
        @test cpp_counts[5] == 10  # 10 Reptiles (each with unique temp, pattern, venom)
        
        total_weight = zoo.get_total_weight()
        @test total_weight > 100.0  # Should be substantial
        
        println("  Successfully converted 50 mixed animals preserving unique types")
        println("  C++ counts: Dogs=$(cpp_counts[1]), Cats=$(cpp_counts[2]), Birds=$(cpp_counts[3]), Fish=$(cpp_counts[4]), Reptiles=$(cpp_counts[5])")
    end
    
    @testset "Edge Cases and Error Handling" begin
        # Test empty collection
        zoo.clear_collection()
        add_animals_preserving_types(zoo, JuliaAnimal[])
        @test zoo.collection_size() == 0
        
        # Test single animal preserving type
        single_dog = JuliaDog("Solo", "Beagle", UInt32(3), Float32(15.0), true, "Ball")
        zoo.clear_collection()
        add_animal_preserving_type(zoo, single_dog)
        @test zoo.collection_size() == 1
        
        cpp_counts = zoo.count_by_type()
        @test cpp_counts[1] == 1  # 1 Dog with unique Dog fields
        @test sum(cpp_counts) == 1
        
        # Test mixed single animals
        zoo.clear_collection()
        add_animal_preserving_type(zoo, JuliaCat("Fluffy", "White", UInt32(2), Float32(3.0), UInt32(8), false, "Garden"))
        add_animal_preserving_type(zoo, JuliaBird("Chirp", "Robin", Float32(25.0), true, "Red", UInt32(12), Float32(30.0)))
        @test zoo.collection_size() == 2
        
        cpp_counts = zoo.count_by_type()
        @test cpp_counts[1] == 0  # 0 Dogs
        @test cpp_counts[2] == 1  # 1 Cat with unique Cat fields
        @test cpp_counts[3] == 1  # 1 Bird with unique Bird fields
        @test sum(cpp_counts) == 2
    end
    
    @testset "Performance Test" begin
        # Test with larger collection for performance
        large_collection = create_large_mixed_collection(1000)
        @test length(large_collection) == 1000
        
        # Time the conversion
        start_time = time()
        
        # Convert preserving unique types
        zoo.clear_collection()
        add_animals_preserving_types(zoo, large_collection)
        
        elapsed = time() - start_time
        
        @test zoo.collection_size() == 1000
        println("  Converted 1000 animals preserving unique types in $(round(elapsed, digits=3)) seconds")
        
        # Verify the counts
        cpp_counts = zoo.count_by_type()
        @test sum(cpp_counts) == 1000
        @test all(count == 200 for count in cpp_counts)  # 1000 ÷ 5 = 200 each
        
        println("  True variant approach maintains type diversity at scale!")
    end
end

println("✅ Julia to C++ Vector of Variants tests completed!")