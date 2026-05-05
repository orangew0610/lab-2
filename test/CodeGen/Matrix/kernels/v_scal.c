// NOTE: Vector SCAL kernel — VLDW, VFMULS32, VSTW.
// RUN: clang --target=matrix -S -emit-llvm -O0 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O1 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O2 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O3 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
//
// Kernel: SCAL  x = alpha * x  (single precision, vectorized)
// Aligned with: labm/benchmark/XT4000/kernel/sscal_kernel.lan
//
// Exercises: VLDW/VSTW vector memory, VFMULS32 element-wise multiply.

typedef int vi32 __attribute__((ext_vector_type(32)));
typedef float vf32 __attribute__((ext_vector_type(32)));

// CHECK-LABEL: @func v_sscal
// CHECK-DAG: VLDW
// CHECK-DAG: VFMULS32
// CHECK-DAG: VSTW
void v_sscal(long long addrX, long long addrY, long long addrOut) {
  vi32 rawX = __builtin_ftm_vldw(addrX, 0);
  vi32 rawY = __builtin_ftm_vldw(addrY, 0);
  vf32 vx = *(vf32 *)&rawX;
  vf32 vy = *(vf32 *)&rawY;
  vf32 result = vx * vy;
  vi32 rawR = *(vi32 *)&result;
  __builtin_ftm_vstw(rawR, addrOut, 0);
}
