; NOTE: Scalar floating-point special function instruction selection tests
; RUN: llc -march=matrix -o - %s | FileCheck %s

;; ===================================================================
;; Scalar floating-point special function instruction selection tests
;;
;; Instructions tested:
;;   SFSRT8D/SFNORMD - f64 division (reciprocal iteration)
;;   SFSRT8S32/SFNORMS32 - v2f32 division
;;   SFMFSQS32/SFMFSINS32/SFMFCOSS32 - v2f32 sqrt/sin/cos
;;   SFMFEXPS32/SFMFLOGS32 - v2f32 exp2/log2
;;   SFMFRCPS32/SFMFRSQS32 - v2f32 reciprocal/rsqrt
;;   SFLOGH16/SFMANH16 - h16 log/mantissa
;;   SFEXTH16HH/HL/LH/LL - h16 extract/broadcast
;;   SFEXTS32H/L - v2f32 extract/broadcast
;;   SFCMULH16/SFDOTH16 - h16 complex mul/dot
;;   SFMULAHHS/SFMULAHLS - mixed h16×f32 FMA
;;   SFLOGD/SFLOGS32/SFMAND/SFMANS32 - exponent/mantissa extraction
;;   SFRCPD/SFRCPS32/SFRSQD/SFRSQS32 - reciprocal approximation
;; ===================================================================

target triple = "matrix-unknown-unknown"

declare <2 x float> @llvm.sqrt.v2f32(<2 x float>)
declare <2 x float> @llvm.sin.v2f32(<2 x float>)
declare <2 x float> @llvm.cos.v2f32(<2 x float>)
declare <2 x float> @llvm.exp2.v2f32(<2 x float>)
declare <2 x float> @llvm.log2.v2f32(<2 x float>)
declare <4 x half> @llvm.ftm.sflogh16(<4 x half>)
declare <4 x i16> @llvm.ftm.sfmanh16(<4 x half>)
declare <4 x half> @llvm.ftm.sfexth16hh(<4 x half>)
declare <4 x half> @llvm.ftm.sfexth16hl(<4 x half>)
declare <4 x half> @llvm.ftm.sfexth16lh(<4 x half>)
declare <4 x half> @llvm.ftm.sfexth16ll(<4 x half>)
declare <2 x float> @llvm.ftm.sfexts32h(<2 x float>)
declare <2 x float> @llvm.ftm.sfexts32l(<2 x float>)
declare <4 x half> @llvm.ftm.sfcmulh16(<4 x half>, <4 x half>)
declare <4 x half> @llvm.ftm.sfdoth16(<4 x half>, <4 x half>)
declare <2 x float> @llvm.ftm.sfmulahhs(<4 x half>, <4 x half>, <2 x float>)
declare <2 x float> @llvm.ftm.sfmulahls(<4 x half>, <4 x half>, <2 x float>)
declare i64 @llvm.ftm.sflogd(double)
declare <2 x i32> @llvm.ftm.sflogs32(<2 x float>)
declare i64 @llvm.ftm.sfmand(double)
declare <2 x i32> @llvm.ftm.sfmans32(<2 x float>)
declare double @llvm.ftm.sfrcpd(double)
declare <2 x float> @llvm.ftm.sfrcps32(<2 x float>)
declare double @llvm.ftm.sfrsqd(double)
declare <2 x float> @llvm.ftm.sfrsqs32(<2 x float>)

;; ==================== f64/v2f32 Division ====================

; CHECK-LABEL: @func fdiv_f64
; CHECK: SMOVI 0,
; CHECK: SFSRT8D
; CHECK: SFSRT8D
; CHECK: SFSRT8D
; CHECK: SFNORMD
define double @fdiv_f64(double %a, double %b) {
  %r = fdiv double %a, %b
  ret double %r
}

; CHECK-LABEL: @func fdiv_v2f32
; CHECK: SMOVI 0,
; CHECK: SFSRT8S32
; CHECK: SFSRT8S32
; CHECK: SFSRT8S32
; CHECK: SFNORMS32
define <2 x float> @fdiv_v2f32(<2 x float> %a, <2 x float> %b) {
  %r = fdiv <2 x float> %a, %b
  ret <2 x float> %r
}

; Verify v2f32 reciprocal still uses SFMFRCPS32 (not SFSRT8S32)
; CHECK-LABEL: @func frcp_v2f32
; CHECK: SFMFRCPS32
; CHECK-NOT: SFSRT8S32
; CHECK-NOT: SFNORMS32
define <2 x float> @frcp_v2f32(<2 x float> %a) {
  %r = fdiv <2 x float> <float 1.0, float 1.0>, %a
  ret <2 x float> %r
}

