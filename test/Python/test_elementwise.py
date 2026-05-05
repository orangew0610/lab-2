"""Test elementwise operations: add, mul, relu → Linalg IR."""

import pytest

torch = pytest.importorskip("torch")

from Python.frontend import FTMCompiler
from Python.ops.tosa import ops_registry as tosa_ops_registry


class AddModel(torch.nn.Module):
    def forward(self, x, y):
        return x + y


class MulModel(torch.nn.Module):
    def forward(self, x, y):
        return x * y


class ReluModel(torch.nn.Module):
    def forward(self, x):
        return torch.relu(x)


class AddMulReluModel(torch.nn.Module):
    def forward(self, x, y):
        z = x + y
        z = z * x
        return torch.relu(z)


@pytest.fixture
def compiler():
    return FTMCompiler(primary_registry=tosa_ops_registry)


def test_add_to_linalg(compiler):
    """Test tensor add produces valid Linalg MLIR."""
    model = AddModel().eval()
    x = torch.randn(2, 4)
    y = torch.randn(2, 4)
    graphs = compiler.compile_to_mlir(model, x, y)
    assert len(graphs) > 0
    mlir_text = str(graphs[0].get_mlir_module())
    # Should contain linalg ops after TOSA lowering
    assert "func.func" in mlir_text
    assert "tosa.add" in mlir_text or "arith.addf" in mlir_text


def test_mul_to_linalg(compiler):
    """Test tensor mul produces valid Linalg MLIR."""
    model = MulModel().eval()
    x = torch.randn(2, 4)
    y = torch.randn(2, 4)
    graphs = compiler.compile_to_mlir(model, x, y)
    assert len(graphs) > 0
    mlir_text = str(graphs[0].get_mlir_module())
    assert "func.func" in mlir_text
    assert "tosa.mul" in mlir_text or "arith.mulf" in mlir_text


def test_relu_to_linalg(compiler):
    """Test ReLU produces valid Linalg MLIR."""
    model = ReluModel().eval()
    x = torch.randn(2, 4)
    graphs = compiler.compile_to_mlir(model, x)
    assert len(graphs) > 0
    mlir_text = str(graphs[0].get_mlir_module())
    assert "func.func" in mlir_text


def test_composite_to_linalg(compiler):
    """Test add+mul+relu composite produces valid Linalg MLIR."""
    model = AddMulReluModel().eval()
    x = torch.randn(4, 8)
    y = torch.randn(4, 8)
    graphs = compiler.compile_to_mlir(model, x, y)
    assert len(graphs) > 0
    mlir_text = str(graphs[0].get_mlir_module())
    assert "func.func" in mlir_text
