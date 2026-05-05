"""Test JIT execution correctness vs PyTorch eager mode."""

import pytest

torch = pytest.importorskip("torch")
import numpy as np

from Python.frontend import FTMCompiler
from Python.ops.tosa import ops_registry as tosa_ops_registry


class SimpleAdd(torch.nn.Module):
    def forward(self, x, y):
        return x + y


class SimpleMul(torch.nn.Module):
    def forward(self, x, y):
        return x * y


class SimpleLinear(torch.nn.Module):
    def __init__(self):
        super().__init__()
        self.linear = torch.nn.Linear(8, 4, bias=False)

    def forward(self, x):
        return self.linear(x)


@pytest.fixture
def compiler():
    return FTMCompiler(primary_registry=tosa_ops_registry)


def _compare_results(jit_results, eager_results, atol=1e-5, rtol=1e-5):
    """Compare JIT results with PyTorch eager results."""
    if isinstance(eager_results, torch.Tensor):
        eager_results = [eager_results]
    if not isinstance(jit_results, list):
        jit_results = [jit_results]

    assert len(jit_results) == len(eager_results), (
        f"Output count mismatch: JIT={len(jit_results)}, "
        f"eager={len(eager_results)}"
    )
    for i, (jit_out, eager_out) in enumerate(zip(jit_results, eager_results)):
        if isinstance(jit_out, torch.Tensor):
            jit_np = jit_out.detach().numpy()
        else:
            jit_np = np.array(jit_out)
        eager_np = eager_out.detach().numpy()
        np.testing.assert_allclose(
            jit_np, eager_np, atol=atol, rtol=rtol,
            err_msg=f"Output {i} mismatch"
        )


def test_jit_add(compiler):
    """Test JIT add matches PyTorch eager."""
    model = SimpleAdd().eval()
    x = torch.randn(2, 4)
    y = torch.randn(2, 4)

    eager_result = model(x, y)
    jit_result = compiler.jit_run(model, x, y)
    _compare_results(jit_result, eager_result)


def test_jit_mul(compiler):
    """Test JIT mul matches PyTorch eager."""
    model = SimpleMul().eval()
    x = torch.randn(2, 4)
    y = torch.randn(2, 4)

    eager_result = model(x, y)
    jit_result = compiler.jit_run(model, x, y)
    _compare_results(jit_result, eager_result)


def test_jit_linear(compiler):
    """Test JIT linear matches PyTorch eager."""
    model = SimpleLinear().eval()
    x = torch.randn(2, 8)

    eager_result = model(x)
    jit_result = compiler.jit_run(model, x)
    _compare_results(jit_result, eager_result)
