export NCCL_IB_TC=136
export NCCL_IB_SL=5
export NCCL_IB_GID_INDEX=3
export NCCL_SOCKET_IFNAME=eth0
export NCCL_DEBUG=INFO
export NCCL_IB_HCA=mlx5
export NCCL_IB_TIMEOUT=22
export NCCL_IB_QPS_PER_CONNECTION=8
export NCCL_NET_PLUGIN=none
export PATH=/workspace/miniconda3/bin:$PATH;
export HF_HOME=/workspace
export NCCL_IB_DISABLE=1
export NCCL_P2P_DISABLE=1
export CUDA_LAUNCH_BLOCKING=1
export TORCH_USE_CUDA_DSA=1

DATA_PATH=${1}
PRETRAINED_MODEL=${2}
OUTPUT_DIR=${3}

DATA_PATH=${DATA_PATH:-"./processed/syn_gen_func_call_dialect.jsonl.npy"}
PRETRAINED_MODEL=${PRETRAINED_MODEL:-"Qwen/Qwen2.5-Coder-3B-Instruct"}
OUTPUT_DIR=${OUTPUT_DIR:-"./checkpoints_syn_gen_func_call_dialect_100_steps/lr${LR}-wr${WARMUP_STEPS}-wd${WEIGHT_DECAY}-bsz${BATCH_SIZE}-maxlen${MAX_LENGTH}/"}

GPUS_PER_NODE=$(python -c "import torch; print(torch.cuda.device_count());")
MASTER_ADDR=${MASTER_ADDR:-localhost}
NNODES=${WORLD_SIZE:-1}
NODE_RANK=${RANK:-0}
WORLD_SIZE=$(($GPUS_PER_NODE*$NNODES))
MASTER_PORT=${MASTER_PORT:-6105}
DISTRIBUTED_ARGS="
    --nproc_per_node $GPUS_PER_NODE \
    --nnodes $NNODES \
    --node_rank $NODE_RANK \
    --master_addr $MASTER_ADDR \
    --master_port $MASTER_PORT
"
DEEPSPEED_CONFIG="./configs/default_offload_opt_param.json"
BATCH_SIZE=16
MICRO_BATCH_SIZE=1
GRAD_ACCU=$(($BATCH_SIZE / $WORLD_SIZE / $MICRO_BATCH_SIZE))

LR=1e-5
MIN_LR=0
WARMUP_STEPS=16
WEIGHT_DECAY=1e-4
MAX_LENGTH=10240

echo $OUTPUT_DIR
echo "Pretrained Model" ${PRETRAINED_MODEL}
echo "WORLD_SIZE" $WORLD_SIZE "MICRO BATCH SIZE" $MICRO_BATCH_SIZE "GRAD_ACCU" $GRAD_ACCU
echo $DISTRIBUTED_ARGS

torchrun ${DISTRIBUTED_ARGS} train.py \
    --model_name_or_path  ${PRETRAINED_MODEL} \
    --data_path $DATA_PATH \
    --model_max_length ${MAX_LENGTH} \
    --output_dir ${OUTPUT_DIR} \
    --max_steps 100 \
    --per_device_train_batch_size ${MICRO_BATCH_SIZE} \
    --gradient_accumulation_steps ${GRAD_ACCU} \
    --per_device_eval_batch_size 4 \
    --evaluation_strategy "no" \
    --save_strategy "steps" \
    --save_steps 25 \
    --save_total_limit 100 \
    --learning_rate ${LR} \
    --weight_decay ${WEIGHT_DECAY} \
    --warmup_ratio 0.1 \
    --lr_scheduler_type "cosine" \
    --logging_strategy "steps" \
    --logging_steps 1 \
    --report_to "tensorboard" \
    --bf16 True \
    --tf32 True \
    --deepspeed ${DEEPSPEED_CONFIG} \
    --truncate_source False \
    --adam_beta1 0.9 \
    --adam_beta2 0.95 \
    --gradient_checkpointing True