; NOTE: Scalar integer ALU instruction selection tests
; RUN: llc -march=matrix -o - %s | FileCheck %s

;; ===================================================================
;; Scalar integer ALU instruction selection tests
;;
;; Instructions tested:
;;   SAND/SOR/SXOR/SNOT - bitwise logic (i64, v2i32)
;;   SABS/SNEG/SLZD     - unary (i64, v2i32, i32)
;;   SMAX/SMIN/SMAXU/SMINU - min/max (i64, v2i32, i32)
;;   SSHFLL/SSHFLR/SSHFAR  - shifts (i64, v2i32, i32)
;;   SADDUSAT/SSUBUSAT     - saturating arith (i64, v2i32, i32)
;;   SSAT/SSAT32           - flag-dependent saturation
;; ===================================================================

target triple = "matrix-unknown-unknown"

declare i64 @llvm.abs.i64(i64, i1)
declare <2 x i32> @llvm.abs.v2i32(<2 x i32>, i1)
declare i32 @llvm.abs.i32(i32, i1)

declare i64 @llvm.ctlz.i64(i64, i1)
declare <2 x i32> @llvm.ctlz.v2i32(<2 x i32>, i1)
declare i32 @llvm.ctlz.i32(i32, i1)

declare i64 @llvm.smax.i64(i64, i64)
declare i64 @llvm.smin.i64(i64, i64)
declare i64 @llvm.umax.i64(i64, i64)
declare i64 @llvm.umin.i64(i64, i64)

declare <2 x i32> @llvm.smax.v2i32(<2 x i32>, <2 x i32>)
declare <2 x i32> @llvm.smin.v2i32(<2 x i32>, <2 x i32>)
declare <2 x i32> @llvm.umax.v2i32(<2 x i32>, <2 x i32>)
declare <2 x i32> @llvm.umin.v2i32(<2 x i32>, <2 x i32>)

declare i32 @llvm.smax.i32(i32, i32)
declare i32 @llvm.smin.i32(i32, i32)
declare i32 @llvm.umax.i32(i32, i32)
declare i32 @llvm.umin.i32(i32, i32)

declare i64 @llvm.uadd.sat.i64(i64, i64)
declare i64 @llvm.usub.sat.i64(i64, i64)
declare <2 x i32> @llvm.uadd.sat.v2i32(<2 x i32>, <2 x i32>)
declare <2 x i32> @llvm.usub.sat.v2i32(<2 x i32>, <2 x i32>)
declare i32 @llvm.uadd.sat.i32(i32, i32)
declare i32 @llvm.usub.sat.i32(i32, i32)

declare i64 @llvm.ftm.ssat(i64)
declare i64 @llvm.ftm.ssat32(i64)

;; ==================== Bitwise Logic (SAND/SOR/SXOR/SNOT) ====================

;; --- i64 AND ---

define i64 @test_and_i64(i64 %a, i64 %b) {
; CHECK-LABEL: @func test_and_i64
; CHECK: SAND
entry:
  %r = and i64 %a, %b
  ret i64 %r
}

define i64 @test_and_i64_imm(i64 %a) {
; CHECK-LABEL: @func test_and_i64_imm
; CHECK: SAND 7
entry:
  %r = and i64 %a, 7
  ret i64 %r
}

;; --- i64 OR ---

define i64 @test_or_i64(i64 %a, i64 %b) {
; CHECK-LABEL: @func test_or_i64
; CHECK: SOR
entry:
  %r = or i64 %a, %b
  ret i64 %r
}

define i64 @test_or_i64_imm(i64 %a) {
; CHECK-LABEL: @func test_or_i64_imm
; CHECK: SOR 3
entry:
  %r = or i64 %a, 3
  ret i64 %r
}

;; --- i64 XOR ---

