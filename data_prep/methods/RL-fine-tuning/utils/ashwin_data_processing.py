import argparse
from tqdm import tqdm
from utils.utils import get_api_name, get_table_info, remove_digits, search_file, execute_sql_with_timeout, split_cte, SqlEnv
from utils.reconstruct_data import get_sqlite_data_bird, get_sqlite_data_spider
import csv
import os
import json
import random
import sys
import pandas as pd
import concurrent
from utils.table_extract_snowflake import fetch_table_metadata as fetch_table_metadata_snowflake
from utils.table_extract_sqlite import fetch_table_metadata as fetch_table_metadata_sqlite
from utils.table_extract_bigquery import fetch_table_metadata as fetch_table_metadata_bigquery


csv.field_size_limit(sys.maxsize)

def get_dict(task, pth):
    dictionaries = [entry for entry in os.listdir(pth) if os.path.isdir(os.path.join(pth, entry))]
    json_path = os.path.join(pth, f"spider2-{task}.jsonl")
    task_dict = {}
    with open(json_path) as f:
        for line in f:
            line_js = json.loads(line)
            if task == "snow":
                task_dict[line_js['instance_id']] = line_js['instruction']
            if task == "lite":
                task_dict[line_js['instance_id']] = line_js['question']
    return dictionaries, task_dict

def get_spider2_data_dict(task_dict_snow, task_dict_lite, combined_list, args, task="train"):
    dict_list = []
    for sql_id in tqdm(combined_list):
        sql_dict = {}
        if not sql_id.endswith("jsonl"):
            sql_dict["example_id"] = sql_id
            sql_dict["data_source"] = "Spider2.0"
            if sql_id.startswith("sf"):
                sql_dict["question"] = task_dict_snow[sql_id]
                if task == "train":
                    with open(os.path.join(args.snow_gold_sql_path_training, sql_id + ".sql")) as f:
                        sql_dict["answer"] = f.read()
                answer = fetch_table_metadata_snowflake(sql_id, main_dir=args.data_path)
                if isinstance(answer, str):
                    continue
                sql_dict["input"] = answer
            else:
                sql_dict["question"] = task_dict_lite[sql_id]
                if task == "train":
                    with open(os.path.join(args.lite_gold_sql_path_training, sql_id + ".sql")) as f:
                        sql_dict["answer"] = f.read()
                if sql_id.startswith("local"):
                    id_path = os.path.join(args.lite_path, sql_id)
                    for file in os.listdir(id_path):
                        if file.endswith(".sqlite"):
                            sql_dict["sqlite_path"] = os.path.join(id_path, file)
                            assert sql_dict["sqlite_path"]
                if "local" in sql_id :
                    answer = fetch_table_metadata_sqlite(sql_id, main_dir=args.data_path, sqlite_path=sql_dict["sqlite_path"])
                    if isinstance(answer, str):
                        continue
                    sql_dict["input"] = answer
                elif "bq" in sql_id or "ga" in sql_id:
                    answer = fetch_table_metadata_bigquery(sql_id, main_dir=args.data_path)
                    if isinstance(answer, str):
                        continue
                    sql_dict["input"] = answer
                else:
                    raise ValueError(f"Unknown task: {sql_id}")
            dict_list.append(sql_dict)
    return dict_list

