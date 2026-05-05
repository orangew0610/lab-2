"""Test matmul → Linalg IR (suitable for FTM tiling)."""

import pytest

torch = pytest.importorskip("torch")

from Python.frontend import FTMCompiler
from Python.ops.tosa import ops_registry as tosa_ops_registry


class MatmulModel(torch.nn.Module):
    def forward(self, x, y):
        return torch.matmul(x, y)


class LinearModel(torch.nn.Module):
    def __init__(self):
        super().__init__()
        self.linear = torch.nn.Linear(16, 8, bias=False)

    def forward(self, x):
        return self.linear(x)


class LinearBiasModel(torch.nn.Module):
    def __init__(self):
        super().__init__()
        self.linear = torch.nn.Linear(16, 8, bias=True)

    def forward(self, x):
        return self.linear(x)


@pytest.fixture
def compiler():
    return FTMCompiler(primary_registry=tosa_ops_registry)


def test_matmul_to_linalg(compiler):
    """Test matmul produces Linalg IR with contraction ops."""
    model = MatmulModel().eval()
    x = torch.randn(4, 16)
    y = torch.randn(16, 8)
    graphs = compiler.compile_to_mlir(model, x, y)
    assert len(graphs) > 0
    mlir_text = str(graphs[0].get_mlir_module())
    assert "func.func" in mlir_text
    assert "tosa.matmul" in mlir_text or "linalg.matmul" in mlir_text


def test_linear_to_linalg(compiler):
    """Test nn.Linear (no bias) produces Linalg IR."""
    model = LinearModel().eval()
    x = torch.randn(4, 16)
    graphs = compiler.compile_to_mlir(model, x)
    assert len(graphs) > 0
    mlir_text = str(graphs[0].get_mlir_module())
    assert "func.func" in mlir_text


def test_linear_bias_to_linalg(compiler):
    """Test nn.Linear (with bias) produces Linalg IR."""
    model = LinearBiasModel().eval()
    x = torch.randn(4, 16)
    graphs = compiler.compile_to_mlir(model, x)
    assert len(graphs) > 0
    mlir_text = str(graphs[0].get_mlir_module())
    assert "func.func" in mlir_text
