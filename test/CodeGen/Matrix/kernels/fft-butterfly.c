// NOTE: FFT butterfly kernel — in-place add/subtract swap pattern.
// RUN: clang --target=matrix -S -emit-llvm -O0 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O1 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O2 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O3 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
//
// Kernel: FFT Butterfly  a[j] = a[j]+b[j], b[j] = a[j]-b[j]
//
// Exercises: interleaved FP add/subtract, paired memory access.

#define N 8

// CHECK-LABEL: @func fft_butterfly
// CHECK-DAG: SLDW
// CHECK-DAG: SFADDD
// CHECK-DAG: SFSUBD
// CHECK-DAG: SSTW
void fft_butterfly(double *a, double *b) {
  for (long j = 0; j < N; j++) {
    double t = a[j];
    a[j] = t + b[j];
    b[j] = t - b[j];
  }
}
