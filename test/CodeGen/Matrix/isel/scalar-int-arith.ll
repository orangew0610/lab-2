; NOTE: Scalar integer arithmetic instruction selection tests
; RUN: llc -march=matrix -o - %s | FileCheck %s

;; ===================================================================
;; Scalar integer arithmetic instruction selection tests
;;
;; Instructions tested:
;;   SADD/SADD32/SADDU32 - 64/32-bit addition
;;   SSUB/SSUB32     - 64/32-bit subtraction
;;   SMULIU/SMULIS   - 64-bit multiply (unsigned/signed imm)
;;   SMULIU32/SMULIS32 - 32-bit multiply
;;   SMULAU32T/SMULAS32T - multiply-add (unsigned/signed)
;;   SMULBU32T/SMULBS32T - multiply-sub (unsigned/signed)
;;   SMULISU/SMULISU32 - mixed-sign multiply
;;   SMULASU32T/SMULAUS32T/SMULBSU32T/SMULBUS32T - mixed-sign MAC
;; ===================================================================

target triple = "matrix-unknown-unknown"

declare i64 @llvm.ftm.smulisu(i64, i64)
declare <2 x i32> @llvm.ftm.smulisu32(<2 x i32>, <2 x i32>)
declare i64 @llvm.ftm.smulasu32t(i64, i64, i64)
declare i64 @llvm.ftm.smulaus32t(i64, i64, i64)
declare i64 @llvm.ftm.smulbsu32t(i64, i64, i64)
declare i64 @llvm.ftm.smulbus32t(i64, i64, i64)
declare i64 @llvm.ftm.smulasu32t.i(i64, i64, i64)
declare i64 @llvm.ftm.smulaus32t.i(i64, i64, i64)
declare i64 @llvm.ftm.smulbsu32t.i(i64, i64, i64)
declare i64 @llvm.ftm.smulbus32t.i(i64, i64, i64)

;; ==================== 64-bit Addition (SADD) ====================

define i64 @test_sadd_rr(i64 %a, i64 %b) {
; CHECK-LABEL: @func test_sadd_rr
; CHECK: SADD
  %result = add i64 %a, %b
  ret i64 %result
}

define i64 @test_sadd_ri_pos(i64 %a) {
; CHECK-LABEL: @func test_sadd_ri_pos
; CHECK: SADD 5,
  %result = add i64 %a, 5
  ret i64 %result
}

define i64 @test_sadd_ri_neg(i64 %a) {
; CHECK-LABEL: @func test_sadd_ri_neg
; CHECK: SADD -32,
  %result = add i64 %a, -32
  ret i64 %result
}

define i64 @test_sadd_ri_max(i64 %a) {
; CHECK-LABEL: @func test_sadd_ri_max
; CHECK: SADD 31,
  %result = add i64 %a, 31
  ret i64 %result
}

define i64 @test_sadd_ri_overflow(i64 %a) {
; CHECK-LABEL: @func test_sadd_ri_overflow
; CHECK-NOT: SADD 32,
; CHECK: SADD
  %result = add i64 %a, 32
  ret i64 %result
}

define i64 @test_sadd_ri_underflow(i64 %a) {
; CHECK-LABEL: @func test_sadd_ri_underflow
; CHECK: SMOVI 0xffffffffffffffdf,
; CHECK-NOT: SADD -33,
; CHECK: SADD
  %result = add i64 %a, -33
  ret i64 %result
}

;; ==================== 32-bit Arithmetic (SADD32/SSUB32/SMULIU32/SMULIS32) ====================

define i32 @test_add32_rr(i32 %a, i32 %b) {
; CHECK-LABEL: @func test_add32_rr
; CHECK: SADD32
  %result = add i32 %a, %b
  ret i32 %result
}

define i32 @test_add32_ri_pos(i32 %a) {
; CHECK-LABEL: @func test_add32_ri_pos
; CHECK: SADD32 5,
  %result = add i32 %a, 5
  ret i32 %result
}

define i32 @test_add32_ri_neg(i32 %a) {
; CHECK-LABEL: @func test_add32_ri_neg
; CHECK: SADD32 -32,
  %result = add i32 %a, -32
  ret i32 %result
}

define i32 @test_add32_ri_uimm6(i32 %a) {
; CHECK-LABEL: @func test_add32_ri_uimm6
; CHECK: SADDU32 50,
  %result = add i32 %a, 50
  ret i32 %result
}

