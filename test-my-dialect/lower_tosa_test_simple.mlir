func.func @test_tensors() -> tensor<2xi32> {
    %a = mydialect.const dense<[10, 20]> : tensor<2xi32> -> tensor<2xi32>
    %b = mydialect.const dense<[30, 40]> : tensor<2xi32> -> tensor<2xi32>
    %res = mydialect.sum input1 = %a : tensor<2xi32>, input2 = %b : tensor<2xi32> -> tensor<2xi32>
    return %res : tensor<2xi32>
}