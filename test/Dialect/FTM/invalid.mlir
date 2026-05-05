// NOTE: FTM dialect memref op verifier error tests.
//
// RUN: mlir-opt -verify-diagnostics %s

// ===================================================================
// Verifier error tests for memref-based vector load/store ops
//
// Each test verifies that the op correctly rejects invalid inputs:
//   - Wrong memref element type
//   - Wrong number of indices for the memref rank
// ===================================================================

// --- Wrong element type: vload_h expects i16 memref, got i32 ---
func.func @vload_h_wrong_elem(%mem: memref<128xi32>, %idx: index) -> vector<32xi32> {
  // expected-error @+1 {{requires memref element type 'i16', got 'i32'}}
  %0 = ftm.vload_h %mem[%idx] : memref<128xi32> -> vector<32xi32>
  return %0 : vector<32xi32>
}

// --- Wrong index count: vload_w on 2D memref with 1 index ---
func.func @vload_w_wrong_indices(%mem: memref<4x32xi32>, %idx: index) -> vector<32xi32> {
  // expected-error @+1 {{requires 2 indices, got 1}}
  %0 = ftm.vload_w %mem[%idx] : memref<4x32xi32> -> vector<32xi32>
  return %0 : vector<32xi32>
}

// --- Wrong element type: vstore_w expects i32 memref, got i16 ---
func.func @vstore_w_wrong_elem(%data: vector<32xi32>, %mem: memref<128xi16>, %idx: index) {
  // expected-error @+1 {{requires memref element type 'i32', got 'i16'}}
  ftm.vstore_w %data, %mem[%idx] : vector<32xi32>, memref<128xi16>
  return
}

// --- Wrong element type: vload_dw expects i64 memref, got i32 ---
func.func @vload_dw_wrong_elem(%mem: memref<512xi32>, %idx: index) -> vector<32xi64> {
  // expected-error @+1 {{requires memref element type 'i64', got 'i32'}}
  %0 = ftm.vload_dw %mem[%idx] : memref<512xi32> -> vector<32xi64>
  return %0 : vector<32xi64>
}

// --- Wrong index count: vstore_dw on 1D memref with 2 indices ---
func.func @vstore_dw_wrong_indices(%data: vector<32xi64>, %mem: memref<512xi64>, %i: index, %j: index) {
  // expected-error @+1 {{requires 1 indices, got 2}}
  ftm.vstore_dw %data, %mem[%i, %j] : vector<32xi64>, memref<512xi64>
  return
}
