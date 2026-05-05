//===- fft_ops.td - FFT extension ops (prototype) -------------------------===//
//
// This file provides a minimal TableGen sketch for FFT-specific
// linalg-like operations. It's a starting point (prototype). It
// intentionally keeps type constraints light and documents intended
// semantics. Later iterations should refine operand/result types,
// add verification, ODS interfaces, and C++ op definitions.
//
// Placement: frontend/include/mlir/fft_ops.td
// NOTE: This file is a prototype scaffold. It may need adjustments to
// integrate with the repo's existing MLIR Dialect registration and
// build system (CMake). Treat this as Task A's initial artifact.
//===----------------------------------------------------------------------===//

include "mlir/Dialect/Linalg/IR/LinalgBase.td"
include "mlir/Dialect/Linalg/IR/LinalgOps.td"

// extend 'linalg'
// final design we may either extend 'linalg' or provide these ops in a
// compatible dialect and then provide conversion passes into linalg.

// AkI_x op: semantic: Y = (A ⊗ I) · X
// This is a linalg-like contraction where A acts on a subset of
// dimensions of X via a Kronecker product with identity on remaining dims.
// For the prototype we accept generic tensor/memref operands and a small
// attribute bag to describe the layout/axes.

def Linalg_AkI_xOp : LianlgOp<"akI_x", [Pure]> {
  let summary = "Apply (A ⊗ I) to X producing Y";
  let description = [{
    AkI_x implements the semantics Y = (A ⊗ I) * X. The op accepts
    an input tensor/memref `A`, an input `X` and produces an output `Y`.
    Attributes describe which axes of X are contracted by A.
  }];

  // Operands/results are left intentionally generic in this prototype.
  let arguments = (ins AnyType:$A, AnyType:$X);
  let results = (outs AnyType:$Y);

  let assemblyFormat = "attr-dict ($A, $X) : $A, $X -> $Y";
}

// IkA_x op: semantic: Y = (I ⊗ A) · X
// Similar to AkI_x but A applies to a trailing/other block of axes.

def FFT_IkA_xOp : Op<"fft.ikA_x", [NoSideEffect]> {
  let summary = "Apply (I ⊗ A) to X producing Y";
  let description = [{
    IkA_x implements Y = (I ⊗ A) * X. Operand/result typing and
    attributes parallel AkI_x.
  }];

  let arguments = (ins AnyType:$A, AnyType:$X);
  let results = (outs AnyType:$Y);

  let assemblyFormat = "attr-dict ($A, $X) : $A, $X -> $Y";
}

// Permute op: elementwise permutation along one axis (pattern attr)

def FFT_PermuteOp : Op<"fft.permute", [NoSideEffect]> {
  let summary = "Permute indices along a single axis according to a pattern";
  let description = [{
    Permute copies elements from the input tensor to the output tensor
    according to an integer permutation `pattern` attribute. The op
    accepts `in`, `out` operands and an `axis` and `pattern` attribute.
  }];

  let arguments = (ins AnyType:$in);
  let results = (outs AnyType:$out);

  let extraClassDeclaration = "  static LogicalResult verify(InFlightDiagnostic &diag, Operation *op) { return success(); }";

  let defaultBuilder = "";

  let argumentsDoc = [
    "in: input tensor/memref",
    "out: output tensor/memref"
  ];

  let attributes = (
    // axis: integer attribute indicating which axis is being permuted
    I64Attr:$axis,
    // pattern: dense integer elements attribute (array of ints)
    ArrayAttr:$pattern
  );

  let assemblyFormat = "{axis = $axis, pattern = $pattern} ($in) : $in -> $out";
}

// Stockham stage op: single Stockham radix-2 stage
// The op encapsulates the per-axis butterflies and twiddle factors for
// one stage. Attributes indicate stage index and axis; operands are
// input and output tensors (real/imag could be represented as two
// operands or a complex-typed tensor in extensions).

def FFT_StockhamStageOp : Op<"fft.stockham_stage", [NoSideEffect]> {
  let summary = "Perform one Stockham radix-2 stage along an axis";
  let description = [{
    StockhamStage implements one stage of an in-place or out-of-place
    Stockham FFT along a given axis. It carries attributes `stage` and
    `axis` and accepts input/output operands.
  }];

  let arguments = (ins AnyType:$in);
  let results = (outs AnyType:$out);

  let attributes = (
    I64Attr:$stage,
    I64Attr:$axis
  );

  let assemblyFormat = "{stage = $stage, axis = $axis} ($in) : $in -> $out";
}

// End of prototype ops

// Notes:
// - This is intentionally a light-weight TableGen scaffold to record the
//   op names, purpose and basic attribute/operand models. Integrating
//   these ops into the MLIR build & C++ side requires further work:
//   generating C++ op classes via ODS, implementing verification builders,
//   and adding registration in the dialect's C++ code.
// - Next steps: refine operand/result types (e.g., ranked tensor/memref
//   shape/type constraints), implement parse/print and verification, and
//   add unit tests exercising the op creation via MLIR Python bindings.
