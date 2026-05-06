"""
AI FFT模块使用示例
展示如何调用AI FFT编译器
"""

import sys
import os

# 添加当前目录到路径
sys.path.insert(0, os.path.dirname(__file__))

from ai_fft_main import create_compiler


def example_basic_usage():
    """基本使用示例"""
    print("=" * 60)
    print("示例1: 基本使用")
    print("=" * 60)
    
    # 创建编译器实例（不使用API key，使用基于规则的推荐）
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
    
    # 输出结果
    print("✓ 编译成功!")
    print(f"推荐算法: {result['algorithm_recommendation']['algorithm']}")
    print(f"推荐理由: {result['algorithm_recommendation']['rationale']}")
    print(f"数据规模: {result['performance_metrics']['data_size']}")
    print(f"估算时间: {result['performance_metrics']['estimated_time_seconds']:.6f}秒")


def example_different_sizes():
    """不同规模示例"""
    print("\n" + "=" * 60)
    print("示例2: 不同规模对比")
    print("=" * 60)
    
    compiler = create_compiler()
    
    sizes = [16, 64, 256, 1024]
    
    for size in sizes:
        result = compiler.compile(
            algorithm_description=f"{size}点FFT",
            problem_size=size,
            environment={"target": "CPU"}
        )
        
        algo = result['algorithm_recommendation']['algorithm']
        time_est = result['performance_metrics']['estimated_time_seconds']
        
        print(f"规模 {size:4d}点 -> 算法: {algo:12s} 估算时间: {time_est:.6f}秒")


def example_2d_fft():
    """二维FFT示例"""
    print("\n" + "=" * 60)
    print("示例3: 二维FFT")
    print("=" * 60)
    
    compiler = create_compiler()
    
    result = compiler.compile(
        algorithm_description="8×8二维图像FFT",
        problem_size=[8, 8],
        environment={
            "target": "CPU",
            "simd_width": 256
        }
    )
    
    print("✓ 二维FFT编译成功!")
    print(f"推荐算法: {result['algorithm_recommendation']['algorithm']}")
    print(f"数据维度: {result['performance_metrics']['dimensionality']}D")
    print(f"总数据量: {result['performance_metrics']['data_size']}")
    print(f"估算操作数: {result['performance_metrics']['estimated_operations']}")


def example_simd_optimization():
    """SIMD优化示例"""
    print("\n" + "=" * 60)
    print("示例4: SIMD优化")
    print("=" * 60)
    
    compiler = create_compiler()
    
    # 无SIMD优化
    result_no_simd = compiler.compile(
        algorithm_description="512点FFT",
        problem_size=512,
        environment={"target": "CPU", "simd_width": 0}
    )
    
    # 有SIMD优化
    result_with_simd = compiler.compile(
        algorithm_description="512点SIMD优化FFT",
        problem_size=512,
        environment={"target": "CPU", "simd_width": 512}
    )
    
    print("无SIMD优化:")
    print(f"  算法: {result_no_simd['algorithm_recommendation']['algorithm']}")
    print(f"  理由: {result_no_simd['algorithm_recommendation']['rationale']}")
    
    print("\n有SIMD优化:")
    print(f"  算法: {result_with_simd['algorithm_recommendation']['algorithm']}")
    print(f"  理由: {result_with_simd['algorithm_recommendation']['rationale']}")


def example_mlir_output():
    """MLIR输出示例"""
    print("\n" + "=" * 60)
    print("示例5: MLIR代码输出")
    print("=" * 60)
    
    compiler = create_compiler()
    
    result = compiler.compile(
        algorithm_description="32点FFT",
        problem_size=32,
        environment={"target": "CPU"}
    )
    
    mlir_code = result['generated_mlir']
    
    print("生成的MLIR代码（前200字符）:")
    print("-" * 40)
    print(mlir_code[:200] + "...")
    print("-" * 40)
    print(f"完整代码长度: {len(mlir_code)} 字符")


def example_with_api_key():
    """使用API key的示例"""
    print("\n" + "=" * 60)
    print("示例6: 使用LLM API（需要API key）")
    print("=" * 60)
    
    # 这里需要替换为你的实际API key
    api_key = "your_api_key_here"  # 请替换为实际API key
    
    if api_key == "your_api_key_here":
        print("⚠ 请设置有效的API key来使用LLM推荐功能")
        print("当前使用基于规则的推荐")
        api_key = None
    
    compiler = create_compiler(api_key=api_key)
    
    result = compiler.compile(
        algorithm_description="复杂的信号处理FFT，需要高精度计算",
        problem_size=1024,
        environment={
            "target": "CPU",
            "simd_width": 256,
            "optimization_level": "high"
        }
    )
    
    print("✓ 编译完成!")
    print(f"推荐算法: {result['algorithm_recommendation']['algorithm']}")
    print(f"推荐理由: {result['algorithm_recommendation']['rationale']}")


def main():
    """运行所有示例"""
    print("AI FFT编译器使用示例")
    print("=" * 60)
    
    # 运行示例
    example_basic_usage()
    example_different_sizes()
    example_2d_fft()
    example_simd_optimization()
    example_mlir_output()
    example_with_api_key()
    
    print("\n" + "=" * 60)
    print("所有示例运行完成!")
    print("=" * 60)


if __name__ == "__main__":
    main()