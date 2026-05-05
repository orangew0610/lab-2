; NOTE: Vector integer compare instruction selection tests
; RUN: llc -march=matrix -o - %s | FileCheck %s

;; ===================================================================
;; Vector integer compare instruction selection tests
;;
;; Instructions tested:
;;   VEQ/VLT/VLTU (v16i64) - element-wise compare
;;   VEQ32/VLT32/VLTU32 (v32i32) - element-wise compare
;;   VCMP + SBRVNZ/SBRVZ - compare + conditional branch
;; ===================================================================

target triple = "matrix-unknown-unknown"

; --- Intrinsic declarations ---
declare <32 x i32> @llvm.ftm.vldw(ptr addrspace(1), i64)
declare void @llvm.ftm.vstw(<32 x i32>, ptr addrspace(1), i64)
declare <16 x i64> @llvm.ftm.veq(<16 x i64>, <16 x i64>)
declare <16 x i64> @llvm.ftm.vlt(<16 x i64>, <16 x i64>)
declare <16 x i64> @llvm.ftm.vltu(<16 x i64>, <16 x i64>)
declare <32 x i32> @llvm.ftm.veq32(<32 x i32>, <32 x i32>)
declare <32 x i32> @llvm.ftm.vlt32(<32 x i32>, <32 x i32>)
declare <32 x i32> @llvm.ftm.vltu32(<32 x i32>, <32 x i32>)
declare i64 @llvm.ftm.veq.all(<16 x i64>, <16 x i64>)
declare i64 @llvm.ftm.vlt.all(<16 x i64>, <16 x i64>)
declare i64 @llvm.ftm.vltu.all(<16 x i64>, <16 x i64>)
declare i64 @llvm.ftm.veq32.all(<32 x i32>, <32 x i32>)
declare i64 @llvm.ftm.vlt32.all(<32 x i32>, <32 x i32>)
declare i64 @llvm.ftm.vltu32.all(<32 x i32>, <32 x i32>)

; ==================== Element-wise Compare ====================

; ===================================================================
; VEQ: v16i64 equality compare
; ===================================================================

; CHECK-LABEL: @func test_veq
; CHECK: VEQ
; CHECK: VSTW
define void @test_veq(ptr addrspace(1) %base, i64 %off, ptr addrspace(1) %base2, i64 %off2) {
  %a_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base2, i64 %off2)
  %a = bitcast <32 x i32> %a_raw to <16 x i64>
  %b = bitcast <32 x i32> %b_raw to <16 x i64>
  %cmp = call <16 x i64> @llvm.ftm.veq(<16 x i64> %a, <16 x i64> %b)
  %res = bitcast <16 x i64> %cmp to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; VLT: v16i64 signed less-than compare
; ===================================================================

; CHECK-LABEL: @func test_vlt
; CHECK: VLT
; CHECK: VSTW
define void @test_vlt(ptr addrspace(1) %base, i64 %off, ptr addrspace(1) %base2, i64 %off2) {
  %a_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base2, i64 %off2)
  %a = bitcast <32 x i32> %a_raw to <16 x i64>
  %b = bitcast <32 x i32> %b_raw to <16 x i64>
  %cmp = call <16 x i64> @llvm.ftm.vlt(<16 x i64> %a, <16 x i64> %b)
  %res = bitcast <16 x i64> %cmp to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; VLTU: v16i64 unsigned less-than compare
; ===================================================================

; CHECK-LABEL: @func test_vltu
; CHECK: VLTU
; CHECK: VSTW
define void @test_vltu(ptr addrspace(1) %base, i64 %off, ptr addrspace(1) %base2, i64 %off2) {
  %a_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base2, i64 %off2)
  %a = bitcast <32 x i32> %a_raw to <16 x i64>
  %b = bitcast <32 x i32> %b_raw to <16 x i64>
  %cmp = call <16 x i64> @llvm.ftm.vltu(<16 x i64> %a, <16 x i64> %b)
  %res = bitcast <16 x i64> %cmp to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; VEQ32: v32i32 equality compare
