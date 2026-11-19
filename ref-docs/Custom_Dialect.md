# MyDialect: Custom MLIR Dialect

An end-to-end, out-of-tree implementation of a custom MLIR (Multi-Level Intermediate Representation) dialect named `mydialect`. This project demonstrates how TableGen definitions (`.td`), C++ library implementations, TableGen code generation, and custom standalone optimizer tooling (`my-opt`) integrate within the MLIR / LLVM compiler framework.

---

## Table of Contents

- [Overview](#overview)
- [Project Structure](#project-structure)
- [Step-by-Step Guide: Creating a Custom Dialect](#step-by-step-guide-creating-a-custom-dialect)
  - [Code Generation & Ingestion Pipeline](#code-generation--ingestion-pipeline)
  - [Step 1: Define Dialect Namespace (`MyDialect.td`)](#step-1-define-dialect-namespace-mydialecttd)
  - [Step 2: Define Dialect Operations (`MyOps.td`)](#step-2-define-dialect-operations-myopstd)
  - [Step 3: Create C++ Dialect Header (`MyDialect.h`)](#step-3-create-c-dialect-header-mydialecth)
  - [Step 4: Create C++ Operations Header (`MyOps.h`)](#step-4-create-c-operations-header-myopsh)
  - [Step 5: Implement Dialect Registration (`MyDialect.cpp`)](#step-5-implement-dialect-registration-mydialectcpp)
  - [Step 6: Implement Operation Definitions (`MyOps.cpp`)](#step-6-implement-operation-definitions-myopscpp)
  - [Step 7: Implement Standalone Optimizer Tool (`tools/my-opt.cpp`)](#step-7-implement-standalone-optimizer-tool-toolsmy-optcpp)
  - [Step 8: Orchestrate Build System (`CMakeLists.txt`)](#step-8-orchestrate-build-system-cmakeliststxt)
  - [Step 9: Write MLIR Verification Test (`test/custom_test.mlir`)](#step-9-write-mlir-verification-test-testcustom_testmlir)
  - [Step 10: Build and Run Verification](#step-10-build-and-run-verification)
- [Operations Reference](#operations-reference)

---

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

### File Breakdown

| File / Path | Role |
| :--- | :--- |
| **`include/MyDialect/MyDialect.td`** | TableGen specification defining dialect name and C++ namespace. |
| **`include/MyDialect/MyOps.td`** | TableGen specification declaring operations, traits, inputs, and outputs. |
| **`include/MyDialect/MyDialect.h`** | Public C++ dialect class header (includes generated `MyDialect.h.inc`). |
| **`include/MyDialect/MyOps.h`** | Public C++ operations header (includes generated `MyOps.h.inc`). |
| **`lib/MyDialect.cpp`** | Registers dialect operations inside `MyDialect::initialize()`. |
| **`lib/MyOps.cpp`** | Compiles operation definitions (includes generated `MyOps.cpp.inc`). |
| **`tools/my-opt.cpp`** | Standalone driver registering dialects and invoking `MlirOptMain`. |
| **`CMakeLists.txt`** | CMake script defining TableGen generator rules and target links. |
| **`test/custom_test.mlir`** | Test input exercising `mydialect.const` and `mydialect.sum`. |

---

## Step-by-Step Guide: Creating a Custom Dialect

Follow this optimal order to create a custom MLIR dialect from scratch:

```
Step 1: MyDialect.td   ──>   Step 2: MyOps.td       ──>   Step 3: MyDialect.h
        │                            │                            │
Step 4: MyOps.h        ──>   Step 5: MyDialect.cpp  ──>   Step 6: MyOps.cpp
        │                            │                            │
Step 7: tools/my-opt   ──>   Step 8: CMakeLists.txt ──>   Steps 9 & 10: Test & Build
```

### Code Generation & Ingestion Pipeline

MLIR relies on LLVM TableGen (`mlir-tblgen`) to declaratively describe dialects and operations. This eliminates redundant C++ boilerplate by auto-generating accessors, verification hooks, and parsing logic.

```
       TableGen Source                    Generated Include                  C++ Consumer File
   ┌───────────────────────┐            ┌───────────────────┐             ┌─────────────────────┐
   │ MyDialect/MyDialect.td│ ─────────> │ MyDialect.h.inc   │ ──────────> │ MyDialect.h         │
   │                       │ ─────────> │ MyDialect.cpp.inc │ ──────────> │ MyDialect.cpp       │
   └───────────────────────┘            └───────────────────┘             └─────────────────────┘

   ┌───────────────────────┐            ┌───────────────────┐             ┌─────────────────────┐
   │   MyDialect/MyOps.td  │ ─────────> │ MyOps.h.inc       │ ──────────> │ MyOps.h             │
   │                       │ ─────────> │ MyOps.cpp.inc     │ ──────────> │ MyOps.cpp           │
   └───────────────────────┘            └───────────────────┘             └─────────────────────┘
```

#### Mapping Between Source & Generated Files

| Source File | Generated `.inc` Target | TableGen Flag | Purpose |
| :--- | :--- | :--- | :--- |
| `include/MyDialect/MyDialect.td` | `MyDialect.h.inc` | `-gen-dialect-decls` | Emits dialect C++ class declaration |
| `include/MyDialect/MyDialect.td` | `MyDialect.cpp.inc` | `-gen-dialect-defs` | Emits dialect constructor and core registration definitions |
| `include/MyDialect/MyOps.td` | `MyOps.h.inc` | `-gen-op-decls` | Emits C++ class declarations for each operation |
| `include/MyDialect/MyOps.td` | `MyOps.cpp.inc` | `-gen-op-defs` | Emits method implementations, parsers, and verifiers |

---

### Step 1: Define Dialect Namespace (`MyDialect.td`)

- **Where to create it**: `include/MyDialect/MyDialect.td`
- **Why create it**: To declaratively define the dialect’s unique identifier and C++ namespace so MLIR’s TableGen generator (`mlir-tblgen`) can auto-generate dialect boilerplate.
- **What it contains**: Includes `mlir/IR/OpBase.td`, inherits from base `Dialect`, and defines `name` and `cppNamespace`.
- **Sample Snippet**:
  ```tablegen
  include "mlir/IR/OpBase.td"

  def MyDialect : Dialect {
      let name = "mydialect";                  // Prefix in textual MLIR (e.g. mydialect.sum)
      let cppNamespace = "::mlir::mydialect";  // Enclosing C++ namespace
  }
  ```
> **Recollection Anchor**: Sets dialect identifier and C++ namespace. TableGen produces `MyDialect.h.inc` and `MyDialect.cpp.inc` from this.

---

### Step 2: Define Dialect Operations (`MyOps.td`)

- **Where to create it**: `include/MyDialect/MyOps.td`
- **Why create it**: To declare operation signatures, arguments, results, traits (invariants), and custom textual syntax without writing hundreds of lines of manual C++ parsing and verification logic.
- **What it contains**:
  1. Base class `MyDialect_Op` inheriting from `Op<MyDialect, mnemonic, traits>`.
  2. Concrete operation definitions (`AddOp`, `ConstantOp`) with argument constraints and traits (`SameOperandsAndResultElementType`, `Pure`).
- **Sample Snippet**:
  ```tablegen
  include "MyDialect/MyDialect.td"
  // ... MLIR trait & interface includes (OpBase.td, SideEffectInterfaces.td) ...

  // 1. Dialect base class
  class MyDialect_Op<string mnemonic, list<Trait> traits = []> :
      Op<MyDialect, mnemonic, traits>;

  // 2. Operation definition skeleton
  def AddOp : MyDialect_Op<"sum", [SameOperandsAndResultElementType]> {
      let arguments = (ins AnyTypeOf<[AnyInteger, AnyFloat]>:$input1,
                           AnyTypeOf<[AnyInteger, AnyFloat]>:$input2);
      let results   = (outs AnyTypeOf<[AnyInteger, AnyFloat]>:$res);
      // Optional: let assemblyFormat = "...";
  }
  ```
> **Recollection Anchor**: Defines operation mnemonic, operand/result type constraints (`arguments`, `results`), and verification invariants (`traits`). Remember: TableGen declares syntax and structural rules; actual computation is performed later by lowering/rewrite passes.

---

### Step 3: Create C++ Dialect Header (`MyDialect.h`)

- **Where to create it**: `include/MyDialect/MyDialect.h`
- **Why create it**: Exposes the C++ declaration of `mlir::mydialect::MyDialect` to the rest of the project.
- **What it contains**: Includes `mlir/IR/Dialect.h` and the generated header `MyDialect.h.inc`.
- **Sample Snippet**:
  ```cpp
  #include "mlir/IR/Dialect.h"

  // Ingests dialect declarations generated by: mlir_tablegen(... -gen-dialect-decls)
  #include "MyDialect.h.inc"
  ```
> **Recollection Anchor**: Public wrapper exposing the TableGen-generated dialect class declaration (`MyDialect.h.inc`).

---

### Step 4: Create C++ Operations Header (`MyOps.h`)

- **Where to create it**: `include/MyDialect/MyOps.h`
- **Why create it**: Exposes strongly-typed C++ classes for each operation (e.g., `mlir::mydialect::AddOp`, `ConstantOp`).
- **What it contains**: Required MLIR support headers, the preprocessor guard `#define GET_OP_CLASSES`, and includes `MyOps.h.inc`.
- **Sample Snippet**:
  ```cpp
  #include "MyDialect.h"
  // ... MLIR core headers (OpDefinition.h, SideEffectInterfaces.h, etc.) ...

  #define GET_OP_CLASSES
  #include "MyOps.h.inc" // Expands only C++ op class declarations
  ```
> **Recollection Anchor**: `#define GET_OP_CLASSES` acts as a preprocessor switch telling `MyOps.h.inc` to emit class *declarations* (method prototypes and member types) for headers.

---

### Step 5: Implement Dialect Registration (`lib/MyDialect.cpp`)

- **Where to create it**: `lib/MyDialect.cpp`
- **Why create it**: Implements the `MyDialect::initialize()` method where custom operations are dynamically registered into the MLIR context.
- **What it contains**: Includes `MyDialect.h`, `MyOps.h`, generated `MyDialect.cpp.inc`, and calls `addOperations<...>()` using `#define GET_OP_LIST` and `#include "MyOps.cpp.inc"`.
- **Sample Snippet**:
  ```cpp
  #include "MyDialect/MyDialect.h"
  #include "MyDialect/MyOps.h"
  #include "MyDialect.cpp.inc" // Dialect constructor & core definitions

  void mlir::mydialect::MyDialect::initialize() {
      addOperations<
          #define GET_OP_LIST
          #include "MyOps.cpp.inc" // Expands into comma-separated: AddOp, ConstantOp, ...
      >();
  }
  ```
> **Recollection Anchor**: Implements `initialize()`. `#define GET_OP_LIST` expands into a comma-separated list of all op types, registering them with the MLIR context to avoid `unregistered operation` errors.

---

### Step 6: Implement Operation Definitions (`lib/MyOps.cpp`)

- **Where to create it**: `lib/MyOps.cpp`
- **Why create it**: Compiles the generated C++ definitions (parsers, printers, verifiers, builders) produced by TableGen.
- **What it contains**: Includes `MyOps.h`, `MyDialect.h`, `mlir/IR/OpImplementation.h`, `#define GET_OP_CLASSES`, and includes `MyOps.cpp.inc`.
- **Sample Snippet**:
  ```cpp
  #include "MyDialect/MyOps.h"
  #include "MyDialect/MyDialect.h"

  // Expands full operation method implementations (parsers, printers, verifiers)
  #define GET_OP_CLASSES
  #include "MyOps.cpp.inc"
  ```
> **Recollection Anchor**: In the `.cpp` file, `#define GET_OP_CLASSES` paired with `MyOps.cpp.inc` emits full method *definitions* (parsers, printers, verifiers) into `libMyDialect.a`.

---

### Step 7: Implement Standalone Optimizer Tool (`tools/my-opt.cpp`)

- **Where to create it**: `tools/my-opt.cpp`
- **Why create it**: Builds a dedicated executable (`my-opt`) capable of parsing, verifying, running passes, and printing MLIR files containing `mydialect` operations without requiring full compiler driver machinery.
- **What it contains**: `main()` function creating `mlir::DialectRegistry`, registering `MyDialect` and standard dialects (`FuncDialect`), and dispatching to `mlir::MlirOptMain`.
- **Sample Snippet**:
  ```cpp
  #include "MyDialect/MyDialect.h"
  #include "mlir/Tools/mlir-opt/MlirOptMain.h"
  #include "mlir/Dialect/Func/IR/FuncOps.h"

  int main(int argc, char **argv) {
      mlir::DialectRegistry registry;
      registry.insert<mlir::mydialect::MyDialect, mlir::func::FuncDialect>();

      return mlir::failed(mlir::MlirOptMain(argc, argv, "My Dialect Optimizer\n", registry));
  }
  ```
> **Recollection Anchor**: Test bench driver populating a `DialectRegistry` and delegating CLI parsing, IR verification, pass execution, and printing to `MlirOptMain`.

---

### Step 8: Configure the Build System (`CMakeLists.txt`)

- **Where to create it**: Root directory `CMakeLists.txt`
- **Why create it**: Automates TableGen execution (`mlir_tablegen`), defines targets, include paths, compile flags (`-fno-rtti`), and dependency propagation (`PUBLIC` vs `PRIVATE`).
- **What it contains**:
  1. `find_package(MLIR REQUIRED CONFIG)` and CMake module loading.
  2. TableGen generation rules for dialect (`MyDialect.h.inc`, `MyDialect.cpp.inc`) and ops (`MyOps.h.inc`, `MyOps.cpp.inc`).
  3. Static library `MyDialect` and executable target `my-opt`.
- **Sample Snippet**:
  ```cmake
  # 1. TableGen Generation Targets
  mlir_tablegen(MyDialect.h.inc -gen-dialect-decls)
  mlir_tablegen(MyOps.h.inc     -gen-op-decls)
  # (and corresponding .cpp.inc rules + add_public_tablegen_target)

  # 2. Dialect Library (add_dependencies prevents build race conditions)
  add_library(MyDialect lib/MyDialect.cpp lib/MyOps.cpp)
  add_dependencies(MyDialect MyDialectDialectIncGen MyDialectOpsIncGen)
  target_link_libraries(MyDialect PUBLIC MLIRIR)
  target_compile_options(MyDialect PRIVATE -fno-rtti)

  # 3. Standalone Driver Tool
  add_executable(my-opt tools/my-opt.cpp)
  target_link_libraries(my-opt PRIVATE MyDialect MLIROptLib MLIRFuncDialect)
  ```
> **Recollection Anchor**: 1) TableGen rules produce `.inc` files, 2) `add_dependencies` ensures `.inc` files exist before compiling C++, 3) `PUBLIC MLIRIR` propagates MLIR headers to consumers, while `my-opt` links `PRIVATE`.

---

### Step 9: Write an MLIR Test File (`test/custom_test.mlir`)

- **Where to create it**: `test/custom_test.mlir`
- **Why create it**: Provides textual MLIR code that exercises your custom operations to verify parsing and IR verification.
- **What it contains**: An MLIR function invoking `mydialect.const` and `"mydialect.sum"`.
- **Sample Snippet**:
  ```mlir
  func.func @main() -> i32 {
      %a = mydialect.const 10 : i32 : i32
      %res = "mydialect.sum"(%a, %a) : (i32, i32) -> i32
      return %res : i32
  }
  ```
> **Recollection Anchor**: Minimal test verifying that both custom declarative syntax (`mydialect.const`) and generic syntax (`"mydialect.sum"`) parse, verify traits, and return valid IR.

---

### Step 10: Build and Run Verification

- **Where to run**: Terminal in project root.
- **Commands & Verification**:
  ```bash
  export LLVM_BUILD_DIR=/home/mcw/Tharun/llvm-project/build
  export MLIR_SRC_DIR=/home/mcw/Tharun/llvm-project/mlir
  cmake -S . -B build -DMLIR_DIR=$LLVM_BUILD_DIR/lib/cmake/mlir   -DLLVM_DIR=$LLVM_BUILD_DIR/lib/cmake/llvm
  cmake --build build --parallel "$(nproc)"
  ./build/my-opt test/custom_test.mlir
  # Expected: IR successfully parses, verifies traits, and prints module { ... } to stdout
  ```
> **Recollection Anchor**: Two commands: generate build files and compile with CMake, then run `my-opt` to verify round-tripping.

---

## Operations Reference

### 1. `mydialect.const` (ConstantOp)
Materializes a constant value from an attribute.

- **Mnemonic**: `mydialect.const`
- **Traits**: `Pure` (specifies side-effect free computation).
- **Arguments**: `TypedAttrInterface:$input`
- **Results**: `AnyType:$res`
- **Syntax**:
  ```mlir
  %c = mydialect.const 10 : i32 : i32
  ```

### 2. `mydialect.sum` (AddOp)
Computes the addition of two operands of matching type.

- **Mnemonic**: `mydialect.sum`
- **Traits**: `SameOperandsAndResultElementType` (ensures operands and result types are compatible).
- **Arguments**:
  - `input1`: `AnyInteger` or `AnyFloat`
  - `input2`: `AnyInteger` or `AnyFloat`
- **Results**:
  - `res`: `AnyInteger` or `AnyFloat`
- **Syntax**:
  ```mlir
  %res = "mydialect.sum"(%a, %b) : (i32, i32) -> i32
  ```