define i64 @test_xor_i64(i64 %a, i64 %b) {
; CHECK-LABEL: @func test_xor_i64
; CHECK: SXOR
entry:
  %r = xor i64 %a, %b
  ret i64 %r
}

define i64 @test_xor_i64_imm(i64 %a) {
; CHECK-LABEL: @func test_xor_i64_imm
; CHECK: SXOR 15
entry:
  %r = xor i64 %a, 15
  ret i64 %r
}

;; --- i64 NOT ---

define i64 @test_not_i64(i64 %a) {
; CHECK-LABEL: @func test_not_i64
; CHECK: SNOT
entry:
  %r = xor i64 %a, -1
  ret i64 %r
}

;; --- v2i32 AND ---

define <2 x i32> @test_and_v2i32(<2 x i32> %a, <2 x i32> %b) {
; CHECK-LABEL: @func test_and_v2i32
; CHECK: SAND
entry:
  %r = and <2 x i32> %a, %b
  ret <2 x i32> %r
}

;; --- v2i32 OR ---

define <2 x i32> @test_or_v2i32(<2 x i32> %a, <2 x i32> %b) {
; CHECK-LABEL: @func test_or_v2i32
; CHECK: SOR
entry:
  %r = or <2 x i32> %a, %b
  ret <2 x i32> %r
}

;; --- v2i32 XOR ---

define <2 x i32> @test_xor_v2i32(<2 x i32> %a, <2 x i32> %b) {
; CHECK-LABEL: @func test_xor_v2i32
; CHECK: SXOR
entry:
  %r = xor <2 x i32> %a, %b
  ret <2 x i32> %r
}

;; --- v2i32 NOT ---

define <2 x i32> @test_not_v2i32(<2 x i32> %a) {
; CHECK-LABEL: @func test_not_v2i32
; CHECK: SNOT
entry:
  %r = xor <2 x i32> %a, <i32 -1, i32 -1>
  ret <2 x i32> %r
}

;; ==================== Unary (SABS/SNEG/SLZD) ====================

;; --- i64 abs ---

define i64 @test_abs_i64(i64 %a) {
; CHECK-LABEL: @func test_abs_i64
; CHECK: SABS
entry:
  %r = call i64 @llvm.abs.i64(i64 %a, i1 false)
  ret i64 %r
}

;; --- v2i32 abs ---

define <2 x i32> @test_abs_v2i32(<2 x i32> %a) {
; CHECK-LABEL: @func test_abs_v2i32
; CHECK: SABS32
entry:
  %r = call <2 x i32> @llvm.abs.v2i32(<2 x i32> %a, i1 false)
  ret <2 x i32> %r
}

;; --- i32 abs ---

define i32 @test_abs_i32(i32 %a) {
; CHECK-LABEL: @func test_abs_i32
; CHECK: SABS32
entry:
  %r = call i32 @llvm.abs.i32(i32 %a, i1 false)
  ret i32 %r
}

;; --- i64 neg ---

define i64 @test_neg_i64(i64 %a) {
; CHECK-LABEL: @func test_neg_i64
; CHECK: SNEG
entry:
  %r = sub i64 0, %a
  ret i64 %r
}

;; --- i32 neg ---

define i32 @test_neg_i32(i32 %a) {
; CHECK-LABEL: @func test_neg_i32
; CHECK: SNEG32
entry:
  %r = sub i32 0, %a
  ret i32 %r
}

;; --- i64 ctlz ---

define i64 @test_ctlz_i64(i64 %a) {
; CHECK-LABEL: @func test_ctlz_i64
; CHECK: SLZD
entry:
  %r = call i64 @llvm.ctlz.i64(i64 %a, i1 true)
  ret i64 %r
}

;; --- v2i32 ctlz ---

define <2 x i32> @test_ctlz_v2i32(<2 x i32> %a) {
; CHECK-LABEL: @func test_ctlz_v2i32
; CHECK: SLZD32
entry:
  %r = call <2 x i32> @llvm.ctlz.v2i32(<2 x i32> %a, i1 true)
  ret <2 x i32> %r
}

