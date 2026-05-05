; NOTE: Address space constraint validation tests
; RUN: llc -march=matrix -o - %s | FileCheck %s

;; ===================================================================
;; Address space constraint validation
;;
;; Verifies that loads/stores with valid offsets in SM/GSM/DDR address
;; spaces compile correctly.
;; ===================================================================

target triple = "matrix-unknown-unknown"

;; ==================== SM (addrspace 2) — valid offset ====================

; SM load with small offset (within 128KB)
define i64 @load_sm_valid_offset(ptr addrspace(2) %p) {
; CHECK-LABEL: @func load_sm_valid_offset
; CHECK: SLD
  %gep = getelementptr i8, ptr addrspace(2) %p, i64 1024
  %v = load i64, ptr addrspace(2) %gep
  ret i64 %v
}

; SM store with small offset
define void @store_sm_valid_offset(ptr addrspace(2) %p, i64 %val) {
; CHECK-LABEL: @func store_sm_valid_offset
; CHECK: SST
  %gep = getelementptr i8, ptr addrspace(2) %p, i64 512
  store i64 %val, ptr addrspace(2) %gep
  ret void
}

;; ==================== GSM (addrspace 3) — valid offset ====================

; GSM load with medium offset (within 16MB)
define i64 @load_gsm_valid_offset(ptr addrspace(3) %p) {
; CHECK-LABEL: @func load_gsm_valid_offset
; CHECK: SLD
  %gep = getelementptr i8, ptr addrspace(3) %p, i64 4096
  %v = load i64, ptr addrspace(3) %gep
  ret i64 %v
}

;; ==================== DDR (addrspace 0) — valid offset ====================

; DDR load with offset
define i64 @load_ddr_valid_offset(ptr %p) {
; CHECK-LABEL: @func load_ddr_valid_offset
; CHECK: SLD
  %gep = getelementptr i8, ptr %p, i64 256
  %v = load i64, ptr %gep
  ret i64 %v
}
