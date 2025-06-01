"""
Preprocess the BIRD dataset to parquet format
"""

import argparse
import os
from transformers import AutoTokenizer
from datasets import concatenate_datasets, load_dataset
import json

from sql_utils import (
    get_db_path,
    SqlTask,
    load_bird_dataset_util, 
    load_spider_dataset_util
)





if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--local_dir", default="~/data/bird")
    parser.add_argument("--dataset_type", type=str, choices=["bird", "spider", "gretelai"])
    parser.add_argument("--dataset_mode", type=str, choices=["train", "dev", "test", "train_aug"])
    parser.add_argument("--raw_data_path", type=str)
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
    if args.dataset_type == "gretelai":
        # with open(args.raw_data_path, "r") as f:
        #     dataset = json.load(f)
        dataset = load_dataset("json", data_files=args.raw_data_path)["train"]
    else:
        if args.dataset_type == "spider":
            load_data = load_spider_dataset_util 
        elif args.dataset_type == "bird":
            load_data = load_bird_dataset_util

        tokenizer = AutoTokenizer.from_pretrained(args.model_path)
        if args.dataset_type == "spider" and args.dataset_mode == "train":
            train_dataset = load_spider_dataset_util(
                args.raw_data_path, "train", args.cache_dir, tokenizer
            )

            dev_dataset = load_spider_dataset_util(
                args.raw_data_path, "dev", args.cache_dir, tokenizer
            )
            dataset = concatenate_datasets([train_dataset, dev_dataset])

        else:
            dataset = load_data(
                args.raw_data_path, args.dataset_mode, args.cache_dir, tokenizer
            )

    print(dataset)
    with open(f"data/{args.dataset_mode}/{args.dataset_mode}_bird.json") as f:
        omni_data = json.load(f)

    def add_db_desc(example, omni):
        question = example['question']
        omni_input = omni['input_seq']
        assert question[:20] in omni_input
        assert omni_input.count("Database Schema:\n") == 1 and omni_input.count("\nThis schema describes the database's structure") == 1
        db_desc = omni_input[
            omni_input.find("Database Schema:\n")+len("Database Schema:\n") :
            omni_input.find("\nThis schema describes the database's structure")
        ]
        example['db_desc'] = db_desc
        return example

    dataset = dataset.map(lambda ex, idx: add_db_desc(ex, omni_data[idx]), with_indices=True)
    print(dataset[0])
    dataset.to_parquet(os.path.join(args.local_dir, f"{args.save_prefix}_{args.dataset_mode}.parquet"))