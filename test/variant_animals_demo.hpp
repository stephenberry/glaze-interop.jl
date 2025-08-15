#pragma once

#include <glaze/interop/interop.hpp>
#include <variant>
#include <string>
#include <cstdint>
#include <vector>

// Different animal types with unique characteristics
struct Dog {
    std::string name = "Buddy";
    std::string breed = "Golden Retriever";
    uint32_t age_years = 3;
    float weight_kg = 30.5f;
    bool is_trained = true;
    std::string favorite_toy = "Tennis ball";
    
    // Auto spaceship operator for comparison
    auto operator<=>(const Dog& other) const = default;
};

struct Cat {
    std::string name = "Whiskers";
    std::string color = "Orange Tabby";
    uint32_t age_years = 2;
    float weight_kg = 4.5f;
    uint32_t lives_remaining = 9;
    bool is_indoor = true;
    std::string favorite_nap_spot = "Sunny windowsill";
    
    // Auto spaceship operator for comparison
    auto operator<=>(const Cat& other) const = default;
};

struct Bird {
    std::string name = "Tweety";
    std::string species = "Canary";
    float wingspan_cm = 20.0f;
    bool can_fly = true;
    std::string feather_color = "Yellow";
    uint32_t songs_known = 5;
    float flight_speed_kmh = 25.0f;
    
    // Auto spaceship operator for comparison
    auto operator<=>(const Bird& other) const = default;
};

struct Fish {
    std::string name = "Nemo";
    std::string species = "Clownfish";
    float length_cm = 8.0f;
    std::string water_type = "Saltwater";
    uint32_t tank_size_liters = 100;
    float swimming_depth_preference_m = 1.5f;
    std::string primary_color = "Orange";
    std::string secondary_color = "White";
    
    // Auto spaceship operator for comparison
    auto operator<=>(const Fish& other) const = default;
};

struct Reptile {
    std::string name = "Spike";
    std::string species = "Bearded Dragon";
    float length_cm = 45.0f;
    float basking_temp_celsius = 38.0f;
    bool is_venomous = false;
    std::string scale_pattern = "Spiky";
    uint32_t shedding_frequency_per_year = 4;
    std::string habitat_type = "Desert";
    
    // Auto spaceship operator for comparison
    auto operator<=>(const Reptile& other) const = default;
};

// Variant type that can hold any animal
using AnimalVariant = std::variant<Dog, Cat, Bird, Fish, Reptile>;

// Zoo container that manages multiple animals
struct Zoo {
    AnimalVariant featured_animal;
    AnimalVariant newest_resident;
    std::vector<std::string> animal_sounds;
    std::vector<AnimalVariant> all_animals;  // Vector of variants for testing
    
    // Constructor - starts with a default dog
    Zoo() {
        featured_animal = Dog{.name = "Max", .breed = "Labrador", .age_years = 5, .weight_kg = 32.0f, .is_trained = true, .favorite_toy = "Frisbee"};
        newest_resident = Cat{.name = "Luna", .color = "Black", .age_years = 1, .weight_kg = 3.5f, .lives_remaining = 9, .is_indoor = true, .favorite_nap_spot = "Cozy bed"};
        animal_sounds = {"Woof!", "Meow!", "Tweet!", "Blub!", "Hiss!"};
        all_animals.reserve(10);  // Reserve space for efficiency
    }
    
    // Methods to add different animals
    void add_dog(const std::string& name, const std::string& breed, uint32_t age, float weight, bool trained, const std::string& toy) {
        featured_animal = Dog{.name = name, .breed = breed, .age_years = age, .weight_kg = weight, .is_trained = trained, .favorite_toy = toy};
    }
    
    void add_cat(const std::string& name, const std::string& color, uint32_t age, float weight, uint32_t lives, bool indoor, const std::string& nap_spot) {
        featured_animal = Cat{.name = name, .color = color, .age_years = age, .weight_kg = weight, .lives_remaining = lives, .is_indoor = indoor, .favorite_nap_spot = nap_spot};
    }
    
    void add_bird(const std::string& name, const std::string& species, float wingspan, bool can_fly, const std::string& color, uint32_t songs, float speed) {
        featured_animal = Bird{.name = name, .species = species, .wingspan_cm = wingspan, .can_fly = can_fly, .feather_color = color, .songs_known = songs, .flight_speed_kmh = speed};
    }
    
    void add_fish(const std::string& name, const std::string& species, float length, const std::string& water, uint32_t tank_size, float depth, const std::string& color1, const std::string& color2) {
        featured_animal = Fish{.name = name, .species = species, .length_cm = length, .water_type = water, .tank_size_liters = tank_size, .swimming_depth_preference_m = depth, .primary_color = color1, .secondary_color = color2};
    }
    
