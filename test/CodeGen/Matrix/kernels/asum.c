// NOTE: ASUM kernel — sum of absolute values, FP compare and negate.
// RUN: clang --target=matrix -S -emit-llvm -O0 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O1 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O2 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O3 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
//
// Kernel: ASUM  result = sum(|x[i]|)  (double precision)
//
// Exercises: FP comparison, conditional negate (SXOR sign bit), FP accumulate.

#define N 8

// CHECK-LABEL: @func asum
// CHECK-DAG: SLDW
// CHECK-DAG: SFCMPLD
// CHECK-DAG: SXOR
// CHECK-DAG: SFADDD
double asum(double *x) {
  double sum = 0.0;
  for (long i = 0; i < N; i++) {
    sum += (x[i] < 0.0) ? -x[i] : x[i];
  }
  return sum;
}