define i32 @test_sub32_rr(i32 %a, i32 %b) {
; CHECK-LABEL: @func test_sub32_rr
; CHECK: SSUB32
  %result = sub i32 %a, %b
  ret i32 %result
}


; Note: sub i32 %a, 5 is canonicalized by DAG combiner to add i32 %a, -5
; -5 fits simm6 [-32,31], so SADD32 -5 is emitted instead of SSUB32 5
define i32 @test_sub32_ri_small(i32 %a) {
; CHECK-LABEL: @func test_sub32_ri_small
; CHECK: SADD32 -5,
  %result = sub i32 %a, 5
  ret i32 %result
}

define i32 @test_mul32_rr(i32 %a, i32 %b) {
; CHECK-LABEL: @func test_mul32_rr
; CHECK: SMULIU32
  %result = mul i32 %a, %b
  ret i32 %result
}

define i32 @test_mul32_ri_pos(i32 %a) {
; CHECK-LABEL: @func test_mul32_ri_pos
; CHECK: SMULIU32 5,
  %result = mul i32 %a, 5
  ret i32 %result
}

define i32 @test_mul32_ri_neg(i32 %a) {
; CHECK-LABEL: @func test_mul32_ri_neg
; CHECK: SMULIS32 -3,
  %result = mul i32 %a, -3
  ret i32 %result
}

;; ==================== 64-bit Multiply (SMULIS/SMULIU) ====================

; --- reg-reg: two register operands → SMULIU (non-negative default path) ---
define i64 @test_mul_rr(i64 %a, i64 %b) {
; CHECK-LABEL: @func test_mul_rr
; CHECK: SMULIU
  %result = mul i64 %a, %b
  ret i64 %result
}

; --- Small positive immediate: imm=5 ∈ [0,63] → SMULIU_ri (non-negative takes unsigned path) ---
define i64 @test_smuliu_ri_5(i64 %a) {
; CHECK-LABEL: @func test_smuliu_ri_5
; CHECK: SMULIU 5,
  %result = mul i64 %a, 5
  ret i64 %result
}

; --- Negative immediate: imm=-5 ∈ [-32,31] → SMULIS_ri (negative takes signed path) ---
define i64 @test_smulis_ri_neg5(i64 %a) {
; CHECK-LABEL: @func test_smulis_ri_neg5
; CHECK: SMULIS -5,
  %result = mul i64 %a, -5
  ret i64 %result
}

; --- simm6 negative boundary: imm=-31 ∈ [-32,31] → SMULIS_ri ---
; (Avoid -32 = -(2^5), which DAG combiner optimizes to sub+shl)
define i64 @test_smulis_ri_neg31(i64 %a) {
; CHECK-LABEL: @func test_smulis_ri_neg31
; CHECK: SMULIS -31,
  %result = mul i64 %a, -31
  ret i64 %result
}

; --- simm6 positive boundary: imm=31 ∈ [-32,31] → SMULIU_ri ---
; (31 non-negative → MUL64U → SMULIU)
define i64 @test_smuliu_ri_31(i64 %a) {
; CHECK-LABEL: @func test_smuliu_ri_31
; CHECK: SMULIU 31,
  %result = mul i64 %a, 31
  ret i64 %result
}

; --- uimm6 mid-range: imm=33 ∈ [0,63] → SMULIU_ri ---
; (33 > 31, only SMULIU can match)
define i64 @test_smuliu_ri_33(i64 %a) {
; CHECK-LABEL: @func test_smuliu_ri_33
; CHECK: SMULIU 33,
  %result = mul i64 %a, 33
  ret i64 %result
}

; --- uimm6 max value: imm=63 ∈ [0,63] → SMULIU_ri ---
define i64 @test_smuliu_ri_63(i64 %a) {
; CHECK-LABEL: @func test_smuliu_ri_63
; CHECK: SMULIU 63,
  %result = mul i64 %a, 63
  ret i64 %result
}

; --- Positive overflow uimm6: imm=65 ∉ [0,63] → SMOVI + SMULIU_rr ---
define i64 @test_smuliu_rr_overflow(i64 %a) {
; CHECK-LABEL: @func test_smuliu_rr_overflow
; CHECK: SMOVI 65,
; CHECK-NOT: SMULIU 65,
; CHECK: SMULIU
  %result = mul i64 %a, 65
  ret i64 %result
}

