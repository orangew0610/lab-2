"""FFTc Python-facing API: a small decorator and builder runtime for user-written FFT algorithms.

This module provides:
- AlgorithmBuilder: a minimal builder object that user functions call to
  declare high-level FFT operations (currently `dft`).
- algorithm: a decorator factory that wraps a user function and produces
  an object with `.compile_to_mlir(N, name)` to emit MLIR via the fft_builder
  transform.

Design notes:
- For now the decorator runs the user function at compile time with a
  synthetic builder that records operations. The recorded sequence is
  passed to the fft_builder transform which produces MLIR text. This keeps
  responsibilities separated and avoids complex AST parsing.
"""
from typing import Any, Callable, List, Optional


class AlgorithmBuilder:
    """A very small builder that records high-level FFT ops.

    Currently supports:
    - dft(name: str): record a DFT op (1D) with a symbolic name.
    """

    def __init__(self) -> None:
        self.ops = []
        # mapping of user-declared buffer names to roles: 'input' or 'output'
        # populated by the input()/output() registration API below.
        self.registered_buffers = {}

    def dft(self, input_name: str = "input") -> None:
        """Record a 1D DFT operation on the given input symbol.

        Args:
            input_name: symbolic buffer name
            axis: optional axis along which to perform the DFT (handled by lowering)
        """
        # default: None means perform full ND DFT across all axes
        self.ops.append(("dft", input_name, None))

    def input(self, name: str, shape: Optional[tuple] = None) -> None:
        """Register a symbolic buffer name as the function input.

        This maps `name` to the function's input memrefs (%arg0/%arg1).
        The `shape` parameter is currently unused (placeholder for future
        shape validation).
        """
        self.registered_buffers[name] = "input"

    def output(self, name: str, shape: Optional[tuple] = None) -> None:
        """Register a symbolic buffer name as the function output.

        This maps `name` to the function's output memrefs (%arg2/%arg3).
        """
        self.registered_buffers[name] = "output"

    # New builder primitives (record-only). Each records a tuple where
    # the first element is the op name and the remaining elements are
    # operands/parameters. These are lowered by `fft_builder`.

    def twiddle_mul(self, input_name: str, output_name: str, N1: int, N2: int, axis: int = -1) -> None:
        """Record a twiddle multiplication op.

        Semantics: elementwise multiply the complex vector `input_name`
        by a twiddle table of size N = N1 * N2 and store to `output_name`.
        """
        self.ops.append(("twiddle_mul", input_name, output_name, N1, N2, axis))

    def butterfly(self, a: str, b: str, w: str, out1: str, out2: str, axis: int = -1) -> None:
        """Record a (elementwise) complex butterfly:

        out1 = a + b * w
        out2 = a - b * w
        where a,b,w are names of complex buffers (real/imag pairs)
        """
        self.ops.append(("butterfly", a, b, w, out1, out2, axis))

    def permute(self, input_name: str, output_name: str, pattern, axis: int = -1) -> None:
        """Record a permutation of elements according to `pattern`.

        `pattern` should be an iterable of length N describing the target
        index for each source index.
        """
        self.ops.append(("permute", input_name, output_name, list(pattern), axis))

    def reshape(self, input_name: str, output_name: str, new_shape, axis: int = -1) -> None:
        """Record a reshape (reinterpret) from `input_name` to `output_name`.

        For 1D current prototype this is a no-op and serves as a hint.
        """
        self.ops.append(("reshape", input_name, output_name, tuple(new_shape), axis))

    def stockham_stage(self, input_name: str, output_name: str, stage: int, axis: int = -1) -> None:
        """Record a single Stockham stage applied to `input_name` producing `output_name`.

        `stage` is the stage index (0-based), block = 2**stage.
        """
        self.ops.append(("stockham_stage", input_name, output_name, stage, axis))

    def stockham_fft(self, input_name: str, output_name: str, axis = None) -> None:
        """Record a full Stockham FFT high-level op. Lowers to multiple stages.
        """
        self.ops.append(("stockham_fft", input_name, output_name, axis))
    
    # Add this method inside class AlgorithmBuilder, after stockham_fft.
    # It records a Cooley‑Tukey operation into the builder's op list.
    def cooley_tukey_fft(self, input, output, axis = None) -> None:
        self.ops.append(("cooley_tukey_fft", input, output, axis))

class Algorithm:
    """Wrapper for a user-defined algorithm function.

    The wrapped object provides `compile_to_mlir(N, name)` which runs the
    user function with an `AlgorithmBuilder`, records ops, and calls the
    fft_builder to produce MLIR text.
    """

    def __init__(self, func: Callable[..., Any], *, default_N: Optional[int] = None):
        self._func = func
        self._default_N = default_N

    def compile_to_mlir(self, N: Optional[int] = None, name: Optional[str] = None, mode: str = "text") -> str:
        """Compile the decorated algorithm to MLIR text.

        Args:
            N: FFT size (overrides decorator default if provided).
            name: optional MLIR function name.
        Returns:
            MLIR module text string.
        """
        if N is None:
            if self._default_N is None:
                raise ValueError("FFT size N must be provided")
            N = self._default_N

        # run user function with a fresh builder to record ops
        builder = AlgorithmBuilder()
        # user function expected to accept one argument: the builder
        self._func(builder)

        # Import local transform to avoid circular imports at module load
        from .transform.fft_builder import build_mlir_from_builder

        return build_mlir_from_builder(builder, N, name, mode)


def algorithm(*, size: Optional[int] = None) -> Callable[[Callable[..., Any]], Algorithm]:
    """Decorator factory for FFT algorithms.

    Usage:
      @algorithm(size=8)
      def myalg(b):
          b.dft('x')

      mlir = myalg.compile_to_mlir()
    """

    def _decorator(func: Callable[..., Any]) -> Algorithm:
        return Algorithm(func, default_N=size)

    return _decorator
