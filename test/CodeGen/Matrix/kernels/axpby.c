// NOTE: AXPBY kernel — y = alpha*x + beta*y, dual FP multiply pattern.
// RUN: clang --target=matrix -S -emit-llvm -O0 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O1 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O2 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O3 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
//
// Kernel: AXPBY  y[i] = alpha * x[i] + beta * y[i]  (double precision)
//
// Exercises: two FP multiplies + FP add per iteration, memory load/store.

#define N 8

// CHECK-LABEL: @func axpby
// CHECK-DAG: SLDW
// CHECK-DAG: SFMULD
// CHECK-DAG: SFMULAD
// CHECK-DAG: SSTW
void axpby(double alpha, double *x, double beta, double *y) {
  for (long i = 0; i < N; i++) {
    y[i] = alpha * x[i] + beta * y[i];
  }
}