; ===================================================================

; CHECK-LABEL: @func test_veq32
; CHECK: VEQ32
; CHECK: VSTW
define void @test_veq32(ptr addrspace(1) %base, i64 %off, ptr addrspace(1) %base2, i64 %off2) {
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base2, i64 %off2)
  %cmp = call <32 x i32> @llvm.ftm.veq32(<32 x i32> %a, <32 x i32> %b)
  call void @llvm.ftm.vstw(<32 x i32> %cmp, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; VLT32: v32i32 signed less-than compare
; ===================================================================

; CHECK-LABEL: @func test_vlt32
; CHECK: VLT32
; CHECK: VSTW
define void @test_vlt32(ptr addrspace(1) %base, i64 %off, ptr addrspace(1) %base2, i64 %off2) {
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base2, i64 %off2)
  %cmp = call <32 x i32> @llvm.ftm.vlt32(<32 x i32> %a, <32 x i32> %b)
  call void @llvm.ftm.vstw(<32 x i32> %cmp, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; VLTU32: v32i32 unsigned less-than compare
; ===================================================================

; CHECK-LABEL: @func test_vltu32
; CHECK: VLTU32
; CHECK: VSTW
define void @test_vltu32(ptr addrspace(1) %base, i64 %off, ptr addrspace(1) %base2, i64 %off2) {
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base2, i64 %off2)
  %cmp = call <32 x i32> @llvm.ftm.vltu32(<32 x i32> %a, <32 x i32> %b)
  call void @llvm.ftm.vstw(<32 x i32> %cmp, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ==================== Compare + Conditional Branch ====================

; ===================================================================
; VEQ + SBRVZ: v16i64 equality, branch if NE (inverted to SBRVZ)
; ===================================================================

; CHECK-LABEL: @func test_veq_brnz
; CHECK: VEQ
; CHECK: SBRVZ
define void @test_veq_brnz(ptr addrspace(1) %base, i64 %off, ptr addrspace(1) %base2, i64 %off2) {
  %a_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base2, i64 %off2)
  %a = bitcast <32 x i32> %a_raw to <16 x i64>
  %b = bitcast <32 x i32> %b_raw to <16 x i64>
  %cmp = call i64 @llvm.ftm.veq.all(<16 x i64> %a, <16 x i64> %b)
  %nz = icmp ne i64 %cmp, 0
  br i1 %nz, label %then, label %else
then:
  call void @llvm.ftm.vstw(<32 x i32> %a_raw, ptr addrspace(1) %base, i64 %off)
  ret void
else:
  ret void
}

; ===================================================================
; VEQ + SBRVNZ: v16i64 equality, branch if EQ (inverted to SBRVNZ)
; ===================================================================

; CHECK-LABEL: @func test_veq_brz
; CHECK: VEQ
; CHECK: SBRVNZ
define void @test_veq_brz(ptr addrspace(1) %base, i64 %off, ptr addrspace(1) %base2, i64 %off2) {
  %a_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base2, i64 %off2)
  %a = bitcast <32 x i32> %a_raw to <16 x i64>
  %b = bitcast <32 x i32> %b_raw to <16 x i64>
  %cmp = call i64 @llvm.ftm.veq.all(<16 x i64> %a, <16 x i64> %b)
  %z = icmp eq i64 %cmp, 0
  br i1 %z, label %then, label %else
then:
  call void @llvm.ftm.vstw(<32 x i32> %a_raw, ptr addrspace(1) %base, i64 %off)
  ret void
else:
  ret void
}

; ===================================================================
; VLT: v16i64 signed less-than compare + branch
; ===================================================================

; CHECK-LABEL: @func test_vlt_brnz
; CHECK: VLT
; CHECK: SBRVZ
define void @test_vlt_brnz(ptr addrspace(1) %base, i64 %off, ptr addrspace(1) %base2, i64 %off2) {
  %a_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base2, i64 %off2)
  %a = bitcast <32 x i32> %a_raw to <16 x i64>
  %b = bitcast <32 x i32> %b_raw to <16 x i64>
  %cmp = call i64 @llvm.ftm.vlt.all(<16 x i64> %a, <16 x i64> %b)
  %nz = icmp ne i64 %cmp, 0
  br i1 %nz, label %then, label %else
then:
  call void @llvm.ftm.vstw(<32 x i32> %a_raw, ptr addrspace(1) %base, i64 %off)
  ret void
else:
  ret void
}

