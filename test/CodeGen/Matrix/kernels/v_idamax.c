// NOTE: Vector IDAMAX kernel — VLDW, VFCMPGD, VSTW.
// RUN: clang --target=matrix -S -emit-llvm -O0 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O1 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O2 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O3 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
//
// Kernel: IDAMAX  find element-wise max  (double precision, vectorized)
// Aligned with: labm/benchmark/XT4000/kernel/idamax_kernel.lan
//
// Exercises: VLDW load, VFCMPGD compare, VSTW store.
// Note: Full IDAMAX requires VFABSD + conditional VMOV + scalar reduction;
//       this tests the vectorized compare-greater step.

typedef int vi32 __attribute__((ext_vector_type(32)));

// CHECK-LABEL: @func v_idamax_cmpg
// CHECK-DAG: VLDW
// CHECK-DAG: VFCMPGD
// CHECK-DAG: VSTW
void v_idamax_cmpg(long long addrX, long long addrMax, long long addrOut) {
  vi32 rawX = __builtin_ftm_vldw(addrX, 0);
  vi32 rawMax = __builtin_ftm_vldw(addrMax, 0);
  vi32 mask = __builtin_ftm_vfcmpgd(rawX, rawMax);
  __builtin_ftm_vstw(mask, addrOut, 0);
}
