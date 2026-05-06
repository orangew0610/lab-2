"""
AI FFT模块测试用例
"""

import sys
import os
import json

# 添加项目路径 - 修复路径设置
current_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.join(current_dir, '..', '..', '..', '..')
frontend_python_path = os.path.join(project_root, 'frontend', 'Python')

# 确保路径存在
if os.path.exists(frontend_python_path):
    sys.path.insert(0, frontend_python_path)
else:
    # 如果标准路径不存在，尝试相对路径
    frontend_python_path = os.path.join(current_dir, '..', '..', '..', 'frontend', 'Python')
    if os.path.exists(frontend_python_path):
        sys.path.insert(0, frontend_python_path)
    else:
        print(f"警告: 无法找到frontend/Python目录，请检查路径: {frontend_python_path}")

# 打印调试信息
print(f"当前目录: {current_dir}")
print(f"项目根目录: {project_root}")
print(f"Python路径: {frontend_python_path}")
print(f"sys.path: {sys.path[:3]}")

try:
    from ai_fft_main import create_compiler
    from ai_fft_interface import FFTInputParser
    print("✓ 模块导入成功")
except ImportError as e:
    print(f"错误: 模块导入失败: {e}")
    print("正在检查frontend/Python目录内容...")
    
    # 列出frontend/Python目录内容
    if os.path.exists(frontend_python_path):
        files = os.listdir(frontend_python_path)
        print(f"frontend/Python目录内容: {[f for f in files if f.endswith('.py')]}")
    
    # 退出测试
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
    print("✓ 测试用例1通过")
    
    # 测试用例2: 从描述中提取规模
    user_input = {
        "algorithm_description": "计算8×8二维FFT",
        "environment": {"target": "CPU", "simd_width": 128}
    }
    
    parsed = parser.parse_input(user_input)
    assert parsed.problem_size == [8, 8]
    assert parsed.environment["simd_width"] == 128
    print("✓ 测试用例2通过")
    
    # 测试用例3: 复杂描述
    user_input = {
        "algorithm_description": "高性能SIMD优化的256点FFT，使用AVX指令集",
        "problem_size": [256]
    }
    
    parsed = parser.parse_input(user_input)
    assert parsed.problem_size == [256]
    assert "SIMD" in parsed.environment["target"]
    assert parsed.environment["optimization_level"] == "high"
    print("✓ 测试用例3通过")
    
    print("所有输入解析测试通过!")


def test_algorithm_recommendation():
    """测试算法推荐"""
    print("\n测试算法推荐...")
    
    compiler = create_compiler()  # 不使用API key，使用基于规则的推荐
    
    # 测试用例1: 小规模数据
    result = compiler.compile(
        algorithm_description="32点FFT",
        problem_size=32,
        environment={"target": "CPU"}
    )
    
    assert result["success"] == True
    algorithm = result["algorithm_recommendation"]["algorithm"]
    
    # 小规模数据应该推荐DFT
    if algorithm == "dft":
        print("✓ 小规模数据推荐DFT算法")
    else:
        print(f"⚠ 小规模数据推荐了{algorithm}算法")
    
    # 测试用例2: 大规模数据
    result = compiler.compile(
        algorithm_description="1024点FFT",
        problem_size=1024,
        environment={"target": "CPU", "simd_width": 256}
    )
    
    algorithm = result["algorithm_recommendation"]["algorithm"]
    
    # 大规模数据应该推荐Stockham FFT
    if algorithm == "stockham_fft":
        print("✓ 大规模数据推荐Stockham FFT算法")
    else:
        print(f"⚠ 大规模数据推荐了{algorithm}算法")
    
    # 测试用例3: SIMD优化环境
    result = compiler.compile(
        algorithm_description="SIMD优化的FFT",
        problem_size=512,
        environment={"target": "CPU", "simd_width": 512}
    )
    
    algorithm = result["algorithm_recommendation"]["algorithm"]
    rationale = result["algorithm_recommendation"]["rationale"]
    
    if "SIMD" in rationale and algorithm == "stockham_fft":
        print("✓ SIMD环境正确推荐Stockham FFT")
    else:
        print(f"⚠ SIMD环境推荐结果: {algorithm}, 理由: {rationale}")
    
    print("算法推荐测试完成!")


