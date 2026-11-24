func.func @test_both(
    %t1: tensor<?xf32>, %t2: tensor<?xf32>
) {
    // 1. Lowers to: tosa.add
    %tensor_res = mydialect.sum input1 = %t1 : tensor<?xf32>, input2 = %t2 : tensor<?xf32> -> tensor<?xf32>

    // 2. Lowers to: tosa.add_shape
    %s1 = tosa.const_shape {values = dense<[1, 2, 3]> : tensor<3xindex>} : () -> !tosa.shape<3>
    %s2 = tosa.const_shape {values = dense<[4, 5, 6]> : tensor<3xindex>} : () -> !tosa.shape<3>
    %shape_res = mydialect.sum input1 = %s1 : !tosa.shape<3>, input2 = %s2 : !tosa.shape<3> -> !tosa.shape<3>

    return
}