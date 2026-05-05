// NOTE: Vector FFT butterfly kernel — VLDW, VFADDS32, VFSUBS32, VSTW.
// RUN: clang --target=matrix -S -emit-llvm -O0 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O1 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O2 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O3 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
//
// Kernel: FFT butterfly  sum = a+b, diff = a-b  (single precision, vectorized)
// Aligned with: labm/benchmark/XT4000/kernel/sfft_col_kernel.lan
//
// Exercises: VLDW/VSTW vector memory, VFADDS32 add, VFSUBS32 subtract.
// Note: Two vstw in one function crashes llc at -O0 (backend limitation),
//       so add and sub are tested in separate functions.

typedef int vi32 __attribute__((ext_vector_type(32)));
typedef float vf32 __attribute__((ext_vector_type(32)));

// CHECK-LABEL: @func v_fft_add
// CHECK-DAG: VLDW
// CHECK-DAG: VFADDS32
// CHECK-DAG: VSTW
void v_fft_add(long long addrA, long long addrB, long long addrOut) {
  vi32 rawA = __builtin_ftm_vldw(addrA, 0);
  vi32 rawB = __builtin_ftm_vldw(addrB, 0);
  vf32 a = *(vf32 *)&rawA;
  vf32 b = *(vf32 *)&rawB;
  vf32 sum = a + b;
  vi32 rawR = *(vi32 *)&sum;
  __builtin_ftm_vstw(rawR, addrOut, 0);
}

// CHECK-LABEL: @func v_fft_sub
// CHECK-DAG: VLDW
// CHECK-DAG: VFSUBS32
// CHECK-DAG: VSTW
void v_fft_sub(long long addrA, long long addrB, long long addrOut) {
  vi32 rawA = __builtin_ftm_vldw(addrA, 0);
  vi32 rawB = __builtin_ftm_vldw(addrB, 0);
  vf32 a = *(vf32 *)&rawA;
  vf32 b = *(vf32 *)&rawB;
  vf32 diff = a - b;
  vi32 rawR = *(vi32 *)&diff;
  __builtin_ftm_vstw(rawR, addrOut, 0);
}
