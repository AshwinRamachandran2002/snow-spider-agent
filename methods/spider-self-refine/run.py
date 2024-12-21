import os
import json
import pandas as pd
import snowflake.connector
from openai import OpenAI
from tqdm import tqdm
import logging
import argparse
import glob
from transformers import AutoModelForCausalLM, AutoTokenizer
from openai import AzureOpenAI
from azure.identity import DefaultAzureCredential, get_bearer_token_provider
import Levenshtein

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

def get_str_sim(str1, str2):
    return Levenshtein.ratio(str1, str2)

def hard_cut(str_e, length):
    if len(str_e) > length:
        str_e = "Too long, hard cut:\n" + str_e[:length]+"\n"
    return str_e

def get_values_from_table(csv_data_str):
    return '\n'.join(csv_data_str.split('\n')[1:])

def search_file(directory, target_file):
    result = []
    for root, dirs, files in os.walk(directory):
        if target_file in files:
            result.append(os.path.join(root, target_file))
    return result

class GPTChat:
    def __init__(self, azure=False, model="gpt-4o") -> None:
        if model == "gpt-4o" or not azure:
            self.client = OpenAI(
                api_key=os.environ.get("OPENAI_API_KEY"),  # This is the default and can be omitted
            )
        else:
            self.client = AzureOpenAI(
                azure_endpoint = os.environ.get("AZURE_ENDPOIONT"),
                api_key=os.environ.get("AZURE_OPENAI_KEY"),  # This is the default and can be omitted
                api_version="2024-02-15-preview"
            )

        self.messages = []
        self.model = model

    def get_model_response(self, prompt, code_format):
        self.messages.append({"role": "user", "content": prompt})
        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=self.messages
            )
        except Exception as e:
            print(e)
            return "Exceeded"
        choices = response.choices
        if choices:
            # Extract the main message content
            main_content = choices[0].message.content
            # print("Main Content:\n", main_content)
            
            sql_query = extract_all_blocks(main_content, code_format)
        self.messages.append({"role": "assistant", "content": main_content})
        return sql_query
    def get_model_response_txt(self, prompt):
        self.messages.append({"role": "user", "content": prompt})
        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=self.messages
            )
        except Exception as e:
            print(e)
            return "Exceeded"
        choices = response.choices
        if choices:
            # Extract the main message content
            main_content = choices[0].message.content
            # print("Main Content:\n", main_content)
            
            # sql_query = extract_all_sql_blocks(main_content)
        self.messages.append({"role": "assistant", "content": main_content})
        return main_content

    def get_message_len(self):
        return sum([len(i['content']) for i in self.messages])
    
    def init_messages(self):
        self.messages = []

class modelChat():
    def __init__(self, model, tokenizer) -> None:
        self.model = model
        self.tokenizer = tokenizer
        self.messages = []

    def get_model_response(self, prompt, code_format):
        self.messages.append({"role": "user", "content": prompt})
        text = self.tokenizer.apply_chat_template(
            self.messages,
            tokenize=False,
            add_generation_prompt=True
        )
        model_inputs = self.tokenizer([text], return_tensors="pt").to(self.model.device)

        generated_ids = self.model.generate(
            **model_inputs,
            max_new_tokens=512
        )
        generated_ids = [
            output_ids[len(input_ids):] for input_ids, output_ids in zip(model_inputs.input_ids, generated_ids)
        ]

        response = self.tokenizer.batch_decode(generated_ids, skip_special_tokens=True)[0]
        sql_query = extract_all_blocks(response)
        self.messages.append({"role": "assistant", "content": response})
        return sql_query

    def get_message_len(self):
        return sum([len(i['content']) for i in self.messages])

    def init_messages(self):
        self.messages = []


