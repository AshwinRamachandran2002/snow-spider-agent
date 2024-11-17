# snow-spider-agent
Agent for Spider 2.0 text-to-SQL.

## 🚀 Quickstart

1. **Snowflake Account**: ~~Follow this [guideline](https://github.com/xlang-ai/Spider2/blob/main/assets/Snowflake_Guideline.md) to get your own Snowflake username and password in our snowflake database. You must update `bigquery_credential.json` and `snowflake_credential.json`.~~ If you're a Snowflake employee, intern or collaborator, please contact `@canwen.xu` for account setup.

2. Create `snowflake_credential.json`. You can find the template in `spider-agent-snow/snowflake_credential.json.example`.


#### Run Spider-Agent(Snow)

1. **Install Docker**. Follow the instructions in the [Docker setup guide](https://docs.docker.com/engine/install/) to install Docker on your machine.
2. **Install conda environment**.
```
git clone https://github.com/snowflakedb/snow-spider-agent.git

# Optional: Create a Conda environment for Spider 2.0
# conda create -n spider2 python=3.11
# conda activate spider2

# Install required dependencies
pip install -r requirements.txt
```
3. **Configure credential**: Create `snowflake_credential.json` in `./spider-agent-snow/` and `./spider2-snow-bench`. You can find the template in `spider-agent-snow/snowflake_credential.json.example`.

4. **Spider 2.0-Snow Setup**
```
cd ./spider-agent-snow
python spider_agent_setup_snow.py
```

5. **Run agent**
```
cd ./spider-agent-snow
export OPENAI_API_KEY=<your-openai-key>
python run.py --model gpt-4o -s <experiment-name>
```

For Azure OpenAI, do this (remember to add `azure/` before the deployment name):
```
export AZURE_API_KEY=<azure-api-key>
export AZURE_ENDPOINT=<azure-endpoint>
python run.py --agent default-agent --model azure/<deployment-name> -s <experiment-name>
```

## Evaluation

```
python get_spider2snow_submission_data.py --experiment_id default-agent-gpt4o-241117 --results_folder_name ../spider2-snow-bench/evaluation_suite/experiments/default-agent-gpt4o-241117

cd ../spider2-snow-bench/evaluation_suite
python evaluate.py --mode exec_result --result_dir ./experiments/default-agent-gpt4o-241117
```
