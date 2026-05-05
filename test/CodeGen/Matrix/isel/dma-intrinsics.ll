; RUN: llc -mtriple=matrix %s -o - | FileCheck %s

; Test that CSL DMA/config functions emit @icall with correct function names
; and explicit register parameters. These functions are provided by
; csl.lan and imported via @import.

declare void @dma_config(i64, i64, i64, i64)
declare void @dma_start(i64, i64, i64, i64, i64, i64, i64, i64)
declare void @dma_start_sg(i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64)
declare void @dma_wait(i64, i64)
declare void @dma_wait_bor(i64, i64)
declare void @config_prir(i64)
declare void @config_sgtc(i64)

; Check that @import "csl.lan" is emitted (includes DMA and other CSL functions)
; CHECK: @import "csl.lan"{{.*}}dma_config{{.*}}dma_start{{.*}}dma_start_sg{{.*}}dma_wait{{.*}}dma_wait_bor

; CHECK-LABEL: @func test_dma_config
; CHECK: @icall dma_config, r10, r11, r12, r13
define void @test_dma_config(i64 %ch, i64 %ctrl1, i64 %ctrl2, i64 %pw7) {
  call void @dma_config(i64 %ch, i64 %ctrl1, i64 %ctrl2, i64 %pw7)
  ret void
}

; CHECK-LABEL: @func test_dma_start
; CHECK: @icall dma_start, r10, r11, r12, r13, r14, r15, r16, r17
define void @test_dma_start(i64 %ch, i64 %src, i64 %dst, i64 %fc,
                            i64 %ec, i64 %sfi, i64 %dfi, i64 %flag) {
  call void @dma_start(i64 %ch, i64 %src, i64 %dst, i64 %fc,
                        i64 %ec, i64 %sfi, i64 %dfi, i64 %flag)
  ret void
}

; CHECK-LABEL: @func test_dma_start_sg
; CHECK: @icall dma_start_sg, r10, r11, r12, r13, r14, r15, r16, r17, r18, r19, r20
define void @test_dma_start_sg(i64 %ch, i64 %c2, i64 %src, i64 %dst,
                               i64 %sfc, i64 %sec, i64 %dfc, i64 %dec,
                               i64 %sfi, i64 %dfi, i64 %flag) {
  call void @dma_start_sg(i64 %ch, i64 %c2, i64 %src, i64 %dst,
                           i64 %sfc, i64 %sec, i64 %dfc, i64 %dec,
                           i64 %sfi, i64 %dfi, i64 %flag)
  ret void
}

; CHECK-LABEL: @func test_dma_wait
; CHECK: @icall dma_wait, r10, r11
define void @test_dma_wait(i64 %ch, i64 %flag) {
  call void @dma_wait(i64 %ch, i64 %flag)
  ret void
}

; CHECK-LABEL: @func test_dma_wait_bor
; CHECK: @icall dma_wait_bor, r10, r11
define void @test_dma_wait_bor(i64 %ch, i64 %flag) {
  call void @dma_wait_bor(i64 %ch, i64 %flag)
  ret void
}

; ===================================================================
; CSL config functions via @icall
; ===================================================================

; CHECK-LABEL: @func test_config_prir
; CHECK: @icall config_prir, r10
define void @test_config_prir(i64 %priority) {
  call void @config_prir(i64 %priority)
  ret void
}

; CHECK-LABEL: @func test_config_sgtc
; CHECK: @icall config_sgtc, r10
define void @test_config_sgtc(i64 %val) {
  call void @config_sgtc(i64 %val)
  ret void
}
