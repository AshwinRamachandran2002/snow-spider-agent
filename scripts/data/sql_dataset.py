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

Given a task, you should reason step by step using execution feedback to arrive at the final answer.

Step 1: Identify all relevant schemas (which may include more than just the gold schema) and enclose them within <schema_linking></schema_linking> tags. The schema should be represented in JSON format:
<schema_linking>
{Table name: [column name1, column name2]}.
</schema_linking>

Step 2: Write SQL queries to examine the values of each column in the JSON to assess their validity. Use <exec_sql></exec_sql> tags to execute SQL queries. The results will be returned in <exec_result></exec_result> tags. You should reason based on results.

Step 3: After reviewing all relevant schemas and values from the database, decide on the final schema to use by removing useless parts in the previous JSON. 
Then, generate the final SQL query inside <exec_sql></exec_sql> tags and verify its correctness based on the feedback provided in <exec_result></exec_result> tags.

Step 4: Write the final SQL in <answer></answer> tags.

Note: 

Do not generate <exec_result></exec_result> tags yourself. If any syntax error or empty result occurs, revise your query accordingly before proceeding. All 'SELECT' should be in <exec_sql></exec_sql> block. <schema_linking> and </schema_linking> should appear twice: in Step 1 and Step 3.

The SQL dialect must be SQLite. Use the format SELECT "column_name" FROM "table_name" WHERE ..., replacing "table_name" and "column_name" with actual names. Always enclose table and column names in double quotation marks.
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
        db_info = "DB Info: " + example["input"] + "\n" + "Question: " + example["question"] + "\n"
        user_prompt += db_info

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
    train_datasets = [TrainDataset.Code.BIRD]
    train_dataset = load_dataset(train_datasets[0])
    test_datasets = [TestDataset.Code.BIRD]
    
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
        test_df.to_parquet(os.path.join(local_dir, f'{dataset_name}_dev.parquet'))
        print(f"{dataset_name} test data size:", len(test_data))

    # Save training dataset
    print("train data size:", len(train_data))
    train_df = pd.DataFrame(train_data)
    train_df.to_parquet(os.path.join(local_dir, 'train.parquet'))

    # Optionally copy to HDFS
    if hdfs_dir is not None:
        makedirs(hdfs_dir)
        copy(src=local_dir, dst=hdfs_dir)