;; --- i32 ctlz (zero_undef=true, avoids zero-check branch) ---

define i32 @test_ctlz_i32(i32 %a) {
; CHECK-LABEL: @func test_ctlz_i32
; CHECK: SLZD32
entry:
  %r = call i32 @llvm.ctlz.i32(i32 %a, i1 true)
  ret i32 %r
}

;; --- i64 ctlz_zero_undef ---

define i64 @test_ctlz_zero_undef_i64(i64 %a) {
; CHECK-LABEL: @func test_ctlz_zero_undef_i64
; CHECK: SLZD
entry:
  %r = call i64 @llvm.ctlz.i64(i64 %a, i1 true)
  ret i64 %r
}

;; ==================== Min/Max (SMAX/SMIN/SMAXU/SMINU) ====================

;; --- i64 smax ---

define i64 @test_smax_i64(i64 %a, i64 %b) {
; CHECK-LABEL: @func test_smax_i64
; CHECK: SMAX
entry:
  %r = call i64 @llvm.smax.i64(i64 %a, i64 %b)
  ret i64 %r
}

;; --- i64 smin ---

define i64 @test_smin_i64(i64 %a, i64 %b) {
; CHECK-LABEL: @func test_smin_i64
; CHECK: SMIN
entry:
  %r = call i64 @llvm.smin.i64(i64 %a, i64 %b)
  ret i64 %r
}

;; --- i64 umax ---

define i64 @test_umax_i64(i64 %a, i64 %b) {
; CHECK-LABEL: @func test_umax_i64
; CHECK: SMAXU
entry:
  %r = call i64 @llvm.umax.i64(i64 %a, i64 %b)
  ret i64 %r
}

;; --- i64 umin ---

define i64 @test_umin_i64(i64 %a, i64 %b) {
; CHECK-LABEL: @func test_umin_i64
; CHECK: SMINU
entry:
  %r = call i64 @llvm.umin.i64(i64 %a, i64 %b)
  ret i64 %r
}

;; --- v2i32 smax ---

define <2 x i32> @test_smax_v2i32(<2 x i32> %a, <2 x i32> %b) {
; CHECK-LABEL: @func test_smax_v2i32
; CHECK: SMAX32
entry:
  %r = call <2 x i32> @llvm.smax.v2i32(<2 x i32> %a, <2 x i32> %b)
  ret <2 x i32> %r
}

;; --- v2i32 smin ---

define <2 x i32> @test_smin_v2i32(<2 x i32> %a, <2 x i32> %b) {
; CHECK-LABEL: @func test_smin_v2i32
; CHECK: SMIN32
entry:
  %r = call <2 x i32> @llvm.smin.v2i32(<2 x i32> %a, <2 x i32> %b)
  ret <2 x i32> %r
}

;; --- v2i32 umax ---

define <2 x i32> @test_umax_v2i32(<2 x i32> %a, <2 x i32> %b) {
; CHECK-LABEL: @func test_umax_v2i32
; CHECK: SMAXU32
entry:
  %r = call <2 x i32> @llvm.umax.v2i32(<2 x i32> %a, <2 x i32> %b)
  ret <2 x i32> %r
}

;; --- v2i32 umin ---

define <2 x i32> @test_umin_v2i32(<2 x i32> %a, <2 x i32> %b) {
; CHECK-LABEL: @func test_umin_v2i32
; CHECK: SMINU32
entry:
  %r = call <2 x i32> @llvm.umin.v2i32(<2 x i32> %a, <2 x i32> %b)
  ret <2 x i32> %r
}

;; --- i32 smax ---

define i32 @test_smax_i32(i32 %a, i32 %b) {
; CHECK-LABEL: @func test_smax_i32
; CHECK: SMAX32
entry:
  %r = call i32 @llvm.smax.i32(i32 %a, i32 %b)
  ret i32 %r
}

