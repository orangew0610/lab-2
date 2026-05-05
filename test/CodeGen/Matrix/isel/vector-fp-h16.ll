; NOTE: Vector half-precision (v64f16) instruction selection tests
; RUN: llc -march=matrix -o - %s | FileCheck %s

;; ===================================================================
;; Vector half-precision (v64f16) instruction selection tests
;;
;; Instructions tested:
;;   VFADDH16/VFSUBH16/VFMULH16/VFMAX16/VFABSH16 - basic arith
;;   VFMULAH16 - FMA
;;   VFCMPEH16 - compare
;;   VFHINT16/VFINTH16 - int conversion
;;   VFHPSP16H/VFSPHP16 - precision conversion
;;   VFP16toBF16 - format conversion
;;   VFLOGH16/VFEXTH16HH/VFCMULH16/VFMULAHHS/VFEXTS32H - special ops
;; ===================================================================

target triple = "matrix-unknown-unknown"

; --- Intrinsic declarations ---
declare <32 x i32> @llvm.ftm.vldw(ptr addrspace(1), i64)
declare void @llvm.ftm.vstw(<32 x i32>, ptr addrspace(1), i64)
declare <64 x half> @llvm.fabs.v64f16(<64 x half>)
declare <64 x half> @llvm.fma.v64f16(<64 x half>, <64 x half>, <64 x half>)
declare <64 x half> @llvm.maxnum.v64f16(<64 x half>, <64 x half>)

; Vector compare intrinsics
declare <64 x i16> @llvm.ftm.vfcmpeh16(<64 x half>, <64 x half>)
declare <64 x i16> @llvm.ftm.vfcmpgh16(<64 x half>, <64 x half>)
declare <64 x i16> @llvm.ftm.vfcmplh16(<64 x half>, <64 x half>)

; Vector conversion intrinsics
declare <64 x i16> @llvm.ftm.vfhint16(<64 x half>)
declare <64 x i16> @llvm.ftm.vfhtru16(<64 x half>)
declare <64 x half> @llvm.ftm.vfinth16(<64 x i16>)
declare <64 x half> @llvm.ftm.vfinthu16(<64 x i16>)
declare <32 x float> @llvm.ftm.vfhpsp16h(<64 x half>)
declare <32 x float> @llvm.ftm.vfhpsp16l(<64 x half>)
declare <64 x half> @llvm.ftm.vfsphp16(<32 x float>, <32 x float>)
declare <64 x i16> @llvm.ftm.vfp16tobf16(<64 x half>)
declare <64 x half> @llvm.ftm.vbf16tofp16(<64 x i16>)

; Vector special intrinsics
declare <64 x half> @llvm.ftm.vflogh16(<64 x half>)
declare <64 x i16> @llvm.ftm.vfmanh16(<64 x half>)
declare <64 x half> @llvm.ftm.vfexth16hh(<64 x half>)
declare <64 x half> @llvm.ftm.vfexth16hl(<64 x half>)
declare <64 x half> @llvm.ftm.vfexth16lh(<64 x half>)
declare <64 x half> @llvm.ftm.vfexth16ll(<64 x half>)
declare <32 x float> @llvm.ftm.vfexts32h(<32 x float>)
declare <32 x float> @llvm.ftm.vfexts32l(<32 x float>)
declare <64 x half> @llvm.ftm.vfcmulh16(<64 x half>, <64 x half>)
declare <64 x half> @llvm.ftm.vfdoth16(<64 x half>, <64 x half>)
declare <32 x float> @llvm.ftm.vfmulahhs(<64 x half>, <64 x half>, <32 x float>)
declare <32 x float> @llvm.ftm.vfmulahls(<64 x half>, <64 x half>, <32 x float>)

; ===================================================================
; Basic Arithmetic
; ===================================================================

