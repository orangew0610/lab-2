; NOTE: Scalar control flow instruction selection tests
; RUN: llc -march=matrix -o - %s | FileCheck %s

;; ===================================================================
;; Scalar control flow instruction selection tests
;;
;; Instructions tested:
;;   @ret - function return
;;   @call - function call
;;   @sect/@usect - global variable emission
;;   SADD - address arithmetic (GEP)
;;   SBR/SEQ/SLT/SLTU - branch + compare
;;   SMAX - select→max optimization
;;   SMCMPEQ - address register compare
;;   SMFENCE/SERET/SIRET/SBRVNZ/SBRVZ/SINT/SEP/SWAIT - system control
;; ===================================================================

target triple = "matrix-unknown-unknown"

declare i64 @external_func(i64, i64)
declare i64 @single_arg(i64)
declare void @void_func()
declare i64 @llvm.ftm.smcmpeq(i64, i64)
declare void @llvm.ftm.smfence()
declare void @llvm.ftm.seret()
declare void @llvm.ftm.siret(i64)
declare void @llvm.ftm.sbrvnz(i64)
declare void @llvm.ftm.sbrvz(i64)
declare void @llvm.ftm.sint(i64)
declare void @llvm.ftm.sep(i64)
declare void @llvm.ftm.swait()

;; ==================== Function Return (@ret) ====================

define i32 @return_zero() {
; CHECK-LABEL: @func return_zero
; CHECK: @ret
entry:
  ret i32 0
}

define i32 @return_42() {
; CHECK-LABEL: @func return_42
; CHECK: @ret
entry:
  ret i32 42
}

define i32 @return_arg(i32 %x) {
; CHECK-LABEL: @func return_arg
; CHECK: @ret
entry:
  ret i32 %x
}

define void @return_void() {
; CHECK-LABEL: @func return_void
; CHECK: @ret
entry:
  ret void
}

;; ==================== Function Call (@call) ====================

; --- Basic two-argument call → @call ---
define i64 @test_call(i64 %a, i64 %b) {
; CHECK-LABEL: @func test_call
; CHECK: @call external_func
; CHECK: @ret
  %r = call i64 @external_func(i64 %a, i64 %b)
  ret i64 %r
}

; --- Call with constant arguments → SMOVI + @call ---
define i64 @test_call_const() {
; CHECK-LABEL: @func test_call_const
; CHECK: SMOVI
; CHECK: @call external_func
  %r = call i64 @external_func(i64 42, i64 7)
  ret i64 %r
}

; --- Single-argument call ---
define i64 @test_call_single(i64 %x) {
; CHECK-LABEL: @func test_call_single
; CHECK: @call single_arg
; CHECK: @ret
  %r = call i64 @single_arg(i64 %x)
  ret i64 %r
}

; --- Void call (no return value) ---
define void @test_call_void() {
; CHECK-LABEL: @func test_call_void
; CHECK: @call void_func
; CHECK: @ret
  call void @void_func()
  ret void
}

;; ==================== Address Arithmetic (GEP → SADD) ====================

; --- Small positive offset: GEP i8 +10 → SADD 10 ---
define ptr @test_sadda_imm_small(ptr %ptr) {
; CHECK-LABEL: @func test_sadda_imm_small
; CHECK: SADD 10
entry:
  %result = getelementptr i8, ptr %ptr, i64 10
  ret ptr %result
}

; --- Negative offset: GEP i8 -20 → SADD -20 ---
define ptr @test_sadda_imm_neg(ptr %ptr) {
; CHECK-LABEL: @func test_sadda_imm_neg
; CHECK: SADD -20
entry:
  %result = getelementptr i8, ptr %ptr, i64 -20
  ret ptr %result
}

; --- Zero offset: GEP i8 0 → optimized away ---
define ptr @test_sadda_imm_zero(ptr %ptr) {
; CHECK-LABEL: @func test_sadda_imm_zero
; CHECK-NOT: SADD
; CHECK: @ret
entry:
  %result = getelementptr i8, ptr %ptr, i64 0
  ret ptr %result
}

; --- simm6 max value: GEP i8 +31 → SADD 31 ---
define ptr @test_sadda_imm_max(ptr %ptr) {
; CHECK-LABEL: @func test_sadda_imm_max
; CHECK: SADD 31
entry:
  %result = getelementptr i8, ptr %ptr, i64 31
  ret ptr %result
}

; --- simm6 min value: GEP i8 -32 → SADD -32 ---
define ptr @test_sadda_imm_min(ptr %ptr) {
; CHECK-LABEL: @func test_sadda_imm_min
; CHECK: SADD -32
entry:
  %result = getelementptr i8, ptr %ptr, i64 -32
  ret ptr %result
}

