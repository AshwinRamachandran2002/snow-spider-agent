"""
Preprocess the BIRD dataset to parquet format
"""
import os
os.environ["TOKENIZERS_PARALLELISM"] = "false"

import argparse
import time
import os
from pathlib import Path
from transformers import AutoTokenizer
from functools import partial

from datasets import load_dataset

from sql_utils import (
    get_db_path,
    SqlTask,
    load_bird_dataset_util, 
    load_spider_dataset_util
)
import shutil
import pandas as pd

def get_messages(data, tokenizer, model_type="qwen"):
    if model_type == "qwen":
        cot_info = "Let me solve this step by step. \n<think>"
        instruct_info = "\n\nPlease provide a chain-of-thought process and write your answer. Show your thought in <think> </think> tags. Provide your final answer in <answer> </answer> tags. Please write your final sql in the form of ```sql ...```. For example, <answer> SOME SUMMARY\n\n```sql\nSELECT * FROM employees\n```</answer>"
    elif model_type == "QwQ":
        cot_info = ""
        instruct_info = ""
    elif model_type == "deepseek":
        cot_info = ""
        instruct_info = ""
    elif model_type == "qwen_coder":
        cot_info = "Let me solve this step by step. \n<think>"
        instruct_info = "\n\nPlease provide a chain-of-thought process and write your answer. Show your thought in <think> </think> tags. Provide your final answer in <answer> </answer> tags. Please write your final sql in the form of ```sql ...```. For example, <answer> SOME SUMMARY\n\n```sql\nSELECT * FROM employees\n```</answer>"
    else:
        raise ValueError(f"model_type: {model_type} is not supported!")

    messages = [
        {
            "role": "system",
            "content": "You are a SQL analyst who writes great SQL code. You should think step-by-step and write your final sql in the format ```sql ...```.",
        },
        {
            "role": "user",
            "content": f"""
Database info: {data["db_desc"]}

Question: {data["question"]} {instruct_info}
""".strip(),
        },
    ]
    prompt = tokenizer.apply_chat_template(
        messages, add_generation_prompt=True, tokenize=False
    )
    prompt += cot_info
    num_tokens = len(
        tokenizer(prompt, return_tensors="pt", add_special_tokens=False)[
            "input_ids"
        ][0]
    )

    # for qwen-instruct,
    # Question: Please list the codes of the schools with a total enrollment of over 500. Total enrollment can be represented by `Enrollment (K-12)` + `Enrollment (Ages 5-17)`<|im_end|>
    # <|im_start|>assistant
    # Let me solve this step by step.
    # <think>

    # for qwen-deepseek distilled
    # Question: Please list the codes of the schools with a total enrollment of over 500. Total enrollment can be represented by `Enrollment (K-12)` + `Enrollment (Ages 5-17)`<｜Assistant｜><think>

    return num_tokens, messages


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--local_dir", default="~/data/bird")
    parser.add_argument("--dataset_type", type=str, choices=["bird", "spider", "gretelai"])
    parser.add_argument("--dataset_mode", type=str, choices=["train", "dev", "test", "train_aug"])
    parser.add_argument("--parquet_data_path", type=str)
    parser.add_argument("--database_path", type=str)
    parser.add_argument("--save_prefix", type=str)
    parser.add_argument("--cache_dir", type=str, default="./.cache")
    parser.add_argument(
        "--model_path",
        type=str,
        default="deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B",
    )

    args = parser.parse_args()

    # import debugpy
    # try:
    #     debugpy.listen(9501)
    #     debugpy.wait_for_client()
    # except Exception as e:
    #     print(e)

    tokenizer = AutoTokenizer.from_pretrained(args.model_path)

    dataset = load_dataset(
            "parquet", data_files=args.parquet_data_path, split="train" # fix split = 'train'
    )

    def make_map_fn(split):

        def process_fn(example, idx):
            num_tokens, messages = get_messages(example, tokenizer)

            time_start = time.time()
            for i in range(1):
                db_folder = Path(args.database_path)
                db_path = get_db_path(db_folder, example["db_id"])
                # print(db_path)
                env = SqlTask(example["ground_truth"], db_path)
                env.launch_env()
            time_end = time.time()
            # check if output is None
            out = env.answer
            empty_result = False
            empty_flag = True
            # try:
            #     empty_flag = all(not bool(x) for x in out[0])
            # except:
            #     pass
            # if len(out) > 1 or not empty_flag:
            if out:
                exec_time = time_end - time_start
            else:
                empty_result = True
                exec_time = 1000000
            data = {
                "data_source": args.dataset_type,
                "prompt": {
                    "question": example["question"],
                    "db_desc": example["db_desc"],
                },
                "ability": "sql",
                "reward_model": {
                    "style": "rule",
                    "ground_truth": example["ground_truth"]
                },
                "extra_info": {
                    'split': split,
                    'index': idx,
                    'answer': str(out),
                    "db_id": example["db_id"],
                    "num_tokens": num_tokens,
                    "exec_time": exec_time,
                    "empty_result": empty_result,
                }
            }
            if split == "dev" or (not empty_result and exec_time < 5 and "##SQLERROR##" not in str(out)):
                df = pd.DataFrame(out)
                df.to_csv(f"BIRD/gold_results/local_BIRD_{split}_{idx:04d}.csv", index=False)
                folder_name = f"BIRD/examples_{split}/local_BIRD_{split}_{idx:04d}"
            else:
                print(f"{idx}: {out}")
            return data

        return process_fn
    
    dataset = dataset.map(function=make_map_fn(args.dataset_mode), with_indices=True, num_proc=int(os.cpu_count() * 0.8))
    dataset.to_parquet(os.path.join(args.local_dir, f"{args.save_prefix}_{args.dataset_mode}.parquet"))
