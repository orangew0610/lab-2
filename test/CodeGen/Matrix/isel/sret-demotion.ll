; NOTE: Tests for sret demotion when return values overflow registers
; RUN: llc -march=matrix -o - %s | FileCheck %s

target triple = "matrix-unknown-unknown"

;; ===================================================================
;; Small struct return — fits in registers (R10-R11), no sret needed
;; ===================================================================

; CHECK-LABEL: @func small_return
; CHECK-NOT: @smovi
; CHECK: @ret
define {i64, i64} @small_return(i64 %a, i64 %b) {
  %r = insertvalue {i64, i64} undef, i64 %a, 0
  %r2 = insertvalue {i64, i64} %r, i64 %b, 1
  ret {i64, i64} %r2
}

;; ===================================================================
;; 16-field struct — boundary case: fits in R10-R25 (no sret)
;; ===================================================================

; CHECK-LABEL: @func boundary_return
; CHECK-NOT: SSTW
; CHECK: @ret
define {i64, i64, i64, i64, i64, i64, i64, i64,
        i64, i64, i64, i64, i64, i64, i64, i64} @boundary_return(i64 %a) {
  %r0 = insertvalue {i64, i64, i64, i64, i64, i64, i64, i64,
                      i64, i64, i64, i64, i64, i64, i64, i64} undef, i64 %a, 0
  %r1 = insertvalue {i64, i64, i64, i64, i64, i64, i64, i64,
                      i64, i64, i64, i64, i64, i64, i64, i64} %r0, i64 %a, 1
  %r2 = insertvalue {i64, i64, i64, i64, i64, i64, i64, i64,
                      i64, i64, i64, i64, i64, i64, i64, i64} %r1, i64 %a, 2
  %r3 = insertvalue {i64, i64, i64, i64, i64, i64, i64, i64,
                      i64, i64, i64, i64, i64, i64, i64, i64} %r2, i64 %a, 3
  %r4 = insertvalue {i64, i64, i64, i64, i64, i64, i64, i64,
                      i64, i64, i64, i64, i64, i64, i64, i64} %r3, i64 %a, 4
  %r5 = insertvalue {i64, i64, i64, i64, i64, i64, i64, i64,
                      i64, i64, i64, i64, i64, i64, i64, i64} %r4, i64 %a, 5
  %r6 = insertvalue {i64, i64, i64, i64, i64, i64, i64, i64,
                      i64, i64, i64, i64, i64, i64, i64, i64} %r5, i64 %a, 6
  %r7 = insertvalue {i64, i64, i64, i64, i64, i64, i64, i64,
                      i64, i64, i64, i64, i64, i64, i64, i64} %r6, i64 %a, 7
  %r8 = insertvalue {i64, i64, i64, i64, i64, i64, i64, i64,
                      i64, i64, i64, i64, i64, i64, i64, i64} %r7, i64 %a, 8
  %r9 = insertvalue {i64, i64, i64, i64, i64, i64, i64, i64,
                      i64, i64, i64, i64, i64, i64, i64, i64} %r8, i64 %a, 9
  %r10 = insertvalue {i64, i64, i64, i64, i64, i64, i64, i64,
                       i64, i64, i64, i64, i64, i64, i64, i64} %r9, i64 %a, 10
  %r11 = insertvalue {i64, i64, i64, i64, i64, i64, i64, i64,
                       i64, i64, i64, i64, i64, i64, i64, i64} %r10, i64 %a, 11
  %r12 = insertvalue {i64, i64, i64, i64, i64, i64, i64, i64,
                       i64, i64, i64, i64, i64, i64, i64, i64} %r11, i64 %a, 12
  %r13 = insertvalue {i64, i64, i64, i64, i64, i64, i64, i64,
                       i64, i64, i64, i64, i64, i64, i64, i64} %r12, i64 %a, 13
  %r14 = insertvalue {i64, i64, i64, i64, i64, i64, i64, i64,
                       i64, i64, i64, i64, i64, i64, i64, i64} %r13, i64 %a, 14
  %r15 = insertvalue {i64, i64, i64, i64, i64, i64, i64, i64,
                       i64, i64, i64, i64, i64, i64, i64, i64} %r14, i64 %a, 15
  ret {i64, i64, i64, i64, i64, i64, i64, i64,
       i64, i64, i64, i64, i64, i64, i64, i64} %r15
}

;; ===================================================================
;; Large struct return — 17 i64 values overflow R10-R25, triggers sret
;; ===================================================================

