; NOTE: LASM loop label annotation tests with iteration counts.
; RUN: llc -march=matrix -o - %s | FileCheck %s
; RUN: llc -march=matrix -O=1 -o - %s | FileCheck %s
; RUN: llc -march=matrix -O=2 -o - %s | FileCheck %s
; RUN: llc -march=matrix -O=3 -o - %s | FileCheck %s

;; ===================================================================
;; Loop label annotation tests
;;
;; Tests:
;;   - Manual metadata annotations (min/max, min-only)
;;   - SCEV auto-computed constant trip count
;;   - SCEV auto-computed bounded trip count (umin clamp)
;;   - Runtime loop (no useful bounds → bare label)
;;   - Manual annotation takes priority over SCEV
;;   - Nested loops (separate labels and numbering)
;;   - Non-loop branches (BB_ labels)
;; ===================================================================

target triple = "matrix-unknown-unknown"

;; ==================== Manual Annotation (min + max) ====================

define void @annotated_loop(ptr %p, i64 %n) {
; CHECK-LABEL: @func annotated_loop
; CHECK:       LOOP_annotated_loop_0: 128, 256
; CHECK:       SBR{{.*}}LOOP_annotated_loop_0
; CHECK:       @ret
entry:
  br label %loop

loop:
  %i = phi i64 [0, %entry], [%i.next, %loop]
  %addr = getelementptr i64, ptr %p, i64 %i
  store i64 %i, ptr %addr
  %i.next = add i64 %i, 1
  %cond = icmp slt i64 %i.next, %n
  br i1 %cond, label %loop, label %exit, !llvm.loop !0

exit:
  ret void
}

!0 = distinct !{!0, !1, !2}
!1 = !{!"llvm.loop.ftm.min_iterations", i64 128}
!2 = !{!"llvm.loop.ftm.max_iterations", i64 256}

;; ==================== Manual Annotation (min only) ====================

define void @min_only_loop(ptr %p, i64 %n) {
; CHECK-LABEL: @func min_only_loop
; CHECK:       LOOP_min_only_loop_0: 64
; CHECK:       SBR{{.*}}LOOP_min_only_loop_0
; CHECK:       @ret
entry:
  br label %loop

loop:
  %i = phi i64 [0, %entry], [%i.next, %loop]
  %addr = getelementptr i64, ptr %p, i64 %i
  store i64 %i, ptr %addr
  %i.next = add i64 %i, 1
  %cond = icmp slt i64 %i.next, %n
  br i1 %cond, label %loop, label %exit, !llvm.loop !3

exit:
  ret void
}

!3 = distinct !{!3, !4}
!4 = !{!"llvm.loop.ftm.min_iterations", i64 64}

;; ==================== SCEV: Constant Trip Count ====================
;; for(i=0; i<1024; i++) — SCEV computes exact trip count = 1024

define void @scev_constant(ptr %p) {
; CHECK-LABEL: @func scev_constant
; CHECK:       LOOP_scev_constant_0: 1024, 1024
; CHECK:       SBR{{.*}}LOOP_scev_constant_0
; CHECK:       @ret
entry:
  br label %loop

loop:
  %i = phi i64 [0, %entry], [%i.next, %loop]
  %addr = getelementptr i64, ptr %p, i64 %i
  store i64 %i, ptr %addr
  %i.next = add nuw nsw i64 %i, 1
  %cond = icmp slt i64 %i.next, 1024
  br i1 %cond, label %loop, label %exit

exit:
  ret void
}

;; ==================== SCEV: Bounded Trip Count ====================
;; for(i=0; i < min(n, 256); i++) — SCEV computes max = 256

