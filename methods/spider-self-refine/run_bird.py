import os
import json
from openai import OpenAI
from tqdm import tqdm
import logging
import argparse
import glob
from openai import AzureOpenAI
from utils import extract_all_blocks, hard_cut, get_values_from_table, search_file, get_table_info, initialize_logger, get_api_name
from agent import execute_sql, self_correct, format_answer, preparation, self_refine, schema_linking
import numpy as np
import pandas as pd
from io import StringIO
from chat import GPTChat, modelChat
from prompt import Prompts
import concurrent

def process_task(sql_data, args, save_path):
    if args.model:
        chat_session = GPTChat(args.azure, args.model, temperature=args.temperature)
        chat_session4o = GPTChat(args.azure, args.understanding_model, temperature=args.temperature)

    ex_id = sql_data["example_id"]

    api = get_api_name(sql_data["example_id"])
    sqlite_path = os.path.join("../RL-fine-tuning/", sql_data['sqlite_path'])

    task = sql_data['question']
    search_directory = os.path.join(args.output_path, sql_data["example_id"])
    if not os.path.exists(search_directory):
        os.makedirs(search_directory)

    # 检查是否需要重新运行
    if args.rerun:
        if os.path.exists(os.path.join(search_directory, sql_save_path)) and os.path.exists(os.path.join(search_directory, save_path)):
            return
    elif not args.overwrite_results and os.path.exists(os.path.join(search_directory, "log.log")):
        return

    # 删除已有结果文件
    self_files = glob.glob(os.path.join(search_directory, f'*{save_path}*'))
    for self_file in self_files:
        os.remove(self_file)
    print(ex_id)
    # 初始化日志
    log_file_path = os.path.join(search_directory, "log.log")
    logger = initialize_logger(log_file_path)

    table_info = sql_data['input']
    table_struct = table_info[table_info.find("The table structure information is "):table_info.find("\n\nExternal knowledge that might be helpful")]

    # 格式化回答
    # response_csv, chat_session4o = format_answer(prompt_all, table_info, task, chat_session4o)
    # logger.info("[Generated Format]\n" + chat_session4o.messages[-1]['content'] + "\n[Generated Format]")

    # if chat_session4o.get_message_len() > 300000:
    #     print("Too long, skip")
    #     return

    # 预处理
    LIMIT = 10
    prompt = "Task: " + task + "\n"
    pre_info, response_pre_txt, LIMIT, chat_session4o = preparation(
        prompt, LIMIT, prompt_all, table_struct, logger, chat_session4o, ex_id, search_directory, api=api, sqlite_path=sqlite_path, answer=sql_data['answer']
    )
    if pre_info == "err during correction":
        return
    # print(f"len(pre_info): {len(pre_info)}, chat_session.get_message_len(): {chat_session.get_message_len()}")
    # print(f"len(pre_info): {len(pre_info)}, chat_session4o.get_message_len(): {chat_session4o.get_message_len()}")

    if LIMIT <= 0:
        print(f"{ex_id}: Inadequate preparation, skip")
        return

    # 生成最终答案
    # self_refine(
    #     args, logger, task, prompt_all, response_csv, search_directory,
    #     save_path, sql_save_path, table_struct, table_info, response_pre_txt, pre_info, chat_session, api=api, sqlite_path=sqlite_path
    # )

# 使用 ThreadPoolExecutor 进行并行处理
def run_parallel_processing(task_dict, args, save_path, num_workers=10):
    with concurrent.futures.ThreadPoolExecutor(max_workers=num_workers) as executor:
        list(tqdm(executor.map(lambda sql_data: process_task(sql_data, args, save_path), task_dict), total=len(task_dict)))


def main(args):
    # 调用并行执行
    run_parallel_processing(task_dict, args, save_path)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--task', type=str, default="snow")
    parser.add_argument('--test_path', type=str, default="bird_train_data_add_ev.json")
    parser.add_argument('--output_path', type=str, default="output/bird_aug")
    parser.add_argument('--model', type=str, default="o1-mini")
    parser.add_argument('--model_local', type=str, default=None)
    parser.add_argument('--understanding_model', type=str, default="o1-mini")
    parser.add_argument('--overwrite_results', action="store_true")
    parser.add_argument('--azure', action="store_true")
    parser.add_argument('--max_iter', type=int, default=2)
    parser.add_argument('--temperature', type=float, default=1)
    parser.add_argument('--save_all_results', action="store_true")
    parser.add_argument('--rerun', action="store_true")
    parser.add_argument('--schema_linking_api', type=str, default=None)
    args = parser.parse_args()
    prompt_all = Prompts()
    
    save_path = "result.csv"
    sql_save_path = "result.sql"

    json_path = args.test_path
    with open(json_path) as f:
        task_dict = json.load(f)

    main(args)