    void add_reptile(const std::string& name, const std::string& species, float length, float temp, bool venomous, const std::string& pattern, uint32_t shedding, const std::string& habitat) {
        featured_animal = Reptile{.name = name, .species = species, .length_cm = length, .basking_temp_celsius = temp, .is_venomous = venomous, .scale_pattern = pattern, .shedding_frequency_per_year = shedding, .habitat_type = habitat};
    }
    
    // Get current animal type index
    int get_featured_animal_index() const { return static_cast<int>(featured_animal.index()); }
    int get_newest_resident_index() const { return static_cast<int>(newest_resident.index()); }
    
    // Get animal variants
    AnimalVariant get_featured_animal() const { return featured_animal; }
    AnimalVariant get_newest_resident() const { return newest_resident; }
    
    // Set animals from variant
    void set_featured_animal(const AnimalVariant& animal) { featured_animal = animal; }
    void set_newest_resident(const AnimalVariant& animal) { newest_resident = animal; }
    
    // Swap animals
    void swap_animals() {
        std::swap(featured_animal, newest_resident);
    }
    
    // Animal type checking methods
    bool has_dog() const { return featured_animal.index() == 0; }
    bool has_cat() const { return featured_animal.index() == 1; }
    bool has_bird() const { return featured_animal.index() == 2; }
    bool has_fish() const { return featured_animal.index() == 3; }
    bool has_reptile() const { return featured_animal.index() == 4; }
    
    // Get animal description
    std::string get_animal_description() const {
        switch(featured_animal.index()) {
            case 0: {
                auto& dog = std::get<Dog>(featured_animal);
                return dog.name + " the " + dog.breed + " (Dog)";
            }
            case 1: {
                auto& cat = std::get<Cat>(featured_animal);
                return cat.name + " the " + cat.color + " (Cat)";
            }
            case 2: {
                auto& bird = std::get<Bird>(featured_animal);
                return bird.name + " the " + bird.species + " (Bird)";
            }
            case 3: {
                auto& fish = std::get<Fish>(featured_animal);
                return fish.name + " the " + fish.species + " (Fish)";
            }
            case 4: {
                auto& reptile = std::get<Reptile>(featured_animal);
                return reptile.name + " the " + reptile.species + " (Reptile)";
            }
            default:
                return "Unknown Animal";
        }
    }
    
    // Get animal sound
    std::string make_sound() const {
        if (featured_animal.index() < animal_sounds.size()) {
            return animal_sounds[featured_animal.index()];
        }
        return "...";
    }
    
    // Get feeding time info
    std::string get_feeding_info() const {
        switch(featured_animal.index()) {
            case 0: return "Dogs eat twice daily - morning and evening";
            case 1: return "Cats prefer small frequent meals throughout the day";
            case 2: return "Birds need fresh seeds and water daily";
            case 3: return "Fish are fed once or twice daily in small amounts";
            case 4: return "Reptiles eat every 2-3 days depending on species";
            default: return "Unknown feeding schedule";
        }
    }
    
    // Count total animals (for this demo, always 2)
    int count_animals() const { return 2; }
    
    // === Vector of variants operations ===
    
    // Add an animal to the collection
    void add_to_collection(const AnimalVariant& animal) {
        all_animals.push_back(animal);
    }
    
    // Add the current featured animal to collection
    void add_featured_to_collection() {
        all_animals.push_back(featured_animal);
    }
    
    // Add animals by creating them directly in the collection
    void add_dog_to_collection(const std::string& name, const std::string& breed, uint32_t age, float weight, bool trained, const std::string& toy) {
        all_animals.emplace_back(Dog{.name = name, .breed = breed, .age_years = age, .weight_kg = weight, .is_trained = trained, .favorite_toy = toy});
    }
    
    void add_cat_to_collection(const std::string& name, const std::string& color, uint32_t age, float weight, uint32_t lives, bool indoor, const std::string& nap_spot) {
        all_animals.emplace_back(Cat{.name = name, .color = color, .age_years = age, .weight_kg = weight, .lives_remaining = lives, .is_indoor = indoor, .favorite_nap_spot = nap_spot});
    }
    
    void add_bird_to_collection(const std::string& name, const std::string& species, float wingspan, bool can_fly, const std::string& color, uint32_t songs, float speed) {
        all_animals.emplace_back(Bird{.name = name, .species = species, .wingspan_cm = wingspan, .can_fly = can_fly, .feather_color = color, .songs_known = songs, .flight_speed_kmh = speed});
    }
    
    void add_fish_to_collection(const std::string& name, const std::string& species, float length, const std::string& water, uint32_t tank_size, float depth, const std::string& color1, const std::string& color2) {
        all_animals.emplace_back(Fish{.name = name, .species = species, .length_cm = length, .water_type = water, .tank_size_liters = tank_size, .swimming_depth_preference_m = depth, .primary_color = color1, .secondary_color = color2});
    }
    
