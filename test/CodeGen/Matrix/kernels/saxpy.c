// NOTE: SAXPY kernel — scalar broadcast, FP multiply-accumulate.
// RUN: clang --target=matrix -S -emit-llvm -O0 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O1 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O2 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O3 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
//
// Kernel: SAXPY  y[i] = a * x[i] + y[i]  (double precision)
//
// Exercises: scalar broadcast, FP multiply-accumulate, memory load/store.

#define N 8

// CHECK-LABEL: @func saxpy
// CHECK-DAG: SLDW
// CHECK-DAG: SFMULAD
// CHECK-DAG: SSTW
void saxpy(double a, double *x, double *y) {
  for (long i = 0; i < N; i++) {
    y[i] = a * x[i] + y[i];
  }
}
