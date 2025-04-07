#!/bin/bash
#SBATCH --job-name=sql_exec_time_1
#SBATCH --output=logs/sql_exec_time_1-%j.out
#SBATCH --error=logs/sql_exec_time_1-%j.err
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=224
#SBATCH --mem=2063800M
#SBATCH --time=100:00:00
#SBATCH --gpus-per-task=8
export DATA_DIR=BIRD
python raw2parquet_0.py \
    --local_dir $DATA_DIR/verl_raw_parquet \
    --raw_data_path $DATA_DIR/train \
    --database_path $DATA_DIR/train/train_databases \
    --dataset_type bird \
    --dataset_mode train \
    --save_prefix bird \
    --model_path Qwen/Qwen2.5-1.5B-instruct 
python sql_exec_time_1.py \
    --parquet_data_path $DATA_DIR/verl_raw_parquet/bird_train.parquet \
    --local_dir $DATA_DIR/verl_exec_time_parquet \
    --database_path $DATA_DIR/train/train_databases \
    --dataset_type bird \
    --dataset_mode train \
    --save_prefix bird_exec_time \
    --model_path Qwen/Qwen2.5-1.5B-instruct 