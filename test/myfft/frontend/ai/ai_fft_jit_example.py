"""
AI FFT JIT即时编译示例
结合AI算法推荐和JIT即时编译，实现端到端的FFT计算

配置说明：
- 在 CONFIG 字典中修改输入参数，无需改动核心代码
- 支持1D/2D/3D/N维FFT
- 自动根据数据规模推荐最优算法
"""

import sys
import os
import numpy as np

# 添加路径
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from frontend.Python.ai_fft_main import create_compiler
from frontend.Python.fftc import algorithm, AlgorithmBuilder
from frontend.Python.ops.fft_mlir_runner import run_mlir_module


# ============================================
# 配置参数 - 在此修改输入参数
# ============================================
CONFIG = {
    # 讯飞API凭证
    "xunfei_app_id": "f3de8856",
    "xunfei_api_secret": "NmQ0MTczZGQxNzk2NDM0ZjI4YTBiY2Zi",
    "xunfei_api_key": "8cef3eb1b83ceb3b058ab1a545b08cff",
    
    # 运行示例配置 (修改这里即可切换不同示例)
    "run_examples": [
        "1d_fft",    # 一维FFT示例
        "2d_fft",    # 二维FFT示例
        "3d_fft",    # 三维FFT示例
        "n_dimensional",  # N维FFT通用示例
    ],
    
    # 各示例配置
    "examples": {
        "1d_fft": {
            "name": "一维FFT",
            "problem_size": 16,          # 数据规模
            "description": "16点快速傅里叶变换，用于信号处理",
            "environment": {"target": "CPU", "simd_width": 128},
            "input_type": "arange",      # "arange" 或 "random"
            "seed": 42,                  # 随机种子
        },
        "2d_fft": {
            "name": "二维FFT",
            "problem_size": [4, 4],      # 4x4 二维
            "description": "4×4二维图像FFT变换",
            "environment": {"target": "CPU", "simd_width": 256},
            "input_type": "arange",
            "seed": 42,
        },
        "3d_fft": {
            "name": "三维FFT",
            "problem_size": [4, 4, 4],   # 4x4x4 三维
            "description": "4×4×4三维体数据FFT变换",
            "environment": {"target": "CPU", "simd_width": 512},
            "input_type": "random",
            "seed": 42,
        },
        "n_dimensional": {
            "name": "N维FFT",
            "problem_size": [2, 4, 4],   # 自定义维度
            "description": "2×4×4多维数据FFT变换",
            "environment": {"target": "CPU", "simd_width": 256},
            "input_type": "random",
            "seed": 123,
        },
    }
}


# ============================================
# 核心函数
# ============================================
def create_ai_compiler():
    """创建AI编译器实例"""
    return create_compiler(
        xunfei_app_id=CONFIG["xunfei_app_id"],
        xunfei_api_secret=CONFIG["xunfei_api_secret"],
        xunfei_api_key=CONFIG["xunfei_api_key"]
    )


def generate_input_data(problem_size, input_type="arange", seed=42):
    """生成输入数据"""
    if isinstance(problem_size, int):
        total_size = problem_size
        shape = (problem_size,)
    else:
        total_size = np.prod(problem_size)
        shape = tuple(problem_size)
    
    if input_type == "arange":
        data = np.arange(total_size, dtype=np.complex64).reshape(shape)
    else:  # random - 分别生成实部和虚部
        rng = np.random.default_rng(seed)
        real_part = rng.random(total_size, dtype=np.float32).reshape(shape)
        imag_part = rng.random(total_size, dtype=np.float32).reshape(shape)
        data = real_part + 1j * imag_part
    
    return data


def ai_recommend_algorithm(compiler, description, size, environment):
    """AI推荐FFT算法"""
    result = compiler.compile(
        algorithm_description=description,
        problem_size=size,
        environment=environment
    )
    return result


def jit_compile_and_execute(problem_size, algorithm_name):
    """JIT编译并执行FFT"""
    if isinstance(problem_size, int):
        size_list = [problem_size]
        total_size = problem_size
    else:
        size_list = problem_size
        total_size = np.prod(problem_size)
    
    # 创建算法
    @algorithm(size=size_list)
    def fft_jit(builder: AlgorithmBuilder):
        builder.input('input')
        builder.output('output')
        
        if algorithm_name == "stockham_fft":
            builder.stockham_fft('input', 'output')
        elif algorithm_name == "cooley_tukey_fft":
            builder.cooley_tukey_fft('input', 'output')
        elif algorithm_name == "dft":
            builder.dft('input')
        else:
            builder.stockham_fft('input', 'output')
    
    # 编译为MLIR
    func_name = f"fft_{'x'.join(map(str, size_list))}"
    mlir_text = fft_jit.compile_to_mlir(name=func_name, mode='bindings')
    
    # 修改MLIR使其可调用
    mlir_text = mlir_text.replace(f'func.func private @{func_name}(', f'func.func @{func_name}(')
    mlir_text = mlir_text.replace(') {', ') attributes { llvm.emit_c_interface } {', 1)
    
    return mlir_text, func_name, total_size


