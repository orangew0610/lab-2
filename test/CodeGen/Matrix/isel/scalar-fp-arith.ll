; NOTE: Scalar floating-point arithmetic instruction selection tests
; RUN: llc -march=matrix -o - %s | FileCheck %s

;; ===================================================================
;; Scalar floating-point arithmetic instruction selection tests
;;
;; Instructions tested:
;;   SFADDD/SFSUBD/SFMULD/SFMULAD/SFMULBD/SFMAXD - f64 arith
;;   SFABSD/SFABSS32/SFABSH16 - FP absolute value
;;   SMOVI - FP constant materialization
;;   SFADDS32/SFSUBS32/SFMULS32/SFMULAS32 - v2f32 arith
;;   SFDOT32/SFCMUL32/SFMULBS32 - v2f32 special ops
;;   SFADDH16/SFSUBH16/SFMULH16/SFMAX16 - h16 arith
;;   SFABSH16/SFMULAH16/SFMULBH16 - h16 FMA
;; ===================================================================

target triple = "matrix-unknown-unknown"

declare double @llvm.fma.f64(double, double, double)
declare double @llvm.maxnum.f64(double, double)
declare double @llvm.fabs.f64(double)
declare <2 x float> @llvm.fabs.v2f32(<2 x float>)
declare i64 @llvm.ftm.sfabsh16(i64)
declare <2 x float> @llvm.fma.v2f32(<2 x float>, <2 x float>, <2 x float>)
declare <2 x float> @llvm.ftm.sfdot32(<2 x float>, <2 x float>)
declare <2 x float> @llvm.ftm.sfcmul32(<2 x float>, <2 x float>)
declare <2 x float> @llvm.ftm.sfmulbs32(<2 x float>, <2 x float>, <2 x float>)
declare <4 x half> @llvm.fabs.v4f16(<4 x half>)
declare <4 x half> @llvm.fma.v4f16(<4 x half>, <4 x half>, <4 x half>)
declare <4 x half> @llvm.maxnum.v4f16(<4 x half>, <4 x half>)

;; ==================== f64 Arithmetic ====================

; --- f64 addition: fadd → SFADDD ---
define double @test_fadd(double %a, double %b) {
; CHECK-LABEL: @func test_fadd
; CHECK: SFADDD
  %result = fadd double %a, %b
  ret double %result
}

; --- f64 subtraction: fsub → SFSUBD ---
define double @test_fsub(double %a, double %b) {
; CHECK-LABEL: @func test_fsub
; CHECK: SFSUBD
  %result = fsub double %a, %b
  ret double %result
}

; --- f64 multiplication: fmul → SFMULD ---
define double @test_fmul(double %a, double %b) {
; CHECK-LABEL: @func test_fmul
; CHECK: SFMULD
  %result = fmul double %a, %b
  ret double %result
}

; --- f64 llvm.fma intrinsic → SFMULAD ---
define double @test_fma(double %a, double %b, double %c) {
; CHECK-LABEL: @func test_fma
; CHECK: SFMULAD
  %result = call double @llvm.fma.f64(double %a, double %b, double %c)
  ret double %result
}

; --- f64 DAGCombine: (fadd (fmul a, b), c) → SFMULAD ---
define double @test_fmadd(double %a, double %b, double %c) {
; CHECK-LABEL: @func test_fmadd
; CHECK: SFMULAD
; CHECK-NOT: SFMULD
; CHECK-NOT: SFADDD
  %mul = fmul double %a, %b
  %result = fadd double %mul, %c
  ret double %result
}

; --- f64 DAGCombine commutative: (fadd c, (fmul a, b)) → SFMULAD ---
define double @test_fmadd_commute(double %a, double %b, double %c) {
; CHECK-LABEL: @func test_fmadd_commute
; CHECK: SFMULAD
; CHECK-NOT: SFMULD
; CHECK-NOT: SFADDD
  %mul = fmul double %a, %b
  %result = fadd double %c, %mul
  ret double %result
}

; --- f64 DAGCombine: (fsub (fmul a, b), c) → SFMULBD ---
define double @test_fmsub(double %a, double %b, double %c) {
; CHECK-LABEL: @func test_fmsub
; CHECK: SFMULBD
; CHECK-NOT: SFMULD
; CHECK-NOT: SFSUBD
  %mul = fmul double %a, %b
  %result = fsub double %mul, %c
  ret double %result
}

