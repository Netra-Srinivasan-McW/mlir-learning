# MyDialect: Custom MLIR Dialect

An end-to-end, out-of-tree implementation of a custom MLIR (Multi-Level Intermediate Representation) dialect named `mydialect`. This project demonstrates how TableGen definitions (`.td`), C++ library implementations, TableGen code generation, custom lowering passes to standard dialects (TOSA), and LLVM `lit` + `FileCheck` automated regression testing integrate within the MLIR / LLVM compiler framework.

## Overview

MLIR enables domain-specific compiler design through modular **dialects**. This repository defines a custom dialect with:
- **`MyDialect`**: Registered under dialect namespace `mydialect` (C++ namespace `::mlir::mydialect`).
- **Custom Operations**:
  - `mydialect.const`: Constant value materialization with attributes.
  - `mydialect.sum`: Flexible addition operation supporting scalars, tensors, and `!tosa.shape` types.
- **Dialect Lowering (Conversion Pass)**:
  - `--lower-mydialect-to-tosa`: Lowers `mydialect.const` to `tosa.const`, and `mydialect.sum` to `tosa.add` (tensors/scalars) and `tosa.add_shape` (`!tosa.shape`).
- **Standalone Optimizer Tool (`my-opt`)**: A custom command-line driver (similar to `mlir-opt`) for parsing, verifying, running optimization/lowering passes, and printing `mydialect` IR.
- **Automated Regression Testing**: LLVM `lit` and `FileCheck` integration hooked into CMake via custom target `check-mydialect`.

---

## Project Structure

```text
my-dialect/
├── CMakeLists.txt                  # Root build configuration & TableGen rules
├── include/
│   └── MyDialect/
│       ├── MyDialect.td            # TableGen definition of the dialect
│       ├── MyOps.td                # TableGen definitions of dialect operations
│       ├── MyDialectToTosa.td      # TableGen DRR rewrite rules lowering sum to tosa
│       ├── MyDialect.h             # C++ dialect header (wraps MyDialect.h.inc)
│       ├── MyOps.h                 # C++ operations header (wraps MyOps.h.inc)
│       └── Passes.h                # Declarations of conversion passes
├── lib/
│   ├── MyDialect.cpp               # Dialect initialization & operation registration
│   ├── MyOps.cpp                   # Operation C++ definitions & implementations
│   └── LowerToTosa.cpp             # Dialect conversion pass & C++ rewrite patterns
├── tools/
│   └── my-opt.cpp                  # Custom mlir-opt driver binary entry point
├── test/
│   ├── CMakeLists.txt              # Test suite target configuration (check-mydialect)
│   ├── lit.cfg.py                  # Main lit runner configuration & tool substitutions
│   ├── lit.site.cfg.py.in          # CMake template for site-specific paths
│   └── my-dialect/
        └── lit_lower_to_tosa.mlir  # Lit & FileCheck regression test for TOSA lowering
```

---

## Building the Project

### Prerequisites
- LLVM / MLIR built from source (with `FileCheck` and `llvm-lit` available).
- CMake >= 3.20
- C++17 compatible compiler (`g++` or `clang++`)

### Configure and Build
```bash
# 1. Configure the project with CMake
cmake -B build -S .

# 2. Build my-opt and the MyDialect library
cmake --build build --parallel "$(nproc)"
```

---

## Running the Lit Regression Tests

The test suite uses LLVM's `lit` test runner and `FileCheck` pattern matcher.

### Run All Tests via CMake
```bash
cmake --build build --target check-mydialect
```

### Run an Individual Test Directly with `llvm-lit`
You can run `llvm-lit` directly against any test in the build directory for verbose output (`-v`):
```bash
<path-to-llvm-build>/bin/llvm-lit -v build/test/my-dialect/lit_lower_to_tosa.mlir
```

---

## Manual Execution with `my-opt`

You can manually inspect the lowering pass on any MLIR input file using `my-opt`:

```bash
./build/bin/my-opt test/my-dialect/lit_lower_to_tosa.mlir --lower-mydialect-to-tosa
```
