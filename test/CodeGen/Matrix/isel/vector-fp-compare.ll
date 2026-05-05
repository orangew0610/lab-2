; NOTE: Vector floating-point compare instruction selection tests
; RUN: llc -march=matrix -o - %s | FileCheck %s

;; ===================================================================
;; Vector floating-point compare instruction selection tests
;;
;; Instructions tested:
;;   VFCMPED/VFCMPGD/VFCMPLD - v16f64 compare
;;   VFCMPES32/VFCMPGS32/VFCMPLS32 - v32f32 compare
;;   VFMAXD/VFMAXS32 - vector FP maximum
;;   VFCMP + SBRVNZ/SBRVZ - compare + conditional branch
;; ===================================================================

target triple = "matrix-unknown-unknown"

; --- Intrinsic declarations ---
declare <32 x i32> @llvm.ftm.vldw(ptr addrspace(1), i64)
declare void @llvm.ftm.vstw(<32 x i32>, ptr addrspace(1), i64)
declare <32 x i32> @llvm.ftm.vfcmped(<32 x i32>, <32 x i32>)
declare <32 x i32> @llvm.ftm.vfcmpgd(<32 x i32>, <32 x i32>)
declare <32 x i32> @llvm.ftm.vfcmpld(<32 x i32>, <32 x i32>)
declare <32 x i32> @llvm.ftm.vfcmpes32(<32 x i32>, <32 x i32>)
declare <32 x i32> @llvm.ftm.vfcmpgs32(<32 x i32>, <32 x i32>)
declare <32 x i32> @llvm.ftm.vfcmpls32(<32 x i32>, <32 x i32>)
declare <32 x i32> @llvm.ftm.vfmaxd(<32 x i32>, <32 x i32>)
declare <32 x i32> @llvm.ftm.vfmaxs32(<32 x i32>, <32 x i32>)
declare i64 @llvm.ftm.vfcmped.all(<32 x i32>, <32 x i32>)
declare i64 @llvm.ftm.vfcmpgd.all(<32 x i32>, <32 x i32>)
declare i64 @llvm.ftm.vfcmpld.all(<32 x i32>, <32 x i32>)
declare i64 @llvm.ftm.vfcmpes32.all(<32 x i32>, <32 x i32>)
declare i64 @llvm.ftm.vfcmpgs32.all(<32 x i32>, <32 x i32>)
declare i64 @llvm.ftm.vfcmpls32.all(<32 x i32>, <32 x i32>)

; ==================== Element-wise FP Compare + Maximum ====================

; ===================================================================
; VFCMPED: v16f64 equality compare
; ===================================================================

