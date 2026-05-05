//===--- Matrix.h - Declare Matrix target feature support --------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file declares Matrix TargetInfo objects.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_CLANG_LIB_BASIC_TARGETS_MATRIX_H
#define LLVM_CLANG_LIB_BASIC_TARGETS_MATRIX_H

#include "clang/Basic/TargetInfo.h"
#include "clang/Basic/TargetOptions.h"
#include "llvm/Support/Compiler.h"
#include "llvm/TargetParser/Triple.h"

namespace clang {
namespace targets {

class LLVM_LIBRARY_VISIBILITY MatrixTargetInfo : public TargetInfo {

public:
  MatrixTargetInfo(const llvm::Triple &Triple, const TargetOptions &)
      : TargetInfo(Triple) {
    // Matrix is a 64-bit architecture with little endian byte order
    NoAsmVariants = true;
    LongDoubleWidth = 128;
    LongDoubleAlign = 128;
    LongDoubleFormat = &llvm::APFloat::IEEEquad();
    DoubleAlign = LongLongAlign = 64;
    SuitableAlign = 64;
    LongWidth = LongAlign = PointerWidth = PointerAlign = 64;
    SizeType = UnsignedLong;
    PtrDiffType = SignedLong;
    IntPtrType = SignedLong;
    IntMaxType = SignedLong;
    Int64Type = SignedLong;
    RegParmMax = 4;
    MaxAtomicPromoteWidth = MaxAtomicInlineWidth = 64;
    HasUnalignedAccess = true;

    WCharType = SignedInt;
    WIntType = UnsignedInt;
    UseZeroLengthBitfieldAlignment = true;

    // Data layout string for Matrix:
    // e - little endian
    // m:e - ELF mangling
    // p:64:64 - 64-bit pointers aligned to 64 bits
    // p1-p3:64:64 - address spaces (AM=1, SM=2, GSM=3), all 64-bit
    // i64:64 - 64-bit integers aligned to 64 bits
    // i128:128 - 128-bit integers aligned to 128 bits (GPR128 pairs)
    // n32:64 - native integer widths (32-bit SIMD + 64-bit scalar)
    // S128 - stack alignment 128 bits
    resetDataLayout(
        "e-m:e-p:64:64-p1:64:64-p2:64:64-p3:64:64-i64:64-i128:128-n32:64-S128");
  }

  void getTargetDefines(const LangOptions &Opts,
                        MacroBuilder &Builder) const override;

  bool hasSjLjLowering() const override { return true; }

  llvm::SmallVector<Builtin::InfosShard> getTargetBuiltins() const override;

  BuiltinVaListKind getBuiltinVaListKind() const override {
    return TargetInfo::VoidPtrBuiltinVaList;
  }

  CallingConvCheckResult checkCallingConvention(CallingConv CC) const override {
    switch (CC) {
    default:
      return CCCR_Warning;
    case CC_C:
      return CCCR_OK;
    }
  }

  std::string_view getClobbers() const override { return ""; }

  ArrayRef<const char *> getGCCRegNames() const override {
    // Matrix scalar register file: 64 GPRs (r0-r63)
    static const char *const GCCRegNames[] = {
        "r0",  "r1",  "r2",  "r3",  "r4",  "r5",  "r6",  "r7",
        "r8",  "r9",  "r10", "r11", "r12", "r13", "r14", "r15",
        "r16", "r17", "r18", "r19", "r20", "r21", "r22", "r23",
        "r24", "r25", "r26", "r27", "r28", "r29", "r30", "r31",
        "r32", "r33", "r34", "r35", "r36", "r37", "r38", "r39",
        "r40", "r41", "r42", "r43", "r44", "r45", "r46", "r47",
        "r48", "r49", "r50", "r51", "r52", "r53", "r54", "r55",
        "r56", "r57", "r58", "r59", "r60", "r61", "r62", "r63",
    };
    return llvm::ArrayRef(GCCRegNames);
  }

  ArrayRef<TargetInfo::GCCRegAlias> getGCCRegAliases() const override {
    // R63 is the hardwired zero register.
    // SP/FP are address registers (AR9/AR8), not GPR aliases.
    static const TargetInfo::GCCRegAlias GCCRegAliases[] = {
        {{"zero"}, "r63"},
    };
    return llvm::ArrayRef(GCCRegAliases);
  }

  bool validateAsmConstraint(const char *&Name,
                             TargetInfo::ConstraintInfo &Info) const override {
    switch (*Name) {
    default:
      return false;
    case 'r':
      Info.setAllowsRegister();
      return true;
    }
  }

  bool allowsLargerPreferedTypeAlignment() const override { return false; }
};
} // namespace targets
} // namespace clang
#endif // LLVM_CLANG_LIB_BASIC_TARGETS_MATRIX_H
