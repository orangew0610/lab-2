// NOTE: C++ ABI tests for name mangling, namespaces, and references.
// RUN: clang++ --target=matrix -x c++ -S -emit-llvm -O0 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang++ --target=matrix -x c++ -S -emit-llvm -O1 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang++ --target=matrix -x c++ -S -emit-llvm -O2 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
// RUN: clang++ --target=matrix -x c++ -S -emit-llvm -O3 -o - %s | llc -mtriple=matrix -o - | FileCheck %s
//
// End-to-end C++ tests: C++ source -> Clang++ -> LLVM IR -> llc -> LASM assembly
// Verifies C++ name mangling, namespaces, references, and extern "C" linkage.

// ===== extern "C" (no mangling) =====

// CHECK-LABEL: @func c_linkage_add
// CHECK: SADD
extern "C" long c_linkage_add(long a, long b) { return a + b; }

// ===== Namespace + mangled name =====

namespace math {
// CHECK-LABEL: @func _ZN4math3mulEll
// CHECK: SMULIU
__attribute__((noinline))
long mul(long a, long b) { return a * b; }
} // namespace math

// ===== Reference parameters =====

// CHECK-LABEL: @func _ZN4math8ref_swapERlS0_
// CHECK: SLDW
// CHECK: SSTW
namespace math {
void ref_swap(long &a, long &b) {
  long t = a;
  a = b;
  b = t;
}
} // namespace math

// ===== Cross-function call (C++ mangled) =====

// CHECK-LABEL: @func _Z8call_mulll
// CHECK: @call _ZN4math3mulEll
long call_mul(long a, long b) { return math::mul(a, b); }

// ===== Struct parameter (passed by pointer) =====

struct Point {
  long x;
  long y;
};

// CHECK-LABEL: @func _Z9point_addPK5PointS1_
// CHECK: SLDW
// CHECK: SADD
Point point_add(const Point *a, const Point *b) {
  Point r;
  r.x = a->x + b->x;
  r.y = a->y + b->y;
  return r;
}

// ===== Ternary with floating-point =====

// CHECK-LABEL: @func _Z6fp_maxdd
// CHECK: SFCMPGD
double fp_max(double a, double b) { return (a > b) ? a : b; }

// ===== Static local computation =====

// CHECK-LABEL: @func _Z11compute_sumii
// CHECK: SADD32
int compute_sum(int a, int b) {
  int result = a + b;
  return result;
}
