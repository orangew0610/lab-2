; NOTE: Scalar memory access with SM/GSM/DDR address spaces
; RUN: llc -march=matrix -o - %s | FileCheck %s

;; ===================================================================
;; Scalar memory access across address spaces
;;
;; Verifies that SLD*/SST* instructions work with all three scalar
;; address spaces: DDR (0), SM (2), GSM (3).
;; Hardware routes by address value, not instruction variant, so the
;; same SLDW/SSTW instructions serve all three spaces.
;;
;; Also verifies that globals in SM/GSM address spaces are placed
;; in the correct sections (.sm.data/.sm.bss, .gsm.data/.gsm.bss).
;; ===================================================================

target triple = "matrix-unknown-unknown"

;; ==================== SM (addrspace 2) Loads ====================

; i64 load from SM
define i64 @load_sm_i64(ptr addrspace(2) %p) {
; CHECK-LABEL: @func load_sm_i64
; CHECK: SLDW
  %v = load i64, ptr addrspace(2) %p
  ret i64 %v
}

; i32 sext load from SM
define i64 @load_sm_sext_i32(ptr addrspace(2) %p) {
; CHECK-LABEL: @func load_sm_sext_i32
; CHECK: SLDH
  %v = load i32, ptr addrspace(2) %p
  %ext = sext i32 %v to i64
  ret i64 %ext
}

; i16 zext load from SM
define i64 @load_sm_zext_i16(ptr addrspace(2) %p) {
; CHECK-LABEL: @func load_sm_zext_i16
; CHECK: SLDDBU
  %v = load i16, ptr addrspace(2) %p
  %ext = zext i16 %v to i64
  ret i64 %ext
}

; i8 load from SM
define i64 @load_sm_zext_i8(ptr addrspace(2) %p) {
; CHECK-LABEL: @func load_sm_zext_i8
; CHECK: SLDBU
  %v = load i8, ptr addrspace(2) %p
  %ext = zext i8 %v to i64
  ret i64 %ext
}

;; ==================== SM (addrspace 2) Stores ====================

; i64 store to SM
define void @store_sm_i64(ptr addrspace(2) %p, i64 %val) {
; CHECK-LABEL: @func store_sm_i64
; CHECK: SSTW
  store i64 %val, ptr addrspace(2) %p
  ret void
}

; i32 store to SM
define void @store_sm_i32(ptr addrspace(2) %p, i32 %val) {
; CHECK-LABEL: @func store_sm_i32
; CHECK: SSTH
  store i32 %val, ptr addrspace(2) %p
  ret void
}

;; ==================== GSM (addrspace 3) Loads ====================

; i64 load from GSM
define i64 @load_gsm_i64(ptr addrspace(3) %p) {
; CHECK-LABEL: @func load_gsm_i64
; CHECK: SLDW
  %v = load i64, ptr addrspace(3) %p
  ret i64 %v
}

; i32 sext load from GSM
define i64 @load_gsm_sext_i32(ptr addrspace(3) %p) {
; CHECK-LABEL: @func load_gsm_sext_i32
; CHECK: SLDH
  %v = load i32, ptr addrspace(3) %p
  %ext = sext i32 %v to i64
  ret i64 %ext
}

;; ==================== GSM (addrspace 3) Stores ====================

; i64 store to GSM
define void @store_gsm_i64(ptr addrspace(3) %p, i64 %val) {
; CHECK-LABEL: @func store_gsm_i64
; CHECK: SSTW
  store i64 %val, ptr addrspace(3) %p
  ret void
}

;; ==================== DDR (addrspace 0) — baseline reference ====================

; i64 load from DDR (default address space)
define i64 @load_ddr_i64(ptr %p) {
; CHECK-LABEL: @func load_ddr_i64
; CHECK: SLDW
  %v = load i64, ptr %p
  ret i64 %v
}

; i64 store to DDR
define void @store_ddr_i64(ptr %p, i64 %val) {
; CHECK-LABEL: @func store_ddr_i64
; CHECK: SSTW
  store i64 %val, ptr %p
  ret void
}

;; ==================== SM/GSM Globals ====================

@sm_data_var = addrspace(2) global i64 42
; CHECK: @sect ".sm.data", sm_data_var, @b64, 42

@sm_bss_var = addrspace(2) global i64 0
; CHECK: @usect ".sm.bss", sm_bss_var, @b64, 1

@gsm_data_var = addrspace(3) global i64 100
; CHECK: @sect ".gsm.data", gsm_data_var, @b64, 100

@gsm_bss_var = addrspace(3) global i64 0
; CHECK: @usect ".gsm.bss", gsm_bss_var, @b64, 1

; DDR globals (baseline)
@ddr_data_var = global i64 77
; CHECK: @sect ".data", ddr_data_var, @b64, 77

@ddr_bss_var = global i64 0
; CHECK: @usect ".bss", ddr_bss_var, @b64, 1