; --- Negative underflow simm6: imm=-33 ∉ [-32,31] → SMOVI + SMULIS_rr ---
define i64 @test_smulis_rr_underflow(i64 %a) {
; CHECK-LABEL: @func test_smulis_rr_underflow
; CHECK: SMOVI 0xffffffffffffffdf,
; CHECK-NOT: SMULIS -33,
; CHECK: SMULIS
  %result = mul i64 %a, -33
  ret i64 %result
}

;; ==================== 64-bit MAC (SMULAU32T/SMULAS32T/SMULBU32T/SMULBS32T) ====================

; --- Multiply-add: (add (mul a, b), c) → SMULAU32T (unsigned, reg-reg-reg) ---
define i64 @test_mac_rrr(i64 %a, i64 %b, i64 %c) {
; CHECK-LABEL: @func test_mac_rrr
; CHECK: SMULAU32T
; CHECK-NOT: SMULIU
; CHECK-NOT: SADD
  %mul = mul i64 %a, %b
  %result = add i64 %mul, %c
  ret i64 %result
}

; --- Multiply-add commutative: (add c, (mul a, b)) → SMULAU32T ---
define i64 @test_mac_commute(i64 %a, i64 %b, i64 %c) {
; CHECK-LABEL: @func test_mac_commute
; CHECK: SMULAU32T
; CHECK-NOT: SMULIU
; CHECK-NOT: SADD
  %mul = mul i64 %a, %b
  %result = add i64 %c, %mul
  ret i64 %result
}

; --- Signed multiply-add: (add (mul a, -5), c) → SMULAS32T (negative immediate takes signed path) ---
define i64 @test_mac_signed(i64 %a, i64 %c) {
; CHECK-LABEL: @func test_mac_signed
; CHECK: SMULAS32T
; CHECK-NOT: SMULAU32T
  %mul = mul i64 %a, -5
  %result = add i64 %mul, %c
  ret i64 %result
}

; --- Multiply-sub: (sub c, (mul a, b)) → SMULBU32T (unsigned, reg-reg-reg) ---
define i64 @test_mas_rrr(i64 %a, i64 %b, i64 %c) {
; CHECK-LABEL: @func test_mas_rrr
; CHECK: SMULBU32T
; CHECK-NOT: SMULIU
; CHECK-NOT: SSUB
  %mul = mul i64 %a, %b
  %result = sub i64 %c, %mul
  ret i64 %result
}

; --- Signed multiply-sub: (sub c, (mul a, -3)) → SMULBS32T ---
define i64 @test_mas_signed(i64 %a, i64 %c) {
; CHECK-LABEL: @func test_mas_signed
; CHECK: SMULBS32T
; CHECK-NOT: SMULBU32T
  %mul = mul i64 %a, -3
  %result = sub i64 %c, %mul
  ret i64 %result
}

; --- No fusion: (sub (mul a, b), c) does not match (mul on LHS) ---
; This should generate separate mul and sub instructions
define i64 @test_no_mas_wrong_order(i64 %a, i64 %b, i64 %c) {
; CHECK-LABEL: @func test_no_mas_wrong_order
; CHECK-NOT: SMULBS32T
; CHECK-NOT: SMULBU32T
  %mul = mul i64 %a, %b
  %result = sub i64 %mul, %c
  ret i64 %result
}

; --- No fusion: mul has multiple uses, does not satisfy hasOneUse ---
define i64 @test_no_mac_multi_use(i64 %a, i64 %b, i64 %c) {
; CHECK-LABEL: @func test_no_mac_multi_use
; CHECK-NOT: SMULAU32T
; CHECK-NOT: SMULAS32T
  %mul = mul i64 %a, %b
  %mac = add i64 %mul, %c
  %result = add i64 %mac, %mul
  ret i64 %result
}

; --- Multiply-add with small positive immediate: (add (mul a, 5), c) → SMULAU32T (5 non-negative takes unsigned path) ---
define i64 @test_mac_uimm(i64 %a, i64 %c) {
; CHECK-LABEL: @func test_mac_uimm
; CHECK: SMULAU32T
  %mul = mul i64 %a, 5
  %result = add i64 %mul, %c
  ret i64 %result
}

; --- Multiply-add immediate in second operand: (add (mul 5, a), c) → SMULAU32T 5, a, c, dst ---
; Test multiplication commutativity places immediate in first position
define i64 @test_mac_uimm_commute(i64 %a, i64 %c) {
; CHECK-LABEL: @func test_mac_uimm_commute
; CHECK: SMULAU32T 5
  %mul = mul i64 5, %a
  %result = add i64 %mul, %c
  ret i64 %result
}

