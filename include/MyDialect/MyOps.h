#ifndef MYDIALECT_OPS_H
#define MYDIALECT_OPS_H

#include "MyDialect.h"
#include "mlir/IR/OpDefinition.h"
#include "mlir/IR/Builders.h"
#include "mlir/Interfaces/SideEffectInterfaces.h" // for pure
#include "mlir/Bytecode/BytecodeOpInterface.h" // for attributes
// #include "mlir/IR/BuiltinTypes.h"

// Add this header so mlir::tosa::shapeType is known, to be included if using Tosa_Shape in MyOps.td
// #include "mlir/Dialect/Tosa/IR/TosaOps.h" 

#define GET_OP_CLASSES
#include "MyOps.h.inc"

#endif