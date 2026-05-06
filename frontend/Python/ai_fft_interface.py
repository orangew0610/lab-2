"""
AI FFT接口模块
负责输入解析、输出格式化，以及与A模块的接口调用
"""

import json
import re
from typing import Dict, Any, List, Optional, Tuple
from dataclasses import dataclass

from fftc import algorithm, AlgorithmBuilder
from ai_fft_recommender import FFTAlgorithmRecommender, AlgorithmRecommendation


@dataclass
class UserInput:
    """用户输入数据"""
    algorithm_description: str
    problem_size: List[int]
    environment: Dict[str, Any]
    input_data: Optional[Dict[str, Any]] = None


@dataclass
class FFTResult:
    """FFT处理结果"""
    mlir_code: str
    algorithm_recommendation: AlgorithmRecommendation
    performance_metrics: Dict[str, Any]
    execution_result: Optional[Any] = None


class FFTInputParser:
    """FFT输入解析器"""
    
    def __init__(self):
        self.size_patterns = [
            (r'(\d+)点', self._parse_single_size),  # "64点"
            (r'(\d+)[×x](\d+)', self._parse_2d_size),  # "8×8"
            (r'(\d+)[×x](\d+)[×x](\d+)', self._parse_3d_size),  # "4×4×4"
            (r'\[(\d+),\s*(\d+)\]', self._parse_list_size),  # "[4, 8]"
        ]
        
        self.environment_keywords = {
            "cpu": "CPU",
            "gpu": "GPU", 
            "simd": "SIMD",
            "avx": "AVX",
            "neon": "NEON",
            "高性能": "high",
            "低功耗": "low_power"
        }
    
    def parse_input(self, user_input: Dict[str, Any]) -> UserInput:
        """解析用户输入"""
        
        # 提取算法描述
        algorithm_description = user_input.get("algorithm_description", "")
        
        # 解析问题规模
        problem_size = self._parse_problem_size(user_input, algorithm_description)
        
        # 解析运行环境
        environment = self._parse_environment(user_input, algorithm_description)
        
        # 解析输入数据描述
        input_data = self._parse_input_data(user_input)
        
        return UserInput(
            algorithm_description=algorithm_description,
            problem_size=problem_size,
            environment=environment,
            input_data=input_data
        )
    
    def _parse_problem_size(self, user_input: Dict[str, Any], description: str) -> List[int]:
        """解析问题规模"""
        
        # 优先使用用户明确指定的规模
        if "problem_size" in user_input:
            size = user_input["problem_size"]
            if isinstance(size, int):
                return [size]
            elif isinstance(size, list):
                return size
        
        # 从描述中提取规模
        for pattern, parser in self.size_patterns:
            match = re.search(pattern, description, re.IGNORECASE)
            if match:
                return parser(match)
        
        # 默认规模
        return [64]
    
    def _parse_single_size(self, match) -> List[int]:
        """解析单点规模"""
        return [int(match.group(1))]
    
    def _parse_2d_size(self, match) -> List[int]:
        """解析2D规模"""
        return [int(match.group(1)), int(match.group(2))]
    
    def _parse_3d_size(self, match) -> List[int]:
        """解析3D规模"""
        return [int(match.group(1)), int(match.group(2)), int(match.group(3))]
    
    def _parse_list_size(self, match) -> List[int]:
        """解析列表规模"""
        return [int(match.group(1)), int(match.group(2))]
    
    def _parse_environment(self, user_input: Dict[str, Any], description: str) -> Dict[str, Any]:
        """解析运行环境"""
        
        environment = user_input.get("environment", {})
        
        # 从描述中提取环境信息
        description_lower = description.lower()
        
        # 检测目标平台
        target = environment.get("target", "CPU")
        for keyword, platform in self.environment_keywords.items():
            if keyword in description_lower:
                target = platform
                break
        
        # 检测SIMD宽度
        simd_match = re.search(r'(\d+).*位', description)
        simd_width = environment.get("simd_width", 128 if "simd" in description_lower else 0)
        if simd_match:
            simd_width = int(simd_match.group(1))
        
        # 检测优化级别
        optimization_level = environment.get("optimization_level", "medium")
        if "高性能" in description or "high" in description_lower:
            optimization_level = "high"
        elif "低功耗" in description or "low" in description_lower:
            optimization_level = "low"
        
        return {
            "target": target,
            "simd_width": simd_width,
            "optimization_level": optimization_level
        }
    
    def _parse_input_data(self, user_input: Dict[str, Any]) -> Dict[str, Any]:
        """解析输入数据描述"""
        
        input_data = user_input.get("input_data", {})
        
        # 设置默认值
        if "type" not in input_data:
            input_data["type"] = "complex"
        
        return input_data


