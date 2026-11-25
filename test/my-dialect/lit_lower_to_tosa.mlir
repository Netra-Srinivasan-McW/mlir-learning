// RUN: my-opt %s --lower-mydialect-to-tosa | FileCheck %s
// CHECK-LABEL: func.func @test_tensor_add
func.func @test_tensor_add(%arg0: tensor<4xi32>, %arg1: tensor<4xi32>) -> tensor<4xi32> {
  // CHECK: tosa.add %arg0, %arg1 : (tensor<4xi32>, tensor<4xi32>) -> tensor<4xi32>
  %0 = mydialect.sum input1 = %arg0 : tensor<4xi32>, input2 = %arg1 : tensor<4xi32> -> tensor<4xi32>
  return %0 : tensor<4xi32>
}
// CHECK-LABEL: func.func @test_shape_add
func.func @test_shape_add() -> !tosa.shape<3> {
  // CHECK: %[[S1:.*]] = tosa.const_shape
  // CHECK: %[[S2:.*]] = tosa.const_shape
  // CHECK: tosa.add_shape %[[S1]], %[[S2]] : (!tosa.shape<3>, !tosa.shape<3>) -> !tosa.shape<3>
  %s1 = tosa.const_shape {values = dense<[1, 2, 3]> : tensor<3xindex>} : () -> !tosa.shape<3>
  %s2 = tosa.const_shape {values = dense<[4, 5, 6]> : tensor<3xindex>} : () -> !tosa.shape<3>
  %res = mydialect.sum input1 = %s1 : !tosa.shape<3>, input2 = %s2 : !tosa.shape<3> -> !tosa.shape<3>
  return %res : !tosa.shape<3>
}

// when CHECK is found here it tries to match to any line of the output, if it is found to match then that line of output is marked as consumed.
// after that if you try to test the same line of output using a CHECK here in lit file, then an error will be raised, stating that the check has failed
// putting <double-slash>CHECK<colon> or CHECK<colon> inside comment will raise error, becuase FILECHECK looks CHECK<colon> regardless of position