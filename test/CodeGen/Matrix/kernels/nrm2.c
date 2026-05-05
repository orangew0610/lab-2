// NOTE: NRM2 kernel — squared Euclidean norm, self-multiply accumulate.
// RUN: clang --target=matrix -S -emit-llvm -O0 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O1 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O2 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O3 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
//
// Kernel: NRM2  result = sum(x[i] * x[i])  (double precision)
//
// Exercises: FP multiply-accumulate with same operand, single loop.

#define N 8

// CHECK-LABEL: @func nrm2
// CHECK-DAG: SLDW
// CHECK-DAG: SFMULAD
double nrm2(double *x) {
  double sum = 0.0;
  for (long i = 0; i < N; i++) {
    sum += x[i] * x[i];
  }
  return sum;
}
