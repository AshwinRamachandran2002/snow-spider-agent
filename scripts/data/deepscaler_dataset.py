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
from verl.utils.reward_score.math import last_boxed_only_string, remove_boxed

from deepscaler.system_prompts import Prompts
from deepscaler.data.utils import load_dataset
from deepscaler.rewards.math_utils.utils import get_api_name
from deepscaler.data.dataset_types import TrainDataset, TestDataset


def extract_solution(solution_str: str) -> str:
    """Extract the final boxed solution from a solution string.

    Args:
        solution_str: Raw solution string that may contain multiple boxed answers

    Returns:
        The final boxed answer with box notation removed
    """
    return remove_boxed(last_boxed_only_string(solution_str))


def make_map_fn(split: str):
    """Create a mapping function to process dataset examples.

    Args:
        split: Dataset split name ('train' or 'test')

    Returns:
        Function that processes individual dataset examples
    """
    def process_fn(example: Dict[str, Any], idx: int) -> Optional[Dict[str, Any]]:
        question = example.pop('question')
        instruction = "This is a Text-to-SQL task where you are given database information and a question, and your goal is to generate only one SQL query as the answer. Let's think step by step and output the whole final SQL within ```sql``` code block.\n"
        instruction += "Table info:\n" + example["input"]

        api = get_api_name(example["example_id"])
        sqlite_path = None
        if api == "sqlite":
            sqlite_path = example["sqlite_path"]
        sql_prompt = Prompts()
        tb_str = "The table structure information is ({database name: {schema name: [table name]}}): \n"
        table_struct = example['input'][example['input'].find(tb_str)+len(tb_str):].replace("\n", "")
        instruction += f"The SQL dialect is {api}. Basic usage: " + sql_prompt.get_prompt_dialect_basic(api)
        if sql_prompt.get_prompt_dialect_basic_eg(api, table_struct):
            # print(sql_prompt.get_prompt_dialect_basic_eg(api, table_struct))
            instruction += sql_prompt.get_prompt_dialect_basic_eg(api, table_struct)
        instruction += f"Question: {question}\n"
        question = instruction
        
        # gold_results_path = example.pop('gold_results_path')
        # answer = gold_results_path
        ex_id = example["example_id"]

        data = {
            "data_source": "",
            "prompt": [{
                "role": "user",
                "content": question
            }],
            "ability": "code",
            "reward_model": {
                "style": "rule",
                # "ground_truth": answer,
                "sqlite_path": sqlite_path,
                "example_id": ex_id
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
    parser.add_argument('--local_dir', default='deepscaler/data/processed',
                       help='Local directory to save processed datasets')
    parser.add_argument('--hdfs_dir', default=None,
                       help='Optional HDFS directory to copy datasets to')
    args = parser.parse_args()

    local_dir = args.local_dir
    hdfs_dir = args.hdfs_dir
    
    # Make local directory if it doesn't exist
    if not os.path.exists(local_dir):
        makedirs(local_dir)

    # Initialize datasets
    train_datasets = [TrainDataset.TRAINING_DATA_AUG]
    train_dataset = load_dataset(train_datasets[0])
    test_datasets = [TestDataset.LITE_TEST_ALL_DATA, TestDataset.LITE_TEST_DATA, TestDataset.SNOW_TEST_ALL_DATA, TestDataset.SNOW_TEST_DATA, TestDataset.VAL_DATA]
    
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