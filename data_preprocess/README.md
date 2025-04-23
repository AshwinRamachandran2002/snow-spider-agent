### Download BIRD Data
```bash
wget https://bird-bench.oss-cn-beijing.aliyuncs.com/train.zip
python -m zipfile -e train.zip .
cd train
python -m zipfile -e train_databases.zip .

cd ..
wget https://bird-bench.oss-cn-beijing.aliyuncs.com/dev.zip
python -m zipfile -e dev.zip .
mv dev_20240627 dev
cd dev
python -m zipfile -e dev_databases.zip .
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