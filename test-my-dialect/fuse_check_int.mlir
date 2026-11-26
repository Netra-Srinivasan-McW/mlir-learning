func.func @main() -> i8 {
    %0 = mydialect.const 5 : i8 -> i8
    %1 = mydialect.const 20 : i8 -> i8
    %c = mydialect.const 2 : i8 -> i8

    // 1. sum = (a + b)
    %sum = mydialect.sum input1 = %0 : i8, input2 = %1 : i8 -> i8

    // 2. mul = sum * c  <-- Must pass %sum here!
    %res = mydialect.mul %sum : i8, %c : i8 -> i8

    return %res : i8
}