def run_fft(mlir_text, func_name, input_data):
    """运行FFT计算"""
    shape = input_data.shape
    total_size = np.prod(shape)
    
    in_r = np.real(input_data).astype(np.float32).ravel()
    in_i = np.imag(input_data).astype(np.float32).ravel()
    out_r = np.zeros(total_size, dtype=np.float32)
    out_i = np.zeros(total_size, dtype=np.float32)
    
    results = run_mlir_module(mlir_text, func_name, [in_r, in_i, out_r, out_i])
    
    if results[2] is not None and results[3] is not None:
        out_r_res = results[2]
        out_i_res = results[3]
    else:
        out_r_res = out_r
        out_i_res = out_i
    
    return out_r_res.astype(np.complex64).reshape(shape) + \
           1j * out_i_res.astype(np.complex64).reshape(shape)


def compare_results(jit_result, np_result, shape):
    """对比JIT结果与NumPy参考结果"""
    l2_error = np.linalg.norm(jit_result.ravel() - np_result.ravel())
    max_error = np.max(np.abs(jit_result - np_result))
    
    print(f"\n[精度验证]")
    print(f"  数据维度: {len(shape)}D")
    print(f"  数据规模: {shape}")
    print(f"  L2误差: {l2_error:.2e}")
    print(f"  最大误差: {max_error:.2e}")
    print(f"  结果验证: {'✓ 正确' if l2_error < 1e-5 else '✗ 有误差'}")
    
    return l2_error


# ============================================
# 示例运行函数
# ============================================
def run_example(example_name):
    """运行单个示例"""
    config = CONFIG["examples"][example_name]
    
    print("\n" + "=" * 60)
    print(f"示例: {config['name']}")
    print("=" * 60)
    
    # 1. 创建编译器
    compiler = create_ai_compiler()
    
    # 2. 生成输入数据
    input_data = generate_input_data(
        config["problem_size"],
        config["input_type"],
        config["seed"]
    )
    
    print(f"\n[用户输入]")
    print(f"  问题描述: {config['description']}")
    print(f"  数据规模: {config['problem_size']}")
    print(f"  运行环境: {config['environment']}")
    print(f"  输入类型: {config['input_type']}")
    print(f"  输入数据形状: {input_data.shape}")
    
    # 3. AI推荐算法
    print("\n[AI推荐] 正在调用讯飞星火API推荐算法...")
    result = ai_recommend_algorithm(
        compiler,
        config["description"],
        config["problem_size"],
        config["environment"]
    )
    
    algo_name = result['algorithm_recommendation']['algorithm']
    rationale = result['algorithm_recommendation']['rationale']
    
    print(f"\n[AI推荐结果]")
    print(f"  推荐算法: {algo_name}")
    print(f"  推荐理由: {rationale}")
    
    # 4. 查看MLIR代码
    mlir_code = result['generated_mlir']
    print(f"\n[MLIR生成] 代码长度: {len(mlir_code)} 字符")
    print(f"  代码片段:\n{mlir_code[:300]}...")
    
    # 5. JIT编译
    print("\n[JIT编译] 生成可执行MLIR...")
    mlir_text, func_name, _ = jit_compile_and_execute(config["problem_size"], algo_name)
    
    # 6. 执行计算
    print("\n[JIT执行] 运行ExecutionEngine...")
    jit_result = run_fft(mlir_text, func_name, input_data)
    
    # 7. NumPy参考
    np_result = np.fft.fftn(input_data)
    
    # 8. 输出结果
    print("\n[计算结果]")
    print(f"  JIT输出 (前10个元素): {np.round(jit_result.ravel()[:10], 2)}")
    print(f"  NumPy参考 (前10个元素): {np.round(np_result.ravel()[:10], 2)}")
    
    # 9. 精度对比
    compare_results(jit_result, np_result, input_data.shape)


# ============================================
# 主函数
# ============================================
def main():
    """运行所有配置的示例"""
    print("AI FFT JIT即时编译演示")
    print("=" * 60)
    print(f"配置的示例: {CONFIG['run_examples']}")
    print("=" * 60)
    
    for example_name in CONFIG["run_examples"]:
        try:
            run_example(example_name)
        except Exception as e:
            print(f"\n[错误] 示例 {example_name} 运行失败: {e}")
            import traceback
            traceback.print_exc()
    
    print("\n" + "=" * 60)
    print("所有示例运行完成!")
    print("=" * 60)


if __name__ == "__main__":
    main()
