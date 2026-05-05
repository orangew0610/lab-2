// NOTE: Target-specific builtin intrinsic tests for Matrix backend.
// RUN: clang --target=matrix -S -emit-llvm -o - %s | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O1 -o - %s | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O2 -o - %s | FileCheck %s
// RUN: clang --target=matrix -S -emit-llvm -O3 -o - %s | FileCheck %s

typedef int vi32 __attribute__((ext_vector_type(32)));
typedef long long vi64_16 __attribute__((ext_vector_type(16)));
typedef long long vi64_32 __attribute__((ext_vector_type(32)));
typedef float vf32 __attribute__((ext_vector_type(32)));
typedef double vf64 __attribute__((ext_vector_type(16)));
typedef int v2i32 __attribute__((ext_vector_type(2)));

// --- Vector Memory ---

// CHECK-LABEL: @test_vldw(
// CHECK: inttoptr
// CHECK: call <32 x i32> @llvm.ftm.vldw(ptr addrspace(1) %{{.*}}, i64 %{{.*}})
vi32 test_vldw(long long base, long long off) {
  return __builtin_ftm_vldw(base, off);
}

// CHECK-LABEL: @test_vstw(
// CHECK: inttoptr
// CHECK: call void @llvm.ftm.vstw(<32 x i32> %{{.*}}, ptr addrspace(1) %{{.*}}, i64 %{{.*}})
void test_vstw(vi32 data, long long base, long long off) {
  __builtin_ftm_vstw(data, base, off);
}

// CHECK-LABEL: @test_vlddw(
// CHECK: inttoptr
// CHECK: call <32 x i64> @llvm.ftm.vlddw(ptr addrspace(1) %{{.*}}, i64 %{{.*}})
vi64_32 test_vlddw(long long base, long long off) {
  return __builtin_ftm_vlddw(base, off);
}

// --- Vector FP Compare ---

// CHECK-LABEL: @test_vfcmped(
// CHECK: call <32 x i32> @llvm.ftm.vfcmped(<32 x i32> %{{.*}}, <32 x i32> %{{.*}})
vi32 test_vfcmped(vi32 a, vi32 b) {
  return __builtin_ftm_vfcmped(a, b);
}

// --- Precision Conversion ---

// CHECK-LABEL: @test_vfdpsp32(
// CHECK: call <32 x float> @llvm.ftm.vfdpsp32(<16 x double> %{{.*}}, <16 x double> %{{.*}})
vf32 test_vfdpsp32(vf64 a, vf64 b) {
  return __builtin_ftm_vfdpsp32(a, b);
}

// --- Reciprocal ---

// CHECK-LABEL: @test_vfrcpd(
// CHECK: call <16 x double> @llvm.ftm.vfrcpd(<16 x double> %{{.*}})
vf64 test_vfrcpd(vf64 a) {
  return __builtin_ftm_vfrcpd(a);
}

// --- Compare All (scalar return) ---

// CHECK-LABEL: @test_vfcmped_all(
// CHECK: call i64 @llvm.ftm.vfcmped.all(<32 x i32> %{{.*}}, <32 x i32> %{{.*}})
long long test_vfcmped_all(vi32 a, vi32 b) {
  return __builtin_ftm_vfcmped_all(a, b);
}

// --- Control Flow ---

// CHECK-LABEL: @test_smfence(
// CHECK: call void @llvm.ftm.smfence()
void test_smfence(void) {
  __builtin_ftm_smfence();
}

// --- Integer Compare ---

// CHECK-LABEL: @test_veq(
// CHECK: call <16 x i64> @llvm.ftm.veq(<16 x i64> %{{.*}}, <16 x i64> %{{.*}})
vi64_16 test_veq(vi64_16 a, vi64_16 b) {
  return __builtin_ftm_veq(a, b);
}

// --- Conditional Subtract-Shift ---

// CHECK-LABEL: @test_ssubc(
// CHECK: call i64 @llvm.ftm.ssubc(i64 %{{.*}}, i64 %{{.*}})
long long test_ssubc(long long a, long long b) {
  return __builtin_ftm_ssubc(a, b);
}

// --- Bit Manipulation ---

// CHECK-LABEL: @test_vbset(
// CHECK: call <16 x i64> @llvm.ftm.vbset(<16 x i64> %{{.*}}, <16 x i64> %{{.*}})
vi64_16 test_vbset(vi64_16 pos, vi64_16 data) {
  return __builtin_ftm_vbset(pos, data);
}

// --- Dot Product ---

// CHECK-LABEL: @test_vfdot32(
// CHECK: call <32 x float> @llvm.ftm.vfdot32(<32 x float> %{{.*}}, <32 x float> %{{.*}})
vf32 test_vfdot32(vf32 a, vf32 b) {
  return __builtin_ftm_vfdot32(a, b);
}
