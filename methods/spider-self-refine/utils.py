import os
import pandas as pd
import snowflake.connector
import json
import logging
import math
from google.cloud import bigquery
from google.oauth2 import service_account
import sqlite3

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
        if len(str_e) > length and not str_e.startswith("Too long, hard cut"):
            str_e = "Too long, hard cut:\n" + str_e[:int(length)]+"\n"
    return str_e

def get_values_from_table(csv_data_str):
    return '\n'.join(csv_data_str.split('\n')[1:])

def search_file(directory, target_file):
    result = []
    for root, dirs, files in os.walk(directory):
        if target_file in files:
            result.append(os.path.join(root, target_file))
    return result

def execute_sql_api(sql_query, save_path=None, api="snowflake", max_len=10000, sqlite_path=None):
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
        raise NotImplementedError("Unsupported API\n")

def split_cte(with_block):
    i = 0
    length = len(with_block)
    cte_list = []

    while i < length:
        as_pos = with_block.find(" AS ", i)
        if as_pos == -1:
            break

        j = as_pos + 3 
        while j < length and with_block[j].isspace():
            j += 1
        
        if j >= length or with_block[j] != '(':
            i = j
            continue
        
        cte_name_part = with_block[:as_pos].rstrip() 
        comma_pos = cte_name_part.rfind(',')
        if comma_pos != -1:
            cte_name_part = cte_name_part[comma_pos+1:]
        cte_name = cte_name_part.strip()

        stack = []
        stack.append('(')
        start_sql_body = j + 1 
        j += 1

        while j < length and stack:
            if with_block[j] == '(':
                stack.append('(')
            elif with_block[j] == ')':
                stack.pop()
            j += 1

        cte_sql_body = with_block[start_sql_body : j-1].strip()

        cte_list.append((cte_name, cte_sql_body))
        i = j

    cte_lists = []
    for i in range(len(cte_list)):
        concat = ' AS (\n'.join(cte_list[i])
        cte_lists.append(concat)

    step_queries = []
    for i in range(1, len(cte_lists) + 1):
        current_with = "), ".join(cte_lists[:i]) + ")"
        cte_name = cte_list[i-1][0].strip("WITH ")
        step_queries.append(f"{current_with}\nSELECT * FROM {cte_name};")
        step_queries.append(f"{current_with}\nSELECT COUNT(*) AS total_rows FROM {cte_name};")

    return step_queries

def get_cte_info(ctes):
    cte_info = "Here are results for each step of the query:\n"
    for query in split_cte(ctes):
        cte_info += "Query:\n" + query + "Results:\n" + hard_cut(execute_sql_api(query), 1000)
    return cte_info

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
    
    tolerance = 1

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