def split_Spider2(task_dict_snow, task_dict_lite, args):
    snow_gold_sql_ids = [i.replace(".sql", "") for i in os.listdir(args.snow_gold_sql_path)]
    snow_all_ids = [i for i in os.listdir(args.snow_path)]
    lite_gold_sql_ids = [i.replace(".sql", "") for i in os.listdir(args.lite_gold_sql_path)]
    lite_all_ids = [i for i in os.listdir(args.lite_path)]
    gold_list = list(set(snow_gold_sql_ids) | set(lite_gold_sql_ids))
    gold_sampled = random.sample(gold_list, 199)

    snow_easier_ids = ['sf014', 'sf044', 'sf_bq005', 'sf_bq006', 'sf_bq010', 'sf_bq017', 'sf_bq018', 'sf_bq021', 'sf_bq025', 'sf_bq032', 'sf_bq033', 'sf_bq034', 'sf_bq035', 'sf_bq042', 'sf_bq056', 'sf_bq059', 'sf_bq060', 'sf_bq061', 'sf_bq066', 'sf_bq076', 'sf_bq077', 'sf_bq078', 'sf_bq081', 'sf_bq085', 'sf_bq088', 'sf_bq090', 'sf_bq091', 'sf_bq096', 'sf_bq097', 'sf_bq103', 'sf_bq109', 'sf_bq113', 'sf_bq115', 'sf_bq121', 'sf_bq126', 'sf_bq130', 'sf_bq143', 'sf_bq151', 'sf_bq158', 'sf_bq161', 'sf_bq171', 'sf_bq172', 'sf_bq176', 'sf_bq210', 'sf_bq211', 'sf_bq213', 'sf_bq214', 'sf_bq216', 'sf_bq218', 'sf_bq219', 'sf_bq223', 'sf_bq224', 'sf_bq227', 'sf_bq228', 'sf_bq232', 'sf_bq252', 'sf_bq255', 'sf_bq264', 'sf_bq270', 'sf_bq279', 'sf_bq280', 'sf_bq281', 'sf_bq282', 'sf_bq284', 'sf_bq285', 'sf_bq286', 'sf_bq289', 'sf_bq300', 'sf_bq302', 'sf_bq303', 'sf_bq308', 'sf_bq309', 'sf_bq310', 'sf_bq321', 'sf_bq327', 'sf_bq328', 'sf_bq330', 'sf_bq334', 'sf_bq341', 'sf_bq345', 'sf_bq349', 'sf_bq350', 'sf_bq352', 'sf_bq355', 'sf_bq357', 'sf_bq359', 'sf_bq361', 'sf_bq362', 'sf_bq375', 'sf_bq377', 'sf_bq379', 'sf_bq389', 'sf_bq392', 'sf_bq394', 'sf_bq396', 'sf_bq399', 'sf_bq407', 'sf_bq414', 'sf_bq419', 'sf_bq444', 'sf_ga001', 'sf_ga002', 'sf_ga003', 'sf_ga004', 'sf_ga010', 'sf_ga020', 'sf_local008', 'sf_local009', 'sf_local019', 'sf_local021', 'sf_local022', 'sf_local023', 'sf_local029', 'sf_local031', 'sf_local038', 'sf_local039', 'sf_local041', 'sf_local054', 'sf_local056', 'sf_local058', 'sf_local065', 'sf_local067', 'sf_local071', 'sf_local072', 'sf_local074', 'sf_local075', 'sf_local078', 'sf_local097', 'sf_local099', 'sf_local141', 'sf_local163', 'sf_local197', 'sf_local198', 'sf_local199', 'sf_local201', 'sf_local202', 'sf_local210', 'sf_local218', 'sf_local221', 'sf_local244', 'sf_local274', 'sf_local284', 'sf_local309', 'sf_local311', 'sf_local329']
    lite_easier_ids = ['bq002', 'bq009', 'bq010', 'bq018', 'bq021', 'bq025', 'bq032', 'bq034', 'bq035', 'bq042', 'bq060', 'bq061', 'bq066', 'bq076', 'bq077', 'bq078', 'bq085', 'bq090', 'bq097', 'bq105', 'bq109', 'bq113', 'bq115', 'bq123', 'bq126', 'bq130', 'bq161', 'bq172', 'bq204', 'bq228', 'bq232', 'bq235', 'bq279', 'bq280', 'bq281', 'bq282', 'bq284', 'bq285', 'bq286', 'bq300', 'bq301', 'bq302', 'bq303', 'bq310', 'bq327', 'bq328', 'bq330', 'bq352', 'bq355', 'bq357', 'bq362', 'bq374', 'bq389', 'bq392', 'bq394', 'bq396', 'bq414', 'ga001', 'ga002', 'ga003', 'ga004', 'ga007', 'ga010', 'ga011', 'ga017', 'ga025', 'local004', 'local017', 'local019', 'local022', 'local023', 'local029', 'local031', 'local038', 'local039', 'local041', 'local054', 'local056', 'local058', 'local059', 'local065', 'local071', 'local072', 'local074', 'local075', 'local078', 'local097', 'local099', 'local141', 'local152', 'local163', 'local195', 'local198', 'local199', 'local202', 'local210', 'local218', 'local221', 'local229', 'local284', 'local301', 'local309', 'local311', 'local329', 'sf001', 'sf014', 'sf044', 'sf_bq005', 'sf_bq017', 'sf_bq033', 'sf_bq056', 'sf_bq091', 'sf_bq158', 'sf_bq171', 'sf_bq176', 'sf_bq210', 'sf_bq211', 'sf_bq213', 'sf_bq214', 'sf_bq216', 'sf_bq219', 'sf_bq223', 'sf_bq224', 'sf_bq252', 'sf_bq255', 'sf_bq264', 'sf_bq289', 'sf_bq321', 'sf_bq334', 'sf_bq341', 'sf_bq345', 'sf_bq349', 'sf_bq359', 'sf_bq361', 'sf_bq375', 'sf_bq377', 'sf_bq444']
    easier_list = list(set(snow_easier_ids) | set(lite_easier_ids))
    easier_sampled = random.sample(easier_list, 199)

    combined_list = list(set(gold_sampled) | set(easier_sampled))
    print(f"Spider2.0 training data number: {len(combined_list)}")
    snow_test_list = list(set(snow_all_ids) - set(combined_list))
    snow_test_all_list = snow_all_ids
    lite_test_list = list(set(lite_all_ids) - set(combined_list))
    lite_test_all_list = lite_all_ids


    spider2_train_data = get_spider2_data_dict(task_dict_snow, task_dict_lite, combined_list, args, task="train")
    snow_test_data = get_spider2_data_dict(task_dict_snow, task_dict_lite, snow_test_list, args, task="test")
    snow_test_all_data = get_spider2_data_dict(task_dict_snow, task_dict_lite, snow_test_all_list, args, task="test")
    lite_test_data = get_spider2_data_dict(task_dict_snow, task_dict_lite, lite_test_list, args, task="test")
    lite_test_all_data = get_spider2_data_dict(task_dict_snow, task_dict_lite, lite_test_all_list, args, task="test")
    return spider2_train_data, snow_test_data, snow_test_all_data, lite_test_data, lite_test_all_data

