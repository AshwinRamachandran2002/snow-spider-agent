import os
from tqdm import tqdm
import argparse
import glob
from utils import get_table_info, initialize_logger, get_dictionary
from agent import REFORCE, schema_linking
from typing import Type
from chat import GPTChat
from prompt import Prompts
import multiprocessing
from sql import SqlEnv

def execute(agent: Type[REFORCE], task, table_info, args, csv_save_path, log_save_path, sql_save_path, search_directory, chat_session, chat_session_pre, format_csv):
    if args.rerun:
        if os.path.exists(os.path.join(search_directory, csv_save_path)):
            return
        else:
            print(f"Rerun: {search_directory}")
    # if log.log exists, pass
    elif not args.overwrite_results and os.path.exists(os.path.join(search_directory, log_save_path)):
        return

    # remove csv
    self_files = glob.glob(os.path.join(search_directory, f'*{csv_save_path}*'))
    for self_file in self_files:
        os.remove(self_file)

    # log
    log_file_path = os.path.join(search_directory, log_save_path)
    logger = initialize_logger(log_file_path)
    logger.info("[Answer format]\n" + format_csv + "\n[Answer format]")
    table_struct = table_info[table_info.find("The table structure information is "):]

    sql_env = SqlEnv()

    # preparation
    pre_info, response_pre_txt, max_try, chat_session_pre, sql_env = agent.exploration(task, table_struct, logger, chat_session_pre, sql_env)
    if max_try <= 0:
        print("Inadequate preparation, skip")
        return
    print(f"{search_directory}: chat_session_pre len: {chat_session_pre.get_message_len()}")
    csv_save_path = os.path.join(search_directory, csv_save_path)
    sql_save_path = os.path.join(search_directory, sql_save_path)

    # answer
    chat_session, sql_env = agent.self_refine(args, logger, task, format_csv, table_struct, table_info, response_pre_txt, pre_info, chat_session, csv_save_path, sql_save_path, sql_env)
    print(f"{search_directory}: chat_session len: {chat_session.get_message_len()}")

    sql_env.close_db()

def main(args):
    prompt_all = Prompts()

    dictionaries, task_dict = get_dictionary(args)

    if args.model:
        chat_session = GPTChat(args.azure, args.model, temperature=args.temperature)
        chat_session_pre = GPTChat(args.azure, args.pre_model, temperature=args.temperature)

    if args.schema_linking_model:
        chat_session_sl = GPTChat(args.azure, args.schema_linking_model, temperature=args.temperature) 
        schema_linking(dictionaries, task_dict, args.db_path, chat_session_sl)

    for sql_data in tqdm(dictionaries):
        chat_session.init_messages()
        chat_session_pre.init_messages()
        print(sql_data)

        task = task_dict[sql_data]
        search_directory = os.path.join(args.output_path, sql_data)

        agent = REFORCE(args, sql_data, search_directory, prompt_all)
        if not os.path.exists(search_directory):
            os.makedirs(search_directory)

        sql_paths = {}
        processes = []

        if not args.overwrite_results and os.path.exists(agent.complete_csv_save_path):
            continue
        if not os.path.exists(search_directory):
            os.makedirs(search_directory)

        table_info = get_table_info(args.db_path, sql_data, agent.api)

        format_csv, chat_session_pre = agent.format_answer(table_info, task, chat_session_pre)

        if chat_session_pre.get_message_len() > 300000:
            print(f"{sql_data} Too long context, skip")
            continue

        if args.model_vote:
            num_processes = args.num_processes

            sql_paths = {}
            processes = []

            for i in range(num_processes):

                csv_save_pathi = str(i) + agent.csv_save_name
                log_pathi = str(i) + agent.log_save_name
                sql_save_pathi = str(i) + agent.sql_save_name
                sql_paths[sql_save_pathi] = csv_save_pathi
                process = multiprocessing.Process(target=execute, args=(agent, task, table_info, args, csv_save_pathi, log_pathi, sql_save_pathi, search_directory, prompt_all, chat_session, chat_session_pre, format_csv))
                processes.append(process)
                process.start()

            for process in processes:
                process.join()

            agent.vote_result(search_directory, task)
        
        else:
            execute(agent, task, table_info, args, agent.csv_save_name, agent.log_save_name, agent.sql_save_name, search_directory, chat_session, chat_session_pre, format_csv)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--task', type=str, default="snow")
    parser.add_argument('--db_path', type=str, default="examples")
    parser.add_argument('--output_path', type=str, default="output/o1-preview-snow-log")
    parser.add_argument('--model', type=str, default="o1-preview")
    parser.add_argument('--pre_model', type=str, default="o1-preview")
    parser.add_argument('--overwrite_results', action="store_true")
    parser.add_argument('--azure', action="store_true")
    parser.add_argument('--max_iter', type=int, default=10)
    parser.add_argument('--temperature', type=float, default=1)
    parser.add_argument('--num_processes', type=int, default=3)
    parser.add_argument('--save_all_results', action="store_true")
    parser.add_argument('--schema_linking_model', type=str, default=None)
    parser.add_argument('--rerun', action="store_true")
    parser.add_argument('--model_vote', action="store_true")
    args = parser.parse_args()
    main(args)