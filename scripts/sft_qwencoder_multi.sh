#!/bin/bash

set -e

#######################
# 1. Parse input arguments
#######################
if [ $# -ne 4 ]; then
  echo "Usage: $0 <DATA_PATH> <PRETRAINED_MODEL> <OUTPUT_DIR> <NODE_RANK>"
  exit 1
fi

DATA_PATH=$1
PRETRAINED_MODEL=$2
OUTPUT_DIR=$3
NODE_RANK=$4

#######################
# 2. Cluster configuration
#######################
# List of private IPs for all nodes (first one is master)
HOSTS=(10.111.0.5 10.111.0.6)
# HOSTS=(10.111.0.5 10.111.0.6)
MASTER_ADDR=${HOSTS[0]}
MASTER_PORT=6105

NNODES=${#HOSTS[@]}
# Check that NODE_RANK is valid
if [ $NODE_RANK -lt 0 ] || [ $NODE_RANK -ge $NNODES ]; then
  echo "Error: NODE_RANK must be in [0, $(($NNODES-1))]"
  exit 1
fi

#######################
# 3. GPU info per node
#######################
GPUS_PER_NODE=$(python -c "import torch; print(torch.cuda.device_count())")
WORLD_SIZE=$(($GPUS_PER_NODE * $NNODES))

#######################
# 4. Training hyperparameters
#######################
DEEPSPEED_CONFIG="./configs/default_offload_opt_param.json"
BATCH_SIZE=16
MICRO_BATCH_SIZE=1
GRAD_ACCU=$(($BATCH_SIZE / $WORLD_SIZE / $MICRO_BATCH_SIZE))

LR=5e-5
WEIGHT_DECAY=0.0
WARMUP_STEPS=0
MAX_LENGTH=6000

#######################
# 5. NCCL & debug environment variables
#######################
export NCCL_SOCKET_IFNAME=eth0         # Replace with your actual network interface name if needed
export NCCL_IB_DISABLE=0
export NCCL_DEBUG_SUBSYS=ALL
export NCCL_IB_DISABLE=1                   # 禁用 InfiniBand，强制走 TCP/IP
export NCCL_P2P_DISABLE=0
export NCCL_NET_GDR_LEVEL=PHB
export NCCL_SOCKET_IFNAME=eth0             # 确保 eth0 是主通信接口，按 `ip a` 确定
export NCCL_TOPO_DUMP_FILE=/tmp/nccl_topo_${RANK}.xml
export GLOO_SOCKET_IFNAME=eth0             # 避免 fallback 的 GLOO 后端出问题
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

#######################
# 6. Print configuration summary
#######################
echo "====== Multi-Node Training Configuration ======"
echo "DATA_PATH:       $DATA_PATH"
echo "MODEL:           $PRETRAINED_MODEL"
echo "OUTPUT_DIR:      $OUTPUT_DIR"
echo "HOSTS:           ${HOSTS[*]}"
echo "MASTER_ADDR:     $MASTER_ADDR"
echo "MASTER_PORT:     $MASTER_PORT"
echo "NODE_RANK:       $NODE_RANK / $((NNODES-1))"
echo "GPUS_PER_NODE:   $GPUS_PER_NODE"
echo "WORLD_SIZE:      $WORLD_SIZE"
echo "GRAD_ACCUM_STEPS:$GRAD_ACCU"
echo "==============================================="

#######################
# 7. Launch distributed training
#######################
torchrun \
  --nproc_per_node=$GPUS_PER_NODE \
  --nnodes=$NNODES \
  --node_rank=$NODE_RANK \
  --master_addr=$MASTER_ADDR \
  --master_port=$MASTER_PORT \
  train.py \
    --model_name_or_path ${PRETRAINED_MODEL} \
    --data_path ${DATA_PATH} \
    --model_max_length ${MAX_LENGTH} \
    --output_dir ${OUTPUT_DIR} \
    --num_train_epochs 3 \
    --per_device_train_batch_size ${MICRO_BATCH_SIZE} \
    --gradient_accumulation_steps ${GRAD_ACCU} \
    --per_device_eval_batch_size 4 \
    --save_strategy "steps" \
    --save_steps 1000 \
    --save_total_limit 100 \
    --learning_rate ${LR} \
    --weight_decay ${WEIGHT_DECAY} \
    --warmup_steps ${WARMUP_STEPS} \
    --lr_scheduler_type "cosine" \
    --logging_strategy "steps" \
    --logging_steps 1 \
    --deepspeed ${DEEPSPEED_CONFIG} \
    --report_to "tensorboard" \
    --bf16 True \
    --tf32 True \
    --truncate_source False \
    # --resume_from_checkpoint /mbz/bruce/exec-fb/models/Qwen3-8B-sft/checkpoint-273