def get_spider1_data_dict(args, json_paths, min_token_len=50):
    eg_count = 0
    dict_list = []
    if not os.path.exists(args.Spider_executed_results_path):
        os.mkdir(args.Spider_executed_results_path)
    for json_path in json_paths:
        data_type = json_path.split('.')[0].split('/')[-1]
        if data_type == "test":
            db_path = "data/Spider/spider_data/test_database"
        else:
            db_path = "data/Spider/spider_data/database"
        print(f"Processing Spider {data_type}")
        with open(json_path) as f:
            examples = json.load(f)
        # Define the function to process a single example
        def process_example(index_ex):
            i, ex = index_ex
            err1, err2 = 0, 0
            
            # Check if the token length exceeds the minimum threshold
            if len(ex["query_toks"]) > min_token_len:
                # Create a unique id based on the index
                id_name = f"local_Spider_{i:03d}" if i < 1000 else f"local_Spider_{i}"
                sqlite_path = os.path.join(db_path, ex["db_id"], ex["db_id"] + ".sqlite")
                if not os.path.exists(sqlite_path):
                    raise FileNotFoundError(f"File not exists: {sqlite_path}")
                
                # Build the sql_dict dictionary
                sql_dict = {
                    "data_source": "Spider1.0",
                    "example_id": id_name,
                    "question": ex["question"],
                    "answer": ex["query"],
                    "sqlite_path": sqlite_path,
                }
                
                # Retrieve table structure information and prompts
                table_names, prompts = get_sqlite_data_bird(sqlite_path)
                prompts += "The table structure information is [table name]: \n" + str(table_names) + "\n"
                sql_dict["input"] = prompts
                
                # Specify the output path for the executed results
                Spider_executed_results_id_path = os.path.join(args.Spider_executed_results_path, id_name + ".csv")
                results = execute_sql_with_timeout(sql_dict["answer"], Spider_executed_results_id_path, "sqlite", sqlite_path=sqlite_path)
                
                # Handle errors if the results are not as expected
                if results != 0:
                    if results == "No data found for the specified query.\n":
                        err1 += 1
                    print(results)
                    return None, err1, err2
                
                return sql_dict, err1, err2
            else:
                err2 += 1
                return None, err1, err2

        # Initialize a list to save successful examples and error counters
        
        total_err1 = 0
        total_err2 = 0

        # Use ThreadPoolExecutor for parallel processing
        with concurrent.futures.ThreadPoolExecutor(max_workers=224) as executor:
            # Submit each example to the executor with its unique index
            futures = {executor.submit(process_example, pair): pair for pair in enumerate(examples)}
            
            # Iterate over the results as they complete
            for future in tqdm(concurrent.futures.as_completed(futures), total=len(futures)):
                result, e1, e2 = future.result()
                total_err1 += e1
                total_err2 += e2
                if result is not None:
                    dict_list.append(result)
                    eg_count += 1

        print(f"Error 1: {total_err1}, Error 2: {total_err2}")
        print("Total examples: ", eg_count)
    return dict_list