def excute_sql(sql_query, save_path=None):
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
                columns = [desc[0] for desc in cursor.description]
                df = pd.DataFrame(results, columns=columns)

                # Check if the result is empty
                if df.empty:
                    print("No data found for the specified query.")
                    return "No data found for the specified query.\n"
                else:
                    # Save or print the results based on the is_save flag
                    if save_path:
                        df.to_csv(f"{save_path}", index=False)
                        print(f"Results saved to {save_path}")
                        return 0
                    else:
                        # print(df)
                        return df.to_csv()
            except Exception as e:
                print("Error occurred: ", str(e))
                return e

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def main(args):

    table_info_txt = ["prompts.txt"]
    target_json = "result.json"
    
    save_path = "result.csv"
    # read file
    # json_path = search_file(search_directory, target_json)[0]

    json_path = os.path.join(args.test_path, "spider2-snow.jsonl")
    task_dict = {}
    with open(json_path) as f:
        for line in f:
            line_js = json.loads(line)
            task_dict[line_js['instance_id']] = line_js['instruction']

    dictionaries = [entry for entry in os.listdir(args.test_path) if os.path.isdir(os.path.join(args.test_path, entry))]

    if "gpt" in args.model or "o1" in args.model:
        if args.azure:
            chat_session = GPTChat(args.azure, args.model)
            chat_session4o = GPTChat(args.azure, args.understanding_model)
            
        else:            
            chat_session = GPTChat(args.model)
            chat_session4o = GPTChat(model=args.understanding_model)
            # chat_session4o = GPTChat(model="o1-mini")
    else:
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

        
        for handler in logger.handlers[:]:
            logger.removeHandler(handler)

        print(sql_data)

        
        task = task_dict[sql_data]
        # search_directory = args.test_path +  '/' + sql_data
        search_directory = os.path.join(args.output_path, sql_data)
        if not os.path.exists(search_directory):
            os.makedirs(search_directory)

        # if log.log exists, pass
        if not args.overwrite_results and os.path.exists(os.path.join(search_directory, "log.log")):
            continue
        
        # if "result_s.csv" in os.listdir(search_directory):
        #     continue
        
        # overwrite
        self_files = glob.glob(os.path.join(search_directory, f'*{save_path}*'))
        for self_file in self_files:
            os.remove(self_file)

        # log
        log_file_path = os.path.join(search_directory, "log.log")
        file_handler = logging.FileHandler(log_file_path, mode='w')
        file_handler.setLevel(logging.INFO)
        formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)

        table_info = ''
        for txt in table_info_txt:
            txt_path = search_file(os.path.join(args.test_path, sql_data), txt)
            for path in txt_path:
                with open(path) as f:
                    table_info += f.read()

        # format
        format_prompt = "\nThis is a sql task. Please provide the simplest possible answer in ```csv``` format like a table and include a brief explanation. Fill the table according to the task description rather than the actual database. For values that cannot be inferred from the task description, use metanames with potential type and conditions, rather than real values. When dealing with superlative cases, ensure the result is limited to just one row. For coordinate-related cases, use the ST_POINT() function. For percentage values, omit the '%' symbol and retain only the numeric format as xx.xx. Do not output any SQL queries. Do not miss any column in the answer format, one column for one attribute and one row for one record in the task."
        format_prompt += "e.g. Retrieve all male and female customers from a customers table who have placed orders in the last 30 days, along with their order count. Format: ```csv\nsex,customer_id,customer_name,total_orders\nmale,id: int,name: string,orders: int\nfemale,id: int,name: string,orders: int```\nCondition: customer_name(have placed orders in the last 30 days)\n"
        format_prompt += "For distance task, no need to convert from meters to miles unless requested.\n"
        format_prompt += "You may combine 2 columns into one if needed. (e.g. concatenate first name and last name as full name)\n" # local056
        response_csv = chat_session4o.get_model_response_txt(table_info + "Task: " + task + format_prompt)

        # preparation
        LIMIT = 10
        prompt = table_info + "\n" + "Task: " + task + "\n"
        pre_info = ''
        while LIMIT > 0:

            ans_pre = prompt + f"Consider which tables and columns are relevant to the task? Answer like: `column name`: `potential usage`. And also conditions that may be used. Then write simple and short sql queries ```sql\nSELECT DISTINCT \"COLUMN_NAME\" FROM PROJECT.DATABASE.TABLE WHERE ... ``` (Adjust \"PROJECT\", \"DATABASE\", and \"TABLE\" to match actual names) in ```sql``` format to have an understanding of values in related columns. Each query should be independent, without using `WITH`. For columns in json nested format: e.g. SELECT t.\"column_name\", f.value::VARIANT:\"key_name\"::STRING AS \"abstract_text\" FROM   PATENTS.PATENTS.PUBLICATIONS t, LATERAL FLATTEN(input => t.\"json_column_name\") f;;. DO NOT directly answer the task and ensure all column names are enclosed in double quotations.\n"
            # ans_pre += "e.g. Retrieve all products whose product_name contains the word \"Professor’s book\". Simple non-nested sql queries: SELECT \"product_id\", \"product_name\" FROM products WHERE product_name LIKE '%Professor%' OR '%Book%'; (For string matching cases, firstly look if the substring exists)"
            ans_pre += "For string-matching scenarios, ensure all characters are converted to standard symbols (e.g., replace ’ with ').\n"
            ans_pre += "When using TO_DATE() function, filter NULL: WHERE TRY_TO_DATE(filing_date, 'YYYYMMDD') IS NOT NULL;.\n"
            logger.info(ans_pre)
            response_pre = chat_session.get_model_response(ans_pre, "sql")
            logger.info(chat_session.messages[-1]['content'])
            if response_pre == "Exceeded":
                LIMIT -= 9
                # print(f"{response_pre}, adjust LIMIT: {LIMIT}")
                print(f"{response_pre}, retry")
                continue

            pre_info += f"Possible values for important columns:\n"
            sql_count = 0
            for i in range(len(response_pre)):
                e = excute_sql(response_pre[i])
                if isinstance(e, str):
                    # if len(e) > 1e4:
                    #     e = "Too long, hard cut:"+e[:10000]+"\n"
                    e = hard_cut(e, 10000)
                    pre_info += "Query:\n" + response_pre[i] + "\nAnswer:\n" + e
                    # if e != "No data found for the specified query.\n":
                    sql_count += 1
                elif "0A000" in e.msg:
                        queries = [query.strip() for query in response_pre[i].strip().split(';') if query.strip()]
                        for q in queries:
                            e = excute_sql(q)
                            if isinstance(e, str):
                                e = hard_cut(e, 10000)
                                pre_info += "Query:\n" + q + "Answer:\n" + e
                                # if e != "No data found for the specified query.\n":
                                sql_count += 1
            if sql_count < len(response_pre) // 2:
                print("Inadequate preparation, retry preparation.")
                LIMIT -= 3
                continue

            if len(pre_info) < 1e5:
                break
            print("Too long, retry preparation.")
            pre_info = ''
            LIMIT -= 3
            chat_session.init_messages()
        print(f"len(pre_info): {len(pre_info)}, chat_session.get_message_len(): {chat_session.get_message_len()}")
        if LIMIT <= 0:
            print("Inadequate preparation, skip")
            continue
        

        # answer
        itercount = 0
        e = pre_info
        results_values = []
        results_tables = []
        complete_save_path = search_directory + "/" + save_path
        e += "Task: " + task + "\n"+'\nPlease answer in snowflake dialect in ```sql``` format.\nUsage example: SELECT S."Column_Name" FROM {Project Name}.{Database Name}.{Table_name} (ensure all column names are enclosed in double quotations)\n'
        e += f"Follow the answer format like: {response_csv}.\n"
        e += "When performing a UNION operation on tables, please ensure that all tables are explicitly listed. Do not omit any.\n"
        e += "When calculating distances between two geometries, use `ST_MakePoint(x, y)` to make point and `ST_Distance(geometry1 GEOMETRY, geometry2 GEOMETRY)` to compute. No need to convert from meters to miles unless requested.\n"
        e += "Please refrain from adding any conditions that are not explicitly specified in the task.\n" # bq398
        e += "Don't ouput extra rows. (e.g. use JOIN rather LEFT JOIN to avoid extra rows)\n" # local131

        # self-refine
        error_rec = []
        while itercount < args.max_iter:
            logger.info(f"itercount: {itercount}")
            logger.info(e)
            if e == 0:
                e = f"Please check the answer again and give the final SQL query. It doesn't mean you are wrong, just check again. The answer format should be like: {response_csv}, check the number of rows and columns. Your snswer: \n"
                with open(complete_save_path) as f:
                    csv_data = f.readlines()
                    csv_data_str = ''.join(csv_data)
                e += csv_data_str if len(csv_data_str) < 1e4 else hard_cut(csv_data_str, 10000)
                if get_values_from_table(csv_data_str) not in results_values:
                    results_values.append(get_values_from_table(csv_data_str))
                    results_tables.append(csv_data_str)
                else:
                    break
                logger.info(f"results: \n{csv_data_str}\n")
                if args.save_all_results:
                    save_path = save_path[:-4] + str(itercount) + save_path[-4:]
            if hasattr(e, 'msg'):
                e = f"Input sql:\n{response}\nThe error information is:\n" + e.msg + "\nPlease correct it and output only 1 complete sql query."
            response = chat_session.get_model_response(e, "sql")
            if response == "Exceeded":
                print(response)
                if os.path.exists(complete_save_path):
                    os.remove(complete_save_path)
                break
            logger.info(chat_session.messages[-1]['content'])
            if len(response) > 0:
                response_len = [len(i) for i in response]
                response_index = response_len.index(max(response_len))
                response = response[response_index]
                e = excute_sql(response, complete_save_path)
            itercount += 1
            error_rec.append(e)
            # if len(error_rec) > 3:
            #     if len(set(error_rec[-4:])) == 1:
            #         print("Can't reach consistency, remove file")
                    
            #         if os.path.exists(complete_save_path):
            #             os.remove(complete_save_path)
            #         if error_rec[-1] == 0:
            #             with open(complete_save_path) as f:
            #                 csv_data = f.readlines()
            #                 csv_data_str = ''.join(csv_data)
            #             results_tables.append(csv_data_str)
            #             selected_ans = chat_session.get_model_response(f"Here are some candidate answers. Please choose one as the correct answer. Provide the output in ```csv``` format: {results_tables}.", "csv")
            #             if selected_ans:
            #                 with open(complete_save_path, "w") as file:
            #                     file.writelines(selected_ans[0])
            #         break
        logger.info(f"Total iteration counts: {itercount}")
        if itercount == args.max_iter and not args.save_all_results:
            print("Max Iter, remove file")
            if os.path.exists(complete_save_path):
                os.remove(complete_save_path)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    # args.test_path = "output/test_with_sql"
    # args.test_path = "output/test"
    # args.test_path = "output/o1-preview-test1"
    parser.add_argument('--test_path', type=str, default="examples")
    parser.add_argument('--output_path', type=str, default="output/gpt-4o-test1-log")
    parser.add_argument('--model', type=str, default="gpt-4o")
    parser.add_argument('--understanding_model', type=str, default="gpt-4o")
    parser.add_argument('--overwrite_results', action="store_true")
    parser.add_argument('--azure', action="store_true")
    parser.add_argument('--max_iter', type=int, default=8)
    parser.add_argument('--save_all_results', action="store_true")
    parser.add_argument('--use_CoT', action="store_true")
    args = parser.parse_args()
    main(args)