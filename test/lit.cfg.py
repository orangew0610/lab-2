import os
import lit.formats
import lit.util

config.name = 'Matrix-CodeGen'
config.test_format = lit.formats.ShTest(True)
config.suffixes = ['.ll', '.c']
config.test_source_root = os.path.dirname(__file__)
config.test_exec_root = config.matrix_obj_root

# Set targets for lit.local.cfg checks (e.g., "Matrix" in config.root.targets)
config.targets = frozenset(config.targets_to_build.split())

import lit.llvm
lit.llvm.initialize(lit_config, config)

from lit.llvm import llvm_config

tool_dirs = [config.llvm_tools_dir]
tools = ['llc', 'clang', 'FileCheck', 'count', 'not']
llvm_config.add_tool_substitutions(tools, tool_dirs)
