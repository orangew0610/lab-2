// NOTE: SCAL kernel — vector scale x = alpha*x, in-place FP multiply.
// RUN: clang --target=matrix -S -emit-llvm -O0 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O1 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O2 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O3 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
//
// Kernel: SCAL  x[i] = alpha * x[i]  (double precision)
//
// Exercises: scalar broadcast multiply, memory load/store.

#define N 8

// CHECK-LABEL: @func scal
// CHECK-DAG: SLDW
// CHECK-DAG: SFMULD
// CHECK-DAG: SSTW
void scal(double alpha, double *x) {
  for (long i = 0; i < N; i++) {
    x[i] = alpha * x[i];
  }
}
