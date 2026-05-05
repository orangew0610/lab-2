; RUN: llc -march=matrix -o - %s | FileCheck %s

target triple = "matrix-unknown-unknown"

;; Vector load/store: VLDW / VSTW

; CHECK-LABEL: @func test_vload_vstore
; CHECK: VLDW
; CHECK: VSTW
define void @test_vload_vstore(ptr %src, ptr %dst) {
  %v = load <32 x float>, ptr %src
  store <32 x float> %v, ptr %dst
  ret void
}

; CHECK-LABEL: @func test_vload_v16f64
; CHECK: VLDW
; CHECK: VSTW
define void @test_vload_v16f64(ptr %src, ptr %dst) {
  %v = load <16 x double>, ptr %src
  store <16 x double> %v, ptr %dst
  ret void
}

; CHECK-LABEL: @func test_vload_v32i32
; CHECK: VLDW
; CHECK: VSTW
define void @test_vload_v32i32(ptr %src, ptr %dst) {
  %v = load <32 x i32>, ptr %src
  store <32 x i32> %v, ptr %dst
  ret void
}

; CHECK-LABEL: @func test_vload_v16i64
; CHECK: VLDW
; CHECK: VSTW
define void @test_vload_v16i64(ptr %src, ptr %dst) {
  %v = load <16 x i64>, ptr %src
  store <16 x i64> %v, ptr %dst
  ret void
}

;; EXTRACT_VECTOR_ELT: SVR-based extraction (VMVCGC + SMVCCG)
;; No vector memory ops — vector load/store can only access AM, not stack/DDR.

; CHECK-LABEL: @func test_extract_v32f32
; CHECK:       VMVCGC v{{[0-9]+}}, SVR
; CHECK:       SMVCCG SVR
; CHECK:       SBALE2H
; CHECK-NOT:   VSTW
define float @test_extract_v32f32(ptr %src) {
  %v = load <32 x float>, ptr %src
  %e = extractelement <32 x float> %v, i32 5
  ret float %e
}

; CHECK-LABEL: @func test_extract_v16f64
; CHECK:       VMVCGC v{{[0-9]+}}, SVR
; CHECK:       SMVCCG SVR
; CHECK-NOT:   VSTW
define double @test_extract_v16f64(ptr %src) {
  %v = load <16 x double>, ptr %src
  %e = extractelement <16 x double> %v, i32 3
  ret double %e
}

; CHECK-LABEL: @func test_extract_v32i32
; CHECK:       VMVCGC v{{[0-9]+}}, SVR
; CHECK:       SMVCCG SVR
; CHECK:       SBALE2H
; CHECK-NOT:   VSTW
define i32 @test_extract_v32i32(ptr %src) {
  %v = load <32 x i32>, ptr %src
  %e = extractelement <32 x i32> %v, i32 7
  ret i32 %e
}

;; INSERT_VECTOR_ELT: load vector from memory, insert, store back

; CHECK-LABEL: @func test_insert_v32f32
; CHECK: VSTW
; CHECK: SST
; CHECK: VLDW
define void @test_insert_v32f32(ptr %src, ptr %dst, float %val) {
  %v = load <32 x float>, ptr %src
  %r = insertelement <32 x float> %v, float %val, i32 3
  store <32 x float> %r, ptr %dst
  ret void
}

; CHECK-LABEL: @func test_insert_v16f64
; CHECK: VSTW
; CHECK: SSTW
; CHECK: VLDW
define void @test_insert_v16f64(ptr %src, ptr %dst, double %val) {
  %v = load <16 x double>, ptr %src
  %r = insertelement <16 x double> %v, double %val, i32 3
  store <16 x double> %r, ptr %dst
  ret void
}

; CHECK-LABEL: @func test_extract_v16i64
; CHECK:       VMVCGC v{{[0-9]+}}, SVR
; CHECK:       SMVCCG SVR
; CHECK-NOT:   VSTW
define i64 @test_extract_v16i64(ptr %src) {
  %v = load <16 x i64>, ptr %src
  %e = extractelement <16 x i64> %v, i32 3
  ret i64 %e
}

; CHECK-LABEL: @func test_insert_v32i32
; CHECK: VSTW
; CHECK: SST
; CHECK: VLDW
define void @test_insert_v32i32(ptr %src, ptr %dst, i32 %val) {
  %v = load <32 x i32>, ptr %src
  %r = insertelement <32 x i32> %v, i32 %val, i32 3
  store <32 x i32> %r, ptr %dst
  ret void
}