; --- i64 array index: GEP i64 idx=1 → SADD 8 ---
define ptr @test_sadda_i64_idx1(ptr %base) {
; CHECK-LABEL: @func test_sadda_i64_idx1
; CHECK: SADD 8
entry:
  %result = getelementptr i64, ptr %base, i64 1
  ret ptr %result
}

; --- i32 array index: GEP i32 idx=7 → SADD 28 ---
define ptr @test_sadda_i32_idx7(ptr %base) {
; CHECK-LABEL: @func test_sadda_i32_idx7
; CHECK: SADD 28
entry:
  %result = getelementptr i32, ptr %base, i64 7
  ret ptr %result
}

; --- i8 array index: GEP i8 idx=10 → SADD 10 ---
define ptr @test_sadda_i8_idx10(ptr %base) {
; CHECK-LABEL: @func test_sadda_i8_idx10
; CHECK: SADD 10
entry:
  %result = getelementptr i8, ptr %base, i64 10
  ret ptr %result
}

; --- Negative offset (SSUBA): GEP i8 -15 → SADD -15 ---
define ptr @test_ssuba_via_sadda(ptr %ptr) {
; CHECK-LABEL: @func test_ssuba_via_sadda
; CHECK: SADD -15
entry:
  %result = getelementptr i8, ptr %ptr, i64 -15
  ret ptr %result
}

; --- Register-register: variable offset → SADD rr ---
define ptr @test_addr_reg_reg(ptr %ptr, i64 %offset) {
; CHECK-LABEL: @func test_addr_reg_reg
; CHECK: SADD r{{[0-9]+}}, r{{[0-9]+}}
entry:
  %result = getelementptr i8, ptr %ptr, i64 %offset
  ret ptr %result
}

; --- Chained address arithmetic: GEP +8 + GEP +8 → SADD 16 (merge optimization) ---
define ptr @test_addr_chain(ptr %base) {
; CHECK-LABEL: @func test_addr_chain
; CHECK: SADD 16
entry:
  %p1 = getelementptr i8, ptr %base, i64 8
  %p2 = getelementptr i8, ptr %p1, i64 8
  ret ptr %p2
}

;; ==================== Branch Control (SBR/SEQ/SLT/SLTU) ====================

; --- Basic unconditional branch → SBR ---
define void @test_unconditional_branch() {
; CHECK-LABEL: @func test_unconditional_branch
; CHECK: @ret
  br label %target

target:
  ret void
}

; --- Conditional branch with PHI → SEQ + SBR ---
define i64 @test_branch_with_phi(i64 %a, i64 %b) {
; CHECK-LABEL: @func test_branch_with_phi
; CHECK: SEQ
; CHECK: SBR
  %cmp = icmp eq i64 %a, %b
  br i1 %cmp, label %true, label %false

true:
  br label %merge

false:
  br label %merge

merge:
  %result = phi i64 [ %a, %true ], [ %b, %false ]
  ret i64 %result
}

; --- Indirect branch (computed goto) → SBR reg ---
define void @test_indirect_branch(ptr %addr) {
; CHECK-LABEL: @func test_indirect_branch
; CHECK: SBR
  indirectbr ptr %addr, [label %target]

target:
  ret void
}

; --- Nested branches → multiple SBR ---
define i64 @test_nested_branches(i64 %a, i64 %b, i64 %c) {
; CHECK-LABEL: @func test_nested_branches
; CHECK: SLT
; CHECK: SBR
; CHECK: SEQ
; CHECK: SBR
  %cmp1 = icmp slt i64 %a, %b
  br i1 %cmp1, label %outer_true, label %outer_false

outer_true:
  %cmp2 = icmp eq i64 %b, %c
  br i1 %cmp2, label %inner_true, label %inner_false

inner_true:
  ret i64 1

inner_false:
  ret i64 2

outer_false:
  ret i64 3
}

; --- icmp eq → SEQ + [!$cond] SBR (branch to false when NOT equal) ---
define i64 @test_icmp_eq_branch(i64 %a, i64 %b) {
; CHECK-LABEL: @func test_icmp_eq_branch
; CHECK: SEQ
; CHECK: SBR
  %cmp = icmp eq i64 %a, %b
  br i1 %cmp, label %iftrue, label %iffalse

iftrue:
  ret i64 1

iffalse:
  ret i64 0
}

; --- icmp ne → SEQ + [$cond] SBR (branch to false when equal) ---
define i64 @test_icmp_ne_branch(i64 %a, i64 %b) {
; CHECK-LABEL: @func test_icmp_ne_branch
; CHECK: SEQ
; CHECK: SBR
  %cmp = icmp ne i64 %a, %b
  br i1 %cmp, label %iftrue, label %iffalse

iftrue:
  ret i64 1

iffalse:
  ret i64 0
}

