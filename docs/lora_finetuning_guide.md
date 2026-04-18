# LoRA 微调完整指南

## 目录
1. [LoRA 简介](#lora-简介)
2. [环境准备](#环境准备)
3. [数据准备](#数据准备)
4. [训练流程](#训练流程)
5. [权重导出](#权重导出)
6. [应用集成](#应用集成)
7. [最佳实践](#最佳实践)
8. [故障排查](#故障排查)

---

## LoRA 简介

### 什么是 LoRA？

LoRA（Low-Rank Adaptation）是一种参数高效的微调技术，通过在预训练模型的权重矩阵旁边添加低秩矩阵来实现模型适配。

### 为什么使用 LoRA？

- **参数效率**：只需训练少量参数（通常 <1% 的原模型参数）
- **训练速度快**：相比全量微调快 3-5 倍
- **存储优势**：LoRA 权重文件通常只有几 MB 到几十 MB
- **易于切换**：可以快速加载/卸载不同的 LoRA 权重

### LoRA 工作原理

对于权重矩阵 W，LoRA 添加两个低秩矩阵 A 和 B：

```
W' = W + BA
```

其中：
- W 是原始权重（冻结）
- B 的维度是 (d, r)
- A 的维度是 (r, k)
- r 是 LoRA rank（秩），通常 r << min(d, k)

---

## 环境准备

### 安装依赖

```bash
# 创建虚拟环境（推荐）
python -m venv lora_env
source lora_env/bin/activate  # Linux/Mac
# 或
lora_env\Scripts\activate  # Windows

# 安装必要的包
pip install transformers==4.36.0
pip install peft==0.7.1
pip install datasets==2.16.0
pip install torch==2.1.0
pip install accelerate==0.25.0
pip install bitsandbytes==0.41.3  # 可选，用于量化
pip install trl==0.7.4  # 用于 SFTTrainer
```

### 硬件要求

- **最低配置**：8GB GPU 显存（使用 4-bit 量化）
- **推荐配置**：16GB+ GPU 显存
- **CPU 训练**：可行但非常慢，不推荐

---

## 数据准备

### 数据格式

LoRA 训练需要 instruction-input-output 格式的数据：

```json
{"instruction": "翻译成英文", "input": "你好", "output": "Hello"}
{"instruction": "解释概念", "input": "什么是机器学习", "output": "机器学习是..."}
{"instruction": "写代码", "input": "用 Python 写一个快速排序", "output": "def quicksort(arr):..."}
```

### 数据准备脚本

创建 `scripts/lora/prepare_data.py`：

```python
import json
import pandas as pd
from datasets import Dataset
import argparse

def format_prompt(row):
    """格式化为训练提示词"""
    if row.get('input'):
        return f"""### Instruction:
{row['instruction']}

### Input:
{row['input']}

### Response:
{row['output']}"""
    else:
        return f"""### Instruction:
{row['instruction']}

### Response:
{row['output']}"""

def prepare_dataset(input_file, output_dir):
    """将原始数据转换为训练格式"""
    print(f"📖 读取数据: {input_file}")
    
    # 读取数据
    if input_file.endswith('.csv'):
        df = pd.read_csv(input_file)
    elif input_file.endswith('.json') or input_file.endswith('.jsonl'):
        df = pd.read_json(input_file, lines=True)
    else:
        raise ValueError("不支持的文件格式，请使用 CSV 或 JSON/JSONL")
    
    print(f"✅ 读取了 {len(df)} 条数据")
    
    # 验证必需字段
    required_fields = ['instruction', 'output']
    for field in required_fields:
        if field not in df.columns:
            raise ValueError(f"缺少必需字段: {field}")
    
    # 格式化为提示词
    df['text'] = df.apply(format_prompt, axis=1)
    
    # 创建数据集
    dataset = Dataset.from_pandas(df[['text']])
    
    # 保存
    dataset.save_to_disk(output_dir)
    print(f"✅ 数据集已保存到: {output_dir}")
    print(f"📊 样本数量: {len(dataset)}")
    
    # 显示第一个样本
    print("\n📝 第一个样本预览:")
    print("-" * 50)
    print(dataset[0]['text'])
    print("-" * 50)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='准备 LoRA 训练数据')
    parser.add_argument('--input', type=str, required=True, help='输入文件路径 (CSV/JSON/JSONL)')
    parser.add_argument('--output', type=str, default='./data/processed_dataset', help='输出目录')
    
    args = parser.parse_args()
    prepare_dataset(args.input, args.output)
```

### 使用示例

```bash
# 准备数据
python scripts/lora/prepare_data.py \
    --input data/raw_data.json \
    --output data/processed_dataset
```

---

## 训练流程

### 训练脚本

创建 `scripts/lora/train_lora.py`：

```python
import torch
from transformers import (
    AutoModelForCausalLM,
    AutoTokenizer,
    TrainingArguments,
    BitsAndBytesConfig
)
from peft import LoraConfig, get_peft_model, prepare_model_for_kbit_training
from datasets import load_from_disk
from trl import SFTTrainer
import argparse

def train_lora(
    base_model_name,
    dataset_path,
    output_dir,
    lora_r=16,
    lora_alpha=32,
    lora_dropout=0.05,
    num_epochs=3,
    batch_size=4,
    learning_rate=2e-4,
    use_4bit=True,
):
    """训练 LoRA 模型"""
    
    print(f"🚀 开始训练 LoRA")
    print(f"📦 基础模型: {base_model_name}")
    print(f"📊 数据集: {dataset_path}")
    print(f"💾 输出目录: {output_dir}")
    print(f"🔧 LoRA rank: {lora_r}, alpha: {lora_alpha}")
    
    # 配置 4-bit 量化（可选，节省显存）
    if use_4bit:
        bnb_config = BitsAndBytesConfig(
            load_in_4bit=True,
            bnb_4bit_quant_type="nf4",
            bnb_4bit_compute_dtype=torch.float16,
            bnb_4bit_use_double_quant=True,
        )
        print("✅ 启用 4-bit 量化")
    else:
        bnb_config = None
    
    # 加载基础模型
    print("📥 加载基础模型...")
    model = AutoModelForCausalLM.from_pretrained(
        base_model_name,
        quantization_config=bnb_config if use_4bit else None,
        torch_dtype=torch.float16,
        device_map="auto",
        trust_remote_code=True,
    )
    
    # 加载分词器
    tokenizer = AutoTokenizer.from_pretrained(base_model_name, trust_remote_code=True)
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token
    
    # 准备模型（如果使用量化）
    if use_4bit:
        model = prepare_model_for_kbit_training(model)
    
    # LoRA 配置
    lora_config = LoraConfig(
        r=lora_r,
        lora_alpha=lora_alpha,
        target_modules=["q_proj", "k_proj", "v_proj", "o_proj"],  # Gemma 的注意力层
        lora_dropout=lora_dropout,
        bias="none",
        task_type="CAUSAL_LM",
    )
    
    # 应用 LoRA
    model = get_peft_model(model, lora_config)
    model.print_trainable_parameters()
    
    # 加载数据集
    print("📊 加载数据集...")
    dataset = load_from_disk(dataset_path)
    print(f"✅ 数据集大小: {len(dataset)}")
    
    # 训练参数
    training_args = TrainingArguments(
        output_dir=output_dir,
        num_train_epochs=num_epochs,
        per_device_train_batch_size=batch_size,
        gradient_accumulation_steps=4,
        learning_rate=learning_rate,
        fp16=True,
        logging_steps=10,
        save_steps=100,
        save_total_limit=3,
        warmup_steps=50,
        optim="paged_adamw_8bit" if use_4bit else "adamw_torch",
        report_to="none",  # 不使用 wandb 等
    )
    
    # 创建训练器
    trainer = SFTTrainer(
        model=model,
        args=training_args,
        train_dataset=dataset,
        tokenizer=tokenizer,
        max_seq_length=512,
        dataset_text_field="text",
    )
    
    # 开始训练
    print("🏋️ 开始训练...")
    trainer.train()
    
    # 保存 LoRA 权重
    print(f"💾 保存 LoRA 权重到: {output_dir}")
    model.save_pretrained(output_dir)
    tokenizer.save_pretrained(output_dir)
    
    print("✅ 训练完成！")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='训练 LoRA 模型')
    parser.add_argument('--base_model', type=str, default='google/gemma-2b-it', help='基础模型名称')
    parser.add_argument('--dataset', type=str, required=True, help='数据集路径')
    parser.add_argument('--output', type=str, default='./lora_weights', help='输出目录')
    parser.add_argument('--lora_r', type=int, default=16, help='LoRA rank')
    parser.add_argument('--lora_alpha', type=int, default=32, help='LoRA alpha')
    parser.add_argument('--epochs', type=int, default=3, help='训练轮数')
    parser.add_argument('--batch_size', type=int, default=4, help='批次大小')
    parser.add_argument('--lr', type=float, default=2e-4, help='学习率')
    parser.add_argument('--no_4bit', action='store_true', help='禁用 4-bit 量化')
    
    args = parser.parse_args()
    
    train_lora(
        base_model_name=args.base_model,
        dataset_path=args.dataset,
        output_dir=args.output,
        lora_r=args.lora_r,
        lora_alpha=args.lora_alpha,
        num_epochs=args.epochs,
        batch_size=args.batch_size,
        learning_rate=args.lr,
        use_4bit=not args.no_4bit,
    )
```

### 训练命令

```bash
# 基础训练（使用 4-bit 量化）
python scripts/lora/train_lora.py \
    --base_model google/gemma-2b-it \
    --dataset data/processed_dataset \
    --output lora_weights \
    --epochs 3

# 自定义参数
python scripts/lora/train_lora.py \
    --base_model google/gemma-2b-it \
    --dataset data/processed_dataset \
    --output lora_weights \
    --lora_r 32 \
    --lora_alpha 64 \
    --epochs 5 \
    --batch_size 2 \
    --lr 1e-4
```

---

## 权重导出

### 导出脚本

创建 `scripts/lora/export_lora.py`：

```python
from peft import PeftModel
from transformers import AutoModelForCausalLM, AutoTokenizer
import torch
import argparse

def export_lora_weights(base_model_name, lora_path, output_path, merge=False):
    """导出 LoRA 权重"""
    
    print(f"📥 加载基础模型: {base_model_name}")
    base_model = AutoModelForCausalLM.from_pretrained(
        base_model_name,
        torch_dtype=torch.float16,
        device_map="auto",
    )
    
    print(f"📥 加载 LoRA 权重: {lora_path}")
    model = PeftModel.from_pretrained(base_model, lora_path)
    
    if merge:
        print("🔀 合并 LoRA 权重到基础模型...")
        model = model.merge_and_unload()
    
    print(f"💾 保存到: {output_path}")
    model.save_pretrained(output_path, safe_serialization=True)
    
    # 保存分词器
    tokenizer = AutoTokenizer.from_pretrained(lora_path)
    tokenizer.save_pretrained(output_path)
    
    print("✅ 导出完成！")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='导出 LoRA 权重')
    parser.add_argument('--base_model', type=str, default='google/gemma-2b-it', help='基础模型')
    parser.add_argument('--lora_path', type=str, required=True, help='LoRA 权重路径')
    parser.add_argument('--output', type=str, required=True, help='输出路径')
    parser.add_argument('--merge', action='store_true', help='合并权重')
    
    args = parser.parse_args()
    
    export_lora_weights(
        base_model_name=args.base_model,
        lora_path=args.lora_path,
        output_path=args.output,
        merge=args.merge,
    )
```

### 使用示例

```bash
# 导出独立的 LoRA 权重
python scripts/lora/export_lora.py \
    --base_model google/gemma-2b-it \
    --lora_path lora_weights \
    --output exported_lora

# 导出合并后的完整模型
python scripts/lora/export_lora.py \
    --base_model google/gemma-2b-it \
    --lora_path lora_weights \
    --output merged_model \
    --merge
```

---

## 应用集成

### 在 Flutter 应用中使用

```dart
import 'package:dagou_flutter/services/ai/lora_service.dart';

// 下载 LoRA 权重
final loraService = LoRAService.instance;
await for (final progress in loraService.downloadLoRAWeights(loraUrl)) {
  print('下载进度: ${(progress * 100).toStringAsFixed(1)}%');
}

// 加载 LoRA 权重
await loraService.loadLoRAWeights('/path/to/lora/weights');

// 使用带 LoRA 的模型进行推理
final aiService = AIService.instance;
final response = await aiService.sendMessage('你好');
print('AI 回复: $response');

// 切换到另一个 LoRA
await loraService.switchLoRAWeights('/path/to/another/lora');

// 卸载 LoRA
await loraService.unloadLoRAWeights();
```

---

## 最佳实践

### LoRA Rank 选择

| Rank | 参数量 | 适用场景 | 文件大小 |
|------|--------|----------|----------|
| r=8  | 最少   | 简单任务（分类、简单对话） | ~5MB |
| r=16 | 中等   | 通用任务（推荐） | ~10MB |
| r=32 | 较多   | 复杂任务（代码生成、长文本） | ~20MB |
| r=64 | 最多   | 极复杂任务 | ~40MB |

### 训练参数调优

**学习率（Learning Rate）**
- 推荐范围：1e-4 到 5e-4
- 太高：训练不稳定，loss 震荡
- 太低：收敛慢，可能欠拟合

**批次大小（Batch Size）**
- 根据 GPU 显存调整
- 8GB 显存：batch_size=2-4（使用 4-bit 量化）
- 16GB 显存：batch_size=4-8
- 使用 gradient_accumulation_steps 模拟更大批次

**训练轮数（Epochs）**
- 小数据集（<1000 样本）：3-5 轮
- 中等数据集（1000-10000 样本）：2-3 轮
- 大数据集（>10000 样本）：1-2 轮

### 数据质量

**数据量要求**
- 最少：100 条高质量样本
- 推荐：1000+ 条样本
- 理想：5000+ 条样本

**数据多样性**
- 覆盖不同的指令类型
- 包含各种输入长度
- 避免重复或相似样本

**数据清洗**
- 移除格式错误的样本
- 统一格式和风格
- 检查输出质量

---

## 故障排查

### 常见问题

**1. OOM（内存不足）错误**

```
RuntimeError: CUDA out of memory
```

解决方案：
- 减小 batch_size
- 启用 4-bit 量化（`--use_4bit`）
- 使用 gradient_checkpointing
- 减小 max_seq_length

**2. 训练不收敛**

症状：loss 不下降或震荡

解决方案：
- 降低学习率（尝试 1e-4）
- 增加 warmup_steps
- 检查数据质量
- 增加训练数据量

**3. 权重不兼容**

```
Error: size mismatch for ...
```

解决方案：
- 确保基础模型版本匹配
- 检查 target_modules 配置
- 重新训练 LoRA

**4. 训练速度慢**

解决方案：
- 启用 fp16 训练
- 使用 4-bit 量化
- 增大 batch_size（如果显存允许）
- 使用更快的优化器（如 paged_adamw_8bit）

---

## 完整训练流程示例

```bash
# 1. 准备数据
python scripts/lora/prepare_data.py \
    --input data/my_data.json \
    --output data/processed

# 2. 训练 LoRA
python scripts/lora/train_lora.py \
    --base_model google/gemma-2b-it \
    --dataset data/processed \
    --output lora_weights \
    --lora_r 16 \
    --epochs 3

# 3. 导出权重
python scripts/lora/export_lora.py \
    --base_model google/gemma-2b-it \
    --lora_path lora_weights \
    --output exported_lora

# 4. 在应用中使用
# 将 exported_lora 目录复制到应用的 assets 或下载到设备
```

---

## 参考资源

- [LoRA 论文](https://arxiv.org/abs/2106.09685)
- [PEFT 文档](https://huggingface.co/docs/peft)
- [Gemma 模型](https://huggingface.co/google/gemma-2b-it)
- [TRL 文档](https://huggingface.co/docs/trl)

---

## 许可证

本文档和脚本遵循 MIT 许可证。
