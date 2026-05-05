// NOTE: GEMV kernel — double-nested loop, FP multiply-accumulate.
// RUN: clang --target=matrix -S -emit-llvm -O0 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O1 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O2 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O3 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
//
// Kernel: General Matrix-Vector Multiply (GEMV)
// y[i] += A[i][j] * x[j]  (double precision)
//
// Exercises: nested loops, pointer arithmetic, FP multiply-accumulate.

#define N 4

// CHECK-LABEL: @func gemv
// CHECK-DAG: SLDW
// CHECK-DAG: SFMULAD
// CHECK-DAG: SSTW
void gemv(double *A, double *x, double *y) {
  for (long i = 0; i < N; i++) {
    double sum = 0.0;
    for (long j = 0; j < N; j++) {
      sum += A[i * N + j] * x[j];
    }
    y[i] = sum;
  }
}