; --- Multiply-sub immediate in second operand: (sub c, (mul a, 10)) → SMULBU32T 10, a, c, dst ---
define i64 @test_mas_uimm(i64 %a, i64 %c) {
; CHECK-LABEL: @func test_mas_uimm
; CHECK: SMULBU32T 10
  %mul = mul i64 %a, 10
  %result = sub i64 %c, %mul
  ret i64 %result
}


; --- Multiply-add boundary: simm6 max value 31 ---
define i64 @test_mac_simm6_max(i64 %a, i64 %c) {
; CHECK-LABEL: @func test_mac_simm6_max
; CHECK: SMULAU32T 31
  %mul = mul i64 %a, 31
  %result = add i64 %mul, %c
  ret i64 %result
}

; --- Multiply-add exceeds simm6 range: 32 requires SMOVI + reg version ---
define i64 @test_mac_out_of_simm6(i64 %a, i64 %c) {
; CHECK-LABEL: @func test_mac_out_of_simm6
; CHECK: SMOVI 32
; CHECK: SMULAU32T
  %mul = mul i64 %a, 32
  %result = add i64 %mul, %c
  ret i64 %result
}

; --- Multiply-add boundary: near simm6 effective minimum -31 ---
define i64 @test_mac_simm6_min(i64 %a, i64 %c) {
; CHECK-LABEL: @func test_mac_simm6_min
; CHECK: SMULAS32T -31
  %mul = mul i64 %a, -31
  %result = add i64 %mul, %c
  ret i64 %result
}

;; ==================== Mixed-Sign Multiply ====================

;; --- SMULISU: 64-bit mixed-sign multiply ---

define i64 @test_smulisu(i64 %a, i64 %b) {
; CHECK-LABEL: @func test_smulisu
; CHECK: SMULISU
  %r = call i64 @llvm.ftm.smulisu(i64 %a, i64 %b)
  ret i64 %r
}

;; --- SMULISU32: 32-bit SIMD mixed-sign multiply ---

define <2 x i32> @test_smulisu32(<2 x i32> %a, <2 x i32> %b) {
; CHECK-LABEL: @func test_smulisu32
; CHECK: SMULISU32
  %r = call <2 x i32> @llvm.ftm.smulisu32(<2 x i32> %a, <2 x i32> %b)
  ret <2 x i32> %r
}

;; --- SMULASU32T: mixed-sign multiply-add (reg-reg-reg) ---

define i64 @test_smulasu32t(i64 %a, i64 %b, i64 %c) {
; CHECK-LABEL: @func test_smulasu32t
; CHECK: SMULASU32T
  %r = call i64 @llvm.ftm.smulasu32t(i64 %a, i64 %b, i64 %c)
  ret i64 %r
}

;; --- SMULAUS32T: mixed-sign multiply-add (reg-reg-reg) ---

define i64 @test_smulaus32t(i64 %a, i64 %b, i64 %c) {
; CHECK-LABEL: @func test_smulaus32t
; CHECK: SMULAUS32T
  %r = call i64 @llvm.ftm.smulaus32t(i64 %a, i64 %b, i64 %c)
  ret i64 %r
}

;; --- SMULBSU32T: mixed-sign multiply-subtract (reg-reg-reg) ---

define i64 @test_smulbsu32t(i64 %a, i64 %b, i64 %c) {
; CHECK-LABEL: @func test_smulbsu32t
; CHECK: SMULBSU32T
  %r = call i64 @llvm.ftm.smulbsu32t(i64 %a, i64 %b, i64 %c)
  ret i64 %r
}

;; --- SMULBUS32T: mixed-sign multiply-subtract (reg-reg-reg) ---

define i64 @test_smulbus32t(i64 %a, i64 %b, i64 %c) {
; CHECK-LABEL: @func test_smulbus32t
; CHECK: SMULBUS32T
  %r = call i64 @llvm.ftm.smulbus32t(i64 %a, i64 %b, i64 %c)
  ret i64 %r
}

;; --- SMULASU32T: mixed-sign multiply-add (imm-reg-reg) ---

define i64 @test_smulasu32t_i(i64 %b, i64 %c) {
; CHECK-LABEL: @func test_smulasu32t_i
; CHECK: SMULASU32T 5
  %r = call i64 @llvm.ftm.smulasu32t.i(i64 5, i64 %b, i64 %c)
  ret i64 %r
}

;; --- SMULAUS32T: mixed-sign multiply-add (imm-reg-reg) ---

