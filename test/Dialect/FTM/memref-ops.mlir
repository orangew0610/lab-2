// NOTE: FTM dialect memref-based vector load/store operation tests.
//
// Test 1: MLIR roundtrip — verify parsing and printing of memref ops.
// RUN: mlir-opt %s | mlir-opt | FileCheck %s --check-prefix=ROUNDTRIP
//
// Test 2: Lowering to LLVM IR — verify memref ops lower to llvm.call_intrinsic.
// RUN: mlir-opt --convert-to-llvm %s \
// RUN:   | mlir-translate --mlir-to-llvmir \
// RUN:   | FileCheck %s --check-prefix=LLVMIR
//
// ===================================================================
// FTM dialect memref-based vector load/store operation tests
//
// Operations tested:
//   ftm.vload_h    — halfword signed load   (i16 memref → v32xi32)
//   ftm.vload_hu   — halfword unsigned load  (i16 memref → v32xi32)
//   ftm.vload_w    — word load               (i32 memref → v32xi32)
//   ftm.vload_dw   — doubleword load         (i64 memref → v32xi64)
//   ftm.vload_dwm2 / dw0m2 / dw1m2 / dw0m4 / dw1m4 — DW load variants
//   ftm.vstore_h   — halfword store          (v32xi32, i16 memref)
//   ftm.vstore_w   — word store              (v32xi32, i32 memref)
//   ftm.vstore_dw  — doubleword store        (v32xi64, i64 memref)
//   ftm.vstore_dwm16 / dw0m16 / dw1m16 / dw0m32 / dw1m32 — DW store variants
// ===================================================================

// ===================================================================
// Group 1: Vector Loads — halfword (i16 memref → vector<32xi32>)
// ===================================================================

// ROUNDTRIP-LABEL: func.func @vload_h
// LLVMIR-LABEL: define <32 x i32> @vload_h
func.func @vload_h(%mem: memref<128xi16>, %idx: index) -> vector<32xi32> {
  // ROUNDTRIP: ftm.vload_h %{{.*}}[%{{.*}}] : memref<128xi16> -> vector<32xi32>
  // LLVMIR: call <32 x i32> @llvm.ftm.vldh(ptr addrspace(1) %{{.*}}, i64 %{{.*}})
  %0 = ftm.vload_h %mem[%idx] : memref<128xi16> -> vector<32xi32>
  return %0 : vector<32xi32>
}

// ROUNDTRIP-LABEL: func.func @vload_hu
// LLVMIR-LABEL: define <32 x i32> @vload_hu
func.func @vload_hu(%mem: memref<128xi16>, %idx: index) -> vector<32xi32> {
  // ROUNDTRIP: ftm.vload_hu %{{.*}}[%{{.*}}] : memref<128xi16> -> vector<32xi32>
  // LLVMIR: call <32 x i32> @llvm.ftm.vldhu(ptr addrspace(1) %{{.*}}, i64 %{{.*}})
  %0 = ftm.vload_hu %mem[%idx] : memref<128xi16> -> vector<32xi32>
  return %0 : vector<32xi32>
}

// ===================================================================
// Group 2: Vector Loads — word (i32 memref → vector<32xi32>)
// ===================================================================

// ROUNDTRIP-LABEL: func.func @vload_w
// LLVMIR-LABEL: define <32 x i32> @vload_w
func.func @vload_w(%mem: memref<1024xi32>, %idx: index) -> vector<32xi32> {
  // ROUNDTRIP: ftm.vload_w %{{.*}}[%{{.*}}] : memref<1024xi32> -> vector<32xi32>
  // LLVMIR: call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %{{.*}}, i64 %{{.*}})
  %0 = ftm.vload_w %mem[%idx] : memref<1024xi32> -> vector<32xi32>
  return %0 : vector<32xi32>
}

