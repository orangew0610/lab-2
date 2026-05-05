//===------ Matrix.cpp - Emit LLVM Code for FTM builtins ------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This contains code to emit __builtin_ftm_* calls as LLVM intrinsic calls.
//
//===----------------------------------------------------------------------===//

#include "CodeGenFunction.h"
#include "clang/Basic/TargetBuiltins.h"
#include "llvm/IR/IntrinsicsMatrix.h"

using namespace clang;
using namespace CodeGen;
using namespace llvm;

Value *CodeGenFunction::EmitMatrixBuiltinExpr(unsigned BuiltinID,
                                              const CallExpr *E) {
  SmallVector<Value *, 4> Ops;
  for (unsigned i = 0, e = E->getNumArgs(); i != e; i++)
    Ops.push_back(EmitScalarExpr(E->getArg(i)));

  Intrinsic::ID ID;
  switch (BuiltinID) {
  default:
    return nullptr;

  // --- Dot / Complex Multiply ---
  case Matrix::BI__builtin_ftm_vfdot32:  ID = Intrinsic::ftm_vfdot32; break;
  case Matrix::BI__builtin_ftm_vfcmul32: ID = Intrinsic::ftm_vfcmul32; break;

  // --- Vector Memory Loads (single VR) ---
  case Matrix::BI__builtin_ftm_vldh:  ID = Intrinsic::ftm_vldh; break;
  case Matrix::BI__builtin_ftm_vldhu: ID = Intrinsic::ftm_vldhu; break;
  case Matrix::BI__builtin_ftm_vldw:  ID = Intrinsic::ftm_vldw; break;

  // --- Vector Memory Loads (VR pair) ---
  case Matrix::BI__builtin_ftm_vlddw:    ID = Intrinsic::ftm_vlddw; break;
  case Matrix::BI__builtin_ftm_vlddwm2:  ID = Intrinsic::ftm_vlddwm2; break;
  case Matrix::BI__builtin_ftm_vlddw0m2: ID = Intrinsic::ftm_vlddw0m2; break;
  case Matrix::BI__builtin_ftm_vlddw1m2: ID = Intrinsic::ftm_vlddw1m2; break;
  case Matrix::BI__builtin_ftm_vlddw0m4: ID = Intrinsic::ftm_vlddw0m4; break;
  case Matrix::BI__builtin_ftm_vlddw1m4: ID = Intrinsic::ftm_vlddw1m4; break;

  // --- Vector Memory Stores (single VR) ---
  case Matrix::BI__builtin_ftm_vsth: ID = Intrinsic::ftm_vsth; break;
  case Matrix::BI__builtin_ftm_vstw: ID = Intrinsic::ftm_vstw; break;

  // --- Vector Memory Stores (VR pair) ---
  case Matrix::BI__builtin_ftm_vstdw:     ID = Intrinsic::ftm_vstdw; break;
  case Matrix::BI__builtin_ftm_vstdwm16:  ID = Intrinsic::ftm_vstdwm16; break;
  case Matrix::BI__builtin_ftm_vstdw0m16: ID = Intrinsic::ftm_vstdw0m16; break;
  case Matrix::BI__builtin_ftm_vstdw1m16: ID = Intrinsic::ftm_vstdw1m16; break;
  case Matrix::BI__builtin_ftm_vstdw0m32: ID = Intrinsic::ftm_vstdw0m32; break;
  case Matrix::BI__builtin_ftm_vstdw1m32: ID = Intrinsic::ftm_vstdw1m32; break;

  // --- Vector FP Compare ---
  case Matrix::BI__builtin_ftm_vfcmped:   ID = Intrinsic::ftm_vfcmped; break;
  case Matrix::BI__builtin_ftm_vfcmpgd:   ID = Intrinsic::ftm_vfcmpgd; break;
  case Matrix::BI__builtin_ftm_vfcmpld:   ID = Intrinsic::ftm_vfcmpld; break;
  case Matrix::BI__builtin_ftm_vfcmpes32: ID = Intrinsic::ftm_vfcmpes32; break;
  case Matrix::BI__builtin_ftm_vfcmpgs32: ID = Intrinsic::ftm_vfcmpgs32; break;
  case Matrix::BI__builtin_ftm_vfcmpls32: ID = Intrinsic::ftm_vfcmpls32; break;

  // --- Vector FP Maximum ---
  case Matrix::BI__builtin_ftm_vfmaxd:   ID = Intrinsic::ftm_vfmaxd; break;
  case Matrix::BI__builtin_ftm_vfmaxs32: ID = Intrinsic::ftm_vfmaxs32; break;

  // --- Vector FP Compare All ---
  case Matrix::BI__builtin_ftm_vfcmped_all:   ID = Intrinsic::ftm_vfcmped_all; break;
  case Matrix::BI__builtin_ftm_vfcmpgd_all:   ID = Intrinsic::ftm_vfcmpgd_all; break;
  case Matrix::BI__builtin_ftm_vfcmpld_all:   ID = Intrinsic::ftm_vfcmpld_all; break;
  case Matrix::BI__builtin_ftm_vfcmpes32_all: ID = Intrinsic::ftm_vfcmpes32_all; break;
  case Matrix::BI__builtin_ftm_vfcmpgs32_all: ID = Intrinsic::ftm_vfcmpgs32_all; break;
  case Matrix::BI__builtin_ftm_vfcmpls32_all: ID = Intrinsic::ftm_vfcmpls32_all; break;

  // --- Precision Conversion ---
  case Matrix::BI__builtin_ftm_vfdpsp32:   ID = Intrinsic::ftm_vfdpsp32; break;
  case Matrix::BI__builtin_ftm_vfspdp32t:  ID = Intrinsic::ftm_vfspdp32t; break;
  case Matrix::BI__builtin_ftm_vfsphdp32t: ID = Intrinsic::ftm_vfsphdp32t; break;

  // --- Reciprocal Approximations ---
  case Matrix::BI__builtin_ftm_vfrcpd:   ID = Intrinsic::ftm_vfrcpd; break;
  case Matrix::BI__builtin_ftm_vfrcps32: ID = Intrinsic::ftm_vfrcps32; break;
  case Matrix::BI__builtin_ftm_vfrsqd:   ID = Intrinsic::ftm_vfrsqd; break;
  case Matrix::BI__builtin_ftm_vfrsqs32: ID = Intrinsic::ftm_vfrsqs32; break;

  // --- Control Flow ---
  case Matrix::BI__builtin_ftm_smfence: ID = Intrinsic::ftm_smfence; break;
  case Matrix::BI__builtin_ftm_seret:   ID = Intrinsic::ftm_seret; break;
  case Matrix::BI__builtin_ftm_siret:   ID = Intrinsic::ftm_siret; break;
  case Matrix::BI__builtin_ftm_sbrvnz:  ID = Intrinsic::ftm_sbrvnz; break;
  case Matrix::BI__builtin_ftm_sbrvz:   ID = Intrinsic::ftm_sbrvz; break;
  case Matrix::BI__builtin_ftm_sint:    ID = Intrinsic::ftm_sint; break;
  case Matrix::BI__builtin_ftm_sep:     ID = Intrinsic::ftm_sep; break;
  case Matrix::BI__builtin_ftm_swait:   ID = Intrinsic::ftm_swait; break;

  // --- Vector Integer Compare ---
  case Matrix::BI__builtin_ftm_veq:    ID = Intrinsic::ftm_veq; break;
  case Matrix::BI__builtin_ftm_vlt:    ID = Intrinsic::ftm_vlt; break;
  case Matrix::BI__builtin_ftm_vltu:   ID = Intrinsic::ftm_vltu; break;
  case Matrix::BI__builtin_ftm_veq32:  ID = Intrinsic::ftm_veq32; break;
  case Matrix::BI__builtin_ftm_vlt32:  ID = Intrinsic::ftm_vlt32; break;
  case Matrix::BI__builtin_ftm_vltu32: ID = Intrinsic::ftm_vltu32; break;

  // --- Vector Integer Compare All ---
  case Matrix::BI__builtin_ftm_veq_all:    ID = Intrinsic::ftm_veq_all; break;
  case Matrix::BI__builtin_ftm_vlt_all:    ID = Intrinsic::ftm_vlt_all; break;
  case Matrix::BI__builtin_ftm_vltu_all:   ID = Intrinsic::ftm_vltu_all; break;
  case Matrix::BI__builtin_ftm_veq32_all:  ID = Intrinsic::ftm_veq32_all; break;
  case Matrix::BI__builtin_ftm_vlt32_all:  ID = Intrinsic::ftm_vlt32_all; break;
  case Matrix::BI__builtin_ftm_vltu32_all: ID = Intrinsic::ftm_vltu32_all; break;

  // --- Conditional Subtract-Shift ---
  case Matrix::BI__builtin_ftm_vsubc:   ID = Intrinsic::ftm_vsubc; break;
  case Matrix::BI__builtin_ftm_ssubc:   ID = Intrinsic::ftm_ssubc; break;
  case Matrix::BI__builtin_ftm_vsubc32: ID = Intrinsic::ftm_vsubc32; break;
  case Matrix::BI__builtin_ftm_ssubc32: ID = Intrinsic::ftm_ssubc32; break;

  // --- Vector Bit Manipulation ---
  case Matrix::BI__builtin_ftm_vbset:   ID = Intrinsic::ftm_vbset; break;
  case Matrix::BI__builtin_ftm_vbclr:   ID = Intrinsic::ftm_vbclr; break;
  case Matrix::BI__builtin_ftm_vbex:    ID = Intrinsic::ftm_vbex; break;
  case Matrix::BI__builtin_ftm_vbtst:   ID = Intrinsic::ftm_vbtst; break;
  case Matrix::BI__builtin_ftm_vbset32: ID = Intrinsic::ftm_vbset32; break;
  case Matrix::BI__builtin_ftm_vbclr32: ID = Intrinsic::ftm_vbclr32; break;
  case Matrix::BI__builtin_ftm_vbex32:  ID = Intrinsic::ftm_vbex32; break;
  case Matrix::BI__builtin_ftm_vbtst32: ID = Intrinsic::ftm_vbtst32; break;

  // --- Vector Bit-Field Extraction ---
  case Matrix::BI__builtin_ftm_vbext:    ID = Intrinsic::ftm_vbext; break;
  case Matrix::BI__builtin_ftm_vbextu:   ID = Intrinsic::ftm_vbextu; break;
  case Matrix::BI__builtin_ftm_vbext32:  ID = Intrinsic::ftm_vbext32; break;
  case Matrix::BI__builtin_ftm_vbext32u: ID = Intrinsic::ftm_vbext32u; break;

  // --- SJV: Scalar from Vector Reduction ---
  case Matrix::BI__builtin_ftm_sjvrz:   ID = Intrinsic::ftm_sjvrz; break;
  case Matrix::BI__builtin_ftm_sjvro16: ID = Intrinsic::ftm_sjvro16; break;
  case Matrix::BI__builtin_ftm_sjvro32: ID = Intrinsic::ftm_sjvro32; break;
  case Matrix::BI__builtin_ftm_sjvro64: ID = Intrinsic::ftm_sjvro64; break;

  // --- SFR: Scalar FP Reciprocal ---
  case Matrix::BI__builtin_ftm_sfrcpd:   ID = Intrinsic::ftm_sfrcpd; break;
  case Matrix::BI__builtin_ftm_sfrcps32: ID = Intrinsic::ftm_sfrcps32; break;
  case Matrix::BI__builtin_ftm_sfrsqd:   ID = Intrinsic::ftm_sfrsqd; break;
  case Matrix::BI__builtin_ftm_sfrsqs32: ID = Intrinsic::ftm_sfrsqs32; break;

  // --- SFABS: Scalar FP Absolute Value ---
  case Matrix::BI__builtin_ftm_sfabsh16: ID = Intrinsic::ftm_sfabsh16; break;

  // --- SVB: Scalar to Vector Broadcast ---
  case Matrix::BI__builtin_ftm_svbcast2:      ID = Intrinsic::ftm_svbcast2; break;
  case Matrix::BI__builtin_ftm_svbcast2sext:  ID = Intrinsic::ftm_svbcast2sext; break;
  case Matrix::BI__builtin_ftm_svbcast2hexth: ID = Intrinsic::ftm_svbcast2hexth; break;
  case Matrix::BI__builtin_ftm_svbcast2hextl: ID = Intrinsic::ftm_svbcast2hextl; break;

  // --- SAT: Saturation ---
  case Matrix::BI__builtin_ftm_ssat:   ID = Intrinsic::ftm_ssat; break;
  case Matrix::BI__builtin_ftm_ssat32: ID = Intrinsic::ftm_ssat32; break;
  case Matrix::BI__builtin_ftm_vsat:   ID = Intrinsic::ftm_vsat; break;
  case Matrix::BI__builtin_ftm_vsat32: ID = Intrinsic::ftm_vsat32; break;

  // --- Half-Precision (f16/i16) ---
  // Scalar v4f16 compare
  case Matrix::BI__builtin_ftm_sfcmpeh16: ID = Intrinsic::ftm_sfcmpeh16; break;
  case Matrix::BI__builtin_ftm_sfcmpgh16: ID = Intrinsic::ftm_sfcmpgh16; break;
  case Matrix::BI__builtin_ftm_sfcmplh16: ID = Intrinsic::ftm_sfcmplh16; break;
  // Scalar v2f32 compare
  case Matrix::BI__builtin_ftm_sfcmpes32: ID = Intrinsic::ftm_sfcmpes32; break;
  case Matrix::BI__builtin_ftm_sfcmpgs32: ID = Intrinsic::ftm_sfcmpgs32; break;
  case Matrix::BI__builtin_ftm_sfcmpls32: ID = Intrinsic::ftm_sfcmpls32; break;
  // Vector v64f16 compare
  case Matrix::BI__builtin_ftm_vfcmpeh16: ID = Intrinsic::ftm_vfcmpeh16; break;
  case Matrix::BI__builtin_ftm_vfcmpgh16: ID = Intrinsic::ftm_vfcmpgh16; break;
  case Matrix::BI__builtin_ftm_vfcmplh16: ID = Intrinsic::ftm_vfcmplh16; break;
  // Conversion f16↔i16
  case Matrix::BI__builtin_ftm_sfhint16:  ID = Intrinsic::ftm_sfhint16; break;
  case Matrix::BI__builtin_ftm_sfhtru16:  ID = Intrinsic::ftm_sfhtru16; break;
  case Matrix::BI__builtin_ftm_sfinth16:  ID = Intrinsic::ftm_sfinth16; break;
  case Matrix::BI__builtin_ftm_sfinthu16: ID = Intrinsic::ftm_sfinthu16; break;
  case Matrix::BI__builtin_ftm_vfhint16:  ID = Intrinsic::ftm_vfhint16; break;
  case Matrix::BI__builtin_ftm_vfhtru16:  ID = Intrinsic::ftm_vfhtru16; break;
  case Matrix::BI__builtin_ftm_vfinth16:  ID = Intrinsic::ftm_vfinth16; break;
  case Matrix::BI__builtin_ftm_vfinthu16: ID = Intrinsic::ftm_vfinthu16; break;
  // Conversion f16↔f32
  case Matrix::BI__builtin_ftm_sfhpsp16h: ID = Intrinsic::ftm_sfhpsp16h; break;
  case Matrix::BI__builtin_ftm_sfhpsp16l: ID = Intrinsic::ftm_sfhpsp16l; break;
  case Matrix::BI__builtin_ftm_sfsphp16:  ID = Intrinsic::ftm_sfsphp16; break;
  case Matrix::BI__builtin_ftm_vfhpsp16h: ID = Intrinsic::ftm_vfhpsp16h; break;
  case Matrix::BI__builtin_ftm_vfhpsp16l: ID = Intrinsic::ftm_vfhpsp16l; break;
  case Matrix::BI__builtin_ftm_vfsphp16:  ID = Intrinsic::ftm_vfsphp16; break;
  // Format conversion f16↔bf16
  case Matrix::BI__builtin_ftm_sfp16tobf16: ID = Intrinsic::ftm_sfp16tobf16; break;
  case Matrix::BI__builtin_ftm_sbf16tofp16: ID = Intrinsic::ftm_sbf16tofp16; break;
  case Matrix::BI__builtin_ftm_vfp16tobf16: ID = Intrinsic::ftm_vfp16tobf16; break;
  case Matrix::BI__builtin_ftm_vbf16tofp16: ID = Intrinsic::ftm_vbf16tofp16; break;
  // Transcendental/special unary
  case Matrix::BI__builtin_ftm_sflogh16:  ID = Intrinsic::ftm_sflogh16; break;
  case Matrix::BI__builtin_ftm_sfmanh16:  ID = Intrinsic::ftm_sfmanh16; break;
  case Matrix::BI__builtin_ftm_vflogh16:  ID = Intrinsic::ftm_vflogh16; break;
  case Matrix::BI__builtin_ftm_vfmanh16:  ID = Intrinsic::ftm_vfmanh16; break;
  // FP exponent / mantissa extraction (f64, v2f32, v16f64, v32f32)
  case Matrix::BI__builtin_ftm_sflogd:   ID = Intrinsic::ftm_sflogd; break;
  case Matrix::BI__builtin_ftm_sflogs32: ID = Intrinsic::ftm_sflogs32; break;
  case Matrix::BI__builtin_ftm_sfmand:   ID = Intrinsic::ftm_sfmand; break;
  case Matrix::BI__builtin_ftm_sfmans32: ID = Intrinsic::ftm_sfmans32; break;
  case Matrix::BI__builtin_ftm_vflogd:   ID = Intrinsic::ftm_vflogd; break;
  case Matrix::BI__builtin_ftm_vflogs32: ID = Intrinsic::ftm_vflogs32; break;
  case Matrix::BI__builtin_ftm_vfmand:   ID = Intrinsic::ftm_vfmand; break;
  case Matrix::BI__builtin_ftm_vfmans32: ID = Intrinsic::ftm_vfmans32; break;
  // Extract/broadcast (v4f16)
  case Matrix::BI__builtin_ftm_sfexth16hh: ID = Intrinsic::ftm_sfexth16hh; break;
  case Matrix::BI__builtin_ftm_sfexth16hl: ID = Intrinsic::ftm_sfexth16hl; break;
  case Matrix::BI__builtin_ftm_sfexth16lh: ID = Intrinsic::ftm_sfexth16lh; break;
  case Matrix::BI__builtin_ftm_sfexth16ll: ID = Intrinsic::ftm_sfexth16ll; break;
  // Extract/broadcast (v64f16)
  case Matrix::BI__builtin_ftm_vfexth16hh: ID = Intrinsic::ftm_vfexth16hh; break;
  case Matrix::BI__builtin_ftm_vfexth16hl: ID = Intrinsic::ftm_vfexth16hl; break;
  case Matrix::BI__builtin_ftm_vfexth16lh: ID = Intrinsic::ftm_vfexth16lh; break;
  case Matrix::BI__builtin_ftm_vfexth16ll: ID = Intrinsic::ftm_vfexth16ll; break;
  // Extract/broadcast (v2f32, v32f32)
  case Matrix::BI__builtin_ftm_sfexts32h: ID = Intrinsic::ftm_sfexts32h; break;
  case Matrix::BI__builtin_ftm_sfexts32l: ID = Intrinsic::ftm_sfexts32l; break;
  case Matrix::BI__builtin_ftm_vfexts32h: ID = Intrinsic::ftm_vfexts32h; break;
  case Matrix::BI__builtin_ftm_vfexts32l: ID = Intrinsic::ftm_vfexts32l; break;
  // Special binary
  case Matrix::BI__builtin_ftm_sfcmulh16: ID = Intrinsic::ftm_sfcmulh16; break;
  case Matrix::BI__builtin_ftm_sfdoth16:  ID = Intrinsic::ftm_sfdoth16; break;
  case Matrix::BI__builtin_ftm_vfcmulh16: ID = Intrinsic::ftm_vfcmulh16; break;
  case Matrix::BI__builtin_ftm_vfdoth16:  ID = Intrinsic::ftm_vfdoth16; break;
  // Mixed-precision FMA
  case Matrix::BI__builtin_ftm_sfmulahhs: ID = Intrinsic::ftm_sfmulahhs; break;
  case Matrix::BI__builtin_ftm_sfmulahls: ID = Intrinsic::ftm_sfmulahls; break;
  case Matrix::BI__builtin_ftm_vfmulahhs: ID = Intrinsic::ftm_vfmulahhs; break;
  case Matrix::BI__builtin_ftm_vfmulahls: ID = Intrinsic::ftm_vfmulahls; break;

  // --- Interleave / Deinterleave (ITL/BALE) ---
  // Unary (swap / unpack)
  case Matrix::BI__builtin_ftm_sitl2:    ID = Intrinsic::ftm_sitl2; break;
  case Matrix::BI__builtin_ftm_sitl4:    ID = Intrinsic::ftm_sitl4; break;
  case Matrix::BI__builtin_ftm_vitl2:    ID = Intrinsic::ftm_vitl2; break;
  case Matrix::BI__builtin_ftm_vitl4:    ID = Intrinsic::ftm_vitl4; break;
  case Matrix::BI__builtin_ftm_subale4h: ID = Intrinsic::ftm_subale4h; break;
  case Matrix::BI__builtin_ftm_subale4l: ID = Intrinsic::ftm_subale4l; break;
  case Matrix::BI__builtin_ftm_vubale4h: ID = Intrinsic::ftm_vubale4h; break;
  case Matrix::BI__builtin_ftm_vubale4l: ID = Intrinsic::ftm_vubale4l; break;
  // Binary (pack / deinterleave)
  case Matrix::BI__builtin_ftm_sbale2:   ID = Intrinsic::ftm_sbale2; break;
  case Matrix::BI__builtin_ftm_sbale2h:  ID = Intrinsic::ftm_sbale2h; break;
  case Matrix::BI__builtin_ftm_sbale2hl: ID = Intrinsic::ftm_sbale2hl; break;
  case Matrix::BI__builtin_ftm_sbale2lh: ID = Intrinsic::ftm_sbale2lh; break;
  case Matrix::BI__builtin_ftm_sbale4h:  ID = Intrinsic::ftm_sbale4h; break;
  case Matrix::BI__builtin_ftm_sbale4l:  ID = Intrinsic::ftm_sbale4l; break;
  case Matrix::BI__builtin_ftm_vbale2:   ID = Intrinsic::ftm_vbale2; break;
  case Matrix::BI__builtin_ftm_vbale2h:  ID = Intrinsic::ftm_vbale2h; break;
  case Matrix::BI__builtin_ftm_vbale2hl: ID = Intrinsic::ftm_vbale2hl; break;
  case Matrix::BI__builtin_ftm_vbale2lh: ID = Intrinsic::ftm_vbale2lh; break;
  case Matrix::BI__builtin_ftm_vbale4h:  ID = Intrinsic::ftm_vbale4h; break;
  case Matrix::BI__builtin_ftm_vbale4l:  ID = Intrinsic::ftm_vbale4l; break;
  // Signed saturating pack
  case Matrix::BI__builtin_ftm_ssbale2:  ID = Intrinsic::ftm_ssbale2; break;
  case Matrix::BI__builtin_ftm_ssbale4:  ID = Intrinsic::ftm_ssbale4; break;
  case Matrix::BI__builtin_ftm_vsbale2:  ID = Intrinsic::ftm_vsbale2; break;
  case Matrix::BI__builtin_ftm_vsbale4:  ID = Intrinsic::ftm_vsbale4; break;

  // --- Address Compare ---
  case Matrix::BI__builtin_ftm_smcmpeq: ID = Intrinsic::ftm_smcmpeq; break;
  }

  Function *F = CGM.getIntrinsic(ID);

  // VMEM intrinsics now expect ptr addrspace(1) for the base argument,
  // but C builtins pass long long (i64). Insert inttoptr as needed.
  llvm::FunctionType *FTy = F->getFunctionType();
  for (unsigned i = 0; i < Ops.size() && i < FTy->getNumParams(); ++i) {
    if (FTy->getParamType(i)->isPointerTy() && Ops[i]->getType()->isIntegerTy())
      Ops[i] = Builder.CreateIntToPtr(Ops[i], FTy->getParamType(i));
  }

  return Builder.CreateCall(F, Ops);
}
