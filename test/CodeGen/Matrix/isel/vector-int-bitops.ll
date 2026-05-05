; NOTE: Vector integer bit operations instruction selection tests
; RUN: llc -march=matrix -o - %s | FileCheck %s

;; ===================================================================
;; Vector integer bit operations instruction selection tests
;;
;; Instructions tested:
;;   VSHFLL/VSHFLR/VSHFAR (v16i64, v32i32) - vector shifts
;;   VBSET/VBCLR/VBEX/VBTST (v16i64, v32i32) - bit manipulation
;;   VBEXT/VBEXTU/VBEXT32/VBEXT32U - bit-field extraction
;; ===================================================================

target triple = "matrix-unknown-unknown"

; --- Memory helper declarations ---
declare <32 x i32> @llvm.ftm.vldw(ptr addrspace(1), i64)
declare void @llvm.ftm.vstw(<32 x i32>, ptr addrspace(1), i64)

; --- Bit manipulation intrinsics ---
declare <16 x i64> @llvm.ftm.vbset(<16 x i64>, <16 x i64>)
declare <16 x i64> @llvm.ftm.vbclr(<16 x i64>, <16 x i64>)
declare <16 x i64> @llvm.ftm.vbex(<16 x i64>, <16 x i64>)
declare <16 x i64> @llvm.ftm.vbtst(<16 x i64>, <16 x i64>)
declare <32 x i32> @llvm.ftm.vbset32(<32 x i32>, <32 x i32>)
declare <32 x i32> @llvm.ftm.vbclr32(<32 x i32>, <32 x i32>)
declare <32 x i32> @llvm.ftm.vbex32(<32 x i32>, <32 x i32>)
declare <32 x i32> @llvm.ftm.vbtst32(<32 x i32>, <32 x i32>)

; --- Bit-field extraction intrinsics ---
declare <16 x i64> @llvm.ftm.vbext(<16 x i64>, <16 x i64>)
declare <16 x i64> @llvm.ftm.vbextu(<16 x i64>, <16 x i64>)
declare <32 x i32> @llvm.ftm.vbext32(<32 x i32>, <32 x i32>)
declare <32 x i32> @llvm.ftm.vbext32u(<32 x i32>, <32 x i32>)

; ===================================================================
; Group A: Vector Shifts — register-register
; ===================================================================