; CHECK-LABEL: @func test_vfaddh16
; CHECK: VLDW
; CHECK: VFADDH16
; CHECK: VSTW
define void @test_vfaddh16(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <64 x half>
  %c = fadd <64 x half> %a, %a
  %res = bitcast <64 x half> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vfsubh16
; CHECK: VLDW
; CHECK: VFSUBH16
; CHECK: VSTW
define void @test_vfsubh16(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <64 x half>
  %c = fsub <64 x half> %a, %a
  %res = bitcast <64 x half> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vfmulh16
; CHECK: VLDW
; CHECK: VFMULH16
; CHECK: VSTW
define void @test_vfmulh16(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <64 x half>
  %c = fmul <64 x half> %a, %a
  %res = bitcast <64 x half> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vfmax16
; CHECK: VLDW
; CHECK: VFMAX16
; CHECK: VSTW
define void @test_vfmax16(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <64 x half>
  %c = call <64 x half> @llvm.maxnum.v64f16(<64 x half> %a, <64 x half> %a)
  %res = bitcast <64 x half> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vfabsh16
; CHECK: VLDW
; CHECK: VFABSH16
; CHECK: VSTW
define void @test_vfabsh16(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <64 x half>
  %c = call <64 x half> @llvm.fabs.v64f16(<64 x half> %a)
  %res = bitcast <64 x half> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; FMA
; ===================================================================

; CHECK-LABEL: @func test_vfmulah16
; CHECK: VFMULAH16
define void @test_vfmulah16(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <64 x half>
  %c = call <64 x half> @llvm.fma.v64f16(<64 x half> %a, <64 x half> %a, <64 x half> %a)
  %res = bitcast <64 x half> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; Compare
; ===================================================================

; CHECK-LABEL: @func test_vfcmpeh16
; CHECK: VFCMPEH16
define void @test_vfcmpeh16(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <64 x half>
  %c = call <64 x i16> @llvm.ftm.vfcmpeh16(<64 x half> %a, <64 x half> %a)
  %res = bitcast <64 x i16> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; Conversions
; ===================================================================

; CHECK-LABEL: @func test_vfhint16
; CHECK: VFHINT16
define void @test_vfhint16(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <64 x half>
  %c = call <64 x i16> @llvm.ftm.vfhint16(<64 x half> %a)
  %res = bitcast <64 x i16> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vfinth16
; CHECK: VFINTH16
define void @test_vfinth16(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <64 x i16>
  %c = call <64 x half> @llvm.ftm.vfinth16(<64 x i16> %a)
  %res = bitcast <64 x half> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vfhpsp16h
; CHECK: VFHPSP16H
define void @test_vfhpsp16h(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <64 x half>
  %c = call <32 x float> @llvm.ftm.vfhpsp16h(<64 x half> %a)
  %res = bitcast <32 x float> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vfsphp16
; CHECK: VFSPHP16
define void @test_vfsphp16(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <32 x float>
  %c = call <64 x half> @llvm.ftm.vfsphp16(<32 x float> %a, <32 x float> %a)
  %res = bitcast <64 x half> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vfp16tobf16
; CHECK: VFP16toBF16
define void @test_vfp16tobf16(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <64 x half>
  %c = call <64 x i16> @llvm.ftm.vfp16tobf16(<64 x half> %a)
  %res = bitcast <64 x i16> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; ===================================================================
; Special ops
; ===================================================================

; CHECK-LABEL: @func test_vflogh16
; CHECK: VFLOGH16
define void @test_vflogh16(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <64 x half>
  %c = call <64 x half> @llvm.ftm.vflogh16(<64 x half> %a)
  %res = bitcast <64 x half> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vfexth16hh
; CHECK: VFEXTH16HH
define void @test_vfexth16hh(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <64 x half>
  %c = call <64 x half> @llvm.ftm.vfexth16hh(<64 x half> %a)
  %res = bitcast <64 x half> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vfcmulh16
; CHECK: VFCMULH16
define void @test_vfcmulh16(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <64 x half>
  %c = call <64 x half> @llvm.ftm.vfcmulh16(<64 x half> %a, <64 x half> %a)
  %res = bitcast <64 x half> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vfmulahhs
; CHECK: VFMULAHHS
define void @test_vfmulahhs(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <64 x half>
  %b = bitcast <32 x i32> %raw to <32 x float>
  %c = call <32 x float> @llvm.ftm.vfmulahhs(<64 x half> %a, <64 x half> %a, <32 x float> %b)
  %res = bitcast <32 x float> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}

; CHECK-LABEL: @func test_vfexts32h
; CHECK: VFEXTS32H
define void @test_vfexts32h(ptr addrspace(1) %base, i64 %off) {
  %raw = call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %base, i64 %off)
  %a = bitcast <32 x i32> %raw to <32 x float>
  %c = call <32 x float> @llvm.ftm.vfexts32h(<32 x float> %a)
  %res = bitcast <32 x float> %c to <32 x i32>
  call void @llvm.ftm.vstw(<32 x i32> %res, ptr addrspace(1) %base, i64 %off)
  ret void
}
