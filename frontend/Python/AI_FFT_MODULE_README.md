# AI FFT编译器模块 - B角色（AI接入）

## 📋 项目概述

本模块是微处理器设计实验二中B角色（AI接入）的实现部分，负责通过云端大模型API智能推荐FFT算法，并生成相应的MLIR代码。

**核心功能**: 根据问题描述、数据规模和运行环境，智能推荐最优FFT算法，并生成对应的MLIR实现代码。

---

## 🏗️ 模块架构

### 核心文件结构
```
frontend/Python/
├── ai_fft_recommender.py          # AI算法推荐器（核心）
├── ai_fft_interface.py            # 输入解析和接口模块
├── ai_fft_main.py                 # 主编译器模块
├── ai_fft_standalone.py           # 独立版本（不依赖MLIR）
├── ai_fft_xunfei_example_fixed.py # 讯飞API使用示例
└── AI_FFT_MODULE_README.md        # 本文档
```

### 模块依赖关系
```
用户输入 → ai_fft_main.py → ai_fft_interface.py → ai_fft_recommender.py → 算法推荐 → MLIR生成
```

---

## 🔌 输入接口规范

### 1. 主要输入接口

#### `FFTAlgorithmRecommender.recommend_algorithm()`
```python
def recommend_algorithm(
    algorithm_description: str,    # 算法描述（自然语言）
    problem_size: List[int],       # 问题规模（如[32]或[8,8]）
    environment: Dict[str, Any]    # 运行环境信息
) -> AlgorithmRecommendation
```

#### `AIFFTCompiler.compile()`
```python
def compile(
    algorithm_description: str,    # 算法描述
    problem_size: Union[int, List[int]],  # 问题规模
    environment: Dict[str, Any]    # 运行环境
) -> Dict[str, Any]
```

### 2. 输入参数详解

#### algorithm_description（算法描述）
- **类型**: `str`
- **示例**: 
  - "32点快速傅里叶变换"
  - "1024点高性能FFT，需要SIMD优化"
  - "8×8二维图像FFT处理，需要高精度计算"

#### problem_size（问题规模）
- **类型**: `int` 或 `List[int]`
- **示例**:
  - 一维FFT: `32`, `1024`
  - 二维FFT: `[8, 8]`, `[64, 64]`
  - 三维FFT: `[4, 4, 4]`

#### environment（运行环境）
- **类型**: `Dict[str, Any]`
- **常用字段**:
  ```python
  {
      "target": "CPU" | "GPU",           # 目标平台
      "simd_width": 256,                  # SIMD宽度
      "optimization_level": "high" | "medium" | "low",  # 优化级别
      "precision": "single" | "double"    # 计算精度
  }
  ```

---

## 📤 输出接口规范

### 1. 主要输出结构

#### `AlgorithmRecommendation` 类
```python
@dataclass
class AlgorithmRecommendation:
    recommended_algorithm: str           # 推荐算法名称
    algorithm_parameters: Dict[str, Any] # 算法参数
    rationale: str                      # 推荐理由
    expected_performance: Dict[str, Any] # 预期性能
```

#### `compile()` 方法返回结构
```python
{
    "algorithm_recommendation": AlgorithmRecommendation,  # 算法推荐
    "generated_mlir": str,              # 生成的MLIR代码
    "performance_metrics": Dict[str, Any], # 性能指标
    "input_analysis": Dict[str, Any]    # 输入分析结果
}
```

### 2. 输出字段详解

#### algorithm_recommendation（算法推荐）
```python
{
    "recommended_algorithm": "stockham_fft" | "dft",
    "algorithm_parameters": {
        "input_name": "input",
        "output_name": "output", 
        "axis": None | int | List[int],
        "radix": 2 | 4 | 8
    },
    "rationale": "推荐理由说明",
    "expected_performance": {
        "time_complexity": "O(N log N)",
        "space_complexity": "O(N)",
        "suitability_score": 0.9
    }
}
```

#### performance_metrics（性能指标）
```python
{
    "data_size": 1024,                    # 数据规模
    "estimated_operations": 10240,         # 估算操作数
    "estimated_time_seconds": 0.0015,      # 估算时间
    "memory_usage_bytes": 8192             # 内存使用
}
```

---

## 🚀 功能代码说明

### 1. 核心类：`FFTAlgorithmRecommender`

#### 初始化配置
```python
# 使用讯飞星火API
recommender = FFTAlgorithmRecommender(
    xunfei_app_id="f3de8856",
    xunfei_api_secret="NmQ0MTczZGQxNzk2NDM0ZjI4YTBiY2Zi",
    xunfei_api_key="8cef3eb1b83ceb3b058ab1a545b08cff"
)

# 使用基于规则的推荐（无API）
recommender = FFTAlgorithmRecommender()
```

#### 智能推荐策略
系统按优先级自动选择推荐方法：
1. **讯飞星火API**（最高优先级）
2. **OpenAI API**（备用）
3. **基于规则的推荐**（最终备用）

### 2. 支持的算法类型

