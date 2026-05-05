; NOTE: Global variable address-space section placement tests
; RUN: llc -march=matrix -o - %s | FileCheck %s

;; ===================================================================
;; Verify that globals in different address spaces are placed in the
;; correct LASM sections:
;;
;;   DDR (0) → .data / .bss (default)
;;   SM  (2) → .sm.data / .sm.bss
;;   GSM (3) → .gsm.data / .gsm.bss
;; ===================================================================

target triple = "matrix-unknown-unknown"

;; --- DDR (default address space) ---
@ddr_init = global i64 100
; CHECK: @sect ".data", ddr_init, @b64, 100

@ddr_zero = global i64 0
; CHECK: @usect ".bss", ddr_zero, @b64, 1

@ddr_uninit = external global i64
; Note: externals are not emitted by AsmPrinter

;; --- SM (addrspace 2) ---
@sm_init = addrspace(2) global i64 200
; CHECK: @sect ".sm.data", sm_init, @b64, 200

@sm_zero = addrspace(2) global i64 0
; CHECK: @usect ".sm.bss", sm_zero, @b64, 1

@sm_fp = addrspace(2) global double 3.14
; CHECK: @sect ".sm.data", sm_fp, @b64,

;; --- GSM (addrspace 3) ---
@gsm_init = addrspace(3) global i64 300
; CHECK: @sect ".gsm.data", gsm_init, @b64, 300

@gsm_zero = addrspace(3) global i64 0
; CHECK: @usect ".gsm.bss", gsm_zero, @b64, 1

@gsm_array = addrspace(3) global [4 x i64] zeroinitializer
; CHECK: @usect ".gsm.bss", gsm_array, @b64, 4

;; Dummy function to make this a valid module
define void @dummy() {
  ret void
}