    void add_reptile_to_collection(const std::string& name, const std::string& species, float length, float temp, bool venomous, const std::string& pattern, uint32_t shedding, const std::string& habitat) {
        all_animals.emplace_back(Reptile{.name = name, .species = species, .length_cm = length, .basking_temp_celsius = temp, .is_venomous = venomous, .scale_pattern = pattern, .shedding_frequency_per_year = shedding, .habitat_type = habitat});
    }
    
    // === Direct Animal Type Functions ===
    
    // Add animals directly by type, preserving their unique structures
    void add_dog_from_json(const std::string& json_data) {
        try {
            Dog dog;
            auto error = glz::read_json(dog, json_data);
            if (!error) {
                all_animals.emplace_back(std::move(dog));
            }
        } catch (...) {}
    }
    
    void add_cat_from_json(const std::string& json_data) {
        try {
            Cat cat;
            auto error = glz::read_json(cat, json_data);
            if (!error) {
                all_animals.emplace_back(std::move(cat));
            }
        } catch (...) {}
    }
    
    void add_bird_from_json(const std::string& json_data) {
        try {
            Bird bird;
            auto error = glz::read_json(bird, json_data);
            if (!error) {
                all_animals.emplace_back(std::move(bird));
            }
        } catch (...) {}
    }
    
    void add_fish_from_json(const std::string& json_data) {
        try {
            Fish fish;
            auto error = glz::read_json(fish, json_data);
            if (!error) {
                all_animals.emplace_back(std::move(fish));
            }
        } catch (...) {}
    }
    
    void add_reptile_from_json(const std::string& json_data) {
        try {
            Reptile reptile;
            auto error = glz::read_json(reptile, json_data);
            if (!error) {
                all_animals.emplace_back(std::move(reptile));
            }
        } catch (...) {}
    }
    
    // Even better - direct variant JSON conversion
    void add_animals_from_variant_json(const std::string& json_data) {
        try {
            std::vector<AnimalVariant> animals;
            auto error = glz::read_json(animals, json_data);
            if (!error) {
                for (const auto& animal : animals) {
                    all_animals.push_back(animal);
                }
            }
        } catch (...) {
            // Ignore JSON parsing errors for now
        }
    }
    
    // Clear the collection
    void clear_collection() {
        all_animals.clear();
    }
    
    // Get collection size
    int collection_size() const {
        return static_cast<int>(all_animals.size());
    }
    
    // Set entire collection from a vector
    void set_animal_collection(const std::vector<AnimalVariant>& animals) {
        all_animals = animals;
    }
    
    // Get the entire collection
    std::vector<AnimalVariant> get_animal_collection() const {
        return all_animals;
    }
    
    // Get a summary of all animals in collection
    std::vector<std::string> get_collection_summary() const {
        std::vector<std::string> summaries;
        for (const auto& animal : all_animals) {
            std::string summary;
            switch(animal.index()) {
                case 0: {
                    auto& dog = std::get<Dog>(animal);
                    summary = dog.name + " (Dog, " + dog.breed + ")";
                    break;
                }
                case 1: {
                    auto& cat = std::get<Cat>(animal);
                    summary = cat.name + " (Cat, " + cat.color + ")";
                    break;
                }
                case 2: {
                    auto& bird = std::get<Bird>(animal);
                    summary = bird.name + " (Bird, " + bird.species + ")";
                    break;
                }
                case 3: {
                    auto& fish = std::get<Fish>(animal);
                    summary = fish.name + " (Fish, " + fish.species + ")";
                    break;
                }
                case 4: {
                    auto& reptile = std::get<Reptile>(animal);
                    summary = reptile.name + " (Reptile, " + reptile.species + ")";
                    break;
                }
                default:
                    summary = "Unknown Animal";
            }
            summaries.push_back(summary);
        }
        return summaries;
    }
    
    // Count animals by type in collection
    std::vector<int> count_by_type() const {
        std::vector<int> counts(5, 0);  // 5 animal types
        for (const auto& animal : all_animals) {
            if (animal.index() < 5) {
                counts[animal.index()]++;
            }
        }
        return counts;
    }
    
    // Get total weight of all animals in collection
    float get_total_weight() const {
        float total = 0.0f;
        for (const auto& animal : all_animals) {
            switch(animal.index()) {
                case 0: total += std::get<Dog>(animal).weight_kg; break;
                case 1: total += std::get<Cat>(animal).weight_kg; break;
                case 2: total += 0.1f; break;  // Birds are light, estimate
                case 3: total += 0.01f; break; // Fish weight in water
                case 4: total += 2.0f; break;  // Reptile estimate
            }
        }
        return total;
    }
};