;; ==================== v2f32 Math Functions ====================

; --- v2f32 square root: llvm.sqrt → SFMFSQS32 ---
define <2 x float> @test_sqrt(<2 x float> %a) {
; CHECK-LABEL: @func test_sqrt
; CHECK: SFMFSQS32
  %result = call <2 x float> @llvm.sqrt.v2f32(<2 x float> %a)
  ret <2 x float> %result
}

; --- v2f32 sine: llvm.sin → SFMFSINS32 ---
define <2 x float> @test_sin(<2 x float> %a) {
; CHECK-LABEL: @func test_sin
; CHECK: SFMFSINS32
  %result = call <2 x float> @llvm.sin.v2f32(<2 x float> %a)
  ret <2 x float> %result
}

; --- v2f32 cosine: llvm.cos → SFMFCOSS32 ---
define <2 x float> @test_cos(<2 x float> %a) {
; CHECK-LABEL: @func test_cos
; CHECK: SFMFCOSS32
  %result = call <2 x float> @llvm.cos.v2f32(<2 x float> %a)
  ret <2 x float> %result
}

; --- v2f32 base-2 exponent: llvm.exp2 → SFMFEXPS32 ---
define <2 x float> @test_exp2(<2 x float> %a) {
; CHECK-LABEL: @func test_exp2
; CHECK: SFMFEXPS32
  %result = call <2 x float> @llvm.exp2.v2f32(<2 x float> %a)
  ret <2 x float> %result
}

; --- v2f32 base-2 logarithm: llvm.log2 → SFMFLOGS32 ---
define <2 x float> @test_log2(<2 x float> %a) {
; CHECK-LABEL: @func test_log2
; CHECK: SFMFLOGS32
  %result = call <2 x float> @llvm.log2.v2f32(<2 x float> %a)
  ret <2 x float> %result
}

; --- v2f32 reciprocal: fdiv <1.0, 1.0>, x → SFMFRCPS32 ---
define <2 x float> @test_rcp(<2 x float> %a) {
; CHECK-LABEL: @func test_rcp
; CHECK: SFMFRCPS32
; CHECK-NOT: FDIV
  %result = fdiv <2 x float> <float 1.0, float 1.0>, %a
  ret <2 x float> %result
}

; --- v2f32 reciprocal square root: fdiv <1.0, 1.0>, sqrt(x) → SFMFRSQS32 ---
define <2 x float> @test_rsqrt(<2 x float> %a) {
; CHECK-LABEL: @func test_rsqrt
; CHECK: SFMFRSQS32
; CHECK-NOT: SFMFSQS32
; CHECK-NOT: SFMFRCPS32
  %sq = call <2 x float> @llvm.sqrt.v2f32(<2 x float> %a)
  %result = fdiv <2 x float> <float 1.0, float 1.0>, %sq
  ret <2 x float> %result
}

;; ==================== h16 Special Operations ====================

; CHECK-LABEL: @func test_sflogh16
; CHECK: SFLOGH16
define <4 x half> @test_sflogh16(<4 x half> %a) {
  %res = call <4 x half> @llvm.ftm.sflogh16(<4 x half> %a)
  ret <4 x half> %res
}

; CHECK-LABEL: @func test_sfmanh16
; CHECK: SFMANH16
define <4 x i16> @test_sfmanh16(<4 x half> %a) {
  %res = call <4 x i16> @llvm.ftm.sfmanh16(<4 x half> %a)
  ret <4 x i16> %res
}

; CHECK-LABEL: @func test_sfexth16hh
; CHECK: SFEXTH16HH
define <4 x half> @test_sfexth16hh(<4 x half> %a) {
  %res = call <4 x half> @llvm.ftm.sfexth16hh(<4 x half> %a)
  ret <4 x half> %res
}

; CHECK-LABEL: @func test_sfexth16hl
; CHECK: SFEXTH16HL
define <4 x half> @test_sfexth16hl(<4 x half> %a) {
  %res = call <4 x half> @llvm.ftm.sfexth16hl(<4 x half> %a)
  ret <4 x half> %res
}

; CHECK-LABEL: @func test_sfexth16lh
; CHECK: SFEXTH16LH
define <4 x half> @test_sfexth16lh(<4 x half> %a) {
  %res = call <4 x half> @llvm.ftm.sfexth16lh(<4 x half> %a)
  ret <4 x half> %res
}

