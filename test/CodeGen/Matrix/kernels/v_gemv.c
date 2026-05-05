// NOTE: Vector GEMV kernel — VLDW, VFMULAS32, VSTW.
// RUN: clang --target=matrix -S -emit-llvm -O0 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O1 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O2 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O3 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
//
// Kernel: GEMV  y += A_row * x  (single precision, vectorized)
// Aligned with: labm/benchmark/XT4000/kernel/sgemv_0_kernel.lan
//
// Exercises: VLDW load matrix row and vector, VFMULAS32 FMA accumulate.

typedef int vi32 __attribute__((ext_vector_type(32)));
typedef float vf32 __attribute__((ext_vector_type(32)));

// CHECK-LABEL: @func v_sgemv_fma
// CHECK-DAG: VLDW
// CHECK-DAG: VFMULAS32
// CHECK-DAG: VSTW
void v_sgemv_fma(long long addrRow, long long addrX, long long addrOut) {
  vi32 rawRow = __builtin_ftm_vldw(addrRow, 0);
  vi32 rawX = __builtin_ftm_vldw(addrX, 0);
  vf32 row = *(vf32 *)&rawRow;
  vf32 x = *(vf32 *)&rawX;
  vf32 result = row * x + x;    // FMA: row*x + x
  vi32 rawR = *(vi32 *)&result;
  __builtin_ftm_vstw(rawR, addrOut, 0);
}
