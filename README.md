# snow-spider-agent
Snowflake Internal agent framework and evaluation toolkit for Spider 2.0-Snow.

This repo is heavily refactored from [the official repo](https://github.com/snowflakedb/snow-spider-agent) for improved engineering practices and allows multiple teams to simultaneously experiment with their own ideas and develop their own agents without causing conflicts. The design document can be found [here](https://docs.google.com/document/d/1RS6YPSkuuZfSQbdt00sMe7D3KLWpOSg_JpUdoDJLCQ4/edit?usp=sharing).

## 🚀 Quickstart

1. **Snowflake Account**: ~~Follow this [guideline](https://github.com/xlang-ai/Spider2/blob/main/assets/Snowflake_Guideline.md) to get your own Snowflake username and password in our snowflake database. You must update `bigquery_credential.json` and `snowflake_credential.json`.~~ If you're a Snowflake employee, intern or collaborator, please use [this form](https://forms.gle/nDo6ovuQhavkpYit5) to submit an account request.

2. Create `snowflake_credential.json`. You can find the template in `spider-agent-snow/snowflake_credential.json.example`.


### Run Spider-Agent(Snow)

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
python run.py --agent default-agent --model gpt4o -s 241117
```

For Azure OpenAI, do this (remember to add `azure/` before the deployment name):
```
export AZURE_API_KEY=<azure-api-key>
export AZURE_ENDPOINT=<azure-endpoint>
python run.py --agent default-agent --model azure/gpt4o -s 241117
```

### Evaluation

```
python get_spider2snow_submission_data.py --experiment_id default-agent-gpt4o-241117 --results_folder_name ../spider2-snow-bench/evaluation_suite/experiments/default-agent-gpt4o-241117

cd ../spider2-snow-bench/evaluation_suite
python evaluate.py --mode exec_result --result_dir ./experiments/default-agent-gpt4o-241117
```

## 🔧 Develop your own agent

You can follow these steps to develop your own agents:
1. Define the actions. The new action should be a separate file in `./snow-spider-agent/spider-agent-snow/spider_agent/agent/actions`. Use existing actions for reference.
2. Define your agents. Create a separate file in `spider-agent-snow/spider_agent/agent/agents`. Use the [official Spider Agent](spider-agent-snow/spider_agent/agent/agents/prompt_agent.py) for reference. Don't forget to register your agents in [`__init__.py`](spider-agent-snow/spider_agent/agent/agents/__init__.py).
3. Run your own agent by `python run.py --agent <your_agent_name> ...`.

## 🏆 Internal Leaderboard

| Name          | Correct/Total | Score | Description                                                                                                                                                                       |
|---------------|---------------|-------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Spider-Agent (gpt4o-240513)  | 40/260        | 15.4  | Reproduced number of [the official repo](https://github.com/snowflakedb/snow-spider-agent) by @canwen.xu                                                                          |
| Spider-Agent (gpt4o-240806)  | 36/260        | 13.8  | Reproduced number of [the official repo](https://github.com/snowflakedb/snow-spider-agent) by @hao.zhang's lab                                                                    |
| default-agent (gpt4o-240806) | 35/260        | 13.5  | [Default agent](/spider-agent-snow/spider_agent/agent/agents/__init__.py) in this repo (added `tree` in initial prompt to save a few steps; minor action name change)             |
