#ifndef MYDIALECT_TO_TOSA_TD
#define MYDIALECT_TO_TOSA_TD

include "mlir/IR/PatternBase.td"
include "mlir/Dialect/Tosa/IR/TosaOps.td"
include "MyDialect/MyOps.td"

def notTosaShape : AnyTypeOf<[
    AnyInteger,
    AnyFloat,
    TensorOf<[AnyInteger, AnyFloat]>
]>;

// Rewrite Pattern:
// Rule 1: When operands are Tensors -> lower to tosa.add
def AddOpToTensorLowering : Pat<(AddOp notTosaShape:$in1, notTosaShape:$in2),  // adding notTosaShape:$in1 instead of $in1, since there are two rules here
                                (Tosa_AddOp $in1, $in2)>;

// Rule 2: When operands are Tosa Shapes -> lower to tosa.add_shape
def AddShapeOpToLowering : Pat<(AddOp Tosa_Shape:$in1, Tosa_Shape:$in2),
                               (Tosa_AddShapeOp $in1, $in2)>; 

#endif // MYDIALECT_TO_TOSA_TD