// ROUNDTRIP-LABEL: func.func @vload_w_2d
// LLVMIR-LABEL: define <32 x i32> @vload_w_2d
func.func @vload_w_2d(%mem: memref<4x32xi32>, %i: index, %j: index) -> vector<32xi32> {
  // ROUNDTRIP: ftm.vload_w %{{.*}}[%{{.*}}, %{{.*}}] : memref<4x32xi32> -> vector<32xi32>
  // LLVMIR: call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %{{.*}}, i64 %{{.*}})
  %0 = ftm.vload_w %mem[%i, %j] : memref<4x32xi32> -> vector<32xi32>
  return %0 : vector<32xi32>
}

// ===================================================================
// Group 3: Vector Loads — doubleword (i64 memref → vector<32xi64>)
// ===================================================================

// ROUNDTRIP-LABEL: func.func @vload_dw
// LLVMIR-LABEL: define <32 x i64> @vload_dw
func.func @vload_dw(%mem: memref<512xi64>, %idx: index) -> vector<32xi64> {
  // ROUNDTRIP: ftm.vload_dw %{{.*}}[%{{.*}}] : memref<512xi64> -> vector<32xi64>
  // LLVMIR: call <32 x i64> @llvm.ftm.vlddw(ptr addrspace(1) %{{.*}}, i64 %{{.*}})
  %0 = ftm.vload_dw %mem[%idx] : memref<512xi64> -> vector<32xi64>
  return %0 : vector<32xi64>
}

// ROUNDTRIP-LABEL: func.func @vload_dwm2
// LLVMIR-LABEL: define <32 x i64> @vload_dwm2
func.func @vload_dwm2(%mem: memref<256xi64>, %idx: index) -> vector<32xi64> {
  // ROUNDTRIP: ftm.vload_dwm2 %{{.*}}[%{{.*}}] : memref<256xi64> -> vector<32xi64>
  // LLVMIR: call <32 x i64> @llvm.ftm.vlddwm2(ptr addrspace(1) %{{.*}}, i64 %{{.*}})
  %0 = ftm.vload_dwm2 %mem[%idx] : memref<256xi64> -> vector<32xi64>
  return %0 : vector<32xi64>
}

// ROUNDTRIP-LABEL: func.func @vload_dw0m2
// LLVMIR-LABEL: define <32 x i64> @vload_dw0m2
func.func @vload_dw0m2(%mem: memref<256xi64>, %idx: index) -> vector<32xi64> {
  // ROUNDTRIP: ftm.vload_dw0m2 %{{.*}}[%{{.*}}] : memref<256xi64> -> vector<32xi64>
  // LLVMIR: call <32 x i64> @llvm.ftm.vlddw0m2(ptr addrspace(1) %{{.*}}, i64 %{{.*}})
  %0 = ftm.vload_dw0m2 %mem[%idx] : memref<256xi64> -> vector<32xi64>
  return %0 : vector<32xi64>
}

// ROUNDTRIP-LABEL: func.func @vload_dw1m2
// LLVMIR-LABEL: define <32 x i64> @vload_dw1m2
func.func @vload_dw1m2(%mem: memref<256xi64>, %idx: index) -> vector<32xi64> {
  // ROUNDTRIP: ftm.vload_dw1m2 %{{.*}}[%{{.*}}] : memref<256xi64> -> vector<32xi64>
  // LLVMIR: call <32 x i64> @llvm.ftm.vlddw1m2(ptr addrspace(1) %{{.*}}, i64 %{{.*}})
  %0 = ftm.vload_dw1m2 %mem[%idx] : memref<256xi64> -> vector<32xi64>
  return %0 : vector<32xi64>
}

// ROUNDTRIP-LABEL: func.func @vload_dw0m4
// LLVMIR-LABEL: define <32 x i64> @vload_dw0m4
func.func @vload_dw0m4(%mem: memref<256xi64>, %idx: index) -> vector<32xi64> {
  // ROUNDTRIP: ftm.vload_dw0m4 %{{.*}}[%{{.*}}] : memref<256xi64> -> vector<32xi64>
  // LLVMIR: call <32 x i64> @llvm.ftm.vlddw0m4(ptr addrspace(1) %{{.*}}, i64 %{{.*}})
  %0 = ftm.vload_dw0m4 %mem[%idx] : memref<256xi64> -> vector<32xi64>
  return %0 : vector<32xi64>
}

