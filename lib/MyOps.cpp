#include "MyDialect/MyOps.h"
#include "MyDialect/MyDialect.h"
#include "mlir/IR/OpImplementation.h"

// Include generated operation definitions
#define GET_OP_CLASSES
#include "MyOps.cpp.inc"

// to automatically canonicalize fusion
#include "mlir/IR/PatternMatch.h"
#include "mlir/IR/TypeUtilities.h"
#include "FuseAddMul.inc"

void mlir::mydialect::MulOp::getCanonicalizationPatterns(
    mlir::RewritePatternSet &results, mlir::MLIRContext *context) {
  populateWithGenerated(results);
}
