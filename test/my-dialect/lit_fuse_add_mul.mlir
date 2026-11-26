// RUN: my-opt %s --canonicalize | FileCheck %s
// RUN: my-opt %s --fuse-add-mul | FileCheck %s

// ============================================================================
// 1. Integer Fusion (LHS): (a + b) * c -> fused_add_mul(a, b, c)
// Integers are always legal to fuse without the {contract} attribute.
// ============================================================================
// CHECK-LABEL: func.func @test_fuse_int_lhs
// CHECK-SAME: (%[[A:.*]]: i32, %[[B:.*]]: i32, %[[C:.*]]: i32) -> i32
func.func @test_fuse_int_lhs(%a: i32, %b: i32, %c: i32) -> i32 {
  // CHECK-NOT: mydialect.sum
  // CHECK-NOT: mydialect.mul
  // CHECK: %[[RES:.*]] = mydialect.fused_add_mul %[[A]] : i32, %[[B]] : i32, %[[C]] : i32 -> i32
  // CHECK: return %[[RES]] : i32
  %sum = mydialect.sum input1 = %a : i32, input2 = %b : i32 -> i32
  %res = mydialect.mul %sum : i32, %c : i32 -> i32
  return %res : i32
}

// ============================================================================
// 2. Integer Fusion (RHS): c * (a + b) -> fused_add_mul(a, b, c)
// Tests the UpliftAddRHSFuse pattern.
// ============================================================================
// CHECK-LABEL: func.func @test_fuse_int_rhs
// CHECK-SAME: (%[[A:.*]]: i32, %[[B:.*]]: i32, %[[C:.*]]: i32) -> i32
func.func @test_fuse_int_rhs(%a: i32, %b: i32, %c: i32) -> i32 {
  // CHECK-NOT: mydialect.sum
  // CHECK-NOT: mydialect.mul
  // CHECK: %[[RES:.*]] = mydialect.fused_add_mul %[[A]] : i32, %[[B]] : i32, %[[C]] : i32 -> i32
  // CHECK: return %[[RES]] : i32
  %sum = mydialect.sum input1 = %a : i32, input2 = %b : i32 -> i32
  %res = mydialect.mul %c : i32, %sum : i32 -> i32
  return %res : i32
}

// ============================================================================
// 3. Float Fusion with {contract}: Allowed when contract attribute is set
// ============================================================================
// CHECK-LABEL: func.func @test_fuse_float_contract
// CHECK-SAME: (%[[A:.*]]: f32, %[[B:.*]]: f32, %[[C:.*]]: f32) -> f32
func.func @test_fuse_float_contract(%a: f32, %b: f32, %c: f32) -> f32 {
  // CHECK-NOT: mydialect.sum
  // CHECK-NOT: mydialect.mul
  // CHECK: %[[RES:.*]] = mydialect.fused_add_mul %[[A]] : f32, %[[B]] : f32, %[[C]] : f32 -> f32
  // CHECK: return %[[RES]] : f32
  %sum = mydialect.sum input1 = %a : f32, input2 = %b : f32 {contract} -> f32
  %res = mydialect.mul %sum : f32, %c : f32 {contract} -> f32
  return %res : f32
}

// ============================================================================
// 4. Float Legality Check (No {contract}): MUST NOT FUSE
// Verifies HasContract prevents fusion when precision could be altered.
// ============================================================================
// CHECK-LABEL: func.func @test_no_fuse_float_without_contract
// CHECK-SAME: (%[[A:.*]]: f32, %[[B:.*]]: f32, %[[C:.*]]: f32) -> f32
func.func @test_no_fuse_float_without_contract(%a: f32, %b: f32, %c: f32) -> f32 {
  // CHECK-NOT: mydialect.fused_add_mul
  // CHECK: %[[SUM:.*]] = mydialect.sum input1 = %[[A]] : f32, input2 = %[[B]] : f32 -> f32
  // CHECK: %[[RES:.*]] = mydialect.mul %[[SUM]] : f32, %[[C]] : f32 -> f32
  // CHECK: return %[[RES]] : f32
  %sum = mydialect.sum input1 = %a : f32, input2 = %b : f32 -> f32
  %res = mydialect.mul %sum : f32, %c : f32 -> f32
  return %res : f32
}
