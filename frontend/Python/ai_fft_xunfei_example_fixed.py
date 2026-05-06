"""
AI FFT编译器 - 讯飞星火API使用示例（修复版）
使用修复后的推荐器模块
"""

import sys
import os

# 添加当前目录到路径
sys.path.insert(0, os.path.dirname(__file__))

from ai_fft_recommender_fixed import create_recommender


def example_with_xunfei():
    """使用讯飞星火API的示例"""
    print("=" * 60)
    print("讯飞星火API使用示例（修复版）")
    print("=" * 60)
    
    # 你的讯飞API配置
    XUNFEI_APP_ID = "f3de8856"
    XUNFEI_API_SECRET = "NmQ0MTczZGQxNzk2NDM0ZjI4YTBiY2Zi"
    XUNFEI_API_KEY = "8cef3eb1b83ceb3b058ab1a545b08cff"
    
    # 创建使用讯飞API的推荐器
    recommender = create_recommender(
        xunfei_app_id=XUNFEI_APP_ID,
        xunfei_api_secret=XUNFEI_API_SECRET,
        xunfei_api_key=XUNFEI_API_KEY
    )
    
    # 测试用例1: 小规模FFT
    print("\n1. 小规模FFT推荐:")
    result = recommender.recommend_algorithm(
        algorithm_description="32点快速傅里叶变换",
        problem_size=32,
        environment={"target": "CPU"}
    )
    
    print(f"   推荐算法: {result.recommended_algorithm}")
    print(f"   推荐理由: {result.rationale}")
    print(f"   时间复杂度: {result.expected_performance['time_complexity']}")
    
    # 测试用例2: 大规模FFT
    print("\n2. 大规模FFT推荐:")
    result = recommender.recommend_algorithm(
        algorithm_description="1024点高性能FFT，需要SIMD优化",
        problem_size=1024,
        environment={"target": "CPU", "simd_width": 256}
    )
    
    print(f"   推荐算法: {result.recommended_algorithm}")
    print(f"   推荐理由: {result.rationale}")
    print(f"   时间复杂度: {result.expected_performance['time_complexity']}")
    
    # 测试用例3: 复杂场景
    print("\n3. 复杂场景推荐:")
    result = recommender.recommend_algorithm(
        algorithm_description="8×8二维图像FFT处理，需要高精度计算",
        problem_size=[8, 8],
        environment={"target": "CPU", "optimization_level": "high"}
    )
    
    print(f"   推荐算法: {result.recommended_algorithm}")
    print(f"   推荐理由: {result.rationale}")
    print(f"   时间复杂度: {result.expected_performance['time_complexity']}")
    
    print("\n讯飞星火API调用成功!")


def example_fallback():
    """备用方案示例（当讯飞API不可用时）"""
    print("\n" + "=" * 60)
    print("备用方案示例（不使用API）")
    print("=" * 60)
    
    # 创建不使用API的推荐器（基于规则推荐）
    recommender = create_recommender()
    
    result = recommender.recommend_algorithm(
        algorithm_description="64点FFT计算",
        problem_size=64,
        environment={"target": "CPU"}
    )
    
    print(f"推荐算法: {result.recommended_algorithm}")
    print(f"推荐理由: {result.rationale}")
    print(f"适合度评分: {result.expected_performance['suitability_score']}")
    
    print("\n基于规则的推荐工作正常!")


def test_api_availability():
    """测试API可用性"""
    print("\n" + "=" * 60)
    print("API可用性测试")
    print("=" * 60)
    
    # 你的讯飞API配置
    XUNFEI_APP_ID = "f3de8856"
    XUNFEI_API_SECRET = "NmQ0MTczZGQxNzk2NDM0ZjI4YTBiY2Zi"
    XUNFEI_API_KEY = "8cef3eb1b83ceb3b058ab1a545b08cff"
    
    try:
        # 尝试创建使用讯飞API的推荐器
        recommender = create_recommender(
            xunfei_app_id=XUNFEI_APP_ID,
            xunfei_api_secret=XUNFEI_API_SECRET,
            xunfei_api_key=XUNFEI_API_KEY
        )
        
        # 快速测试
        result = recommender.recommend_algorithm(
            algorithm_description="测试API连接",
            problem_size=16,
            environment={"target": "CPU"}
        )
        
        print("讯飞星火API连接成功!")
        print(f"推荐算法: {result.recommended_algorithm}")
        
    except Exception as e:
        print(f"讯飞星火API连接失败: {e}")
        print("将使用基于规则的推荐方案")
        
        # 使用备用方案
        recommender = create_recommender()
        result = recommender.recommend_algorithm(
            algorithm_description="测试备用方案",
            problem_size=16,
            environment={"target": "CPU"}
        )
        
        print(f"备用方案工作正常，推荐算法: {result.recommended_algorithm}")


def main():
    """运行所有示例"""
    print("AI FFT编译器 - 讯飞星火API集成测试（修复版）")
    print("=" * 60)
    
    # 测试API可用性
    test_api_availability()
    
    # 运行示例
    example_with_xunfei()
    example_fallback()
    
    print("\n" + "=" * 60)
    print("所有示例运行完成!")
    print("=" * 60)
    
    # 使用说明
    print("\n使用说明:")
    print("1. 要使用讯飞星火API，请设置正确的API配置")
    print("2. 如果API不可用，系统会自动使用基于规则的推荐")
    print("3. 支持多种输入格式和运行环境配置")
    print("4. 修复版避免了复杂的WebSocket连接问题")


if __name__ == "__main__":
    main()