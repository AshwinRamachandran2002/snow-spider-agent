import os
import pandas as pd
import snowflake.connector
import json
import logging
import math
from google.cloud import bigquery
from google.oauth2 import service_account
import sqlite3
import re

def extract_all_blocks(main_content, code_format):
    sql_blocks = []
    start = 0
    
    while True:

        sql_query_start = main_content.find(f"```{code_format}", start)
        if sql_query_start == -1:
            break
        

        sql_query_end = main_content.find("```", sql_query_start + len(f"```{code_format}"))
        if sql_query_end == -1:
            break 

        sql_block = main_content[sql_query_start + len(f"```{code_format}"):sql_query_end].strip()
        sql_blocks.append(sql_block)

        start = sql_query_end + len("```")
    
    return sql_blocks

def hard_cut(str_e, length=0):
    if length:
        if len(str_e) > length:
            str_e = str_e[:int(length)]+"\n"
    return str_e

def get_values_from_table(csv_data_str):
    return '\n'.join(csv_data_str.split('\n')[1:])

def search_file(directory, target_file):
    result = []
    for root, dirs, files in os.walk(directory):
        if target_file in files:
            result.append(os.path.join(root, target_file))
    return result

def execute_sql_api(sql_query, save_path=None, api="snowflake", max_len=30000, sqlite_path=None):
    if api == "snowflake":
        # Load Snowflake credentials
        snowflake_credential = json.load(open("./snowflake_credential.json"))
        # Define the SQL query
        # Execute the SQL query
        with snowflake.connector.connect(**snowflake_credential) as conn:
            with conn.cursor() as cursor:
                try:
                    cursor.execute(sql_query)
                    # Fetch the results
                    results = cursor.fetchall()
                    results = results[:max_len] if len(results) > max_len else results
                    columns = [desc[0] for desc in cursor.description]
                    df = pd.DataFrame(results, columns=columns)

                    # Check if the result is empty
                    if df.empty:
                        # print("No data found for the specified query.")
                        return "No data found for the specified query.\n"
                    else:
                        # Save or print the results based on the is_save flag
                        if save_path:
                            try:
                                df.to_csv(f"{save_path}", index=False)
                                # print(f"Results saved to {save_path}")
                                return 0
                            except Exception as e:
                                print(e)
                        else:
                            return hard_cut(df.to_csv(index=False), max_len)
                except Exception as e:
                    # print("Error occurred: ", str(e))
                    return e
    elif api == "bigquery":
        bigquery_credential = service_account.Credentials.from_service_account_file("./bigquery_credential.json")
        client = bigquery.Client(credentials=bigquery_credential, project=bigquery_credential.project_id)
        try:
            query_job = client.query(sql_query)
            result_iterator = query_job.result()
            rows = []
            current_len = 0
            for row in result_iterator:
                if current_len > max_len:
                    break
                current_len += len(str(dict(row)))
                rows.append(dict(row))
            df = pd.DataFrame(rows)
            # Check if the result is empty
            if df.empty:
                # print("No data found for the specified query.")
                return "No data found for the specified query.\n"
            else:
                # Save or print the results based on the is_save flag
                if save_path:
                    df.to_csv(f"{save_path}", index=False)
                    # print(f"Results saved to {save_path}")
                    return 0
                else:
                    return hard_cut(df.to_csv(index=False), max_len)
        except Exception as e:
            # print("Error occurred: ", str(e))
            return e
    elif api == "sqlite":
        conn = sqlite3.connect(sqlite_path)
        try:
            cursor = conn.cursor()
                        
            cursor.execute(sql_query)
            # Fetch the results
            results = cursor.fetchall()
            results = results[:max_len] if len(results) > max_len else results
            columns = [desc[0] for desc in cursor.description]
            df = pd.DataFrame(results, columns=columns)

            # Check if the result is empty
            if df.empty:
                # print("No data found for the specified query.")
                return "No data found for the specified query.\n"
            else:
                # Save or print the results based on the is_save flag
                if save_path:
                    try:
                        df.to_csv(f"{save_path}", index=False)
                        # print(f"Results saved to {save_path}")
                        return 0
                    except Exception as e:
                        print(e)
                else:
                    return hard_cut(df.to_csv(index=False), max_len)
        except Exception as e:
            # print("Error occurred: ", str(e))
            return e
        finally:
            cursor.close()  # Close the cursor manually
            conn.close()    # Close the connection manually
    else:
        raise NotImplementedError("Unsupported API")

def get_longest(sql_list):
    sql_list_len = [len(i) for i in sql_list]
    sql_list_len_index = sql_list_len.index(max(sql_list_len))
    return sql_list[sql_list_len_index]