def get_bird_data_dict(args, json_paths, min_token_len=50, timeout=600):
    eg_count = 0
    dict_list = []
    if not os.path.exists(args.BIRD_executed_results_path):
        os.mkdir(args.BIRD_executed_results_path)
    for json_path in json_paths:
        data_type = json_path.split('.')[0].split('/')[-1]
        db_path = f"data/BIRD/{data_type}/{data_type}_databases"
        print(f"Processing BIRD {data_type}")
        with open(json_path) as f:
            examples = json.load(f)
        def process_example(index_ex):
            """
            Process a single sample:
            - Check if the number of tokens in ex["SQL"] is greater than min_token_len.
            - Construct the sql_dict with data source, question, answer, and sqlite path.
            - If available, read additional external knowledge from the "database_description" folder.
            - Append the table structure information using get_sqlite_data_bird.
            - Execute the SQL using execute_sql_api.
            Returns the sql_dict if successful; otherwise, returns None.
            """
            i, ex = index_ex
            sql_dict = {}
            tokens = ex["SQL"].split()
            if len(tokens) > min_token_len:
                # Create a unique id_name using the sample index
                id_name = f"local_BIRD_{data_type}_{i:03d}" if i < 1000 else f"local_BIRD_{data_type}_{i}"
                sqlite_path = os.path.join(db_path, ex["db_id"], ex["db_id"] + ".sqlite")
                if not os.path.exists(sqlite_path):
                    raise FileNotFoundError(f"SQLite file does not exist: {sqlite_path}")
                sql_dict["data_source"] = "BIRD"
                sql_dict["example_id"] = id_name
                sql_dict["question"] = ex["question"]
                sql_dict["answer"] = ex["SQL"]
                sql_dict["sqlite_path"] = sqlite_path

                # Build the external knowledge if available
                external = ''
                desc_path = os.path.join(db_path, "database_description")
                if os.path.exists(desc_path):
                    external = 'Column description:\n'
                    for table_file in os.listdir(desc_path):
                        # Remove .csv suffix to obtain the table name
                        table_name = table_file.removesuffix(".csv")
                        with open(os.path.join(desc_path, table_file), errors="ignore") as f:
                            external += f"Table name: {table_name}\n"
                            external += f.read()
                    external += f"\nEvidence of the task: {ex['evidence']}"

                table_names, prompts = get_sqlite_data_bird(sqlite_path)
                prompts += "The table structure information is [table names]: \n" + str(table_names) + "\n"
                sql_dict["input"] = prompts + f"\nExternal knowledge that might be helpful:\n{external}\n"

                BIRD_executed_results_id_path = os.path.join(args.BIRD_executed_results_path, id_name + ".csv")
                results = sqlenv.execute_sql_with_timeout(sql_dict["answer"], BIRD_executed_results_id_path, "sqlite", sqlite_path=sqlite_path, timeout=timeout)
                if results != 0:
                    # If the SQL execution fails, skip this sample
                    return None
                return sql_dict
            else:
                return None

        # Parallel execution using ThreadPoolExecutor
        with concurrent.futures.ThreadPoolExecutor(max_workers=1024) as executor:
            # Use enumerate to assign a unique index to each sample
            futures = {executor.submit(process_example, pair): pair for pair in enumerate(examples)}
            for future in tqdm(concurrent.futures.as_completed(futures), total=len(futures)):
                res = None
                try:
                    # Set a timeout for each future's result retrieval (in seconds)
                    res = future.result(timeout=timeout)
                except concurrent.futures.TimeoutError:
                    print("Timeout occurred for one task.")
                    continue
                if res is not None:
                    dict_list.append(res)

        print("Total examples: ", len(dict_list))
    return dict_list

