"""
AI FFT主接口模块
提供用户友好的API接口
"""

import json
import sys
from typing import Dict, Any, Optional

from ai_fft_interface import FFTCompilerInterface, create_fft_interface


class AIFFTCompiler:
    """AI FFT编译器主类"""
    
    def __init__(self, 
                 api_key: Optional[str] = None,
                 xunfei_app_id: Optional[str] = None,
                 xunfei_api_secret: Optional[str] = None,
                 xunfei_api_key: Optional[str] = None):
        """初始化AI FFT编译器"""
        self.interface = create_fft_interface(
            api_key=api_key,
            xunfei_app_id=xunfei_app_id,
            xunfei_api_secret=xunfei_api_secret,
            xunfei_api_key=xunfei_api_key
        )
    
    def compile(self, 
                algorithm_description: str,
                problem_size: Optional[Any] = None,
                environment: Optional[Dict[str, Any]] = None,
                input_data: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        编译FFT算法
        
        Args:
            algorithm_description: 算法描述（自然语言或数学公式）
            problem_size: 问题规模，可以是整数或列表
            environment: 运行环境信息
            input_data: 输入数据描述
            
        Returns:
            Dict: 编译结果
        """
        
        # 构建用户输入
        user_input = self._build_user_input(
            algorithm_description, problem_size, environment, input_data
        )
        
        # 处理FFT请求
        result = self.interface.process_fft_request(user_input)
        
        # 格式化输出
        return self.interface.format_output(result)
    
    def _build_user_input(self, 
                         algorithm_description: str,
                         problem_size: Optional[Any],
                         environment: Optional[Dict[str, Any]],
                         input_data: Optional[Dict[str, Any]]) -> Dict[str, Any]:
        """构建用户输入字典"""
        
        user_input = {
            "algorithm_description": algorithm_description
        }
        
        if problem_size is not None:
            user_input["problem_size"] = problem_size
        
        if environment is not None:
            user_input["environment"] = environment
        
        if input_data is not None:
            user_input["input_data"] = input_data
        
        return user_input
    
    def get_supported_algorithms(self) -> Dict[str, Any]:
        """获取支持的算法列表"""
        return self.interface.get_supported_algorithms()
    
    def get_version(self) -> str:
        """获取版本信息"""
        return "1.0.0"


def create_compiler(api_key: Optional[str] = None,
                    xunfei_app_id: Optional[str] = None,
                    xunfei_api_secret: Optional[str] = None,
                    xunfei_api_key: Optional[str] = None) -> AIFFTCompiler:
    """创建AI FFT编译器实例"""
    return AIFFTCompiler(
        api_key=api_key,
        xunfei_app_id=xunfei_app_id,
        xunfei_api_secret=xunfei_api_secret,
        xunfei_api_key=xunfei_api_key
    )


# 命令行接口
def main():
    """命令行主函数"""
    
    if len(sys.argv) < 2:
        print("用法: python ai_fft_main.py <算法描述> [问题规模] [环境JSON]")
        print("示例: python ai_fft_main.py \"64点FFT计算\" 64 '{\"target\":\"CPU\"}'")
        sys.exit(1)
    
    algorithm_description = sys.argv[1]
    problem_size = None
    environment = None
    
    if len(sys.argv) > 2:
        try:
            problem_size = int(sys.argv[2])
        except ValueError:
            # 尝试解析为列表
            if sys.argv[2].startswith('[') and sys.argv[2].endswith(']'):
                problem_size = json.loads(sys.argv[2])
    
    if len(sys.argv) > 3:
        try:
            environment = json.loads(sys.argv[3])
        except json.JSONDecodeError:
            print("错误: 环境参数必须是有效的JSON格式")
            sys.exit(1)
    
    # 创建编译器并执行
    compiler = create_compiler()
    
    try:
        result = compiler.compile(algorithm_description, problem_size, environment)
        
        # 输出结果
        print("=" * 50)
        print("AI FFT编译器结果")
        print("=" * 50)
        
        print("\n1. 算法推荐:")
        rec = result["algorithm_recommendation"]
        print(f"   算法: {rec['algorithm']}")
        print(f"   参数: {rec['parameters']}")
        print(f"   理由: {rec['rationale']}")
        print(f"   预期性能: {rec['expected_performance']}")
        
        print("\n2. 性能指标:")
        metrics = result["performance_metrics"]
        for key, value in metrics.items():
            print(f"   {key}: {value}")
        
        print("\n3. 生成的MLIR代码:")
        print(result["generated_mlir"])
        
    except Exception as e:
        print(f"编译失败: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()