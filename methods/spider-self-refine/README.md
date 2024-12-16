# spider2 snow subset by self-refine prompting

## Set up
Put `snowflake_credential.json` in this folder.

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
python run.py --test_path examples --model gpt-4o --output_path output/gpt-4o-test1-log
```

## Evaluation
Preparation for evaluation files:
```
python get_metadata.py --result_path output/gpt-4o-test1-log --output_path output/gpt-4o-test1
```

Run evaluation:
```
cd ../../spider2-snow/evaluation_suite
python evaluate.py --mode exec_result --result_dir ../../methods/spider-self-refine/output/gpt-4o-test1
```