#!/usr/bin/env julia

# Example demonstrating C++ std::variant support in Glaze.jl

using Glaze

# This example assumes you have a C++ library with variant types
# For example, a struct like:
#
# struct VariantExample {
#     std::variant<int, std::string, double> data;
#     
#     void set_int(int val) { data = val; }
#     void set_string(const std::string& val) { data = val; }
#     void set_double(double val) { data = val; }
#     int get_index() const { return data.index(); }
# };

# Load your library
# lib = Glaze.load("path/to/your/library.so")

# Access a struct with variant member
# obj = lib.VariantExample

# Access the variant member
# var = obj.data

# Get information about the variant
# println("Number of alternatives: ", length(var))
# println("Currently active index: ", index(var))

# Check which alternative is active
# if holds_alternative(var, 0)
#     println("Variant holds an integer")
# elseif holds_alternative(var, 1)
#     println("Variant holds a string")
# elseif holds_alternative(var, 2)
#     println("Variant holds a double")
# end

# Get the current value
# current_value = get_value(var)
# println("Current value: ", current_value)

# Set the variant to different alternatives
# set_value!(var, 0, Int32(42))        # Set to integer
# println("After setting to int: ", get_value(var))

# set_value!(var, 1, "Hello, Variant!") # Set to string
# println("After setting to string: ", get_value(var))

# set_value!(var, 2, 3.14159)          # Set to double
# println("After setting to double: ", get_value(var))

# Use member functions that work with variants
# obj.set_int(100)
# println("After set_int(100): index=", obj.get_index(), ", value=", get_value(obj.data))

# Variants work seamlessly with Julia's multiple dispatch
function process_variant_value(var::CppVariant)
    val = get_value(var)
    if isa(val, Integer)
        println("Processing integer: ", val * 2)
    elseif isa(val, AbstractString)
        println("Processing string: ", uppercase(String(val)))
    elseif isa(val, AbstractFloat)
        println("Processing float: ", round(val, digits=2))
    else
        println("Unknown type: ", typeof(val))
    end
end

# process_variant_value(var)

# =============================================================================
# Julia-idiomatic variant interface examples
# =============================================================================

function demonstrate_idiomatic_interface()
    println("=== Julia-Idiomatic Variant Interface Examples ===\n")
    
    # Assume we have loaded the library and have a variant
    # lib = Glaze.load("path/to/library.so")  
    # container = lib.VariantContainer
    # var = container.simple_var
    
    # Safe access with tryget
    # int_result = tryget(var, Int32)
    # if int_result isa Some
    #     println("Safely got integer: ", something(int_result))
    # else
    #     println("Variant doesn't contain an Int32")
    # end
    
    # Functional tryget
    # doubled = tryget(var, Int32) do x
    #     x * 2
    # end
    # if doubled isa Some
    #     println("Doubled value: ", something(doubled))
    # end
    
    # Pattern matching  
    # result = match_variant(var,
    #     Int32 => x -> "Found an integer: $x",
    #     String => x -> "Found a string: $x",
    #     Float64 => x -> "Found a float: $x", 
    #     :_ => x -> "Found something else: $(typeof(x))"
    # )
    # println("Pattern match result: ", result)
    
    # Symbolic access (if variant supports it)
    # if hastype(var, :int32)
    #     try
    #         # Safe symbolic access
    #         int_val = tryget(var, :int32)
    #         if int_val isa Some
    #             println("Got int via symbol: ", something(int_val))
    #         end
    #         
    #         # Direct symbolic access (throws if wrong type)
    #         # var[:int32] = 999
    #         # println("Set via symbol: ", var[:int32])
    #     catch e
    #         println("Symbolic access not fully supported yet: ", e)
    #     end
    # end
    
    # Type introspection
    # types = alternative_types(var)
    # println("Available types: ", types)
    # 
    # current = current_type(var)
    # println("Current type: ", current)
    
    # Iterate over alternatives
    # println("Alternative types and indices:")
    # for (idx, typ) in alternatives(var)
    #     println("  $idx => $typ")
    # end
    
    # Union type detection
    # union_type = variant_union_type(var)
    # println("Union type: ", union_type)
    
    # Type checking
    # println("Is active Int32? ", is_active(var, Int32))
    # println("Is active String? ", is_active(var, String))
    
    println("\nThese features provide a Julia-native interface for C++ variants!")
end

# Call the demo
# demonstrate_idiomatic_interface()

println("""
This example demonstrates both traditional and idiomatic Julia interfaces for C++ variants:

Traditional Interface:
1. Accessing C++ std::variant members
2. Querying variant state (index, alternatives)  
3. Getting and setting variant values
4. Type-safe operations with variants
5. Integration with Julia's type system

Julia-Idiomatic Interface (NEW):
6. Safe access with tryget() and Some/Nothing pattern
7. Pattern matching with match_variant() function
8. Symbolic access with :type symbols
9. Union-type-like behavior
10. Iterator interface for exploring alternatives
11. Type introspection and checking functions
12. Functional programming patterns

To use this with your own C++ library:
1. Ensure your C++ types are registered with Glaze
2. Load your library with Glaze.load()
3. Access structs containing variants
4. Use either interface as shown above
""")