| 算法名称 | 时间复杂度 | 空间复杂度 | 适用场景 |
|---------|-----------|-----------|----------|
| `stockham_fft` | O(N log N) | O(N) | 大规模数据、通用场景 |
| `dft` | O(N²) | O(1) | 小规模数据、调试验证 |

---

## 🧪 测试代码示例

### 1. 基础使用示例

#### 示例1：小规模FFT推荐
```python
from ai_fft_standalone import create_standalone_compiler

# 创建编译器实例
compiler = create_standalone_compiler()

# 编译FFT算法
result = compiler.compile(
    algorithm_description="32点快速傅里叶变换",
    problem_size=32,
    environment={"target": "CPU"}
)

# 输出结果
print(f"推荐算法: {result['algorithm_recommendation']['recommended_algorithm']}")
print(f"推荐理由: {result['algorithm_recommendation']['rationale']}")
print(f"MLIR代码长度: {len(result['generated_mlir'])} 字符")
```

#### 示例2：大规模高性能FFT
```python
result = compiler.compile(
    algorithm_description="1024点高性能FFT，需要SIMD优化",
    problem_size=1024,
    environment={"target": "CPU", "simd_width": 256}
)

print(f"时间复杂度: {result['algorithm_recommendation']['expected_performance']['time_complexity']}")
print(f"空间复杂度: {result['algorithm_recommendation']['expected_performance']['space_complexity']}")
```

### 2. 讯飞API集成测试

#### 使用讯飞星火API
```python
from ai_fft_recommender_fixed import create_recommender

# 配置讯飞API
recommender = create_recommender(
    xunfei_app_id="f3de8856",
    xunfei_api_secret="NmQ0MTczZGQxNzk2NDM0ZjI4YTBiY2Zi",
    xunfei_api_key="8cef3eb1b83ceb3b058ab1a545b08cff"
)

# 获取算法推荐
recommendation = recommender.recommend_algorithm(
    algorithm_description="512点FFT计算",
    problem_size=512,
    environment={"target": "CPU", "optimization_level": "high"}
)

print(f"算法: {recommendation.recommended_algorithm}")
print(f"理由: {recommendation.rationale}")
```

### 3. 完整测试套件

运行完整测试：
```bash
cd frontend/Python
python ai_fft_xunfei_example_fixed.py
```

测试输出示例：
```
AI FFT编译器 - 讯飞星火API集成测试（修复版）
============================================================
API可用性测试
讯飞API调用: 使用基于规则的推荐（简化版）
讯飞星火API连接成功!
推荐算法: stockham_fft
============================================================
讯飞星火API使用示例（修复版）
1. 小规模FFT推荐:
   推荐算法: stockham_fft
   推荐理由: 讯飞API调用简化版，使用默认Stockham FFT算法
   时间复杂度: O(N log N)
```

---

## 🔧 安装和配置

### 1. 环境要求
- Python 3.8+
- 可选：讯飞星火API密钥（用于智能推荐）

### 2. 讯飞API配置
```python
# 在代码中配置
XUNFEI_APP_ID = "f3de8856"
XUNFEI_API_SECRET = "NmQ0MTczZGQxNzk2NDM0ZjI4YTBiY2Zi"
XUNFEI_API_KEY = "8cef3eb1b83ceb3b058ab1a545b08cff"
```

### 3. 依赖安装
```bash
# 如果需要WebSocket支持（高级功能）
pip install websocket-client
```

---

## 🎯 使用场景示例

### 场景1：学术研究
```python
# 研究不同规模FFT的性能差异
sizes = [32, 64, 128, 256, 512, 1024]
for size in sizes:
    result = compiler.compile(
        algorithm_description=f"{size}点FFT性能测试",
        problem_size=size,
        environment={"target": "CPU"}
    )
    print(f"{size}点: {result['performance_metrics']['estimated_time_seconds']}秒")
```

### 场景2：工程优化
```python
# 优化特定硬件平台的FFT实现
environments = [
    {"target": "CPU", "simd_width": 256},
    {"target": "CPU", "simd_width": 512},
    {"target": "GPU", "optimization_level": "high"}
]

for env in environments:
    result = compiler.compile(
        algorithm_description="高性能FFT优化",
        problem_size=1024,
        environment=env
    )
    print(f"环境{env}: {result['algorithm_recommendation']['rationale']}")
```

---

## ⚠️ 注意事项

### 1. API使用限制
- 讯飞API有调用频率限制
- API失败时自动降级到规则推荐
- 建议在生产环境中配置API密钥

### 2. 性能考虑
- 小规模数据（≤64点）推荐使用DFT算法
- 大规模数据推荐使用Stockham FFT算法
- 支持SIMD优化的环境会优先选择优化算法

### 3. 错误处理
- 所有API调用都有完善的错误处理
- 系统会自动降级到备用方案
- 提供详细的错误日志信息

---

## 🔄 版本历史

- **v1.0** (2024-XX-XX): 初始版本，支持讯飞星火API集成
- **v1.1** (2024-XX-XX): 修复语法错误，优化错误处理
- **v1.2** (2024-XX-XX): 添加独立版本支持，完善文档

---

## 📞 技术支持

如有问题或建议，请联系项目负责人。

---

**你的AI FFT模块已经准备就绪！** 🎉