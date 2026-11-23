func.func @main() -> f16 {
    %a = mydialect.const 5.45 : f16 -> f16
    %b = mydialect.const 3.12 : f16 -> f16
    // no assemblyFormat generic syntax
    // %result = mydialect.sum() <{operandSegmentSizes = array<i32: 1, 0>}> : (f16) -> f16

    // two inputs
    // %result = mydialect.sum input1 = %a : f16, input2 = %b : f16 {name="inputs"} -> f16

    // one input
    %result = mydialect.sum input1 = %a : f16 -> f16

    // no inputs - parser succeeds, but verifier doesn't.
    // %result = mydialect.sum : -> f16
    return %result : f16
}