define i64 @test_smulaus32t_i(i64 %b, i64 %c) {
; CHECK-LABEL: @func test_smulaus32t_i
; CHECK: SMULAUS32T 10
  %r = call i64 @llvm.ftm.smulaus32t.i(i64 10, i64 %b, i64 %c)
  ret i64 %r
}

;; --- SMULBSU32T: mixed-sign multiply-subtract (imm-reg-reg) ---

define i64 @test_smulbsu32t_i(i64 %b, i64 %c) {
; CHECK-LABEL: @func test_smulbsu32t_i
; CHECK: SMULBSU32T 3
  %r = call i64 @llvm.ftm.smulbsu32t.i(i64 3, i64 %b, i64 %c)
  ret i64 %r
}

;; --- SMULBUS32T: mixed-sign multiply-subtract (imm-reg-reg) ---

define i64 @test_smulbus32t_i(i64 %b, i64 %c) {
; CHECK-LABEL: @func test_smulbus32t_i
; CHECK: SMULBUS32T 7
  %r = call i64 @llvm.ftm.smulbus32t.i(i64 7, i64 %b, i64 %c)
  ret i64 %r
}

;; ==================== v2i32 SIMD Arithmetic ====================

; --- v2i32 addition: add v2i32 → SADD32 ---
define <2 x i32> @test_v2i32_add(<2 x i32> %a, <2 x i32> %b) {
; CHECK-LABEL: @func test_v2i32_add
; CHECK: SADD32
entry:
  %result = add <2 x i32> %a, %b
  ret <2 x i32> %result
}

; --- v2i32 subtraction: sub v2i32 → SSUB32 ---
define <2 x i32> @test_v2i32_sub(<2 x i32> %a, <2 x i32> %b) {
; CHECK-LABEL: @func test_v2i32_sub
; CHECK: SSUB32
entry:
  %result = sub <2 x i32> %a, %b
  ret <2 x i32> %result
}

; --- i64 chained operations: add + sub ---
define i64 @test_chain64(i64 %a, i64 %b, i64 %c) {
; CHECK-LABEL: @func test_chain64
; CHECK: SADD
; CHECK: SSUB
entry:
  %tmp = add i64 %a, %b
  %result = sub i64 %tmp, %c
  ret i64 %result
}

; --- v2i32 chained operations: add + sub ---
define <2 x i32> @test_chain_v2i32(<2 x i32> %a, <2 x i32> %b, <2 x i32> %c) {
; CHECK-LABEL: @func test_chain_v2i32
; CHECK: SADD32
; CHECK: SSUB32
entry:
  %tmp = add <2 x i32> %a, %b
  %result = sub <2 x i32> %tmp, %c
  ret <2 x i32> %result
}

; --- i64 mixed operations: add → sub ---
define i64 @test_mixed_add_sub(i64 %a, i64 %b, i64 %c) {
; CHECK-LABEL: @func test_mixed_add_sub
; CHECK: SADD
; CHECK: SSUB
entry:
  %sum = add i64 %a, %b
  %result = sub i64 %sum, %c
  ret i64 %result
}

; --- i64 mixed operations: sub → add ---
define i64 @test_mixed_sub_add(i64 %a, i64 %b, i64 %c) {
; CHECK-LABEL: @func test_mixed_sub_add
; CHECK: SSUB
; CHECK: SADD
entry:
  %diff = sub i64 %a, %b
  %result = add i64 %diff, %c
  ret i64 %result
}

;; ==================== v2i32/i32 Multiply ====================

;; ==================== v2i32 vector multiply ====================

; --- v2i32 basic multiply: mul v2i32 → SMULIU32 ---
define <2 x i32> @test_v2i32_mul_basic(<2 x i32> %a, <2 x i32> %b) {
; CHECK-LABEL: @func test_v2i32_mul_basic
; CHECK: SMULIU32
entry:
  %result = mul <2 x i32> %a, %b
  ret <2 x i32> %result
}

; --- v2i32 self-multiply (splat): mul a, a → SMULIU32 ---
define <2 x i32> @test_v2i32_mul_splat(<2 x i32> %a) {
; CHECK-LABEL: @func test_v2i32_mul_splat
; CHECK: SMULIU32
entry:
  %result = mul <2 x i32> %a, %a
  ret <2 x i32> %result
}

; --- v2i32 chained multiply: mul → mul → SMULIU32 × 2 ---
define <2 x i32> @test_v2i32_mul_chain(<2 x i32> %a, <2 x i32> %b, <2 x i32> %c) {
; CHECK-LABEL: @func test_v2i32_mul_chain
; CHECK: SMULIU32
; CHECK: SMULIU32
entry:
  %tmp = mul <2 x i32> %a, %b
  %result = mul <2 x i32> %tmp, %c
  ret <2 x i32> %result
}

