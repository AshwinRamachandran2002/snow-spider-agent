sbatch.sh:
```
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


```

```
python mk_json.py --dataset_mode train --parquet_data_path BIRD/verl_exec_time_parquet/bird_exec_time_train.parquet
python mk_json.py --dataset_mode dev --parquet_data_path BIRD/verl_exec_time_parquet/bird_exec_time_dev.parquet
```

```
cd BIRD
python make_json.py
```