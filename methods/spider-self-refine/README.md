# Self-Refinement Agent with Format Restriction and Column Exploration on Spider2.0-snow and Spider2.0-lite

## Dependencies

```
conda create -n sql python=3.10 -y
conda activate sql
pip install -r requirements.txt
```

## Spider2.0-snow

### Set up
Put `snowflake_credential.json` in folder `snow-spider-agent/methods/spider-self-refine`.

Set up folders: 
```
python spider_agent_setup_snow.py
```

### Reconstruct data
```
python reconstruct_data.py --example_folder examples
```

### Run
Export keys: OPENAI or AZURE
```
export OPENAI_API_KEY=YOUR_API_KEY
export AZURE_ENDPOIONT=YOUR_AZURE_ENDPOIONT
export AZURE_OPENAI_KEY=YOUR_AZURE_API_KEY
```
Run single process version:
```
python run.py --test_path examples --model o1-preview --understanding_model o1-preview --output_path output/o1-preview-snow-log --azure --temperature 0
```
Run voting:
```
python run_vote.py --test_path examples --model o1-preview --understanding_model o1-preview --output_path output/o1-preview-snow-log --azure --temperature 0 --num_processes 3
```
### Evaluation
Preparation for evaluation files:
```
python get_metadata.py --result_path output/o1-preview-snow-log --output_path output/o1-preview-snow
```

Run evaluation:
```
cd ../../spider2-snow/evaluation_suite
python evaluate.py --mode exec_result --result_dir ../../methods/spider-self-refine/output/o1-preview-snow
```

## Spider2.0-lite

### Set up
Put `snowflake_credential.json` and `bigquery_credential.json` in folder `snow-spider-agent/methods/spider-self-refine`.

Set up folders: 
```
gdown 'https://drive.google.com/uc?id=1coEVsCZq-Xvj9p2TnhBFoFTsY-UoYGmG' -O ../../spider2-lite/resource/
rm -rf ../../spider2-lite/resource/databases/spider2-localdb
mkdir -p ../../spider2-lite/resource/databases/spider2-localdb
unzip ../../spider2-lite/resource/local_sqlite.zip -d ../../spider2-lite/resource/databases/spider2-localdb
python spider_agent_setup_lite.py
```

### Reconstruct data
```
python reconstruct_data.py --example_folder examples_lite
```

### Run
Export keys: OPENAI or AZURE
```
export OPENAI_API_KEY=YOUR_API_KEY
export AZURE_ENDPOIONT=YOUR_AZURE_ENDPOIONT
export AZURE_OPENAI_KEY=YOUR_AZURE_API_KEY
```
Run single process version:
```
python run.py --test_path examples_lite --model o1-preview --understanding_model o1-preview --output_path output/o1-preview-lite-log --azure --temperature 0
```
Run voting:
```
python run_vote.py --test_path examples_lite --model o1-preview --understanding_model o1-preview --output_path output/o1-preview-lite-log --azure --temperature 0 --num_processes 3
```
### Evaluation
Preparation for evaluation files:
```
python get_metadata.py --result_path output/o1-preview-lite-log --output_path output/o1-preview-lite
```

Run evaluation:
```
cd ../../spider2-lite/evaluation_suite
python evaluate.py --mode exec_result --result_dir ../../methods/spider-self-refine/output/o1-preview-lite
```