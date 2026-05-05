// RUN: mlir-opt --convert-vector-to-ftm %s | FileCheck %s

// CHECK-LABEL: func @transfer_read_i32
// CHECK:         ftm.vload_w %{{.*}}[%{{.*}}, %{{.*}}] : memref<4x32xi32> -> vector<32xi32>
func.func @transfer_read_i32(%mem: memref<4x32xi32>, %i: index, %j: index) -> vector<32xi32> {
  %pad = arith.constant 0 : i32
  %v = vector.transfer_read %mem[%i, %j], %pad {in_bounds = [true]} : memref<4x32xi32>, vector<32xi32>
  return %v : vector<32xi32>
}

// CHECK-LABEL: func @transfer_read_i64
// CHECK:         ftm.vload_dw %{{.*}}[%{{.*}}, %{{.*}}] : memref<4x32xi64> -> vector<32xi64>
func.func @transfer_read_i64(%mem: memref<4x32xi64>, %i: index, %j: index) -> vector<32xi64> {
  %pad = arith.constant 0 : i64
  %v = vector.transfer_read %mem[%i, %j], %pad {in_bounds = [true]} : memref<4x32xi64>, vector<32xi64>
  return %v : vector<32xi64>
}

// CHECK-LABEL: func @transfer_write_i32
// CHECK:         ftm.vstore_w %{{.*}}, %{{.*}}[%{{.*}}, %{{.*}}] : vector<32xi32>, memref<4x32xi32>
func.func @transfer_write_i32(%v: vector<32xi32>, %mem: memref<4x32xi32>, %i: index, %j: index) {
  vector.transfer_write %v, %mem[%i, %j] {in_bounds = [true]} : vector<32xi32>, memref<4x32xi32>
  return
}

// CHECK-LABEL: func @transfer_write_i64
// CHECK:         ftm.vstore_dw %{{.*}}, %{{.*}}[%{{.*}}, %{{.*}}] : vector<32xi64>, memref<4x32xi64>
func.func @transfer_write_i64(%v: vector<32xi64>, %mem: memref<4x32xi64>, %i: index, %j: index) {
  vector.transfer_write %v, %mem[%i, %j] {in_bounds = [true]} : vector<32xi64>, memref<4x32xi64>
  return
}

// CHECK-LABEL: func @transfer_read_3d_indices
// CHECK:         ftm.vload_w %{{.*}}[%{{.*}}, %{{.*}}, %{{.*}}] : memref<8x16x32xi32> -> vector<32xi32>
func.func @transfer_read_3d_indices(%mem: memref<8x16x32xi32>, %i: index, %j: index, %k: index) -> vector<32xi32> {
  %pad = arith.constant 0 : i32
  %v = vector.transfer_read %mem[%i, %j, %k], %pad {in_bounds = [true]} : memref<8x16x32xi32>, vector<32xi32>
  return %v : vector<32xi32>
}

// Negative test: non-FTM vector width should NOT be converted
// CHECK-LABEL: func @transfer_read_non_ftm_width
// CHECK:         vector.transfer_read
// CHECK-NOT:     ftm.vload
func.func @transfer_read_non_ftm_width(%mem: memref<4x4xi32>, %i: index, %j: index) -> vector<4xi32> {
  %pad = arith.constant 0 : i32
  %v = vector.transfer_read %mem[%i, %j], %pad {in_bounds = [true]} : memref<4x4xi32>, vector<4xi32>
  return %v : vector<4xi32>
}

// Negative test: out-of-bounds (no in_bounds attr) should NOT be converted
// CHECK-LABEL: func @transfer_read_out_of_bounds
// CHECK:         vector.transfer_read
// CHECK-NOT:     ftm.vload
func.func @transfer_read_out_of_bounds(%mem: memref<4x32xi32>, %i: index, %j: index) -> vector<32xi32> {
  %pad = arith.constant 0 : i32
  %v = vector.transfer_read %mem[%i, %j], %pad : memref<4x32xi32>, vector<32xi32>
  return %v : vector<32xi32>
}
