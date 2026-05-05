; NOTE: Vector integer ALU instruction selection tests
; RUN: llc -march=matrix -o - %s | FileCheck %s

;; ===================================================================
;; Vector integer ALU instruction selection tests
;;
;; Instructions tested:
;;   VADD/VADD32/VSUB/VSUB32 - vector add/sub
;;   VABS/VABS32/VNEG - vector unary
;;   VMAX/VMAX32/VMIN/VMIN32 - vector signed min/max
;;   VMAXU/VMAXU32/VMINU/VMINU32 - vector unsigned min/max
;;   VAND/VOR/VXOR/VNOT - vector bitwise logic
;;   VLZD/VLZD32 - vector leading zero count
;;   VSUBC/VSUBC32/SSUBC/SSUBC32 - conditional subtract-shift
;;   VSAT/VSAT32 - vector saturation
;; ===================================================================

target triple = "matrix-unknown-unknown"

; --- Intrinsic declarations ---
declare <32 x i32> @llvm.ftm.vldw(ptr addrspace(1), i64)
declare void @llvm.ftm.vstw(<32 x i32>, ptr addrspace(1), i64)
declare <16 x i64> @llvm.abs.v16i64(<16 x i64>, i1)
declare <32 x i32> @llvm.abs.v32i32(<32 x i32>, i1)
declare <16 x i64> @llvm.smax.v16i64(<16 x i64>, <16 x i64>)
declare <32 x i32> @llvm.smax.v32i32(<32 x i32>, <32 x i32>)
declare <16 x i64> @llvm.smin.v16i64(<16 x i64>, <16 x i64>)
declare <32 x i32> @llvm.smin.v32i32(<32 x i32>, <32 x i32>)
declare <16 x i64> @llvm.umax.v16i64(<16 x i64>, <16 x i64>)
declare <32 x i32> @llvm.umax.v32i32(<32 x i32>, <32 x i32>)
declare <16 x i64> @llvm.umin.v16i64(<16 x i64>, <16 x i64>)
declare <32 x i32> @llvm.umin.v32i32(<32 x i32>, <32 x i32>)
declare <16 x i64> @llvm.ctlz.v16i64(<16 x i64>, i1)
declare <32 x i32> @llvm.ctlz.v32i32(<32 x i32>, i1)
declare <16 x i64> @llvm.ftm.vsubc(<16 x i64>, <16 x i64>)
declare i64 @llvm.ftm.ssubc(i64, i64)
declare <32 x i32> @llvm.ftm.vsubc32(<32 x i32>, <32 x i32>)
declare <2 x i32> @llvm.ftm.ssubc32(<2 x i32>, <2 x i32>)
declare <16 x i64> @llvm.ftm.vsat(<16 x i64>)
declare <32 x i32> @llvm.ftm.vsat32(<32 x i32>)

; ==================== Vector ALU (from valu.ll) ====================

; ===================================================================
; Group A: Arithmetic
; ===================================================================

; CHECK-LABEL: @func test_vadd
; CHECK: VADD
define void @test_vadd(ptr addrspace(1) %base, i64 %off, i64 %off2) {
  %r1 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %r2 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off2)
  %a = bitcast <32 x i32> %r1 to <16 x i64>
  %b = bitcast <32 x i32> %r2 to <16 x i64>
  %c = add <16 x i64> %a, %b
  %res = bitcast <16 x i64> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vadd32
