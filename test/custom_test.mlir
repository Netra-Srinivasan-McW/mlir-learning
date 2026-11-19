func.func @main() -> i32 {
    %a = mydialect.const 10 : i32 : i32
    %b = mydialect.const 20 : i32 : i32
    %result = "mydialect.sum"(%a, %b) : (i32, i32) -> i32
    return %result : i32
}