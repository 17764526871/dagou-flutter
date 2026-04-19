#!/usr/bin/env python3
"""
NAS模型HTTP服务器 - 用于局域网分发AI模型
运行: python nas_model_server.py
访问: http://<本机IP>:8080
"""
import http.server
import socketserver
import os
from pathlib import Path

# NAS模型目录
MODEL_DIR = r"U:\DG model"
PORT = 8080

class ModelHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=MODEL_DIR, **kwargs)

    def end_headers(self):
        # 添加CORS头，允许跨域访问
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', '*')
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

if __name__ == "__main__":
    os.chdir(MODEL_DIR)

    print("=" * 60)
    print("🚀 NAS模型HTTP服务器")
    print("=" * 60)
    print(f"📁 模型目录: {MODEL_DIR}")
    print(f"🌐 端口: {PORT}")
    print()
    print("可用模型:")
    for f in Path(MODEL_DIR).glob("*.litertlm"):
        size = f.stat().st_size / (1024**3)
        print(f"  ✅ {f.name} ({size:.1f}GB)")
    print()
    print("访问地址:")
    print(f"  http://localhost:{PORT}")
    print(f"  http://<本机IP>:{PORT}")
    print()
    print("按 Ctrl+C 停止服务器")
    print("=" * 60)

    with socketserver.TCPServer(("", PORT), ModelHTTPRequestHandler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n\n服务器已停止")
