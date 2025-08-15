# Julia struct definitions that mirror the C++ animal types
# These will be used to create vectors in Julia that can be converted to C++ std::vector<std::variant>

struct JuliaDog
    name::String
    breed::String
    age_years::UInt32
    weight_kg::Float32
    is_trained::Bool
    favorite_toy::String
end

struct JuliaCat
    name::String
    color::String
    age_years::UInt32
    weight_kg::Float32
    lives_remaining::UInt32
    is_indoor::Bool
    favorite_nap_spot::String
end

struct JuliaBird
    name::String
    species::String
    wingspan_cm::Float32
    can_fly::Bool
    feather_color::String
    songs_known::UInt32
    flight_speed_kmh::Float32
end

struct JuliaFish
    name::String
    species::String
    length_cm::Float32
    water_type::String
    tank_size_liters::UInt32
    swimming_depth_preference_m::Float32
    primary_color::String
    secondary_color::String
end

struct JuliaReptile
    name::String
    species::String
    length_cm::Float32
    basking_temp_celsius::Float32
    is_venomous::Bool
    scale_pattern::String
    shedding_frequency_per_year::UInt32
    habitat_type::String
end

# Union type for creating vectors of mixed animals
const JuliaAnimal = Union{JuliaDog, JuliaCat, JuliaBird, JuliaFish, JuliaReptile}

# Helper function to create a mixed vector of animals
function create_sample_animals()::Vector{JuliaAnimal}
    return JuliaAnimal[
        JuliaDog("Buddy", "Golden Retriever", UInt32(4), 28.5f0, true, "Tennis Ball"),
        JuliaCat("Whiskers", "Tabby", UInt32(3), 4.2f0, UInt32(9), true, "Windowsill"),
        JuliaBird("Tweety", "Canary", 18.0f0, true, "Yellow", UInt32(7), 22.0f0),
        JuliaFish("Nemo", "Clownfish", 8.5f0, "Saltwater", UInt32(150), 1.2f0, "Orange", "White"),
        JuliaReptile("Rex", "Iguana", 45.0f0, 35.5f0, false, "Scaly", UInt32(3), "Tropical")
    ]
end

function create_large_mixed_collection(count::Int)::Vector{JuliaAnimal}
    animals = JuliaAnimal[]
    
    for i in 1:count
        # Rotate through different animal types
        animal = if i % 5 == 1
            JuliaDog("Dog$i", "Mixed", UInt32(i % 8 + 1), Float32(10 + i), i % 2 == 0, "Toy$i")
        elseif i % 5 == 2  
            JuliaCat("Cat$i", "Tabby", UInt32(i % 6 + 1), Float32(3 + i * 0.1), UInt32(9), i % 3 == 0, "Spot$i")
        elseif i % 5 == 3
            JuliaBird("Bird$i", "Sparrow", Float32(15 + i), i % 4 != 0, "Brown", UInt32(i % 10), Float32(20 + i))
        elseif i % 5 == 4
            JuliaFish("Fish$i", "Goldfish", Float32(8 + i * 0.5), "Freshwater", UInt32(50 + i * 10), Float32(0.5 + i * 0.1), "Gold", "White")
        else
            JuliaReptile("Reptile$i", "Gecko", Float32(20 + i), Float32(30 + i * 0.2), false, "Spotted", UInt32(2 + i % 5), "Desert")
        end
        
        push!(animals, animal)
    end
    
    return animals
end

# Function to get animal type as string (for debugging)
function get_animal_type(animal::JuliaAnimal)::String
    if animal isa JuliaDog
        return "Dog"
    elseif animal isa JuliaCat
        return "Cat"
    elseif animal isa JuliaBird  
        return "Bird"
    elseif animal isa JuliaFish
        return "Fish"
    elseif animal isa JuliaReptile
        return "Reptile"
    else
        return "Unknown"
    end
end

# Function to get animal name (for debugging)
function get_animal_name(animal::JuliaAnimal)::String
    return animal.name
end

# Function to count animals by type in Julia vector
function count_julia_animals_by_type(animals::Vector{JuliaAnimal})::Vector{Int}
    counts = [0, 0, 0, 0, 0]  # Dog, Cat, Bird, Fish, Reptile
    
    for animal in animals
        if animal isa JuliaDog
            counts[1] += 1
        elseif animal isa JuliaCat
            counts[2] += 1
        elseif animal isa JuliaBird
            counts[3] += 1
        elseif animal isa JuliaFish
            counts[4] += 1
        elseif animal isa JuliaReptile
            counts[5] += 1
        end
    end
    
    return counts
end

# Direct JSON conversion functions that preserve unique animal structures
function julia_animal_to_json(animal::JuliaAnimal)::String
    if animal isa JuliaDog
        return """{"name":"$(animal.name)","breed":"$(animal.breed)","age_years":$(animal.age_years),"weight_kg":$(animal.weight_kg),"is_trained":$(animal.is_trained ? "true" : "false"),"favorite_toy":"$(animal.favorite_toy)"}"""
    elseif animal isa JuliaCat
        return """{"name":"$(animal.name)","color":"$(animal.color)","age_years":$(animal.age_years),"weight_kg":$(animal.weight_kg),"lives_remaining":$(animal.lives_remaining),"is_indoor":$(animal.is_indoor ? "true" : "false"),"favorite_nap_spot":"$(animal.favorite_nap_spot)"}"""
    elseif animal isa JuliaBird
        return """{"name":"$(animal.name)","species":"$(animal.species)","wingspan_cm":$(animal.wingspan_cm),"can_fly":$(animal.can_fly ? "true" : "false"),"feather_color":"$(animal.feather_color)","songs_known":$(animal.songs_known),"flight_speed_kmh":$(animal.flight_speed_kmh)}"""
    elseif animal isa JuliaFish
        return """{"name":"$(animal.name)","species":"$(animal.species)","length_cm":$(animal.length_cm),"water_type":"$(animal.water_type)","tank_size_liters":$(animal.tank_size_liters),"swimming_depth_preference_m":$(animal.swimming_depth_preference_m),"primary_color":"$(animal.primary_color)","secondary_color":"$(animal.secondary_color)"}"""
    elseif animal isa JuliaReptile
        return """{"name":"$(animal.name)","species":"$(animal.species)","length_cm":$(animal.length_cm),"basking_temp_celsius":$(animal.basking_temp_celsius),"is_venomous":$(animal.is_venomous ? "true" : "false"),"scale_pattern":"$(animal.scale_pattern)","shedding_frequency_per_year":$(animal.shedding_frequency_per_year),"habitat_type":"$(animal.habitat_type)"}"""
    else
        error("Unknown animal type: $(typeof(animal))")
    end
end

# Function to add an animal preserving its unique type structure
function add_animal_preserving_type(zoo, animal::JuliaAnimal)
    json_data = julia_animal_to_json(animal)
    
    if animal isa JuliaDog
        zoo.add_dog_from_json(json_data)
    elseif animal isa JuliaCat
        zoo.add_cat_from_json(json_data) 
    elseif animal isa JuliaBird
        zoo.add_bird_from_json(json_data)
    elseif animal isa JuliaFish
        zoo.add_fish_from_json(json_data)
    elseif animal isa JuliaReptile
        zoo.add_reptile_from_json(json_data)
    end
end

# Batch function to add multiple animals preserving their types
function add_animals_preserving_types(zoo, animals::Vector{JuliaAnimal})
    for animal in animals
        add_animal_preserving_type(zoo, animal)
    end
end