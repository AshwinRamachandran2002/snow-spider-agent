export VLLM_ATTENTION_BACKEND=XFORMERS
export WANDB_API_KEY=REDACTED_WANDB_API_KEY
export PATH_TO_SQLITE_PATH="data_prep/methods/RL-fine-tuning"
export EXEC_FOLDER="exec"
rm -rf $EXEC_FOLDER
mkdir $EXEC_FOLDER
export HYDRA_FULL_ERROR=1
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

if [ -z "$MODEL_PATH" ]; then
    MODEL_PATH="models/Qwen2.5-Coder-7B-Instruct-sft"
fi

LOGDIR="/tmp/ray_hao/7B-Coder-func-bird"
mkdir -p "$LOGDIR" && export TMPDIR="$LOGDIR"

python3 -u -m verl.trainer.main_ppo \
    algorithm.adv_estimator=grpo \
    data.train_files=deepscaler/data/processed/bird_train_data_add_ev_change_pth.parquet \
    data.val_files=deepscaler/data/processed/bird_dev_data_add_ev_change_pth.parquet \
    data.train_batch_size=128 \
    data.val_batch_size=512 \
    data.max_prompt_length=8192 \
    data.max_response_length=4096 \
    rewards.max_workers=96 \
    actor_rollout_ref.model.path=$MODEL_PATH  \
    actor_rollout_ref.actor.optim.lr=1e-6 \
    actor_rollout_ref.model.use_remove_padding=True \
    actor_rollout_ref.actor.ppo_mini_batch_size=64 \
    actor_rollout_ref.actor.ppo_micro_batch_size=4 \
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
    actor_rollout_ref.rollout.n=8 \
    actor_rollout_ref.rollout.n_val=1 \
    actor_rollout_ref.rollout.sql_executor.max_time=300 \
    actor_rollout_ref.rollout.sql_executor.max_calls=20 \
    actor_rollout_ref.rollout.sql_executor.sqlite_source_path=data_prep/methods/RL-fine-tuning\
    actor_rollout_ref.ref.fsdp_config.param_offload=True \
    algorithm.kl_ctrl.kl_coef=0.001 \
    trainer.critic_warmup=0 \
    trainer.logger=['console','wandb'] \
    trainer.project_name='deepscaler' \
    trainer.experiment_name='deepscaler-7b-4n-Coder-func-bird' \
    +trainer.val_before_train=False \
    trainer.n_gpus_per_node=8 \
    trainer.nnodes=4 \
    trainer.save_freq=10 \
    trainer.test_freq=20 \
    trainer.default_hdfs_dir=null \
    trainer.total_epochs=30 "${@:1}"

