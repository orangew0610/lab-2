# 课程小组实验仅需用到或者扩展frontend/python中的文件，以及测试文件test/myfft和新建的AI接入文件
# myFFT 设计与在 matrix-mlir 中的集成说明

该文档将你的 `myFFT.txt` 设计要点，映射到当前仓库（matrix-mlir）的具体位置与实现建议。

目标：在不改变仓库既有目录结构和 backend 的前提下，将 FFT 编译器设计逐步集成到 `frontend`（Python 前端）和 `midend`（MLIR dialect / conversion / passes）。

---

## 一、总体策略（摘要）

- Frontend（Python）：提供用户友好的 Python API（例如 `@fftc.algorithm` 装饰器），捕获用户的 FFT 算法/符号表达，构建 graph/FFTOp，并能导出 MLIR（优先生成通用 dialect，如 `linalg` / `tensor` / `arith`；未来可选择生成 midend FTM dialect op？）。
- Midend（C++ / TableGen）：定义/扩展 FFT 专用 TableGen op（如 `AkI_xOp`, `IkA_xOp`, `PermuteOp`, `TwiddleMulOp`），并实现 conversion/optimization passes（pattern match -> replace -> tiling/vectorization -> lower to FTM/LLVMIR）。
- Backend（不改）：midend 输出需保持到 backend 已有的 pipeline（FTM->LLVMIR 或已支持的 dialect），确保无需更改 `backend`。

---

## 二、文档位置与新增文件（frontend）

在 `frontend/Python` 内新增并维护以下文档/模块（按实现顺序）：

- `frontend/Python/ops/fft.py`（高层符号/Op 定义）
  - 定义：`FFTOp`、`DFTMatrix`、`TwiddleMatrix`、`Permute` 等符号类。
  - 接口要求：继承或兼容 `graph/operation.py` 中的 Operation 接口（name, args, tensor_meta, to_mlir/serialize）。

- `frontend/Python/transform/fft_builder.py`（构建器）
  - 负责把用户编写的符号表达或装饰器捕获结果转为 graph（node）或直接构建 MLIR module（临时阶段用 linalg 表达）。

