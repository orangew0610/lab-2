// NOTE: Fibonacci kernel — recursion, branches, integer arithmetic.
// RUN: clang --target=matrix -S -emit-llvm -O0 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O1 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O2 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O3 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
//
// Kernel: Fibonacci (recursive + iterative)
// Exercises: recursion (@call), branches (SBR), comparisons, integer arithmetic.

// --- Recursive ---

// CHECK-LABEL: @func fib_recursive
// CHECK-DAG: @call fib_recursive
// CHECK-DAG: SADD
long fib_recursive(long n) {
  if (n <= 1)
    return n;
  return fib_recursive(n - 1) + fib_recursive(n - 2);
}

// --- Iterative ---

// CHECK-LABEL: @func fib_iterative
// CHECK-DAG: SADD
long fib_iterative(long n) {
  long a = 0, b = 1;
  for (long i = 0; i < n; i++) {
    long t = a + b;
    a = b;
    b = t;
  }
  return a;
}
