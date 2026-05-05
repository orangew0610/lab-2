// NOTE: Vector dot product kernel — VLDW, VFMULD, VSTW.
// RUN: clang --target=matrix -S -emit-llvm -O0 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O1 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O2 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O3 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
//
// Kernel: DOT  result = sum(x[i]*y[i])  (double precision, vectorized)
// Aligned with: labm/benchmark/XT4000/kernel/ddot_kernel.lan
//
// Exercises: VLDW vector load, VFMULD multiply, VSTW store.
// Note: Full dot product requires vector reduction (VMVCGC + scalar chain),
//       which is not expressible in C. This test covers the vectorized
//       element-wise multiply step.

typedef int vi32 __attribute__((ext_vector_type(32)));
typedef double vf64 __attribute__((ext_vector_type(16)));

// CHECK-LABEL: @func v_ddot_mul
// CHECK-DAG: VLDW
// CHECK-DAG: VFMULD
// CHECK-DAG: VSTW
void v_ddot_mul(long long addrX, long long addrY, long long addrOut) {
  vi32 rawX = __builtin_ftm_vldw(addrX, 0);
  vi32 rawY = __builtin_ftm_vldw(addrY, 0);
  vf64 vx = *(vf64 *)&rawX;
  vf64 vy = *(vf64 *)&rawY;
  vf64 prod = vx * vy;
  vi32 rawR = *(vi32 *)&prod;
  __builtin_ftm_vstw(rawR, addrOut, 0);
}
