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
python run.py --test_path examples --model gpt-4o
```