def save_json(file_name, new_data, mode="w"):
    file_path = f"data/{file_name}.json"
    if mode == "a":
        if os.path.exists(file_path) and os.stat(file_path).st_size > 0:
            with open(file_path, "r", encoding="utf-8") as f:
                data = json.load(f)
        else:
            data = []
        # Append new data
        data += new_data
        # Write back the updated JSON file
        with open(file_path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=4)
    elif mode == "w":
        with open(file_path, mode=mode, encoding="utf-8") as f:
            json.dump(new_data, f, ensure_ascii=False, indent=4)

def sample_json_data(json_path, sample_size=200, output_path=None):
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    df = pd.DataFrame(data)
    sample_size = min(sample_size, len(df))
    sampled_df = df.sample(n=sample_size, replace=False, random_state=42)
    if output_path:
        sampled_df.to_json(output_path, orient='records', force_ascii=False, indent=4)
    
    return sampled_df


def main(args):
    dictionaries_snow, task_dict_snow = get_dict("snow", args.snow_path)
    dictionaries_lite, task_dict_lite = get_dict("lite", args.lite_path)

    # spider2_train_data, snow_test_data, snow_test_all_data, lite_test_data, lite_test_all_data = split_Spider2(task_dict_snow, task_dict_lite, args)
    # save_json("spider2_train_data", spider2_train_data)
    # save_json("snow_test_data", snow_test_data)
    # save_json("snow_test_all_data", snow_test_all_data)
    # save_json("lite_test_data", lite_test_data)
    # save_json("lite_test_all_data", lite_test_all_data)

    # spider1_test_data = get_spider1_data_dict(args, ["data/Spider/spider_data/test.json"], 0)
    # save_json("spider1_test_data", spider1_test_data)

    # spider1_dev_data = get_spider1_data_dict(args, ["data/Spider/spider_data/dev.json"], 0)
    # save_json("spider1_dev_data", spider1_dev_data)

    bird_dev_data = get_bird_data_dict(args, ["data/BIRD/dev/dev.json"], 0)
    save_json("bird_dev_data", bird_dev_data)

    # spider1_train_data = get_spider1_data_dict(args, ["data/Spider/spider_data/train_spider.json", "data/Spider/spider_data/train_others.json"], 0)
    # bird_train_data = get_bird_data_dict(args, ["data/BIRD/train/train.json"], 0)
    # save_json("bird_train_data", bird_train_data)
    # save_json("spider1_bird_train_data", spider1_train_data + bird_train_data)
    


if __name__ == '__main__':
    random.seed(42)

    sqlenv = SqlEnv()
    parser = argparse.ArgumentParser()
    parser.add_argument('--snow_path', type=str, default="data/Spider2.0_snow")
    parser.add_argument('--lite_path', type=str, default="data/Spider2.0_lite")
    parser.add_argument('--snow_gold_sql_path', type=str, default="../../spider2-snow/evaluation_suite/gold/sql")
    parser.add_argument('--snow_gold_sql_path_training', type=str, default="data/Spider2.0_snow_gold_sql")
    parser.add_argument('--lite_gold_sql_path', type=str, default="../../spider2-lite/evaluation_suite/gold/sql")
    parser.add_argument('--lite_gold_sql_path_training', type=str, default="data/Spider2.0_lite_gold_sql")
    parser.add_argument('--Spider_executed_results_path', type=str, default="data/Spider_exec_results")
    parser.add_argument('--Spider2_aug_results_path', type=str, default="data/Spider2_aug_results")
    parser.add_argument('--gold_results_path', type=str, default="gold/gold_answer")
    parser.add_argument('--train_json_name', type=str, default="training_data")
    parser.add_argument('--train_aug_json_name', type=str, default="training_data_aug")
    parser.add_argument('--BIRD_executed_results_path', type=str, default="data/BIRD_exec_results")
    parser.add_argument('--model_api', type=str, default="o1-preview")
    parser.add_argument('--azure', action="store_true")
    parser.add_argument('--temperature', type=float, default=1)
    parser.add_argument('--txt_len_threshold', type=float, default=25000)
    parser.add_argument('--data_augmentaion', action="store_true")
    parser.add_argument('--schema_linking', action="store_true")
    parser.add_argument('--load_data', type=str, default=None)
    parser.add_argument('--data_path', type=str, default="./data")
    args = parser.parse_args()
    main(args)