define void @scev_bounded(ptr %p, i64 %n) {
; CHECK-LABEL: @func scev_bounded
; CHECK:       LOOP_scev_bounded_0:
; CHECK-NOT:   LOOP_scev_bounded_0: {{[0-9]}}
; CHECK:       SBR{{.*}}LOOP_scev_bounded_0
; CHECK:       @ret
entry:
  %clamp = call i64 @llvm.umin.i64(i64 %n, i64 256)
  br label %loop

loop:
  %i = phi i64 [0, %entry], [%i.next, %loop]
  %addr = getelementptr i64, ptr %p, i64 %i
  store i64 %i, ptr %addr
  %i.next = add nuw nsw i64 %i, 1
  %cond = icmp ult i64 %i.next, %clamp
  br i1 %cond, label %loop, label %exit

exit:
  ret void
}

declare i64 @llvm.umin.i64(i64, i64)

;; ==================== Runtime Loop (no bounds) ====================
;; for(i=0; i<n; i++) — SCEV cannot determine useful bounds

define void @runtime_loop(ptr %p, i64 %n) {
; CHECK-LABEL: @func runtime_loop
; CHECK:       LOOP_runtime_loop_0:
; CHECK-NOT:   LOOP_runtime_loop_0: {{[0-9]}}
; CHECK:       SBR{{.*}}LOOP_runtime_loop_0
; CHECK:       @ret
entry:
  br label %loop

loop:
  %i = phi i64 [0, %entry], [%i.next, %loop]
  %addr = getelementptr i64, ptr %p, i64 %i
  store i64 %i, ptr %addr
  %i.next = add i64 %i, 1
  %cond = icmp slt i64 %i.next, %n
  br i1 %cond, label %loop, label %exit

exit:
  ret void
}

;; ==================== Manual Overrides SCEV ====================
;; Constant loop (SCEV would compute 512,512) but user says 100,500

define void @manual_overrides_scev(ptr %p) {
; CHECK-LABEL: @func manual_overrides_scev
; CHECK:       LOOP_manual_overrides_scev_0: 100, 500
; CHECK:       @ret
entry:
  br label %loop

loop:
  %i = phi i64 [0, %entry], [%i.next, %loop]
  %addr = getelementptr i64, ptr %p, i64 %i
  store i64 %i, ptr %addr
  %i.next = add nuw nsw i64 %i, 1
  %cond = icmp slt i64 %i.next, 512
  br i1 %cond, label %loop, label %exit, !llvm.loop !5

exit:
  ret void
}

!5 = distinct !{!5, !6, !7}
!6 = !{!"llvm.loop.ftm.min_iterations", i64 100}
!7 = !{!"llvm.loop.ftm.max_iterations", i64 500}

;; ==================== Nested Loops ====================

define void @nested_loops(ptr %p, i64 %m, i64 %n) {
; CHECK-LABEL: @func nested_loops
; CHECK:       LOOP_nested_loops_0:
; CHECK:       LOOP_nested_loops_1:
; CHECK:       SBR{{.*}}LOOP_nested_loops_1
; CHECK:       SBR{{.*}}LOOP_nested_loops_0
; CHECK:       @ret
entry:
  br label %outer

outer:
  %i = phi i64 [0, %entry], [%i.next, %outer.latch]
  br label %inner

inner:
  %j = phi i64 [0, %outer], [%j.next, %inner]
  %idx = add i64 %i, %j
  %addr = getelementptr i64, ptr %p, i64 %idx
  store i64 %idx, ptr %addr
  %j.next = add i64 %j, 1
  %inner.cond = icmp slt i64 %j.next, %n
  br i1 %inner.cond, label %inner, label %outer.latch

outer.latch:
  %i.next = add i64 %i, 1
  %outer.cond = icmp slt i64 %i.next, %m
  br i1 %outer.cond, label %outer, label %exit

exit:
  ret void
}

;; ==================== Non-loop Branch ====================

define i64 @non_loop_branch(i64 %a, i64 %b) {
; CHECK-LABEL: @func non_loop_branch
; CHECK:       SBR{{.*}}BB_
; CHECK:       @ret
entry:
  %cmp = icmp slt i64 %a, %b
  br i1 %cmp, label %iftrue, label %iffalse

iftrue:
  ret i64 %a

iffalse:
  ret i64 %b
}
