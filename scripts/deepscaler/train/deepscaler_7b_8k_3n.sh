#!/bin/bash
# Usage:
#   bash run_ray_multi.sh <NODE_RANK> [--model path_to_model]
# Make sure HOSTS is defined below with correct IPs for your cluster
export NCCL_DEBUG=INFO
export NCCL_SOCKET_IFNAME=eth0
export NCCL_IB_DISABLE=1

#############################
# 1. Cluster Configuration
#############################
HOSTS=(10.111.0.5 10.111.0.6 10.111.0.7)  # <<< 替换为你的4节点IP
MASTER_ADDR=${HOSTS[0]}
MASTER_PORT=6379
NNODES=${#HOSTS[@]}

#############################
# 2. Parse arguments
#############################
NODE_RANK=$1
shift
MODEL_PATH="/mbz/bruce/exec-fb/checkpoints/execution/8B/actor/global_step_30"
# MODEL_PATH="models/Qwen3-8B-sft"

while [[ $# -gt 0 ]]; do
    case $1 in
        --model)
            MODEL_PATH="$2"
            shift 2
            ;;
        *)
            break
            ;;
    esac
done
export MODEL_PATH=$MODEL_PATH

if [ -z "$NODE_RANK" ] || [ "$NODE_RANK" -ge "$NNODES" ]; then
    echo "Usage: $0 <NODE_RANK> [--model path_to_model]"
    exit 1
fi

#############################
# 3. System Settings
#############################
CPUS_PER_NODE=96
GPUS_PER_NODE=8
# export VLLM_ATTENTION_BACKEND=XFORMERS
export VLLM_USE_V1="0"
export WANDB_API_KEY=REDACTED_WANDB_API_KEY
export PATH_TO_SQLITE_PATH="data_preprocess"

EXEC_FOLDER="exec"
export EXEC_FOLDER=$EXEC_FOLDER

LOG_FOLDER="log"
export LOG_FOLDER=$LOG_FOLDER

ip_head="$MASTER_ADDR:$MASTER_PORT"


ray stop
# TMP_DIR="/mbz/bruce/ray/ray_node_${NODE_RANK}"
TMP_DIR="/tmp/ray"
rm -rf $TMP_DIR
mkdir -p $TMP_DIR
#############################
# 4. Start Ray
#############################
if [ "$NODE_RANK" -eq 0 ]; then
    rm -rf $EXEC_FOLDER
    mkdir $EXEC_FOLDER

    rm -rf $LOG_FOLDER
    mkdir $LOG_FOLDER

    export TMPDIR=$TMP_DIR
    
    ray start --head --node-ip-address="$MASTER_ADDR" --port=$MASTER_PORT \
        --num-cpus=$CPUS_PER_NODE --num-gpus=$GPUS_PER_NODE --temp-dir=$TMP_DIR &
    echo "[NODE 0] Starting Ray head at $MASTER_ADDR"
    sleep 10
else
    
    ray start --address "$ip_head" \
        --num-cpus=$CPUS_PER_NODE --num-gpus=$GPUS_PER_NODE &
    echo "[NODE $NODE_RANK] Joining Ray cluster at $ip_head"
    sleep 5
fi

#############################
# 5. Launch Training
#############################
if [ "$NODE_RANK" -eq 0 ]; then
    echo "[NODE 0] Launching training..."
    python3 -u -m verl.trainer.main_ppo \
        algorithm.adv_estimator=grpo \
        data.train_files=data_preprocess/data/processed/train.parquet \
        data.val_files=data_preprocess/data/processed/bird_dev.parquet \
        data.train_batch_size=144 \
        data.val_batch_size=512 \
        data.max_prompt_length=8192 \
        data.max_response_length=8192 \
        actor_rollout_ref.model.path=$MODEL_PATH  \
        actor_rollout_ref.actor.optim.lr=1e-6 \
        actor_rollout_ref.model.use_remove_padding=True \
        actor_rollout_ref.actor.ppo_mini_batch_size=48 \
        actor_rollout_ref.actor.ppo_micro_batch_size=3 \
        actor_rollout_ref.actor.ppo_epochs=1 \
        actor_rollout_ref.actor.use_dynamic_bsz=True \
        actor_rollout_ref.actor.ppo_max_token_len_per_gpu=32768 \
        actor_rollout_ref.actor.use_kl_loss=True \
        actor_rollout_ref.actor.kl_loss_coef=0.001 \
        actor_rollout_ref.actor.kl_loss_type=low_var_kl \
        actor_rollout_ref.actor.ulysses_sequence_parallel_size=1 \
        actor_rollout_ref.model.enable_gradient_checkpointing=True \
        actor_rollout_ref.actor.fsdp_config.param_offload=False \
        actor_rollout_ref.actor.fsdp_config.grad_offload=False \
        actor_rollout_ref.actor.fsdp_config.optimizer_offload=False \
        actor_rollout_ref.rollout.tensor_model_parallel_size=1 \
        actor_rollout_ref.rollout.name=vllm \
        actor_rollout_ref.rollout.temperature=0.6 \
        actor_rollout_ref.rollout.val_temperature=0.6 \
        actor_rollout_ref.rollout.gpu_memory_utilization=0.85 \
        actor_rollout_ref.rollout.n=16 \
        actor_rollout_ref.rollout.n_val=1 \
        actor_rollout_ref.rollout.sql_executor.max_time=400 \
        actor_rollout_ref.rollout.sql_executor.max_calls=20 \
        actor_rollout_ref.rollout.sql_executor.timeout_for_exploration=10 \
        actor_rollout_ref.rollout.sql_executor.timeout_for_final_answer=10 \
        actor_rollout_ref.rollout.enforce_eager=True \
        actor_rollout_ref.rollout.free_cache_engine=False \
        actor_rollout_ref.ref.fsdp_config.param_offload=True \
        algorithm.kl_ctrl.kl_coef=0.001 \
        trainer.critic_warmup=0 \
        trainer.logger=['console','wandb'] \
        trainer.project_name='execution' \
        trainer.experiment_name='8B_step70' \
        +trainer.val_before_train=False \
        trainer.n_gpus_per_node=$GPUS_PER_NODE \
        trainer.nnodes=$NNODES \
        trainer.save_freq=10 \
        trainer.test_freq=1000 \
        trainer.default_hdfs_dir=null \
        trainer.total_epochs=30 "${@}"
fi
