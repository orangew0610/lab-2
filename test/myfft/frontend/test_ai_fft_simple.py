"""
AI FFT模块测试用例 - 简化版（避免Unicode字符）
"""

import sys
import os
import json

# 添加项目路径
current_dir = os.path.dirname(os.path.abspath(__file__))
frontend_python_path = os.path.join(current_dir, '..', '..', '..', 'frontend', 'Python')

# 确保路径存在
if os.path.exists(frontend_python_path):
    sys.path.insert(0, frontend_python_path)
else:
    print(f"错误: 无法找到frontend/Python目录: {frontend_python_path}")
    sys.exit(1)

# 尝试导入独立版本（不依赖MLIR）
try:
    from ai_fft_standalone import create_standalone_compiler
    print("✓ 使用独立版本（不依赖MLIR）")
    USE_STANDALONE = True
except ImportError:
    # 如果独立版本不可用，尝试标准版本
    try:
        from ai_fft_main import create_compiler
        print("✓ 使用标准版本（需要MLIR依赖）")
        USE_STANDALONE = False
    except ImportError as e:
        print(f"❌ 模块导入失败: {e}")
        print("请确保已安装MLIR依赖或使用独立版本")
        sys.exit(1)


def test_input_parser():
    """测试输入解析器"""
    print("测试输入解析器...")
    
    parser = FFTInputParser()
    
    # 测试用例1: 简单描述
    user_input = {
        "algorithm_description": "64点FFT计算",
        "problem_size": 64,
        "environment": {"target": "CPU"}
    }
    
    parsed = parser.parse_input(user_input)
    assert parsed.algorithm_description == "64点FFT计算"
    assert parsed.problem_size == [64]
    assert parsed.environment["target"] == "CPU"
    print("测试用例1通过")
    
    # 测试用例2: 从描述中提取规模
    user_input = {
        "algorithm_description": "计算8x8二维FFT",
        "environment": {"target": "CPU", "simd_width": 128}
    }
    
    parsed = parser.parse_input(user_input)
    assert parsed.problem_size == [8, 8]
    assert parsed.environment["simd_width"] == 128
    print("测试用例2通过")
    
    print("所有输入解析测试通过!")


def test_algorithm_recommendation():
    """测试算法推荐"""
    print("\n测试算法推荐...")
    
    if USE_STANDALONE:
        compiler = create_standalone_compiler()
    else:
        compiler = create_compiler()
    
    # 测试用例1: 小规模数据
    result = compiler.compile(
        algorithm_description="32点FFT",
        problem_size=32,
        environment={"target": "CPU"}
    )
    
    assert result["success"] == True
    algorithm = result["algorithm_recommendation"]["algorithm"]
    
    print(f"小规模数据推荐算法: {algorithm}")
    
    # 测试用例2: 大规模数据
    result = compiler.compile(
        algorithm_description="1024点FFT",
        problem_size=1024,
        environment={"target": "CPU", "simd_width": 256}
    )
    
    algorithm = result["algorithm_recommendation"]["algorithm"]
    print(f"大规模数据推荐算法: {algorithm}")
    
    print("算法推荐测试完成!")


def test_mlir_generation():
    """测试MLIR代码生成"""
    print("\n测试MLIR代码生成...")
    
    if USE_STANDALONE:
        compiler = create_standalone_compiler()
    else:
        compiler = create_compiler()
    
    # 生成MLIR代码
    result = compiler.compile(
        algorithm_description="64点FFT",
        problem_size=64,
        environment={"target": "CPU"}
    )
    
    mlir_code = result["generated_mlir"]
    
    # 检查MLIR代码的基本结构
    assert "module" in mlir_code
    assert "func.func" in mlir_code
    assert "memref" in mlir_code
    
    print("MLIR代码生成成功")
    print(f"MLIR代码长度: {len(mlir_code)} 字符")
    
    # 测试不同规模
    sizes_to_test = [16, 32, 64]
    
    for size in sizes_to_test:
        result = compiler.compile(
            algorithm_description=f"{size}点FFT",
            problem_size=size,
            environment={"target": "CPU"}
        )
        
        mlir_code = result["generated_mlir"]
        assert "module" in mlir_code and "func.func" in mlir_code
        print(f"{size}点FFT MLIR生成成功")
    
    print("MLIR生成测试完成!")


def test_performance_metrics():
    """测试性能指标计算"""
    print("\n测试性能指标计算...")
    
    if USE_STANDALONE:
        compiler = create_standalone_compiler()
    else:
        compiler = create_compiler()
    
    # 测试不同规模
    test_cases = [
        ("小规模FFT", 32),
        ("中等规模FFT", 256),
        ("大规模FFT", 1024)
    ]
    
    for desc, size in test_cases:
        result = compiler.compile(
            algorithm_description=desc,
            problem_size=size,
            environment={"target": "CPU"}
        )
        
        metrics = result["performance_metrics"]
        
        # 检查必需字段
        required_fields = ["estimated_operations", "estimated_time_seconds", 
                         "data_size", "dimensionality", "algorithm_efficiency"]
        
        for field in required_fields:
            assert field in metrics, f"缺少性能指标字段: {field}"
        
        # 验证数据
        assert metrics["data_size"] == size
        assert metrics["dimensionality"] == 1
        assert metrics["estimated_operations"] > 0
        
        print(f"{desc}性能指标计算正确")
        print(f"  数据规模: {metrics['data_size']}")
        print(f"  估算操作数: {metrics['estimated_operations']}")
    
    print("性能指标测试完成!")


def test_supported_algorithms():
    """测试支持的算法列表"""
    print("\n测试支持的算法列表...")
    
    if USE_STANDALONE:
        compiler = create_standalone_compiler()
    else:
        compiler = create_compiler()
    algorithms = compiler.get_supported_algorithms()
    
    # 检查必需字段
    required_fields = ["name", "description", "time_complexity", 
                      "space_complexity", "best_for"]
    
    for algo_name, algo_info in algorithms.items():
        for field in required_fields:
            assert field in algo_info, f"算法{algo_name}缺少字段: {field}"
        
        print(f"算法{algo_name}信息完整")
        print(f"  名称: {algo_info['name']}")
        print(f"  时间复杂度: {algo_info['time_complexity']}")
    
    print("支持的算法列表测试完成!")


def run_all_tests():
    """运行所有测试"""
    print("开始AI FFT模块测试...")
    print("=" * 50)
    
    try:
        test_input_parser()
        test_algorithm_recommendation()
        test_mlir_generation()
        test_performance_metrics()
        test_supported_algorithms()
        
        print("=" * 50)
        print("所有测试通过!")
        
    except Exception as e:
        print(f"测试失败: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    run_all_tests()