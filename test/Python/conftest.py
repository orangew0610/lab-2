"""pytest configuration for FTM Python frontend tests."""

import sys
import os
from pathlib import Path

# Add MLIR Python bindings and FTM package to path
_project_root = Path(__file__).resolve().parent.parent.parent
_mlir_python = _project_root / "llvm" / "build" / "tools" / "mlir" / "python_packages" / "mlir_core"
_ftm_python = _project_root / "build" / "python_packages"

if str(_mlir_python) not in sys.path:
    sys.path.insert(0, str(_mlir_python))
if str(_ftm_python) not in sys.path:
    sys.path.insert(0, str(_ftm_python))

# Also add the source directory directly for development use
_src_python = _project_root / "frontend" / "Python"
_src_parent = _project_root / "frontend"
if str(_src_parent) not in sys.path:
    sys.path.insert(0, str(_src_parent))
