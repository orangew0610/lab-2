// NOTE: Vector AXPBY kernel — VLDW, VFMULS32, VFMULAS32, VSTW.
// RUN: clang --target=matrix -S -emit-llvm -O0 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O1 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O2 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O3 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
//
// Kernel: AXPBY  y = alpha*x + beta*y  (single precision, vectorized)
// Aligned with: labm/benchmark/XT4000/kernel/saxpby_kernel.lan
//
// Exercises: VLDW/VSTW vector memory, VFMULS32 multiply, VFMULAS32 FMA.

typedef int vi32 __attribute__((ext_vector_type(32)));
typedef float vf32 __attribute__((ext_vector_type(32)));

// CHECK-LABEL: @func v_saxpby
// CHECK-DAG: VLDW
// CHECK-DAG: VFMULAS32
// CHECK-DAG: VSTW
void v_saxpby(long long addrX, long long addrY, long long addrOut) {
  vi32 rawX = __builtin_ftm_vldw(addrX, 0);
  vi32 rawY = __builtin_ftm_vldw(addrY, 0);
  vf32 vx = *(vf32 *)&rawX;
  vf32 vy = *(vf32 *)&rawY;
  vf32 result = vx * vy + vy;   // FMA: x*y + y
  vi32 rawR = *(vi32 *)&result;
  __builtin_ftm_vstw(rawR, addrOut, 0);
}
