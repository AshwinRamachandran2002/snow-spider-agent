import os
import json
from openai import OpenAI
from tqdm import tqdm
import logging
import argparse
import glob
from openai import AzureOpenAI
from utils import extract_all_blocks, hard_cut, get_values_from_table, search_file, get_cte_info, initialize_logger
from agent import execute_sql, self_correct, format_answer, preparation, self_refine
import numpy as np
import pandas as pd
from io import StringIO
from model import GPTChat, modelChat
from prompt import Prompts

def main(args):

    prompt_all = Prompts()
    table_info_txt = ["prompts.txt"]
    target_json = "result.json"
    
    save_path = "result.csv"
    sql_save_path = "result.sql"
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

        
        # logger = initialize_logger()

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
        
        task = task_dict[sql_data]
        # search_directory = args.test_path +  '/' + sql_data
        search_directory = os.path.join(args.output_path, sql_data)
        if not os.path.exists(search_directory):
            os.makedirs(search_directory)

        # rerun for empty results
        if args.rerun:
            if os.path.exists(os.path.join(search_directory, save_path)):
                continue
            else:
                print("Rerun")
        # if log.log exists, pass
        elif not args.overwrite_results and os.path.exists(os.path.join(search_directory, "log.log")):
            continue
        
        # if "result_s.csv" in os.listdir(search_directory):
        #     continue
        
        # overwrite
        self_files = glob.glob(os.path.join(search_directory, f'*{save_path}*'))
        for self_file in self_files:
            os.remove(self_file)

        # log
        log_file_path = os.path.join(search_directory, "log.log")
        # file_handler = logging.FileHandler(log_file_path, mode='w')
        # file_handler.setLevel(logging.INFO)
        # formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
        # file_handler.setFormatter(formatter)
        # logger.addHandler(file_handler)
        logger = initialize_logger(log_file_path)

        table_info = ''
        for txt in table_info_txt:
            txt_path = search_file(os.path.join(args.test_path, sql_data), txt)
            for path in txt_path:
                with open(path) as f:
                    table_info += f.read()
        table_struct = table_info[table_info.find("({project name: {database name: {table name}}}):"):]
        # format
        response_csv, chat_session4o = format_answer(prompt_all, table_info, task, chat_session4o)

        # preparation
        LIMIT = 10
        prompt = "Task: " + task + "\n"
        pre_info, response_pre_txt, LIMIT, chat_session4o = preparation(prompt, LIMIT, prompt_all, table_struct, logger, chat_session4o, api=api, sqlite_path=sqlite_path)
            # chat_session4o.init_messages()
        print(f"len(pre_info): {len(pre_info)}, chat_session.get_message_len(): {chat_session.get_message_len()}")
        print(f"len(pre_info): {len(pre_info)}, chat_session4o.get_message_len(): {chat_session4o.get_message_len()}")
        if LIMIT <= 0:
            print("Inadequate preparation, skip")
            continue
        

        # answer
        self_refine(args, logger, task, prompt_all, response_csv, search_directory, save_path, sql_save_path, table_struct, table_info, response_pre_txt, pre_info, chat_session, api=api, sqlite_path=sqlite_path)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    # args.test_path = "output/test_with_sql"
    # args.test_path = "output/test"
    # args.test_path = "output/o1-preview-test1"
    parser.add_argument('--task', type=str, default="snow")
    parser.add_argument('--test_path', type=str, default="examples")
    parser.add_argument('--output_path', type=str, default="output/gpt-4o-test1-log")
    parser.add_argument('--model', type=str, default="gpt-4o")
    parser.add_argument('--understanding_model', type=str, default="gpt-4o")
    parser.add_argument('--overwrite_results', action="store_true")
    parser.add_argument('--azure', action="store_true")
    parser.add_argument('--max_iter', type=int, default=10)
    parser.add_argument('--temperature', type=float, default=1)
    parser.add_argument('--save_all_results', action="store_true")
    parser.add_argument('--model_vote', action="store_true")
    parser.add_argument('--rerun', action="store_true")
    args = parser.parse_args()
    main(args)
    
    # with Pool(processes=2) as pool:
    #     pool.apply_async(main, args=(args,))

    #     pool.close()
    #     pool.join()