; ===================================================================
; VLTU: v16i64 unsigned less-than compare + branch
; ===================================================================

; CHECK-LABEL: @func test_vltu_brnz
; CHECK: VLTU
; CHECK: SBRVZ
define void @test_vltu_brnz(ptr addrspace(1) %base, i64 %off, ptr addrspace(1) %base2, i64 %off2) {
  %a_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base2, i64 %off2)
  %a = bitcast <32 x i32> %a_raw to <16 x i64>
  %b = bitcast <32 x i32> %b_raw to <16 x i64>
  %cmp = call i64 @llvm.ftm.vltu.all(<16 x i64> %a, <16 x i64> %b)
  %nz = icmp ne i64 %cmp, 0
  br i1 %nz, label %then, label %else
then:
  call void @llvm.ftm.vstw(<32 x i32> %a_raw, ptr addrspace(1) %base, i64 %off)
  ret void
else:
  ret void
}

; ===================================================================
; VEQ32: v32i32 equality compare + branch
; ===================================================================

; CHECK-LABEL: @func test_veq32_brnz
; CHECK: VEQ32
; CHECK: SBRVZ
define void @test_veq32_brnz(ptr addrspace(1) %base, i64 %off, ptr addrspace(1) %base2, i64 %off2) {
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base2, i64 %off2)
  %cmp = call i64 @llvm.ftm.veq32.all(<32 x i32> %a, <32 x i32> %b)
  %nz = icmp ne i64 %cmp, 0
  br i1 %nz, label %then, label %else
then:
  call void @llvm.ftm.vstw(<32 x i32> %a, ptr addrspace(1) %base, i64 %off)
  ret void
else:
  ret void
}

; ===================================================================
; VLT32: v32i32 signed less-than compare + branch
; ===================================================================

; CHECK-LABEL: @func test_vlt32_brnz
; CHECK: VLT32
; CHECK: SBRVZ
define void @test_vlt32_brnz(ptr addrspace(1) %base, i64 %off, ptr addrspace(1) %base2, i64 %off2) {
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base2, i64 %off2)
  %cmp = call i64 @llvm.ftm.vlt32.all(<32 x i32> %a, <32 x i32> %b)
  %nz = icmp ne i64 %cmp, 0
  br i1 %nz, label %then, label %else
then:
  call void @llvm.ftm.vstw(<32 x i32> %a, ptr addrspace(1) %base, i64 %off)
  ret void
else:
  ret void
}

; ===================================================================
; VLTU32: v32i32 unsigned less-than compare + branch
; ===================================================================

; CHECK-LABEL: @func test_vltu32_brnz
; CHECK: VLTU32
; CHECK: SBRVZ
define void @test_vltu32_brnz(ptr addrspace(1) %base, i64 %off, ptr addrspace(1) %base2, i64 %off2) {
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base2, i64 %off2)
  %cmp = call i64 @llvm.ftm.vltu32.all(<32 x i32> %a, <32 x i32> %b)
  %nz = icmp ne i64 %cmp, 0
  br i1 %nz, label %then, label %else
then:
  call void @llvm.ftm.vstw(<32 x i32> %a, ptr addrspace(1) %base, i64 %off)
  ret void
else:
  ret void
}
