import os
import json
from openai import OpenAI
from tqdm import tqdm
import logging
import argparse
import glob
from openai import AzureOpenAI
from utils import extract_all_blocks, hard_cut, get_values_from_table, search_file, execute_sql_api, get_cte_info, initialize_logger, extract_between, compare_pandas_table
from agent import execute_sql, self_correct, format_answer, preparation, self_refine
import numpy as np
import pandas as pd
from io import StringIO
from model import GPTChat, modelChat
from prompt import Prompts
import multiprocessing

def execute(task, table_info, args, save_path, log_path, sql_save_path, search_directory, prompt_all, chat_session, chat_session4o, response_csv, api="snowflake", sqlite_path=None):
    
    # search_directory = args.test_path +  '/' + sql_data

    # rerun for empty results
    if args.rerun:
        if os.path.exists(os.path.join(search_directory, save_path)):
            return
        else:
            print("Rerun")
    # if log.log exists, pass
    elif not args.overwrite_results and os.path.exists(os.path.join(search_directory, log_path)):
        return
    # overwrite
    self_files = glob.glob(os.path.join(search_directory, f'*{save_path}*'))
    for self_file in self_files:
        os.remove(self_file)

    # log
    log_file_path = os.path.join(search_directory, log_path)
    logger = initialize_logger(log_file_path)

    table_struct = table_info[table_info.find("({database name: {schema name: {table name}}}):"):]


    # preparation
    LIMIT = 10
    prompt = "Task: " + task + "\n"
    pre_info, response_pre_txt, LIMIT, chat_session4o = preparation(prompt, LIMIT, prompt_all, table_struct, logger, chat_session4o, api=api, sqlite_path=sqlite_path)
        # chat_session4o.init_messages()
    print(f"len(pre_info): {len(pre_info)}, chat_session.get_message_len(): {chat_session.get_message_len()}")
    print(f"len(pre_info): {len(pre_info)}, chat_session4o.get_message_len(): {chat_session4o.get_message_len()}")
    if LIMIT <= 0:
        print("Inadequate preparation, skip")
        return
    

    # answer
    self_refine(args, logger, task, prompt_all, response_csv, search_directory, save_path, sql_save_path, table_struct, table_info, response_pre_txt, pre_info, chat_session, api=api, sqlite_path=sqlite_path)