; CHECK-LABEL: @func test_vfcmped
; CHECK: VFCMPED
; CHECK: VSTW
define void @test_vfcmped(ptr addrspace(1) %base, i64 %off, ptr addrspace(1) %base2, i64 %off2) {
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base2, i64 %off2)
  %cmp = call <32 x i32> @llvm.ftm.vfcmped(<32 x i32> %a, <32 x i32> %b)
  call void @llvm.ftm.vstw(<32 x i32> %cmp, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; VFCMPGD: v16f64 greater-than compare
; ===================================================================

; CHECK-LABEL: @func test_vfcmpgd
; CHECK: VFCMPGD
; CHECK: VSTW
define void @test_vfcmpgd(ptr addrspace(1) %base, i64 %off, ptr addrspace(1) %base2, i64 %off2) {
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base2, i64 %off2)
  %cmp = call <32 x i32> @llvm.ftm.vfcmpgd(<32 x i32> %a, <32 x i32> %b)
  call void @llvm.ftm.vstw(<32 x i32> %cmp, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; VFCMPLD: v16f64 less-than compare
; ===================================================================

; CHECK-LABEL: @func test_vfcmpld
; CHECK: VFCMPLD
; CHECK: VSTW
define void @test_vfcmpld(ptr addrspace(1) %base, i64 %off, ptr addrspace(1) %base2, i64 %off2) {
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base2, i64 %off2)
  %cmp = call <32 x i32> @llvm.ftm.vfcmpld(<32 x i32> %a, <32 x i32> %b)
  call void @llvm.ftm.vstw(<32 x i32> %cmp, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; VFCMPES32: v32f32 equality compare
; ===================================================================

; CHECK-LABEL: @func test_vfcmpes32
; CHECK: VFCMPES32
; CHECK: VSTW
define void @test_vfcmpes32(ptr addrspace(1) %base, i64 %off, ptr addrspace(1) %base2, i64 %off2) {
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base2, i64 %off2)
  %cmp = call <32 x i32> @llvm.ftm.vfcmpes32(<32 x i32> %a, <32 x i32> %b)
  call void @llvm.ftm.vstw(<32 x i32> %cmp, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; VFCMPGS32: v32f32 greater-than compare
; ===================================================================

; CHECK-LABEL: @func test_vfcmpgs32
; CHECK: VFCMPGS32
; CHECK: VSTW
define void @test_vfcmpgs32(ptr addrspace(1) %base, i64 %off, ptr addrspace(1) %base2, i64 %off2) {
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base2, i64 %off2)
  %cmp = call <32 x i32> @llvm.ftm.vfcmpgs32(<32 x i32> %a, <32 x i32> %b)
  call void @llvm.ftm.vstw(<32 x i32> %cmp, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; VFCMPLS32: v32f32 less-than compare
; ===================================================================

; CHECK-LABEL: @func test_vfcmpls32
; CHECK: VFCMPLS32
; CHECK: VSTW
define void @test_vfcmpls32(ptr addrspace(1) %base, i64 %off, ptr addrspace(1) %base2, i64 %off2) {
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base2, i64 %off2)
  %cmp = call <32 x i32> @llvm.ftm.vfcmpls32(<32 x i32> %a, <32 x i32> %b)
  call void @llvm.ftm.vstw(<32 x i32> %cmp, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; VFMAXD: v16f64 element-wise maximum (via intrinsic)
; ===================================================================

; CHECK-LABEL: @func test_vfmaxd
; CHECK: VFMAXD
; CHECK: VSTW
define void @test_vfmaxd(ptr addrspace(1) %base, i64 %off, ptr addrspace(1) %base2, i64 %off2) {
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base2, i64 %off2)
  %max = call <32 x i32> @llvm.ftm.vfmaxd(<32 x i32> %a, <32 x i32> %b)
  call void @llvm.ftm.vstw(<32 x i32> %max, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; VFMAXS32: v32f32 element-wise maximum (via intrinsic)
; ===================================================================

; CHECK-LABEL: @func test_vfmaxs32
; CHECK: VFMAXS32
; CHECK: VSTW
define void @test_vfmaxs32(ptr addrspace(1) %base, i64 %off, ptr addrspace(1) %base2, i64 %off2) {
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base2, i64 %off2)
  %max = call <32 x i32> @llvm.ftm.vfmaxs32(<32 x i32> %a, <32 x i32> %b)
  call void @llvm.ftm.vstw(<32 x i32> %max, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ==================== FP Compare + Conditional Branch ====================

; ===================================================================
; VFCMPED + SBRVZ: v16f64 equality, branch if NE (inverted to SBRVZ)
; ===================================================================

; CHECK-LABEL: @func test_vfcmped_brnz
; CHECK: VFCMPED
; CHECK: SBRVZ
define void @test_vfcmped_brnz(ptr addrspace(1) %base, i64 %off, ptr addrspace(1) %base2, i64 %off2) {
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base2, i64 %off2)
  %cmp = call i64 @llvm.ftm.vfcmped.all(<32 x i32> %a, <32 x i32> %b)
  %nz = icmp ne i64 %cmp, 0
  br i1 %nz, label %then, label %else
then:
  call void @llvm.ftm.vstw(<32 x i32> %a, ptr addrspace(1) %base, i64 %off)
  ret void
else:
  ret void
}

; ===================================================================
; VFCMPED + SBRVNZ: v16f64 equality, branch if EQ (inverted to SBRVNZ)
; ===================================================================

; CHECK-LABEL: @func test_vfcmped_brz
; CHECK: VFCMPED
; CHECK: SBRVNZ
define void @test_vfcmped_brz(ptr addrspace(1) %base, i64 %off, ptr addrspace(1) %base2, i64 %off2) {
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base2, i64 %off2)
  %cmp = call i64 @llvm.ftm.vfcmped.all(<32 x i32> %a, <32 x i32> %b)
  %z = icmp eq i64 %cmp, 0
  br i1 %z, label %then, label %else
then:
  call void @llvm.ftm.vstw(<32 x i32> %a, ptr addrspace(1) %base, i64 %off)
  ret void
else:
  ret void
}

; ===================================================================
; VFCMPGD: v16f64 greater-than compare + branch
; ===================================================================

; CHECK-LABEL: @func test_vfcmpgd_brnz
; CHECK: VFCMPGD
; CHECK: SBRVZ
define void @test_vfcmpgd_brnz(ptr addrspace(1) %base, i64 %off, ptr addrspace(1) %base2, i64 %off2) {
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base2, i64 %off2)
  %cmp = call i64 @llvm.ftm.vfcmpgd.all(<32 x i32> %a, <32 x i32> %b)
  %nz = icmp ne i64 %cmp, 0
  br i1 %nz, label %then, label %else
then:
  call void @llvm.ftm.vstw(<32 x i32> %a, ptr addrspace(1) %base, i64 %off)
  ret void
else:
  ret void
}

; ===================================================================
; VFCMPLD: v16f64 less-than compare + branch
; ===================================================================

; CHECK-LABEL: @func test_vfcmpld_brnz
; CHECK: VFCMPLD
; CHECK: SBRVZ
define void @test_vfcmpld_brnz(ptr addrspace(1) %base, i64 %off, ptr addrspace(1) %base2, i64 %off2) {
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base2, i64 %off2)
  %cmp = call i64 @llvm.ftm.vfcmpld.all(<32 x i32> %a, <32 x i32> %b)
  %nz = icmp ne i64 %cmp, 0
  br i1 %nz, label %then, label %else
then:
  call void @llvm.ftm.vstw(<32 x i32> %a, ptr addrspace(1) %base, i64 %off)
  ret void
else:
  ret void
}

; ===================================================================
; VFCMPES32: v32f32 equality compare + branch
; ===================================================================

; CHECK-LABEL: @func test_vfcmpes32_brnz
; CHECK: VFCMPES32
; CHECK: SBRVZ
define void @test_vfcmpes32_brnz(ptr addrspace(1) %base, i64 %off, ptr addrspace(1) %base2, i64 %off2) {
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base2, i64 %off2)
  %cmp = call i64 @llvm.ftm.vfcmpes32.all(<32 x i32> %a, <32 x i32> %b)
  %nz = icmp ne i64 %cmp, 0
  br i1 %nz, label %then, label %else
then:
  call void @llvm.ftm.vstw(<32 x i32> %a, ptr addrspace(1) %base, i64 %off)
  ret void
else:
  ret void
}

; ===================================================================
; VFCMPGS32: v32f32 greater-than compare + branch
; ===================================================================

; CHECK-LABEL: @func test_vfcmpgs32_brnz
; CHECK: VFCMPGS32
; CHECK: SBRVZ
define void @test_vfcmpgs32_brnz(ptr addrspace(1) %base, i64 %off, ptr addrspace(1) %base2, i64 %off2) {
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base2, i64 %off2)
  %cmp = call i64 @llvm.ftm.vfcmpgs32.all(<32 x i32> %a, <32 x i32> %b)
  %nz = icmp ne i64 %cmp, 0
  br i1 %nz, label %then, label %else
then:
  call void @llvm.ftm.vstw(<32 x i32> %a, ptr addrspace(1) %base, i64 %off)
  ret void
else:
  ret void
}

; ===================================================================
; VFCMPLS32: v32f32 less-than compare + branch
; ===================================================================

; CHECK-LABEL: @func test_vfcmpls32_brnz
; CHECK: VFCMPLS32
; CHECK: SBRVZ
define void @test_vfcmpls32_brnz(ptr addrspace(1) %base, i64 %off, ptr addrspace(1) %base2, i64 %off2) {
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base2, i64 %off2)
  %cmp = call i64 @llvm.ftm.vfcmpls32.all(<32 x i32> %a, <32 x i32> %b)
  %nz = icmp ne i64 %cmp, 0
  br i1 %nz, label %then, label %else
then:
  call void @llvm.ftm.vstw(<32 x i32> %a, ptr addrspace(1) %base, i64 %off)
  ret void
else:
  ret void
}
