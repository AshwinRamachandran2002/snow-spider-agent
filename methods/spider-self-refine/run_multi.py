import os
import json
from tqdm import tqdm
from tqdm.contrib.concurrent import process_map
import argparse
import glob
from utils import extract_all_blocks, hard_cut, get_values_from_table, search_file, get_table_info, initialize_logger, get_api_name
from agent import execute_sql, self_correct, format_answer, preparation, self_refine, schema_linking

from multiprocessing import Pool, Manager, Lock
from chat import GPTChat, modelChat
from prompt import Prompts


def process_folder(sql_data):
    prompt_all = Prompts()
    
    save_path = "result.csv"
    sql_save_path = "result.sql"

    json_path = os.path.join(args.test_path, f"spider2-{args.task}.jsonl")
    task_dict = {}
    with open(json_path) as f:
        for line in f:
            line_js = json.loads(line)
            if args.task == "snow":
                task_dict[line_js['instance_id']] = line_js['instruction']
            elif args.task == "lite":
                task_dict[line_js['instance_id']] = line_js['question']

    if args.model:
        chat_session = GPTChat(args.azure, args.model, temperature=args.temperature)
        chat_session4o = GPTChat(args.azure, args.understanding_model, temperature=args.temperature)

    if args.schema_linking_api:
        chat_session_sl = GPTChat(args.azure, args.schema_linking_api, temperature=args.temperature) 
        schema_linking(dictionaries, task_dict, args.test_path, chat_session_sl)
    
    if args.model_local:
        from transformers import AutoModelForCausalLM, AutoTokenizer
        model = AutoModelForCausalLM.from_pretrained(
            args.model_local,
            torch_dtype="auto",
            device_map="auto"
        )
        tokenizer = AutoTokenizer.from_pretrained(args.model_local)
        chat_session = modelChat(model, tokenizer, temperature=args.temperature)

        
    # logger = initialize_logger()

    print(sql_data)
    api = get_api_name(sql_data)
    sql_data_path = os.path.join(args.test_path, sql_data)
    sqlite_path = None
    for sqlite in os.listdir(sql_data_path):
        if sqlite.endswith(".sqlite"):
            sqlite_path = os.path.join(sql_data_path, sqlite)
    
    task = task_dict[sql_data]
    # search_directory = args.test_path +  '/' + sql_data
    search_directory = os.path.join(args.output_path, sql_data)
    if not os.path.exists(search_directory):
        os.makedirs(search_directory)

    # rerun for empty results
    if args.rerun:
        if os.path.exists(os.path.join(search_directory, save_path)):
            return
        else:
            print("Rerun")
    # if log.log exists, pass
    elif not args.overwrite_results and os.path.exists(os.path.join(search_directory, "log.log")):
        return
    
    # if "result_s.csv" in os.listdir(search_directory):
    #     continue
    
    # overwrite
    self_files = glob.glob(os.path.join(search_directory, f'*{save_path}*'))
    for self_file in self_files:
        os.remove(self_file)

    # log
    log_file_path = os.path.join(search_directory, "log.log")
    logger = initialize_logger(log_file_path)

    table_info = get_table_info(args.test_path, sql_data, api)
    table_struct = table_info[table_info.find("The table structure information is "):]
    # format
    response_csv, chat_session4o = format_answer(prompt_all, table_info, task, chat_session4o)
    if "context_length_exceeded" in str(response_csv):
        logger.info(response_csv)
        return
    if chat_session4o.get_message_len() > 300000:
        print("Too long, skip")
        return

    # preparation
    LIMIT = 10
    prompt = "Task: " + task + "\n"
    pre_info, response_pre_txt, LIMIT, chat_session4o = preparation(prompt, LIMIT, prompt_all, table_struct, logger, chat_session4o, api=api, sqlite_path=sqlite_path)
        # chat_session4o.init_messages()
    print(f"{sql_data}: len(pre_info): {len(pre_info)}, chat_session.get_message_len(): {chat_session.get_message_len()}")
    print(f"{sql_data}: len(pre_info): {len(pre_info)}, chat_session4o.get_message_len(): {chat_session4o.get_message_len()}")
    if LIMIT <= 0:
        print("Inadequate preparation, skip")
        return
    

    # answer
    self_refine(args, logger, task, prompt_all, response_csv, search_directory, save_path, sql_save_path, table_struct, table_info, response_pre_txt, pre_info, chat_session, api=api, sqlite_path=sqlite_path)


def worker(task_queue, result_queue):
    while not task_queue.empty():
        try:
            folder = task_queue.get()
            process_folder(folder)
            result_queue.put(1)
        except Exception as e:
            print(f"Error processing folder: {e}")

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    # args.test_path = "output/test_with_sql"
    # args.test_path = "output/test"
    # args.test_path = "output/o1-preview-test1"
    parser.add_argument('--task', type=str, default="snow")
    parser.add_argument('--test_path', type=str, default="examples")
    parser.add_argument('--output_path', type=str, default="output/o1-preview-snow-log")
    parser.add_argument('--model', type=str, default="o1-preview")
    parser.add_argument('--model_local', type=str, default=None)
    parser.add_argument('--understanding_model', type=str, default="o1-preview")
    parser.add_argument('--overwrite_results', action="store_true")
    parser.add_argument('--azure', action="store_true")
    parser.add_argument('--max_iter', type=int, default=10)
    parser.add_argument('--temperature', type=float, default=1)
    parser.add_argument('--save_all_results', action="store_true")
    parser.add_argument('--use_CoT', action="store_true")
    parser.add_argument('--schema_linking_api', type=str, default=None)
    parser.add_argument('--rerun', action="store_true")
    parser.add_argument('--num_process', type=str, default=2)
    args = parser.parse_args()
    num_process = int(args.num_process)
    # main(args)
    dictionaries = [entry for entry in os.listdir(args.test_path) if os.path.isdir(os.path.join(args.test_path, entry))]

    with Manager() as manager:
        task_queue = manager.Queue()
        result_queue = manager.Queue()
        for folder in dictionaries:
            task_queue.put(folder)

        lock = Lock()
        with tqdm(total=len(dictionaries), desc="Processing Folders") as progress_bar:
            with Pool(processes=num_process) as pool:
                for _ in range(num_process):
                    pool.apply_async(worker, args=(task_queue, result_queue))
                pool.close()
                while not task_queue.empty() or not result_queue.empty():
                    result_queue.get()
                    progress_bar.update(1)
                pool.join()