// NOTE: Integer sum reduction kernel — single loop accumulation.
// RUN: clang --target=matrix -S -emit-llvm -O0 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O1 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O2 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O3 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
//
// Kernel: Integer Sum Reduction
// result = sum(arr[i])  (i64)
//
// Exercises: loop, integer add, memory load, scalar accumulation.

#define N 16

// CHECK-LABEL: @func reduction
// CHECK-DAG: SLDW
// CHECK-DAG: SADD
long reduction(long *arr) {
  long sum = 0;
  for (long i = 0; i < N; i++) {
    sum += arr[i];
  }
  return sum;
}