; --- f64 llvm.maxnum → SFMAXD ---
define double @test_fmaxnum(double %a, double %b) {
; CHECK-LABEL: @func test_fmaxnum
; CHECK: SFMAXD
  %result = call double @llvm.maxnum.f64(double %a, double %b)
  ret double %result
}

;; ==================== FP Absolute Value (SFABSD/SFABSS32/SFABSH16) ====================

; CHECK-LABEL: @func test_sfabsd
; CHECK: SFABSD
define double @test_sfabsd(double %a) {
  %res = call double @llvm.fabs.f64(double %a)
  ret double %res
}

; CHECK-LABEL: @func test_sfabss32
; CHECK: SFABSS32
define <2 x float> @test_sfabss32(<2 x float> %a) {
  %res = call <2 x float> @llvm.fabs.v2f32(<2 x float> %a)
  ret <2 x float> %res
}

; CHECK-LABEL: @func test_sfabsh16
; CHECK: SFABSH16
define i64 @test_sfabsh16(i64 %a) {
  %res = call i64 @llvm.ftm.sfabsh16(i64 %a)
  ret i64 %res
}

;; ==================== FP Constant Materialization ====================

; --- double 1.5 → SMOVI with IEEE754 bit pattern ---
define double @test_fp_const() {
; CHECK-LABEL: @func test_fp_const
; CHECK: SMOVI
  ret double 1.5
}

; --- double 0.0 → SMOVI 0 ---
define double @test_fp_zero() {
; CHECK-LABEL: @func test_fp_zero
; CHECK: SMOVI 0,
  ret double 0.0
}

; --- double -1.0 → SMOVI with negative FP bit pattern ---
define double @test_fp_neg() {
; CHECK-LABEL: @func test_fp_neg
; CHECK: SMOVI
  ret double -1.0
}

;; ==================== v2f32 Arithmetic ====================

; --- v2f32 addition: fadd → SFADDS32 ---
define <2 x float> @test_fadd_v2f32(<2 x float> %a, <2 x float> %b) {
; CHECK-LABEL: @func test_fadd_v2f32
; CHECK: SFADDS32
  %result = fadd <2 x float> %a, %b
  ret <2 x float> %result
}

; --- v2f32 subtraction: fsub → SFSUBS32 ---
define <2 x float> @test_fsub_v2f32(<2 x float> %a, <2 x float> %b) {
; CHECK-LABEL: @func test_fsub_v2f32
; CHECK: SFSUBS32
  %result = fsub <2 x float> %a, %b
  ret <2 x float> %result
}

; --- v2f32 multiplication: fmul → SFMULS32 ---
define <2 x float> @test_fmul_v2f32(<2 x float> %a, <2 x float> %b) {
; CHECK-LABEL: @func test_fmul_v2f32
; CHECK: SFMULS32
  %result = fmul <2 x float> %a, %b
  ret <2 x float> %result
}

; --- v2f32 llvm.fma intrinsic → SFMULAS32 ---
define <2 x float> @test_fma_v2f32(<2 x float> %a, <2 x float> %b, <2 x float> %c) {
; CHECK-LABEL: @func test_fma_v2f32
; CHECK: SFMULAS32
  %result = call <2 x float> @llvm.fma.v2f32(<2 x float> %a, <2 x float> %b, <2 x float> %c)
  ret <2 x float> %result
}

; --- v2f32 DAGCombine: (fadd (fmul a, b), c) → SFMULAS32 ---
define <2 x float> @test_fmadd_v2f32(<2 x float> %a, <2 x float> %b, <2 x float> %c) {
; CHECK-LABEL: @func test_fmadd_v2f32
; CHECK: SFMULAS32
; CHECK-NOT: SFMULS32
; CHECK-NOT: SFADDS32
  %mul = fmul <2 x float> %a, %b
  %result = fadd <2 x float> %mul, %c
  ret <2 x float> %result
}