- `frontend/Python/frontend.py`（API 暴露）
  - 增加 `@fftc.algorithm` 装饰器入口说明（见下方“装饰器说明”）。
  - 注意：早期样例中在 `frontend.py` 中添加了一个 `compile_fft_to_mlir()` 测试 helper；该 helper 已移除，推荐通过 `frontend/Python/fftc.py` 的装饰器 API 或直接调用 `frontend/Python/ops/fft.py::gen_dft_mlir_bindings` 来生成 MLIR（现在仅支持 bindings 模式）。

  ## 最近工作进度（补充）

  - 我们已把原先的文本 DFT 生成器移除，统一使用 MLIR Python bindings（`gen_dft_mlir_bindings`）进行生成/降低。
  - 新增了 builder 原语：`twiddle_mul`, `butterfly`, `permute`, `reshape`, `stockham_stage`, `stockham_fft`，这些记录在 `AlgorithmBuilder.ops` 中，由 `transform/fft_builder.py` 读取并调用 `ops/fft` 中的 bindings helper 完成实际 MLIR 构造。
  - 把低阶算子（twiddle/butterfly/permute/reshape/stockham_stage）的 bindings-lowering helper 放在 `frontend/Python/ops/fft.py`（便于复用与单测），并让 `fft_builder` 负责序列化地把 builder.ops 映射到这些 helper 调用。

  ## 已知问题与说明：buffer 连接

  发现一个值得注意的问题（也是预期行为）：

  - 当用户直接调用 `b.stockham_fft('s1', 'output', N)` 且没有事先把 `'s1'` 显式注册为输入缓冲符号时，当前实现的 `fft_builder` 会在 `ensure_buffer('s1')` 时为该名称分配新的临时 memref（`memref.alloc`），因此后续的 `memref.load` 会读取未初始化的临时缓冲区。
  - 正确的用法是使用内置的 input 符号名称（`'input'`），因为 `fft_builder` 在函数入口处把 symbol 名称 `'input'` 映射到了函数参数 `%arg0/%arg1`（实/虚部）。例如：

  ```python
  @algorithm(size=4)
  def test_ops(b):
    b.stockham_fft('input', 'output', 4)  # 'input' maps to function args
  ```

  - 若希望使用其它名字（例如 `'s1'`）作为函数输入，需要在 builder 层显式注册该名字并映射到函数参数（当前 API 尚未提供显式 `input(name, shape)` 方法；后续可以添加）。否则当前行为会生成 `memref.alloc`。

  ## 测试用例（已添加）

  我已在 `test/myfft/frontend/` 下添加两个简单的 smoke 脚本，用于演示并回归上述行为：

  - `test_stockham_buffer_mapping_correct.py`：使用 `'input'`，断言生成 MLIR 中存在 `memref.load %arg0` 或 `memref.load %arg1`（表明数据来自函数参数）。
  # myFFT：设计说明与当前实现综述

  该文档是当前仓库中 FFT 前端（Python）实现的简要说明与开发手册，包含：
  - 当前实现所在文件与导出函数/原语清单；
  - 每个函数/原语的签名与语义（简明）；
  - 现有测试映射与运行要点；
  - 下一步建议与注意事项。

  本文档目标受众：项目贡献者（需要理解 builder → lowering → MLIR 的流程）以及希望用装饰器 API 快速生成并 JIT 运行 FFT 的开发者。

  ## 1) 关键实现文件（位置）

  - `frontend/Python/fftc.py` — builder / 装饰器接口（AlgorithmBuilder、algorithm 装饰器、Algorithm wrapper）。
  - `frontend/Python/transform/fft_builder.py` — 将 builder 记录（AlgorithmBuilder.ops）用 MLIR Python bindings 降低为 MLIR Module（当前仅支持 mode='bindings'）。
  - `frontend/Python/ops/fft.py` — bindings-lowering helpers（DFT generator、lower_* helpers），包含低阶算子实现：complex mul、twiddle、butterfly、permute、reshape、stockham stage/fft。
  - `frontend/Python/ops/fft_mlir_runner.py` — （辅助）把 MLIR 降低到 LLVM 并用 ExecutionEngine JIT 运行（numpy <-> ranked memref 转换）。
  - `test/myfft/frontend/` — 若干单元/示例测试脚本（用于回归和 JIT 验证）。

  ## 2) Builder / 装饰器 API（概要）

  文件：`frontend/Python/fftc.py`

  - class AlgorithmBuilder
    - 属性：ops (list of tuples)、registered_buffers (dict name -> 'input'|'output')
    - 记录型原语（record-only）：
      - dft(input_name: str = 'input')
        - 记录: ("dft", input_name, axis)
        - 说明：axis 默认 None（表示按所有轴进行可分离 ND DFT）；在 builder 中默认将其记录为全 ND DFT。

      - twiddle_mul(input_name: str, output_name: str, N1: int, N2: int, axis: int = -1)
        - 记录: ("twiddle_mul", in, out, N1, N2, axis)
        - 说明：对指定 axis 上的元素按 twiddle table 乘法。

      - butterfly(a: str, b: str, w: str, out1: str, out2: str, axis: int = -1)
        - 记录: ("butterfly", a, b, w, out1, out2, axis)
        - 说明：元素级蝶形操作 out1 = a + b * w, out2 = a - b * w。

      - permute(input_name: str, output_name: str, pattern: Sequence[int], axis: int = -1)
        - 记录: ("permute", in, out, pattern, axis)
        - 说明：沿 axis 做离散索引置换。

      - reshape(input_name: str, output_name: str, new_shape: Sequence[int], axis: int = -1)
        - 记录: ("reshape", in, out, new_shape, axis)
        - 说明：当前为 elementwise copy / hint（no-op）实现。

      - stockham_stage(input_name: str, output_name: str, stage: int, axis: int = -1)
        - 记录: ("stockham_stage", in, out, stage, axis)
        - 说明：单个 Stockham stage（radix-2 典型内部实现）。

      - stockham_fft(input_name: str, output_name: str, axis = None)
        - 记录: ("stockham_fft", in, out, axis)
        - 说明：高阶算子，会在 lowering 阶段展开为若干 `permute` + `stockham_stage` 插入到 builder.ops 中。axis 默认 None 表示按每个轴顺次做可分离 ND Stockham。

    - 注册 API（用于把 symbol 绑定到函数参数）:
      - input(name: str, shape: Optional[tuple] = None)
      - output(name: str, shape: Optional[tuple] = None)
      - 说明：若一个 symbol 在 registered_buffers 中被标记为 'input' 或 'output'，fft_builder 在 lowering 时会把该名字映射到函数入口参数 (`%arg0/%arg1` 为实/虚部输入，`%arg2/%arg3` 为实/虚部输出)，从而避免对该名字执行 `memref.alloc`。

  - decorator: algorithm(size: Optional[int] = None)
    - 返回一个 Algorithm 包装对象，包装对象提供 `compile_to_mlir(N=None, name=None, mode='text'|'bindings')`。
    - 注意：当前仅支持 `mode='bindings'`，text 模式的旧文本生成器已基本被替代（剩余函数仍存在于 `ops/fft.py`）。

  ## 3) Lowering helpers（接口与行为）

  文件：`frontend/Python/ops/fft.py`

  - gen_dft_mlir_bindings(N: int or Sequence[int], name: Optional[str]) -> str
    - 功能：使用 MLIR Python bindings 创建设备为 `func.func` 的 Module（返回字符串形式）。实现为直接的 O(N^2) DFT（主要用于调试、对照和早期验证）。支持 N 为整数或 shape 列表（ND）。

  - lower_complex_mul(a_re, a_im, b_re, b_im, arith)
    - 功能：在当前插入点生成复数乘法运算（返回 (re, im)）。

  - lower_dft_into(in_r, in_i, out_r, out_i, shape, axis, f32, arith, memref, idx_type)
    - 功能：把 DFT（按 axis）降低到当前插入点；当 axis=None 时执行可分离 ND DFT（对每个轴的组合索引做全乘加）。

  - lower_twiddle_mul(in_r,in_i,out_r,out_i,shape,axis,N1,N2,f32,arith,memref,idx_type)
    - 功能：沿 axis 对每个元素乘以 precomputed twiddle 值并写到 out。

  - lower_butterfly(a_r,a_i,b_r,b_i,w_r,w_i,out1_r,out1_i,out2_r,out2_i,shape,axis,arith,memref,idx_type)
    - 功能：沿 axis 做元素级蝶形（从 a,b,w 加载，计算后写回 out1/out2）。

  - lower_permute(in_r,in_i,out_r,out_i,pattern,shape,axis,arith,memref,idx_type)
    - 功能：按给定 pattern 沿 axis 做元素复制（置换）。

  - lower_reshape(in_r,in_i,out_r,out_i,new_shape,axis,arith,memref,idx_type)
    - 功能：按 new_shape 遍历并逐元素复制（当前实现为 elementwise copy）。

  - lower_stockham_stage(in_r,in_i,out_r,out_i,shape,axis,stage,f32,arith,memref,idx_type)
    - 功能：实现 Stockham 单阶段（radix-2 分支），使用 classic iterative butterfly，将结果写回自然位置（u_idx, v_idx）。

  - lower_stockham_fft(in_name,out_name,shape,axis,symtab,builder_ops_insert,f32,arith,memref,idx_type)
    - 功能：高阶 Stockham op 的展开器：当 builder 中遇到 `("stockham_fft", in, out, axis)` 时，lowering 会调用该 helper。它会：
      - 如果 axis=None，则按每个轴顺次处理（可分离 ND Stockham）；
      - 对每个轴先插入 bit-reversal 的 `permute`（builder_ops_insert 会把新的 `permute` op 插入到 builder.ops），随后按 stage 插入 `stockham_stage`；
      - 最后确保最终结果写到用户的 out buffer（若有中间临时名则会插入一次 identity-permute 以复制结果）。

  注意：这些 helpers 都依赖传入的 `arith`, `memref`, `idx_type` 等类型和值，以便在当前 MLIR 插入点上生成对应的 ops（这是 bindings-lowering 风格的设计）。

  ## 4) 典型 lowering 流程（简述）

  1. 用户通过 `@algorithm(size=...)` 装饰器定义算法函数，该函数在编译时被调用并接收一个 `AlgorithmBuilder` 实例。
  2. 用户使用 builder 的方法（如 `b.stockham_fft('input','output')`）来记录操作序列。
  3. 调用 `Algorithm.compile_to_mlir(...)` 时会调用 `build_mlir_from_builder`：此函数创建 MLIR 模块 / 函数并为默认 input/output 建立符号表映射；随后按顺序迭代 builder.ops，调用 `ops.fft` 中的对应 `lower_*` helper 在当前插入点生成 MLIR ops。
  4. 对于 `stockham_fft` 这样的高阶 op，lowering 通过 `lower_stockham_fft` 展开更多 op（permute + stockham_stage）并把它们插入到 builder.ops 中，随后这些新 op 会在后续迭代中被处理和降低。

  ## 5) 测试文件与映射（当前仓库中相关测试）

  位置：`test/myfft/frontend/`

  - test_dft_jit.py
    - 作用：使用 `@algorithm` 装饰器生成 DFT 的 MLIR（bindings 模式），用 `fft_mlir_runner.run_mlir_module` JIT 运行并与 numpy 的 `np.fft.fftn` 做数值对比。

  - test_stockham_fft*_jit.py（若干变体）
    - 作用：测试 stockham 的分阶段展开、bindings 降低和 JIT 数值正确性（1D/2D 小规模例子）。

  运行说明：许多测试依赖本地 Python 环境能 import MLIR Python bindings 和 numpy；你可能需要激活项目虚拟环境并设置 PYTHONPATH 指向构建的 MLIR Python 包和仓库的 Python 目录（这是此前测试运行时需要的步骤）。

  ## 6) 已知问题与使用注意

  - Builder 名称绑定：若希望一个符号名使用函数输入/输出缓冲，请先用 `builder.input(name)` / `builder.output(name)` 注册（当前实现已支持这些方法）；否则 `fft_builder` 会对未注册的名字执行 `memref.alloc` 分配临时缓冲区。
  - API 兼容性：若你从早期样例迁移，注意 `dft` 与 `stockham_fft` 的默认 axis 已由早期单一 N 参数语义变为 axis-aware（默认 axis=None 表示 ND 可分离）。因此旧测试可能需要更新为新的参数顺序/语义。
  - 性能：当前降低器主要面向正确性与原型验证（例如 `gen_dft_mlir_bindings` 是 O(N^2) 的直接实现）。要获得高性能需要 midend 的 TableGen ops + 优化 passes。


  ## 8) 简短示例

  1) 编写并生成 MLIR（bindings 模式）：

  ```py
  from frontend.Python.fftc import algorithm

  @algorithm(size=(2,4))
  def fft_test(b):
      # use default registered 'input' / 'output' symbols
      b.dft('input')

  mlir = fft_test.compile_to_mlir(name='fft_test_dft', mode='bindings')
  print(mlir)
  ```

  2) Stockham（高阶 op，会在 lowering 阶段展开）：

  ```py
  @algorithm(size=(2,4))
  def fft_stockham(b):
      b.stockham_fft('input', 'output')  # axis=None => separable ND

  mlir = fft_stockham.compile_to_mlir(mode='bindings')
  ```

