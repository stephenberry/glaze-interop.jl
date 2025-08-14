# Test for map types (std::unordered_map)
# Using TestMapTypes from test_map_types.hpp

@testset "Map Types" begin
    @testset "String to Int32 Map" begin
        data = lib.TestMapTypes
        
        # Access and modify map
        data.string_to_int["Alice"] = 1
        data.string_to_int["Bob"] = 2
        data.string_to_int["Charlie"] = 3
        
        @test data.string_to_int["Alice"] == 1
        @test data.string_to_int["Bob"] == 2
        @test data.string_to_int["Charlie"] == 3
        
        # Check size
        @test length(data.string_to_int) == 3
        
        # Modify existing entry
        data.string_to_int["Alice"] = 100
        @test data.string_to_int["Alice"] == 100
        
        # Check if key exists
        @test haskey(data.string_to_int, "Bob")
        @test !haskey(data.string_to_int, "David")
    end
    
    @testset "String to Vector<Float> Map" begin
        data = lib.TestMapTypes
        
        # Create vector for first key
        data.string_to_vec_float["dataset1"] = Float32[1.0, 2.0, 3.0]
        data.string_to_vec_float["dataset2"] = Float32[4.0, 5.0]
        
        @test length(data.string_to_vec_float["dataset1"]) == 3
        @test length(data.string_to_vec_float["dataset2"]) == 2
        @test data.string_to_vec_float["dataset1"][1] ≈ 1.0f0
        @test data.string_to_vec_float["dataset2"][2] ≈ 5.0f0
        
        # Modify vector in map
        push!(data.string_to_vec_float["dataset1"], 4.0f0)
        @test length(data.string_to_vec_float["dataset1"]) == 4
        @test data.string_to_vec_float["dataset1"][4] ≈ 4.0f0
    end
    
    @testset "Map iteration" begin
        data = lib.TestMapTypes
        
        # Clear and repopulate
        empty!(data.string_to_int)
        data.string_to_int["First"] = 10
        data.string_to_int["Second"] = 20
        data.string_to_int["Third"] = 30
        
        # Iterate over map
        total = 0
        for (key, value) in data.string_to_int
            total += value
            @test value > 0
        end
        @test total == 60
        
        # Get all keys
        keys_list = collect(keys(data.string_to_int))
        @test length(keys_list) == 3
        @test "First" in keys_list
        @test "Second" in keys_list
        @test "Third" in keys_list
        
        # Get all values
        values_list = collect(values(data.string_to_int))
        @test length(values_list) == 3
        @test 10 in values_list
        @test 20 in values_list
        @test 30 in values_list
    end
    
    @testset "Map deletion" begin
        data = lib.TestMapTypes
        
        # Add and remove entries
        data.string_to_int["ToDelete"] = 999
        @test haskey(data.string_to_int, "ToDelete")
        
        delete!(data.string_to_int, "ToDelete")
        @test !haskey(data.string_to_int, "ToDelete")
        
        # Clear entire map
        data.string_to_int["A"] = 1
        data.string_to_int["B"] = 2
        @test length(data.string_to_int) > 0
        
        empty!(data.string_to_int)
        @test length(data.string_to_int) == 0
    end
end