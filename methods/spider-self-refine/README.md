# spider2 snow subset by self-refine prompting

## Set up
Put `snowflake_credential.json` in folder `snow-spider-agent/methods/spider-self-refine`.

Run:
```
conda create -n sql python=3.10 -y
conda activate sql
pip install -r requirements.txt
```

Set up folders: 
```
python spider_agent_setup_snow.py
```

## Reconstruct data
```
python reconstruct_data.py --example_folder examples
```

## Run
```
export OPENAI_API_KEY=YOUR_API_KEY
export AZURE_ENDPOIONT=YOUR_AZURE_ENDPOIONT
export AZURE_OPENAI_KEY=YOUR_AZURE_API_KEY
python run.py --test_path examples --model o1-preview --understanding_model o1-preview --output_path output/o1-preview-test-all-log --azure
```

## Evaluation
Preparation for evaluation files:
```
python get_metadata.py --result_path output/o1-preview-test1-log --output_path output/o1-preview-test-all
```

Run evaluation:
```
cd ../../spider2-snow/evaluation_suite
python evaluate.py --mode exec_result --result_dir ../../methods/spider-self-refine/output/o1-preview-test-all
```