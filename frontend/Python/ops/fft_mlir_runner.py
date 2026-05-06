"""Helpers to JIT-run MLIR modules using the MLIR Python ExecutionEngine.

This utility mirrors patterns used in the project's frontend driver and
MLIR test-suite. It lowers the provided MLIR module to LLVM, constructs
an ExecutionEngine, and invokes a function by name with numpy-backed
ranked memrefs.

Notes/requirements:
- Requires the MLIR Python bindings with `mlir.execution_engine` and
  `mlir.runtime` available in the Python environment.
- Requires the runner utils shared libraries (libmlir_runner_utils,
  libmlir_c_runner_utils) to be locatable; you can pass `shared_libs`
  or set environment variables `MLIR_RUNNER_UTILS` / `MLIR_C_RUNNER_UTILS`.

API:
  run_mlir_module(module_or_text, func_name, args, shared_libs=None, opt_level=3)

Example usage:
  module_text = algo.compile_to_mlir(N=8, mode='bindings')
  # prepare numpy arrays for arguments (in_r, in_i, out_r, out_i)
  outs = run_mlir_module(module_text, 'fft_dft_8', [in_r, in_i, out_r, out_i])
"""
from typing import List, Optional, Sequence, Union
import os
import ctypes

import numpy as np

from mlir.ir import Context, Module
from mlir.passmanager import PassManager
from mlir.execution_engine import ExecutionEngine
import mlir.runtime as rt


def _lower_to_llvm(module: Module) -> Module:
    # Use the same pipeline as MLIR test-suite for lowering to llvm
    pm = PassManager.parse(
        "builtin.module(convert-complex-to-llvm,finalize-memref-to-llvm,convert-func-to-llvm,convert-arith-to-llvm,convert-cf-to-llvm,reconcile-unrealized-casts)"
    )
    pm.run(module.operation)
    return module


def _default_shared_libs() -> List[str]:
    # Allow environment override
    mlir_runner = os.getenv("MLIR_RUNNER_UTILS")
    mlir_c_runner = os.getenv("MLIR_C_RUNNER_UTILS")
    libs = []
    if mlir_runner:
        libs.append(mlir_runner)
    if mlir_c_runner:
        libs.append(mlir_c_runner)
    # Fallback heuristic: relative to this file, mirror test expectations
    if not libs:
        base = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../../lib"))
        libs = [os.path.join(base, "libmlir_runner_utils.so"), os.path.join(base, "libmlir_c_runner_utils.so")]
    return [p for p in libs if p and os.path.exists(p)]


def run_mlir_module(
    module_or_text: Union[Module, str],
    func_name: str,
    args: Sequence[np.ndarray],
    shared_libs: Optional[List[str]] = None,
    opt_level: int = 3,
):
    """Lower and run the given MLIR module/function with numpy-backed args.

    Args:
      module_or_text: either an `mlir.ir.Module` or MLIR text string
      func_name: function name to invoke in the module
      args: sequence of numpy arrays corresponding to function arguments
      shared_libs: optional list of shared libraries for the ExecutionEngine
      opt_level: optimization level for ExecutionEngine

    Returns:
      list of numpy arrays corresponding to the (possibly modified) args
      after the invocation. Typically outputs are written into provided
      output arrays (caller-provided).
    """
    # Ensure shared libs
    if shared_libs is None:
        shared_libs = _default_shared_libs()

    # Create a fresh context to parse and run the module
    with Context():
        if isinstance(module_or_text, Module):
            module = module_or_text
        else:
            module = Module.parse(str(module_or_text))

        # Lower to LLVM dialects required by the ExecutionEngine
        lowered = _lower_to_llvm(module)

        # Build ExecutionEngine
        ee = ExecutionEngine(lowered, opt_level=opt_level, shared_libs=shared_libs)

        # Prepare arguments: for each numpy array, build a ranked memref descriptor
        input_slots = []
        descs = []
        for arr in args:
            np_arr = np.ascontiguousarray(arr)
            desc = rt.get_ranked_memref_descriptor(np_arr)
            descs.append(desc)
            input_slots.append(ctypes.pointer(ctypes.pointer(desc)))

        # Invoke function. The ExecutionEngine expects ctypes pointers as parameters.
        ee.invoke(func_name, *input_slots)

        # Convert descriptors back to numpy arrays for return.
        results: List[np.ndarray] = []
        for desc in descs:
            try:
                out = rt.ranked_memref_to_numpy(ctypes.pointer(desc))
            except Exception:
                # Fall back to the original array if conversion fails.
                out = None
            results.append(out)

        return results
