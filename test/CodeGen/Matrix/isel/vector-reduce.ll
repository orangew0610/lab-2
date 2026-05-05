; RUN: llc -mtriple=matrix < %s | FileCheck %s

; ===================================================================
; Vector horizontal reduction via SVR (Shared Vector Register)
; Pattern: VMVCGC vr → SVR, 16 × SMVCCG SVRi → ri, scalar tree
;
; SVR has 16 × 64-bit slots. For 32-bit elements (f32/i32), each slot
; holds 2 packed elements split with SBALE2H.
;
; No vector memory ops (VSTW/VLDW) — vector load/store can only access
; AM (addrspace 1), not stack/DDR.
; ===================================================================

; --- reduce_add i64: VMVCGC + 16 SMVCCG + 15 SADD ---

; CHECK-LABEL: @reduce_add_i64
; CHECK:       VMVCGC v{{[0-9]+}}, SVR
; CHECK:       SMVCCG SVR0
; CHECK:       SMVCCG SVR15
; CHECK:       SADD
; CHECK-NOT:   VSTW
; CHECK:       @ret
define i64 @reduce_add_i64(ptr %p) {
  %v = load <16 x i64>, ptr %p
  %r = call i64 @llvm.vector.reduce.add.v16i64(<16 x i64> %v)
  ret i64 %r
}

; --- reduce_add i32: VMVCGC + 16 SMVCCG + 16 SBALE2H + 31 SADD32 ---

; CHECK-LABEL: @reduce_add_i32
; CHECK:       VMVCGC v{{[0-9]+}}, SVR
; CHECK:       SMVCCG SVR0
; CHECK:       SBALE2H
; CHECK:       SADD32
; CHECK-NOT:   VSTW
; CHECK:       @ret
define i32 @reduce_add_i32(ptr %p) {
  %v = load <32 x i32>, ptr %p
  %r = call i32 @llvm.vector.reduce.add.v32i32(<32 x i32> %v)
  ret i32 %r
}

; --- reduce_fadd f64 (reassoc, tree reduction) ---

; CHECK-LABEL: @reduce_fadd_f64_reassoc
; CHECK:       VMVCGC v{{[0-9]+}}, SVR
; CHECK:       SMVCCG SVR0
; CHECK:       SFADDD
; CHECK-NOT:   VSTW
; CHECK:       @ret
define double @reduce_fadd_f64_reassoc(ptr %p) {
  %v = load <16 x double>, ptr %p
  %r = call reassoc double @llvm.vector.reduce.fadd.v16f64(double 0.0, <16 x double> %v)
  ret double %r
}

; --- reduce_fadd f32 (reassoc, tree reduction with SBALE2H) ---

; CHECK-LABEL: @reduce_fadd_f32_reassoc
; CHECK:       VMVCGC v{{[0-9]+}}, SVR
; CHECK:       SMVCCG SVR0
; CHECK:       SBALE2H
; CHECK-NOT:   VSTW
; CHECK:       @ret
define float @reduce_fadd_f32_reassoc(ptr %p) {
  %v = load <32 x float>, ptr %p
  %r = call reassoc float @llvm.vector.reduce.fadd.v32f32(float 0.0, <32 x float> %v)
  ret float %r
}

; --- reduce_fadd f64 (strict sequential — expanded by SelectionDAGBuilder) ---
; Note: strict reductions bypass VECREDUCE nodes; uses stack spill fallback.

; CHECK-LABEL: @reduce_fadd_f64_strict
; CHECK:       SFADDD
; CHECK:       @ret
define double @reduce_fadd_f64_strict(ptr %p) {
  %v = load <16 x double>, ptr %p
  %r = call double @llvm.vector.reduce.fadd.v16f64(double 0.0, <16 x double> %v)
  ret double %r
}

; --- reduce_smax i64 ---

; CHECK-LABEL: @reduce_smax_i64
; CHECK:       VMVCGC v{{[0-9]+}}, SVR
; CHECK:       SMVCCG SVR0
; CHECK:       SMAX
; CHECK-NOT:   VSTW
; CHECK:       @ret
define i64 @reduce_smax_i64(ptr %p) {
  %v = load <16 x i64>, ptr %p
  %r = call i64 @llvm.vector.reduce.smax.v16i64(<16 x i64> %v)
  ret i64 %r
}

; --- reduce_fmax f64 ---

; CHECK-LABEL: @reduce_fmax_f64
; CHECK:       VMVCGC v{{[0-9]+}}, SVR
; CHECK:       SMVCCG SVR0
; CHECK:       SFMAXD
; CHECK-NOT:   VSTW
; CHECK:       @ret
define double @reduce_fmax_f64(ptr %p) {
  %v = load <16 x double>, ptr %p
  %r = call double @llvm.vector.reduce.fmax.v16f64(<16 x double> %v)
  ret double %r
}

declare i64 @llvm.vector.reduce.add.v16i64(<16 x i64>)
declare i32 @llvm.vector.reduce.add.v32i32(<32 x i32>)
declare double @llvm.vector.reduce.fadd.v16f64(double, <16 x double>)
declare float @llvm.vector.reduce.fadd.v32f32(float, <32 x float>)
declare i64 @llvm.vector.reduce.smax.v16i64(<16 x i64>)
declare double @llvm.vector.reduce.fmax.v16f64(<16 x double>)
