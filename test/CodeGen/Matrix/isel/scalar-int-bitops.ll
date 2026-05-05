; NOTE: Scalar integer bit operations instruction selection tests
; RUN: llc -march=matrix -o - %s | FileCheck %s

;; ===================================================================
;; Scalar integer bit operations instruction selection tests
;;
;; Instructions tested:
;;   SBSET/SBCLR/SBEX   - bit set/clear/toggle (i64 DAG patterns)
;;   SBTST/SBEXT/SBEXTU - bit test/extract (i64 intrinsics)
;;   SBSET32/SBCLR32/SBTST32/SBEXT32/SBEXT32U - 32-bit variants
;; ===================================================================

target triple = "matrix-unknown-unknown"

declare i64 @llvm.ftm.sbtst(i64, i64)
declare i64 @llvm.ftm.sbext(i64, i64)
declare i64 @llvm.ftm.sbextu(i64, i64)
declare <2 x i32> @llvm.ftm.sbset32(<2 x i32>, <2 x i32>)
declare <2 x i32> @llvm.ftm.sbclr32(<2 x i32>, <2 x i32>)
declare <2 x i32> @llvm.ftm.sbtst32(<2 x i32>, <2 x i32>)
declare <2 x i32> @llvm.ftm.sbext32(<2 x i32>, <2 x i32>)
declare <2 x i32> @llvm.ftm.sbext32u(<2 x i32>, <2 x i32>)

;; ==================== Bit Set/Clear/Toggle (SBSET/SBCLR/SBEX) ====================

;; --- SBSET: dst = src2 | (1 << src1) ---

define i64 @test_sbset(i64 %val, i64 %pos) {
; CHECK-LABEL: @func test_sbset
; CHECK: SBSET
entry:
  %mask = shl i64 1, %pos
  %r = or i64 %val, %mask
  ret i64 %r
}

; Commuted operand order: (shl 1, pos) | val
define i64 @test_sbset_commuted(i64 %val, i64 %pos) {
; CHECK-LABEL: @func test_sbset_commuted
; CHECK: SBSET
entry:
  %mask = shl i64 1, %pos
  %r = or i64 %mask, %val
  ret i64 %r
}

;; --- SBCLR: dst = src2 & ~(1 << src1) ---

define i64 @test_sbclr(i64 %val, i64 %pos) {
; CHECK-LABEL: @func test_sbclr
; CHECK: SBCLR
entry:
  %mask = shl i64 1, %pos
  %nmask = xor i64 %mask, -1
  %r = and i64 %val, %nmask
  ret i64 %r
}

; Commuted operand order: ~(shl 1, pos) & val
define i64 @test_sbclr_commuted(i64 %val, i64 %pos) {
; CHECK-LABEL: @func test_sbclr_commuted
; CHECK: SBCLR
entry:
  %mask = shl i64 1, %pos
  %nmask = xor i64 %mask, -1
  %r = and i64 %nmask, %val
  ret i64 %r
}

;; --- SBEX: dst = src2 ^ (1 << src1) ---

define i64 @test_sbex(i64 %val, i64 %pos) {
; CHECK-LABEL: @func test_sbex
; CHECK: SBEX
entry:
  %mask = shl i64 1, %pos
  %r = xor i64 %val, %mask
  ret i64 %r
}

; Commuted operand order: (shl 1, pos) ^ val
define i64 @test_sbex_commuted(i64 %val, i64 %pos) {
; CHECK-LABEL: @func test_sbex_commuted
; CHECK: SBEX
entry:
  %mask = shl i64 1, %pos
  %r = xor i64 %mask, %val
  ret i64 %r
}

;; ==================== Bit Test/Extract (SBTST/SBEXT/SBEXTU + 32-bit) ====================

;; --- 64-bit bit manipulation ---

define i64 @test_sbtst(i64 %a, i64 %b) {
; CHECK-LABEL: @func test_sbtst
; CHECK: SBTST
  %r = call i64 @llvm.ftm.sbtst(i64 %a, i64 %b)
  ret i64 %r
}

define i64 @test_sbext(i64 %a, i64 %b) {
; CHECK-LABEL: @func test_sbext
; CHECK: SBEXT
; CHECK-NOT: SBEXTU
  %r = call i64 @llvm.ftm.sbext(i64 %a, i64 %b)
  ret i64 %r
}

define i64 @test_sbextu(i64 %a, i64 %b) {
; CHECK-LABEL: @func test_sbextu
; CHECK: SBEXTU
  %r = call i64 @llvm.ftm.sbextu(i64 %a, i64 %b)
  ret i64 %r
}

;; --- 32-bit SIMD bit manipulation ---

define <2 x i32> @test_sbset32(<2 x i32> %a, <2 x i32> %b) {
; CHECK-LABEL: @func test_sbset32
; CHECK: SBSET32
  %r = call <2 x i32> @llvm.ftm.sbset32(<2 x i32> %a, <2 x i32> %b)
  ret <2 x i32> %r
}

define <2 x i32> @test_sbclr32(<2 x i32> %a, <2 x i32> %b) {
; CHECK-LABEL: @func test_sbclr32
; CHECK: SBCLR32
  %r = call <2 x i32> @llvm.ftm.sbclr32(<2 x i32> %a, <2 x i32> %b)
  ret <2 x i32> %r
}

define <2 x i32> @test_sbtst32(<2 x i32> %a, <2 x i32> %b) {
; CHECK-LABEL: @func test_sbtst32
; CHECK: SBTST32
  %r = call <2 x i32> @llvm.ftm.sbtst32(<2 x i32> %a, <2 x i32> %b)
  ret <2 x i32> %r
}

define <2 x i32> @test_sbext32(<2 x i32> %a, <2 x i32> %b) {
; CHECK-LABEL: @func test_sbext32
; CHECK: SBEXT32
; CHECK-NOT: SBEXT32U
  %r = call <2 x i32> @llvm.ftm.sbext32(<2 x i32> %a, <2 x i32> %b)
  ret <2 x i32> %r
}

define <2 x i32> @test_sbext32u(<2 x i32> %a, <2 x i32> %b) {
; CHECK-LABEL: @func test_sbext32u
; CHECK: SBEXT32U
  %r = call <2 x i32> @llvm.ftm.sbext32u(<2 x i32> %a, <2 x i32> %b)
  ret <2 x i32> %r
}
