#ifndef MY_OPS
#define MY_OPS

include "MyDialect/MyDialect.td"

include "mlir/IR/OpBase.td"
include "mlir/Interfaces/SideEffectInterfaces.td"
include "mlir/IR/BuiltinAttributeInterfaces.td"

// Base class for operations in MyDialect
// Op - base class provided by MLIR
// Below is an inherited class, can be written in MyDialect.td also

class MyDialect_Op<string mnemonic, list<Trait> traits = []> : Op<MyDialect, mnemonic, traits>;

def AddOp : MyDialect_Op<"sum", [SameOperandsAndResultElementType]> {
    let summary = "Addition operation in a custom dialect named 'MyDialect'";

    let arguments = (ins
        AnyTypeOf<[AnyInteger, AnyFloat]>:$input1,
        AnyTypeOf<[AnyInteger, AnyFloat]>:$input2
    );
    let results = (outs
        AnyTypeOf<[AnyInteger, AnyFloat]>:$res
    );
}

def ConstantOp : MyDialect_Op<"const", [Pure]> {
    let summary = "Receives a value as constant";

    let arguments = (ins TypedAttrInterface:$input);
    let results = (outs AnyType:$res);
    let assemblyFormat = "$input attr-dict `:` type($res)";
}

#endif // MY_OPS