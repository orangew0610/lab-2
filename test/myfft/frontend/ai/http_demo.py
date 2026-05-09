# encoding:UTF-8
import websocket
import datetime
import hashlib
import hmac
import base64
import json
import time
from urllib.parse import urlencode
from wsgiref.handlers import format_date_time
from time import mktime

APPID = "f3de8856"
APISecret = "NmQ0MTczZGQxNzk2NDM0ZjI4YTBiY2Zi"
APIKey = "8cef3eb1b83ceb3b058ab1a545b08cff"

def create_url():
    now = datetime.datetime.now()
    date = format_date_time(mktime(now.timetuple()))

    signature_origin = "host: spark-api.xf-yun.com\n"
    signature_origin += "date: " + date + "\n"
    signature_origin += "GET /v1.1/chat HTTP/1.1"

    signature_sha = hmac.new(APISecret.encode('utf-8'), signature_origin.encode('utf-8'),
                             digestmod=hashlib.sha256).digest()

    signature_sha_base64 = base64.b64encode(signature_sha).decode('utf-8')

    authorization_origin = (
        'api_key="' + APIKey + '", algorithm="hmac-sha256", headers="host date request-line", '
        'signature="' + signature_sha_base64 + '"'
    )

    authorization = base64.b64encode(authorization_origin.encode('utf-8')).decode('utf-8')

    params = {
        "authorization": authorization,
        "date": date,
        "host": "spark-api.xf-yun.com"
    }

    url = "wss://spark-api.xf-yun.com/v1.1/chat?" + urlencode(params)
    return url

def on_message(ws, message):
    print("收到消息:")
    data = json.loads(message)
    print(json.dumps(data, indent=2, ensure_ascii=False))

    if "payload" in data and "choices" in data["payload"]:
        content = data["payload"]["choices"]["text"]
        for item in content:
            if "content" in item:
                print("AI回复:", item["content"])

def on_error(ws, error):
    print("错误:", error)

def on_close(ws, close_status_code, close_msg):
    print("连接关闭")

def on_open(ws):
    print("连接成功，发送消息...")

    question = "你好，请介绍一下你自己"

    request_data = {
        "header": {
            "app_id": APPID,
            "uid": "user_001"
        },
        "parameter": {
            "chat": {
                "domain": "lite",
                "temperature": 0.5,
                "max_tokens": 2048
            }
        },
        "payload": {
            "message": {
                "text": [
                    {
                        "role": "user",
                        "content": question
                    }
                ]
            }
        }
    }

    ws.send(json.dumps(request_data, ensure_ascii=False))

if __name__ == "__main__":
    print("开始连接 Spark API...")
    url = create_url()
    print("鉴权URL:", url[:100] + "...")

    ws = websocket.WebSocketApp(
        url,
        on_message=on_message,
        on_error=on_error,
        on_close=on_close,
        on_open=on_open
    )

    ws.run_forever(ping_interval=30)