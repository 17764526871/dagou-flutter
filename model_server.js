#!/usr/bin/env node
/**
 * NAS模型HTTP服务器 - 用于局域网分发AI模型
 * 运行: node model_server.js
 */
const http = require('http');
const fs = require('fs');
const path = require('path');
const os = require('os');

const MODEL_DIR = 'U:\\DG model';
const PORT = 8080;

// 获取本机IP地址
function getLocalIP() {
  const interfaces = os.networkInterfaces();
  const addresses = [];

  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      // 跳过内部和非IPv4地址
      if (iface.family === 'IPv4' && !iface.internal) {
        addresses.push(iface.address);
      }
    }
  }

  return addresses;
}

// 获取所有可用模型
function getAvailableModels() {
  const models = [];
  const files = fs.readdirSync(MODEL_DIR);

  for (const file of files) {
    if (file.endsWith('.litertlm') || file.endsWith('.task') || file.endsWith('.bin')) {
      const filePath = path.join(MODEL_DIR, file);
      const stats = fs.statSync(filePath);
      const sizeMB = (stats.size / (1024 * 1024)).toFixed(1);

      models.push({
        name: file,
        size: `${sizeMB}MB`,
        sizeBytes: stats.size,
        url: `/${encodeURIComponent(file)}`,
      });
    }
  }

  return models;
}

// 创建HTTP服务器
const server = http.createServer((req, res) => {
  // 添加CORS头
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', '*');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  // API: 获取模型列表
  if (req.url === '/api/models') {
    const models = getAvailableModels();
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify({ models }));
    return;
  }

  // 首页
  if (req.url === '/' || req.url === '/index.html') {
    const models = getAvailableModels();
    const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>AI模型服务器</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #f5f5f5; padding: 20px; }
    .container { max-width: 800px; margin: 0 auto; }
    h1 { color: #333; margin-bottom: 20px; }
    .info { background: #e3f2fd; padding: 15px; border-radius: 8px; margin-bottom: 20px; }
    .info p { margin: 5px 0; color: #1976d2; }
    .models { background: white; border-radius: 8px; padding: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
    .model { padding: 15px; border-bottom: 1px solid #eee; display: flex; justify-content: space-between; align-items: center; }
    .model:last-child { border-bottom: none; }
    .model-name { font-weight: 500; color: #333; }
    .model-size { color: #666; font-size: 14px; }
    .download-btn { background: #2196f3; color: white; padding: 8px 16px; border-radius: 4px; text-decoration: none; font-size: 14px; }
    .download-btn:hover { background: #1976d2; }
    .empty { text-align: center; color: #999; padding: 40px; }
  </style>
</head>
<body>
  <div class="container">
    <h1>🤖 AI模型服务器</h1>
    <div class="info">
      <p><strong>📁 模型目录:</strong> ${MODEL_DIR}</p>
      <p><strong>🌐 访问地址:</strong> http://localhost:${PORT}</p>
      ${getLocalIP().map(ip => `<p><strong>📱 局域网地址:</strong> http://${ip}:${PORT}</p>`).join('')}
    </div>
    <div class="models">
      <h2 style="margin-bottom: 15px;">可用模型 (${models.length})</h2>
      ${models.length > 0 ? models.map(model => `
        <div class="model">
          <div>
            <div class="model-name">${model.name}</div>
            <div class="model-size">${model.size}</div>
          </div>
          <a href="${model.url}" class="download-btn" download>下载</a>
        </div>
      `).join('') : '<div class="empty">暂无可用模型</div>'}
    </div>
  </div>
</body>
</html>
    `;
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    res.end(html);
    return;
  }

  // 下载模型文件
  const filePath = path.join(MODEL_DIR, decodeURIComponent(req.url.slice(1)));

  if (!filePath.startsWith(MODEL_DIR)) {
    res.writeHead(403);
    res.end('Forbidden');
    return;
  }

  if (!fs.existsSync(filePath)) {
    res.writeHead(404);
    res.end('Not Found');
    return;
  }

  const stat = fs.statSync(filePath);
  const fileName = path.basename(filePath);

  res.writeHead(200, {
    'Content-Type': 'application/octet-stream',
    'Content-Length': stat.size,
    'Content-Disposition': `attachment; filename="${encodeURIComponent(fileName)}"`,
  });

  const stream = fs.createReadStream(filePath);
  stream.pipe(res);

  console.log(`📥 下载: ${fileName} (${(stat.size / 1024 / 1024).toFixed(1)}MB)`);
});

// 启动服务器
server.listen(PORT, () => {
  console.log('='.repeat(60));
  console.log('🚀 NAS模型HTTP服务器已启动');
  console.log('='.repeat(60));
  console.log(`📁 模型目录: ${MODEL_DIR}`);
  console.log(`🌐 端口: ${PORT}`);
  console.log();
  console.log('可用模型:');
  const models = getAvailableModels();
  models.forEach(model => {
    console.log(`  ✅ ${model.name} (${model.size})`);
  });
  console.log();
  console.log('访问地址:');
  console.log(`  http://localhost:${PORT}`);
  getLocalIP().forEach(ip => {
    console.log(`  http://${ip}:${PORT}`);
  });
  console.log();
  console.log('API接口:');
  console.log(`  GET /api/models - 获取模型列表`);
  console.log();
  console.log('按 Ctrl+C 停止服务器');
  console.log('='.repeat(60));
});

server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.error(`❌ 端口 ${PORT} 已被占用，请关闭其他程序或更改端口`);
  } else {
    console.error('❌ 服务器错误:', err);
  }
  process.exit(1);
});
