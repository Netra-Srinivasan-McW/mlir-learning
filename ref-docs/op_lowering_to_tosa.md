# MLIR Operation Lowering: From `MyDialect` to `TOSA`

This guide explains what operation lowering is, the two primary ways to implement it in MLIR, how each operation in your dialect (`mydialect.const` and `mydialect.sum`) is lowered step-by-step, and how the overall dialect conversion pass functions.

---

## Table of Contents

- [1. What is Operation Lowering?](#1-what-is-operation-lowering)
  - [The Two Methods of Op Lowering](#the-two-methods-of-op-lowering)
- [2. Lowering Operation 1: `mydialect.const` (C++ Method)](#2-lowering-operation-1-mydialectconst-c-method)
  - [What is aimed to be done?](#what-is-aimed-to-be-done)
  - [The Code Snippet (`lib/LowerToTosa.cpp`)](#the-code-snippet-liblowertotosacpp)
  - [Logic Breakdown for Beginners](#logic-breakdown-for-beginners)
    - [A. Class Declaration & Inheritance](#a-class-declaration--inheritance)
    - [B. The `matchAndRewrite` Method](#b-the-matchandrewrite-method)
    - [C. Validation (Matching Phase)](#c-validation-matching-phase)
    - [D. Replacement (Rewriting Phase)](#d-replacement-rewriting-phase)
- [3. Lowering Operation 2: `mydialect.sum` (TableGen DRR Method)](#3-lowering-operation-2-mydialectsum-tablegen-drr-method)
  - [What is aimed to be done?](#what-is-aimed-to-be-done-1)
  - [The Code Snippet (`include/MyDialect/MyDialectToTosa.td`)](#the-code-snippet-includemydialectmydialecttotosatd)
  - [Logic Breakdown for Beginners](#logic-breakdown-for-beginners-1)
    - [A. Disambiguating the Type Constraint (`notTosaShape`)](#a-disambiguating-the-type-constraint-nottosashape)
    - [B. Declarative Rewrite Pattern (`Pat`)](#b-declarative-rewrite-pattern-pat)
    - [C. Shape Addition Rule](#c-shape-addition-rule)
    - [D. How It Links to C++](#d-how-it-links-to-c)
- [4. The Overall Dialect Conversion Pass](#4-the-overall-dialect-conversion-pass)
- [5. Summary Comparison of the Two Lowering Methods](#5-summary-comparison-of-the-two-lowering-methods)

---

## 1. What is Operation Lowering?

In MLIR, higher-level dialects (like your custom `mydialect`) represent operations close to your domain (e.g., arithmetic, graph layers). However, backends (like hardware runtimes, LLVM, or accelerators) cannot directly execute your custom operations.

**Operation Lowering** (also called **Dialect Conversion**) is the process of translating high-level operations into equivalent, more standardized lower-level operations (such as [TOSA - Tensor Operator Set Architecture](https://mlir.llvm.org/docs/Dialects/TOSA/)).

### The Two Methods of Op Lowering

In MLIR, rewrite patterns can be written in two ways:

1. **C++ `OpConversionPattern` / `OpRewritePattern`**:
   - Written directly in C++.
   - Best when lowering requires imperative logic: inspecting complex attributes, branching based on types, creating new helper operations, or type conversions.
   - Example used in your project: **`mydialect.const` → `tosa.const`**.

2. **Declarative Rewrite Rules (DRR in TableGen `.td`)**:
   - Written using TableGen `def : Pat<(SourceOp ...), (TargetOp ...)>`.
   - Best for 1:1, 1:N, or structural pattern replacements that are declarative and concise.
   - Example used in your project: **`mydialect.sum` → `tosa.add` / `tosa.add_shape`**.

---

## 2. Lowering Operation 1: `mydialect.const` (C++ Method)

### What is aimed to be done?
Convert `mydialect.const` (which holds a compile-time value) into `tosa.const`:
```mlir
// Before:
%0 = mydialect.const dense<[1.0, 2.0]> : tensor<2xf32> -> tensor<2xf32>

// After:
%0 = "tosa.const"() {value = dense<[1.0, 2.0]> : tensor<2xf32>} : () -> tensor<2xf32>
```

### The Code Snippet (`lib/LowerToTosa.cpp`)
```cpp
struct ConstOpLowering : public OpConversionPattern<mydialect::ConstantOp> {
    using OpConversionPattern<mydialect::ConstantOp>::OpConversionPattern;

    LogicalResult matchAndRewrite(mydialect::ConstantOp op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        // Step 1: Validate result is a ranked tensor
        auto resultType = dyn_cast<RankedTensorType>(op.getType());
        if (!resultType)
            return rewriter.notifyMatchFailure(op, "result must be a ranked tensor");

        // Step 2: Validate attribute is DenseElementsAttr
        auto value = dyn_cast<DenseElementsAttr>(op.getInput());
        if (!value)
            return rewriter.notifyMatchFailure(op, "value must be DenseElementsAttr");
        
        // Step 3: Replace old op with tosa::ConstOp
        rewriter.replaceOpWithNewOp<tosa::ConstOp>(op, resultType, value);
        return success();
    }
};
```

### Logic Breakdown for Beginners

#### A. Class Declaration & Inheritance
```cpp
struct ConstOpLowering : public OpConversionPattern<mydialect::ConstantOp>
```
- `OpConversionPattern<T>`: Tells MLIR's dialect conversion framework: *"This pattern matches whenever it sees a `mydialect::ConstantOp` in the IR."*
- `using OpConversionPattern...`: Inherits standard constructors from the base class so MLIR can pass the context into it.

#### B. The `matchAndRewrite` Method
```cpp
LogicalResult matchAndRewrite(mydialect::ConstantOp op, OpAdaptor adaptor,
                              ConversionPatternRewriter &rewriter) const override
```
- `op`: The existing operation in the IR being checked.
- `adaptor`: Provides access to the operands after they have been converted by type converters (not used here since `const` has attributes, not operands).
- `rewriter`: The tool used to modify the IR (create new ops, erase old ops, replace values).
- Returns `LogicalResult`: Either `success()` or `failure()`.

#### C. Validation (Matching Phase)
```cpp
auto resultType = dyn_cast<RankedTensorType>(op.getType());
if (!resultType)
    return rewriter.notifyMatchFailure(op, "result must be a ranked tensor");

auto value = dyn_cast<DenseElementsAttr>(op.getInput());
if (!value)
    return rewriter.notifyMatchFailure(op, "value must be DenseElementsAttr");
```
- TOSA's `tosa.const` requires a ranked tensor and a dense attribute (e.g. `dense<...>`).
- `dyn_cast<RankedTensorType>(...)`: Safely checks if the return type is a ranked tensor (like `tensor<2xf32>`).
- `rewriter.notifyMatchFailure(...)`: If the op does not meet requirements, it gracefully fails without crashing. The pass can try another pattern or report an error.

#### D. Replacement (Rewriting Phase)
```cpp
rewriter.replaceOpWithNewOp<tosa::ConstOp>(op, resultType, value);
return success();
```
- `replaceOpWithNewOp<tosa::ConstOp>`:
  1. Creates the new `tosa::ConstOp` at the exact same location as `op`.
  2. Substitutes all uses of the old op's result with the new op's result.
  3. Erases the old `mydialect.const` from the IR.
- Returns `success()`, signalling to MLIR that the pattern transformation completed.

---

## 3. Lowering Operation 2: `mydialect.sum` (TableGen DRR Method)

### What is aimed to be done?
`mydialect.sum` is a polymorphic addition operation. Depending on operand types, it must lower to two different TOSA operations:
1. **Tensors & Scalars:** → Lower to `tosa.add`
2. **Shape types (`!tosa.shape`):** → Lower to `tosa.add_shape`

```mlir
// Case 1: Tensors
%res = mydialect.sum input1 = %t1 : tensor<4xi32>, input2 = %t2 : tensor<4xi32> -> tensor<4xi32>
// Lowers to:
%res = tosa.add %t1, %t2 : (tensor<4xi32>, tensor<4xi32>) -> tensor<4xi32>

// Case 2: Shapes
%s = mydialect.sum input1 = %s1 : !tosa.shape<3>, input2 = %s2 : !tosa.shape<3> -> !tosa.shape<3>
// Lowers to:
%s = tosa.add_shape %s1, %s2 : (!tosa.shape<3>, !tosa.shape<3>) -> !tosa.shape<3>
```

### The Code Snippet (`include/MyDialect/MyDialectToTosa.td`)
```tablegen
include "mlir/IR/PatternBase.td"
include "mlir/Dialect/Tosa/IR/TosaOps.td"
include "MyDialect/MyOps.td"

// 1. Define type constraint for tensors/scalars (excluding shape)
def notTosaShape : AnyTypeOf<[
    AnyInteger,
    AnyFloat,
    TensorOf<[AnyInteger, AnyFloat]>
]>;

// 2. Rule 1: Tensors / Scalars -> tosa.add
def AddOpToTensorLowering : Pat<(AddOp notTosaShape:$in1, notTosaShape:$in2),
                                (Tosa_AddOp $in1, $in2)>;

// 3. Rule 2: Tosa Shapes -> tosa.add_shape
def AddShapeOpToLowering  : Pat<(AddOp Tosa_Shape:$in1, Tosa_Shape:$in2),
                                (Tosa_AddShapeOp $in1, $in2)>; 
```

### Logic Breakdown for Beginners

#### A. Disambiguating the Type Constraint (`notTosaShape`)
```tablegen
def notTosaShape : AnyTypeOf<[
    AnyInteger,
    AnyFloat,
    TensorOf<[AnyInteger, AnyFloat]>
]>;
```
- If we wrote `(AddOp $in1, $in2)` without constraints, TableGen wouldn't know which pattern to apply when encountering an `AddOp`.
- `notTosaShape` explicitly constrains Rule 1 to only fire when `$in1` and `$in2` are integers, floats, or tensors of integers/floats.

#### B. Declarative Rewrite Pattern (`Pat`)
```tablegen
def AddOpToTensorLowering : Pat<
    (AddOp notTosaShape:$in1, notTosaShape:$in2),   // SOURCE PATTERN (What to match)
    (Tosa_AddOp $in1, $in2)                         // TARGET PATTERN (What to generate)
>;
```
- In MLIR TableGen, `Pat<source, target>` defines a transformation:
  - **Source Dag `(...)`**: Look for `mydialect.sum` where both inputs match `notTosaShape`. Bind operand 1 to `$in1` and operand 2 to `$in2`.
  - **Target Dag `(...)`**: Replace it with `tosa.add` using the captured `$in1` and `$in2`.

#### C. Shape Addition Rule
```tablegen
def AddShapeOpToLowering : Pat<
    (AddOp Tosa_Shape:$in1, Tosa_Shape:$in2),
    (Tosa_AddShapeOp $in1, $in2)
>;
```
- `Tosa_Shape` matches operands of type `!tosa.shape<...>`.
- When both operands are shape types, it emits `tosa.add_shape`.

#### D. How It Links to C++
When building, CMake runs `mlir-tablegen -gen-rewriters`, which auto-generates `build/LowerToTosa.inc`.
In `LowerToTosa.cpp`, calling:
```cpp
#include "LowerToTosa.inc"
...
populateWithGenerated(patterns);
```
registers these auto-generated C++ pattern classes into the MLIR pass.

---

## 4. The Overall Dialect Conversion Pass

The patterns by themselves are just recipes. A **Dialect Conversion Pass** (`LowerMyDialectToTosaPass`) acts as the driver that executes them over the IR:

```cpp
void runOnOperation() override {
    ConversionTarget target(getContext());
    target.addLegalDialect<tosa::TosaDialect>();
    target.addLegalDialect<func::FuncDialect>();
    target.addIllegalDialect<mydialect::MyDialect>();

    RewritePatternSet patterns(&getContext());
    patterns.add<ConstOpLowering>(&getContext()); // C++ pattern
    populateWithGenerated(patterns);             // TableGen patterns

    if (failed(applyPartialConversion(getOperation(), target, std::move(patterns))))        
        signalPassFailure();
}
```

- **`ConversionTarget`**:
  - `addLegalDialect<tosa::TosaDialect>()`: TOSA operations are valid.
  - `addIllegalDialect<mydialect::MyDialect>()`: Any operation from `MyDialect` remaining after this pass is an error.
- **`RewritePatternSet`**: The collection of all rewrite patterns to apply (`ConstOpLowering` + `populateWithGenerated`).
- **`applyPartialConversion`**: MLIR traverses the operations in the module, matches patterns, and replaces all illegal `mydialect` operations with legal TOSA operations.

---

## 5. Summary Comparison of the Two Lowering Methods

| Aspect | Declarative TableGen (DRR / `.td`) | C++ (`OpConversionPattern`) |
| :--- | :--- | :--- |
| **Syntax** | Concise TableGen rules (`Pat<(Src), (Dst)>`) | Full C++ class (`matchAndRewrite`) |
| **Best Used For** | 1:1 or 1:N structural op replacements | Complex branching, attribute validation, dynamic reshaping |
| **Boilerplate** | Very low (3–5 lines per op) | Medium (class definitions, dyn_cast checks) |
| **Flexibility** | Limited to expressible DAG patterns | Turing-complete C++ with access to MLIR APIs |
| **How Used in Repo** | `mydialect.sum` → `tosa.add` / `tosa.add_shape` | `mydialect.const` → `tosa.const` |