; CHECK-LABEL: @func test_vshfll
; CHECK: VSHFLL
; CHECK: VSTW
define void @test_vshfll(ptr addrspace(1) %base, i64 %off) {
  %a_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %a_raw to <16 x i64>
  %b = bitcast <32 x i32> %b_raw to <16 x i64>
  %r = shl <16 x i64> %a, %b
  %r_raw = bitcast <16 x i64> %r to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %r_raw, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vshflr
; CHECK: VSHFLR
; CHECK: VSTW
define void @test_vshflr(ptr addrspace(1) %base, i64 %off) {
  %a_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %a_raw to <16 x i64>
  %b = bitcast <32 x i32> %b_raw to <16 x i64>
  %r = lshr <16 x i64> %a, %b
  %r_raw = bitcast <16 x i64> %r to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %r_raw, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vshfar
; CHECK: VSHFAR
; CHECK: VSTW
define void @test_vshfar(ptr addrspace(1) %base, i64 %off) {
  %a_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %a_raw to <16 x i64>
  %b = bitcast <32 x i32> %b_raw to <16 x i64>
  %r = ashr <16 x i64> %a, %b
  %r_raw = bitcast <16 x i64> %r to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %r_raw, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vshfll32
; CHECK: VSHFLL32
; CHECK: VSTW
define void @test_vshfll32(ptr addrspace(1) %base, i64 %off) {
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %r = shl <32 x i32> %a, %b
  call void @llvm.ftm.vstw(<32 x i32> %r, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vshflr32
; CHECK: VSHFLR32
; CHECK: VSTW
define void @test_vshflr32(ptr addrspace(1) %base, i64 %off) {
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %r = lshr <32 x i32> %a, %b
  call void @llvm.ftm.vstw(<32 x i32> %r, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vshfar32
; CHECK: VSHFAR32
; CHECK: VSTW
define void @test_vshfar32(ptr addrspace(1) %base, i64 %off) {
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %r = ashr <32 x i32> %a, %b
  call void @llvm.ftm.vstw(<32 x i32> %r, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; Group A: Vector Shifts — immediate (splat constant)
; ===================================================================

; CHECK-LABEL: @func test_vshfll_imm
; CHECK: VSHFLL 3
; CHECK: VSTW
define void @test_vshfll_imm(ptr addrspace(1) %base, i64 %off) {
  %a_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %a_raw to <16 x i64>
  %r = shl <16 x i64> %a, splat (i64 3)
  %r_raw = bitcast <16 x i64> %r to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %r_raw, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vshflr_imm
; CHECK: VSHFLR 5
; CHECK: VSTW
define void @test_vshflr_imm(ptr addrspace(1) %base, i64 %off) {
  %a_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %a_raw to <16 x i64>
  %r = lshr <16 x i64> %a, splat (i64 5)
  %r_raw = bitcast <16 x i64> %r to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %r_raw, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vshfar_imm
; CHECK: VSHFAR 7
; CHECK: VSTW
define void @test_vshfar_imm(ptr addrspace(1) %base, i64 %off) {
  %a_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %a_raw to <16 x i64>
  %r = ashr <16 x i64> %a, splat (i64 7)
  %r_raw = bitcast <16 x i64> %r to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %r_raw, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vshfll32_imm
; CHECK: VSHFLL32 4
; CHECK: VSTW
define void @test_vshfll32_imm(ptr addrspace(1) %base, i64 %off) {
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %r = shl <32 x i32> %a, splat (i32 4)
  call void @llvm.ftm.vstw(<32 x i32> %r, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vshflr32_imm
; CHECK: VSHFLR32 6
; CHECK: VSTW
define void @test_vshflr32_imm(ptr addrspace(1) %base, i64 %off) {
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %r = lshr <32 x i32> %a, splat (i32 6)
  call void @llvm.ftm.vstw(<32 x i32> %r, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vshfar32_imm
; CHECK: VSHFAR32 2
; CHECK: VSTW
define void @test_vshfar32_imm(ptr addrspace(1) %base, i64 %off) {
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %r = ashr <32 x i32> %a, splat (i32 2)
  call void @llvm.ftm.vstw(<32 x i32> %r, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; Group B: Bit Manipulation — v16i64
; ===================================================================

; CHECK-LABEL: @func test_vbset
; CHECK: VBSET
; CHECK: VSTW
define void @test_vbset(ptr addrspace(1) %base, i64 %off) {
  %a_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %a_raw to <16 x i64>
  %b = bitcast <32 x i32> %b_raw to <16 x i64>
  %r = call <16 x i64> @llvm.ftm.vbset(<16 x i64> %a, <16 x i64> %b)
  %r_raw = bitcast <16 x i64> %r to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %r_raw, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vbclr
; CHECK: VBCLR
; CHECK: VSTW
define void @test_vbclr(ptr addrspace(1) %base, i64 %off) {
  %a_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %a_raw to <16 x i64>
  %b = bitcast <32 x i32> %b_raw to <16 x i64>
  %r = call <16 x i64> @llvm.ftm.vbclr(<16 x i64> %a, <16 x i64> %b)
  %r_raw = bitcast <16 x i64> %r to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %r_raw, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vbex
; CHECK: VBEX
; CHECK: VSTW
define void @test_vbex(ptr addrspace(1) %base, i64 %off) {
  %a_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %a_raw to <16 x i64>
  %b = bitcast <32 x i32> %b_raw to <16 x i64>
  %r = call <16 x i64> @llvm.ftm.vbex(<16 x i64> %a, <16 x i64> %b)
  %r_raw = bitcast <16 x i64> %r to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %r_raw, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vbtst
; CHECK: VBTST
; CHECK: VSTW
define void @test_vbtst(ptr addrspace(1) %base, i64 %off) {
  %a_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %a_raw to <16 x i64>
  %b = bitcast <32 x i32> %b_raw to <16 x i64>
  %r = call <16 x i64> @llvm.ftm.vbtst(<16 x i64> %a, <16 x i64> %b)
  %r_raw = bitcast <16 x i64> %r to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %r_raw, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; Group B: Bit Manipulation — v32i32
; ===================================================================

; CHECK-LABEL: @func test_vbset32
; CHECK: VBSET32
; CHECK: VSTW
define void @test_vbset32(ptr addrspace(1) %base, i64 %off) {
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %r = call <32 x i32> @llvm.ftm.vbset32(<32 x i32> %a, <32 x i32> %b)
  call void @llvm.ftm.vstw(<32 x i32> %r, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vbclr32
; CHECK: VBCLR32
; CHECK: VSTW
define void @test_vbclr32(ptr addrspace(1) %base, i64 %off) {
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %r = call <32 x i32> @llvm.ftm.vbclr32(<32 x i32> %a, <32 x i32> %b)
  call void @llvm.ftm.vstw(<32 x i32> %r, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vbex32
; CHECK: VBEX32
; CHECK: VSTW
define void @test_vbex32(ptr addrspace(1) %base, i64 %off) {
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %r = call <32 x i32> @llvm.ftm.vbex32(<32 x i32> %a, <32 x i32> %b)
  call void @llvm.ftm.vstw(<32 x i32> %r, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vbtst32
; CHECK: VBTST32
; CHECK: VSTW
define void @test_vbtst32(ptr addrspace(1) %base, i64 %off) {
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %r = call <32 x i32> @llvm.ftm.vbtst32(<32 x i32> %a, <32 x i32> %b)
  call void @llvm.ftm.vstw(<32 x i32> %r, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; Group C: Bit-Field Extraction — v16i64
; ===================================================================

; CHECK-LABEL: @func test_vbext
; CHECK: VBEXT
; CHECK: VSTW
define void @test_vbext(ptr addrspace(1) %base, i64 %off) {
  %a_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %a_raw to <16 x i64>
  %b = bitcast <32 x i32> %b_raw to <16 x i64>
  %r = call <16 x i64> @llvm.ftm.vbext(<16 x i64> %a, <16 x i64> %b)
  %r_raw = bitcast <16 x i64> %r to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %r_raw, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vbextu
; CHECK: VBEXTU
; CHECK: VSTW
define void @test_vbextu(ptr addrspace(1) %base, i64 %off) {
  %a_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %a_raw to <16 x i64>
  %b = bitcast <32 x i32> %b_raw to <16 x i64>
  %r = call <16 x i64> @llvm.ftm.vbextu(<16 x i64> %a, <16 x i64> %b)
  %r_raw = bitcast <16 x i64> %r to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %r_raw, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; Group C: Bit-Field Extraction — v32i32
; ===================================================================

; CHECK-LABEL: @func test_vbext32
; CHECK: VBEXT32
; CHECK: VSTW
define void @test_vbext32(ptr addrspace(1) %base, i64 %off) {
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %r = call <32 x i32> @llvm.ftm.vbext32(<32 x i32> %a, <32 x i32> %b)
  call void @llvm.ftm.vstw(<32 x i32> %r, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vbext32u
; CHECK: VBEXT32U
; CHECK: VSTW
define void @test_vbext32u(ptr addrspace(1) %base, i64 %off) {
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %r = call <32 x i32> @llvm.ftm.vbext32u(<32 x i32> %a, <32 x i32> %b)
  call void @llvm.ftm.vstw(<32 x i32> %r, ptr addrspace(1) %base, i64 %off)
  ret void
}
