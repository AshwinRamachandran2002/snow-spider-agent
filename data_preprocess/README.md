### Download BIRD Data
```bash
cd BIRD
wget https://bird-bench.oss-cn-beijing.aliyuncs.com/train.zip
unzip train.zip
cd train
unzip train_databases.zip

cd ..
wget https://bird-bench.oss-cn-beijing.aliyuncs.com/dev.zip
unzip dev.zip
mv dev_20240627 dev
cd dev
unzip dev_databases.zip
```

### Data Preprocessing
```
sbatch sbatch.sh:
```

```
python mk_json.py --dataset_mode train --parquet_data_path BIRD/verl_exec_time_parquet/bird_exec_time_train.parquet
python mk_json.py --dataset_mode dev --parquet_data_path BIRD/verl_exec_time_parquet/bird_exec_time_dev.parquet
```

```
cd BIRD
python make_json.py
```