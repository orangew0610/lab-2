; NOTE: Vector integer data manipulation instruction selection tests
; RUN: llc -march=matrix -o - %s | FileCheck %s

;; ===================================================================
;; Vector integer data manipulation instruction selection tests
;;
;; Instructions tested:
;;   SITL2/SITL4/SUBALE4H/SUBALE4L - scalar interleave/deinterleave
;;   VITL2/VITL4/VUBALE4H/VUBALE4L - vector interleave/deinterleave
;;   SBALE2/SBALE2H/SBALE2HL/SBALE2LH/SBALE4H/SBALE4L - scalar bale
;;   SSBALE2/SSBALE4 - scalar signed bale
;;   VBALE2/VBALE2H/VBALE2HL/VBALE2LH/VBALE4H/VBALE4L - vector bale
;;   VSBALE2/VSBALE4 - vector signed bale
;; ===================================================================

target triple = "matrix-unknown-unknown"

; --- Memory helper declarations ---
declare <32 x i32> @llvm.ftm.vldw(ptr addrspace(1), i64)
declare void @llvm.ftm.vstw(<32 x i32>, ptr addrspace(1), i64)

; --- Unary intrinsic declarations (scalar) ---
declare i64 @llvm.ftm.sitl2(i64)
declare i64 @llvm.ftm.sitl4(i64)
declare i64 @llvm.ftm.subale4h(i64)
declare i64 @llvm.ftm.subale4l(i64)

; --- Unary intrinsic declarations (vector) ---
declare <16 x i64> @llvm.ftm.vitl2(<16 x i64>)
declare <16 x i64> @llvm.ftm.vitl4(<16 x i64>)
declare <16 x i64> @llvm.ftm.vubale4h(<16 x i64>)
declare <16 x i64> @llvm.ftm.vubale4l(<16 x i64>)

; --- Binary intrinsic declarations (scalar) ---
declare i64 @llvm.ftm.sbale2(i64, i64)
declare i64 @llvm.ftm.sbale2h(i64, i64)
declare i64 @llvm.ftm.sbale2hl(i64, i64)
declare i64 @llvm.ftm.sbale2lh(i64, i64)
declare i64 @llvm.ftm.sbale4h(i64, i64)
declare i64 @llvm.ftm.sbale4l(i64, i64)
declare i64 @llvm.ftm.ssbale2(i64, i64)
declare i64 @llvm.ftm.ssbale4(i64, i64)

; --- Binary intrinsic declarations (vector) ---
declare <16 x i64> @llvm.ftm.vbale2(<16 x i64>, <16 x i64>)
declare <16 x i64> @llvm.ftm.vbale2h(<16 x i64>, <16 x i64>)
declare <16 x i64> @llvm.ftm.vbale2hl(<16 x i64>, <16 x i64>)
declare <16 x i64> @llvm.ftm.vbale2lh(<16 x i64>, <16 x i64>)
declare <16 x i64> @llvm.ftm.vbale4h(<16 x i64>, <16 x i64>)
declare <16 x i64> @llvm.ftm.vbale4l(<16 x i64>, <16 x i64>)
declare <16 x i64> @llvm.ftm.vsbale2(<16 x i64>, <16 x i64>)
declare <16 x i64> @llvm.ftm.vsbale4(<16 x i64>, <16 x i64>)

; ===================================================================
; Scalar unary tests
; ===================================================================

; CHECK-LABEL: @func test_sitl2
; CHECK: SITL2
define i64 @test_sitl2(i64 %a) {
  %r = call i64 @llvm.ftm.sitl2(i64 %a)
  ret i64 %r
}

; CHECK-LABEL: @func test_sitl4
; CHECK: SITL4
define i64 @test_sitl4(i64 %a) {
  %r = call i64 @llvm.ftm.sitl4(i64 %a)
  ret i64 %r
}

; CHECK-LABEL: @func test_subale4h
; CHECK: SUBALE4H
define i64 @test_subale4h(i64 %a) {
  %r = call i64 @llvm.ftm.subale4h(i64 %a)
  ret i64 %r
}

; CHECK-LABEL: @func test_subale4l
; CHECK: SUBALE4L
define i64 @test_subale4l(i64 %a) {
  %r = call i64 @llvm.ftm.subale4l(i64 %a)
  ret i64 %r
}

; ===================================================================
; Scalar binary tests
; ===================================================================

; CHECK-LABEL: @func test_sbale2
; CHECK: SBALE2
define i64 @test_sbale2(i64 %a, i64 %b) {
  %r = call i64 @llvm.ftm.sbale2(i64 %a, i64 %b)
  ret i64 %r
}

; CHECK-LABEL: @func test_sbale2h
; CHECK: SBALE2H
define i64 @test_sbale2h(i64 %a, i64 %b) {
  %r = call i64 @llvm.ftm.sbale2h(i64 %a, i64 %b)
  ret i64 %r
}

; CHECK-LABEL: @func test_sbale2hl
; CHECK: SBALE2HL
define i64 @test_sbale2hl(i64 %a, i64 %b) {
  %r = call i64 @llvm.ftm.sbale2hl(i64 %a, i64 %b)
  ret i64 %r
}

; CHECK-LABEL: @func test_sbale2lh
; CHECK: SBALE2LH
define i64 @test_sbale2lh(i64 %a, i64 %b) {
  %r = call i64 @llvm.ftm.sbale2lh(i64 %a, i64 %b)
  ret i64 %r
}

; CHECK-LABEL: @func test_sbale4h
; CHECK: SBALE4H
define i64 @test_sbale4h(i64 %a, i64 %b) {
  %r = call i64 @llvm.ftm.sbale4h(i64 %a, i64 %b)
  ret i64 %r
}

