#!/usr/bin/env node
/**
 * 下载AI模型到NAS - 尝试多个镜像源
 */
const https = require('https');
const http = require('http');
const fs = require('fs');
const path = require('path');
const { URL } = require('url');

const NAS_DIR = 'U:\\DG model';

// 模型列表 - 尝试多个镜像源
const MODELS = [
  {
    name: 'Gemma 3 1B',
    filename: 'Gemma3-1B-IT.task',
    urls: [
      'https://hf-mirror.com/litert-community/Gemma3-1B-IT/resolve/main/Gemma3-1B-IT.task',
      'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/Gemma3-1B-IT.task',
      'https://hf.co/litert-community/Gemma3-1B-IT/resolve/main/Gemma3-1B-IT.task',
    ],
  },
  {
    name: 'FunctionGemma 270M',
    filename: 'function-gemma-270M-it.task',
    urls: [
      'https://hf-mirror.com/sasha-denisov/function-gemma-270M-it/resolve/main/function-gemma-270M-it.task',
      'https://huggingface.co/sasha-denisov/function-gemma-270M-it/resolve/main/function-gemma-270M-it.task',
    ],
  },
  {
    name: 'DeepSeek R1',
    filename: 'DeepSeek-R1-Distill-Qwen-1.5B.task',
    urls: [
      'https://hf-mirror.com/litert-community/DeepSeek-R1-Distill-Qwen-1.5B/resolve/main/DeepSeek-R1-Distill-Qwen-1.5B.task',
      'https://huggingface.co/litert-community/DeepSeek-R1-Distill-Qwen-1.5B/resolve/main/DeepSeek-R1-Distill-Qwen-1.5B.task',
    ],
  },
  {
    name: 'Qwen2.5 0.5B',
    filename: 'Qwen2.5-0.5B-Instruct.task',
    urls: [
      'https://hf-mirror.com/litert-community/Qwen2.5-0.5B-Instruct/resolve/main/Qwen2.5-0.5B-Instruct.task',
      'https://huggingface.co/litert-community/Qwen2.5-0.5B-Instruct/resolve/main/Qwen2.5-0.5B-Instruct.task',
    ],
  },
  {
    name: 'Phi-4 Mini',
    filename: 'Phi-4-mini-instruct.task',
    urls: [
      'https://hf-mirror.com/litert-community/Phi-4-mini-instruct/resolve/main/Phi-4-mini-instruct.task',
      'https://huggingface.co/litert-community/Phi-4-mini-instruct/resolve/main/Phi-4-mini-instruct.task',
    ],
  },
  {
    name: 'SmolLM 135M',
    filename: 'SmolLM-135M-Instruct.task',
    urls: [
      'https://hf-mirror.com/litert-community/SmolLM-135M-Instruct/resolve/main/SmolLM-135M-Instruct.task',
      'https://huggingface.co/litert-community/SmolLM-135M-Instruct/resolve/main/SmolLM-135M-Instruct.task',
    ],
  },
];

function downloadFile(url, destPath) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const protocol = urlObj.protocol === 'https:' ? https : http;

    const file = fs.createWriteStream(destPath);
    let downloadedBytes = 0;

    const request = protocol.get(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      },
    }, (response) => {
      if (response.statusCode === 302 || response.statusCode === 301) {
        file.close();
        fs.unlinkSync(destPath);
        return downloadFile(response.headers.location, destPath).then(resolve).catch(reject);
      }

      if (response.statusCode !== 200) {
        file.close();
        fs.unlinkSync(destPath);
        return reject(new Error(`HTTP ${response.statusCode}: ${response.statusMessage}`));
      }

      const totalBytes = parseInt(response.headers['content-length'], 10);

      if (totalBytes < 1000000) {
        file.close();
        fs.unlinkSync(destPath);
        return reject(new Error('文件太小，可能不是真实文件'));
      }

      response.pipe(file);

      response.on('data', (chunk) => {
        downloadedBytes += chunk.length;
        const progress = ((downloadedBytes / totalBytes) * 100).toFixed(1);
        process.stdout.write(`\r  进度: ${progress}% (${(downloadedBytes / 1024 / 1024).toFixed(1)}MB / ${(totalBytes / 1024 / 1024).toFixed(1)}MB)`);
      });

      file.on('finish', () => {
        file.close();
        console.log('\n  ✅ 下载成功');
        resolve();
      });
    });

    request.on('error', (err) => {
      file.close();
      fs.unlinkSync(destPath);
      reject(err);
    });

    file.on('error', (err) => {
      file.close();
      fs.unlinkSync(destPath);
      reject(err);
    });
  });
}

async function downloadWithRetry(urls, destPath, modelName) {
  for (const url of urls) {
    console.log(`\n  尝试: ${url}`);
    try {
      await downloadFile(url, destPath);
      return true;
    } catch (err) {
      console.log(`  ❌ 失败: ${err.message}`);
    }
  }
  return false;
}

async function main() {
  console.log('='.repeat(60));
  console.log('🤖 下载AI模型到NAS');
  console.log('='.repeat(60));

  if (!fs.existsSync(NAS_DIR)) {
    fs.mkdirSync(NAS_DIR, { recursive: true });
  }

  let successCount = 0;
  const failedModels = [];

  for (let i = 0; i < MODELS.length; i++) {
    const model = MODELS[i];
    console.log(`\n[${i + 1}/${MODELS.length}] ${model.name}`);

    const destPath = path.join(NAS_DIR, model.filename);

    // 跳过已存在的大文件
    if (fs.existsSync(destPath) && fs.statSync(destPath).size > 1000000) {
      console.log(`  ✅ 已存在: ${destPath}`);
      successCount++;
      continue;
    }

    if (await downloadWithRetry(model.urls, destPath, model.name)) {
      successCount++;
    } else {
      failedModels.push(model.name);
      // 删除失败的小文件
      if (fs.existsSync(destPath)) {
        fs.unlinkSync(destPath);
      }
    }
  }

  console.log('\n' + '='.repeat(60));
  console.log(`✅ 成功: ${successCount}/${MODELS.length}`);
  if (failedModels.length > 0) {
    console.log(`❌ 失败: ${failedModels.length}`);
    failedModels.forEach(name => console.log(`  - ${name}`));
  }
  console.log('='.repeat(60));
}

main().catch(console.error);
