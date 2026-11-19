# MyDialect: Custom MLIR Dialect

An end-to-end, out-of-tree implementation of a custom MLIR (Multi-Level Intermediate Representation) dialect named `mydialect`. This project demonstrates how TableGen definitions (`.td`), C++ library implementations, TableGen code generation, and custom standalone optimizer tooling (`my-opt`) integrate within the MLIR / LLVM compiler framework.

## Overview

MLIR enables domain-specific compiler design through modular **dialects**. This repository defines a custom dialect with:
- **`MyDialect`**: Registered under dialect namespace `mydialect` (C++ namespace `::mlir::mydialect`).
- **Custom Operations**:
  - `mydialect.const`: Constant value materialization with attributes.
  - `mydialect.sum`: Type-safe addition supporting integer and floating-point types.
- **Standalone Optimizer Tool (`my-opt`)**: A custom command-line driver (similar to `mlir-opt`) for parsing, verifying, running optimization passes, and printing `mydialect` IR.

---

## Project Structure

```text
my-dialect/
├── CMakeLists.txt              # Build configuration & TableGen rules
├── include/
│   └── MyDialect/
│       ├── MyDialect.td        # TableGen definition of the dialect
│       ├── MyOps.td            # TableGen definitions of dialect operations
│       ├── MyDialect.h         # C++ dialect header (wraps MyDialect.h.inc)
│       └── MyOps.h             # C++ operations header (wraps MyOps.h.inc)
├── lib/
│   ├── MyDialect.cpp           # Dialect initialization & operation registration
│   └── MyOps.cpp               # Operation C++ definitions & implementations
├── tools/
│   └── my-opt.cpp              # Entry point for custom mlir-opt driver binary
└── test/
    └── custom_test.mlir        # Sample MLIR program exercising custom operations
```
