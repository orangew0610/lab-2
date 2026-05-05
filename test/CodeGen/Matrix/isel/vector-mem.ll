; NOTE: Vector memory and data move instruction selection tests
; RUN: llc -march=matrix -o - %s | FileCheck %s

;; ===================================================================
;; Vector memory and data move instruction selection tests
;;
;; Instructions tested:
;;   VLDH/VLDHU/VLDW - single VR loads
;;   VLDDW/VLDDWM2/VLDDW0M2/VLDDW1M2/VLDDW0M4/VLDDW1M4 - VR pair loads
;;   VSTH/VSTW - single VR stores
;;   VSTDW/VSTDWM16/VSTDW0M16/VSTDW1M16/VSTDW0M32/VSTDW1M32 - VR pair stores
;;   VMOV - VR register copy
;;   VMOVI - VR immediate broadcast / constant splat
;; ===================================================================

target triple = "matrix-unknown-unknown"

; --- Intrinsic declarations ---

; Single VR loads (v32i32)
declare <32 x i32> @llvm.ftm.vldh(ptr addrspace(1), i64)
declare <32 x i32> @llvm.ftm.vldhu(ptr addrspace(1), i64)
declare <32 x i32> @llvm.ftm.vldw(ptr addrspace(1), i64)

; VR pair loads (v32i64)
declare <32 x i64> @llvm.ftm.vlddw(ptr addrspace(1), i64)
declare <32 x i64> @llvm.ftm.vlddwm2(ptr addrspace(1), i64)
declare <32 x i64> @llvm.ftm.vlddw0m2(ptr addrspace(1), i64)
declare <32 x i64> @llvm.ftm.vlddw1m2(ptr addrspace(1), i64)
declare <32 x i64> @llvm.ftm.vlddw0m4(ptr addrspace(1), i64)
declare <32 x i64> @llvm.ftm.vlddw1m4(ptr addrspace(1), i64)

; Single VR stores (v32i32)
declare void @llvm.ftm.vsth(<32 x i32>, ptr addrspace(1), i64)
declare void @llvm.ftm.vstw(<32 x i32>, ptr addrspace(1), i64)

; VR pair stores (v32i64)
declare void @llvm.ftm.vstdw(<32 x i64>, ptr addrspace(1), i64)
declare void @llvm.ftm.vstdwm16(<32 x i64>, ptr addrspace(1), i64)
declare void @llvm.ftm.vstdw0m16(<32 x i64>, ptr addrspace(1), i64)
declare void @llvm.ftm.vstdw1m16(<32 x i64>, ptr addrspace(1), i64)
declare void @llvm.ftm.vstdw0m32(<32 x i64>, ptr addrspace(1), i64)
declare void @llvm.ftm.vstdw1m32(<32 x i64>, ptr addrspace(1), i64)

; ==================== Vector Memory Access ====================

; ===================================================================
; Single VR Load Tests (load then store to consume value)
; ===================================================================

define void @test_vldh(ptr addrspace(1) %base, i64 %off) {
; CHECK-LABEL: @func test_vldh
; CHECK: VLDH *+{{.*}}[{{.*}}], {{.*}}
; CHECK: VSTH
; CHECK: @ret
  %v = call <32 x i32> @llvm.ftm.vldh(ptr addrspace(1) %base, i64 %off)
  call void @llvm.ftm.vsth(<32 x i32> %v, ptr addrspace(1) %base, i64 %off)
  ret void
}

define void @test_vldhu(ptr addrspace(1) %base, i64 %off) {
; CHECK-LABEL: @func test_vldhu
; CHECK: VLDHU *+{{.*}}[{{.*}}], {{.*}}
; CHECK: VSTH
; CHECK: @ret
  %v = call <32 x i32> @llvm.ftm.vldhu(ptr addrspace(1) %base, i64 %off)
  call void @llvm.ftm.vsth(<32 x i32> %v, ptr addrspace(1) %base, i64 %off)
  ret void
}