; CHECK: VADD32
define void @test_vadd32(ptr addrspace(1) %base, i64 %off, i64 %off2) {
  %r1 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %r2 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off2)
  %c = add <32 x i32> %r1, %r2
  call void @llvm.ftm.vstw(<32 x i32> %c, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vsub
; CHECK: VSUB
define void @test_vsub(ptr addrspace(1) %base, i64 %off, i64 %off2) {
  %r1 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %r2 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off2)
  %a = bitcast <32 x i32> %r1 to <16 x i64>
  %b = bitcast <32 x i32> %r2 to <16 x i64>
  %c = sub <16 x i64> %a, %b
  %res = bitcast <16 x i64> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vsub32
; CHECK: VSUB32
define void @test_vsub32(ptr addrspace(1) %base, i64 %off, i64 %off2) {
  %r1 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %r2 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off2)
  %c = sub <32 x i32> %r1, %r2
  call void @llvm.ftm.vstw(<32 x i32> %c, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; Group B: Unary (Abs, Neg)
; ===================================================================

; CHECK-LABEL: @func test_vabs
; CHECK: VABS
define void @test_vabs(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <16 x i64>
  %c = call <16 x i64> @llvm.abs.v16i64(<16 x i64> %a, i1 false)
  %res = bitcast <16 x i64> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vabs32
; CHECK: VABS32
define void @test_vabs32(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %c = call <32 x i32> @llvm.abs.v32i32(<32 x i32> %raw, i1 false)
  call void @llvm.ftm.vstw(<32 x i32> %c, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vneg
; CHECK: VNEG
define void @test_vneg(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <16 x i64>
  %c = sub <16 x i64> zeroinitializer, %a
  %res = bitcast <16 x i64> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; Group C: Min/Max
; ===================================================================

; CHECK-LABEL: @func test_vmax
; CHECK: VMAX
define void @test_vmax(ptr addrspace(1) %base, i64 %off, i64 %off2) {
  %r1 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %r2 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off2)
  %a = bitcast <32 x i32> %r1 to <16 x i64>
  %b = bitcast <32 x i32> %r2 to <16 x i64>
  %c = call <16 x i64> @llvm.smax.v16i64(<16 x i64> %a, <16 x i64> %b)
  %res = bitcast <16 x i64> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vmax32
; CHECK: VMAX32
define void @test_vmax32(ptr addrspace(1) %base, i64 %off, i64 %off2) {
  %r1 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %r2 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off2)
  %c = call <32 x i32> @llvm.smax.v32i32(<32 x i32> %r1, <32 x i32> %r2)
  call void @llvm.ftm.vstw(<32 x i32> %c, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vmin
; CHECK: VMIN
define void @test_vmin(ptr addrspace(1) %base, i64 %off, i64 %off2) {
  %r1 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %r2 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off2)
  %a = bitcast <32 x i32> %r1 to <16 x i64>
  %b = bitcast <32 x i32> %r2 to <16 x i64>
  %c = call <16 x i64> @llvm.smin.v16i64(<16 x i64> %a, <16 x i64> %b)
  %res = bitcast <16 x i64> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vmin32
; CHECK: VMIN32
define void @test_vmin32(ptr addrspace(1) %base, i64 %off, i64 %off2) {
  %r1 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %r2 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off2)
  %c = call <32 x i32> @llvm.smin.v32i32(<32 x i32> %r1, <32 x i32> %r2)
  call void @llvm.ftm.vstw(<32 x i32> %c, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vmaxu
; CHECK: VMAXU
define void @test_vmaxu(ptr addrspace(1) %base, i64 %off, i64 %off2) {
  %r1 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %r2 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off2)
  %a = bitcast <32 x i32> %r1 to <16 x i64>
  %b = bitcast <32 x i32> %r2 to <16 x i64>
  %c = call <16 x i64> @llvm.umax.v16i64(<16 x i64> %a, <16 x i64> %b)
  %res = bitcast <16 x i64> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vmaxu32
; CHECK: VMAXU32
define void @test_vmaxu32(ptr addrspace(1) %base, i64 %off, i64 %off2) {
  %r1 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %r2 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off2)
  %c = call <32 x i32> @llvm.umax.v32i32(<32 x i32> %r1, <32 x i32> %r2)
  call void @llvm.ftm.vstw(<32 x i32> %c, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vminu
; CHECK: VMINU
define void @test_vminu(ptr addrspace(1) %base, i64 %off, i64 %off2) {
  %r1 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %r2 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off2)
  %a = bitcast <32 x i32> %r1 to <16 x i64>
  %b = bitcast <32 x i32> %r2 to <16 x i64>
  %c = call <16 x i64> @llvm.umin.v16i64(<16 x i64> %a, <16 x i64> %b)
  %res = bitcast <16 x i64> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vminu32
; CHECK: VMINU32
define void @test_vminu32(ptr addrspace(1) %base, i64 %off, i64 %off2) {
  %r1 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %r2 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off2)
  %c = call <32 x i32> @llvm.umin.v32i32(<32 x i32> %r1, <32 x i32> %r2)
  call void @llvm.ftm.vstw(<32 x i32> %c, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; Group D: Bitwise Logic
; ===================================================================

; CHECK-LABEL: @func test_vand
; CHECK: VAND
define void @test_vand(ptr addrspace(1) %base, i64 %off, i64 %off2) {
  %r1 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %r2 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off2)
  %a = bitcast <32 x i32> %r1 to <16 x i64>
  %b = bitcast <32 x i32> %r2 to <16 x i64>
  %c = and <16 x i64> %a, %b
  %res = bitcast <16 x i64> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vor
; CHECK: VOR
define void @test_vor(ptr addrspace(1) %base, i64 %off, i64 %off2) {
  %r1 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %r2 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off2)
  %a = bitcast <32 x i32> %r1 to <16 x i64>
  %b = bitcast <32 x i32> %r2 to <16 x i64>
  %c = or <16 x i64> %a, %b
  %res = bitcast <16 x i64> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vxor
; CHECK: VXOR
define void @test_vxor(ptr addrspace(1) %base, i64 %off, i64 %off2) {
  %r1 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %r2 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off2)
  %a = bitcast <32 x i32> %r1 to <16 x i64>
  %b = bitcast <32 x i32> %r2 to <16 x i64>
  %c = xor <16 x i64> %a, %b
  %res = bitcast <16 x i64> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vnot
; CHECK: VNOT
define void @test_vnot(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <16 x i64>
  %c = xor <16 x i64> %a, splat (i64 -1)
  %res = bitcast <16 x i64> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; --- v32i32 bitwise (reuse v16i64 instructions via Pat<>) ---

; CHECK-LABEL: @func test_vand32
; CHECK: VAND
define void @test_vand32(ptr addrspace(1) %base, i64 %off, i64 %off2) {
  %r1 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %r2 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off2)
  %c = and <32 x i32> %r1, %r2
  call void @llvm.ftm.vstw(<32 x i32> %c, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vor32
; CHECK: VOR
define void @test_vor32(ptr addrspace(1) %base, i64 %off, i64 %off2) {
  %r1 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %r2 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off2)
  %c = or <32 x i32> %r1, %r2
  call void @llvm.ftm.vstw(<32 x i32> %c, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vxor32
; CHECK: VXOR
define void @test_vxor32(ptr addrspace(1) %base, i64 %off, i64 %off2) {
  %r1 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %r2 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off2)
  %c = xor <32 x i32> %r1, %r2
  call void @llvm.ftm.vstw(<32 x i32> %c, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vnot32
; CHECK: VNOT
define void @test_vnot32(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %c = xor <32 x i32> %raw, splat (i32 -1)
  call void @llvm.ftm.vstw(<32 x i32> %c, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; Group E: Leading Zero Count
; ===================================================================

; CHECK-LABEL: @func test_vlzd
; CHECK: VLZD
define void @test_vlzd(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <16 x i64>
  %c = call <16 x i64> @llvm.ctlz.v16i64(<16 x i64> %a, i1 false)
  %res = bitcast <16 x i64> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vlzd32
; CHECK: VLZD32
define void @test_vlzd32(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %c = call <32 x i32> @llvm.ctlz.v32i32(<32 x i32> %raw, i1 false)
  call void @llvm.ftm.vstw(<32 x i32> %c, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; Group G: Conditional Subtract-Shift (intrinsics)
; ===================================================================

; CHECK-LABEL: @func test_vsubc
; CHECK: VSUBC
define void @test_vsubc(ptr addrspace(1) %base, i64 %off, i64 %off2) {
  %r1 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %r2 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off2)
  %a = bitcast <32 x i32> %r1 to <16 x i64>
  %b = bitcast <32 x i32> %r2 to <16 x i64>
  %c = call <16 x i64> @llvm.ftm.vsubc(<16 x i64> %a, <16 x i64> %b)
  %res = bitcast <16 x i64> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_ssubc
; CHECK: SSUBC
define i64 @test_ssubc(i64 %a, i64 %b) {
  %r = call i64 @llvm.ftm.ssubc(i64 %a, i64 %b)
  ret i64 %r
}

; CHECK-LABEL: @func test_vsubc32
; CHECK: VSUBC32
define void @test_vsubc32(ptr addrspace(1) %base, i64 %off, i64 %off2) {
  %r1 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %r2 = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off2)
  %c = call <32 x i32> @llvm.ftm.vsubc32(<32 x i32> %r1, <32 x i32> %r2)
  call void @llvm.ftm.vstw(<32 x i32> %c, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_ssubc32
; CHECK: SSUBC32
define <2 x i32> @test_ssubc32(<2 x i32> %a, <2 x i32> %b) {
  %r = call <2 x i32> @llvm.ftm.ssubc32(<2 x i32> %a, <2 x i32> %b)
  ret <2 x i32> %r
}

; ==================== Vector Saturation (VSAT/VSAT32) ====================

; ===================================================================
; VSAT: 64-bit vector saturation (flag-dependent)
; ===================================================================

; CHECK-LABEL: @func test_vsat
; CHECK: VSAT
define void @test_vsat(ptr addrspace(1) %base, i64 %off) {
  %v_raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %v = bitcast <32 x i32> %v_raw to <16 x i64>
  %res = call <16 x i64> @llvm.ftm.vsat(<16 x i64> %v)
  %out = bitcast <16 x i64> %res to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %out, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; VSAT32: 32-bit vector saturation (flag-dependent)
; ===================================================================

; CHECK-LABEL: @func test_vsat32
; CHECK: VSAT32
define void @test_vsat32(ptr addrspace(1) %base, i64 %off) {
  %v = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %res = call <32 x i32> @llvm.ftm.vsat32(<32 x i32> %v)
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}
