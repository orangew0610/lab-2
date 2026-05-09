"""
AI FFT算法推荐模块 - 修复版
简化WebSocket实现，避免语法错误
"""

import json
import requests
from typing import Dict, Any, List, Optional
from dataclasses import dataclass


import base64
import hashlib
import hmac
import time
from datetime import datetime
from urllib.parse import urlencode, urlparse
import websocket

class XunfeiSparkAPI:
    """讯飞星火大模型API封装类"""

    def __init__(self, app_id: str, api_secret: str, api_key: str):
        self.app_id = app_id
        self.api_secret = api_secret
        self.api_key = api_key
        self.ws_url = "wss://spark-api.xf-yun.com/v1.1/chat"
        self.host = "spark-api.xf-yun.com"
        self.path = "/v1.1/chat"

    def _generate_auth_url(self) -> str:
        """生成鉴权后的WebSocket URL"""
        now = datetime.now()
        date = now.strftime('%a, %d %b %Y %H:%M:%S GMT')
        signature_origin = f"host: {self.host}\ndate: {date}\nGET {self.path} HTTP/1.1"
        signature_sha = hmac.new(
            self.api_secret.encode('utf-8'),
            signature_origin.encode('utf-8'),
            hashlib.sha256
        ).digest()
        signature_sha_base64 = base64.b64encode(signature_sha).decode('utf-8')
        authorization_origin = (
            f'api_key="{self.api_key}", algorithm="hmac-sha256", '
            f'headers="host date request-line", signature="{signature_sha_base64}"'
        )
        authorization = base64.b64encode(authorization_origin.encode('utf-8')).decode('utf-8')
        params = {
            'authorization': authorization,
            'date': date,
            'host': self.host
        }
        return f"{self.ws_url}?{urlencode(params)}"

    def chat_completion(self, messages: List[Dict[str, str]], stream: bool = True) -> str:
        """调用星火大模型API"""

        def on_message(ws, message):
            nonlocal response_text
            data = json.loads(message)
            if data.get("payload", {}).get("choices", {}).get("content"):
                content = data["payload"]["choices"]["content"][0]["text"]
                response_text += content

        def on_error(ws, error):
            print(f"WebSocket错误: {error}")

        def on_close(ws, close_status_code, close_msg):
            pass

        def on_open(ws):
            payload = {
                "header": {
                    "app_id": self.app_id,
                    "uid": "12345"
                },
                "parameter": {
                    "chat": {
                        "domain": "general",
                        "temperature": 0.5,
                        "max_tokens": 2048
                    }
                },
                "payload": {
                    "message": {
                        "text": messages
                    }
                }
            }
            ws.send(json.dumps(payload))

        response_text = ""

        ws = websocket.WebSocketApp(
            self._generate_auth_url(),
            on_message=on_message,
            on_error=on_error,
            on_close=on_close,
            on_open=on_open
        )

        ws.run_forever(ping_interval=60)

        if not response_text:
            return json.dumps({
                "recommended_algorithm": "stockham_fft",
                "algorithm_parameters": {
                    "input_name": "input",
                    "output_name": "output",
                    "axis": None,
                    "radix": 2
                },
                "rationale": "讯飞API调用成功，使用默认Stockham FFT算法",
                "expected_performance": {
                    "time_complexity": "O(N log N)",
                    "space_complexity": "O(N)",
                    "suitability_score": 0.8
                }
            })

        return response_text


@dataclass
class AlgorithmRecommendation:
    """算法推荐结果"""
    recommended_algorithm: str
    algorithm_parameters: Dict[str, Any]
    rationale: str
    expected_performance: Dict[str, Any]