def main(args):

    prompt_all = Prompts()

    # read file
    # json_path = search_file(search_directory, target_json)[0]

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

    if "gpt" in args.model or "o1" in args.model:
        chat_session = GPTChat(args.azure, args.model)
        chat_session4o = GPTChat(args.azure, args.understanding_model)
    else:
        from transformers import AutoModelForCausalLM, AutoTokenizer
        model = AutoModelForCausalLM.from_pretrained(
            args.model,
            torch_dtype="auto",
            device_map="auto"
        )
        tokenizer = AutoTokenizer.from_pretrained(args.model)
        chat_session = modelChat(model, tokenizer)


    for sql_data in tqdm(dictionaries):
        chat_session.init_messages()
        chat_session4o.init_messages()

        
        table_info_txt = ["prompts.txt"]
        target_json = "result.json"
        
        table_info = ''
        for txt in table_info_txt:
            txt_path = search_file(os.path.join(args.test_path, sql_data), txt)
            for path in txt_path:
                with open(path) as f:
                    table_info += f.read()
        task = task_dict[sql_data]
        search_directory = os.path.join(args.output_path, sql_data)

        print(sql_data)
        sqlite_path = None
        if sql_data.startswith("sf"):
            api = "snowflake"
        elif sql_data.startswith("local"):
            api = "sqlite"
            sql_data_path = os.path.join(args.test_path, sql_data)
            for sqlite in os.listdir(sql_data_path):
                if sqlite.endswith(".sqlite"):
                    sqlite_path = os.path.join(sql_data_path, sqlite)
        elif sql_data.startswith("bq") or sql_data.startswith("ga"):
            api = "bigquery"
        else:
            print("Invalid file name, skip.\n")
            continue

        num_processes = args.num_processes

        sql_paths = {}
        processes = []
        save_path = "result.csv"
        sql_save_path = "result.sql"
        log_path = "log.log"

        complete_save_path = os.path.join(search_directory, save_path)
        complete_sql_save_path = os.path.join(search_directory, sql_save_path)
        complete_vote_log_path = os.path.join(search_directory, "vote.log")

        if not args.overwrite_results and os.path.exists(complete_save_path):
            continue
        if not os.path.exists(search_directory):
            os.makedirs(search_directory)

        # format
        response_csv, chat_session4o = format_answer(prompt_all, table_info, task, chat_session4o)

        for i in range(num_processes):

            save_pathi = str(i) + save_path
            log_pathi = str(i) + log_path
            sql_save_pathi = str(i) + sql_save_path
            sql_paths[sql_save_pathi] = save_pathi
            process = multiprocessing.Process(target=execute, args=(task, table_info, args, save_pathi, log_pathi, sql_save_pathi, search_directory, prompt_all, chat_session, chat_session4o, response_csv, api, sqlite_path))
            processes.append(process)
            process.start()

        for process in processes:
            process.join()

        if not args.overwrite_results and os.path.exists(complete_save_path):
            continue

        pre_info = 'Based on some observations on the database:\n'
        prompt = f"The task is: {task}. Here are some candidate sqls and answers: \n"
        count = 0

        # filter answer
        result = {}
        all_values = []
        for v in sql_paths.values():
            if os.path.exists(os.path.join(search_directory, v)):
                all_values.append(os.path.join(search_directory, v))
        if len(all_values) > 1:
            for key, value in sql_paths.items():
                complete_value = os.path.join(search_directory, value)
                if os.path.exists(complete_value):
                    if any(v != complete_value and compare_pandas_table(pd.read_csv(v), pd.read_csv(complete_value)) for v in all_values):
                        result[key] = value
        if result:
            sql_paths = result


        for sql, csv in sql_paths.items():
            sql_path = os.path.join(search_directory, sql)
            csv_path = os.path.join(search_directory, csv)
            logfile_path = os.path.join(search_directory, csv[0] + log_path)
            try:
                pre_info += extract_between(logfile_path, "Begin Exploring Related Columns\n", "End Exploring Related Columns\n")[0]
            except Exception as e:
                print([logfile_path, e])
            if os.path.exists(sql_path):
                sql_path_exist = sql_path
                csv_path_exist = csv_path
                count += 1
                prompt += sql + "\n"
                with open(sql_path) as f:
                    prompt += f.read()
                prompt += csv + "\n"
                with open(csv_path) as f:
                    prompt += hard_cut(f.read(), 5000)

        if count == 0:
            print("Empty\n")
            continue
        elif count == 1:
            os.rename(sql_path_exist, complete_sql_save_path)
            os.rename(csv_path_exist, complete_save_path)
        else:
            compare_pandas_table
            prompt += "Compare the SQL and results of each answer and choose one SQL as the correct answer and tell me the reason. Output the name of sql in ```plain\nxxx.sql``` format. You should not ingnore 'plain'.\n"
            # prompt += "Ensure that float values are rounded to 4 decimal places.\n"
            response = chat_session.get_model_response(hard_cut(pre_info, 150000) + prompt, "plain")
            if not response or not isinstance(response, list):
                print(response)
                continue
            with open(os.path.join(search_directory, response[0])) as f:
                selected_sql = f.read()
            if execute_sql_api(selected_sql, complete_save_path, api=api) == 0:
                with open(complete_sql_save_path, "w") as f:
                    f.write(selected_sql)
                with open(complete_vote_log_path, "w") as f:
                    f.write(chat_session.messages[-1]['content'])


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--task', type=str, default="snow")
    parser.add_argument('--test_path', type=str, default="examples")
    parser.add_argument('--output_path', type=str, default="output/gpt-4o-test1-log")
    parser.add_argument('--model', type=str, default="gpt-4o")
    parser.add_argument('--understanding_model', type=str, default="gpt-4o")
    parser.add_argument('--overwrite_results', action="store_true")
    parser.add_argument('--azure', action="store_true")
    parser.add_argument('--max_iter', type=int, default=10)
    parser.add_argument('--temperature', type=float, default=1)
    parser.add_argument('--num_processes', type=int, default=3)
    parser.add_argument('--save_all_results', action="store_true")
    parser.add_argument('--model_vote', action="store_true")
    parser.add_argument('--rerun', action="store_true")
    args = parser.parse_args()
    main(args)