"""Test that the FTM compiler frontend can be imported."""

import pytest


def test_import_mlir_ir():
    """Verify MLIR Python bindings are available."""
    import mlir.ir
    ctx = mlir.ir.Context()
    assert ctx is not None


def test_import_mlir_dialects():
    """Verify key MLIR dialect bindings are available."""
    from mlir.dialects import tosa, linalg, arith, math, func, tensor


def test_import_graph_module():
    """Verify the graph module imports cleanly."""
    from Python.graph import Graph, NodeType, TensorDType, TensorMeta, DeviceType


def test_import_ops_modules():
    """Verify all ops modules import cleanly."""
    from Python.ops import tosa as tosa_ops
    from Python.ops import linalg as linalg_ops
    from Python.ops import math as math_ops
    from Python.ops import func as func_ops
    from Python.ops import utils as utils_ops

    # Verify registries exist
    assert isinstance(tosa_ops.ops_registry, dict)
    assert isinstance(linalg_ops.ops_registry, dict)
    assert isinstance(math_ops.ops_registry, dict)
    assert isinstance(func_ops.ops_registry, dict)


def test_import_pipeline():
    """Verify the FTM pipeline module imports cleanly."""
    from Python.pipeline import FTMPipeline


def test_import_dynamo_compiler():
    """Verify DynamoCompiler can be imported (requires torch)."""
    torch = pytest.importorskip("torch")
    from Python.frontend import DynamoCompiler, FTMCompiler


def test_device_type_ftm():
    """Verify DeviceType.FTM is available."""
    from Python.graph.type import DeviceType
    assert DeviceType.FTM.value == "ftm"


def test_ops_registry_coverage():
    """Verify ops registries contain expected operations."""
    from Python.ops.tosa import ops_registry as tosa_reg
    from Python.ops.math import ops_registry as math_reg

    from Python.ops.linalg import ops_registry as linalg_reg

    # TOSA should have common ops
    assert "AddOp" in tosa_reg
    assert "ReluOp" in tosa_reg
    assert "Conv2dOp" in tosa_reg

    # Linalg should have matmul
    assert "MatmulOp" in linalg_reg

    # Math should have transcendental ops
    assert "SqrtOp" in math_reg
    assert "ExpOp" in math_reg
    assert "LogOp" in math_reg
    assert "RsqrtOp" in math_reg