def get_shortest(sql_list):
    sql_list_len = [len(i) for i in sql_list]
    sql_list_len_index = sql_list_len.index(min(sql_list_len))
    return sql_list[sql_list_len_index]

def initialize_logger(log_path):
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    file_handler = logging.FileHandler(log_path, mode='w')
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
    file_handler.setFormatter(formatter)
    logger.handlers.clear()
    logger.addHandler(file_handler)
    return logger

def extract_between(file_path, start_str, end_str):
    with open(file_path, 'r', encoding='utf-8') as file:
        content = file.read()
        if not content:
            pass
    
    results = []
    start_index = 0

    while True:
        start_index = content.find(start_str, start_index)
        if start_index == -1:
            break
        start_index += len(start_str)
        end_index = content.find(end_str, start_index)
        if end_index == -1:
            break
        results.append(content[start_index:end_index].strip())
        start_index = end_index + len(end_str)
    
    return results


def compare_pandas_table(pred, gold, condition_cols=[], ignore_order=False):
    """_summary_

    Args:
        pred (Dataframe): _description_
        gold (Dataframe): _description_
        condition_cols (list, optional): _description_. Defaults to [].
        ignore_order (bool, optional): _description_. Defaults to True.

    """
    # print('condition_cols', condition_cols)
    
    tolerance = 0.01

    def vectors_match(v1, v2, tol=tolerance, ignore_order_=False):
        if ignore_order_:
            v1, v2 = (sorted(v1, key=lambda x: (x is None, str(x), isinstance(x, (int, float)))),
                    sorted(v2, key=lambda x: (x is None, str(x), isinstance(x, (int, float)))))
        if len(v1) != len(v2):
            return False
        for a, b in zip(v1, v2):
            if pd.isna(a) and pd.isna(b):
                continue
            elif isinstance(a, (int, float)) and isinstance(b, (int, float)):
                if not math.isclose(float(a), float(b), abs_tol=tol):
                    return False
            elif a != b:
                return False
        return True
    
    if condition_cols != []:
        gold_cols = gold.iloc[:, condition_cols]
    else:
        gold_cols = gold
    pred_cols = pred

    t_gold_list = gold_cols.transpose().values.tolist()
    t_pred_list = pred_cols.transpose().values.tolist()
    score = 1
    for _, gold in enumerate(t_gold_list):
        if not any(vectors_match(gold, pred, ignore_order_=ignore_order) for pred in t_pred_list):
            score = 0
        else:
            for j, pred in enumerate(t_pred_list):
                if vectors_match(gold, pred, ignore_order_=ignore_order):
                    break

    return score

def clear_description(table_info):
    return re.sub(r'OPTIONS\(description=.*?\)', '', table_info, flags=re.DOTALL)

def get_table_info(test_path, sql_data, api):
    table_info_txt = ["prompts.txt"]      
    table_info = ''
    for txt in table_info_txt:
        txt_path = search_file(os.path.join(test_path, sql_data), txt)
        for path in txt_path:
            with open(path) as f:
                table_info += f.read()
    if api == "bigquery":
        if len(table_info) > 200000:
            table_info = clear_description(table_info)
    return table_info

def get_api_name(sql_data):
    if sql_data.startswith("sf"):
        return "snowflake"
    elif sql_data.startswith("local"):
        return "sqlite"
    elif sql_data.startswith("bq") or sql_data.startswith("ga"):
        return "bigquery"
    else:
        raise NotImplementedError("Invalid file name.")

def remove_digits(s):
    return re.sub(r'\d', '', s)

def is_file(filepath, suffix):
    return os.path.isfile(filepath) and filepath.lower().endswith(suffix)

def matching_at_same_position(s1, s2):
    min_length = min(len(s1), len(s2))
    matches = [s1[i] for i in range(min_length) if s1[i] == s2[i]]
    return "".join(matches)

def get_dictionary(args):
    json_path = os.path.join(args.test_path, f"spider2-{args.task}.jsonl")
    task_dict = {}
    with open(json_path) as f:
        for line in f:
            line_js = json.loads(line)
            if args.task == "snow":
                task_dict[line_js['instance_id']] = line_js['instruction']
            elif args.task == "lite":
                task_dict[line_js['instance_id']] = line_js['question']

    dictionaries = [entry for entry in os.listdir(args.test_path) if os.path.isdir(os.path.join(args.test_path, entry))]
    return dictionaries, task_dict

def get_sqlite_path(args, sql_data):
    sql_data_path = os.path.join(args.test_path, sql_data)
    sqlite_path = None
    for sqlite in os.listdir(sql_data_path):
        if sqlite.endswith(".sqlite"):
            sqlite_path = os.path.join(sql_data_path, sqlite)
    return sqlite_path