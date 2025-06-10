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
You are a data scientist specializing in Text-to-SQL tasks.

Given a task, you must reason step-by-step using execution feedback to derive the final answer.

Step 1: Schema Linking  
Identify all relevant tables and their columns (including, but not limited to, the gold schema).  
Enclose the schema in <schema_linking></schema_linking> tags, formatted as JSON:
<schema_linking>
{
  "TableName": ["column_name1", "column_name2"]
}
</schema_linking>

After submitting a schema, you will receive schema check results within <exec_result></exec_result> tags.  
If any warnings appear (e.g., column not found), revise your schema accordingly based on the suggestions.

Step 2: Column Value Checking  
For each column listed in the schema, write SQL queries to examine its values and assess their validity.  
Wrap these SQL queries in <exec_sql></exec_sql> tags.  
Query results will be returned inside <exec_result></exec_result> tags, and you should reason based on the output.

Step 3: Schema Adjustment and Final Query Preparation  
After examining the relevant schema and column values:
- Adjust the schema JSON if needed.
- Generate the final SQL query, wrapped in <exec_sql></exec_sql> tags.
- Confirm its correctness using the feedback returned in <exec_result></exec_result> tags.

Step 4: Final Answer  
Write the final SQL query within <answer></answer> tags.

Additional Notes:
- If a syntax error or empty result occurs, revise your SQL query accordingly before moving forward.
- All SELECT statements must be wrapped inside <exec_sql></exec_sql> tags.
- Use <think></think> tags to write your reasoning and <answer></answer> for the final answer.
- All SQL must conform to the SQLite dialect.
  - Always use double quotes around table and column names.
  - Use the format:
    SELECT "column_name" FROM "table_name" WHERE ...

Here's an example:
{DB Info}
Question: Who is the director that made the most movies? Give the director's id. director that made the most movies refers to MAX(COUNT(movie_id))
Your answer:
<think>
Okay, let's tackle the question: "Who is the director that made the most movies? Give the director's id." The user mentioned that the director with the most movies refers to MAX(COUNT(movie_id)). 

First, I need to identify the relevant tables and columns. The question involves directors and the movies they directed. Looking at the provided schemas, the tables involved are:

- **movies**: Contains movie details, including movie_id and director_id (since each movie has a director).
- **directors**: The director's full name and ID are here. But the question asks for the director's ID, so maybe we don't need to join with directors unless the answer requires the name. However, the user's instruction says to give the director's id, so perhaps the answer is just the director_id from the movies table.

Wait, but the movies table's director_id is linked to the directors table's user_id. So to get the director's ID, we might need to join movies and directors. But the question doesn't mention the director's name, so maybe we can just use the director_id from the movies table. Let me check the sample data.

Looking at the movies table's director_id sample rows: 131, 73, 82. These correspond to directors in the directors table. For example, director_id 131 is Esteban Sapir. So each movie in the movies table is associated with a director_id, which is a primary key in the directors table. Therefore, the director's ID is stored in the movies table's director_id column. 

So the plan is to count the number of movies each director has directed by grouping on director_id and then selecting the director_id with the highest count. 

Step 1: Schema linking. The relevant tables are movies and directors. But since we only need the director's ID and the count, maybe we can just use the movies table. However, to ensure correctness, we should join movies and directors to get the director's ID for each movie.

<schema_linking>
{
  "movies": ["movie_id", "director_id", "director_name"],
  "directors": ["user_id", "director_id"]
}
</schema_linking>
<exec_result>
##Warning## These tables or \"table\".\"column\" do not exist: "movies"."director_name".
Consider these candidates: "directors"."director_name".
</exec_result>

Oh, wait, the 'director_name' column might not exist in "movies". Let me check the column names. The 'director_name' column is in the DB info, but maybe it's not present in the actual database. 

Alternatively, maybe the 'directors' table's 'director_name' column has entries. Let's try to see.

<schema_linking>
{
  "movies": ["movie_id", "director_id"],
  "directors": ["user_id", "director_id", "director_name"]
}
</schema_linking>
<exec_result>
Schema check passed. All column exists.
</exec_result>

Step 2: Check if the director_id in movies is valid. Let's write a SQL query to count the movies per director_id.

<exec_sql>
SELECT "director_id", COUNT(*) AS movie_count
FROM "movies"
GROUP BY "director_id"
ORDER BY movie_count DESC
LIMIT 5;
</exec_sql>
<exec_result>
director_id,movie_count
524073,746
18991,253
35368,188
34989,179
47738,166

</exec_result>

The result shows that director_id 524073 has the highest count of 746 movies. Therefore, the director with the most movies is the one with ID 524073. 

Step 3: Final schema changed since we only needed the movies table. 

<schema_linking>
{
  "movies": ["movie_id", "director_id"]
}
</schema_linking>
<exec_result>
Schema check passed. All column exists.
</exec_result>

The final SQL should select the director_id with the maximum count.

<exec_sql>
SELECT "director_id" 
FROM "movies" 
GROUP BY "director_id" 
ORDER BY COUNT(*) DESC 
LIMIT 1;
</exec_sql>
<exec_result>
director_id
524073

</exec_result>

This query returns the director_id 524073 as the director who made the most movies. 
</think>

<answer>
SELECT "director_id" 
FROM "movies" 
GROUP BY "director_id" 
ORDER BY COUNT(*) DESC 
LIMIT 1;
</answer>

Now it's time for you to answer by following the format of the example.
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
            "prompt": [
            {
                "role": "system",
                "content": "You are a helpful assistant."
            },                
            {
                "role": "user",
                "content": user_prompt
            }],
            "ability": "math",
            "reward_model": {
                "style": "rule",
                "ground_truth": {"sqlite_path": example["sqlite_path"], "example_id": example["example_id"], "gold_sql": example["answer"]}
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