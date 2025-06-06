set -e
export DATA_DIR="BIRD"
# rm -rf BIRD/gold_results
mkdir -p BIRD/gold_results

MODEL_PATH=$1

# python raw2parquet_0.py \
#     --local_dir $DATA_DIR/verl_raw_parquet \
#     --raw_data_path $DATA_DIR/train \
#     --database_path $DATA_DIR/train/train_databases \
#     --dataset_type bird \
#     --dataset_mode train \
#     --save_prefix bird \
#     --model_path $MODEL_PATH
# python sql_exec_time_1.py \
#     --parquet_data_path $DATA_DIR/verl_raw_parquet/bird_train.parquet \
#     --local_dir $DATA_DIR/verl_exec_time_parquet \
#     --database_path $DATA_DIR/train/train_databases \
#     --dataset_type bird \
#     --dataset_mode train \
#     --save_prefix bird_exec_time \
#     --model_path $MODEL_PATH

# python raw2parquet_0.py \
#     --local_dir $DATA_DIR/verl_raw_parquet \
#     --raw_data_path $DATA_DIR/dev \
#     --database_path $DATA_DIR/dev/dev_databases \
#     --dataset_type bird \
#     --dataset_mode dev \
#     --save_prefix bird \
#     --model_path $MODEL_PATH
# python sql_exec_time_1.py \
#     --parquet_data_path $DATA_DIR/verl_raw_parquet/bird_dev.parquet \
#     --local_dir $DATA_DIR/verl_exec_time_parquet \
#     --database_path $DATA_DIR/dev/dev_databases \
#     --dataset_type bird \
#     --dataset_mode dev \
#     --save_prefix bird_exec_time \
#     --model_path $MODEL_PATH
python mk_json.py --dataset_mode train --parquet_data_path BIRD/verl_exec_time_parquet/bird_exec_time_train.parquet
python mk_json.py --dataset_mode dev --parquet_data_path BIRD/verl_exec_time_parquet/bird_exec_time_dev.parquet

cd ..
cp data_preprocess/data/train/bird.json rllm/data/train/code/
cp data_preprocess/data/dev/bird.json rllm/data/test/code/
python scripts/data/sql_dataset.py