; CHECK-LABEL: @func test_insert_v16i64
; CHECK: VSTW
; CHECK: SSTW
; CHECK: VLDW
define void @test_insert_v16i64(ptr %src, ptr %dst, i64 %val) {
  %v = load <16 x i64>, ptr %src
  %r = insertelement <16 x i64> %v, i64 %val, i32 3
  store <16 x i64> %r, ptr %dst
  ret void
}

;; BUILD_VECTOR non-splat: store each element to stack + VLDW

; CHECK-LABEL: @func test_build_v32f32_nonsplat
; CHECK: SST
; CHECK: VLDW
define void @test_build_v32f32_nonsplat(ptr %dst, float %a, float %b) {
  %v0 = insertelement <32 x float> undef, float %a, i32 0
  %v1 = insertelement <32 x float> %v0, float %b, i32 1
  %v2 = insertelement <32 x float> %v1, float %a, i32 2
  %v3 = insertelement <32 x float> %v2, float %b, i32 3
  %v4 = insertelement <32 x float> %v3, float %a, i32 4
  %v5 = insertelement <32 x float> %v4, float %b, i32 5
  %v6 = insertelement <32 x float> %v5, float %a, i32 6
  %v7 = insertelement <32 x float> %v6, float %b, i32 7
  %v8 = insertelement <32 x float> %v7, float %a, i32 8
  %v9 = insertelement <32 x float> %v8, float %b, i32 9
  %v10 = insertelement <32 x float> %v9, float %a, i32 10
  %v11 = insertelement <32 x float> %v10, float %b, i32 11
  %v12 = insertelement <32 x float> %v11, float %a, i32 12
  %v13 = insertelement <32 x float> %v12, float %b, i32 13
  %v14 = insertelement <32 x float> %v13, float %a, i32 14
  %v15 = insertelement <32 x float> %v14, float %b, i32 15
  %v16 = insertelement <32 x float> %v15, float %a, i32 16
  %v17 = insertelement <32 x float> %v16, float %b, i32 17
  %v18 = insertelement <32 x float> %v17, float %a, i32 18
  %v19 = insertelement <32 x float> %v18, float %b, i32 19
  %v20 = insertelement <32 x float> %v19, float %a, i32 20
  %v21 = insertelement <32 x float> %v20, float %b, i32 21
  %v22 = insertelement <32 x float> %v21, float %a, i32 22
  %v23 = insertelement <32 x float> %v22, float %b, i32 23
  %v24 = insertelement <32 x float> %v23, float %a, i32 24
  %v25 = insertelement <32 x float> %v24, float %b, i32 25
  %v26 = insertelement <32 x float> %v25, float %a, i32 26
  %v27 = insertelement <32 x float> %v26, float %b, i32 27
  %v28 = insertelement <32 x float> %v27, float %a, i32 28
  %v29 = insertelement <32 x float> %v28, float %b, i32 29
  %v30 = insertelement <32 x float> %v29, float %a, i32 30
  %v31 = insertelement <32 x float> %v30, float %b, i32 31
  store <32 x float> %v31, ptr %dst
  ret void
}

;; BUILD_VECTOR splat: should use VMOVI or SVBCAST

; CHECK-LABEL: @func test_build_v32f32_splat
; CHECK: {{VMOVI|SVBCAST}}
define void @test_build_v32f32_splat(ptr %dst, float %val) {
  %v0 = insertelement <32 x float> undef, float %val, i32 0
  %v = shufflevector <32 x float> %v0, <32 x float> undef,
       <32 x i32> zeroinitializer
  store <32 x float> %v, ptr %dst
  ret void
}

;; <1 x float> scalarization: should be auto-scalarized

; CHECK-LABEL: @func test_v1f32_insert
; CHECK-NOT: VLDW
; CHECK-NOT: VSTW
define <1 x float> @test_v1f32_insert(<1 x float> %v, float %val) {
  %r = insertelement <1 x float> %v, float %val, i64 0
  ret <1 x float> %r
}

;; Vector fadd with load/store integration test

; CHECK-LABEL: @func test_vector_fadd_v32f32
; CHECK: VLDW
; CHECK: VFADDS32
; CHECK: VSTW
define void @test_vector_fadd_v32f32(ptr %src1, ptr %src2, ptr %dst) {
  %a = load <32 x float>, ptr %src1
  %b = load <32 x float>, ptr %src2
  %c = fadd <32 x float> %a, %b
  store <32 x float> %c, ptr %dst
  ret void
}