;; --- i32 smin ---

define i32 @test_smin_i32(i32 %a, i32 %b) {
; CHECK-LABEL: @func test_smin_i32
; CHECK: SMIN32
entry:
  %r = call i32 @llvm.smin.i32(i32 %a, i32 %b)
  ret i32 %r
}

;; --- i32 umax ---

define i32 @test_umax_i32(i32 %a, i32 %b) {
; CHECK-LABEL: @func test_umax_i32
; CHECK: SMAXU32
entry:
  %r = call i32 @llvm.umax.i32(i32 %a, i32 %b)
  ret i32 %r
}

;; --- i32 umin ---

define i32 @test_umin_i32(i32 %a, i32 %b) {
; CHECK-LABEL: @func test_umin_i32
; CHECK: SMINU32
entry:
  %r = call i32 @llvm.umin.i32(i32 %a, i32 %b)
  ret i32 %r
}

;; ==================== Shifts (SSHFLL/SSHFLR/SSHFAR) ====================

; === 64-bit logical left shift (SSHFLL) ===

define i64 @test_shl_rr(i64 %a, i64 %b) {
; CHECK-LABEL: @func test_shl_rr
; CHECK: SSHFLL
  %result = shl i64 %a, %b
  ret i64 %result
}

define i64 @test_shl_ri(i64 %a) {
; CHECK-LABEL: @func test_shl_ri
; CHECK: SSHFLL 3,
  %result = shl i64 %a, 3
  ret i64 %result
}

; === 64-bit logical right shift (SSHFLR) ===

define i64 @test_srl_rr(i64 %a, i64 %b) {
; CHECK-LABEL: @func test_srl_rr
; CHECK: SSHFLR
  %result = lshr i64 %a, %b
  ret i64 %result
}

define i64 @test_srl_ri(i64 %a) {
; CHECK-LABEL: @func test_srl_ri
; CHECK: SSHFLR 4,
  %result = lshr i64 %a, 4
  ret i64 %result
}

; === 64-bit arithmetic right shift (SSHFAR) ===

define i64 @test_sra_rr(i64 %a, i64 %b) {
; CHECK-LABEL: @func test_sra_rr
; CHECK: SSHFAR
  %result = ashr i64 %a, %b
  ret i64 %result
}

define i64 @test_sra_ri(i64 %a) {
; CHECK-LABEL: @func test_sra_ri
; CHECK: SSHFAR 5,
  %result = ashr i64 %a, 5
  ret i64 %result
}

; === mul optimized to shl scenario (key use case) ===

define i64 @test_mul_pow2_to_shl(i64 %a) {
; CHECK-LABEL: @func test_mul_pow2_to_shl
; CHECK: SSHFLL 3,
  %result = mul i64 %a, 8
  ret i64 %result
}

define i64 @test_mul_pow2_16(i64 %a) {
; CHECK-LABEL: @func test_mul_pow2_16
; CHECK: SSHFLL 4,
  %result = mul i64 %a, 16
  ret i64 %result
}

; === v2i32 32-bit parallel shifts ===

define <2 x i32> @test_shl_v2i32(<2 x i32> %a, <2 x i32> %b) {
; CHECK-LABEL: @func test_shl_v2i32
; CHECK: SSHFLL32
  %result = shl <2 x i32> %a, %b
  ret <2 x i32> %result
}

define <2 x i32> @test_lshr_v2i32(<2 x i32> %a, <2 x i32> %b) {
; CHECK-LABEL: @func test_lshr_v2i32
; CHECK: SSHFLR32
  %result = lshr <2 x i32> %a, %b
  ret <2 x i32> %result
}

define <2 x i32> @test_ashr_v2i32(<2 x i32> %a, <2 x i32> %b) {
; CHECK-LABEL: @func test_ashr_v2i32
; CHECK: SSHFAR32
  %result = ashr <2 x i32> %a, %b
  ret <2 x i32> %result
}

