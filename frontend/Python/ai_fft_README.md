# AI FFT编译器模块

## 概述

这是分工中B角色（AI接入）的代码实现，负责：
- LLM API调用（算法推荐）
- 输入解析和输出格式化
- 与A模块（编译器核心）的接口调用

## 特点

- **无需安装LLVM**：你只需要Python环境即可工作
- **支持云端大模型API**：可调用OpenAI等API进行智能算法推荐
- **基于规则的备选方案**：当API不可用时，使用内置规则进行推荐
- **完整的错误处理**：对各种异常情况进行优雅处理

## 文件结构

```
frontend/Python/
├── ai_fft_recommender.py    # AI算法推荐模块
├── ai_fft_interface.py      # 输入解析和接口模块
├── ai_fft_main.py           # 主接口模块
├── ai_fft_example.py        # 使用示例
└── ai_fft_README.md         # 本文档

test/myfft/frontend/
└── test_ai_fft.py           # 测试用例
```

## 快速开始

### 1. 基本使用

```python
from ai_fft_main import create_compiler

# 创建编译器实例
compiler = create_compiler()

# 编译FFT算法
result = compiler.compile(
    algorithm_description="64点快速傅里叶变换",
    problem_size=64,
    environment={
        "target": "CPU",
        "simd_width": 128,
        "optimization_level": "high"
    }
)

# 查看结果
print(f"推荐算法: {result['algorithm_recommendation']['algorithm']}")
print(f"MLIR代码长度: {len(result['generated_mlir'])}")
```

### 2. 使用LLM API

```python
# 使用API key创建编译器
compiler = create_compiler(api_key="your_openai_api_key")

result = compiler.compile(
    algorithm_description="复杂的信号处理FFT",
    problem_size=1024,
    environment={"target": "CPU", "simd_width": 256}
)
```

### 3. 命令行使用

```bash
# 基本用法
python ai_fft_main.py "64点FFT计算" 64

# 指定环境参数
python ai_fft_main.py "SIMD优化FFT" 256 '{"target":"CPU","simd_width":256}'
```

## API接口

### AIFFTCompiler类

主要方法：

- `compile(algorithm_description, problem_size, environment, input_data)` - 编译FFT算法
- `get_supported_algorithms()` - 获取支持的算法列表
- `get_version()` - 获取版本信息

### 输入格式

```python
{
    "algorithm_description": "自然语言描述或数学公式",
    "problem_size": [4, 8],  # 整数或列表
    "environment": {
        "target": "CPU",      # 运行环境
        "simd_width": 128,    # SIMD宽度
        "optimization_level": "high"  # 优化级别
    },
    "input_data": {           # 可选
        "type": "complex",    # 数据类型
        "shape": [4, 8]       # 数据形状
    }
}
```

### 输出格式

```python
{
    "success": True,
    "algorithm_recommendation": {
        "algorithm": "stockham_fft",
        "parameters": {...},
        "rationale": "推荐理由",
        "expected_performance": {...}
    },
    "generated_mlir": "MLIR代码",
    "performance_metrics": {
        "estimated_operations": 1000,
        "estimated_time_seconds": 0.001,
        "data_size": 64,
        "dimensionality": 1,
        "algorithm_efficiency": 0.95
    }
}
```

## 支持的算法

当前支持以下FFT算法：

1. **stockham_fft**
   - 名称: Stockham FFT
   - 时间复杂度: O(N log N)
   - 空间复杂度: O(N)
   - 适用场景: 通用FFT计算、大规模数据、SIMD优化

2. **dft**
   - 名称: 直接DFT
   - 时间复杂度: O(N^2)
   - 空间复杂度: O(1)
   - 适用场景: 小规模数据、调试和验证

## 测试

运行测试用例：

```bash
cd test/myfft/frontend
python test_ai_fft.py
```

## 示例

查看完整使用示例：

```bash
cd frontend/Python
python ai_fft_example.py
```

## 依赖

- Python 3.7+
- requests (用于API调用)
- A模块的Python接口 (`fftc.py`)

## 注意事项

1. **无需LLVM**: 你不需要安装LLVM，所有编译工作由A模块处理
2. **API密钥**: 如需使用LLM推荐功能，需要设置有效的API密钥
3. **错误处理**: 模块包含完整的错误处理机制，API调用失败时会自动回退到基于规则的推荐
4. **性能估算**: 性能指标是基于算法复杂度和数据规模的估算值

## 与A模块的集成

你的代码通过以下方式与A模块（编译器核心）集成：

```python
from fftc import algorithm, AlgorithmBuilder

# 使用A模块的装饰器接口
@algorithm(size=problem_size)
def fft_algorithm(builder):
    # 根据AI推荐调用相应算法
    if algorithm == "stockham_fft":
        builder.stockham_fft('input', 'output')
    elif algorithm == "dft":
        builder.dft('input')

# 生成MLIR代码
mlir_code = fft_algorithm.compile_to_mlir(mode='bindings')
```

## 开发记录

作为B角色，你的主要工作包括：
- ✅ AI算法推荐模块实现
- ✅ 输入解析和输出格式化
- ✅ 与A模块的接口集成
- ✅ 测试用例编写
- ✅ 使用示例和文档

你的代码完全独立，不需要安装LLVM，可以直接调用云端大模型API完成算法推荐任务。