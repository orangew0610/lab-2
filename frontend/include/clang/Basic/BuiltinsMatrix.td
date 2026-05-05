//===--- BuiltinsMatrix.td - FTM Builtin function database ------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file defines the FT-Matrix (FTM)-specific builtin function database.
// Maps to llvm.ftm.* intrinsics defined in IntrinsicsMatrix.td.
//
//===----------------------------------------------------------------------===//

include "clang/Basic/BuiltinsBase.td"

class FTMBuiltin<string prototype> : TargetBuiltin {
  let Spellings = ["__builtin_ftm_" # NAME];
  let Prototype = prototype;
}

//===----------------------------------------------------------------------===//
// Vector Dot / Complex Multiply (2)
//===----------------------------------------------------------------------===//

let Attributes = [NoThrow, Const] in {
def vfdot32  : FTMBuiltin<"_ExtVector<32, float>(_ExtVector<32, float>, _ExtVector<32, float>)">;
def vfcmul32 : FTMBuiltin<"_ExtVector<32, float>(_ExtVector<32, float>, _ExtVector<32, float>)">;
}

//===----------------------------------------------------------------------===//
// Vector Memory Loads — single VR (9)
//===----------------------------------------------------------------------===//

let Attributes = [NoThrow] in {
// Single VR loads → v32i32
def vldh  : FTMBuiltin<"_ExtVector<32, int>(long long int, long long int)">;
def vldhu : FTMBuiltin<"_ExtVector<32, int>(long long int, long long int)">;
def vldw  : FTMBuiltin<"_ExtVector<32, int>(long long int, long long int)">;

// VR pair loads → v32i64
def vlddw    : FTMBuiltin<"_ExtVector<32, long long int>(long long int, long long int)">;
def vlddwm2  : FTMBuiltin<"_ExtVector<32, long long int>(long long int, long long int)">;
def vlddw0m2 : FTMBuiltin<"_ExtVector<32, long long int>(long long int, long long int)">;
def vlddw1m2 : FTMBuiltin<"_ExtVector<32, long long int>(long long int, long long int)">;
def vlddw0m4 : FTMBuiltin<"_ExtVector<32, long long int>(long long int, long long int)">;
def vlddw1m4 : FTMBuiltin<"_ExtVector<32, long long int>(long long int, long long int)">;
}

//===----------------------------------------------------------------------===//
// Vector Memory Stores (8)
//===----------------------------------------------------------------------===//

let Attributes = [NoThrow] in {
// Single VR stores: v32i32
def vsth : FTMBuiltin<"void(_ExtVector<32, int>, long long int, long long int)">;
def vstw : FTMBuiltin<"void(_ExtVector<32, int>, long long int, long long int)">;

// VR pair stores: v32i64
def vstdw     : FTMBuiltin<"void(_ExtVector<32, long long int>, long long int, long long int)">;
def vstdwm16  : FTMBuiltin<"void(_ExtVector<32, long long int>, long long int, long long int)">;
def vstdw0m16 : FTMBuiltin<"void(_ExtVector<32, long long int>, long long int, long long int)">;
def vstdw1m16 : FTMBuiltin<"void(_ExtVector<32, long long int>, long long int, long long int)">;
def vstdw0m32 : FTMBuiltin<"void(_ExtVector<32, long long int>, long long int, long long int)">;
def vstdw1m32 : FTMBuiltin<"void(_ExtVector<32, long long int>, long long int, long long int)">;
}

//===----------------------------------------------------------------------===//
// Vector FP Compare (6)
//===----------------------------------------------------------------------===//

let Attributes = [NoThrow, Const] in {
def vfcmped   : FTMBuiltin<"_ExtVector<32, int>(_ExtVector<32, int>, _ExtVector<32, int>)">;
def vfcmpgd   : FTMBuiltin<"_ExtVector<32, int>(_ExtVector<32, int>, _ExtVector<32, int>)">;
def vfcmpld   : FTMBuiltin<"_ExtVector<32, int>(_ExtVector<32, int>, _ExtVector<32, int>)">;
def vfcmpes32 : FTMBuiltin<"_ExtVector<32, int>(_ExtVector<32, int>, _ExtVector<32, int>)">;
def vfcmpgs32 : FTMBuiltin<"_ExtVector<32, int>(_ExtVector<32, int>, _ExtVector<32, int>)">;
def vfcmpls32 : FTMBuiltin<"_ExtVector<32, int>(_ExtVector<32, int>, _ExtVector<32, int>)">;
}

//===----------------------------------------------------------------------===//
// Vector FP Maximum (2)
//===----------------------------------------------------------------------===//

let Attributes = [NoThrow, Const] in {
def vfmaxd   : FTMBuiltin<"_ExtVector<32, int>(_ExtVector<32, int>, _ExtVector<32, int>)">;
def vfmaxs32 : FTMBuiltin<"_ExtVector<32, int>(_ExtVector<32, int>, _ExtVector<32, int>)">;
}

//===----------------------------------------------------------------------===//
// Vector FP Compare All (6) — return scalar
//===----------------------------------------------------------------------===//

let Attributes = [NoThrow, Const] in {
def vfcmped_all   : FTMBuiltin<"long long int(_ExtVector<32, int>, _ExtVector<32, int>)">;
def vfcmpgd_all   : FTMBuiltin<"long long int(_ExtVector<32, int>, _ExtVector<32, int>)">;
def vfcmpld_all   : FTMBuiltin<"long long int(_ExtVector<32, int>, _ExtVector<32, int>)">;
def vfcmpes32_all : FTMBuiltin<"long long int(_ExtVector<32, int>, _ExtVector<32, int>)">;
def vfcmpgs32_all : FTMBuiltin<"long long int(_ExtVector<32, int>, _ExtVector<32, int>)">;
def vfcmpls32_all : FTMBuiltin<"long long int(_ExtVector<32, int>, _ExtVector<32, int>)">;
}

//===----------------------------------------------------------------------===//
// Precision Conversion (3)
//===----------------------------------------------------------------------===//

let Attributes = [NoThrow, Const] in {
def vfdpsp32   : FTMBuiltin<"_ExtVector<32, float>(_ExtVector<16, double>, _ExtVector<16, double>)">;
def vfspdp32t  : FTMBuiltin<"_ExtVector<16, double>(_ExtVector<32, float>)">;
def vfsphdp32t : FTMBuiltin<"_ExtVector<16, double>(_ExtVector<32, float>)">;
}

//===----------------------------------------------------------------------===//
// Reciprocal Approximations (4)
//===----------------------------------------------------------------------===//

let Attributes = [NoThrow, Const] in {
def vfrcpd   : FTMBuiltin<"_ExtVector<16, double>(_ExtVector<16, double>)">;
def vfrcps32 : FTMBuiltin<"_ExtVector<32, float>(_ExtVector<32, float>)">;
def vfrsqd   : FTMBuiltin<"_ExtVector<16, double>(_ExtVector<16, double>)">;
def vfrsqs32 : FTMBuiltin<"_ExtVector<32, float>(_ExtVector<32, float>)">;
}

//===----------------------------------------------------------------------===//
// Control Flow (5)
//===----------------------------------------------------------------------===//

let Attributes = [NoThrow] in {
def smfence : FTMBuiltin<"void()">;
def seret   : FTMBuiltin<"void()">;
def siret   : FTMBuiltin<"void(long long int)">;
def sbrvnz  : FTMBuiltin<"void(long long int)">;
def sbrvz   : FTMBuiltin<"void(long long int)">;
def sint    : FTMBuiltin<"void(long long int)">;
def sep     : FTMBuiltin<"void(long long int)">;
def swait   : FTMBuiltin<"void()">;
}

//===----------------------------------------------------------------------===//
// Vector Integer Compare (6)
//===----------------------------------------------------------------------===//

let Attributes = [NoThrow, Const] in {
def veq    : FTMBuiltin<"_ExtVector<16, long long int>(_ExtVector<16, long long int>, _ExtVector<16, long long int>)">;
def vlt    : FTMBuiltin<"_ExtVector<16, long long int>(_ExtVector<16, long long int>, _ExtVector<16, long long int>)">;
def vltu   : FTMBuiltin<"_ExtVector<16, long long int>(_ExtVector<16, long long int>, _ExtVector<16, long long int>)">;
def veq32  : FTMBuiltin<"_ExtVector<32, int>(_ExtVector<32, int>, _ExtVector<32, int>)">;
def vlt32  : FTMBuiltin<"_ExtVector<32, int>(_ExtVector<32, int>, _ExtVector<32, int>)">;
def vltu32 : FTMBuiltin<"_ExtVector<32, int>(_ExtVector<32, int>, _ExtVector<32, int>)">;
}

//===----------------------------------------------------------------------===//
// Vector Integer Compare All (6) — return scalar
//===----------------------------------------------------------------------===//

let Attributes = [NoThrow, Const] in {
def veq_all    : FTMBuiltin<"long long int(_ExtVector<16, long long int>, _ExtVector<16, long long int>)">;
def vlt_all    : FTMBuiltin<"long long int(_ExtVector<16, long long int>, _ExtVector<16, long long int>)">;
def vltu_all   : FTMBuiltin<"long long int(_ExtVector<16, long long int>, _ExtVector<16, long long int>)">;
def veq32_all  : FTMBuiltin<"long long int(_ExtVector<32, int>, _ExtVector<32, int>)">;
def vlt32_all  : FTMBuiltin<"long long int(_ExtVector<32, int>, _ExtVector<32, int>)">;
def vltu32_all : FTMBuiltin<"long long int(_ExtVector<32, int>, _ExtVector<32, int>)">;
}

//===----------------------------------------------------------------------===//
// Conditional Subtract-Shift (4)
//===----------------------------------------------------------------------===//

let Attributes = [NoThrow, Const] in {
def vsubc   : FTMBuiltin<"_ExtVector<16, long long int>(_ExtVector<16, long long int>, _ExtVector<16, long long int>)">;
def ssubc   : FTMBuiltin<"long long int(long long int, long long int)">;
def vsubc32 : FTMBuiltin<"_ExtVector<32, int>(_ExtVector<32, int>, _ExtVector<32, int>)">;
def ssubc32 : FTMBuiltin<"_ExtVector<2, int>(_ExtVector<2, int>, _ExtVector<2, int>)">;
}

//===----------------------------------------------------------------------===//
// Vector Bit Manipulation (8)
//===----------------------------------------------------------------------===//

let Attributes = [NoThrow, Const] in {
def vbset   : FTMBuiltin<"_ExtVector<16, long long int>(_ExtVector<16, long long int>, _ExtVector<16, long long int>)">;
def vbclr   : FTMBuiltin<"_ExtVector<16, long long int>(_ExtVector<16, long long int>, _ExtVector<16, long long int>)">;
def vbex    : FTMBuiltin<"_ExtVector<16, long long int>(_ExtVector<16, long long int>, _ExtVector<16, long long int>)">;
def vbtst   : FTMBuiltin<"_ExtVector<16, long long int>(_ExtVector<16, long long int>, _ExtVector<16, long long int>)">;
def vbset32 : FTMBuiltin<"_ExtVector<32, int>(_ExtVector<32, int>, _ExtVector<32, int>)">;
def vbclr32 : FTMBuiltin<"_ExtVector<32, int>(_ExtVector<32, int>, _ExtVector<32, int>)">;
def vbex32  : FTMBuiltin<"_ExtVector<32, int>(_ExtVector<32, int>, _ExtVector<32, int>)">;
def vbtst32 : FTMBuiltin<"_ExtVector<32, int>(_ExtVector<32, int>, _ExtVector<32, int>)">;
}

//===----------------------------------------------------------------------===//
// Vector Bit-Field Extraction (4)
//===----------------------------------------------------------------------===//

let Attributes = [NoThrow, Const] in {
def vbext    : FTMBuiltin<"_ExtVector<16, long long int>(_ExtVector<16, long long int>, _ExtVector<16, long long int>)">;
def vbextu   : FTMBuiltin<"_ExtVector<16, long long int>(_ExtVector<16, long long int>, _ExtVector<16, long long int>)">;
def vbext32  : FTMBuiltin<"_ExtVector<32, int>(_ExtVector<32, int>, _ExtVector<32, int>)">;
def vbext32u : FTMBuiltin<"_ExtVector<32, int>(_ExtVector<32, int>, _ExtVector<32, int>)">;
}

//===----------------------------------------------------------------------===//
// SJV: Scalar from Vector Reduction (4)
//===----------------------------------------------------------------------===//

let Attributes = [NoThrow, Const] in {
def sjvrz   : FTMBuiltin<"long long int(_ExtVector<16, long long int>)">;
def sjvro16 : FTMBuiltin<"long long int(_ExtVector<32, int>)">;
def sjvro32 : FTMBuiltin<"long long int(_ExtVector<32, int>)">;
def sjvro64 : FTMBuiltin<"long long int(_ExtVector<16, long long int>)">;
}

//===----------------------------------------------------------------------===//
// SFR: Scalar Floating-Point Reciprocal (4)
//===----------------------------------------------------------------------===//

let Attributes = [NoThrow, Const] in {
def sfrcpd   : FTMBuiltin<"double(double)">;
def sfrcps32 : FTMBuiltin<"_ExtVector<2, float>(_ExtVector<2, float>)">;
def sfrsqd   : FTMBuiltin<"double(double)">;
def sfrsqs32 : FTMBuiltin<"_ExtVector<2, float>(_ExtVector<2, float>)">;
}

//===----------------------------------------------------------------------===//
// SFABS: Scalar FP Absolute Value (1) — only v4f16 needs intrinsic
//===----------------------------------------------------------------------===//

let Attributes = [NoThrow, Const] in {
def sfabsh16 : FTMBuiltin<"long long int(long long int)">;
}

//===----------------------------------------------------------------------===//
// SVB: Scalar to Vector Broadcast (4)
//===----------------------------------------------------------------------===//

let Attributes = [NoThrow, Const] in {
def svbcast2      : FTMBuiltin<"_ExtVector<32, long long int>(long long int, long long int)">;
def svbcast2sext  : FTMBuiltin<"_ExtVector<32, long long int>(long long int)">;
def svbcast2hexth : FTMBuiltin<"_ExtVector<32, long long int>(long long int)">;
def svbcast2hextl : FTMBuiltin<"_ExtVector<32, long long int>(long long int)">;
}

//===----------------------------------------------------------------------===//
// SAT: Saturation (4)
//===----------------------------------------------------------------------===//

let Attributes = [NoThrow] in {
def ssat   : FTMBuiltin<"long long int(long long int)">;
def ssat32 : FTMBuiltin<"long long int(long long int)">;
def vsat   : FTMBuiltin<"_ExtVector<16, long long int>(_ExtVector<16, long long int>)">;
def vsat32 : FTMBuiltin<"_ExtVector<32, int>(_ExtVector<32, int>)">;
}

//===----------------------------------------------------------------------===//
// Half-Precision (f16/i16) Builtins
//===----------------------------------------------------------------------===//

// --- Scalar v4f16 Compare (i64 container) (3) ---
let Attributes = [NoThrow, Const] in {
def sfcmpeh16 : FTMBuiltin<"long long int(long long int, long long int)">;
def sfcmpgh16 : FTMBuiltin<"long long int(long long int, long long int)">;
def sfcmplh16 : FTMBuiltin<"long long int(long long int, long long int)">;
}

// --- Scalar v2f32 Compare (i64 container) (3) ---
let Attributes = [NoThrow, Const] in {
def sfcmpes32 : FTMBuiltin<"long long int(long long int, long long int)">;
def sfcmpgs32 : FTMBuiltin<"long long int(long long int, long long int)">;
def sfcmpls32 : FTMBuiltin<"long long int(long long int, long long int)">;
}

// --- Vector v64f16 Compare (6) ---
let Attributes = [NoThrow, Const] in {
def vfcmpeh16 : FTMBuiltin<"_ExtVector<64, short>(_ExtVector<64, __fp16>, _ExtVector<64, __fp16>)">;
def vfcmpgh16 : FTMBuiltin<"_ExtVector<64, short>(_ExtVector<64, __fp16>, _ExtVector<64, __fp16>)">;
def vfcmplh16 : FTMBuiltin<"_ExtVector<64, short>(_ExtVector<64, __fp16>, _ExtVector<64, __fp16>)">;
}

// --- Conversion f16↔i16 (scalar) (4) ---
let Attributes = [NoThrow, Const] in {
def sfhint16  : FTMBuiltin<"_ExtVector<4, short>(_ExtVector<4, __fp16>)">;
def sfhtru16  : FTMBuiltin<"_ExtVector<4, short>(_ExtVector<4, __fp16>)">;
def sfinth16  : FTMBuiltin<"_ExtVector<4, __fp16>(_ExtVector<4, short>)">;
def sfinthu16 : FTMBuiltin<"_ExtVector<4, __fp16>(_ExtVector<4, short>)">;
}

// --- Conversion f16↔i16 (vector) (4) ---
let Attributes = [NoThrow, Const] in {
def vfhint16  : FTMBuiltin<"_ExtVector<64, short>(_ExtVector<64, __fp16>)">;
def vfhtru16  : FTMBuiltin<"_ExtVector<64, short>(_ExtVector<64, __fp16>)">;
def vfinth16  : FTMBuiltin<"_ExtVector<64, __fp16>(_ExtVector<64, short>)">;
def vfinthu16 : FTMBuiltin<"_ExtVector<64, __fp16>(_ExtVector<64, short>)">;
}

// --- Conversion f16↔f32 (scalar) (3) ---
let Attributes = [NoThrow, Const] in {
def sfhpsp16h : FTMBuiltin<"_ExtVector<2, float>(_ExtVector<4, __fp16>)">;
def sfhpsp16l : FTMBuiltin<"_ExtVector<2, float>(_ExtVector<4, __fp16>)">;
def sfsphp16  : FTMBuiltin<"_ExtVector<4, __fp16>(_ExtVector<2, float>, _ExtVector<2, float>)">;
}

// --- Conversion f16↔f32 (vector) (3) ---
let Attributes = [NoThrow, Const] in {
def vfhpsp16h : FTMBuiltin<"_ExtVector<32, float>(_ExtVector<64, __fp16>)">;
def vfhpsp16l : FTMBuiltin<"_ExtVector<32, float>(_ExtVector<64, __fp16>)">;
def vfsphp16  : FTMBuiltin<"_ExtVector<64, __fp16>(_ExtVector<32, float>, _ExtVector<32, float>)">;
}

// --- Format conversion f16↔bf16 (4) ---
let Attributes = [NoThrow, Const] in {
def sfp16tobf16 : FTMBuiltin<"_ExtVector<4, short>(_ExtVector<4, __fp16>)">;
def sbf16tofp16 : FTMBuiltin<"_ExtVector<4, __fp16>(_ExtVector<4, short>)">;
def vfp16tobf16 : FTMBuiltin<"_ExtVector<64, short>(_ExtVector<64, __fp16>)">;
def vbf16tofp16 : FTMBuiltin<"_ExtVector<64, __fp16>(_ExtVector<64, short>)">;
}

// --- Transcendental/special unary (4) ---
let Attributes = [NoThrow, Const] in {
def sflogh16  : FTMBuiltin<"_ExtVector<4, __fp16>(_ExtVector<4, __fp16>)">;
def sfmanh16  : FTMBuiltin<"_ExtVector<4, short>(_ExtVector<4, __fp16>)">;
def vflogh16  : FTMBuiltin<"_ExtVector<64, __fp16>(_ExtVector<64, __fp16>)">;
def vfmanh16  : FTMBuiltin<"_ExtVector<64, short>(_ExtVector<64, __fp16>)">;
}

// --- FP Exponent / Mantissa Extraction — f64 and v2f32 (8) ---
let Attributes = [NoThrow, Const] in {
def sflogd   : FTMBuiltin<"long long int(double)">;
def sflogs32 : FTMBuiltin<"_ExtVector<2, int>(_ExtVector<2, float>)">;
def sfmand   : FTMBuiltin<"long long int(double)">;
def sfmans32 : FTMBuiltin<"_ExtVector<2, int>(_ExtVector<2, float>)">;
def vflogd   : FTMBuiltin<"_ExtVector<16, long long int>(_ExtVector<16, double>)">;
def vflogs32 : FTMBuiltin<"_ExtVector<32, int>(_ExtVector<32, float>)">;
def vfmand   : FTMBuiltin<"_ExtVector<16, long long int>(_ExtVector<16, double>)">;
def vfmans32 : FTMBuiltin<"_ExtVector<32, int>(_ExtVector<32, float>)">;
}

// --- Extract/broadcast (scalar v4f16) (4) ---
let Attributes = [NoThrow, Const] in {
def sfexth16hh : FTMBuiltin<"_ExtVector<4, __fp16>(_ExtVector<4, __fp16>)">;
def sfexth16hl : FTMBuiltin<"_ExtVector<4, __fp16>(_ExtVector<4, __fp16>)">;
def sfexth16lh : FTMBuiltin<"_ExtVector<4, __fp16>(_ExtVector<4, __fp16>)">;
def sfexth16ll : FTMBuiltin<"_ExtVector<4, __fp16>(_ExtVector<4, __fp16>)">;
}

// --- Extract/broadcast (vector v64f16) (4) ---
let Attributes = [NoThrow, Const] in {
def vfexth16hh : FTMBuiltin<"_ExtVector<64, __fp16>(_ExtVector<64, __fp16>)">;
def vfexth16hl : FTMBuiltin<"_ExtVector<64, __fp16>(_ExtVector<64, __fp16>)">;
def vfexth16lh : FTMBuiltin<"_ExtVector<64, __fp16>(_ExtVector<64, __fp16>)">;
def vfexth16ll : FTMBuiltin<"_ExtVector<64, __fp16>(_ExtVector<64, __fp16>)">;
}

// --- Extract/broadcast (scalar v2f32) (2) ---
let Attributes = [NoThrow, Const] in {
def sfexts32h : FTMBuiltin<"_ExtVector<2, float>(_ExtVector<2, float>)">;
def sfexts32l : FTMBuiltin<"_ExtVector<2, float>(_ExtVector<2, float>)">;
}

// --- Extract/broadcast (vector v32f32) (2) ---
let Attributes = [NoThrow, Const] in {
def vfexts32h : FTMBuiltin<"_ExtVector<32, float>(_ExtVector<32, float>)">;
def vfexts32l : FTMBuiltin<"_ExtVector<32, float>(_ExtVector<32, float>)">;
}

// --- Special binary (scalar/vector) (4) ---
let Attributes = [NoThrow, Const] in {
def sfcmulh16 : FTMBuiltin<"_ExtVector<4, __fp16>(_ExtVector<4, __fp16>, _ExtVector<4, __fp16>)">;
def sfdoth16  : FTMBuiltin<"_ExtVector<4, __fp16>(_ExtVector<4, __fp16>, _ExtVector<4, __fp16>)">;
def vfcmulh16 : FTMBuiltin<"_ExtVector<64, __fp16>(_ExtVector<64, __fp16>, _ExtVector<64, __fp16>)">;
def vfdoth16  : FTMBuiltin<"_ExtVector<64, __fp16>(_ExtVector<64, __fp16>, _ExtVector<64, __fp16>)">;
}

// --- Mixed-precision FMA f16×f16+f32→f32 (4) ---
let Attributes = [NoThrow, Const] in {
def sfmulahhs : FTMBuiltin<"_ExtVector<2, float>(_ExtVector<4, __fp16>, _ExtVector<4, __fp16>, _ExtVector<2, float>)">;
def sfmulahls : FTMBuiltin<"_ExtVector<2, float>(_ExtVector<4, __fp16>, _ExtVector<4, __fp16>, _ExtVector<2, float>)">;
def vfmulahhs : FTMBuiltin<"_ExtVector<32, float>(_ExtVector<64, __fp16>, _ExtVector<64, __fp16>, _ExtVector<32, float>)">;
def vfmulahls : FTMBuiltin<"_ExtVector<32, float>(_ExtVector<64, __fp16>, _ExtVector<64, __fp16>, _ExtVector<32, float>)">;
}

//===----------------------------------------------------------------------===//
// Interleave / Deinterleave (ITL/BALE) (24)
//===----------------------------------------------------------------------===//

// Unary (scalar): swap sub-word halves / unsigned unpack
let Attributes = [NoThrow, Const] in {
def sitl2    : FTMBuiltin<"long long int(long long int)">;
def sitl4    : FTMBuiltin<"long long int(long long int)">;
def subale4h : FTMBuiltin<"long long int(long long int)">;
def subale4l : FTMBuiltin<"long long int(long long int)">;
}

// Unary (vector): swap sub-word halves / unsigned unpack
let Attributes = [NoThrow, Const] in {
def vitl2    : FTMBuiltin<"_ExtVector<16, long long int>(_ExtVector<16, long long int>)">;
def vitl4    : FTMBuiltin<"_ExtVector<16, long long int>(_ExtVector<16, long long int>)">;
def vubale4h : FTMBuiltin<"_ExtVector<16, long long int>(_ExtVector<16, long long int>)">;
def vubale4l : FTMBuiltin<"_ExtVector<16, long long int>(_ExtVector<16, long long int>)">;
}

// Binary (scalar): pack / deinterleave
let Attributes = [NoThrow, Const] in {
def sbale2   : FTMBuiltin<"long long int(long long int, long long int)">;
def sbale2h  : FTMBuiltin<"long long int(long long int, long long int)">;
def sbale2hl : FTMBuiltin<"long long int(long long int, long long int)">;
def sbale2lh : FTMBuiltin<"long long int(long long int, long long int)">;
def sbale4h  : FTMBuiltin<"long long int(long long int, long long int)">;
def sbale4l  : FTMBuiltin<"long long int(long long int, long long int)">;
}

// Binary (vector): pack / deinterleave
let Attributes = [NoThrow, Const] in {
def vbale2   : FTMBuiltin<"_ExtVector<16, long long int>(_ExtVector<16, long long int>, _ExtVector<16, long long int>)">;
def vbale2h  : FTMBuiltin<"_ExtVector<16, long long int>(_ExtVector<16, long long int>, _ExtVector<16, long long int>)">;
def vbale2hl : FTMBuiltin<"_ExtVector<16, long long int>(_ExtVector<16, long long int>, _ExtVector<16, long long int>)">;
def vbale2lh : FTMBuiltin<"_ExtVector<16, long long int>(_ExtVector<16, long long int>, _ExtVector<16, long long int>)">;
def vbale4h  : FTMBuiltin<"_ExtVector<16, long long int>(_ExtVector<16, long long int>, _ExtVector<16, long long int>)">;
def vbale4l  : FTMBuiltin<"_ExtVector<16, long long int>(_ExtVector<16, long long int>, _ExtVector<16, long long int>)">;
}

// Binary: signed saturating pack (scalar + vector) — IntrHasSideEffects (sets saturation flags)
let Attributes = [NoThrow] in {
def ssbale2  : FTMBuiltin<"long long int(long long int, long long int)">;
def ssbale4  : FTMBuiltin<"long long int(long long int, long long int)">;
def vsbale2  : FTMBuiltin<"_ExtVector<16, long long int>(_ExtVector<16, long long int>, _ExtVector<16, long long int>)">;
def vsbale4  : FTMBuiltin<"_ExtVector<16, long long int>(_ExtVector<16, long long int>, _ExtVector<16, long long int>)">;
}

//===----------------------------------------------------------------------===//
// FP Conversions with Hardware Rounding Mode (4)
//===----------------------------------------------------------------------===//

let Attributes = [NoThrow, Const] in {
def sfdint   : FTMBuiltin<"long long int(double)">;
def sfsint32 : FTMBuiltin<"_ExtVector<2, int>(_ExtVector<2, float>)">;
}

let Attributes = [NoThrow, Const] in {
def vfdint   : FTMBuiltin<"_ExtVector<16, long long int>(_ExtVector<16, double>)">;
def vfsint32 : FTMBuiltin<"_ExtVector<32, int>(_ExtVector<32, float>)">;
}

//===----------------------------------------------------------------------===//
// Scalar Precision Pack/Unpack (3)
//===----------------------------------------------------------------------===//

let Attributes = [NoThrow, Const] in {
def sfdpsp32   : FTMBuiltin<"_ExtVector<2, float>(double, double)">;
def sfspdp32t  : FTMBuiltin<"double(_ExtVector<2, float>)">;
def sfsphdp32t : FTMBuiltin<"double(_ExtVector<2, float>)">;
}

//===----------------------------------------------------------------------===//
// Scalar v2f32 Special Operations (3)
//===----------------------------------------------------------------------===//

let Attributes = [NoThrow, Const] in {
def sfdot32    : FTMBuiltin<"_ExtVector<2, float>(_ExtVector<2, float>, _ExtVector<2, float>)">;
def sfcmul32   : FTMBuiltin<"_ExtVector<2, float>(_ExtVector<2, float>, _ExtVector<2, float>)">;
def sfmulbs32  : FTMBuiltin<"_ExtVector<2, float>(_ExtVector<2, float>, _ExtVector<2, float>, _ExtVector<2, float>)">;
}

//===----------------------------------------------------------------------===//
// Scalar Bit Manipulation (8)
//===----------------------------------------------------------------------===//

let Attributes = [NoThrow, Const] in {
// 64-bit variants
def sbtst  : FTMBuiltin<"long long int(long long int, long long int)">;
def sbext  : FTMBuiltin<"long long int(long long int, long long int)">;
def sbextu : FTMBuiltin<"long long int(long long int, long long int)">;
// 32-bit SIMD variants
def sbset32  : FTMBuiltin<"_ExtVector<2, int>(_ExtVector<2, int>, _ExtVector<2, int>)">;
def sbclr32  : FTMBuiltin<"_ExtVector<2, int>(_ExtVector<2, int>, _ExtVector<2, int>)">;
def sbtst32  : FTMBuiltin<"_ExtVector<2, int>(_ExtVector<2, int>, _ExtVector<2, int>)">;
def sbext32  : FTMBuiltin<"_ExtVector<2, int>(_ExtVector<2, int>, _ExtVector<2, int>)">;
def sbext32u : FTMBuiltin<"_ExtVector<2, int>(_ExtVector<2, int>, _ExtVector<2, int>)">;
}

//===----------------------------------------------------------------------===//
// Mixed-Sign Multiplication (10)
//===----------------------------------------------------------------------===//

let Attributes = [NoThrow, Const] in {
def smulisu   : FTMBuiltin<"long long int(long long int, long long int)">;
def smulisu32 : FTMBuiltin<"_ExtVector<2, int>(_ExtVector<2, int>, _ExtVector<2, int>)">;
// Multiply-add/sub (reg-reg-reg)
def smulasu32t  : FTMBuiltin<"long long int(long long int, long long int, long long int)">;
def smulaus32t  : FTMBuiltin<"long long int(long long int, long long int, long long int)">;
def smulbsu32t  : FTMBuiltin<"long long int(long long int, long long int, long long int)">;
def smulbus32t  : FTMBuiltin<"long long int(long long int, long long int, long long int)">;
// Multiply-add/sub with immediate (imm-reg-reg)
def smulasu32t_i  : FTMBuiltin<"long long int(long long int, long long int, long long int)">;
def smulaus32t_i  : FTMBuiltin<"long long int(long long int, long long int, long long int)">;
def smulbsu32t_i  : FTMBuiltin<"long long int(long long int, long long int, long long int)">;
def smulbus32t_i  : FTMBuiltin<"long long int(long long int, long long int, long long int)">;
}

//===----------------------------------------------------------------------===//
// Address Compare (1)
//===----------------------------------------------------------------------===//

let Attributes = [NoThrow, Const] in {
def smcmpeq : FTMBuiltin<"long long int(long long int, long long int)">;
}
