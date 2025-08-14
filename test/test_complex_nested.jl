# Test complex nested structures and vectors of structs
# Using existing Person/Address types from test library

@testset "Complex Nested Structures" begin
    # Test nested structures with Person and Address
    @testset "Nested struct access" begin
        # Create a Person with nested Address
        person = lib.Person
        person.name = "John Doe"
        person.age = 30
        
        # Test nested Address struct
        person.address.street = "123 Main St"
        person.address.city = "New York"
        person.address.zipcode = 10001
        
        @test String(person.name) == "John Doe"
        @test person.age == 30
        @test String(person.address.street) == "123 Main St"
        @test String(person.address.city) == "New York"
        @test person.address.zipcode == 10001
    end
    
    @testset "Vectors in nested structures" begin
        person = lib.Person
        
        # Clear and populate scores vector
        resize!(person.scores, 0)
        
        # Add scores
        push!(person.scores, 85)
        push!(person.scores, 90)
        push!(person.scores, 95)
        push!(person.scores, 88)
        
        @test length(person.scores) == 4
        @test person.scores[1] == 85
        @test person.scores[2] == 90
        @test person.scores[3] == 95
        @test person.scores[4] == 88
        
        # Calculate average score
        total = sum(person.scores[i] for i in 1:length(person.scores))
        avg = total / length(person.scores)
        @test avg ≈ 89.5
    end
    
    @testset "Modifying nested fields" begin
        person = lib.Person
        
        # Modify nested address fields
        original_zip = person.address.zipcode
        person.address.zipcode = 20001
        @test person.address.zipcode == 20001
        @test person.address.zipcode ≠ original_zip
        
        person.address.city = "Washington DC"
        @test String(person.address.city) == "Washington DC"
        
        # Modify scores vector
        if length(person.scores) > 0
            original_score = person.scores[1]
            person.scores[1] = 100
            @test person.scores[1] == 100
            @test person.scores[1] ≠ original_score
        end
    end
    
    @testset "Multiple Person instances" begin
        # Test creating and managing multiple Person instances
        person1 = lib.Person
        person1.name = "Alice"
        person1.age = 25
        person1.address.city = "Boston"
        
        person2 = lib.Person  
        person2.name = "Bob"
        person2.age = 35
        person2.address.city = "Seattle"
        
        # Verify they are independent
        @test String(person1.name) == "Alice"
        @test String(person2.name) == "Bob"
        @test person1.age == 25
        @test person2.age == 35
    end
    
    @testset "OptionalNestedStruct tests" begin
        # Test optional nested structures
        opt_nested = lib.OptionalNestedStruct
        opt_nested.name = "Test User"
        
        # Test when optional address is not set
        @test String(opt_nested.name) == "Test User"
        
        # Set optional address
        if isdefined(opt_nested, :opt_address) && !isnothing(opt_nested.opt_address)
            opt_nested.opt_address.street = "456 Oak Ave"
            opt_nested.opt_address.city = "Chicago"
            opt_nested.opt_address.zipcode = 60601
            
            @test String(opt_nested.opt_address.street) == "456 Oak Ave"
            @test String(opt_nested.opt_address.city) == "Chicago"
            @test opt_nested.opt_address.zipcode == 60601
        end
        
        # Test optional vector
        if isdefined(opt_nested, :opt_scores) && !isnothing(opt_nested.opt_scores)
            push!(opt_nested.opt_scores, 75)
            push!(opt_nested.opt_scores, 82)
            @test length(opt_nested.opt_scores) >= 2
        end
    end
end