# ReFoRCE: A Text-to-SQL Agent with Self-Refinement, Format Restriction, and Column Exploration

## Setup

### Dependencies
```
conda create -n sql python=3.10 -y
conda activate sql
pip install -r requirements.txt
```

For folder `spider2-lite` and `spider2-snow`, get the latest version from [Spider2 repo](https://github.com/xlang-ai/Spider2).

## Spider2.0-snow

### Set up
Put `snowflake_credential.json` in this folder (`snow-spider-agent/methods/ReFoRCE`).

Set up folders: 
```
python spider_agent_setup_snow.py
```

### Reconstruct data
First, roughly compress.
```
python reconstruct_data.py --example_folder examples_snow --add_description --make_folder --rm_digits
```

### Run
Export keys: OPENAI or AZURE (optional)
```
export OPENAI_API_KEY=YOUR_API_KEY
export AZURE_ENDPOIONT=YOUR_AZURE_ENDPOIONT
export AZURE_OPENAI_KEY=YOUR_AZURE_API_KEY
```

Run voting:
```
python run.py --db_path examples_snow --model o1-preview --pre_model o1-preview --output_path output/o1-preview-snow-log --azure --num_threads 3 --task snow
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
Put `snowflake_credential.json` and `bigquery_credential.json` in this folder (`snow-spider-agent/methods/ReFoRCE`).

Set up folders: 
```
gdown 'https://drive.google.com/uc?id=1coEVsCZq-Xvj9p2TnhBFoFTsY-UoYGmG' -O ../../spider2-lite/resource/
rm -rf ../../spider2-lite/resource/databases/spider2-localdb
mkdir -p ../../spider2-lite/resource/databases/spider2-localdb
unzip ../../spider2-lite/resource/local_sqlite.zip -d ../../spider2-lite/resource/databases/spider2-localdb
python spider_agent_setup_lite.py
```

### Reconstruct data
First, roughly compress.
```
python reconstruct_data.py --example_folder examples_lite --add_description --make_folder --rm_digits
```

### Run
Export keys: OPENAI or AZURE (optional)
```
export OPENAI_API_KEY=YOUR_API_KEY
export AZURE_ENDPOIONT=YOUR_AZURE_ENDPOIONT
export AZURE_OPENAI_KEY=YOUR_AZURE_API_KEY
```

Run voting:
```
python run.py \
--task lite \
--db_path examples_lite \
--output_path output/o1-preview-lite-log \
--model o1-preview \
--pre_model o1-preview \
--azure \
--schema_linking_model o1-preview \
--model_vote
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