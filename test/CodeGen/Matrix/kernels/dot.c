// NOTE: Dot product kernel — single loop, FP multiply-accumulate.
// RUN: clang --target=matrix -S -emit-llvm -O0 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O1 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O2 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O3 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
//
// Kernel: Dot Product
// result = sum(a[i] * b[i])  (double precision)
//
// Exercises: single loop, FP multiply-accumulate, memory load/store.

#define N 8

// CHECK-LABEL: @func dot
// CHECK-DAG: SLDW
// CHECK-DAG: SFMULAD
double dot(double *a, double *b) {
  double sum = 0.0;
  for (long i = 0; i < N; i++) {
    sum += a[i] * b[i];
  }
  return sum;
}
