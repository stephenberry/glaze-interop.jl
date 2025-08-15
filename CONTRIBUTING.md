# Contributing to Glaze-interop.jl

Thank you for your interest in contributing to Glaze-interop.jl! This document provides guidelines for contributing to the project.

## Development Setup

### Prerequisites

- **Julia** ≥ 1.6 ([Download Julia](https://julialang.org/downloads/))
- **C++23 Compiler**:
  - Linux: GCC 13+ or Clang 15+
  - macOS: Xcode 14+ command line tools
- **CMake** ≥ 3.20

### Quick Start

1. Clone the repository:
   ```bash
   git clone https://github.com/stephenberry/glaze-interop.jl.git
   cd glaze-interop.jl
   ```

2. Run the test suite:
   ```bash
   # Unix/macOS
   ./run_tests.sh
   
   # Windows
   run_tests.bat
   ```

3. If tests pass, you're ready to contribute!

## Making Changes

### Code Style

- **Julia**: Follow the [Julia Style Guide](https://docs.julialang.org/en/v1/manual/style-guide/)
- **C++**: Use consistent formatting with existing code
- **Documentation**: Update docstrings and documentation for any new features

### Testing

All contributions must pass the existing test suite:

```bash
./run_tests.sh    # Must pass without errors
```

#### Adding Tests

When adding new features:

1. **Add C++ test code** in `test/` directory if needed
2. **Add Julia test code** in appropriate test files
3. **Update `test/runtests.jl`** to include new test files
4. **Ensure all tests pass** locally before submitting

#### Test Structure

- `test/test_*.jl` - Julia test files
- `test/test_*.cpp` - C++ test implementations  
- `test/test_*.hpp` - C++ test headers
- `test/runtests.jl` - Main test runner

### Continuous Integration

The project uses GitHub Actions for CI/CD:

- **Multiple platforms**: Ubuntu, macOS (Apple Silicon)
- **Julia version**: 1.11
- **Compiler compatibility**: GCC 13+, Clang 15+
- **Memory checking**: Valgrind on Linux (limited)

All pull requests must pass CI before merging.

### Debugging

For debugging segfaults and memory issues:

```bash
# Debug script with enhanced logging
./run_tests_debug.sh

# With address sanitizer (may not work on all platforms)
cmake -DCMAKE_BUILD_TYPE=Debug ..
```

## Submitting Changes

### Pull Request Process

1. **Create a feature branch** from `main`:
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Make your changes** with appropriate tests

3. **Ensure tests pass**:
   ```bash
   ./run_tests.sh
   ```

4. **Commit with clear messages**:
   ```bash
   git commit -m "Add feature: description of what was added"
   ```

5. **Push and create a pull request**:
   ```bash
   git push origin feature/my-feature
   ```

### Pull Request Requirements

- [ ] All tests pass locally (`./run_tests.sh`)
- [ ] CI tests pass on GitHub Actions
- [ ] New features include tests
- [ ] Documentation updated if applicable
- [ ] Code follows project style guidelines
- [ ] No segfaults or memory leaks introduced

### Review Process

1. **Automated checks** run via GitHub Actions
2. **Maintainer review** for code quality and design
3. **Testing** on different platforms via CI
4. **Merge** when all requirements are met

## Common Issues

### Compilation Errors

- **C++23 support**: Ensure your compiler supports C++23
- **CMake version**: Must be ≥ 3.20
- **Missing dependencies**: Install required system packages

### Memory Issues

- Use address sanitizer when possible: `cmake -DCMAKE_BUILD_TYPE=Debug`
- Check for proper object lifetime management
- Ensure proper initialization order

## Getting Help

- **Issues**: [GitHub Issues](https://github.com/stephenberry/glaze-interop.jl/issues)
- **Discussions**: [GitHub Discussions](https://github.com/stephenberry/glaze-interop.jl/discussions)
- **Documentation**: Check the `docs/` directory

## Code of Conduct

Please be respectful and inclusive in all interactions. We welcome contributions from developers of all backgrounds and skill levels.

---

Thank you for contributing to Glaze-interop.jl! 🚀