; CHECK-LABEL: @func test_sfexth16ll
; CHECK: SFEXTH16LL
define <4 x half> @test_sfexth16ll(<4 x half> %a) {
  %res = call <4 x half> @llvm.ftm.sfexth16ll(<4 x half> %a)
  ret <4 x half> %res
}

; CHECK-LABEL: @func test_sfexts32h
; CHECK: SFEXTS32H
define <2 x float> @test_sfexts32h(<2 x float> %a) {
  %res = call <2 x float> @llvm.ftm.sfexts32h(<2 x float> %a)
  ret <2 x float> %res
}

; CHECK-LABEL: @func test_sfexts32l
; CHECK: SFEXTS32L
define <2 x float> @test_sfexts32l(<2 x float> %a) {
  %res = call <2 x float> @llvm.ftm.sfexts32l(<2 x float> %a)
  ret <2 x float> %res
}

; CHECK-LABEL: @func test_sfcmulh16
; CHECK: SFCMULH16
define <4 x half> @test_sfcmulh16(<4 x half> %a, <4 x half> %b) {
  %res = call <4 x half> @llvm.ftm.sfcmulh16(<4 x half> %a, <4 x half> %b)
  ret <4 x half> %res
}

; CHECK-LABEL: @func test_sfdoth16
; CHECK: SFDOTH16
define <4 x half> @test_sfdoth16(<4 x half> %a, <4 x half> %b) {
  %res = call <4 x half> @llvm.ftm.sfdoth16(<4 x half> %a, <4 x half> %b)
  ret <4 x half> %res
}

; CHECK-LABEL: @func test_sfmulahhs
; CHECK: SFMULAHHS
define <2 x float> @test_sfmulahhs(<4 x half> %a, <4 x half> %b, <2 x float> %c) {
  %res = call <2 x float> @llvm.ftm.sfmulahhs(<4 x half> %a, <4 x half> %b, <2 x float> %c)
  ret <2 x float> %res
}

; CHECK-LABEL: @func test_sfmulahls
; CHECK: SFMULAHLS
define <2 x float> @test_sfmulahls(<4 x half> %a, <4 x half> %b, <2 x float> %c) {
  %res = call <2 x float> @llvm.ftm.sfmulahls(<4 x half> %a, <4 x half> %b, <2 x float> %c)
  ret <2 x float> %res
}

;; ==================== Scalar Exponent/Mantissa Extraction ====================

; CHECK-LABEL: @func test_sflogd
; CHECK: SFLOGD
define i64 @test_sflogd(double %a) {
  %r = call i64 @llvm.ftm.sflogd(double %a)
  ret i64 %r
}

; CHECK-LABEL: @func test_sflogs32
; CHECK: SFLOGS32
define <2 x i32> @test_sflogs32(<2 x float> %a) {
  %r = call <2 x i32> @llvm.ftm.sflogs32(<2 x float> %a)
  ret <2 x i32> %r
}

; CHECK-LABEL: @func test_sfmand
; CHECK: SFMAND
define i64 @test_sfmand(double %a) {
  %r = call i64 @llvm.ftm.sfmand(double %a)
  ret i64 %r
}

; CHECK-LABEL: @func test_sfmans32
; CHECK: SFMANS32
define <2 x i32> @test_sfmans32(<2 x float> %a) {
  %r = call <2 x i32> @llvm.ftm.sfmans32(<2 x float> %a)
  ret <2 x i32> %r
}

;; ==================== Scalar Reciprocal Approximation ====================

; CHECK-LABEL: @func test_sfrcpd
; CHECK: SFRCPD
define double @test_sfrcpd(double %x) {
  %res = call double @llvm.ftm.sfrcpd(double %x)
  ret double %res
}

; CHECK-LABEL: @func test_sfrcps32
; CHECK: SFRCPS32
define <2 x float> @test_sfrcps32(<2 x float> %x) {
  %res = call <2 x float> @llvm.ftm.sfrcps32(<2 x float> %x)
  ret <2 x float> %res
}

; CHECK-LABEL: @func test_sfrsqd
; CHECK: SFRSQD
define double @test_sfrsqd(double %x) {
  %res = call double @llvm.ftm.sfrsqd(double %x)
  ret double %res
}

; CHECK-LABEL: @func test_sfrsqs32
; CHECK: SFRSQS32
define <2 x float> @test_sfrsqs32(<2 x float> %x) {
  %res = call <2 x float> @llvm.ftm.sfrsqs32(<2 x float> %x)
  ret <2 x float> %res
}
