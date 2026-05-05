; NOTE: Scalar floating-point compare instruction selection tests
; RUN: llc -march=matrix -o - %s | FileCheck %s

;; ===================================================================
;; Scalar floating-point compare instruction selection tests
;;
;; Instructions tested:
;;   SFCMPED/SFCMPGD/SFCMPLD - f64 compare + branch/select
;;   SFCMPEH16/SFCMPGH16/SFCMPLH16 - h16 compare + branch
;;   SFCMPES32/SFCMPGS32/SFCMPLS32 - v2f32 compare + branch
;; ===================================================================

target triple = "matrix-unknown-unknown"

declare void @foo()
declare void @bar()
declare i64 @llvm.ftm.sfcmpeh16(i64, i64)
declare i64 @llvm.ftm.sfcmpgh16(i64, i64)
declare i64 @llvm.ftm.sfcmplh16(i64, i64)
declare i64 @llvm.ftm.sfcmpes32(i64, i64)
declare i64 @llvm.ftm.sfcmpgs32(i64, i64)
declare i64 @llvm.ftm.sfcmpls32(i64, i64)

;; ==================== f64 Compare + Branch/Select ====================

; --- f64 less-than branch: fcmp olt → SFCMPLD + SBR ---
define void @test_fcmp_olt_branch(double %a, double %b) {
; CHECK-LABEL: @func test_fcmp_olt_branch
; CHECK: SFCMPLD
; CHECK-NOT: SEQ
; CHECK: SBR
entry:
  %cmp = fcmp olt double %a, %b
  br i1 %cmp, label %then, label %else
then:
  call void @foo()
  br label %end
else:
  call void @bar()
  br label %end
end:
  ret void
}

; --- f64 greater-than branch: fcmp ogt → SFCMPGD + SBR ---
define void @test_fcmp_ogt_branch(double %a, double %b) {
; CHECK-LABEL: @func test_fcmp_ogt_branch
; CHECK: SFCMPGD
; CHECK-NOT: SEQ
; CHECK: SBR
entry:
  %cmp = fcmp ogt double %a, %b
  br i1 %cmp, label %then, label %else
then:
  call void @foo()
  br label %end
else:
  call void @bar()
  br label %end
end:
  ret void
}

; --- f64 equality branch: fcmp oeq → SFCMPED + SBR ---
define void @test_fcmp_oeq_branch(double %a, double %b) {
; CHECK-LABEL: @func test_fcmp_oeq_branch
; CHECK: SFCMPED
; CHECK-NOT: SEQ
; CHECK: SBR
entry:
  %cmp = fcmp oeq double %a, %b
  br i1 %cmp, label %then, label %else
then:
  call void @foo()
  br label %end
else:
  call void @bar()
  br label %end
end:
  ret void
}

; --- f64 SELECT (compare f64, select f64): fcmp ogt → SFCMPGD + SBR ---
define double @test_fp_select_fp(double %a, double %b, double %x, double %y) {
; CHECK-LABEL: @func test_fp_select_fp
; CHECK: SFCMPGD
; CHECK-NOT: SEQ
; CHECK: SBR
  %cmp = fcmp ogt double %a, %b
  %result = select i1 %cmp, double %x, double %y
  ret double %result
}

; --- f64 SELECT (compare f64, select i64): fcmp oeq → SFCMPED + SBR ---
define i64 @test_fp_select_int(double %a, double %b, i64 %x, i64 %y) {
; CHECK-LABEL: @func test_fp_select_int
; CHECK: SFCMPED
; CHECK-NOT: SEQ
; CHECK: SBR
  %cmp = fcmp oeq double %a, %b
  %result = select i1 %cmp, i64 %x, i64 %y
  ret i64 %result
}

;; ==================== h16/v2f32 Compare + Branch ====================

; CHECK-LABEL: @func test_sfcmpeh16
; CHECK: SFCMPEH16
define i64 @test_sfcmpeh16(i64 %a, i64 %b) {
  %res = call i64 @llvm.ftm.sfcmpeh16(i64 %a, i64 %b)
  ret i64 %res
}

; CHECK-LABEL: @func test_sfcmpgh16
; CHECK: SFCMPGH16
define i64 @test_sfcmpgh16(i64 %a, i64 %b) {
  %res = call i64 @llvm.ftm.sfcmpgh16(i64 %a, i64 %b)
  ret i64 %res
}

; CHECK-LABEL: @func test_sfcmplh16
; CHECK: SFCMPLH16
define i64 @test_sfcmplh16(i64 %a, i64 %b) {
  %res = call i64 @llvm.ftm.sfcmplh16(i64 %a, i64 %b)
  ret i64 %res
}

; CHECK-LABEL: @func test_sfcmpeh16_branch
; CHECK: SFCMPEH16
; CHECK: SEQ
; CHECK: SBR
define i64 @test_sfcmpeh16_branch(i64 %a, i64 %b) {
  %cmp = call i64 @llvm.ftm.sfcmpeh16(i64 %a, i64 %b)
  %nz = icmp ne i64 %cmp, 0
  br i1 %nz, label %then, label %else
then:
  ret i64 1
else:
  ret i64 0
}

; CHECK-LABEL: @func test_sfcmpes32_standalone
; CHECK: SFCMPES32
define i64 @test_sfcmpes32_standalone(i64 %a, i64 %b) {
  %res = call i64 @llvm.ftm.sfcmpes32(i64 %a, i64 %b)
  ret i64 %res
}

; CHECK-LABEL: @func test_sfcmpes32_branch
; CHECK: SFCMPES32
; CHECK: SEQ
; CHECK: SBR
define i64 @test_sfcmpes32_branch(i64 %a, i64 %b) {
  %cmp = call i64 @llvm.ftm.sfcmpes32(i64 %a, i64 %b)
  %nz = icmp ne i64 %cmp, 0
  br i1 %nz, label %then, label %else
then:
  ret i64 1
else:
  ret i64 0
}

; CHECK-LABEL: @func test_sfcmpgs32_branch
; CHECK: SFCMPGS32
; CHECK: SEQ
; CHECK: SBR
define i64 @test_sfcmpgs32_branch(i64 %a, i64 %b) {
  %cmp = call i64 @llvm.ftm.sfcmpgs32(i64 %a, i64 %b)
  %nz = icmp ne i64 %cmp, 0
  br i1 %nz, label %then, label %else
then:
  ret i64 1
else:
  ret i64 0
}
