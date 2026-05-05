; NOTE: Scalar↔vector transfer instruction selection tests
; RUN: llc -march=matrix -o - %s | FileCheck %s

;; ===================================================================
;; Scalar↔vector transfer instruction selection tests
;;
;; Instructions tested:
;;   SJVRZ/SJVRO16/SJVRO32/SJVRO64 - vector→scalar reduction
;;   SVBCAST - scalar→vector broadcast (non-constant)
;;   SVBCAST2/SVBCAST2SEXT/SVBCAST2HEXTH/SVBCAST2HEXTL - extended broadcast
;;   VMOVI - constant vector splat (regression test)
;; ===================================================================

target triple = "matrix-unknown-unknown"

declare <32 x i32> @llvm.ftm.vldw(ptr addrspace(1), i64)
declare i64 @llvm.ftm.sjvrz(<16 x i64>)
declare i64 @llvm.ftm.sjvro16(<32 x i32>)
declare i64 @llvm.ftm.sjvro32(<32 x i32>)
declare i64 @llvm.ftm.sjvro64(<16 x i64>)
declare <32 x i32> @llvm.ftm.veq32(<32 x i32>, <32 x i32>)
declare void @llvm.ftm.vstw(<32 x i32>, ptr addrspace(1), i64)
declare void @llvm.ftm.vstdw(<32 x i64>, ptr addrspace(1), i64)
declare <32 x i64> @llvm.ftm.svbcast2(i64, i64)
declare <32 x i64> @llvm.ftm.svbcast2sext(i64)
declare <32 x i64> @llvm.ftm.svbcast2hexth(i64)
declare <32 x i64> @llvm.ftm.svbcast2hextl(i64)

;; ==================== Vector→Scalar Reduction (SJV) ====================

; ===================================================================
; SJVRZ: all 64-bit elements zero → 1
; ===================================================================

; CHECK-LABEL: @func test_sjvrz
; CHECK: SJVRZ
define i64 @test_sjvrz(ptr addrspace(1) %base, i64 %off) {
  %v_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %v = bitcast <32 x i32> %v_raw to <16 x i64>
  %res = call i64 @llvm.ftm.sjvrz(<16 x i64> %v)
  ret i64 %res
}

; ===================================================================
; SJVRO16: all 16-bit elements == 1 → 1
; ===================================================================

; CHECK-LABEL: @func test_sjvro16
; CHECK: SJVRO16
define i64 @test_sjvro16(ptr addrspace(1) %base, i64 %off) {
  %v = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %res = call i64 @llvm.ftm.sjvro16(<32 x i32> %v)
  ret i64 %res
}

; ===================================================================
; SJVRO32: all 32-bit elements == 1 → 1
; ===================================================================

; CHECK-LABEL: @func test_sjvro32
; CHECK: SJVRO32
define i64 @test_sjvro32(ptr addrspace(1) %base, i64 %off) {
  %v = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %res = call i64 @llvm.ftm.sjvro32(<32 x i32> %v)
  ret i64 %res
}

; ===================================================================
; SJVRO64: all 64-bit elements == 1 → 1
; ===================================================================

; CHECK-LABEL: @func test_sjvro64
; CHECK: SJVRO64
define i64 @test_sjvro64(ptr addrspace(1) %base, i64 %off) {
  %v_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %v = bitcast <32 x i32> %v_raw to <16 x i64>
  %res = call i64 @llvm.ftm.sjvro64(<16 x i64> %v)
  ret i64 %res
}

; ===================================================================
; SJV + conditional branch: VCMP → SJV → SEQ → SBR pattern
; ===================================================================

; CHECK-LABEL: @func test_sjv_branch
; CHECK: VEQ32
; CHECK: SJVRO32
; CHECK: SEQ
; CHECK: SBR
define void @test_sjv_branch(ptr addrspace(1) %base, i64 %off, ptr addrspace(1) %base2, i64 %off2) {
entry:
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base2, i64 %off2)
  %cmp = call <32 x i32> @llvm.ftm.veq32(<32 x i32> %a, <32 x i32> %b)
  %all_eq = call i64 @llvm.ftm.sjvro32(<32 x i32> %cmp)
  %cond = icmp ne i64 %all_eq, 0
  br i1 %cond, label %if.then, label %if.end

