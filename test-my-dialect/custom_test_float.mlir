func.func @main() -> (f16, f16) {
    %a = mydialect.const 5.45 : f16 -> f16
    %b = mydialect.const 20.42567 : f16 -> f16
    // %result = "mydialect.sum"(%a, %b) {
    //     operandSegmentSizes = array<i32: 1, 1>
    //     } : (f16, f16) -> f16
    %result = "mydialect.sum"(%a, %b) {contract} : (f16, f16) -> f16
    %prod = mydialect.mul %a : f16, %b : f16 {contract} -> f16
    "func.return" (%prod, %result) : (f16, f16) -> ()
}