// Global instance for testing (declared in cpp file)
extern Zoo global_zoo;

// Initialization function
extern "C" __attribute__((visibility("default"))) void init_animals_demo();

// Glaze metadata for all structs
template<>
struct glz::meta<Dog> {
    using T = Dog;
    static constexpr auto value = object(
        "name", &T::name,
        "breed", &T::breed,
        "age_years", &T::age_years,
        "weight_kg", &T::weight_kg,
        "is_trained", &T::is_trained,
        "favorite_toy", &T::favorite_toy
    );
};

template<>
struct glz::meta<Cat> {
    using T = Cat;
    static constexpr auto value = object(
        "name", &T::name,
        "color", &T::color,
        "age_years", &T::age_years,
        "weight_kg", &T::weight_kg,
        "lives_remaining", &T::lives_remaining,
        "is_indoor", &T::is_indoor,
        "favorite_nap_spot", &T::favorite_nap_spot
    );
};

template<>
struct glz::meta<Bird> {
    using T = Bird;
    static constexpr auto value = object(
        "name", &T::name,
        "species", &T::species,
        "wingspan_cm", &T::wingspan_cm,
        "can_fly", &T::can_fly,
        "feather_color", &T::feather_color,
        "songs_known", &T::songs_known,
        "flight_speed_kmh", &T::flight_speed_kmh
    );
};

template<>
struct glz::meta<Fish> {
    using T = Fish;
    static constexpr auto value = object(
        "name", &T::name,
        "species", &T::species,
        "length_cm", &T::length_cm,
        "water_type", &T::water_type,
        "tank_size_liters", &T::tank_size_liters,
        "swimming_depth_preference_m", &T::swimming_depth_preference_m,
        "primary_color", &T::primary_color,
        "secondary_color", &T::secondary_color
    );
};

template<>
struct glz::meta<Reptile> {
    using T = Reptile;
    static constexpr auto value = object(
        "name", &T::name,
        "species", &T::species,
        "length_cm", &T::length_cm,
        "basking_temp_celsius", &T::basking_temp_celsius,
        "is_venomous", &T::is_venomous,
        "scale_pattern", &T::scale_pattern,
        "shedding_frequency_per_year", &T::shedding_frequency_per_year,
        "habitat_type", &T::habitat_type
    );
};


template<>
struct glz::meta<Zoo> {
    using T = Zoo;
    static constexpr auto value = object(
        "featured_animal", &T::featured_animal,
        "newest_resident", &T::newest_resident,
        "animal_sounds", &T::animal_sounds,
        "all_animals", &T::all_animals,
        "add_dog", &T::add_dog,
        "add_cat", &T::add_cat,
        "add_bird", &T::add_bird,
        "add_fish", &T::add_fish,
        "add_reptile", &T::add_reptile,
        "get_featured_animal_index", &T::get_featured_animal_index,
        "get_newest_resident_index", &T::get_newest_resident_index,
        "get_featured_animal", &T::get_featured_animal,
        "get_newest_resident", &T::get_newest_resident,
        "set_featured_animal", &T::set_featured_animal,
        "set_newest_resident", &T::set_newest_resident,
        "swap_animals", &T::swap_animals,
        "has_dog", &T::has_dog,
        "has_cat", &T::has_cat,
        "has_bird", &T::has_bird,
        "has_fish", &T::has_fish,
        "has_reptile", &T::has_reptile,
        "get_animal_description", &T::get_animal_description,
        "make_sound", &T::make_sound,
        "get_feeding_info", &T::get_feeding_info,
        "count_animals", &T::count_animals,
        "add_to_collection", &T::add_to_collection,
        "add_featured_to_collection", &T::add_featured_to_collection,
        "add_dog_to_collection", &T::add_dog_to_collection,
        "add_cat_to_collection", &T::add_cat_to_collection,
        "add_bird_to_collection", &T::add_bird_to_collection,
        "add_fish_to_collection", &T::add_fish_to_collection,
        "add_reptile_to_collection", &T::add_reptile_to_collection,
        "clear_collection", &T::clear_collection,
        "collection_size", &T::collection_size,
        "set_animal_collection", &T::set_animal_collection,
        "get_animal_collection", &T::get_animal_collection,
        "get_collection_summary", &T::get_collection_summary,
        "count_by_type", &T::count_by_type,
        "get_total_weight", &T::get_total_weight,
        "add_dog_from_json", &T::add_dog_from_json,
        "add_cat_from_json", &T::add_cat_from_json,
        "add_bird_from_json", &T::add_bird_from_json,
        "add_fish_from_json", &T::add_fish_from_json,
        "add_reptile_from_json", &T::add_reptile_from_json,
        "add_animals_from_variant_json", &T::add_animals_from_variant_json
    );
};