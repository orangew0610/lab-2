// NOTE: MathToFTM conversion pass tests — math dialect ops to FTM dialect ops.
//
// RUN: mlir-opt --convert-math-to-ftm %s | FileCheck %s
//
// ===================================================================
// MathToFTM conversion pass tests
//
// Operations tested:
//   math.rsqrt → ftm.vfrsqd / ftm.vfrsqs32 / ftm.sfrsqd / ftm.sfrsqs32
//   math.floor  → NOT converted (vfdint semantics differ from floor)
//
// Type dispatch:
//   v16f64  → vf*d    (vector double)
//   v32f32  → vf*s32  (vector float)
//   f64     → sf*d    (scalar double)
//   v2f32   → sf*s32  (scalar float pair)
// ===================================================================

// ===================================================================
// Group 1: math.rsqrt — all four type variants
// ===================================================================

// CHECK-LABEL: func.func @rsqrt_v16f64
// CHECK-NOT:   math.rsqrt
// CHECK:       ftm.vfrsqd
func.func @rsqrt_v16f64(%arg0: vector<16xf64>) -> vector<16xf64> {
  %0 = math.rsqrt %arg0 : vector<16xf64>
  return %0 : vector<16xf64>
}

// CHECK-LABEL: func.func @rsqrt_v32f32
// CHECK-NOT:   math.rsqrt
// CHECK:       ftm.vfrsqs32
func.func @rsqrt_v32f32(%arg0: vector<32xf32>) -> vector<32xf32> {
  %0 = math.rsqrt %arg0 : vector<32xf32>
  return %0 : vector<32xf32>
}

// CHECK-LABEL: func.func @rsqrt_f64
// CHECK-NOT:   math.rsqrt
// CHECK:       ftm.sfrsqd
func.func @rsqrt_f64(%arg0: f64) -> f64 {
  %0 = math.rsqrt %arg0 : f64
  return %0 : f64
}

// CHECK-LABEL: func.func @rsqrt_v2f32
// CHECK-NOT:   math.rsqrt
// CHECK:       ftm.sfrsqs32
func.func @rsqrt_v2f32(%arg0: vector<2xf32>) -> vector<2xf32> {
  %0 = math.rsqrt %arg0 : vector<2xf32>
  return %0 : vector<2xf32>
}

// ===================================================================
// Group 2: Unsupported types — ops should remain unconverted
// ===================================================================

// CHECK-LABEL: func.func @rsqrt_f32_unsupported
// CHECK:       math.rsqrt
// CHECK-NOT:   ftm.
func.func @rsqrt_f32_unsupported(%arg0: f32) -> f32 {
  %0 = math.rsqrt %arg0 : f32
  return %0 : f32
}

// CHECK-LABEL: func.func @rsqrt_v4f32_unsupported
// CHECK:       math.rsqrt
// CHECK-NOT:   ftm.
func.func @rsqrt_v4f32_unsupported(%arg0: vector<4xf32>) -> vector<4xf32> {
  %0 = math.rsqrt %arg0 : vector<4xf32>
  return %0 : vector<4xf32>
}

// CHECK-LABEL: func.func @floor_v16f64_unconverted
// CHECK:       math.floor
// CHECK-NOT:   ftm.
func.func @floor_v16f64_unconverted(%arg0: vector<16xf64>) -> vector<16xf64> {
  %0 = math.floor %arg0 : vector<16xf64>
  return %0 : vector<16xf64>
}

// CHECK-LABEL: func.func @floor_v32f32_unconverted
// CHECK:       math.floor
// CHECK-NOT:   ftm.
func.func @floor_v32f32_unconverted(%arg0: vector<32xf32>) -> vector<32xf32> {
  %0 = math.floor %arg0 : vector<32xf32>
  return %0 : vector<32xf32>
}

// CHECK-LABEL: func.func @floor_f64_unsupported
// CHECK:       math.floor
// CHECK-NOT:   ftm.
func.func @floor_f64_unsupported(%arg0: f64) -> f64 {
  %0 = math.floor %arg0 : f64
  return %0 : f64
}

// CHECK-LABEL: func.func @floor_v2f32_unsupported
// CHECK:       math.floor
// CHECK-NOT:   ftm.
func.func @floor_v2f32_unsupported(%arg0: vector<2xf32>) -> vector<2xf32> {
  %0 = math.floor %arg0 : vector<2xf32>
  return %0 : vector<2xf32>
}