; --- v2i32 multiply-add pattern: mul + add → SMULIU32 + SADD32 ---
define <2 x i32> @test_v2i32_mul_add(<2 x i32> %a, <2 x i32> %b, <2 x i32> %c) {
; CHECK-LABEL: @func test_v2i32_mul_add
; CHECK: SMULIU32
; CHECK: SADD32
entry:
  %prod = mul <2 x i32> %a, %b
  %result = add <2 x i32> %prod, %c
  ret <2 x i32> %result
}

; --- v2i32 multiply-sub pattern: mul + sub → SMULIU32 + SSUB32 ---
define <2 x i32> @test_v2i32_mul_sub(<2 x i32> %a, <2 x i32> %b, <2 x i32> %c) {
; CHECK-LABEL: @func test_v2i32_mul_sub
; CHECK: SMULIU32
; CHECK: SSUB32
entry:
  %prod = mul <2 x i32> %a, %b
  %result = sub <2 x i32> %c, %prod
  ret <2 x i32> %result
}

;; ==================== i32 scalar multiply ====================

; --- i32 basic multiply: reg × reg → SMULIU32 ---
define i32 @test_i32_mul_basic(i32 %a, i32 %b) {
; CHECK-LABEL: @func test_i32_mul_basic
; CHECK: SMULIU32
entry:
  %result = mul i32 %a, %b
  ret i32 %result
}

; --- i32 uimm6 exclusive range [32,63]: × 50 → SMULIU32 50 ---
define i32 @test_i32_mul_imm_u50(i32 %a) {
; CHECK-LABEL: @func test_i32_mul_imm_u50
; CHECK: SMULIU32 50
entry:
  %result = mul i32 %a, 50
  ret i32 %result
}

; --- i32 uimm6 max value: × 63 → SMULIU32 63 ---
define i32 @test_i32_mul_imm_u63(i32 %a) {
; CHECK-LABEL: @func test_i32_mul_imm_u63
; CHECK: SMULIU32 63
entry:
  %result = mul i32 %a, 63
  ret i32 %result
}

; --- i32 uimm6 overlap range: × 31 → SMULIU32 31 ---
define i32 @test_i32_mul_imm_u31(i32 %a) {
; CHECK-LABEL: @func test_i32_mul_imm_u31
; CHECK: SMULIU32 31
entry:
  %result = mul i32 %a, 31
  ret i32 %result
}

; --- i32 uimm6 overflow: × 100 → SMOVI + SMULIU32 rr ---
define i32 @test_i32_mul_imm_u100(i32 %a) {
; CHECK-LABEL: @func test_i32_mul_imm_u100
; CHECK: SMOVI 100
; CHECK: SMULIU32
entry:
  %result = mul i32 %a, 100
  ret i32 %result
}

;; ==================== simm6 vs uimm6 boundary tests ====================

; --- Negative -15: within simm6 range → SMULIS32 -15 ---
define i32 @test_boundary_neg15(i32 %a) {
; CHECK-LABEL: @func test_boundary_neg15
; CHECK: SMULIS32 -15
entry:
  %result = mul i32 %a, -15
  ret i32 %result
}

; --- Positive 50: uimm6 exclusive range → SMULIU32 50 ---
define i32 @test_boundary_u50(i32 %a) {
; CHECK-LABEL: @func test_boundary_u50
; CHECK: SMULIU32 50
entry:
  %result = mul i32 %a, 50
  ret i32 %result
}

; --- Negative -33: exceeds simm6 → SMOVI + SMULIS32 rr ---
define i32 @test_boundary_neg33(i32 %a) {
; CHECK-LABEL: @func test_boundary_neg33
; CHECK: SMOVI 0xffffffffffffffdf
; CHECK: SMULIS32
entry:
  %result = mul i32 %a, -33
  ret i32 %result
}

; --- Mixed immediate chained multiply ---
define i32 @test_mixed_mul_pattern(i32 %a) {
; CHECK-LABEL: @func test_mixed_mul_pattern
; CHECK: SMOVI
; CHECK: SMULIS32
entry:
  %t1 = mul i32 %a, 50
  %t2 = mul i32 %t1, -10
  %t3 = mul i32 %t2, 63
  %t4 = mul i32 %t3, -32
  ret i32 %t4
}