// ROUNDTRIP-LABEL: func.func @vload_dw1m4
// LLVMIR-LABEL: define <32 x i64> @vload_dw1m4
func.func @vload_dw1m4(%mem: memref<256xi64>, %idx: index) -> vector<32xi64> {
  // ROUNDTRIP: ftm.vload_dw1m4 %{{.*}}[%{{.*}}] : memref<256xi64> -> vector<32xi64>
  // LLVMIR: call <32 x i64> @llvm.ftm.vlddw1m4(ptr addrspace(1) %{{.*}}, i64 %{{.*}})
  %0 = ftm.vload_dw1m4 %mem[%idx] : memref<256xi64> -> vector<32xi64>
  return %0 : vector<32xi64>
}

// ===================================================================
// Group 4: Vector Stores — halfword
// ===================================================================

// ROUNDTRIP-LABEL: func.func @vstore_h
// LLVMIR-LABEL: define void @vstore_h
func.func @vstore_h(%data: vector<32xi32>, %mem: memref<128xi16>, %idx: index) {
  // ROUNDTRIP: ftm.vstore_h %{{.*}}, %{{.*}}[%{{.*}}] : vector<32xi32>, memref<128xi16>
  // LLVMIR: call void @llvm.ftm.vsth(<32 x i32> %{{.*}}, ptr addrspace(1) %{{.*}}, i64 %{{.*}})
  ftm.vstore_h %data, %mem[%idx] : vector<32xi32>, memref<128xi16>
  return
}

// ===================================================================
// Group 5: Vector Stores — word
// ===================================================================

// ROUNDTRIP-LABEL: func.func @vstore_w
// LLVMIR-LABEL: define void @vstore_w
func.func @vstore_w(%data: vector<32xi32>, %mem: memref<1024xi32>, %idx: index) {
  // ROUNDTRIP: ftm.vstore_w %{{.*}}, %{{.*}}[%{{.*}}] : vector<32xi32>, memref<1024xi32>
  // LLVMIR: call void @llvm.ftm.vstw(<32 x i32> %{{.*}}, ptr addrspace(1) %{{.*}}, i64 %{{.*}})
  ftm.vstore_w %data, %mem[%idx] : vector<32xi32>, memref<1024xi32>
  return
}

// ROUNDTRIP-LABEL: func.func @vstore_w_2d
// LLVMIR-LABEL: define void @vstore_w_2d
func.func @vstore_w_2d(%data: vector<32xi32>, %mem: memref<4x32xi32>, %i: index, %j: index) {
  // ROUNDTRIP: ftm.vstore_w %{{.*}}, %{{.*}}[%{{.*}}, %{{.*}}] : vector<32xi32>, memref<4x32xi32>
  // LLVMIR: call void @llvm.ftm.vstw(<32 x i32> %{{.*}}, ptr addrspace(1) %{{.*}}, i64 %{{.*}})
  ftm.vstore_w %data, %mem[%i, %j] : vector<32xi32>, memref<4x32xi32>
  return
}

// ===================================================================
// Group 6: Vector Stores — doubleword (all variants)
// ===================================================================

// ROUNDTRIP-LABEL: func.func @vstore_dw
// LLVMIR-LABEL: define void @vstore_dw
func.func @vstore_dw(%data: vector<32xi64>, %mem: memref<512xi64>, %idx: index) {
  // ROUNDTRIP: ftm.vstore_dw %{{.*}}, %{{.*}}[%{{.*}}] : vector<32xi64>, memref<512xi64>
  // LLVMIR: call void @llvm.ftm.vstdw(<32 x i64> %{{.*}}, ptr addrspace(1) %{{.*}}, i64 %{{.*}})
  ftm.vstore_dw %data, %mem[%idx] : vector<32xi64>, memref<512xi64>
  return
}

