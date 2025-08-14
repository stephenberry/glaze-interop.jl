# Advanced Usage Guide

This guide covers advanced patterns, performance optimization, and complex use cases for Glaze.jl.

## Table of Contents

1. [Performance Optimization](#performance-optimization)
2. [Complex Type Patterns](#complex-type-patterns)
3. [Memory Management](#memory-management)
4. [Asynchronous Programming](#asynchronous-programming)
5. [Integration Patterns](#integration-patterns)
6. [Debugging and Profiling](#debugging-and-profiling)
7. [Best Practices](#best-practices)

## Performance Optimization

### Zero-Copy Array Operations

For large datasets, use array views to avoid copying:

```julia
# Efficient: Zero-copy read access
function compute_statistics(data_vector::CppVector)
    view = array_view(data_vector)
    return (
        mean = sum(view) / length(view),
        min = minimum(view),
        max = maximum(view)
    )
end

# Less efficient: Copying to Julia array
function compute_statistics_slow(data_vector::CppVector)
    julia_array = collect(data_vector)  # Copies data
    return (
        mean = sum(julia_array) / length(julia_array),
        min = minimum(julia_array), 
        max = maximum(julia_array)
    )
end
```

### Batch Operations

When modifying many elements, batch operations are more efficient:

```julia
# Efficient: Batch resize then populate
function populate_vector_fast(vec::CppVector, data::Vector{Float64})
    resize!(vec, length(data))
    for (i, val) in enumerate(data)
        vec[i] = val
    end
end

# Less efficient: Many individual push! operations
function populate_vector_slow(vec::CppVector, data::Vector{Float64})
    for val in data
        push!(vec, val)  # Individual resize operations
    end
end
```

### Function Call Optimization

Cache member function objects when calling repeatedly:

```julia
# Efficient: Cache function object
function process_many_calculations(calc, values)
    compute_func = calc.compute  # Cache the function object
    results = Float64[]
    for val in values
        result = compute_func(val)  # Reuse cached object
        push!(results, result)
    end
    return results
end

# Less efficient: Function lookup each time
function process_many_calculations_slow(calc, values)
    results = Float64[]
    for val in values
        result = calc.compute(val)  # Function lookup each time
        push!(results, result)
    end
    return results
end
```

### String Operations

For string-heavy operations, minimize conversions:

```julia
# Efficient: Work with CppString directly
function count_prefix_matches(strings::CppVector, prefix::String)
    count = 0
    for cpp_str in strings
        if startswith(cpp_str, prefix)  # Direct CppString operation
            count += 1
        end
    end
    return count
end

# Less efficient: Convert to Julia strings
function count_prefix_matches_slow(strings::CppVector, prefix::String)
    count = 0
    for cpp_str in strings
        julia_str = String(cpp_str)  # Unnecessary conversion
        if startswith(julia_str, prefix)
            count += 1
        end
    end
    return count
end
```

## Complex Type Patterns

### Polymorphic Interfaces

Handle different C++ types through a common interface:

```cpp
// C++ side - common base interface
struct Shape {
    virtual ~Shape() = default;
    virtual double area() const = 0;
    virtual std::string name() const = 0;
};

struct Circle : public Shape {
    double radius;
    double area() const override { return M_PI * radius * radius; }
    std::string name() const override { return "Circle"; }
};

struct Rectangle : public Shape {
    double width, height;
    double area() const override { return width * height; }
    std::string name() const override { return "Rectangle"; }
};

// Register both types
template<> struct glz::meta<Circle> {
    using T = Circle;
    static constexpr auto value = glz::object(
        "radius", &T::radius,
        "area", &T::area,
        "name", &T::name
    );
};

template<> struct glz::meta<Rectangle> {
    using T = Rectangle;
    static constexpr auto value = glz::object(
        "width", &T::width,
        "height", &T::height,
        "area", &T::area,
        "name", &T::name
    );
};
```

```julia
# Julia side - polymorphic processing
function process_shapes(lib, shape_names::Vector{String})
    total_area = 0.0
    
    for name in shape_names
        shape = Glaze.get_instance(lib, name)
        area = shape.area()
        shape_name = shape.name()
        
        println("$(shape_name): area = $area")
        total_area += area
    end
    
    return total_area
end
```

### Template Specializations

Handle C++ template specializations:

```cpp
// C++ template specializations
template<typename T>
struct Container {
    std::vector<T> data;
    
    void add(const T& item) { data.push_back(item); }
    size_t size() const { return data.size(); }
    T& get(size_t index) { return data[index]; }
};

// Register specific instantiations
using IntContainer = Container<int32_t>;
using FloatContainer = Container<float>;
using StringContainer = Container<std::string>;

template<> struct glz::meta<IntContainer> {
    using T = IntContainer;
    static constexpr auto value = glz::object(
        "data", &T::data,
        "add", &T::add,
        "size", &T::size,
        "get", &T::get
    );
};
// Similar for FloatContainer and StringContainer
```

```julia
# Julia side - generic container handling
function fill_container(container, items)
    for item in items
        container.add(item)
    end
    println("Container now has $(container.size()) items")
end

# Use with different types
int_container = lib.IntContainer
fill_container(int_container, [1, 2, 3, 4, 5])

float_container = lib.FloatContainer  
fill_container(float_container, [1.1, 2.2, 3.3])

string_container = lib.StringContainer
fill_container(string_container, ["hello", "world"])
```

### State Machines

Implement C++ state machines accessible from Julia:

```cpp
enum class State { IDLE, RUNNING, PAUSED, STOPPED };

struct StateMachine {
    State current_state = State::IDLE;
    std::string last_error;
    
    bool start() {
        if (current_state == State::IDLE) {
            current_state = State::RUNNING;
            return true;
        }
        last_error = "Cannot start from current state";
        return false;
    }
    
    bool pause() {
        if (current_state == State::RUNNING) {
            current_state = State::PAUSED;
            return true;
        }
        last_error = "Cannot pause from current state";
        return false;
    }
    
    bool resume() {
        if (current_state == State::PAUSED) {
            current_state = State::RUNNING;
            return true;
        }
        last_error = "Cannot resume from current state";
        return false;
    }
    
    void stop() {
        current_state = State::STOPPED;
    }
    
    std::string state_name() const {
        switch (current_state) {
            case State::IDLE: return "IDLE";
            case State::RUNNING: return "RUNNING";
            case State::PAUSED: return "PAUSED";
            case State::STOPPED: return "STOPPED";
            default: return "UNKNOWN";
        }
    }
};
```

```julia
# Julia side - state machine control
function run_state_machine_demo(state_machine)
    println("Initial state: $(state_machine.state_name())")
    
    # Start
    if state_machine.start()
        println("Started: $(state_machine.state_name())")
    end
    
    # Pause
    if state_machine.pause()
        println("Paused: $(state_machine.state_name())")
    end
    
    # Resume
    if state_machine.resume()
        println("Resumed: $(state_machine.state_name())")
    end
    
    # Stop
    state_machine.stop()
    println("Final state: $(state_machine.state_name())")
end
```

## Memory Management

### Lifetime Management

Understanding object lifetimes in Glaze.jl:

```julia
function demonstrate_lifetimes(lib)
    # 1. Global instances - live for duration of C++ library
    global_obj = Glaze.get_instance(lib, "global_instance")
    # Safe to use throughout program lifetime
    
    # 2. Created instances - live until Julia GC (but C++ owns memory)
    local_obj = lib.MyType
    # Safe within function scope, but don't rely on persistence
    
    # 3. Nested objects - lifetime tied to parent
    nested = global_obj.nested_field
    # Safe as long as global_obj is alive
    
    return global_obj, local_obj, nested
end

# Best practice: Keep references to parent objects
struct MyDataProcessor
    lib::CppLibrary
    main_object::CppStruct
    worker_objects::Vector{CppStruct}
end

function MyDataProcessor(lib_path::String)
    lib = Glaze.CppLibrary(lib_path)
    ccall((:init_types, lib.handle), Cvoid, ())
    
    main_obj = Glaze.get_instance(lib, "main_processor")
    workers = [lib.Worker for _ in 1:4]
    
    return MyDataProcessor(lib, main_obj, workers)
end
```

### Resource Management

Handle C++ resources properly:

```cpp
// C++ side - resource management
struct FileProcessor {
    std::string filename;
    bool is_open = false;
    
    bool open(const std::string& file) {
        filename = file;
        is_open = true;  // Simplified - would actually open file
        return true;
    }
    
    void close() {
        is_open = false;  // Simplified - would actually close file
        filename.clear();
    }
    
    bool process_data() {
        return is_open;  // Simplified processing
    }
    
    ~FileProcessor() {
        if (is_open) close();  // Automatic cleanup
    }
};
```

```julia
# Julia side - RAII pattern
struct SafeFileProcessor
    processor::CppStruct
    
    function SafeFileProcessor(lib, filename::String)
        proc = lib.FileProcessor
        if proc.open(filename)
            return new(proc)
        else
            error("Failed to open file: $filename")
        end
    end
end

# Automatic cleanup when processor goes out of scope
function process_file_safely(lib, filename::String)
    processor = SafeFileProcessor(lib, filename)
    
    try
        result = processor.processor.process_data()
        return result
    finally
        processor.processor.close()  # Explicit cleanup
    end
end
```

## Asynchronous Programming 

### Working with std::shared_future

Advanced patterns for async operations:

```cpp
// C++ side - async computation service
struct AsyncService {
    std::shared_future<double> compute_pi_async(int precision) {
        return std::async(std::launch::async, [precision]() {
            // Simulate computation
            std::this_thread::sleep_for(std::chrono::milliseconds(precision));
            return 3.14159265358979323846;
        }).share();
    }
    
    std::shared_future<std::vector<double>> generate_data_async(size_t count) {
        return std::async(std::launch::async, [count]() {
            std::vector<double> data;
            data.reserve(count);
            for (size_t i = 0; i < count; ++i) {
                data.push_back(static_cast<double>(i) * 0.1);
            }
            return data;
        }).share();
    }
};
```

```julia
# Julia side - async coordination
function coordinate_async_operations(service)
    # Start multiple async operations
    pi_future = service.compute_pi_async(1000)
    data_future = service.generate_data_async(10000)
    
    # Do other work while waiting
    println("Started async operations...")
    sleep(0.1)  # Simulate other work
    
    # Check periodically
    while !isready(pi_future) || !isready(data_future)
        ready_count = isready(pi_future) + isready(data_future)
        println("$ready_count/2 operations ready...")
        sleep(0.1)
    end
    
    # Get results
    pi_value = get(pi_future)
    data_vector = get(data_future)
    
    println("π ≈ $pi_value")
    println("Generated $(length(data_vector)) data points")
end

# Async error handling
function safe_async_operation(service)
    future = service.compute_pi_async(500)
    
    try
        if isvalid(future)
            wait(future)  # Wait for completion
            result = get(future)
            return result
        else
            error("Invalid future")
        end
    catch e
        println("Async operation failed: $e")
        return nothing
    end
end
```

### Future Collections

Managing multiple futures:

```julia
function process_multiple_futures(service, requests)
    # Start all operations
    futures = [service.compute_pi_async(req.precision) for req in requests]
    
    # Wait for all to complete
    while !all(isready, futures)
        ready_count = count(isready, futures)
        println("$ready_count/$(length(futures)) operations complete")
        sleep(0.1)
    end
    
    # Collect results
    results = [get(future) for future in futures]
    return results
end

# Process as they complete
function process_futures_as_ready(service, requests)
    futures = [service.compute_pi_async(req.precision) for req in requests]
    results = Vector{Float64}()
    
    while length(results) < length(futures)
        for (i, future) in enumerate(futures)
            if isready(future) && i > length(results)
                result = get(future)
                push!(results, result)
                println("Got result $i: $result")
            end
        end
        sleep(0.01)
    end
    
    return results
end
```

## Integration Patterns

### Configuration Management

Use C++ for configuration with Julia control:

```cpp
// C++ side - configuration system
struct AppConfig {
    std::string app_name = "DefaultApp";
    int32_t max_workers = 4;
    double timeout_seconds = 30.0;
    std::vector<std::string> plugin_paths;
    std::unordered_map<std::string, std::string> properties;
    
    bool load_from_file(const std::string& config_file) {
        // Load configuration from file
        return true;  // Simplified
    }
    
    bool save_to_file(const std::string& config_file) const {
        // Save configuration to file  
        return true;  // Simplified
    }
    
    void reset_to_defaults() {
        app_name = "DefaultApp";
        max_workers = 4;
        timeout_seconds = 30.0;
        plugin_paths.clear();
        properties.clear();
    }
};
```

```julia
# Julia side - configuration management
struct ConfigManager
    config::CppStruct
    config_file::String
    
    function ConfigManager(lib, config_file::String)
        config = lib.AppConfig
        if isfile(config_file)
            config.load_from_file(config_file)
        end
        return new(config, config_file)
    end
end

function update_config!(manager::ConfigManager, updates::Dict)
    for (key, value) in updates
        if hasfield(typeof(manager.config), Symbol(key))
            setfield!(manager.config, Symbol(key), value)
        else
            # Store in properties map
            manager.config.properties[key] = string(value)
        end
    end
end

function save_config(manager::ConfigManager)
    return manager.config.save_to_file(manager.config_file)
end

# Usage
config_manager = ConfigManager(lib, "app_config.json")
update_config!(config_manager, Dict(
    "app_name" => "MyApp",
    "max_workers" => 8,
    "custom_setting" => "custom_value"
))
save_config(config_manager)
```

### Plugin Architecture

Implement plugin system with C++ plugins and Julia control:

```cpp
// C++ side - plugin interface
struct Plugin {
    std::string name;
    std::string version;
    bool enabled = true;
    
    virtual ~Plugin() = default;
    virtual bool initialize() = 0;
    virtual void shutdown() = 0;
    virtual std::string process(const std::string& input) = 0;
};

struct EchoPlugin : public Plugin {
    EchoPlugin() {
        name = "EchoPlugin";
        version = "1.0.0";
    }
    
    bool initialize() override { return true; }
    void shutdown() override {}
    std::string process(const std::string& input) override {
        return "Echo: " + input;
    }
};

struct PluginManager {
    std::vector<std::unique_ptr<Plugin>> plugins;
    
    void add_plugin(std::unique_ptr<Plugin> plugin) {
        plugins.push_back(std::move(plugin));
    }
    
    std::vector<std::string> list_plugins() const {
        std::vector<std::string> names;
        for (const auto& plugin : plugins) {
            names.push_back(plugin->name);
        }
        return names;
    }
    
    std::string process_with_plugin(const std::string& plugin_name, 
                                   const std::string& input) {
        for (const auto& plugin : plugins) {
            if (plugin->name == plugin_name && plugin->enabled) {
                return plugin->process(input);
            }
        }
        return "Plugin not found: " + plugin_name;
    }
};
```

```julia
# Julia side - plugin management
function setup_plugin_system(lib)
    manager = lib.PluginManager
    
    # Add plugins (this would be more sophisticated in practice)
    echo_plugin = lib.EchoPlugin
    manager.add_plugin(echo_plugin)  # Simplified - needs proper unique_ptr handling
    
    return manager
end

function process_with_plugins(manager, inputs::Vector{String})
    plugin_names = manager.list_plugins()
    results = Dict{String, Vector{String}}()
    
    for plugin_name in plugin_names
        plugin_results = String[]
        for input in inputs
            result = manager.process_with_plugin(plugin_name, input)
            push!(plugin_results, result)
        end
        results[plugin_name] = plugin_results
    end
    
    return results
end
```

## Debugging and Profiling

### Debug Information

Enable verbose debugging:

```julia
# Debug type information
function debug_type_info(obj::CppStruct)
    println("Object type: $(typeof(obj))")
    println("Pointer: $(obj.ptr)")
    println("Library: $(obj.lib)")
    println("Owned: $(obj.owned)")
    
    # Print all fields (simplified)
    println("Fields:")
    try
        # This would need actual field introspection
        println("  Use pretty printing: $obj")
    catch e
        println("  Error accessing fields: $e")
    end
end

# Debug vector information
function debug_vector_info(vec::CppVector)
    println("Vector type: $(typeof(vec))")
    println("Length: $(length(vec))")
    println("First few elements: $(collect(vec[1:min(5, length(vec))]))")
end
```

### Performance Profiling

Profile Glaze.jl operations:

```julia
using BenchmarkTools

function benchmark_operations(lib)
    obj = lib.TestStruct
    
    # Benchmark field access
    @btime $obj.int_field              # Field read
    @btime $obj.int_field = 42         # Field write
    
    # Benchmark vector operations
    vec = obj.data_vector
    @btime length($vec)                # Vector length
    @btime $vec[1]                     # Element access
    @btime $vec[1] = 3.14             # Element write
    @btime push!($vec, 2.71)          # Vector append
    
    # Benchmark function calls
    func = obj.compute
    @btime $func(1.0, 2.0)            # Member function call
    
    # Benchmark string operations
    str = obj.name_field
    @btime length($str)                # String length
    @btime $str == "test"              # String comparison
end

# Memory allocation profiling
function profile_memory_usage(lib)
    obj = lib.TestStruct
    
    # Check allocations
    @allocated obj.int_field           # Should be 0 (no allocation)
    @allocated obj.compute(1.0, 2.0)   # Should be minimal
    
    # Compare with copying operations
    vec = obj.data_vector
    @allocated collect(vec)            # Shows copy allocation
    @allocated array_view(vec)         # Should be minimal
end
```

## Best Practices

### 1. Initialization Patterns

```julia
# Good: Single initialization function
function initialize_system(lib_path::String)
    lib = Glaze.CppLibrary(lib_path)
    ccall((:init_all_types, lib.handle), Cvoid, ())
    return lib
end

# Good: Lazy initialization
function get_lib()
    if !isdefined(Main, :_glaze_lib)
        Main._glaze_lib = initialize_system("./mylib.so")
    end
    return Main._glaze_lib
end
```

### 2. Error Handling

```julia
# Good: Comprehensive error handling
function safe_operation(obj, operation_args...)
    try
        return obj.risky_operation(operation_args...)
    catch BoundsError as e
        @warn "Array bounds error in operation" exception=e
        return nothing
    catch ErrorException as e
        @error "Glaze operation failed" exception=e
        return nothing
    catch e
        @error "Unexpected error in C++ operation" exception=e
        rethrow(e)
    end
end
```

### 3. Resource Management

```julia
# Good: Explicit resource management
function process_files(lib, filenames::Vector{String})
    results = []
    processor = lib.FileProcessor
    
    try
        for filename in filenames
            if processor.open(filename)
                result = processor.process()
                push!(results, result)
                processor.close()
            end
        end
    finally
        # Ensure cleanup even if errors occur
        if processor.is_open()
            processor.close()
        end
    end
    
    return results
end
```

### 4. Type Safety

```julia
# Good: Type-safe wrapper functions
function safe_vector_access(vec::CppVector, index::Int)
    if 1 <= index <= length(vec)
        return vec[index]
    else
        throw(BoundsError(vec, index))
    end
end

# Good: Input validation
function validate_and_call(obj, method_name::String, args...)
    if !hasfield(typeof(obj), Symbol(method_name))
        throw(ArgumentError("Method $method_name not found"))
    end
    
    method = getfield(obj, Symbol(method_name))
    if !isa(method, CppMemberFunction)
        throw(ArgumentError("$method_name is not a callable method"))
    end
    
    return method(args...)
end
```

### 5. Performance Patterns

```julia
# Good: Batch operations
function update_all_values(vec::CppVector, new_values::Vector{Float64})
    @assert length(vec) == length(new_values)
    
    for (i, val) in enumerate(new_values)
        vec[i] = val  # Direct assignment, no intermediate allocations
    end
end

# Good: Reuse objects
function repeated_computations(obj, inputs::Vector{Float64})
    compute_func = obj.compute  # Cache function object
    results = Vector{Float64}(undef, length(inputs))
    
    for (i, input) in enumerate(inputs)
        results[i] = compute_func(input)  # Reuse cached function
    end
    
    return results
end
```

---

This advanced usage guide covers sophisticated patterns and optimization techniques for getting the most out of Glaze.jl in complex applications.