if.then:
  call void @llvm.ftm.vstw(<32 x i32> %a, ptr addrspace(1) %base, i64 %off)
  br label %if.end

if.end:
  ret void
}

;; ==================== Scalar→Vector Broadcast (SVBCAST) ====================

; ===================================================================
; SVBCAST: non-constant scalar splat → SVBCAST (not VMOVI)
; Uses insertelement + shufflevector to produce SPLAT_VECTOR in DAG
; ===================================================================

; CHECK-LABEL: @func test_svbcast_i64
; CHECK: SVBCAST
; CHECK-NOT: VMOVI
; CHECK: VSTW
define void @test_svbcast_i64(i64 %val, ptr addrspace(1) %base, i64 %off) {
  %splat = insertelement <16 x i64> poison, i64 %val, i64 0
  %vec = shufflevector <16 x i64> %splat, <16 x i64> poison, <16 x i32> zeroinitializer
  %out = bitcast <16 x i64> %vec to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %out, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_svbcast_f64
; CHECK: SVBCAST
; CHECK-NOT: VMOVI
; CHECK: VSTW
define void @test_svbcast_f64(double %val, ptr addrspace(1) %base, i64 %off) {
  %splat = insertelement <16 x double> poison, double %val, i64 0
  %vec = shufflevector <16 x double> %splat, <16 x double> poison, <16 x i32> zeroinitializer
  %out = bitcast <16 x double> %vec to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %out, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; SVBCAST2: GPR128 → VPR2048 broadcast
; ===================================================================

; CHECK-LABEL: @func test_svbcast2
; CHECK: SVBCAST2 {{.*}}
; CHECK: VSTDW
define void @test_svbcast2(i64 %lo, i64 %hi, ptr addrspace(1) %base, i64 %off) {
  %res = call <32 x i64> @llvm.ftm.svbcast2(i64 %lo, i64 %hi)
  call void @llvm.ftm.vstdw(<32 x i64> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; SVBCAST2SEXT: f32→f64 sign-extend broadcast → VPR2048
; ===================================================================

; CHECK-LABEL: @func test_svbcast2sext
; CHECK: SVBCAST2SEXT
; CHECK: VSTDW
define void @test_svbcast2sext(i64 %val, ptr addrspace(1) %base, i64 %off) {
  %res = call <32 x i64> @llvm.ftm.svbcast2sext(i64 %val)
  call void @llvm.ftm.vstdw(<32 x i64> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; SVBCAST2HEXTH: f16 high → f64 broadcast → VPR2048
; ===================================================================

; CHECK-LABEL: @func test_svbcast2hexth
; CHECK: SVBCAST2HEXTH
; CHECK: VSTDW
define void @test_svbcast2hexth(i64 %val, ptr addrspace(1) %base, i64 %off) {
  %res = call <32 x i64> @llvm.ftm.svbcast2hexth(i64 %val)
  call void @llvm.ftm.vstdw(<32 x i64> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; SVBCAST2HEXTL: f16 low → f64 broadcast → VPR2048
; ===================================================================

; CHECK-LABEL: @func test_svbcast2hextl
; CHECK: SVBCAST2HEXTL
; CHECK: VSTDW
define void @test_svbcast2hextl(i64 %val, ptr addrspace(1) %base, i64 %off) {
  %res = call <32 x i64> @llvm.ftm.svbcast2hextl(i64 %val)
  call void @llvm.ftm.vstdw(<32 x i64> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; Regression: constant splat still uses VMOVI (not SVBCAST)
; ===================================================================

; CHECK-LABEL: @func test_vmovi_regression
; CHECK: VMOVI
; CHECK: VSTW
define void @test_vmovi_regression(ptr addrspace(1) %base, i64 %off) {
  %splat = insertelement <16 x i64> poison, i64 42, i64 0
  %vec = shufflevector <16 x i64> %splat, <16 x i64> poison, <16 x i32> zeroinitializer
  %out = bitcast <16 x i64> %vec to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %out, ptr addrspace(1) %base, i64 %off)
  ret void
}
