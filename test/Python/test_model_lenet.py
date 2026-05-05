"""Test LeNet end-to-end: conv2d + pool + fc + relu → Linalg IR.

Uses scaled-up channel/spatial dimensions so that all features >= 32
(f32 vector width), enabling FTM vectorization pass verification.
"""

import pytest

torch = pytest.importorskip("torch")

from Python.frontend import FTMCompiler
from Python.ops.tosa import ops_registry as tosa_ops_registry


class LeNet(torch.nn.Module):
    """Scaled-up LeNet for vectorization testing.

    All channel and spatial dimensions >= 32 so the FTM cost model can
    select a parallel dimension for tiling/vectorization.

    Architecture (input 1×32×64×64):
      conv1  32→64, k=5, pad=2  → 64×64×64
      pool   2×2                 → 64×32×32
      conv2  64→128, k=5         → 128×28×28
      pool   2×2                 → 128×14×14   (14 < 32, but channels 128 ok)
      fc1    128*14*14=25088→512
      fc2    512→256
      fc3    256→10
    """

    def __init__(self):
        super().__init__()
        self.conv1 = torch.nn.Conv2d(32, 64, 5, padding=2)
        self.pool = torch.nn.MaxPool2d(2, 2)
        self.conv2 = torch.nn.Conv2d(64, 128, 5)
        self.fc1 = torch.nn.Linear(128 * 14 * 14, 512)
        self.fc2 = torch.nn.Linear(512, 256)
        self.fc3 = torch.nn.Linear(256, 10)

    def forward(self, x):
        x = self.pool(torch.relu(self.conv1(x)))
        x = self.pool(torch.relu(self.conv2(x)))
        x = x.view(-1, 128 * 14 * 14)
        x = torch.relu(self.fc1(x))
        x = torch.relu(self.fc2(x))
        x = self.fc3(x)
        return x


INPUT_SHAPE = (1, 32, 64, 64)


@pytest.fixture
def compiler():
    return FTMCompiler(primary_registry=tosa_ops_registry)


def test_lenet_to_linalg(compiler):
    """Test LeNet produces valid Linalg MLIR."""
    model = LeNet().eval()
    x = torch.randn(*INPUT_SHAPE)
    graphs = compiler.compile_to_mlir(model, x)
    assert len(graphs) > 0
    mlir_text = str(graphs[0].get_mlir_module())
    assert "func.func" in mlir_text
    assert len(mlir_text) > 500


def test_lenet_to_llvmir(compiler):
    """Test LeNet pipeline through ftm-opt and ftm-translate to LLVM IR."""
    from pathlib import Path

    project_root = Path(__file__).resolve().parent.parent.parent
    ftm_opt = project_root / "build" / "bin" / "ftm-opt"
    ftm_translate = project_root / "build" / "bin" / "ftm-translate"

    if not ftm_opt.is_file() or not ftm_translate.is_file():
        pytest.skip("Build tools (ftm-opt, ftm-translate) not available")

    from Python.pipeline import FTMPipeline

    model = LeNet().eval()
    x = torch.randn(*INPUT_SHAPE)
    graphs = compiler.compile_to_mlir(model, x)
    mlir_text = str(graphs[-1].get_mlir_module())

    pipeline = FTMPipeline()
    ftm_mlir = pipeline.lower_to_ftm(mlir_text)
    llvm_ir = pipeline.translate_to_llvmir(ftm_mlir)

    assert "define" in llvm_ir
    assert "llvm.ftm" in llvm_ir
    assert len(llvm_ir) > 1000


def test_lenet_to_lasm(compiler, tmp_path):
    """Test LeNet full pipeline to LASM (requires build tools)."""
    from pathlib import Path

    project_root = Path(__file__).resolve().parent.parent.parent
    ftm_opt = project_root / "build" / "bin" / "ftm-opt"
    llc = project_root / "llvm" / "build" / "bin" / "llc"

    if not ftm_opt.is_file() or not llc.is_file():
        pytest.skip("Build tools (ftm-opt, llc) not available")

    model = LeNet().eval()
    x = torch.randn(*INPUT_SHAPE)
    output_path = str(tmp_path / "lenet.lan")
    graphs = compiler.compile_to_lasm(model, x, output_path=output_path)
    assert len(graphs) > 0
    assert Path(output_path).exists()
    lasm_text = Path(output_path).read_text()
    assert len(lasm_text) > 0
    assert "@func" in lasm_text
