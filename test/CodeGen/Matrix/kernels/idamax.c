// NOTE: IDAMAX kernel — index of max absolute value, FP compare and branch.
// RUN: clang --target=matrix -S -emit-llvm -O0 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O1 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O2 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O3 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
//
// Kernel: IDAMAX  idx = argmax(|x[i]|)  (double precision)
//
// Exercises: FP absolute value (sign-bit XOR), FP comparison, conditional
//            branch, index tracking.

#define N 8

// CHECK-LABEL: @func idamax
// CHECK-DAG: SLDW
// CHECK-DAG: SFCMPLD
// CHECK-DAG: SFCMPGD
// CHECK-DAG: SXOR
long idamax(double *x) {
  long idx = 0;
  double maxval = 0.0;
  for (long i = 0; i < N; i++) {
    double v = (x[i] < 0.0) ? -x[i] : x[i];
    if (v > maxval) {
      maxval = v;
      idx = i;
    }
  }
  return idx;
}
