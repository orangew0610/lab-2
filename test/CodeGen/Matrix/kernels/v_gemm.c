// NOTE: Vector GEMM kernel — VLDDW/VSTDW, VFMULAD, VSTW.
// RUN: clang --target=matrix -S -emit-llvm -O0 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O1 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O2 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O3 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
//
// Kernel: GEMM  C += A_col * B_row  (double precision, vectorized)
// Aligned with: labm/benchmark/XT4000/kernel/dgemm_kernel.lan
//
// Exercises: VLDDW/VSTDW double-width vector memory, VFMULAD FMA.

typedef long long vdi64 __attribute__((ext_vector_type(32)));
typedef double vf64 __attribute__((ext_vector_type(16)));
typedef int vi32 __attribute__((ext_vector_type(32)));

// v_dgemm_copy: double-width vector load/store
// CHECK-LABEL: @func v_dgemm_copy
// CHECK-DAG: VLDDW
// CHECK-DAG: VSTDW
void v_dgemm_copy(long long addrIn, long long addrOut) {
  vdi64 data = __builtin_ftm_vlddw(addrIn, 0);
  __builtin_ftm_vstdw(data, addrOut, 0);
}

// v_dgemm_fma: double-precision FMA (2 loads only to avoid register pressure)
// CHECK-LABEL: @func v_dgemm_fma
// CHECK-DAG: VLDW
// CHECK-DAG: VFMULAD
// CHECK-DAG: VSTW
void v_dgemm_fma(long long addrA, long long addrB, long long addrOut) {
  vi32 rawA = __builtin_ftm_vldw(addrA, 0);
  vi32 rawB = __builtin_ftm_vldw(addrB, 0);
  vf64 a = *(vf64 *)&rawA;
  vf64 b = *(vf64 *)&rawB;
  vf64 result = a * b + b;      // FMA: a*b + b
  vi32 rawR = *(vi32 *)&result;
  __builtin_ftm_vstw(rawR, addrOut, 0);
}
