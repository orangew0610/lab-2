; NOTE: Scalar floating-point conversion instruction selection tests
; RUN: llc -march=matrix -o - %s | FileCheck %s

;; ===================================================================
;; Scalar floating-point conversion instruction selection tests
;;
;; Instructions tested:
;;   SFDTRU/SFINTD/SFINTDU - f64↔i64 conversion
;;   SFDPSP32/SFSPDP32T/SFSPHDP32T - precision pack/unpack
;;   SFHINT16/SFHTRU16/SFINTH16/SFINTHU16 - h16 int conversion
;;   SFHPSP16H/SFHPSP16L/SFSPHP16 - h16↔f32 conversion
;;   SFP16toBF16/SBF16toFP16 - h16↔bf16 conversion
;;   SFDINT/SFSINT32 - hardware rounding conversion
;; ===================================================================

target triple = "matrix-unknown-unknown"

declare <2 x float> @llvm.ftm.sfdpsp32(double, double)
declare double @llvm.ftm.sfspdp32t(<2 x float>)
declare double @llvm.ftm.sfsphdp32t(<2 x float>)
declare <4 x i16> @llvm.ftm.sfhint16(<4 x half>)
declare <4 x i16> @llvm.ftm.sfhtru16(<4 x half>)
declare <4 x half> @llvm.ftm.sfinth16(<4 x i16>)
declare <4 x half> @llvm.ftm.sfinthu16(<4 x i16>)
declare <2 x float> @llvm.ftm.sfhpsp16h(<4 x half>)
declare <2 x float> @llvm.ftm.sfhpsp16l(<4 x half>)
declare <4 x half> @llvm.ftm.sfsphp16(<2 x float>, <2 x float>)
declare <4 x i16> @llvm.ftm.sfp16tobf16(<4 x half>)
declare <4 x half> @llvm.ftm.sbf16tofp16(<4 x i16>)
declare i64 @llvm.ftm.sfdint(double)
declare <2 x i32> @llvm.ftm.sfsint32(<2 x float>)

;; ==================== f64↔i64 Conversion ====================

; --- f64 → i64 (signed): fptosi → SFDTRU ---
define i64 @test_fptosi(double %a) {
; CHECK-LABEL: @func test_fptosi
; CHECK: SFDTRU
  %result = fptosi double %a to i64
  ret i64 %result
}

; --- i64 → f64 (signed): sitofp → SFINTD ---
define double @test_sitofp(i64 %a) {
; CHECK-LABEL: @func test_sitofp
; CHECK: SFINTD
  %result = sitofp i64 %a to double
  ret double %result
}

; --- i64 → f64 (unsigned): uitofp → SFINTDU ---
define double @test_uitofp(i64 %a) {
; CHECK-LABEL: @func test_uitofp
; CHECK: SFINTDU
  %result = uitofp i64 %a to double
  ret double %result
}

;; ==================== Precision Pack/Unpack ====================

;; --- SFDPSP32: pack two f64 → v2f32 ---

define <2 x float> @test_sfdpsp32(double %a, double %b) {
; CHECK-LABEL: @func test_sfdpsp32
; CHECK: SFDPSP32
  %r = call <2 x float> @llvm.ftm.sfdpsp32(double %a, double %b)
  ret <2 x float> %r
}

;; --- SFSPDP32T: v2f32 low element → f64 ---

define double @test_sfspdp32t(<2 x float> %a) {
; CHECK-LABEL: @func test_sfspdp32t
; CHECK: SFSPDP32T
  %r = call double @llvm.ftm.sfspdp32t(<2 x float> %a)
  ret double %r
}

;; --- SFSPHDP32T: v2f32 high element → f64 ---

define double @test_sfsphdp32t(<2 x float> %a) {
; CHECK-LABEL: @func test_sfsphdp32t
; CHECK: SFSPHDP32T
  %r = call double @llvm.ftm.sfsphdp32t(<2 x float> %a)
  ret double %r
}

;; ==================== h16 Conversions ====================

; CHECK-LABEL: @func test_sfhint16
; CHECK: SFHINT16
define <4 x i16> @test_sfhint16(<4 x half> %a) {
  %res = call <4 x i16> @llvm.ftm.sfhint16(<4 x half> %a)
  ret <4 x i16> %res
}

; CHECK-LABEL: @func test_sfhtru16
; CHECK: SFHTRU16
define <4 x i16> @test_sfhtru16(<4 x half> %a) {
  %res = call <4 x i16> @llvm.ftm.sfhtru16(<4 x half> %a)
  ret <4 x i16> %res
}

; CHECK-LABEL: @func test_sfinth16
; CHECK: SFINTH16
define <4 x half> @test_sfinth16(<4 x i16> %a) {
  %res = call <4 x half> @llvm.ftm.sfinth16(<4 x i16> %a)
  ret <4 x half> %res
}

; CHECK-LABEL: @func test_sfinthu16
; CHECK: SFINTHU16
define <4 x half> @test_sfinthu16(<4 x i16> %a) {
  %res = call <4 x half> @llvm.ftm.sfinthu16(<4 x i16> %a)
  ret <4 x half> %res
}

; CHECK-LABEL: @func test_sfhpsp16h
; CHECK: SFHPSP16H
define <2 x float> @test_sfhpsp16h(<4 x half> %a) {
  %res = call <2 x float> @llvm.ftm.sfhpsp16h(<4 x half> %a)
  ret <2 x float> %res
}

; CHECK-LABEL: @func test_sfhpsp16l
; CHECK: SFHPSP16L
define <2 x float> @test_sfhpsp16l(<4 x half> %a) {
  %res = call <2 x float> @llvm.ftm.sfhpsp16l(<4 x half> %a)
  ret <2 x float> %res
}

; CHECK-LABEL: @func test_sfsphp16
; CHECK: SFSPHP16
define <4 x half> @test_sfsphp16(<2 x float> %a, <2 x float> %b) {
  %res = call <4 x half> @llvm.ftm.sfsphp16(<2 x float> %a, <2 x float> %b)
  ret <4 x half> %res
}

; CHECK-LABEL: @func test_sfp16tobf16
; CHECK: SFP16toBF16
define <4 x i16> @test_sfp16tobf16(<4 x half> %a) {
  %res = call <4 x i16> @llvm.ftm.sfp16tobf16(<4 x half> %a)
  ret <4 x i16> %res
}

; CHECK-LABEL: @func test_sbf16tofp16
; CHECK: SBF16toFP16
define <4 x half> @test_sbf16tofp16(<4 x i16> %a) {
  %res = call <4 x half> @llvm.ftm.sbf16tofp16(<4 x i16> %a)
  ret <4 x half> %res
}

;; ==================== Hardware Rounding Conversion (SFDINT/SFSINT32) ====================

;; --- SFDINT: f64 → i64 with hardware rounding mode ---

; CHECK-LABEL: @func test_sfdint
; CHECK: SFDINT
define i64 @test_sfdint(double %a) {
  %r = call i64 @llvm.ftm.sfdint(double %a)
  ret i64 %r
}

;; --- SFSINT32: v2f32 → v2i32 with hardware rounding mode ---

; CHECK-LABEL: @func test_sfsint32
; CHECK: SFSINT32
define <2 x i32> @test_sfsint32(<2 x float> %a) {
  %r = call <2 x i32> @llvm.ftm.sfsint32(<2 x float> %a)
  ret <2 x i32> %r
}