; --- v2f32 DAGCombine commutative: (fadd c, (fmul a, b)) → SFMULAS32 ---
define <2 x float> @test_fmadd_commute_v2f32(<2 x float> %a, <2 x float> %b, <2 x float> %c) {
; CHECK-LABEL: @func test_fmadd_commute_v2f32
; CHECK: SFMULAS32
; CHECK-NOT: SFMULS32
; CHECK-NOT: SFADDS32
  %mul = fmul <2 x float> %a, %b
  %result = fadd <2 x float> %c, %mul
  ret <2 x float> %result
}

;; ==================== v2f32 Special Ops (SFDOT32/SFCMUL32/SFMULBS32) ====================

;; --- SFDOT32: v2f32 dot product ---

define <2 x float> @test_sfdot32(<2 x float> %a, <2 x float> %b) {
; CHECK-LABEL: @func test_sfdot32
; CHECK: SFDOT32
  %r = call <2 x float> @llvm.ftm.sfdot32(<2 x float> %a, <2 x float> %b)
  ret <2 x float> %r
}

;; --- SFCMUL32: v2f32 complex multiply ---

define <2 x float> @test_sfcmul32(<2 x float> %a, <2 x float> %b) {
; CHECK-LABEL: @func test_sfcmul32
; CHECK: SFCMUL32
  %r = call <2 x float> @llvm.ftm.sfcmul32(<2 x float> %a, <2 x float> %b)
  ret <2 x float> %r
}

;; --- SFMULBS32: v2f32 multiply-subtract (src3 - src1*src2) ---

define <2 x float> @test_sfmulbs32(<2 x float> %a, <2 x float> %b, <2 x float> %c) {
; CHECK-LABEL: @func test_sfmulbs32
; CHECK: SFMULBS32
  %r = call <2 x float> @llvm.ftm.sfmulbs32(<2 x float> %a, <2 x float> %b, <2 x float> %c)
  ret <2 x float> %r
}

;; ==================== h16 Arithmetic ====================

; CHECK-LABEL: @func test_sfaddh16
; CHECK: SFADDH16
define <4 x half> @test_sfaddh16(<4 x half> %a, <4 x half> %b) {
  %res = fadd <4 x half> %a, %b
  ret <4 x half> %res
}

; CHECK-LABEL: @func test_sfsubh16
; CHECK: SFSUBH16
define <4 x half> @test_sfsubh16(<4 x half> %a, <4 x half> %b) {
  %res = fsub <4 x half> %a, %b
  ret <4 x half> %res
}

; CHECK-LABEL: @func test_sfmulh16
; CHECK: SFMULH16
define <4 x half> @test_sfmulh16(<4 x half> %a, <4 x half> %b) {
  %res = fmul <4 x half> %a, %b
  ret <4 x half> %res
}

; CHECK-LABEL: @func test_sfmax16
; CHECK: SFMAX16
define <4 x half> @test_sfmax16(<4 x half> %a, <4 x half> %b) {
  %res = call <4 x half> @llvm.maxnum.v4f16(<4 x half> %a, <4 x half> %b)
  ret <4 x half> %res
}

; CHECK-LABEL: @func test_sfabsh16_native
; CHECK: SFABSH16
define <4 x half> @test_sfabsh16_native(<4 x half> %a) {
  %res = call <4 x half> @llvm.fabs.v4f16(<4 x half> %a)
  ret <4 x half> %res
}

; CHECK-LABEL: @func test_sfmulah16
; CHECK: SFMULAH16
define <4 x half> @test_sfmulah16(<4 x half> %a, <4 x half> %b, <4 x half> %c) {
  %res = call <4 x half> @llvm.fma.v4f16(<4 x half> %a, <4 x half> %b, <4 x half> %c)
  ret <4 x half> %res
}

; CHECK-LABEL: @func test_sfmulah16_combine
; CHECK: SFMULAH16
define <4 x half> @test_sfmulah16_combine(<4 x half> %a, <4 x half> %b, <4 x half> %c) {
  %mul = fmul <4 x half> %a, %b
  %res = fadd <4 x half> %mul, %c
  ret <4 x half> %res
}

; CHECK-LABEL: @func test_sfmulbh16_combine
; CHECK: SFMULBH16
define <4 x half> @test_sfmulbh16_combine(<4 x half> %a, <4 x half> %b, <4 x half> %c) {
  %mul = fmul <4 x half> %a, %b
  %res = fsub <4 x half> %mul, %c
  ret <4 x half> %res
}