define void @test_vldw(ptr addrspace(1) %base, i64 %off) {
; CHECK-LABEL: @func test_vldw
; CHECK: VLDW *+{{.*}}[{{.*}}], {{.*}}
; CHECK: VSTW
; CHECK: @ret
  %v = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  call void @llvm.ftm.vstw(<32 x i32> %v, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; VR Pair Load Tests
; ===================================================================

define void @test_vlddw(ptr addrspace(1) %base, i64 %off) {
; CHECK-LABEL: @func test_vlddw
; CHECK: VLDDW *+{{.*}}[{{.*}}], {{.*}}
; CHECK: VSTDW
; CHECK: @ret
  %v = call <32 x i64> @llvm.ftm.vlddw(ptr addrspace(1) %base, i64 %off)
  call void @llvm.ftm.vstdw(<32 x i64> %v, ptr addrspace(1) %base, i64 %off)
  ret void
}

define void @test_vlddwm2(ptr addrspace(1) %base, i64 %off) {
; CHECK-LABEL: @func test_vlddwm2
; CHECK: VLDDWM2 *+{{.*}}[{{.*}}], {{.*}}
; CHECK: VSTDW
; CHECK: @ret
  %v = call <32 x i64> @llvm.ftm.vlddwm2(ptr addrspace(1) %base, i64 %off)
  call void @llvm.ftm.vstdw(<32 x i64> %v, ptr addrspace(1) %base, i64 %off)
  ret void
}

define void @test_vlddw0m2(ptr addrspace(1) %base, i64 %off) {
; CHECK-LABEL: @func test_vlddw0m2
; CHECK: VLDDW0M2 *+{{.*}}[{{.*}}], {{.*}}
; CHECK: VSTDW
; CHECK: @ret
  %v = call <32 x i64> @llvm.ftm.vlddw0m2(ptr addrspace(1) %base, i64 %off)
  call void @llvm.ftm.vstdw(<32 x i64> %v, ptr addrspace(1) %base, i64 %off)
  ret void
}

define void @test_vlddw1m2(ptr addrspace(1) %base, i64 %off) {
; CHECK-LABEL: @func test_vlddw1m2
; CHECK: VLDDW1M2 *+{{.*}}[{{.*}}], {{.*}}
; CHECK: VSTDW
; CHECK: @ret
  %v = call <32 x i64> @llvm.ftm.vlddw1m2(ptr addrspace(1) %base, i64 %off)
  call void @llvm.ftm.vstdw(<32 x i64> %v, ptr addrspace(1) %base, i64 %off)
  ret void
}

define void @test_vlddw0m4(ptr addrspace(1) %base, i64 %off) {
; CHECK-LABEL: @func test_vlddw0m4
; CHECK: VLDDW0M4 *+{{.*}}[{{.*}}], {{.*}}
; CHECK: VSTDW
; CHECK: @ret
  %v = call <32 x i64> @llvm.ftm.vlddw0m4(ptr addrspace(1) %base, i64 %off)
  call void @llvm.ftm.vstdw(<32 x i64> %v, ptr addrspace(1) %base, i64 %off)
  ret void
}

define void @test_vlddw1m4(ptr addrspace(1) %base, i64 %off) {
; CHECK-LABEL: @func test_vlddw1m4
; CHECK: VLDDW1M4 *+{{.*}}[{{.*}}], {{.*}}
; CHECK: VSTDW
; CHECK: @ret
  %v = call <32 x i64> @llvm.ftm.vlddw1m4(ptr addrspace(1) %base, i64 %off)
  call void @llvm.ftm.vstdw(<32 x i64> %v, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; Single VR Store Tests (load to produce value, then store)
; ===================================================================

define void @test_vsth(ptr addrspace(1) %base, i64 %off) {
; CHECK-LABEL: @func test_vsth
; CHECK: VLDW
; CHECK: VSTH {{.*}}, *+{{.*}}[{{.*}}]
; CHECK: @ret
  %v = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  call void @llvm.ftm.vsth(<32 x i32> %v, ptr addrspace(1) %base, i64 %off)
  ret void
}

define void @test_vstw(ptr addrspace(1) %base, i64 %off) {
; CHECK-LABEL: @func test_vstw
; CHECK: VLDW
; CHECK: VSTW {{.*}}, *+{{.*}}[{{.*}}]
; CHECK: @ret
  %v = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  call void @llvm.ftm.vstw(<32 x i32> %v, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; VR Pair Store Tests
; ===================================================================

define void @test_vstdw(ptr addrspace(1) %base, i64 %off) {
; CHECK-LABEL: @func test_vstdw
; CHECK: VLDDW
; CHECK: VSTDW {{.*}}, *+{{.*}}[{{.*}}]
; CHECK: @ret
  %v = call <32 x i64> @llvm.ftm.vlddw(ptr addrspace(1) %base, i64 %off)
  call void @llvm.ftm.vstdw(<32 x i64> %v, ptr addrspace(1) %base, i64 %off)
  ret void
}

define void @test_vstdwm16(ptr addrspace(1) %base, i64 %off) {
; CHECK-LABEL: @func test_vstdwm16
; CHECK: VLDDW
; CHECK: VSTDWM16 {{.*}}, *+{{.*}}[{{.*}}]
; CHECK: @ret
  %v = call <32 x i64> @llvm.ftm.vlddw(ptr addrspace(1) %base, i64 %off)
  call void @llvm.ftm.vstdwm16(<32 x i64> %v, ptr addrspace(1) %base, i64 %off)
  ret void
}

define void @test_vstdw0m16(ptr addrspace(1) %base, i64 %off) {
; CHECK-LABEL: @func test_vstdw0m16
; CHECK: VLDDW
; CHECK: VSTDW0M16 {{.*}}, *+{{.*}}[{{.*}}]
; CHECK: @ret
  %v = call <32 x i64> @llvm.ftm.vlddw(ptr addrspace(1) %base, i64 %off)
  call void @llvm.ftm.vstdw0m16(<32 x i64> %v, ptr addrspace(1) %base, i64 %off)
  ret void
}

define void @test_vstdw1m16(ptr addrspace(1) %base, i64 %off) {
; CHECK-LABEL: @func test_vstdw1m16
; CHECK: VLDDW
; CHECK: VSTDW1M16 {{.*}}, *+{{.*}}[{{.*}}]
; CHECK: @ret
  %v = call <32 x i64> @llvm.ftm.vlddw(ptr addrspace(1) %base, i64 %off)
  call void @llvm.ftm.vstdw1m16(<32 x i64> %v, ptr addrspace(1) %base, i64 %off)
  ret void
}

define void @test_vstdw0m32(ptr addrspace(1) %base, i64 %off) {
; CHECK-LABEL: @func test_vstdw0m32
; CHECK: VLDDW
; CHECK: VSTDW0M32 {{.*}}, *+{{.*}}[{{.*}}]
; CHECK: @ret
  %v = call <32 x i64> @llvm.ftm.vlddw(ptr addrspace(1) %base, i64 %off)
  call void @llvm.ftm.vstdw0m32(<32 x i64> %v, ptr addrspace(1) %base, i64 %off)
  ret void
}

define void @test_vstdw1m32(ptr addrspace(1) %base, i64 %off) {
; CHECK-LABEL: @func test_vstdw1m32
; CHECK: VLDDW
; CHECK: VSTDW1M32 {{.*}}, *+{{.*}}[{{.*}}]
; CHECK: @ret
  %v = call <32 x i64> @llvm.ftm.vlddw(ptr addrspace(1) %base, i64 %off)
  call void @llvm.ftm.vstdw1m32(<32 x i64> %v, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ==================== Vector Data Move (VMOV/VMOVI) ====================

; ===================================================================
; PHI node merging two vector values. With optimization enabled,
; PHI elimination uses VMOV (register copy) instead of spill/reload.
; The optimizer may reorder loads; VLDH and VLDW both appear.
; ===================================================================

; CHECK-LABEL: @func test_vmov_phi
; CHECK-DAG: VLDW
; CHECK-DAG: VLDH
; CHECK: SEQ
; CHECK: SBR
; CHECK: VMOV
; CHECK: VSTW
define void @test_vmov_phi(ptr addrspace(1) %base, i64 %off, i64 %cond) {
entry:
  %a = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %b = call <32 x i32> @llvm.ftm.vldh(ptr addrspace(1) %base, i64 %off)
  %cmp = icmp eq i64 %cond, 0
  br i1 %cmp, label %then, label %else

then:
  br label %merge

else:
  br label %merge

merge:
  %val = phi <32 x i32> [ %a, %then ], [ %b, %else ]
  call void @llvm.ftm.vstw(<32 x i32> %val, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; Vector SELECT: conditional vector select via SELECT_CC pseudo
; Tests the Custom lowering path: SELECT → MatrixISD::SELECT_CC
; → Select_VPR_Using_CC_GPR → triangle control flow with VMOVI.
; With optimization, the false value is placed first, branch skips
; to the true block, and VMOV is eliminated.
; ===================================================================

; CHECK-LABEL: @func test_vselect
; CHECK: VMOVI
; CHECK: SEQ
; CHECK: SBR
; CHECK: VMOVI
define void @test_vselect(i64 %cond) {
  %cmp = icmp eq i64 %cond, 0
  %sel = select i1 %cmp, <16 x double> splat (double 2.5), <16 x double> splat (double 1.5)
  %cast = bitcast <16 x double> %sel to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %cast, ptr addrspace(1) null, i64 0)
  ret void
}

; ===================================================================
; Test: f64 splat constant → VMOVI
; double 1.5 = 0x3FF8000000000000
; ===================================================================

; CHECK-LABEL: @func test_vmovi_f64_splat
; CHECK: VMOVI 4609434218613702656, v0
; CHECK: VSTW
define void @test_vmovi_f64_splat(ptr addrspace(1) %base, i64 %off) {
  %splat_ins = insertelement <16 x double> undef, double 1.5, i32 0
  %splat = shufflevector <16 x double> %splat_ins, <16 x double> undef, <16 x i32> zeroinitializer
  %cast = bitcast <16 x double> %splat to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %cast, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; Test: zero vector → VMOVI 0
; ===================================================================

; CHECK-LABEL: @func test_vmovi_zero
; CHECK: VMOVI 0, v0
; CHECK: VSTW
define void @test_vmovi_zero(ptr addrspace(1) %base, i64 %off) {
  %splat_ins = insertelement <16 x double> undef, double 0.0, i32 0
  %splat = shufflevector <16 x double> %splat_ins, <16 x double> undef, <16 x i32> zeroinitializer
  %cast = bitcast <16 x double> %splat to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %cast, ptr addrspace(1) %base, i64 %off)
  ret void
}