// ROUNDTRIP-LABEL: func.func @vstore_dwm16
// LLVMIR-LABEL: define void @vstore_dwm16
func.func @vstore_dwm16(%data: vector<32xi64>, %mem: memref<256xi64>, %idx: index) {
  // ROUNDTRIP: ftm.vstore_dwm16 %{{.*}}, %{{.*}}[%{{.*}}] : vector<32xi64>, memref<256xi64>
  // LLVMIR: call void @llvm.ftm.vstdwm16(<32 x i64> %{{.*}}, ptr addrspace(1) %{{.*}}, i64 %{{.*}})
  ftm.vstore_dwm16 %data, %mem[%idx] : vector<32xi64>, memref<256xi64>
  return
}

// ROUNDTRIP-LABEL: func.func @vstore_dw0m16
// LLVMIR-LABEL: define void @vstore_dw0m16
func.func @vstore_dw0m16(%data: vector<32xi64>, %mem: memref<256xi64>, %idx: index) {
  // ROUNDTRIP: ftm.vstore_dw0m16 %{{.*}}, %{{.*}}[%{{.*}}] : vector<32xi64>, memref<256xi64>
  // LLVMIR: call void @llvm.ftm.vstdw0m16(<32 x i64> %{{.*}}, ptr addrspace(1) %{{.*}}, i64 %{{.*}})
  ftm.vstore_dw0m16 %data, %mem[%idx] : vector<32xi64>, memref<256xi64>
  return
}

// ROUNDTRIP-LABEL: func.func @vstore_dw1m16
// LLVMIR-LABEL: define void @vstore_dw1m16
func.func @vstore_dw1m16(%data: vector<32xi64>, %mem: memref<256xi64>, %idx: index) {
  // ROUNDTRIP: ftm.vstore_dw1m16 %{{.*}}, %{{.*}}[%{{.*}}] : vector<32xi64>, memref<256xi64>
  // LLVMIR: call void @llvm.ftm.vstdw1m16(<32 x i64> %{{.*}}, ptr addrspace(1) %{{.*}}, i64 %{{.*}})
  ftm.vstore_dw1m16 %data, %mem[%idx] : vector<32xi64>, memref<256xi64>
  return
}

// ROUNDTRIP-LABEL: func.func @vstore_dw0m32
// LLVMIR-LABEL: define void @vstore_dw0m32
func.func @vstore_dw0m32(%data: vector<32xi64>, %mem: memref<256xi64>, %idx: index) {
  // ROUNDTRIP: ftm.vstore_dw0m32 %{{.*}}, %{{.*}}[%{{.*}}] : vector<32xi64>, memref<256xi64>
  // LLVMIR: call void @llvm.ftm.vstdw0m32(<32 x i64> %{{.*}}, ptr addrspace(1) %{{.*}}, i64 %{{.*}})
  ftm.vstore_dw0m32 %data, %mem[%idx] : vector<32xi64>, memref<256xi64>
  return
}

// ROUNDTRIP-LABEL: func.func @vstore_dw1m32
// LLVMIR-LABEL: define void @vstore_dw1m32
func.func @vstore_dw1m32(%data: vector<32xi64>, %mem: memref<256xi64>, %idx: index) {
  // ROUNDTRIP: ftm.vstore_dw1m32 %{{.*}}, %{{.*}}[%{{.*}}] : vector<32xi64>, memref<256xi64>
  // LLVMIR: call void @llvm.ftm.vstdw1m32(<32 x i64> %{{.*}}, ptr addrspace(1) %{{.*}}, i64 %{{.*}})
  ftm.vstore_dw1m32 %data, %mem[%idx] : vector<32xi64>, memref<256xi64>
  return
}