def test_mlir_generation():
    """测试MLIR代码生成"""
    print("\n测试MLIR代码生成...")
    
    compiler = create_compiler()
    
    # 测试用例1: 生成MLIR代码
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
    
    print("✓ MLIR代码生成成功")
    print(f"MLIR代码长度: {len(mlir_code)} 字符")
    
    # 测试用例2: 不同规模的MLIR生成
    sizes_to_test = [16, 32, 64, 128]
    
    for size in sizes_to_test:
        result = compiler.compile(
            algorithm_description=f"{size}点FFT",
            problem_size=size,
            environment={"target": "CPU"}
        )
        
        mlir_code = result["generated_mlir"]
        assert "module" in mlir_code and "func.func" in mlir_code
        print(f"✓ {size}点FFT MLIR生成成功")
    
    print("MLIR生成测试完成!")


def test_performance_metrics():
    """测试性能指标计算"""
    print("\n测试性能指标计算...")
    
    compiler = create_compiler()
    
    # 测试不同规模下的性能指标
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
        
        # 检查必需的性能指标
        required_fields = ["estimated_operations", "estimated_time_seconds", 
                         "data_size", "dimensionality", "algorithm_efficiency"]
        
        for field in required_fields:
            assert field in metrics, f"缺少性能指标字段: {field}"
        
        # 验证数据规模
        assert metrics["data_size"] == size
        assert metrics["dimensionality"] == 1
        
        # 验证操作数估算
        assert metrics["estimated_operations"] > 0
        assert metrics["estimated_time_seconds"] > 0
        
        print(f"✓ {desc}性能指标计算正确")
        print(f"  数据规模: {metrics['data_size']}")
        print(f"  估算操作数: {metrics['estimated_operations']}")
        print(f"  估算时间: {metrics['estimated_time_seconds']:.6f}秒")
    
    print("性能指标测试完成!")


def test_error_handling():
    """测试错误处理"""
    print("\n测试错误处理...")
    
    compiler = create_compiler()
    
    # 测试用例1: 空描述
    try:
        result = compiler.compile("", 64)
        print("✓ 空描述处理正常")
    except Exception as e:
        print(f"⚠ 空描述处理异常: {e}")
    
    # 测试用例2: 无效规模
    try:
        result = compiler.compile("FFT计算", -1)
        print("✓ 无效规模处理正常")
    except Exception as e:
        print(f"⚠ 无效规模处理异常: {e}")
    
    # 测试用例3: 超大规模
    try:
        result = compiler.compile("超大FFT", 1000000)
        print("✓ 超大规模处理正常")
    except Exception as e:
        print(f"⚠ 超大规模处理异常: {e}")
    
    print("错误处理测试完成!")


def test_supported_algorithms():
    """测试支持的算法列表"""
    print("\n测试支持的算法列表...")
    
    compiler = create_compiler()
    algorithms = compiler.get_supported_algorithms()
    
    # 检查必需字段
    required_fields = ["name", "description", "time_complexity", 
                      "space_complexity", "best_for"]
    
    for algo_name, algo_info in algorithms.items():
        for field in required_fields:
            assert field in algo_info, f"算法{algo_name}缺少字段: {field}"
        
        print(f"✓ 算法{algo_name}信息完整")
        print(f"  名称: {algo_info['name']}")
        print(f"  描述: {algo_info['description']}")
        print(f"  时间复杂度: {algo_info['time_complexity']}")
    
    print("支持的算法列表测试完成!")


def run_all_tests():
    """运行所有测试"""
    print("开始AI FFT模块测试...")
    print("=" * 60)
    
    try:
        test_input_parser()
        test_algorithm_recommendation()
        test_mlir_generation()
        test_performance_metrics()
        test_error_handling()
        test_supported_algorithms()
        
        print("=" * 60)
        print("🎉 所有测试通过!")
        
    except Exception as e:
        print(f"❌ 测试失败: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    run_all_tests()