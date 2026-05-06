# 李玉森 - Cooley‑Tukey 算法扩展工作记录

## 修改的文件
1. `frontend/Python/fftc.py` – 添加 `cooley_tukey_fft` 方法，用于记录 Cooley‑Tukey 操作
2. `frontend/Python/transform/fft_builder.py` – 添加 `cooley_tukey_fft` 和 `cooley_tukey_stage` 的分支，并在导入列表中加入对应 lowering 函数
3. `frontend/Python/ops/fft.py` – 新增 `lower_cooley_tukey_stage` 和 `lower_cooley_tukey_fft`，实现算法展开

## 实现概要
- **位反序**：通过 `permute` 原语，预计算 bit‑reverse 索引映射，将输入重排到临时缓冲区
- **多级蝶形**：每个 stage 复用 `lower_stockham_stage`（蝶形公式相同），共 `log2(N)` 级
- **支持长度**：N = 2^k（测试 N=8 通过），仅支持一维 FFT

## 验证结果
运行 `test_cooley.py`，生成合法 MLIR 模块，输出中包含：
- 位反序的 `memref.load/store` 序列
- 多级蝶形运算（复数乘法、加法、旋转因子常量）
- 无报错，MLIR 结构完整

## 接口说明（供 B 组调用）
```python
builder.cooley_tukey_fft('input', 'output', n)