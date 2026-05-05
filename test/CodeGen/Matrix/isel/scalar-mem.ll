; NOTE: Scalar memory access instruction selection tests
; RUN: llc -march=matrix -o - %s | FileCheck %s

;; ===================================================================
;; Scalar memory access instruction selection tests
;;
;; Instructions tested:
;;   SLDW/SLDH/SLDHU/SLDDB/SLDDBU/SLDB/SLDBU - scalar loads
;;   SSTW/SSTH/SSTDB/SSTB - scalar stores
;; ===================================================================

;; ==================== Scalar Loads ====================

; Test i64 load (SLDW)
define i64 @test_load_i64(ptr %p) {
; CHECK-LABEL: @func test_load_i64
; CHECK: SLDW
  %val = load i64, ptr %p
  ret i64 %val
}

; Test i32 sign-extending load (SLDH)
define i64 @test_load_sext_i32(ptr %p) {
; CHECK-LABEL: @func test_load_sext_i32
; CHECK: SLDH
  %val = load i32, ptr %p
  %ext = sext i32 %val to i64
  ret i64 %ext
}

; Test i32 zero-extending load (SLDHU)
define i64 @test_load_zext_i32(ptr %p) {
; CHECK-LABEL: @func test_load_zext_i32
; CHECK: SLDHU
  %val = load i32, ptr %p
  %ext = zext i32 %val to i64
  ret i64 %ext
}

; Test i16 sign-extending load (SLDDB)
define i64 @test_load_sext_i16(ptr %p) {
; CHECK-LABEL: @func test_load_sext_i16
; CHECK: SLDDB
  %val = load i16, ptr %p
  %ext = sext i16 %val to i64
  ret i64 %ext
}

; Test i16 zero-extending load (SLDDBU)
define i64 @test_load_zext_i16(ptr %p) {
; CHECK-LABEL: @func test_load_zext_i16
; CHECK: SLDDBU
  %val = load i16, ptr %p
  %ext = zext i16 %val to i64
  ret i64 %ext
}

; Test i8 sign-extending load (SLDB)
define i64 @test_load_sext_i8(ptr %p) {
; CHECK-LABEL: @func test_load_sext_i8
; CHECK: SLDB
  %val = load i8, ptr %p
  %ext = sext i8 %val to i64
  ret i64 %ext
}

; Test i8 zero-extending load (SLDBU)
define i64 @test_load_zext_i8(ptr %p) {
; CHECK-LABEL: @func test_load_zext_i8
; CHECK: SLDBU
  %val = load i8, ptr %p
  %ext = zext i8 %val to i64
  ret i64 %ext
}

; Test f64 load (SLDW)
define double @test_load_f64(ptr %p) {
; CHECK-LABEL: @func test_load_f64
; CHECK: SLDW
  %val = load double, ptr %p
  ret double %val
}

; Test address syntax with *+ar notation
define i64 @test_load_addr_syntax(ptr %p) {
; CHECK-LABEL: @func test_load_addr_syntax
; CHECK: *+ar
  %val = load i64, ptr %p
  ret i64 %val
}

;; ==================== Scalar Stores ====================

; Test i64 store (SSTW)
define void @test_store_i64(i64 %val, ptr %p) {
; CHECK-LABEL: @func test_store_i64
; CHECK: SSTW
  store i64 %val, ptr %p
  ret void
}

; Test i32 truncating store (SSTH)
define void @test_store_trunc_i32(i64 %val, ptr %p) {
; CHECK-LABEL: @func test_store_trunc_i32
; CHECK: SSTH
  %trunc = trunc i64 %val to i32
  store i32 %trunc, ptr %p
  ret void
}

; Test i16 truncating store (SSTDB)
define void @test_store_trunc_i16(i64 %val, ptr %p) {
; CHECK-LABEL: @func test_store_trunc_i16
; CHECK: SSTDB
  %trunc = trunc i64 %val to i16
  store i16 %trunc, ptr %p
  ret void
}

; Test i8 truncating store (SSTB)
define void @test_store_trunc_i8(i64 %val, ptr %p) {
; CHECK-LABEL: @func test_store_trunc_i8
; CHECK: SSTB
  %trunc = trunc i64 %val to i8
  store i8 %trunc, ptr %p
  ret void
}

; Test f64 store (SSTW)
define void @test_store_f64(double %val, ptr %p) {
; CHECK-LABEL: @func test_store_f64
; CHECK: SSTW
  store double %val, ptr %p
  ret void
}

; Test address syntax with *+ar notation
define void @test_store_addr_syntax(i64 %val, ptr %p) {
; CHECK-LABEL: @func test_store_addr_syntax
; CHECK: *+ar
  store i64 %val, ptr %p
  ret void
}
