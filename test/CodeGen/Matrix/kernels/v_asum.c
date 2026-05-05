// NOTE: Vector ASUM kernel — VLDW, VFCMPGD, VFADDD, VSTW.
// RUN: clang --target=matrix -S -emit-llvm -O0 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O1 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O2 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O3 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
//
// Kernel: ASUM  result = sum(|x[i]|)  (double precision, vectorized)
// Aligned with: labm/benchmark/XT4000/kernel/dasum_kernel.lan
//
// Exercises: VLDW vector load, VFCMPGD compare, VFADDD accumulate.
// Note: VFABSD maps from llvm.fabs on v16f64 but is hard to express in C
//       without __builtin_elementwise_abs; we test the compare path instead.
//       Full reduction requires VMVCGC (not expressible in C).

typedef int vi32 __attribute__((ext_vector_type(32)));
typedef double vf64 __attribute__((ext_vector_type(16)));

// v_dasum_cmp: compare elements (part of absolute value computation)
// CHECK-LABEL: @func v_dasum_cmp
// CHECK-DAG: VLDW
// CHECK-DAG: VFCMPGD
// CHECK-DAG: VSTW
void v_dasum_cmp(long long addrX, long long addrZero, long long addrOut) {
  vi32 rawX = __builtin_ftm_vldw(addrX, 0);
  vi32 rawZ = __builtin_ftm_vldw(addrZero, 0);
  vi32 mask = __builtin_ftm_vfcmpgd(rawX, rawZ);
  __builtin_ftm_vstw(mask, addrOut, 0);
}

// v_dasum_acc: accumulate absolute values
// CHECK-LABEL: @func v_dasum_acc
// CHECK-DAG: VLDW
// CHECK-DAG: VFADDD
// CHECK-DAG: VSTW
void v_dasum_acc(long long addrA, long long addrB, long long addrOut) {
  vi32 rawA = __builtin_ftm_vldw(addrA, 0);
  vi32 rawB = __builtin_ftm_vldw(addrB, 0);
  vf64 va = *(vf64 *)&rawA;
  vf64 vb = *(vf64 *)&rawB;
  vf64 sum = va + vb;
  vi32 rawR = *(vi32 *)&sum;
  __builtin_ftm_vstw(rawR, addrOut, 0);
}
