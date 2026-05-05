# ===- pipeline.py -------------------------------------------------------------
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ===---------------------------------------------------------------------------
#
# FTM compilation pipeline: invokes ftm-opt, ftm-translate, and llc via
# subprocess to produce LASM (.lan) assembly from Linalg-level MLIR.
#
# ===---------------------------------------------------------------------------

import os
import subprocess
import tempfile
from pathlib import Path
from typing import Optional


def _find_tool(name: str) -> str:
    """Locate a build tool by searching known build directories."""
    # Check environment variable override first
    env_key = f"FTM_{name.upper().replace('-', '_')}"
    env_val = os.environ.get(env_key)
    if env_val and os.path.isfile(env_val):
        return env_val

    # Search in project build directories
    project_root = Path(__file__).resolve().parent.parent.parent
    candidates = [
        project_root / "build" / "bin" / name,
        project_root / "llvm" / "build" / "bin" / name,
    ]
    for c in candidates:
        if c.is_file():
            return str(c)

    # Fall back to PATH
    return name


class FTMPipeline:
    """
    Wraps the FTM tool chain as subprocess invocations:
        ftm-opt --ftm-pipeline  →  ftm-translate --mlir-to-llvmir  →  llc -mtriple=matrix

    Usage:
        pipeline = FTMPipeline()
        lasm_text = pipeline.run(linalg_mlir_text, output_path="out.lan")
    """

    def __init__(
        self,
        ftm_opt: Optional[str] = None,
        ftm_translate: Optional[str] = None,
        llc: Optional[str] = None,
    ):
        self._ftm_opt = ftm_opt or _find_tool("ftm-opt")
        self._ftm_translate = ftm_translate or _find_tool("ftm-translate")
        self._llc = llc or _find_tool("llc")

    def _run_cmd(self, cmd: list[str], input_text: str) -> str:
        """Run a subprocess, piping input_text to stdin."""
        result = subprocess.run(
            cmd,
            input=input_text,
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            raise RuntimeError(
                f"Command failed: {' '.join(cmd)}\n"
                f"stderr:\n{result.stderr}"
            )
        return result.stdout

    def bufferize(self, tensor_mlir: str) -> str:
        """
        Bufferize tensor-level Linalg IR to memref-level IR.

        The --ftm-pipeline expects memref-based linalg input.  This step
        converts tensor semantics to buffer (memref) semantics via
        one-shot-bufferize, following the Qwen3 reference pipeline.
        """
        return self._run_cmd(
            [
                self._ftm_opt,
                "--pass-pipeline="
                "builtin.module("
                "canonicalize,"
                "convert-elementwise-to-linalg,"
                "linalg-generalize-named-ops,"
                "canonicalize,"
                "one-shot-bufferize{bufferize-function-boundaries=true},"
                "buffer-deallocation-pipeline,"
                "convert-bufferization-to-memref,"
                "canonicalize"
                ")",
            ],
            tensor_mlir,
        )

    def lower_to_ftm(self, linalg_mlir: str) -> str:
        """
        Bufferize tensor-level Linalg MLIR, run --ftm-pipeline for
        FTM-specific tiling/vectorization, then lower all remaining
        dialects to LLVM dialect for translation.

        Pass ordering follows buddy-mlir's proven pipeline pattern.
        """
        memref_mlir = self.bufferize(linalg_mlir)
        ftm_mlir = self._run_cmd(
            [self._ftm_opt, "--ftm-pipeline"],
            memref_mlir,
        )
        return self._run_cmd(
            [
                self._ftm_opt,
                "--convert-vector-to-scf",
                "--convert-linalg-to-loops",
                "--lower-affine",
                "--convert-scf-to-cf",
                "--convert-csl-to-llvm",
                "--convert-math-to-funcs=convert-ctlz=true",
                "--expand-strided-metadata",
                "--lower-affine",
                "--convert-vector-to-llvm",
                "--convert-ub-to-llvm",
                "--convert-to-llvm",
                "--reconcile-unrealized-casts",
                "--promote-alloc-to-static",
                "--canonicalize",
            ],
            ftm_mlir,
        )

    def lower_to_llvm_scalar(self, linalg_mlir: str) -> str:
        """
        Bufferize and lower Linalg MLIR to LLVM dialect without FTM
        vectorization. Produces scalar LLVM IR suitable for llc.

        Use this path for compile_to_lasm — the FTM vectorization
        generates vector types that llc's ISel cannot fully handle.
        """
        memref_mlir = self.bufferize(linalg_mlir)
        return self._run_cmd(
            [
                self._ftm_opt,
                "--convert-linalg-to-loops",
                "--expand-strided-metadata",
                "--lower-affine",
                "--convert-scf-to-cf",
                "--convert-to-llvm",
                "--reconcile-unrealized-casts",
                "--promote-alloc-to-static",
                "--canonicalize",
            ],
            memref_mlir,
        )

    def translate_to_llvmir(self, ftm_mlir: str) -> str:
        """
        Run ftm-translate --mlir-to-llvmir.
        Returns LLVM IR text.
        """
        return self._run_cmd(
            [self._ftm_translate, "--mlir-to-llvmir"],
            ftm_mlir,
        )

    def compile_to_lasm(self, llvm_ir: str) -> str:
        """
        Run llc -mtriple=matrix to produce LASM assembly.
        Returns LASM text.
        """
        return self._run_cmd(
            [self._llc, "-mtriple=matrix"],
            llvm_ir,
        )

    def run(
        self,
        linalg_mlir: str,
        output_path: Optional[str] = None,
    ) -> str:
        """
        Full pipeline: Linalg MLIR → scalar LLVM IR → LASM.

        Uses the scalar lowering path (no FTM vectorization) since llc's
        ISel cannot handle all FTM vector types. The FTM vectorization
        path (lower_to_ftm) is for ftm-translate output instead.

        Args:
            linalg_mlir: MLIR text at Linalg level.
            output_path: If provided, write LASM to this file.

        Returns:
            LASM assembly text.
        """
        llvm_mlir = self.lower_to_llvm_scalar(linalg_mlir)
        llvm_ir = self.translate_to_llvmir(llvm_mlir)
        lasm = self.compile_to_lasm(llvm_ir)

        if output_path is not None:
            Path(output_path).parent.mkdir(parents=True, exist_ok=True)
            Path(output_path).write_text(lasm)

        return lasm