; --- icmp slt → SLT + [!$cond] SBR ---
define i64 @test_icmp_slt_branch(i64 %a, i64 %b) {
; CHECK-LABEL: @func test_icmp_slt_branch
; CHECK: SLT
; CHECK: SBR
  %cmp = icmp slt i64 %a, %b
  br i1 %cmp, label %iftrue, label %iffalse

iftrue:
  ret i64 1

iffalse:
  ret i64 0
}

; --- icmp sgt → SLT (swapped operands) + [!$cond] SBR ---
define i64 @test_icmp_sgt_branch(i64 %a, i64 %b) {
; CHECK-LABEL: @func test_icmp_sgt_branch
; CHECK: SLT
; CHECK: SBR
  %cmp = icmp sgt i64 %a, %b
  br i1 %cmp, label %iftrue, label %iffalse

iftrue:
  ret i64 1

iffalse:
  ret i64 0
}

; --- icmp ult → SLTU + [!$cond] SBR ---
define i64 @test_icmp_ult_branch(i64 %a, i64 %b) {
; CHECK-LABEL: @func test_icmp_ult_branch
; CHECK: SLTU
; CHECK: SBR
  %cmp = icmp ult i64 %a, %b
  br i1 %cmp, label %iftrue, label %iffalse

iftrue:
  ret i64 1

iffalse:
  ret i64 0
}

; --- select with icmp sgt → SMAX (DAG combiner recognizes max pattern) ---
; Note: Previously generated SLT + SBR (triangle CFG), but since SMAX was marked Legal,
; DAG combiner recognizes select(icmp sgt a, b, a, b) as smax(a, b) and emits SMAX directly
define i64 @test_select_sgt(i64 %a, i64 %b) {
; CHECK-LABEL: @func test_select_sgt
; CHECK: SMAX
  %cmp = icmp sgt i64 %a, %b
  %res = select i1 %cmp, i64 %a, i64 %b
  ret i64 %res
}

;; ==================== Address Register Compare (SMCMPEQ) ====================

define i64 @test_smcmpeq(i64 %a, i64 %b) {
; CHECK-LABEL: @func test_smcmpeq
; CHECK: SMCMPEQ
entry:
  %r = call i64 @llvm.ftm.smcmpeq(i64 %a, i64 %b)
  ret i64 %r
}

;; ==================== System Control (SMFENCE/SERET/SIRET/etc.) ====================

; --- SMFENCE: memory fence ---
define void @test_smfence() {
; CHECK-LABEL: @func test_smfence
; CHECK: SMFENCE
; CHECK: @ret
  call void @llvm.ftm.smfence()
  ret void
}

; --- SERET: exception return ---
define void @test_seret() {
; CHECK-LABEL: @func test_seret
; CHECK: SERET
  call void @llvm.ftm.seret()
  unreachable
}

; --- SIRET: interrupt return (normal, imm=0) ---
define void @test_siret_normal() {
; CHECK-LABEL: @func test_siret_normal
; CHECK: SIRET 0
  call void @llvm.ftm.siret(i64 0)
  unreachable
}

; --- SIRET: interrupt return (NMI, imm=1) ---
define void @test_siret_nmi() {
; CHECK-LABEL: @func test_siret_nmi
; CHECK: SIRET 1
  call void @llvm.ftm.siret(i64 1)
  unreachable
}

; --- SBRVNZ: branch if VR0 != 0, register target ---
define void @test_sbrvnz_reg(i64 %target) {
; CHECK-LABEL: @func test_sbrvnz_reg
; CHECK: SBRVNZ
  call void @llvm.ftm.sbrvnz(i64 %target)
  ret void
}

; --- SBRVZ: branch if VR0 == 0, register target ---
define void @test_sbrvz_reg(i64 %target) {
; CHECK-LABEL: @func test_sbrvz_reg
; CHECK: SBRVZ
  call void @llvm.ftm.sbrvz(i64 %target)
  ret void
}

; --- SINT: set interrupt flag ---
define void @test_sint() {
; CHECK-LABEL: @func test_sint
; CHECK: SINT 5
  call void @llvm.ftm.sint(i64 5)
  ret void
}

; --- SEP: set exception flag ---
define void @test_sep() {
; CHECK-LABEL: @func test_sep
; CHECK: SEP 3
  call void @llvm.ftm.sep(i64 3)
  ret void
}

; --- SWAIT: stall pipeline ---
define void @test_swait() {
; CHECK-LABEL: @func test_swait
; CHECK: SWAIT
  call void @llvm.ftm.swait()
  ret void
}

;; ==================== Global Variables (@sect/@usect) ====================
;; Note: Globals are emitted after functions in assembly output.

@gvar = global i64 42
; CHECK: @sect ".data", gvar, @b64, 42

@bss_var = global i64 0
; CHECK: @usect ".bss", bss_var, @b64, 1
