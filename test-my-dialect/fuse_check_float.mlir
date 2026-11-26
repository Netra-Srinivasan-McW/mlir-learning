func.func @main() -> f16 {
    %0 = mydialect.const 5.4586980 : f16 -> f16
    %1 = mydialect.const 20.4 : f16 -> f16
    %c = mydialect.const 2.0 : f16 -> f16

    // 1. sum = (a + b)
    %sum = mydialect.sum input1 = %0 : f16, input2 = %1 : f16 {contract} -> f16

    // 2. mul = sum * c  <-- Must pass %sum here!
    %res = mydialect.mul %sum : f16, %c : f16 -> f16

    return %res : f16
}