; CHECK-LABEL: @func large_return
; CHECK: SSTW
; CHECK: @ret
define {i64, i64, i64, i64, i64, i64, i64, i64,
        i64, i64, i64, i64, i64, i64, i64, i64, i64} @large_return(i64 %a) {
  %r0 = insertvalue {i64, i64, i64, i64, i64, i64, i64, i64,
                      i64, i64, i64, i64, i64, i64, i64, i64, i64} undef, i64 %a, 0
  %r1 = insertvalue {i64, i64, i64, i64, i64, i64, i64, i64,
                      i64, i64, i64, i64, i64, i64, i64, i64, i64} %r0, i64 %a, 1
  %r2 = insertvalue {i64, i64, i64, i64, i64, i64, i64, i64,
                      i64, i64, i64, i64, i64, i64, i64, i64, i64} %r1, i64 %a, 2
  %r3 = insertvalue {i64, i64, i64, i64, i64, i64, i64, i64,
                      i64, i64, i64, i64, i64, i64, i64, i64, i64} %r2, i64 %a, 3
  %r4 = insertvalue {i64, i64, i64, i64, i64, i64, i64, i64,
                      i64, i64, i64, i64, i64, i64, i64, i64, i64} %r3, i64 %a, 4
  %r5 = insertvalue {i64, i64, i64, i64, i64, i64, i64, i64,
                      i64, i64, i64, i64, i64, i64, i64, i64, i64} %r4, i64 %a, 5
  %r6 = insertvalue {i64, i64, i64, i64, i64, i64, i64, i64,
                      i64, i64, i64, i64, i64, i64, i64, i64, i64} %r5, i64 %a, 6
  %r7 = insertvalue {i64, i64, i64, i64, i64, i64, i64, i64,
                      i64, i64, i64, i64, i64, i64, i64, i64, i64} %r6, i64 %a, 7
  %r8 = insertvalue {i64, i64, i64, i64, i64, i64, i64, i64,
                      i64, i64, i64, i64, i64, i64, i64, i64, i64} %r7, i64 %a, 8
  %r9 = insertvalue {i64, i64, i64, i64, i64, i64, i64, i64,
                      i64, i64, i64, i64, i64, i64, i64, i64, i64} %r8, i64 %a, 9
  %r10 = insertvalue {i64, i64, i64, i64, i64, i64, i64, i64,
                       i64, i64, i64, i64, i64, i64, i64, i64, i64} %r9, i64 %a, 10
  %r11 = insertvalue {i64, i64, i64, i64, i64, i64, i64, i64,
                       i64, i64, i64, i64, i64, i64, i64, i64, i64} %r10, i64 %a, 11
  %r12 = insertvalue {i64, i64, i64, i64, i64, i64, i64, i64,
                       i64, i64, i64, i64, i64, i64, i64, i64, i64} %r11, i64 %a, 12
  %r13 = insertvalue {i64, i64, i64, i64, i64, i64, i64, i64,
                       i64, i64, i64, i64, i64, i64, i64, i64, i64} %r12, i64 %a, 13
  %r14 = insertvalue {i64, i64, i64, i64, i64, i64, i64, i64,
                       i64, i64, i64, i64, i64, i64, i64, i64, i64} %r13, i64 %a, 14
  %r15 = insertvalue {i64, i64, i64, i64, i64, i64, i64, i64,
                       i64, i64, i64, i64, i64, i64, i64, i64, i64} %r14, i64 %a, 15
  %r16 = insertvalue {i64, i64, i64, i64, i64, i64, i64, i64,
                       i64, i64, i64, i64, i64, i64, i64, i64, i64} %r15, i64 %a, 16
  ret {i64, i64, i64, i64, i64, i64, i64, i64,
       i64, i64, i64, i64, i64, i64, i64, i64, i64} %r16
}

;; ===================================================================
;; Memref-like struct — 7 fields ({ptr, ptr, i64, [2 x i64], [2 x i64]})
;; This is what MLIR generates for a memref descriptor without bare-ptr.
;; With 16 return registers, this fits easily — no sret needed.
;; ===================================================================

; CHECK-LABEL: @func memref_like_return
; CHECK-NOT: SSTW
; CHECK: @ret
define {ptr, ptr, i64, [2 x i64], [2 x i64]} @memref_like_return(ptr %p) {
  %r = insertvalue {ptr, ptr, i64, [2 x i64], [2 x i64]} undef, ptr %p, 0
  %r1 = insertvalue {ptr, ptr, i64, [2 x i64], [2 x i64]} %r, ptr %p, 1
  %r2 = insertvalue {ptr, ptr, i64, [2 x i64], [2 x i64]} %r1, i64 0, 2
  ret {ptr, ptr, i64, [2 x i64], [2 x i64]} %r2
}
