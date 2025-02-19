## Getting Started 🎯
### Installation
```bash
# Recommend Python 3.10.
cd snow-spider-agent
pip install -r requirements.txt
pip install -e ./verl
pip install -e .
pip install antlr4-python3-runtime==4.9.*
```

### Data
Our raw training data in `deepscaler/data/[train|test]`. Parquet files in `deepscaler/data/processed`.

For DB data, please dowload from [HuggingFace](https://huggingface.co/datasets/xxxbrem/sql).

```
huggingface-cli download --resume-download xxxbrem/sql --include "data.zip" --local-dir ./ --repo-type dataset --local-dir-use-symlinks False --resume
```

Unzip and put `data` folder in root folder (`snow-spider-agent`).

### Credential
Put `snowflake_credential.json` and `bigquery_credential.json` in root folder (`snow-spider-agent`).

### Model
```
huggingface-cli download --resume-download Qwen/Qwen2.5-Coder-1.5B --local-dir models/Qwen2.5-Coder-1.5B --local-dir-use-symlinks False --resume
```

### Training Scripts

We provide training scripts for both single-node and multi-node setups in `scripts/train/`.

#### Single-Node Training (8 GPUs)
Our 8k context script runs on a single node with 8 A100-80GB GPUs:
```bash
# Set XFormers backend to avoid CUDA errors
export VLLM_ATTENTION_BACKEND=XFORMERS
# Run 8K context length training
export MODEL_PATH="models/Qwen2.5-Coder-1.5B"
export WANDB_API_KEY=<YOUR_WANDB_KEY>
./scripts/train/run_deepscaler_1.5b_8k_sql.sh
```

#### Multi-Node Training (32 GPUs)

Our long-context runs (16K/24K) are distributed across 4 nodes with 8 A100-80GB GPUs each. To run, follow these steps:

1. On the head node:
```bash
# Set XFormers backend to avoid CUDA errors
export VLLM_ATTENTION_BACKEND=XFORMERS
# Start Ray head node
ray start --head
```

2. On each worker node:
```bash
# Set XFormers backend to avoid CUDA errors
export VLLM_ATTENTION_BACKEND=XFORMERS
# Connect to head node (replace with your head node's address)
ray start --address=[RAY_ADDRESS]
```

3. Finally, on the head node, run the training script:
```bash
# Run 16K or 24K context length training
./scripts/train/run_deepscaler_1.5b_[16k|24k].sh --model [CHECKPOINT_PATH]
```
We welcome the community to try out different models, context legnths, and RL parameters in the training scripts!

### Ablations

Finally, we provide ablations for the 2k/4k context runs in `scripts/ablation/`. To run:
```bash
./scripts/ablation/run_deepscaler_1.5b_[2k|4k].sh --model [CHECKPOINT_PATH]
```

## Evaluation

Our evaluation scripts automatically runs vLLM to generate 16 samples for each problem. To run our evaluation scripts, run:
```bash
./scripts/eval/eval_model.sh --model [CHECKPOINT_PATH] --datasets [DATASET1] [DATASET2] --output-dir [OUTPUT_DIR]
```