# Test file for Person construction and assignment through Glaze.jl interface
# This file tests creating Person objects in Julia and assigning them to registered instances

using Test
using Glaze

@testset "Person Construction and Assignment" begin
    # Get the test library that should already be loaded
    lib = test_lib_for_all_types
    
    @testset "Person Construction in Julia" begin
        # Create a new Person instance in Julia
        person = lib.Person
        
        @test isa(person, Glaze.CppStruct)
        
        # Test setting basic properties
        person.name = "Alice Smith"
        person.age = 25
        
        @test person.name == "Alice Smith"
        @test person.age == 25
        
        # Test nested Address construction
        person.address.street = "456 Oak Ave"
        person.address.city = "San Francisco"  
        person.address.zipcode = 94102
        
        @test person.address.street == "456 Oak Ave"
        @test person.address.city == "San Francisco"
        @test person.address.zipcode == 94102
        
        # Test vector operations
        resize!(person.scores, 4)
        person.scores[1] = 88
        person.scores[2] = 92
        person.scores[3] = 95
        person.scores[4] = 90
        
        @test length(person.scores) == 4
        @test person.scores[1] == 88
        @test person.scores[2] == 92
        @test person.scores[3] == 95
        @test person.scores[4] == 90
        
        # Test push! operation
        push!(person.scores, 94)
        @test length(person.scores) == 5
        @test person.scores[5] == 94
    end
    
    @testset "Accessing Global Person Instances" begin
        # Test accessing the pre-registered global person
        global_person = Glaze.get_instance(lib, "global_person")
        
        @test global_person.name == "John Doe"
        @test global_person.age == 30
        @test global_person.address.street == "123 Main St"
        @test global_person.address.city == "New York"
        @test global_person.address.zipcode == 10001
        @test length(global_person.scores) == 3
        @test global_person.scores[1] == 95
        @test global_person.scores[2] == 87
        @test global_person.scores[3] == 92
        
        # Test accessing the empty target person
        target_person = Glaze.get_instance(lib, "global_person_target")
        
        # Initially should be empty/default values
        @test target_person.name == ""
        @test target_person.age == 0
        @test target_person.address.street == ""
        @test target_person.address.city == ""
        @test target_person.address.zipcode == 0
        @test length(target_person.scores) == 0
    end
    
    @testset "Person Assignment to Registered Instance" begin
        # Create a new Person in Julia
        julia_person = lib.Person
        
        # Set up the Julia person with data
        julia_person.name = "Bob Wilson"
        julia_person.age = 35
        julia_person.address.street = "789 Pine St"
        julia_person.address.city = "Chicago"
        julia_person.address.zipcode = 60601
        
        resize!(julia_person.scores, 3)
        julia_person.scores[1] = 85
        julia_person.scores[2] = 91
        julia_person.scores[3] = 88
        
        # Get the target global instance
        target_person = Glaze.get_instance(lib, "global_person_target")
        
        # Now you can write assignment in multiple convenient ways:
        
        # Option 1: Using the copy! function
        copy!(target_person, julia_person)
        
        # Verify the first assignment worked
        @test target_person.name == "Bob Wilson"
        @test target_person.age == 35
        
        # Option 2: Using the @assign macro (clean syntax!)
        # Reset the target first
        target_person.name = ""
        target_person.age = 0
        
        # Now use the macro for clean assignment syntax
        Glaze.@assign target_person = julia_person
        
        # Verify the macro assignment worked  
        @test target_person.name == "Bob Wilson"
        @test target_person.age == 35
        
        # Option 3: Using the assign! function
        # Reset the target first
        target_person.name = ""
        target_person.age = 0
        
        # Use the assign! function
        Glaze.assign!(target_person, julia_person)
        
        # Final comprehensive verification (after all assignment methods)
        @test target_person.name == "Bob Wilson"
        @test target_person.age == 35
        @test target_person.address.street == "789 Pine St"
        @test target_person.address.city == "Chicago"
        @test target_person.address.zipcode == 60601
        @test length(target_person.scores) == 3
        @test target_person.scores[1] == 85
        @test target_person.scores[2] == 91
        @test target_person.scores[3] == 88
        
        # Verify that getting the instance again returns the updated data
        # (confirms the data persists in the registered instance)
        target_person2 = Glaze.get_instance(lib, "global_person_target")
        @test target_person2.name == "Bob Wilson"
        @test target_person2.age == 35
        @test target_person2.address.street == "789 Pine St"
        @test target_person2.address.city == "Chicago"
        @test target_person2.address.zipcode == 60601
    end
    
    @testset "Multiple Person Instances Independence" begin
        # Create multiple Person instances and verify they're independent
        person1 = lib.Person
        person2 = lib.Person
        
        person1.name = "Person One"
        person1.age = 20
        
        person2.name = "Person Two"
        person2.age = 40
        
        # Verify independence
        @test person1.name == "Person One"
        @test person1.age == 20
        @test person2.name == "Person Two"
        @test person2.age == 40
        
        # Modify one and ensure the other isn't affected
        person1.name = "Modified Person One"
        @test person1.name == "Modified Person One"
        @test person2.name == "Person Two"  # Should be unchanged
    end
    
    @testset "Person Pretty Printing" begin
        # Test that Person structs can be pretty printed
        person = lib.Person
        person.name = "Test User"
        person.age = 42
        person.address.street = "123 Test St"
        person.address.city = "Test City"
        person.address.zipcode = 12345
        
        resize!(person.scores, 2)
        person.scores[1] = 100
        person.scores[2] = 99
        
        # Capture the pretty printing output
        output = sprint(show, person)
        
        # Verify that the output contains expected structure
        @test occursin("Person", output)
        @test occursin("name:", output)
        @test occursin("Test User", output)
        @test occursin("age:", output)
        @test occursin("42", output)
        @test occursin("address:", output)
        @test occursin("Address", output)
        @test occursin("street:", output)
        @test occursin("123 Test St", output)
        @test occursin("scores:", output)
        @test occursin("[100, 99]", output)
    end
end