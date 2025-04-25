"""Script to prepare DeepScaler training and test datasets.

This script processes math problem datasets into a standardized format for training
and testing DeepScaler models. It loads problems from specified datasets, adds
instruction prompts, and saves the processed data as parquet files.
"""

import argparse
import os
from typing import Dict, List, Optional, Any

import pandas as pd
from verl.utils.hdfs_io import copy, makedirs

from rllm.data.utils import load_dataset
from rllm.data.dataset_types import TrainDataset, TestDataset


prompt = """
You are a data scientist proficient in Text-to-SQL tasks. 
Given a task, you should reason step by step to generate at least 5 SQL queries from simple to complex to undersatnd DB schema, execute them step by step, and provide a final answer after reviewing the results. 
You should use the <exec_sql></exec_sql> tags to execute SQLs and you will get result feedback in <exec_result></exec_result> tags. You should continue to reason based on results. Don't generate <exec_result></exec_result> tags by yourself.
If there is any syntax error or empty result, you should fix it. For most questions, there's no gold answer with empty results. 
Write final answer in <answer>\n</answer> tags. The SQL dialect must be SQLite. 
Basic usage: SELECT \"column_name\" FROM \"table_name\" WHERE ... (Replace \"table_name\" with the actual table name. Enclose table and column names with double quotations.)
"""

def make_map_fn(split: str):
    """Create a mapping function to process dataset examples.

    Args:
        split: Dataset split name ('train' or 'test')

    Returns:
        Function that processes individual dataset examples
    """
    def process_fn(example: Dict[str, Any], idx: int, instruction: str = None) -> Optional[Dict[str, Any]]:
        
        user_prompt = prompt
        user_prompt += "\nTask: " + example["question"]

        data = {
            "data_source": "",
            "prompt": [{
                "role": "user",
                "content": user_prompt
            }],
            "ability": "math",
            "reward_model": {
                "style": "rule",
                "ground_truth": {"sqlite_path": example["sqlite_path"], "example_id": example["example_id"]}
            },
            "extra_info": {
                'split': split,
                'index': idx
            }
        }
        return data
    return process_fn


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Process datasets for DeepScaler training')
    parser.add_argument('--local_dir', default="data_preprocess/data/processed",
                       help='Local directory to save processed datasets')
    parser.add_argument('--hdfs_dir', default=None,
                       help='Optional HDFS directory to copy datasets to')
    args = parser.parse_args()

    local_dir = args.local_dir
    hdfs_dir = args.hdfs_dir
    
    # Make local directory if it doesn't exist
    makedirs(local_dir, exist_ok=True)

    # Initialize datasets
    train_datasets = [TrainDataset.Code.BIRD_TRAIN]
    train_dataset = load_dataset(train_datasets[0])
    test_datasets = [TestDataset.Code.BIRD_DEV]
    
    test_datasets_data = [load_dataset(d) for d in test_datasets]

    # Process training data
    train_data: List[Dict[str, Any]] = []
    process_fn = make_map_fn('train')
    for idx, example in enumerate(train_dataset):
        processed_example = process_fn(example, idx)
        if processed_example is not None:
            train_data.append(processed_example)

    # Process and save each test dataset separately
    for test_dataset, test_data_list in zip(test_datasets, test_datasets_data):
        test_data: List[Dict[str, Any]] = []
        process_fn = make_map_fn('test')
        for idx, example in enumerate(test_data_list):
            processed_example = process_fn(example, idx)
            if processed_example is not None:
                test_data.append(processed_example)

        dataset_name = test_dataset.value.lower()
        test_df = pd.DataFrame(test_data)
        test_df.to_parquet(os.path.join(local_dir, f'{dataset_name}.parquet'))
        print(f"{dataset_name} test data size:", len(test_data))

    # Save training dataset
    print("train data size:", len(train_data))
    train_df = pd.DataFrame(train_data)
    train_df.to_parquet(os.path.join(local_dir, 'train.parquet'))

    # Optionally copy to HDFS
    if hdfs_dir is not None:
        makedirs(hdfs_dir)
        copy(src=local_dir, dst=hdfs_dir)