; NOTE: Vector floating-point arithmetic instruction selection tests
; RUN: llc -march=matrix -o - %s | FileCheck %s

;; ===================================================================
;; Vector floating-point arithmetic instruction selection tests
;;
;; Instructions tested:
;;   VFADDD/VFADDS32/VFSUBD/VFSUBS32 - vector add/sub
;;   VFABSD/VFABSS32 - vector FP absolute
;;   VFDTRU/VFINTD/VFINTDU/VFSTRU32/VFINTS32/VFINTSU32 - FP↔int convert
;;   VFDPSP32/VFSPDP32T/VFSPHDP32T - precision convert
;;   VFRCPD/VFRCPS32/VFRSQD/VFRSQS32 - reciprocal approx
;;   VFMULD/VFMULS32 - vector multiply
;;   VFMULAD/VFMULAS32/VFMULBD/VFMULBS32 - vector FMA
;;   VFDOT32/VFCMUL32 - dot product/complex multiply
;;   VFLOGD/VFLOGS32/VFMAND/VFMANS32 - exponent/mantissa extract
;;   VFDINT/VFSINT32 - hardware rounding conversion
;; ===================================================================

target triple = "matrix-unknown-unknown"

; --- Intrinsic declarations ---
declare <32 x i32> @llvm.ftm.vldw(ptr addrspace(1), i64)
declare <32 x i32> @llvm.ftm.vldh(ptr addrspace(1), i64)
declare <32 x i32> @llvm.ftm.vldhu(ptr addrspace(1), i64)
declare void @llvm.ftm.vstw(<32 x i32>, ptr addrspace(1), i64)
declare void @llvm.ftm.vsth(<32 x i32>, ptr addrspace(1), i64)
declare <16 x double> @llvm.fabs.v16f64(<16 x double>)
declare <32 x float> @llvm.fabs.v32f32(<32 x float>)
declare <32 x float> @llvm.ftm.vfdpsp32(<16 x double>, <16 x double>)
declare <16 x double> @llvm.ftm.vfspdp32t(<32 x float>)
declare <16 x double> @llvm.ftm.vfsphdp32t(<32 x float>)
declare <16 x double> @llvm.ftm.vfrcpd(<16 x double>)
declare <32 x float> @llvm.ftm.vfrcps32(<32 x float>)
declare <16 x double> @llvm.ftm.vfrsqd(<16 x double>)
declare <32 x float> @llvm.ftm.vfrsqs32(<32 x float>)
declare <16 x double> @llvm.fma.v16f64(<16 x double>, <16 x double>, <16 x double>)
declare <32 x float> @llvm.fma.v32f32(<32 x float>, <32 x float>, <32 x float>)
declare <32 x float> @llvm.ftm.vfdot32(<32 x float>, <32 x float>)
declare <32 x float> @llvm.ftm.vfcmul32(<32 x float>, <32 x float>)
declare <16 x i64> @llvm.ftm.vfdint(<16 x double>)
declare <32 x i32> @llvm.ftm.vfsint32(<32 x float>)
declare <16 x i64> @llvm.ftm.vflogd(<16 x double>)
declare <32 x i32> @llvm.ftm.vflogs32(<32 x float>)
declare <16 x i64> @llvm.ftm.vfmand(<16 x double>)
declare <32 x i32> @llvm.ftm.vfmans32(<32 x float>)

; ==================== Vector FP ALU (VFADD/VFSUB/VFABS/convert/precision/reciprocal) ====================

; ===================================================================
; Group 1: Basic Arithmetic
; ===================================================================