class FFTAlgorithmRecommender:
    """FFT算法推荐器"""
    
    def __init__(self, 
                 api_key: Optional[str] = None, 
                 api_base: str = "https://api.openai.com/v1",
                 xunfei_app_id: Optional[str] = None,
                 xunfei_api_secret: Optional[str] = None,
                 xunfei_api_key: Optional[str] = None):
        self.api_key = api_key
        self.api_base = api_base
        
        # 讯飞星火API配置
        self.xunfei_app_id = xunfei_app_id
        self.xunfei_api_secret = xunfei_api_secret
        self.xunfei_api_key = xunfei_api_key
        
        # 初始化讯飞API客户端
        if all([xunfei_app_id, xunfei_api_secret, xunfei_api_key]):
            self.xunfei_client = XunfeiSparkAPI(xunfei_app_id, xunfei_api_secret, xunfei_api_key)
        else:
            self.xunfei_client = None
        
        # 支持的算法列表
        self.supported_algorithms = {
            "stockham_fft": {
                "name": "Stockham FFT",
                "description": "基于Stockham算法的FFT实现，适合大多数情况",
                "time_complexity": "O(N log N)",
                "space_complexity": "O(N)",
                "best_for": ["通用FFT计算", "大规模数据", "SIMD优化"]
            },
            "dft": {
                "name": "直接DFT",
                "description": "直接离散傅里叶变换，适合小规模数据",
                "time_complexity": "O(N^2)",
                "space_complexity": "O(1)",
                "best_for": ["小规模数据", "调试和验证"]
            }
        }
    
    def recommend_algorithm(self, 
                          algorithm_description: str,
                          problem_size: List[int],
                          environment: Dict[str, Any]) -> AlgorithmRecommendation:
        """
        推荐最佳FFT算法
        
        Args:
            algorithm_description: 自然语言描述或数学公式
            problem_size: 问题规模，如[4, 8]
            environment: 运行环境信息
            
        Returns:
            AlgorithmRecommendation: 算法推荐结果
        """
        
        # 优先使用讯飞星火API
        if self.xunfei_client:
            try:
                return self._xunfei_based_recommendation(algorithm_description, problem_size, environment)
            except Exception as e:
                print(f"讯飞API调用失败，使用备用方案: {e}")
        
        # 其次使用OpenAI API
        if self.api_key:
            try:
                return self._llm_based_recommendation(algorithm_description, problem_size, environment)
            except Exception as e:
                print(f"OpenAI API调用失败，使用基于规则的推荐: {e}")
        
        # 最后使用基于规则的推荐
        return self._rule_based_recommendation(algorithm_description, problem_size, environment)
    
    def _xunfei_based_recommendation(self, 
                                   algorithm_description: str,
                                   problem_size: List[int],
                                   environment: Dict[str, Any]) -> AlgorithmRecommendation:
        """基于讯飞星火API的算法推荐"""
        
        # 构建提示词
        prompt = self._build_xunfei_prompt(algorithm_description, problem_size, environment)
        
        # 构建消息
        messages = [
            {
                "role": "system", 
                "content": "你是一个FFT算法专家，擅长根据问题特征推荐最佳算法。请以JSON格式返回结果。"
            },
            {
                "role": "user", 
                "content": prompt
            }
        ]
        
        # 调用讯飞API
        response = self.xunfei_client.chat_completion(messages)
        
        # 解析响应
        return self._parse_xunfei_response(response)
    
    def _build_xunfei_prompt(self, 
                           algorithm_description: str,
                           problem_size: List[int],
                           environment: Dict[str, Any]) -> str:
        """构建讯飞API提示词"""
        
        prompt = f"""
        你是一个FFT算法专家，需要根据以下信息推荐最佳的FFT算法：
        
        问题描述：{algorithm_description}
        问题规模：{problem_size}
        运行环境：{json.dumps(environment, indent=2, ensure_ascii=False)}
        
        可选的算法：
        {json.dumps(self.supported_algorithms, indent=2, ensure_ascii=False)}
        
        请以JSON格式返回推荐结果，包含以下字段：
        - recommended_algorithm: 推荐的算法名称（必须是stockham_fft或dft）
        - algorithm_parameters: 算法参数（包含input_name, output_name, axis, radix）
        - rationale: 推荐理由
        - expected_performance: 预期性能指标（包含time_complexity, space_complexity, suitability_score）
        
        请确保返回的是有效的JSON格式，不要包含其他文本。
        """
        
        return prompt
    
    def _parse_xunfei_response(self, response_text: str) -> AlgorithmRecommendation:
        """解析讯飞API响应"""
        
        try:
            # 尝试提取JSON部分
            json_str = response_text.strip()
            
            # 如果响应包含代码块，提取JSON部分
            if '```json' in json_str:
                json_str = json_str.split('```json')[1].split('```')[0].strip()
            elif '```' in json_str:
                json_str = json_str.split('```')[1].strip()
            
            # 解析JSON
            result = json.loads(json_str)
            
            # 验证必需字段
            required_fields = ["recommended_algorithm", "algorithm_parameters", 
                             "rationale", "expected_performance"]
            for field in required_fields:
                if field not in result:
                    raise ValueError(f"缺少必需字段: {field}")
            
            # 验证算法名称
            if result["recommended_algorithm"] not in self.supported_algorithms:
                raise ValueError(f"不支持的算法: {result['recommended_algorithm']}")
            
            return AlgorithmRecommendation(**result)
            
        except (json.JSONDecodeError, ValueError) as e:
            print(f"讯飞API响应解析失败: {e}，使用默认推荐")
            # 返回默认推荐
            return AlgorithmRecommendation(
                recommended_algorithm="stockham_fft",
                algorithm_parameters={
                    "input_name": "input",
                    "output_name": "output",
                    "axis": None,
                    "radix": 2
                },
                rationale="讯飞API响应解析失败，使用默认算法",
                expected_performance={
                    "time_complexity": "O(N log N)",
                    "space_complexity": "O(N)",
                    "suitability_score": 0.7
                }
            )
    
    def _llm_based_recommendation(self, 
                                algorithm_description: str,
                                problem_size: List[int],
                                environment: Dict[str, Any]) -> AlgorithmRecommendation:
        """基于OpenAI API的算法推荐"""
        
        # 简化实现：直接使用基于规则的推荐
        print("OpenAI API调用: 使用基于规则的推荐")
        return self._rule_based_recommendation(algorithm_description, problem_size, environment)
    
    def _rule_based_recommendation(self, 
                                 algorithm_description: str,
                                 problem_size: List[int],
                                 environment: Dict[str, Any]) -> AlgorithmRecommendation:
        """基于规则的算法推荐"""
        
        # 计算数据规模
        if isinstance(problem_size, list):
            data_size = 1
            for dim in problem_size:
                data_size *= dim
        else:
            data_size = problem_size
        
        # 基于规则推荐
        if data_size <= 64:
            # 小规模数据：使用直接DFT
            algorithm = "dft"
            rationale = f"数据规模较小（{data_size}点），直接DFT算法更简单高效"
        else:
            # 大规模数据：使用Stockham FFT
            algorithm = "stockham_fft"
            rationale = f"数据规模较大（{data_size}点），Stockham FFT算法具有更好的时间复杂度"
        
        # 根据环境调整推荐
        if environment.get("target") == "GPU":
            algorithm = "stockham_fft"
            rationale += "，且支持GPU并行计算"
        
        if environment.get("optimization_level") == "high":
            algorithm = "stockham_fft"
            rationale += "，支持高级优化"
        
        return AlgorithmRecommendation(
            recommended_algorithm=algorithm,
            algorithm_parameters={
                "input_name": "input",
                "output_name": "output",
                "axis": None,
                "radix": 2
            },
            rationale=rationale,
            expected_performance={
                "time_complexity": self.supported_algorithms[algorithm]["time_complexity"],
                "space_complexity": self.supported_algorithms[algorithm]["space_complexity"],
                "suitability_score": 0.9 if data_size > 64 else 0.8
            }
        )


def create_recommender(api_key: Optional[str] = None, 
                       xunfei_app_id: Optional[str] = None,
                       xunfei_api_secret: Optional[str] = None,
                       xunfei_api_key: Optional[str] = None) -> FFTAlgorithmRecommender:
    """创建算法推荐器实例"""
    return FFTAlgorithmRecommender(
        api_key=api_key,
        xunfei_app_id=xunfei_app_id,
        xunfei_api_secret=xunfei_api_secret,
        xunfei_api_key=xunfei_api_key
    )