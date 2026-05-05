//===--- Matrix.cpp - Matrix ToolChain Implementations -----------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "MatrixToolchain.h"
#include "clang/Driver/CommonArgs.h"
#include "clang/Driver/Compilation.h"
#include "clang/Driver/Driver.h"
#include "clang/Driver/Options.h"
#include "llvm/Option/ArgList.h"
#include "llvm/Support/Path.h"
#include <cstdlib>

using namespace clang::driver;
using namespace clang::driver::toolchains;
using namespace clang;
using namespace llvm::opt;

MatrixToolChain::MatrixToolChain(const Driver &D, const llvm::Triple &Triple,
                                 const ArgList &Args)
    : Linux(D, Triple, Args) {
  getFilePaths().clear();

  if (std::optional<std::string> Path = getStdlibPath())
    getFilePaths().push_back(std::move(*Path));
  for (const auto &Path : getArchSpecificLibPaths())
    getFilePaths().push_back(Path);
}

Tool *MatrixToolChain::buildAssembler() const {
  return new tools::gnutools::Assembler(*this);
}

Tool *MatrixToolChain::buildLinker() const {
  return new tools::gnutools::Linker(*this);
}

bool MatrixToolChain::isPICDefault() const { return false; }

bool MatrixToolChain::isPIEDefault(const llvm::opt::ArgList &Args) const {
  return false;
}

bool MatrixToolChain::isPICDefaultForced() const { return false; }

bool MatrixToolChain::SupportsProfiling() const { return false; }

bool MatrixToolChain::hasBlocksRuntime() const { return false; }

void MatrixToolChain::AddClangSystemIncludeArgs(const ArgList &DriverArgs,
                                                ArgStringList &CC1Args) const {
  if (DriverArgs.hasArg(clang::driver::options::OPT_nostdinc))
    return;

  if (DriverArgs.hasArg(options::OPT_nobuiltininc) &&
      DriverArgs.hasArg(options::OPT_nostdlibinc))
    return;

  if (!DriverArgs.hasArg(options::OPT_nobuiltininc)) {
    SmallString<128> P(getDriver().ResourceDir);
    llvm::sys::path::append(P, "include");
    addSystemInclude(DriverArgs, CC1Args, P);
  }

  if (!DriverArgs.hasArg(options::OPT_nostdlibinc)) {
    addSystemInclude(DriverArgs, CC1Args, getDriver().SysRoot + "/usr/include");
  }
}

void MatrixToolChain::addClangTargetOptions(const ArgList &DriverArgs,
                                            ArgStringList &CC1Args,
                                            Action::OffloadKind) const {
  CC1Args.push_back("-nostdsysteminc");
  bool UseInitArrayDefault = true;
  if (!DriverArgs.hasFlag(options::OPT_fuse_init_array,
                          options::OPT_fno_use_init_array, UseInitArrayDefault))
    CC1Args.push_back("-fno-use-init-array");
}

void MatrixToolChain::AddClangCXXStdlibIncludeArgs(const ArgList &DriverArgs,
                                                   ArgStringList &CC1Args) const {
  if (DriverArgs.hasArg(clang::driver::options::OPT_nostdinc) ||
      DriverArgs.hasArg(options::OPT_nostdlibinc) ||
      DriverArgs.hasArg(options::OPT_nostdincxx))
    return;

  addLibCxxIncludePaths(DriverArgs, CC1Args);
}

void MatrixToolChain::AddCXXStdlibLibArgs(const ArgList &Args,
                                          ArgStringList &CmdArgs) const {
  assert((GetCXXStdlibType(Args) == ToolChain::CST_Libcxx) &&
         "Only -lc++ (aka libxx) is supported in this toolchain.");

  tools::addArchSpecificRPath(*this, Args, CmdArgs);

  if (std::optional<std::string> Path = getStdlibPath()) {
    CmdArgs.push_back("-rpath");
    CmdArgs.push_back(Args.MakeArgString(*Path));
  }

  CmdArgs.push_back("-lc++");
  if (Args.hasArg(options::OPT_fexperimental_library))
    CmdArgs.push_back("-lc++experimental");
  CmdArgs.push_back("-lc++abi");
  CmdArgs.push_back("-lunwind");
  CmdArgs.push_back("-lpthread");
  CmdArgs.push_back("-ldl");
}

llvm::ExceptionHandling
MatrixToolChain::GetExceptionModel(const ArgList &Args) const {
  return llvm::ExceptionHandling::SjLj;
}