; CHECK-LABEL: @func test_vfaddd
; CHECK: VLDW
; CHECK: VFADDD
; CHECK: VSTW
define void @test_vfaddd(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <16 x double>
  %c = fadd <16 x double> %a, %a
  %res = bitcast <16 x double> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vfadds32
; CHECK: VLDW
; CHECK: VFADDS32
; CHECK: VSTW
define void @test_vfadds32(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <32 x float>
  %c = fadd <32 x float> %a, %a
  %res = bitcast <32 x float> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vfsubd
; CHECK: VLDW
; CHECK: VFSUBD
; CHECK: VSTW
define void @test_vfsubd(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <16 x double>
  %c = fsub <16 x double> %a, %a
  %res = bitcast <16 x double> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vfsubs32
; CHECK: VLDW
; CHECK: VFSUBS32
; CHECK: VSTW
define void @test_vfsubs32(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <32 x float>
  %c = fsub <32 x float> %a, %a
  %res = bitcast <32 x float> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; Group 2: Absolute Value
; ===================================================================

; CHECK-LABEL: @func test_vfabsd
; CHECK: VLDW
; CHECK: VFABSD
; CHECK: VSTW
define void @test_vfabsd(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <16 x double>
  %c = call <16 x double> @llvm.fabs.v16f64(<16 x double> %a)
  %res = bitcast <16 x double> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vfabss32
; CHECK: VLDW
; CHECK: VFABSS32
; CHECK: VSTW
define void @test_vfabss32(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <32 x float>
  %c = call <32 x float> @llvm.fabs.v32f32(<32 x float> %a)
  %res = bitcast <32 x float> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; Group 3: FP↔Int Conversions
; ===================================================================

; CHECK-LABEL: @func test_vfdtru
; CHECK: VLDW
; CHECK: VFDTRU
; CHECK: VSTW
define void @test_vfdtru(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <16 x double>
  %c = fptosi <16 x double> %a to <16 x i64>
  %res = bitcast <16 x i64> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vfintd
; CHECK: VLDW
; CHECK: VFINTD
; CHECK: VSTW
define void @test_vfintd(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <16 x i64>
  %c = sitofp <16 x i64> %a to <16 x double>
  %res = bitcast <16 x double> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vfintdu
; CHECK: VLDW
; CHECK: VFINTDU
; CHECK: VSTW
define void @test_vfintdu(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <16 x i64>
  %c = uitofp <16 x i64> %a to <16 x double>
  %res = bitcast <16 x double> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vfstru32
; CHECK: VLDW
; CHECK: VFSTRU32
; CHECK: VSTW
define void @test_vfstru32(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <32 x float>
  %c = fptosi <32 x float> %a to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %c, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vfints32
; CHECK: VLDW
; CHECK: VFINTS32
; CHECK: VSTW
define void @test_vfints32(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %c = sitofp <32 x i32> %raw to <32 x float>
  %res = bitcast <32 x float> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vfintsu32
; CHECK: VLDW
; CHECK: VFINTSU32
; CHECK: VSTW
define void @test_vfintsu32(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %c = uitofp <32 x i32> %raw to <32 x float>
  %res = bitcast <32 x float> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; Group 4: Precision Conversions (target intrinsics)
; ===================================================================

; CHECK-LABEL: @func test_vfdpsp32
; CHECK: VLDW
; CHECK: VFDPSP32
; CHECK: VSTW
define void @test_vfdpsp32(ptr addrspace(1) %base, i64 %off1, i64 %off2) {
  %raw1 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off1)
  %raw2 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off2)
  %a = bitcast <32 x i32> %raw1 to <16 x double>
  %b = bitcast <32 x i32> %raw2 to <16 x double>
  %c = call <32 x float> @llvm.ftm.vfdpsp32(<16 x double> %a, <16 x double> %b)
  %res = bitcast <32 x float> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off1)
  ret void
}

; CHECK-LABEL: @func test_vfspdp32t
; CHECK: VLDW
; CHECK: VFSPDP32T
; CHECK: VSTW
define void @test_vfspdp32t(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <32 x float>
  %c = call <16 x double> @llvm.ftm.vfspdp32t(<32 x float> %a)
  %res = bitcast <16 x double> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vfsphdp32t
; CHECK: VLDW
; CHECK: VFSPHDP32T
; CHECK: VSTW
define void @test_vfsphdp32t(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <32 x float>
  %c = call <16 x double> @llvm.ftm.vfsphdp32t(<32 x float> %a)
  %res = bitcast <16 x double> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; Group 5: Reciprocal Approximations (target intrinsics)
; ===================================================================

; CHECK-LABEL: @func test_vfrcpd
; CHECK: VLDW
; CHECK: VFRCPD
; CHECK: VSTW
define void @test_vfrcpd(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <16 x double>
  %c = call <16 x double> @llvm.ftm.vfrcpd(<16 x double> %a)
  %res = bitcast <16 x double> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vfrcps32
; CHECK: VLDW
; CHECK: VFRCPS32
; CHECK: VSTW
define void @test_vfrcps32(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <32 x float>
  %c = call <32 x float> @llvm.ftm.vfrcps32(<32 x float> %a)
  %res = bitcast <32 x float> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vfrsqd
; CHECK: VLDW
; CHECK: VFRSQD
; CHECK: VSTW
define void @test_vfrsqd(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <16 x double>
  %c = call <16 x double> @llvm.ftm.vfrsqd(<16 x double> %a)
  %res = bitcast <16 x double> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vfrsqs32
; CHECK: VLDW
; CHECK: VFRSQS32
; CHECK: VSTW
define void @test_vfrsqs32(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <32 x float>
  %c = call <32 x float> @llvm.ftm.vfrsqs32(<32 x float> %a)
  %res = bitcast <32 x float> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ==================== Vector FP MAC (VFMUL/VFMULA/VFMULB/VFDOT/VFCMUL) ====================

; ===================================================================
; VFMULD: v16f64 multiply via fmul
; Hardware: dst = src1 * src2
; ===================================================================

; CHECK-LABEL: @func test_vfmuld
; CHECK: VLDW
; CHECK: VFMULD
; CHECK: VSTW
define void @test_vfmuld(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <16 x double>
  %c = fmul <16 x double> %a, %a
  %res = bitcast <16 x double> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; VFMULS32: v32f32 multiply via fmul
; Hardware: dst = src1 * src2
; ===================================================================

; CHECK-LABEL: @func test_vfmuls32
; CHECK: VLDW
; CHECK: VFMULS32
; CHECK: VSTW
define void @test_vfmuls32(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <32 x float>
  %c = fmul <32 x float> %a, %a
  %res = bitcast <32 x float> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; VFMULAD: v16f64 fused multiply-add via llvm.fma
; Hardware: dst = src1*src2 + src3  (op_rule "*,+:1,2,3")
; LLVM fma(a,b,c) = a*b + c → maps to VFMULAD src1=a, src2=b, src3=c
; ===================================================================

; CHECK-LABEL: @func test_vfmulad_fma
; CHECK-DAG: VLDW
; CHECK-DAG: VLDH
; Verify: VFMULAD with 3 operands + dst
; CHECK: VFMULAD {{v[0-9]+}}, {{v[0-9]+}}, {{v[0-9]+}}, {{v[0-9]+}}
; CHECK: VSTW
define void @test_vfmulad_fma(ptr addrspace(1) %base, i64 %off) {
  %raw1 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %raw2 = call <32 x i32> @llvm.ftm.vldh(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw1 to <16 x double>
  %c = bitcast <32 x i32> %raw2 to <16 x double>
  ; fma(a, a, c) = a*a + c
  %d = call <16 x double> @llvm.fma.v16f64(<16 x double> %a, <16 x double> %a, <16 x double> %c)
  %res = bitcast <16 x double> %d to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; VFMULAS32: v32f32 fused multiply-add via llvm.fma
; Hardware: dst = src1*src2 + src3  (op_rule "*,+:1,2,3")
; ===================================================================

; CHECK-LABEL: @func test_vfmulas32_fma
; CHECK-DAG: VLDW
; CHECK-DAG: VLDH
; CHECK: VFMULAS32 {{v[0-9]+}}, {{v[0-9]+}}, {{v[0-9]+}}, {{v[0-9]+}}
; CHECK: VSTW
define void @test_vfmulas32_fma(ptr addrspace(1) %base, i64 %off) {
  %raw1 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %raw2 = call <32 x i32> @llvm.ftm.vldh(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw1 to <32 x float>
  %c = bitcast <32 x i32> %raw2 to <32 x float>
  %d = call <32 x float> @llvm.fma.v32f32(<32 x float> %a, <32 x float> %a, <32 x float> %c)
  %res = bitcast <32 x float> %d to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; VFMULBD: v16f64 fused multiply-subtract via DAGCombine
; Hardware: dst = src1*src2 - src3  (op_rule "*,-:1,2,3")
; IR: fsub(fmul(a,b), c) → VFMULBD src1=a, src2=b, src3=c
; ===================================================================

; CHECK-LABEL: @func test_vfmulbd
; CHECK-DAG: VLDW
; CHECK-DAG: VLDH
; CHECK: VFMULBD {{v[0-9]+}}, {{v[0-9]+}}, {{v[0-9]+}}, {{v[0-9]+}}
; CHECK: VSTW
define void @test_vfmulbd(ptr addrspace(1) %base, i64 %off) {
  %raw1 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %raw2 = call <32 x i32> @llvm.ftm.vldh(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw1 to <16 x double>
  %c = bitcast <32 x i32> %raw2 to <16 x double>
  ; a*a - c
  %mul = fmul <16 x double> %a, %a
  %d = fsub <16 x double> %mul, %c
  %res = bitcast <16 x double> %d to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; VFMULBS32: v32f32 fused multiply-subtract via DAGCombine
; Hardware: dst = src1*src2 - src3  (op_rule "*,-:1,2,3")
; ===================================================================

; CHECK-LABEL: @func test_vfmulbs32
; CHECK-DAG: VLDW
; CHECK-DAG: VLDH
; CHECK: VFMULBS32 {{v[0-9]+}}, {{v[0-9]+}}, {{v[0-9]+}}, {{v[0-9]+}}
; CHECK: VSTW
define void @test_vfmulbs32(ptr addrspace(1) %base, i64 %off) {
  %raw1 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %raw2 = call <32 x i32> @llvm.ftm.vldh(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw1 to <32 x float>
  %c = bitcast <32 x i32> %raw2 to <32 x float>
  %mul = fmul <32 x float> %a, %a
  %d = fsub <32 x float> %mul, %c
  %res = bitcast <32 x float> %d to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; VFDOT32: v32f32 dot product via target intrinsic
; Hardware: dst.lo = src1.hi*src2.hi + src1.lo*src2.lo
; ===================================================================

; CHECK-LABEL: @func test_vfdot32
; CHECK-DAG: VLDW
; CHECK-DAG: VLDH
; CHECK: VFDOT32 {{v[0-9]+}}, {{v[0-9]+}}, {{v[0-9]+}}
; CHECK: VSTW
define void @test_vfdot32(ptr addrspace(1) %base, i64 %off) {
  %raw1 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %raw2 = call <32 x i32> @llvm.ftm.vldh(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw1 to <32 x float>
  %b = bitcast <32 x i32> %raw2 to <32 x float>
  %c = call <32 x float> @llvm.ftm.vfdot32(<32 x float> %a, <32 x float> %b)
  %res = bitcast <32 x float> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; VFCMUL32: v32f32 complex multiply via target intrinsic
; Hardware: complex mul (a+bi)*(c+di) on packed v2f32
; ===================================================================

; CHECK-LABEL: @func test_vfcmul32
; CHECK-DAG: VLDW
; CHECK-DAG: VLDH
; CHECK: VFCMUL32 {{v[0-9]+}}, {{v[0-9]+}}, {{v[0-9]+}}
; CHECK: VSTW
define void @test_vfcmul32(ptr addrspace(1) %base, i64 %off) {
  %raw1 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %raw2 = call <32 x i32> @llvm.ftm.vldh(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw1 to <32 x float>
  %b = bitcast <32 x i32> %raw2 to <32 x float>
  %c = call <32 x float> @llvm.ftm.vfcmul32(<32 x float> %a, <32 x float> %b)
  %res = bitcast <32 x float> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; VFMULAD via DAGCombine: fadd(fmul(a,b), c) → VFMULAD
; Tests the DAGCombine path (separate from llvm.fma intrinsic path)
; ===================================================================

; CHECK-LABEL: @func test_vfmulad_dagcombine
; CHECK-DAG: VLDW
; CHECK-DAG: VLDH
; CHECK: VFMULAD {{v[0-9]+}}, {{v[0-9]+}}, {{v[0-9]+}}, {{v[0-9]+}}
; CHECK: VSTW
define void @test_vfmulad_dagcombine(ptr addrspace(1) %base, i64 %off) {
  %raw1 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %raw2 = call <32 x i32> @llvm.ftm.vldh(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw1 to <16 x double>
  %c = bitcast <32 x i32> %raw2 to <16 x double>
  ; fadd(fmul(a,a), c) should be fused into VFMULAD
  %mul = fmul <16 x double> %a, %a
  %d = fadd <16 x double> %mul, %c
  %res = bitcast <16 x double> %d to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ==================== Vector FP Rounding Conversion (VFDINT/VFSINT32) ====================

;; --- VFDINT: v16f64 → v16i64 with hardware rounding mode ---

; CHECK-LABEL: @func test_vfdint
; CHECK: VLDW
; CHECK: VFDINT
; CHECK: VSTW
define void @test_vfdint(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %src = bitcast <32 x i32> %raw to <16 x double>
  %r = call <16 x i64> @llvm.ftm.vfdint(<16 x double> %src)
  %out = bitcast <16 x i64> %r to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %out, ptr addrspace(1) %base, i64 %off)
  ret void
}

;; --- VFSINT32: v32f32 → v32i32 with hardware rounding mode ---

; CHECK-LABEL: @func test_vfsint32
; CHECK: VLDW
; CHECK: VFSINT32
; CHECK: VSTW
define void @test_vfsint32(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %src = bitcast <32 x i32> %raw to <32 x float>
  %r = call <32 x i32> @llvm.ftm.vfsint32(<32 x float> %src)
  call void @llvm.ftm.vstw(<32 x i32> %r, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ==================== Vector Exponent/Mantissa Extraction ====================

; CHECK-LABEL: @func test_vflogd
; CHECK: VFLOGD
define void @test_vflogd(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %src = bitcast <32 x i32> %raw to <16 x double>
  %r = call <16 x i64> @llvm.ftm.vflogd(<16 x double> %src)
  %res = bitcast <16 x i64> %r to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vflogs32
; CHECK: VFLOGS32
define void @test_vflogs32(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %src = bitcast <32 x i32> %raw to <32 x float>
  %r = call <32 x i32> @llvm.ftm.vflogs32(<32 x float> %src)
  call void @llvm.ftm.vstw(<32 x i32> %r, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vfmand
; CHECK: VFMAND
define void @test_vfmand(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %src = bitcast <32 x i32> %raw to <16 x double>
  %r = call <16 x i64> @llvm.ftm.vfmand(<16 x double> %src)
  %res = bitcast <16 x i64> %r to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vfmans32
; CHECK: VFMANS32
define void @test_vfmans32(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %src = bitcast <32 x i32> %raw to <32 x float>
  %r = call <32 x i32> @llvm.ftm.vfmans32(<32 x float> %src)
  call void @llvm.ftm.vstw(<32 x i32> %r, ptr addrspace(1) %base, i64 %off)
  ret void
}
