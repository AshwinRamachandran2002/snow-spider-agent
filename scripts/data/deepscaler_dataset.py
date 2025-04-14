import argparse
import os
from typing import Dict, List, Optional, Any

import pandas as pd
from verl.workers.reward_model.reward_utils import get_api_name


def make_map_fn(split: str):
    """Create a mapping function to process dataset examples.

    Args:
        split: Dataset split name ('train' or 'test')

    Returns:
        Function that processes individual dataset examples
    """
    def process_fn(example: Dict[str, Any], idx: int) -> Optional[Dict[str, Any]]:
        api = get_api_name(example["example_id"])
        sqlite_path = None
        if api == "sqlite":
            sqlite_path = example["sqlite_path"]

        ex_id = example["example_id"]
        
        sql_input = example["input"]
        sys_prompt = f"You are a data scientist proficient in Text-to-SQL tasks. Given a task, you should determine the answer format first, then reason step by step to generate at least 5 SQL queries from simple to complex to undersatnd DB schema, execute them step by step, and provide a final answer after reviewing the results. You should use the <formatting></formatting> tags for formatting in ``csv\n``` code block, <exec_sql></exec_sql> tags to execute SQLs and you will get result feedback. If there is any syntax error or empty result, you should fix it. There's no gold answer with empty results. Write final answer in <|im_start|>SQL\n<|im_end|> tags. The SQL dialect must be {api}. Basic usage: SELECT \"column_name\" FROM \"table_name\" WHERE ... (Replace \"table_name\" with the actual table name. Enclose table and column names with double quotations if they contain special characters or match reserved keywords.)\n"
        user_prompt = sys_prompt
        if isinstance(sql_input, list):
            user_prompt += sql_input[0]
            table_structure = sql_input[1]
            if api == "sqlite":
                user_prompt += "The table structure information is [table name: {column name}]: \n" + table_structure + "\n"
            else:
                user_prompt += "The table structure information is ({database name: {schema name: {table name}}}): \n" + table_structure + "\n"
        else:
            user_prompt += sql_input

        user_prompt += "\nTask: " + example["question"]

        data = {
            "data_source": "",
            "prompt": [{
                "role": "user",
                "content": user_prompt
            }],
            "ability": "code",
            "reward_model": {
                "style": "rule",
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
    args = parser.parse_args()

    local_dir = args.local_dir

    # Initialize datasets
    import json
    train_datasets = [
        # "spider2_train_data",
        # "spider1_bird_train_data",
        # "bird_train_data_add_ev",
        "bird_train_data_change_pth"
    ]
    def load_dataset_train(file_path):
        file_path = f"deepscaler/data/train/{file_path}.json"
        with open(file_path, "r", encoding="utf-8") as file:
            return json.load(file)
    train_datasets_data = [load_dataset_train(d) for d in train_datasets]
    # Process and save combined together
    
    for train_dataset, train_data_list in zip(train_datasets, train_datasets_data):
        train_data: List[Dict[str, Any]] = []
        process_fn = make_map_fn('train')
        for idx, example in enumerate(train_data_list):
            processed_example = process_fn(example, idx)
            if processed_example is not None:
                train_data.append(processed_example)

        train_df = pd.DataFrame(train_data)
        train_df.to_parquet(os.path.join(local_dir, f'{train_dataset}.parquet'))
        print(f"{train_dataset} size:", len(train_data))


    test_datasets = [
        # "lite_test_data",
        # "snow_test_data",
        # "lite_test_all_data",
        # "snow_test_all_data",
        # "spider1_dev_data",
        # "spider1_test_data",
        # "bird_dev_data_add_ev",
        "bird_dev_data_change_pth"
    ]    
    def load_dataset(file_path):
        file_path = f"deepscaler/data/test/{file_path}.json"
        with open(file_path, "r", encoding="utf-8") as file:
            return json.load(file)
    test_datasets_data = [load_dataset(d) for d in test_datasets]
    # Process and save combined together
    
    for test_dataset, test_data_list in zip(test_datasets, test_datasets_data):
        test_data: List[Dict[str, Any]] = []
        process_fn = make_map_fn('test')
        for idx, example in enumerate(test_data_list):
            processed_example = process_fn(example, idx)
            if processed_example is not None:
                test_data.append(processed_example)

        test_df = pd.DataFrame(test_data)
        test_df.to_parquet(os.path.join(local_dir, f'{test_dataset}.parquet'))
        print(f"{test_dataset} size:", len(test_data))