class FFTCompilerInterface:
    """FFT编译器接口"""
    
    def __init__(self, 
                 api_key: Optional[str] = None,
                 xunfei_app_id: Optional[str] = None,
                 xunfei_api_secret: Optional[str] = None,
                 xunfei_api_key: Optional[str] = None):
        self.recommender = FFTAlgorithmRecommender(
            api_key=api_key,
            xunfei_app_id=xunfei_app_id,
            xunfei_api_secret=xunfei_api_secret,
            xunfei_api_key=xunfei_api_key
        )
        self.parser = FFTInputParser()
    
    def process_fft_request(self, user_input: Dict[str, Any]) -> FFTResult:
        """处理FFT请求"""
        
        # 1. 解析输入
        parsed_input = self.parser.parse_input(user_input)
        
        # 2. 推荐算法
        recommendation = self.recommender.recommend_algorithm(
            parsed_input.algorithm_description,
            parsed_input.problem_size,
            parsed_input.environment
        )
        
        # 3. 生成MLIR代码
        mlir_code = self._generate_mlir(parsed_input.problem_size, recommendation)
        
        # 4. 计算性能指标
        performance_metrics = self._calculate_performance_metrics(
            parsed_input.problem_size, recommendation
        )
        
        return FFTResult(
            mlir_code=mlir_code,
            algorithm_recommendation=recommendation,
            performance_metrics=performance_metrics
        )
    
    def _generate_mlir(self, problem_size: List[int], recommendation: AlgorithmRecommendation) -> str:
        """生成MLIR代码"""
        
        # 创建算法装饰器
        @algorithm(size=problem_size)
        def fft_algorithm(builder: AlgorithmBuilder):
            # 根据推荐的算法调用相应方法
            params = recommendation.algorithm_parameters
            
            if recommendation.recommended_algorithm == "stockham_fft":
                builder.stockham_fft(
                    params["input_name"], 
                    params["output_name"], 
                    axis=params.get("axis")
                )
            elif recommendation.recommended_algorithm == "dft":
                builder.dft(params["input_name"])
            else:
                # 默认使用stockham_fft
                builder.stockham_fft("input", "output", axis=None)
        
        # 编译生成MLIR
        mlir_code = fft_algorithm.compile_to_mlir(
            name=f"fft_{recommendation.recommended_algorithm}",
            mode='bindings'
        )
        
        return mlir_code
    
    def _calculate_performance_metrics(self, 
                                     problem_size: List[int], 
                                     recommendation: AlgorithmRecommendation) -> Dict[str, Any]:
        """计算性能指标"""
        
        total_size = 1
        for size in problem_size:
            total_size *= size
        
        # 基于算法复杂度和数据规模估算性能
        time_complexity = recommendation.expected_performance["time_complexity"]
        
        if time_complexity == "O(N log N)":
            estimated_operations = total_size * (total_size.bit_length() - 1)  # 近似N log N
        elif time_complexity == "O(N^2)":
            estimated_operations = total_size * total_size
        else:
            estimated_operations = total_size
        
        # 估算执行时间（基于经验值）
        base_time_per_op = 1e-9  # 1纳秒/操作
        estimated_time = estimated_operations * base_time_per_op
        
        return {
            "estimated_operations": estimated_operations,
            "estimated_time_seconds": estimated_time,
            "data_size": total_size,
            "dimensionality": len(problem_size),
            "algorithm_efficiency": recommendation.expected_performance.get("suitability_score", 0.8)
        }
    
    def format_output(self, result: FFTResult) -> Dict[str, Any]:
        """格式化输出结果"""
        
        return {
            "success": True,
            "algorithm_recommendation": {
                "algorithm": result.algorithm_recommendation.recommended_algorithm,
                "parameters": result.algorithm_recommendation.algorithm_parameters,
                "rationale": result.algorithm_recommendation.rationale,
                "expected_performance": result.algorithm_recommendation.expected_performance
            },
            "generated_mlir": result.mlir_code,
            "performance_metrics": result.performance_metrics,
            "metadata": {
                "input_processed": True,
                "algorithm_selected": True,
                "mlir_generated": True
            }
        }
    
    def get_supported_algorithms(self) -> Dict[str, Any]:
        """获取支持的算法列表"""
        return self.recommender.get_supported_algorithms()


def create_fft_interface(api_key: Optional[str] = None,
                        xunfei_app_id: Optional[str] = None,
                        xunfei_api_secret: Optional[str] = None,
                        xunfei_api_key: Optional[str] = None) -> FFTCompilerInterface:
    """创建FFT接口实例"""
    return FFTCompilerInterface(
        api_key=api_key,
        xunfei_app_id=xunfei_app_id,
        xunfei_api_secret=xunfei_api_secret,
        xunfei_api_key=xunfei_api_key
    )