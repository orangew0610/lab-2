// NOTE: GEMM kernel — triple-nested loop, FP multiply-accumulate.
// RUN: clang --target=matrix -S -emit-llvm -O0 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O1 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O2 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O3 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
//
// Kernel: General Matrix Multiply (GEMM)
// C[i][j] += A[i][k] * B[k][j]  (double precision, NxN)
//
// Exercises: nested loops, array indexing, FP multiply-accumulate, memory ops.

#define N 4

// CHECK-LABEL: @func gemm
// CHECK-DAG: SLDW
// CHECK-DAG: SFMULAD
// CHECK-DAG: SSTW
void gemm(double *A, double *B, double *C) {
  for (long i = 0; i < N; i++) {
    for (long j = 0; j < N; j++) {
      double sum = 0.0;
      for (long k = 0; k < N; k++) {
        sum += A[i * N + k] * B[k * N + j];
      }
      C[i * N + j] = sum;
    }
  }
}
