# Glaze-interop.jl Documentation

Welcome to the comprehensive documentation for Glaze-interop.jl - a high-performance Julia package for zero-copy interoperability with C++ data structures.

## 📚 Documentation Overview

This documentation is organized into several categories to help you find the information you need quickly:

### 🚀 Getting Started
- **[Getting Started Guide](getting_started.md)** - Complete tutorial from installation to first project
- **[Quick Reference Card](#quick-reference)** - Essential commands and patterns

### 📖 User Guides  
- **[API Reference](api_reference.md)** - Complete function and type reference
- **[Type System Guide](type_system.md)** - Understanding C++ to Julia type mappings
- **[Advanced Usage](advanced_usage.md)** - Complex patterns and performance optimization

### 🔧 Developer Resources
- **[Building from Source](building.md)** - Development setup and build instructions
- **[Architecture Overview](../ARCHITECTURE.md)** - Internal design and implementation details

### 🆘 Support & Troubleshooting
- **[Troubleshooting Guide](troubleshooting.md)** - Common issues and solutions
- **[Performance Tips](#performance-tips)** - Optimization guidelines
- **[FAQ](#frequently-asked-questions)** - Answers to common questions

### 📋 Additional Resources
- **[Examples Directory](../examples/)** - Practical usage demonstrations
- **[Test Suite](../test/)** - Comprehensive test examples
- **[Benchmarks](../test/benchmarks/)** - Performance comparisons

## 🎯 Quick Reference

### Essential Commands

```julia
# Library management
lib = Glaze.CppLibrary("path/to/lib.so")
ccall((:init_function, lib.handle), Cvoid, ())

# Instance access  
global_obj = Glaze.get_instance(lib, "instance_name")
new_obj = lib.TypeName

# Data manipulation
obj.field = value                     # Direct field access
push!(obj.vector_field, element)     # Vector operations
result = obj.method(args...)          # Member function calls
```

### Type Quick Reference

| C++ Type | Julia Type | Usage Example |
|----------|------------|---------------|
| `int32_t` | `Int32` | `obj.count = 42` |
| `std::string` | `CppString` | `obj.name == "test"` |
| `std::vector<T>` | `CppVector` | `push!(obj.data, 3.14)` |
| `std::optional<T>` | `CppOptional` | `value(obj.maybe_value)` |
| `std::shared_future<T>` | `CppSharedFuture` | `get(obj.async_result)` |
| Member functions | `CppMemberFunction` | `obj.compute(1.0, 2.0)` |

### Build Quick Reference

```bash
# Quick build and test
./run_tests.sh                       # Unix/macOS
.\run_tests.bat                     # Windows

# Manual build
cd cpp_interface/build && cmake .. && make
julia --project=. test/runtests.jl
```

## 📈 Performance Tips

### Zero-Copy Operations
```julia
# ✅ Efficient: Direct access
value = obj.data_vector[1000]         # ~10ns
length = length(obj.data_vector)      # ~5ns

# ✅ Efficient: Array view for read-only
view = array_view(obj.large_dataset)
sum_val = sum(view)                   # Zero-copy

# ❌ Inefficient: Unnecessary copying  
julia_array = collect(obj.data_vector) # Copies all data
```

### String Operations
```julia
# ✅ Efficient: Direct CppString operations
if obj.name == "target_name"          # Native comparison
    length = length(obj.name)         # Direct length
    println("Name: $(obj.name)")      # String interpolation
end

# ❌ Less efficient: Unnecessary conversion
julia_string = String(obj.name)      # Only if really needed
```

### Function Calls
```julia
# ✅ Efficient: Cache function objects
compute_func = obj.compute            # Cache once
for val in data
    result = compute_func(val)        # Reuse cached object
end

# ❌ Less efficient: Repeated lookup
for val in data
    result = obj.compute(val)         # Function lookup each time
end
```

## 🔍 Frequently Asked Questions

### General Usage

**Q: How does Glaze.jl achieve zero-copy performance?**
A: Glaze.jl directly accesses C++ memory through pointers, without serialization or data copying. Julia wrappers provide safe access to the underlying C++ objects.

**Q: Can I modify C++ objects from Julia?**
A: Yes! All modifications through Glaze.jl directly update the C++ objects in memory. Changes are immediately visible to both C++ and Julia code.

**Q: What happens to object lifetime and memory management?**
A: C++ owns all memory. Julia holds references but doesn't manage object lifetimes. Ensure C++ objects remain valid while accessed from Julia.

### Type System

**Q: Why do I get `CppString` instead of Julia `String`?**
A: `CppString` inherits from `AbstractString` and supports all Julia string operations while maintaining zero-copy access to C++ memory. Convert with `String(cpp_string)` if needed.

**Q: How do I work with nested C++ structures?**
A: Access nested fields naturally: `person.address.street = "123 Main St"`. All nesting levels support zero-copy access.

**Q: Can I use Julia broadcasting with C++ vectors?**
A: Yes! `CppVector` supports Julia array operations: `obj.scores .+ 10`, `sum(obj.data)`, etc.

### Performance

**Q: How fast is Glaze.jl compared to alternatives?**
A: Glaze.jl provides true zero-copy performance:
- Field access: ~5ns (same as native Julia structs)
- Vector operations: ~10ns (same as Julia arrays)  
- No serialization overhead (vs. JSON: 10,000x faster)

**Q: When should I use `array_view()` vs direct vector access?**
A: Use `array_view()` for read-only access to large datasets to avoid any potential copying. Use direct access when you need to modify elements.

### Development

**Q: How do I debug C++/Julia interaction issues?**
A: 
1. Enable debug mode: `ENV["JULIA_DEBUG"] = "Glaze"`
2. Use minimal reproduction cases
3. Check object validity: `obj.ptr != C_NULL`
4. Verify initialization: ensure init functions are called

**Q: How do I add support for new C++ types?**
A: Follow the pattern in existing code:
1. Add type descriptor in C++ interface
2. Add Julia wrapper type
3. Implement required operations
4. Add comprehensive tests

## 🗺️ Learning Path

### For New Users
1. **Start here**: [Getting Started Guide](getting_started.md)
2. **Learn the basics**: Work through the tutorial examples
3. **Explore types**: Read [Type System Guide](type_system.md)
4. **Try examples**: Run code from [Examples Directory](../examples/)

### For Advanced Users
1. **Performance**: [Advanced Usage Guide](advanced_usage.md)
2. **Complex patterns**: Study [Complex Type Patterns](advanced_usage.md#complex-type-patterns)
3. **Optimization**: [Performance Optimization](advanced_usage.md#performance-optimization)
4. **Integration**: [Integration Patterns](advanced_usage.md#integration-patterns)

### For Contributors
1. **Setup**: [Building from Source](building.md)
2. **Architecture**: [Architecture Overview](../ARCHITECTURE.md)
3. **Testing**: Explore the [Test Suite](../test/)

## 🆘 Getting Help

### Community Support
- **🐛 Issues**: [GitHub Issues](https://github.com/stephenberry/glaze-interop.jl/issues) - Bug reports and feature requests
- **💬 Discussions**: [GitHub Discussions](https://github.com/stephenberry/glaze-interop.jl/discussions) - Questions and ideas
- **📖 Documentation**: You're reading it! Check specific guides above
- **💡 Stack Overflow**: Tag questions with `glaze-interop.jl` and `julia`

### Before Asking for Help
1. **Search existing issues** and discussions
2. **Check the troubleshooting guide** - many common issues are covered
3. **Create a minimal reproduction case** - helps others help you faster
4. **Include system information** - OS, Julia version, compiler version

### Reporting Issues
When reporting bugs, please include:

```julia
# System information
println("Julia: ", VERSION)
println("Platform: ", Sys.MACHINE)

# Package information  
using Pkg
Pkg.status("Glaze")

# Minimal reproduction code
lib = Glaze.CppLibrary("your_lib.so")
# ... minimal code that shows the issue
```

## 📄 License and Attribution

Glaze-interop.jl is licensed under the MIT License. See the [LICENSE](../LICENSE) file for details.

### Acknowledgments
- **[Glaze](https://github.com/stephenberry/glaze)** - The C++ reflection library that powers this package
- **Julia Community** - For creating an amazing language for scientific computing
- **Contributors** - Thank you to everyone who has contributed to this project!

---

## 📞 Quick Links

| What you want to do | Where to go |
|---------------------|-------------|
| **Get started quickly** | [Getting Started Guide](getting_started.md) |
| **Look up a function** | [API Reference](api_reference.md) |
| **Solve a problem** | [Troubleshooting Guide](troubleshooting.md) |
| **Optimize performance** | [Advanced Usage Guide](advanced_usage.md) |
| **Contribute code** | [GitHub Issues](https://github.com/stephenberry/glaze-interop.jl/issues) |
| **Understand internals** | [Architecture Overview](../ARCHITECTURE.md) |
| **See examples** | [Examples Directory](../examples/) |
| **Report a bug** | [GitHub Issues](https://github.com/stephenberry/glaze-interop.jl/issues) |

---

**Happy coding with Glaze-interop.jl! 🚀**