; CHECK-LABEL: @func test_sbale4l
; CHECK: SBALE4L
define i64 @test_sbale4l(i64 %a, i64 %b) {
  %r = call i64 @llvm.ftm.sbale4l(i64 %a, i64 %b)
  ret i64 %r
}

; CHECK-LABEL: @func test_ssbale2
; CHECK: SSBALE2
define i64 @test_ssbale2(i64 %a, i64 %b) {
  %r = call i64 @llvm.ftm.ssbale2(i64 %a, i64 %b)
  ret i64 %r
}

; CHECK-LABEL: @func test_ssbale4
; CHECK: SSBALE4
define i64 @test_ssbale4(i64 %a, i64 %b) {
  %r = call i64 @llvm.ftm.ssbale4(i64 %a, i64 %b)
  ret i64 %r
}

; ===================================================================
; Vector unary tests (load → bitcast → compute → bitcast → store)
; ===================================================================

; CHECK-LABEL: @func test_vitl2
; CHECK: VITL2
define void @test_vitl2(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %src = bitcast <32 x i32> %raw to <16 x i64>
  %r = call <16 x i64> @llvm.ftm.vitl2(<16 x i64> %src)
  %res = bitcast <16 x i64> %r to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vitl4
; CHECK: VITL4
define void @test_vitl4(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %src = bitcast <32 x i32> %raw to <16 x i64>
  %r = call <16 x i64> @llvm.ftm.vitl4(<16 x i64> %src)
  %res = bitcast <16 x i64> %r to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vubale4h
; CHECK: VUBALE4H
define void @test_vubale4h(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %src = bitcast <32 x i32> %raw to <16 x i64>
  %r = call <16 x i64> @llvm.ftm.vubale4h(<16 x i64> %src)
  %res = bitcast <16 x i64> %r to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vubale4l
; CHECK: VUBALE4L
define void @test_vubale4l(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %src = bitcast <32 x i32> %raw to <16 x i64>
  %r = call <16 x i64> @llvm.ftm.vubale4l(<16 x i64> %src)
  %res = bitcast <16 x i64> %r to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; Vector binary tests (load → bitcast → compute → bitcast → store)
; ===================================================================

; CHECK-LABEL: @func test_vbale2
; CHECK: VBALE2
define void @test_vbale2(ptr addrspace(1) %base, i64 %off) {
  %a_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %a_raw to <16 x i64>
  %b = bitcast <32 x i32> %b_raw to <16 x i64>
  %r = call <16 x i64> @llvm.ftm.vbale2(<16 x i64> %a, <16 x i64> %b)
  %res = bitcast <16 x i64> %r to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vbale2h
; CHECK: VBALE2H
define void @test_vbale2h(ptr addrspace(1) %base, i64 %off) {
  %a_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %a_raw to <16 x i64>
  %b = bitcast <32 x i32> %b_raw to <16 x i64>
  %r = call <16 x i64> @llvm.ftm.vbale2h(<16 x i64> %a, <16 x i64> %b)
  %res = bitcast <16 x i64> %r to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vbale2hl
; CHECK: VBALE2HL
define void @test_vbale2hl(ptr addrspace(1) %base, i64 %off) {
  %a_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %a_raw to <16 x i64>
  %b = bitcast <32 x i32> %b_raw to <16 x i64>
  %r = call <16 x i64> @llvm.ftm.vbale2hl(<16 x i64> %a, <16 x i64> %b)
  %res = bitcast <16 x i64> %r to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vbale2lh
; CHECK: VBALE2LH
define void @test_vbale2lh(ptr addrspace(1) %base, i64 %off) {
  %a_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %a_raw to <16 x i64>
  %b = bitcast <32 x i32> %b_raw to <16 x i64>
  %r = call <16 x i64> @llvm.ftm.vbale2lh(<16 x i64> %a, <16 x i64> %b)
  %res = bitcast <16 x i64> %r to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vbale4h
; CHECK: VBALE4H
define void @test_vbale4h(ptr addrspace(1) %base, i64 %off) {
  %a_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %a_raw to <16 x i64>
  %b = bitcast <32 x i32> %b_raw to <16 x i64>
  %r = call <16 x i64> @llvm.ftm.vbale4h(<16 x i64> %a, <16 x i64> %b)
  %res = bitcast <16 x i64> %r to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vbale4l
; CHECK: VBALE4L
define void @test_vbale4l(ptr addrspace(1) %base, i64 %off) {
  %a_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %a_raw to <16 x i64>
  %b = bitcast <32 x i32> %b_raw to <16 x i64>
  %r = call <16 x i64> @llvm.ftm.vbale4l(<16 x i64> %a, <16 x i64> %b)
  %res = bitcast <16 x i64> %r to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vsbale2
; CHECK: VSBALE2
define void @test_vsbale2(ptr addrspace(1) %base, i64 %off) {
  %a_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %a_raw to <16 x i64>
  %b = bitcast <32 x i32> %b_raw to <16 x i64>
  %r = call <16 x i64> @llvm.ftm.vsbale2(<16 x i64> %a, <16 x i64> %b)
  %res = bitcast <16 x i64> %r to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vsbale4
; CHECK: VSBALE4
define void @test_vsbale4(ptr addrspace(1) %base, i64 %off) {
  %a_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %a_raw to <16 x i64>
  %b = bitcast <32 x i32> %b_raw to <16 x i64>
  %r = call <16 x i64> @llvm.ftm.vsbale4(<16 x i64> %a, <16 x i64> %b)
  %res = bitcast <16 x i64> %r to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}
