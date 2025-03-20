from utils import execute_sql_api, hard_cut, get_values_from_table, search_file, get_api_name, get_table_info, compare_pandas_table, extract_between, get_sqlite_path
from reconstruct_data import remove_digits, compress_ddl
import pandas as pd
from io import StringIO
import os
import ast
import csv
from prompt import Prompts
from typing import Type
from tqdm import tqdm
from chat import GPTChat

class REFORCE():
    def __init__(self, sql_data, search_directory, prompt_class: Type[Prompts]):
        self.csv_save_name = "result.csv"
        self.sql_save_name = "result.sql"
        self.log_save_name = "log.log"
        self.log_vote_name = "vote.log"
        self.empty_result = "No data found for the specified query.\n"

        self.api = get_api_name(sql_data)
        self.sqlite_path = get_sqlite_path(sql_data)

        self.sql_id = sql_data

        self.complete_csv_save_path = os.path.join(search_directory, self.csv_save_name)
        self.complete_sql_save_path = os.path.join(search_directory, self.sql_save_name)
        self.complete_vote_log_path = os.path.join(search_directory, self.log_vote_name)

        self.prompt_class = prompt_class
        self.max_try = 3

    def execute_sqls(self, sqls, chat_session: Type[GPTChat], logger, max_len=500):
        result_dic_list = []
        error_rec = []
        causes = ''
        while sqls:
            result_dic = {}
            sql = sqls[0]
            sqls = sqls[1:]
            check_again_flag = False
            logger.info("[Try to execute]\n" + sql + "\n[Try to execute]")
            results = execute_sql_api(sql, api=self.api, max_len=max_len, sqlite_path=self.sqlite_path)
            try:
                # Check null values
                if results != self.empty_result:
                    df_csv = StringIO(results)
                    df_csv = pd.read_csv(df_csv).fillna(0)
                    if ((df_csv == 0) | (df_csv == "")).all().any():
                        check_again_flag = True
            except:
                pass
            if isinstance(results, str) and results != self.empty_result and not check_again_flag:
                result_dic['sql'] = sql
                result_dic['res'] = results
                chat_session.messages.append({"role": "user", "content": f"Successfully executed. SQL:\n{sql}\nResults:\n{results}"})
                logger.info("[Successfully executed]\n" + chat_session.messages[-1]['content'] + "\n[Successfully executed]")
                result_dic_list.append(result_dic)
            else:
                logger.info("[Error occurred]\n" + str(results) + "\n[Error occurred]")
                max_iter = 3
                simplify = False
                corrected_sql = None
                while not isinstance(results, str) or results == self.empty_result or check_again_flag:
                    if max_iter == 0:
                        break
                    if results == self.empty_result:
                        simplify = True
                    corrected_sql, chat_session = self.self_correct(sql, results, chat_session, logger, simplify=simplify, check_again_flag=check_again_flag)
                    check_again_flag = False
                    if not isinstance(corrected_sql, list) or len(corrected_sql) != 1:
                        print(f"{self.sql_id}: Not a valid SQL.\n")
                        continue
                    corrected_sql = corrected_sql[0]
                    results = execute_sql_api(corrected_sql, api=self.api, max_len=max_len, sqlite_path=self.sqlite_path)
                    logger.info("[Results for corrected sql]\n"+str(results)+"\n[Results for corrected sql]")
                    max_iter -= 1
                    simplify = False

                cause = chat_session.get_model_response_txt("The error is corrected. Please conclude all possible causes to this error in only one sentence. Don't output any SQL query.")
                causes += cause
                logger.info("[Cause]\n"+str(cause)+"\n[Cause]")
                if isinstance(results, str) and results != self.empty_result:
                    error_rec.append(1)
                    response = chat_session.get_model_response(f"Please correct other sqls if they have similar errors: {cause}. SQLs: {sqls}. For each SQL, answer in ```sql``` format.\n", "sql")
                    if isinstance(corrected_sql, list) and corrected_sql != []:
                        response_sqls = []
                        for s in response:
                            try:
                                queries = [query.strip() for query in s.strip().split(';') if query.strip()]
                                response_sqls += queries
                            except:
                                pass
                        if len(response_sqls) >= len(sqls):
                            sqls = response_sqls
                            logger.info("[Corrected other sqls]\n"+chat_session.messages[-1]['content']+"\n[Corrected other sqls]")
                else:
                    error_rec.append(0)
                    results = str(results)
                # Many times error, return
                if len(error_rec) > 5 and sum(error_rec[-5:]) == 0:
                    return result_dic_list, chat_session
                if not corrected_sql:
                    continue
                result_dic['sql'] = corrected_sql
                result_dic['res'] = results
                chat_session.messages.append({"role": "user", "content": f"Successfully corrected. SQL:\n{corrected_sql}\nResults:\n{results}"})
                logger.info("[Successfully corrected]\n" + chat_session.messages[-1]['content'] + "\n[Successfully corrected]")
        return result_dic_list, chat_session, causes

    def self_correct(self, sql, error, chat_session, logger, simplify=False, check_again_flag=False):
        prompt = f"Input sql:\n{sql}\nThe error information is:\n" + str(error) if not isinstance(error, str) else error + "\nPlease correct it based on previous context and output the thinking process with only one sql query in ```sql``` format. Don't just analyze without SQL or output several SQLs.\n"
        if simplify:
            prompt += "Since the output is empty, please simplify some conditions of the past sql.\n"
        if check_again_flag:
            prompt += "Some columns are empty values. Please check it again.\n"
        response = chat_session.get_model_response(prompt, "sql")

        max_try = self.max_try
        while max_try > 0 and (not isinstance(response, str) or len(response) > 1):
            response = chat_session.get_model_response("Please generate only one SQL with thinking process.", "sql")
            max_try -= 1
        logger.info("[Corrected SQL]\n" + chat_session.messages[-1]['content'] + "\n[Corrected SQL]")
        return response, chat_session

    def format_answer(self, table_info, task, chat_session: Type[GPTChat]):
        format_prompt = self.prompt_class.get_format_prompt()
        response_csv = chat_session.get_model_response_txt(table_info + "Task: " + task + format_prompt)
        return response_csv, chat_session

    def exploration(self, task, max_try, table_struct, logger, chat_session: Type[GPTChat]):
        pre_info = ''
        task = "Task: " + task + "\n"
        max_try = 3
        while max_try > 0:
            exploration_prompt = task + self.prompt_class.get_exploration_prompt(self.api, table_struct)

            response_pre = chat_session.get_model_response(exploration_prompt, "sql")
            response_pre_txt = chat_session.messages[-1]['content']
            if not isinstance(response_pre, list):
                max_try -= 1
                continue
            if len(response_pre) == 1:
                sql_list = [query.strip() for query in response_pre[0].strip().split(';') if query.strip()]
            if len(sql_list) < 10:
                max_try -= 1
                print(f"{self.sql_id}: Few sqls, retry preparation.")
                continue
            results_pre_dic_list, chat_session, causes = self.execute_sqls(sql_list, chat_session, logger, max_len=500)
            sql_count = 0
            for dic in results_pre_dic_list:
                pre_info += "Query:\n" + dic['sql'] + "\nAnswer:\n" + str(dic['res'])
                if isinstance(dic['res'], str):
                    sql_count += 1

            if sql_count < len(response_pre) // 2:
                print(f"{self.sql_id}: sql_count: {sql_count}, len(response_pre): {len(response_pre)}. Inadequate preparation, retry preparation.")
                pre_info = ''
                max_try -= 1
                continue

            if len(pre_info) < 1e5:
                break
            print(f"{self.sql_id}: Too long, retry preparation.")
            pre_info = ''
            max_try -= 1
        pre_info += f"Please note that this may cause errors:\n{causes}"
        return pre_info, response_pre_txt, max_try, chat_session

    def schema_linking(dictionaries, task_dict, example_path, chat_session_sl, txt_len_threshold):
        for eg_id in tqdm(dictionaries):
            skip_flag = False
            chat_session_sl.init_messages()
            print(eg_id)
            api = get_api_name(eg_id)
            task = task_dict[eg_id]
            table_info = get_table_info(example_path, eg_id, api)
            if len(table_info) < txt_len_threshold or skip_flag:
                continue
            print("Doing schema linking")
            table_struct = table_info[table_info.find("The table structure information is "):]

            prompt = f"Table information: {table_info}\nTask: {task}\nConsider which tables are related to the task. Remove unnecessary tables in {table_struct} and answer table names in ```python``` format in a list.\n"
            
            max_iter = 3
            while max_iter > 0:
                chat_session_sl.init_messages()
                e = None
                table_struct_response = chat_session_sl.get_model_response(prompt, "python")
                try:
                    table_names = ast.literal_eval(table_struct_response[0])
                    table_names_no_digit = [remove_digits(s) for s in table_names]
                except Exception as e:
                    print(str(table_struct_response))
                    continue
                if table_names_no_digit != []:
                    break
                max_iter -= 1
            if e is not None or max_iter <= 0:
                print([max_iter, e])
                continue
            ddl_paths = search_file(os.path.join(example_path, eg_id), "DDL.csv")
            
            for ddl_path in ddl_paths:
                temp_file = ddl_path.replace("DDL.csv", "DDL_tmp.csv")
                with open(ddl_path, "r", newline="", encoding="utf-8", errors="ignore") as infile, \
                    open(temp_file, "w", newline="", encoding="utf-8", errors="ignore") as outfile:
                    
                    reader = csv.reader(infile)
                    writer = csv.writer(outfile)

                    header = next(reader)
                    writer.writerow(header)
                    row_count = 0
                    row_list_all = []
                    row_list = []
                    for row in reader:
                        if any(remove_digits(row[0]) in item for item in table_names_no_digit):
                            row_count += 1
                            row_list_all.append(row)
                        if any(row[0] in item for item in table_names):
                            row_list.append(row)

                    if row_count > 100:
                        writer.writerows(row_list)
                    else:
                        writer.writerows(row_list_all)

                os.replace(temp_file, ddl_path)

        compress_ddl(example_path)

    def self_refine(self, args, logger, task, format_csv, table_struct, table_info, response_pre_txt, pre_info, chat_session):
        itercount = 0
        results_values = []
        results_tables = []

        self_refine_prompt = self.prompt_class.get_self_refine_prompt(self, table_info, response_pre_txt, pre_info, task, self.api, format_csv, table_struct)
        # self-refine
        error_rec = []
        while itercount < args.max_iter:
            logger.info(f"itercount: {itercount}")
            logger.info(self_refine_prompt)
            
            max_try = self.max_try
            while max_try > 0:
                response = chat_session.get_model_response(self_refine_prompt, "sql")
                if not isinstance(response, list) or len(response) != 1:
                    self_refine_prompt = "Please output one SQL only."
            if not isinstance(response, list) or response == []:
                if os.path.exists(self.complete_csv_save_path):
                    os.remove(self.complete_csv_save_path)
                print(f"{self.sql_id}: Error when generating final SQL.")
                break
            logger.info("[Try to run SQL]\n" + chat_session.messages[-1]['content'] + "\n[Try to run SQL]")
 
            executed_result = execute_sql_api(response, self.complete_csv_save_path, api=self.api, sqlite_path=self.sqlite_path)
            error_rec.append(executed_result)
            if len(error_rec) > 3:
                # Eraly stop for repeatitive empty results
                if len(set(error_rec[-4:])) == 1 and error_rec[-1] == self.empty_result:
                    logger.info("No data found for the specified query, remove file.")                    
                    if os.path.exists(self.complete_csv_save_path):
                        os.remove(self.complete_csv_save_path)
                    break
            
            if executed_result == 0:
                self_consistency_prompt = self.prompt_class.get_self_consistency_prompt(self, task, format_csv)
                with open(self.complete_csv_save_path) as f:
                    csv_data = f.readlines()
                    csv_data_str = ''.join(csv_data)
                self_consistency_prompt += csv_data_str if len(csv_data_str) < 1e4 else hard_cut(csv_data_str, 10000)
                self_consistency_prompt += f"Current sql:\n{response}"
                if '"""' in csv_data_str:
                    self_consistency_prompt += 'Please remove """ in results. Use CAST: CAST(column_name AS STRING).\n'

                csv_buffer = StringIO(csv_data_str)
                df_csv = pd.read_csv(csv_buffer).fillna("")

                nested_val = [(item) for i, row in enumerate(df_csv.values.tolist()) for j, item in enumerate(row) if isinstance(item, str) and '\n' in item in item]
                df_csv_copy = df_csv.copy()
                for col in df_csv.select_dtypes(include=['float']):
                    df_csv_copy[col] = df_csv[col].round(2)
                df_csv_copy_sorted = df_csv_copy.sort_values(by=df_csv_copy.columns[0])
                csv_data_str_round2 = df_csv_copy_sorted.to_string()
                if get_values_from_table(csv_data_str_round2) not in results_values:
                    if nested_val:
                        self_consistency_prompt += f"Values {nested_val} are nested. Please correct them. e.g. Transfer '[\nA,\n B\n]' to 'A, B'.\n"
                    elif not ((df_csv == 0) | (df_csv == "")).all().any():
                            results_values.append(get_values_from_table(csv_data_str_round2))
                            results_tables.append(csv_data_str)
                    else:
                        empty_columns = df_csv.columns[((df_csv == 0) | (df_csv == "")).all()].to_list()
                        self_consistency_prompt += f"Empty results in Column {empty_columns}. Please correct them.\n"
                else:
                    # self-consistency
                    logger.info(f"[Consistent results]\n{hard_cut(csv_data_str, 500)}\n[Consistent results]")
                    with open(self.complete_sql_save_path, "w") as f:
                        f.write(response)
                    break
                
                if any(keyword in response for keyword in self.prompt_class.get_condition_onmit_tables()):
                    self_consistency_prompt += self.prompt_class.get_prompt_dialect_list_all_tables(table_struct, self.api)
                if args.save_all_results:
                    save_path = save_path[:-4] + str(itercount) + save_path[-4:]
                self_refine_prompt = self_consistency_prompt
            
            elif not isinstance(executed_result, str):
                self_refine_prompt = f"Input sql:\n{response}\nThe error information is:\n" + str(executed_result) + "\nPlease correct it and output only 1 complete SQL query."
            
            elif executed_result == self.empty_result:
                self_refine_prompt = f"Input sql:\n{response}\nThe error information is: {self.empty_result}"

            itercount += 1

        logger.info(f"Total iteration counts: {itercount}")
        if itercount == args.max_iter and not args.save_all_results:
            if os.path.exists(self.complete_csv_save_path):
                os.remove(self.complete_csv_save_path)
            logger.info("Max Iter, remove file")

    def vote_result(self, search_directory, task, chat_session):
        

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
                    if any(v != complete_value and compare_pandas_table(pd.read_csv(v), pd.read_csv(complete_value), ignore_order=True) for v in all_values):
                        result[key] = value
        if result:
            sql_paths = result


        for sql, csv in sql_paths.items():
            sql_path = os.path.join(search_directory, sql)
            csv_path = os.path.join(search_directory, csv)
            logfile_path = os.path.join(search_directory, csv[0] + self.log_save_name)
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
            return
        elif count == 1:
            os.rename(sql_path_exist, self.complete_sql_save_path)
            os.rename(csv_path_exist, self.complete_csv_save_path)
        else:
            max_try = 3
            prompt += "Compare the SQL and results of each answer and choose one SQL as the correct answer and tell me the reason. Output the name of sql in ```plaintext\nxxx.sql``` format. You should not ingnore 'plaintext'.\n"
            response = chat_session.get_model_response(hard_cut(pre_info, 150000) + prompt, "plaintext")
            while max_try > 0:
                if not response or not isinstance(response, list):
                    print(response)
                    chat_session.get_model_response("Please output the name of sql in ```plaintext\nxxx.sql``` format. You should not ingnore 'plaintext'.", "plaintext")
                else:
                    break
                max_try -= 1
            with open(os.path.join(search_directory, response[0])) as f:
                selected_sql = f.read()
            if execute_sql_api(selected_sql, self.complete_csv_save_path, api=self.api, sqlite_path=self.sqlite_path) == 0:
                with open(self.complete_sql_save_path, "w") as f:
                    f.write(selected_sql)
                with open(self.complete_vote_log_path, "w") as f:
                    f.write(chat_session.messages[-1]['content'])