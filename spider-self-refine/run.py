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


def search_file(directory, target_file):
    result = []
    for root, dirs, files in os.walk(directory):
        if target_file in files:
            result.append(os.path.join(root, target_file))
    return result

class GPTChat:
    def __init__(self, model="gpt-4o") -> None:
        self.client = OpenAI(
            api_key=os.environ.get("OPENAI_API_KEY"),  # This is the default and can be omitted
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
        except:
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
        except:
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

    # Connect to Snowflake
    conn = snowflake.connector.connect(
        **snowflake_credential
    )
    cursor = conn.cursor()

    # Define the SQL query
    # Execute the SQL query
    try:
        cursor.execute(sql_query)
        try:
            # Fetch the results
            results = cursor.fetchall()
            columns = [desc[0] for desc in cursor.description]
            df = pd.DataFrame(results, columns=columns)

            # Check if the result is empty
            if df.empty:
                print("No data found for the specified query.")
                return "No data found for the specified query."
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
            print("Error occurred while fetching data: ", e)
            return e
        finally:
            cursor.close()
            conn.close()
    except Exception as e:
        print("Error occurred while fetching data: ", e)
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
        chat_session = GPTChat(args.model)
        chat_session4o = GPTChat("gpt-4o")
        # chat_session4o = GPTChat("o1-mini")
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

        # if self.csv exists, pass
        if not args.overwrite_results and os.path.exists(os.path.join(search_directory, save_path)):
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
        format_prompt = "\nThis is a sql task. Please output a possible simplest answer format in ```plaintext``` format. Fill the table according to the task description (and explain why) rather than database. Be careful of limiting just 1 row when faced with superlative. For coordinates cases, use ST_POINT() function. Don't output any sql query."
        response_csv = chat_session4o.get_model_response_txt("Task: " + task + format_prompt)

        # preparation
        LIMIT = 10
        while LIMIT > 0:
            
            prompt = table_info + "\n" + "Task: " + task + "\n"
            
            ans_pre = prompt + f"Consider which tables and columns are relevant to the task? Answer like: `column name`: `potential usage`. And also conditions that may be used. Then write sql queries `SELECT DISTINCT \"COLUMN_NAME\" FROM PROJECT.DATABASE.TABLE LIMIT {LIMIT}` to have an understanding of values in these columns. For columns in json format: \"key\".value:\"value\". DO NOT directly answer the task and ensure all column names are enclosed in double quotations!\n"
            logger.info(ans_pre)
            response_pre = chat_session.get_model_response(ans_pre, "sql")
            logger.info(chat_session.messages[-1]['content'])
            if response_pre == "Exceeded":
                LIMIT -= 9
                # print(f"{response_pre}, adjust LIMIT: {LIMIT}")
                print(f"{response_pre}, retry")
                continue

            pre_info = f"Possible values for important columns:\n"
            for i in range(len(response_pre)):
                e = excute_sql(response_pre[i])
                if isinstance(e, str):
                    pre_info += e
                else:
                    if "0A000" in e.msg:
                        queries = [query.strip() for query in response_pre[i].strip().split(';') if query.strip()]
                        for q in queries:
                            e = excute_sql(q)
                            if isinstance(e, str):
                                pre_info += e

            if len(pre_info) < 1e5:
                break
            print("Retry preparation.")
            LIMIT -= 3
            chat_session.init_messages()
        print(f"len(pre_info): {len(pre_info)}, chat_session.get_message_len(): {chat_session.get_message_len()}")

        

        # answer
        itercount = 0
        e = pre_info
        results_post = None
        e += "Task: " + task + "\n"+'\nPlease answer in snowflake dialect.\nUsage example: SELECT S."Column_Name" FROM {Project Name}.{Database Name}.{Table_name} (ensure all column names are enclosed in double quotations)\n'
        e += f"You may combine 2 column into 1 column to follow the column name in answer format like: {response_csv}.\n"
        error_rec = []
        while itercount < args.max_iter:
            logger.info(e)
            if e == 0:
                e = f"Please check the answer again and give the final SQL query. It doesn't mean you are wrong, just check again. The answer format may be like {response_csv}. Don't output extra rows. Your snswer: \n"
                with open(search_directory + "/" + save_path) as f:
                    csv_data = f.readlines()
                e += ''.join(csv_data)
                if not results_post:
                    results_post = ''.join(csv_data)
                else:
                    if results_post == ''.join(csv_data):
                        break
                
                if args.save_all_results:
                    save_path = save_path[:-4] + str(itercount) + save_path[-4:]
            if hasattr(e, 'msg'):
                e = "The error information is:\n" + e.msg + "\nPlease correct it and output only 1 complete sql query."
            response = chat_session.get_model_response(e, "sql")
            if response == "Exceeded":
                print(response)
                os.remove(save_path)
                break
            logger.info(chat_session.messages[-1]['content'])
            if len(response) > 0:
                response_len = [len(i) for i in response]
                response_index = response_len.index(max(response_len))
                e = excute_sql(response[response_index], search_directory + "/" + save_path)
            itercount += 1
            error_rec.append(e)
            if len(error_rec) > 3:
                if len(set(error_rec[-3:])) == 1:
                    break
        logger.info(f"Total iteration counts: {itercount}")
        if itercount == args.max_iter and args.save_all_results:
            print("Exceede Max Iter")
            os.remove(save_path)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    # args.test_path = "output/test_with_sql"
    # args.test_path = "output/test"
    # args.test_path = "output/o1-preview-test1"
    parser.add_argument('--test_path', type=str, default="examples")
    parser.add_argument('--output_path', type=str, default="output/gpt-4o-test1")
    parser.add_argument('--model', type=str, default="models/gpt-4o")
    parser.add_argument('--overwrite_results', action="store_true")
    parser.add_argument('--max_iter', type=int, default=10)
    parser.add_argument('--save_all_results', action="store_true")
    args = parser.parse_args()
    main(args)