; NOTE: Post-increment addressing mode tests
; RUN: llc -march=matrix -o - %s | FileCheck %s

;; ===================================================================
;; Post-increment load/store instruction selection tests
;;
;; Tests that load(ptr) + add(ptr, stride) patterns are combined into
;; post-increment loads/stores: *ar++[stride]
;; ===================================================================

target triple = "matrix-unknown-unknown"

; --- Scalar 64-bit load post-increment (SLDW) ---

; CHECK-LABEL: @func test_sldw_postinc
; CHECK: SLDW *{{ar[0-9]+}}++[1]
define i64 @test_sldw_postinc(ptr %base, i32 %n) {
entry:
  %cmp = icmp sgt i32 %n, 0
  br i1 %cmp, label %loop, label %exit

loop:
  %ptr = phi ptr [ %base, %entry ], [ %ptr.next, %loop ]
  %acc = phi i64 [ 0, %entry ], [ %acc.next, %loop ]
  %i = phi i32 [ 0, %entry ], [ %i.next, %loop ]
  %val = load i64, ptr %ptr, align 8
  %acc.next = add i64 %acc, %val
  %ptr.next = getelementptr inbounds i64, ptr %ptr, i64 1
  %i.next = add i32 %i, 1
  %done = icmp eq i32 %i.next, %n
  br i1 %done, label %exit, label %loop

exit:
  %result = phi i64 [ 0, %entry ], [ %acc.next, %loop ]
  ret i64 %result
}

; --- Scalar f32 load post-increment (SLDHU) ---

; CHECK-LABEL: @func test_sldhu_postinc
; CHECK: SLDHU *{{ar[0-9]+}}++[1]
define float @test_sldhu_postinc(ptr %base, i32 %n) {
entry:
  %cmp = icmp sgt i32 %n, 0
  br i1 %cmp, label %loop, label %exit

loop:
  %ptr = phi ptr [ %base, %entry ], [ %ptr.next, %loop ]
  %acc = phi float [ 0.0, %entry ], [ %acc.next, %loop ]
  %i = phi i32 [ 0, %entry ], [ %i.next, %loop ]
  %val = load float, ptr %ptr, align 4
  %acc.next = fadd float %acc, %val
  %ptr.next = getelementptr inbounds float, ptr %ptr, i64 1
  %i.next = add i32 %i, 1
  %done = icmp eq i32 %i.next, %n
  br i1 %done, label %exit, label %loop

exit:
  %result = phi float [ 0.0, %entry ], [ %acc.next, %loop ]
  ret float %result
}

; --- Scalar 64-bit store post-increment (SSTW) ---

; CHECK-LABEL: @func test_sstw_postinc
; CHECK: SSTW {{r[0-9]+}}, *{{ar[0-9]+}}++[1]
define void @test_sstw_postinc(ptr %base, i64 %val, i32 %n) {
entry:
  %cmp = icmp sgt i32 %n, 0
  br i1 %cmp, label %loop, label %exit

loop:
  %ptr = phi ptr [ %base, %entry ], [ %ptr.next, %loop ]
  %i = phi i32 [ 0, %entry ], [ %i.next, %loop ]
  store i64 %val, ptr %ptr, align 8
  %ptr.next = getelementptr inbounds i64, ptr %ptr, i64 1
  %i.next = add i32 %i, 1
  %done = icmp eq i32 %i.next, %n
  br i1 %done, label %exit, label %loop

exit:
  ret void
}

; --- Scalar f32 store post-increment (SSTH) ---

; CHECK-LABEL: @func test_ssth_postinc
; CHECK: SSTH {{r[0-9]+}}, *{{ar[0-9]+}}++[1]
define void @test_ssth_postinc(ptr %base, float %val, i32 %n) {
entry:
  %cmp = icmp sgt i32 %n, 0
  br i1 %cmp, label %loop, label %exit

loop:
  %ptr = phi ptr [ %base, %entry ], [ %ptr.next, %loop ]
  %i = phi i32 [ 0, %entry ], [ %i.next, %loop ]
  store float %val, ptr %ptr, align 4
  %ptr.next = getelementptr inbounds float, ptr %ptr, i64 1
  %i.next = add i32 %i, 1
  %done = icmp eq i32 %i.next, %n
  br i1 %done, label %exit, label %loop

exit:
  ret void
}