; === i32 scalar shifts with immediate (Custom lowered to SHL32_SCALAR etc.) ===
; Note: i32 register-register shifts have a pre-existing ISel limitation
; (zero_extend of i32 shift amount to i64 cannot be selected).

define i32 @test_shl_i32_imm(i32 %a) {
; CHECK-LABEL: @func test_shl_i32_imm
; CHECK: SSHFLL32 3,
  %result = shl i32 %a, 3
  ret i32 %result
}

define i32 @test_lshr_i32_imm(i32 %a) {
; CHECK-LABEL: @func test_lshr_i32_imm
; CHECK: SSHFLR32 4,
  %result = lshr i32 %a, 4
  ret i32 %result
}

define i32 @test_ashr_i32_imm(i32 %a) {
; CHECK-LABEL: @func test_ashr_i32_imm
; CHECK: SSHFAR32 5,
  %result = ashr i32 %a, 5
  ret i32 %result
}

;; ==================== Saturating Arithmetic (SADDUSAT/SSUBUSAT) ====================

;; --- i64 uaddsat ---

define i64 @test_uaddsat_i64(i64 %a, i64 %b) {
; CHECK-LABEL: @func test_uaddsat_i64
; CHECK: SADDUSAT
entry:
  %r = call i64 @llvm.uadd.sat.i64(i64 %a, i64 %b)
  ret i64 %r
}

;; --- i64 usubsat ---

define i64 @test_usubsat_i64(i64 %a, i64 %b) {
; CHECK-LABEL: @func test_usubsat_i64
; CHECK: SSUBUSAT
entry:
  %r = call i64 @llvm.usub.sat.i64(i64 %a, i64 %b)
  ret i64 %r
}

;; --- v2i32 uaddsat ---

define <2 x i32> @test_uaddsat_v2i32(<2 x i32> %a, <2 x i32> %b) {
; CHECK-LABEL: @func test_uaddsat_v2i32
; CHECK: SADDU32SAT
entry:
  %r = call <2 x i32> @llvm.uadd.sat.v2i32(<2 x i32> %a, <2 x i32> %b)
  ret <2 x i32> %r
}

;; --- v2i32 usubsat ---

define <2 x i32> @test_usubsat_v2i32(<2 x i32> %a, <2 x i32> %b) {
; CHECK-LABEL: @func test_usubsat_v2i32
; CHECK: SSUBU32SAT
entry:
  %r = call <2 x i32> @llvm.usub.sat.v2i32(<2 x i32> %a, <2 x i32> %b)
  ret <2 x i32> %r
}

;; --- i32 uaddsat ---

define i32 @test_uaddsat_i32(i32 %a, i32 %b) {
; CHECK-LABEL: @func test_uaddsat_i32
; CHECK: SADDU32SAT
entry:
  %r = call i32 @llvm.uadd.sat.i32(i32 %a, i32 %b)
  ret i32 %r
}

;; --- i32 usubsat ---

define i32 @test_usubsat_i32(i32 %a, i32 %b) {
; CHECK-LABEL: @func test_usubsat_i32
; CHECK: SSUBU32SAT
entry:
  %r = call i32 @llvm.usub.sat.i32(i32 %a, i32 %b)
  ret i32 %r
}

;; ==================== Flag-Dependent Saturation (SSAT/SSAT32) ====================

; CHECK-LABEL: @func test_ssat
; CHECK: SSAT
define i64 @test_ssat(i64 %x) {
  %res = call i64 @llvm.ftm.ssat(i64 %x)
  ret i64 %res
}

; CHECK-LABEL: @func test_ssat32
; CHECK: SSAT32
define i64 @test_ssat32(i64 %x) {
  %res = call i64 @llvm.ftm.ssat32(i64 %x)
  ret i64 %res
}
