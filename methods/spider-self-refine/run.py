import os
import json
from openai import OpenAI
from tqdm import tqdm
import logging
import argparse
import glob
from transformers import AutoModelForCausalLM, AutoTokenizer
from openai import AzureOpenAI
from azure.identity import DefaultAzureCredential, get_bearer_token_provider
import Levenshtein
from utils import extract_all_blocks, hard_cut, get_values_from_table, search_file, execute_sql_snow, get_cte_info
from agent import execute_sql, self_correct
import numpy as np
import pandas as pd
from io import StringIO

CONDITION_OMIT_TABLES = ["-- Include all", "-- Omit", "-- Continue", "-- Union all", "-- ...", "-- List all", "-- Replace this", "-- Each table"]
class Prompts:
    def __init__(self):
        pass
    def get_prompt_list_all_tables(self, table_struct):
        return f"When performing a UNION operation on many tables, ensure that all table names are explicitly listed. Union first and then add condition and selection. e.g. SELECT \"col1\", \"col2\" FROM (TABLE1 UNION ALL TABLE2) WHERE ...; Don't write sqls as (SELECT col1, col2 FROM TABLE1 WHERE ...) UNION ALL (SELECT col1, col2 FROM TABLE2 WHERE ...); Don't use {CONDITION_OMIT_TABLES} to omit any table. Table names here: {table_struct}\n"
    def get_prompt_quantile_duration(self):
        return "For 50 min durations divided into 10 quantiles, it's about time not distance, so calculate distance every 5 minutes. When calculating the average number of sth, no need to filter null values, as they'll be treated as 0.\n"
    # def get_prompt_quantile_trip(self):
    #     return "For trips partition, it's about distance not time, so calculate minutes in equal divided trips.\n"
    def get_prompt_package(self):
        return "It's acceptable that there are repetitive names and versions in NPM package.\n"
    def get_prompt_generator(self):
        return "Be careful of using GENERATOR. Don't use seq4(), use ROW_NUMBER().\n"
    def get_prompt_NPM_package(self):
        return "For NPM packages, the result can contain repetitive names and versions.\n"
    def get_prompt_ST_INTERSECTS_FUNC(self):
        return "Usage of ST_INTERSECTS: ST_INTERSECTS(geometry1, ST_GEOGFROMWKB(geometry2)) This function checks if the two geometries intersect. The first argument, geometry1, is compared with the second argument, geometry2, which is converted from its WKB (Well-Known Binary) representation to a geography type using ST_GEOGFROMWKB. If the two geometries share any portion of space, the function returns TRUE; otherwise, it returns FALSE. Usage of ST_CONTAINS: ST_CONTAINS(r1.geometry, r2.geometry) This function checks if the geometry r1.geometry completely contains the geometry r2.geometry. It returns TRUE if all points of r2.geometry are within r1.geometry and FALSE otherwise. This is useful for spatial containment queries, such as verifying whether one region is entirely within another. ARRAY_INTERSECTION(nodes1, nodes2): This function computes the intersection of the two arrays, returning a new array containing only the elements that are present in both nodes1 and nodes2. ARRAY_SIZE(...): This function then determines the size (or number of elements) in the resulting array from the intersection.\n"
    def get_prompt_trip_duration(self):
        return "Calculation of trip duration in date range (A, B): pickup_datetime in (A, B) and dropoff_datetime in (A, B), not only pickup_datetime.\n"
    def get_prompt_full_outer_join(self):
        return "Avoid using FULL OUTER JOIN\n"
    def get_prompt_fuzzy_query(self):
        return "For string-matching scenarios, if the string is decided, don't use fuzzy query, and avoid using REGEXP. e.g. Get the object's title contains the word \"book\" SQL: WHERE \"title\" LIKE '%book%'\nHowever, if the string is not decided, you may use ILIKE and %. e.g. Get articles that mention \"education\": SQL: \"body\" ILIKE '%education%' OR \"title\" ILIKE '%education%'\n"
    def get_prompt_decimal_places(self):
        return "Keep all decimals to four decimal places.\n"
    def get_prompt_UNION_ALL(self):
        return "When unioning many tables, UNION ALL first and then SELECT and add conditions.\n"
    def get_prompt_convert_symbols(self):
        return "For string-matching scenarios, convert non-standard symbols to '%'. e.g. ('he’s to he%s)\n"
    def get_prompt_filter_null(self):
        return "If the column is not the main part of the answer, there's no need to filter NULL. e.g. Get the name, the trip ID, the ride duration, the start time, the starting station, and the gender of the rider. In this case, no need to filter NULL for the gender of the rider.\n"
    def get_prompt_name(self):
        return "For tasks asking fullname or name, you may combine first name and last name into one column called name.\n"


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
        print(f"Current_context_len: {self.get_message_len()}")
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
        print(f"Current_context_len: {self.get_message_len()}")
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


logger = logging.getLogger()
logger.setLevel(logging.INFO)

def main(args):

    prompt_all = Prompts()
    table_info_txt = ["prompts.txt"]
    target_json = "result.json"
    
    save_path = "result.csv"
    sql_save_path = "result.sql"
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
        table_struct = table_info[table_info.find("({project name: {database name: {table name}}}):"):]
        # format
        format_prompt = "This is an SQL task. Please provide the simplest possible answer in ```csv``` format like a table and include a brief explanation. Fill the table according to the task description rather than the actual database. For values that cannot be inferred from the task description, use metanames with potential types and conditions, rather than real values.\n"
        format_prompt += "For bool type, just write bool, don't fill with true or false. e.g. Please display the drug id, drug type and withdrawal status. Format: ```csv\ndrug_id,drug_type,hasBeenWithdrawn\npremarin_id,known_drug_type,bool\nhumira_id,known_drug_type,bool```\n"
        format_prompt += prompt_all.get_prompt_decimal_places()
        format_prompt += "Don't ouput extra rows. e.g. When dealing with superlative cases, ensure the result is limited to just one row. Get the fourth highest number of the group. Format: ```csv\nFourth-highest-num,group-name\nxx:int,name:str``` And emphasize only one row.\n"
        format_prompt += "e.g. Calculate the chi-square value of A, B, C. You should only focus on chi-square value. Format: ```csv\nchi-value\nv1:float\n e.g. Number of active and closed stations in 2012, 2013. Format: ```csv\nyear,number_active,number_closed\n2012,num:int,num:int\n2013,num:int,num:int```\n" # bq159\n" # ga010
        format_prompt += "e.g. Calculate the difference between A and B. You should only focus on difference value.\n"
        format_prompt += "e.g. Calculate proportion of A and B. You should only focus on proportion. Format: ```csv\nproportion\nnum:float```\n"
        format_prompt += "For coordinate-related cases, use the ST_POINT() function. e.g. Including its travel coordinates and the cumulative travel distance at each point. Format: ```csv\ngeom,cumulative_distance\nPOINT(longitude latitude),distance```\n"
        format_prompt += "For task asking percentage values, omit the '%' symbol and retain only the numeric format as xx.xx. Otherwise, for portion, proportion, answer a float number < 1.\n"
        format_prompt += "Ensure that no columns are omitted in the response format by assigning each attribute to its own column and representing each record in a separate row. e.g. When answering Wages Growth Rate and Inflation, the format should be ```csv\nWage_growth_rate,Inflation_rate\nxx.xx,xx.xx``` rather than ```csv\nMetric,rate\nrate1,xx.xx\nrate2,xx.xx```\n" # bq112
        format_prompt += "Don't lose any column: e.g. Top 5 states and counties counts and rank. Format: ```csv\nstate_name,state_num,state_rank,county_name,county_num,county_rank\nstr,int,int,str,int,int```\n"
        # format_prompt += "Don't output format like: ```csv\nSection,name,appearance_count,rank\nState Ranking,State1,num1,1\nCounty Ranking for State4,County1,num1,1```\n Because state and county can be different columns\n"
        format_prompt += "e.g. Retrieve all male and female customers from a customers table who have placed orders in the last 30 days, along with their order count. Format: ```csv\nsex,customer_id,customer_name,total_orders\nmale,id: int,name: string,orders: int\nfemale,id: int,name: string,orders: int```\n"
        # format_prompt += "For each column, specify its range or condition: e.g. Assess whether different genetic variants affect the log10-transformed TP53 expression levels in TCGA-BRCA samples. Provide the total number of samples and the number of mutation types. Format: ```csv\ntotal_number_of_samples,number_of_mutation_types\nnumber1:int,number2:int``` total_number_of_samples: TCGA-BRCA samples using sequencing and mutation data, number_of_mutation_types: TCGA-BRCA samples using mutation data\n"
        format_prompt += "For the Magnificent 7 tech companies, their ticker names are: META, GOOGL (not GOOG), AMZN, MSFT, AAPL, TSLA, NVDA\n"
        format_prompt += "For distance task, no need to convert from meters to miles unless requested.\n"
        format_prompt += prompt_all.get_prompt_name()
        format_prompt += "For other cases string should be separate, return both 2 strings. e.g. Ask team name: ```csv\nmarket,name\nstr1,str2```\n When asked for income, don't concatenate income with '$', just output number." # local056
        format_prompt += "If there are some records specified in the task, you should follow and capitalize them. e.g. Task: Give me the number of small, medium and large clothes. Format: ```csv\nSize,Number\nSmall,num1\nMedium,num2\nLarge,num3```\n" # local008
        format_prompt += "For month cases, form format in both month_num and month: ```csv\nMonth_num,Month\n01,Jan\n02,Feb```.\n" # local028
        format_prompt += "For quantile cases, explicitly list each quantile and convince the object to quantile. e.g. 60 minutes trip durations 10 quantiles: Format: ```csv\ntime_range,distance\n00m to 10m,dis1\n10m to 20m,dis2\n...\n50m to 60m,dis3``` Start from 0.\n"
        format_prompt += "If you meet with an ambiguous name in the task that may match 2 columns, feel free to add 2 columns of them. e.g. Tell me the tract code. Tract code may mean geo_id or tract_ce, then format: ```csv\geo_id,tract_ce\nid,code```\n"
        format_prompt += "You can also add a column related to the task. e.g. The month with the highest number. Format: ```csv\nmonth,month_num,number\nstr,int,int```\n"
        format_prompt += "Please output only one format. If there could be 2 tables as the complete answers, return the latter one as format. e.g. Identify the top five states by daily increases. Then, examine the state that ranks fourth overall and identify its top five counties. Format: ```csv\ntop_five_counties,count\ncounty1,count1\ncounty2,count2\ncounty3,count3\ncounty4,count4\ncounty5,count5```In this case, return results of the later one table.\n"
        format_prompt += "If there is any math relationship between columns, you should note it. e.g. Get a number added to the cart, without being purchased in the cart and count of actual purchases. Format: ```csv\nnumber added to the cart, without being purchased in the cart and count of actual purchases,num1,num2,num3``` Note: num1=num2+num3\n"
        # format_prompt += "For blockchain timestamp cases, Format: ```csv\nblock_timestamp\n2021-05-12 01:40:17.000000 UTC```\n"
        format_prompt += "Do not output any SQL queries.\n"
        response_csv = chat_session4o.get_model_response_txt(table_info + "Task: " + task + format_prompt)
        # format_csv = extract_all_blocks(response_csv, "csv")
        # if len(format_csv) > 0:
        #     print("Choose longer format.\n")
        #     format_csv = format_csv
        #     format_csv_len = [len(i) for i in format_csv]
        #     format_csv_index = format_csv_len.index(max(format_csv_len))
        #     format_csv = format_csv[format_csv_index]

        # preparation
        LIMIT = 10
        prompt = table_info + "\n" + "Task: " + task + "\n"
        pre_info = ''
        ans_pre = prompt
        ans_pre = ''
        while LIMIT > 0:

            ans_pre += f"Consider which tables and columns are relevant to the task. Answer like: `column name`: `potential usage`. And also conditions that may be used. Then write at least 10 simple, short, non-nested SQL queries like ```sql\nSELECT DISTINCT \"COLUMN_NAME\" FROM PROJECT.DATABASE.TABLE WHERE ... ``` (Adjust \"PROJECT\", \"DATABASE\", and \"TABLE\" to match actual names) in ```sql``` format to have an understanding of values in related columns. Each query should be independent, without using `WITH`. For columns in json nested format: e.g. SELECT t.\"column_name\", f.value::VARIANT:\"key_name\"::STRING AS \"abstract_text\" FROM   PATENTS.PATENTS.PUBLICATIONS t, LATERAL FLATTEN(input => t.\"json_column_name\") f; DO NOT directly answer the task and ensure all column names are enclosed in double quotations.\n"
            # ans_pre += "e.g. Retrieve all products whose product_name contains the word \"Professor’s book\". Simple non-nested sql queries: SELECT \"product_id\", \"product_name\" FROM products WHERE product_name LIKE '%Professor%' OR '%Book%'; (For string matching cases, firstly look if the substring exists)"
            # ensure all characters are converted to standard symbols (e.g., replace ’ with Escape Character \', replace ” with Escape Character \"'). And also u
            ans_pre += "For nested columns like event_params, when you don't know the structure of it, first watch the whole column: SELECT f.value FROM table, LATERAL FLATTEN(input => t.\"event_params\") f;\n"
            ans_pre += f"Don't use CTEs and don't query about any SCHEMA or checking data types. You can write SELECT query only. For each SQL LIMIT 1000 rows.\n"
            ans_pre += prompt_all.get_prompt_convert_symbols()
            ans_pre += "Use fuzzy query: WHERE str LIKE \"%target_str%\", don't directly match strings and avoid using REGEXP.\n" # bq085, local099
            ans_pre += "When faced with string matching for a topic, first retrieve every column related to the topic. e.g. A single Python 2 specific question on Stack Overflow. SQL: SELECT * FROM table WHERE (\"title\" iLIKE '%Python%2%' OR \"body\" iLIKE '%Python%2%' OR \"tags\" iLIKE '%python-2.%') Note for match string phase, e.g. meat lovers, you should use % to replace space. e.g. ILKIE %meat%lovers%.\n" 
            
            ans_pre += "When using TO_DATE() function, filter NULL: WHERE TRY_TO_DATE(filing_date, 'YYYYMMDD') IS NOT NULL;\n"
            ans_pre += "For time-related queries, given the variety of formats such as UNIX timestamp, ISO 8601, and DATETIME, avoid using time functions unless you are certain of the specific format being used.\n"
            
            ans_pre += "When generating SQL, be aware of quotation matching: 'Vegetarian\"; You sometimes match \' with \" which may cause an error.\n"
            
            ans_pre += "For the keyword in the task that appears in two tables, explore two of them. e.g. Provide the total number of confirmed cases: explore table CONFIRMED_CASES and also SUMMARY which has column \"confirmed\"\n"
            # ans_pre += "If you can get information you want in one table, then there's no need to join another.\n"
            ans_pre += f"You can only use tables in {table_struct}"
            # logger.info(ans_pre)
            
            response_pre = chat_session4o.get_model_response(ans_pre, "sql")
            response_pre_txt = chat_session4o.get_model_response_txt(ans_pre)
            if len(response_pre) == 1:
                response_pre = [query.strip() for query in response_pre[0].strip().split(';') if query.strip()]
            if len(response_pre) < 10:
                ans_pre = ''
                LIMIT -= 3
                print("Few sqls, retry preparation.")
                continue
            results_pre_dic, chat_session4o = execute_sql(response_pre, chat_session4o, logger, max_len=5000)
            sql_count = 0
            for key, value in results_pre_dic.items():
                pre_info += "Query:\n" + key + "\nAnswer:\n" + value
                if isinstance(value, str):
                    sql_count += 1

            if sql_count < len(response_pre) // 2:
                print(f"sql_count: {sql_count}, len(response_pre): {len(response_pre)}. Inadequate preparation, retry preparation.\n")
                pre_info = ''
                LIMIT -= 3
                continue

            if len(pre_info) < 1e5:
                break
            print("Too long, retry preparation.")
            pre_info = ''
            LIMIT -= 3
            # chat_session4o.init_messages()
        print(f"len(pre_info): {len(pre_info)}, chat_session.get_message_len(): {chat_session.get_message_len()}")
        print(f"len(pre_info): {len(pre_info)}, chat_session4o.get_message_len(): {chat_session4o.get_message_len()}")
        if LIMIT <= 0:
            print("Inadequate preparation, skip")
            continue
        

        # answer
        itercount = 0
        e = table_info + response_pre_txt + pre_info
        results_values = []
        results_tables = []
        complete_save_path = search_directory + "/" + save_path
        complete_save_path_sql = search_directory + "/" + sql_save_path
        e += "Task: " + task + "\n"+'\nPlease answer only one complete SQL in snowflake dialect in ```sql``` format.\nUsage example: SELECT S."Column_Name" FROM {Project Name}.{Database Name}.{Table_name} (ensure all column names are enclosed in double quotations)\n'
        e += f"Follow the answer format like: {response_csv}.\n"
        e += "Here are some useful tips for answering:\n"
        e += "When calculating distances between two geometries, use `ST_MakePoint(x, y)` to make a point and `ST_Distance(geometry1 GEOMETRY, geometry2 GEOMETRY)` to compute. No need to convert from meters to miles unless requested. Don't use Haversine like 2 * 6371000 * ASIN(...), use ST_DISTANCE for more precise results.\n"
        e += "Please refrain from adding any conditions that are not explicitly specified in the task.\n" # bq398
        e += prompt_all.get_prompt_list_all_tables(table_struct)
        e += prompt_all.get_prompt_fuzzy_query()
        e += "Be careful one country may have different names in different columns in a database.\n"
        #  However, if the task is to match string regardless of upper and lowercase, use ILIKE.
        e += "Don't be disturbed by extra description in the task. e.g. When searching tags about Android development, example tags such as 'android-layout', 'android-activity', 'android-intent', and others. In this case, the condition of string matching should be `\"tags\" ILIKE %android%` rather than matching examples.\n"
        e += "When handling TO_TIMESTAMP_NTZ conversions, use query like: SELECT CASE WHEN \"date\" >= 1e15 THEN TO_TIMESTAMP_NTZ(\"date\" / 1000000) WHEN \"date\" >= 1e12 THEN TO_TIMESTAMP_NTZ(\"date\" / 1000) ELSE TO_TIMESTAMP_NTZ(\"date\") END AS parsed_timestamp FROM my_table;\n"
        e += "Be careful of information in nested JSON columns. e.g.1. When it comes to active users, it refers to has engagement_time_msec parameter rather than directly counting users. So the right query is: SELECT DISTINCT USER_PSEUDO_ID FROM all_user_activity, LATERAL FLATTEN(input => event_params) AS flattened_params WHERE flattened_params.value:key = 'engagement_time_msec'\n"
        e += "e.g. When it comes to top-selling product, you should pay attention to hits2.value:\"eCommerceAction\":\"action_type\"::INTEGER = 6 where 6 means sold product.\n"
        e += "When using ORDER BY xxx DESC, add NULLS LAST to exclude null records: ORDER BY xxx DESC NULLS LAST.\n"
        e += prompt_all.get_prompt_filter_null()
        e += "When counting for rows of a column, ensure they are distinct: SELECT COUNT(DISTINCT col_name) FROM table;\n"
        # e += "When the condition is superlative, use ROW_NUMBER() to rank first and get rn=1.\n"
        e += prompt_all.get_prompt_decimal_places()
        # e += "For complex tasks, use CTEs to think step by step.\n"
        if "duration" in task and "quantile" in task:
            e += prompt_all.get_prompt_quantile_duration()
        if "’" in task:
            e += prompt_all.get_prompt_convert_symbols()
        # if args.use_CoT:
        #     step = 1
        #     prompt_step = e
        #     prompt_step_info = "Let's approach the task step by step. For each step, write a SQL query (subquery of the answer) format like ```sql``` and review the results. If the results are reasonable, proceed to the next step until the task is complete."
        #     prompt_step_info += "Don't output the whole results at once! Break it down into steps, using one SELECT query per step. Consider using WITH to link the previous steps together.\n"
        #     prompt_step_info += "e.g. Step 1: WITH name1 AS (SELECT \"column\" FROM PROJECT.DATABASE.TABLE WHERE ...) SELECT * FROM name; For other steps: Step k: WITH name1 AS (...), name2 AS (...) ... namek AS (...) SELECT * FROM namek;"
        #     prompt_step = e + prompt_step_info + f"Step {step}:\n"
        #     past_steps = ""
        #     while step < 10:               
        #         response_step = chat_session.get_model_response(prompt_step, "sql")
        #         table_step, chat_session = execute_sql(response_step, chat_session)
        #         sql, table, chat_session = self_correct(sql, table_step, chat_session, max_len=1000)
        #         sql, table, chat_session = self_check(sql, table, chat_session)
        #         past_steps += f"Step {step}: SQL: {sql}\n"
        #         prompt_step = prompt_step_info + "Completed steps:\n" + past_steps
        #         step += 1
        #         prompt_step += f"Step {step}:\n"
        #         if self_check(sql, table, chat_session, response_csv) == "A":
        #             break
        #     e = 0

        # self-refine
        error_rec = []
        while itercount < args.max_iter:
            logger.info(f"itercount: {itercount}")
            logger.info(e)
            if e == 0:
                e = f"Please check the answer again by reviewing {task}, reviewing Relevant Tables and Columns and Possible Conditions and then give the final SQL query. Don't output other queries. If you think the answer is right, just output the current SQL.\n" 
                e += prompt_all.get_prompt_decimal_places()
                e += f"The answer format should be like: {response_csv} The answer should match the number of rows, the column name of the format and the filled values in the format (e.g. filled year or month). Don't output extra rows or nested rows!\n"
                e += "Current snswer: \n"
                with open(complete_save_path) as f:
                    csv_data = f.readlines()
                    csv_data_str = ''.join(csv_data)
                e += csv_data_str if len(csv_data_str) < 1e4 else hard_cut(csv_data_str, 10000)
                e += f"Current sql:\n{response}"
                if "first" in csv_data_str.lower() and "name" in csv_data_str.lower():
                    e += prompt_all.get_prompt_name()
                if '"""' in csv_data_str:
                    e += 'Please remove """ in results.\n'
                # e += "Remember the task is :" + task
                
                # if response.startswith("WITH"):
                #     e += get_cte_info(response)
                csv_buffer = StringIO(csv_data_str)
                df_csv = pd.read_csv(csv_buffer)
                df_csv_copy = df_csv.copy()
                for col in df_csv.select_dtypes(include=['float']):
                    df_csv_copy[col] = df_csv[col].round(2)
                csv_data_str_round2 = df_csv_copy.to_string()
                if get_values_from_table(csv_data_str_round2) not in results_values:
                    if not ((df_csv == 0) | (df_csv == "")).all().any():
                        # if len(format_csv.split('\n')) == len(csv_data_str.split('\n')):
                            results_values.append(get_values_from_table(csv_data_str_round2))
                            results_tables.append(csv_data_str)
                    else:
                        e += "Some columns are empty results. Please correct it.\n"
                else:
                    with open(complete_save_path_sql, "w") as f:
                        f.write(response)
                    break
                logger.info(f"results: \n{csv_data_str}\n")
                if args.save_all_results:
                    save_path = save_path[:-4] + str(itercount) + save_path[-4:]
            if hasattr(e, 'msg'):
                e = f"Input sql:\n{response}\nThe error information is:\n" + e.msg + "\nPlease correct it and output only 1 complete SQL query."
            if e == "No data found for the specified query.\n":
                e = f"Input sql:\n{response}\nThe error information is:\n No data found for the specified query.\n"
            if itercount > 0:
                if "LEFT JOIN" in response:
                    e += "Be careful of using JOIN and LEFT JOIN. JOIN: The length of the result corresponds to the intersection of the two tables based on the ON condition. LEFT JOIN: The result will include all rows from the left table.\n"
                    e += "e.g. 1 Assess whether different genetic variants affect the log10-transformed TP53 expression levels in TCGA-BRCA samples using sequencing and mutation data: SELECT COUNT(*) FROM (SELECT * FROM expression_data e JOIN mutation_data m ON e.\"case_barcode\" = m.\"case_barcode\"); In this case we just need their intersection to count specific samples, so we shouldn't use LEFT JOIN." # local131, bq150, local099
                    e += "e.g. 2 List each musical style with the number of times it appears as a preference. You should write a query like: SELECT * FROM \"MUSICAL_STYLES\" s JOIN \"MUSICAL_PREFERENCES\" p ON s.\"StyleID\" = p.\"StyleID\", for the task is to get the intersection of style and preference.\n"
                if "Google Analytics" in table_info:
                    e += "Be careful of information in nested JSON columns. e.g.1. When it comes to active users in a date range, it refers to has engagement_time_msec parameter rather than directly counting users. So the right query is: SELECT DISTINCT USER_PSEUDO_ID FROM all_user_activity, LATERAL FLATTEN(input => event_params) AS flattened_params WHERE flattened_params.value:key = 'engagement_time_msec' rather than directly count number in or not in the date range.\n"
                    e += "e.g.2 When it comes to top-selling product, you should pay attention to hits2.value:\"eCommerceAction\":\"action_type\"::INTEGER = 6 where 6 means sold product.\n"
                if "ST_GEOGPOINT" in response or "ST_MAKEGEOGRAPHYPOINT" in response or "2 * 6371000 * ASIN" in response:
                    e += "When calculating distances between two geometries, use `ST_MakePoint(x, y)` to make a point and `ST_Distance(geometry1 GEOMETRY, geometry2 GEOMETRY)` to compute. No need to convert from meters to miles unless requested. Don't use Haversine like 2 * 6371000 * ASIN(...), use ST_DISTANCE for more precise results.\n"
                if "ORDER BY" in response and "DESC" in response:
                    e += "When using ORDER BY xxx DESC, add NULLS LAST to exclude null records: ORDER BY xxx DESC NULLS LAST.\n"
                if '"day_of_week" IN (' in response:
                    e += "For day_of_week, 1=Sunday and 7=Saturday.\n"
                if any(keyword in response for keyword in CONDITION_OMIT_TABLES):
                    e += prompt_all.get_prompt_list_all_tables(table_struct)
                if "duration" in task and "quantile" in task:
                    e += prompt_all.get_prompt_quantile_duration()
                if "GENERATOR" in response:
                    e += prompt_all.get_prompt_generator()
                if any(keyword in response for keyword in ["ST_INTERSECTS", "ARRAY_", "ST_OVERLAPS", "CARDINALITY", "OBJECT_AGG"]):
                    e += prompt_all.get_prompt_ST_INTERSECTS_FUNC()
                if "trip duration" in task:
                    e += prompt_all.get_prompt_trip_duration()
                if "FULL OUTER JOIN" in response:
                    e += prompt_all.get_prompt_full_outer_join()
                if "ILIKE" in response or ("LIKE" in response and "%" in response):
                    e += prompt_all.get_prompt_fuzzy_query()
                # if "NPM" in task and "packages" in task:
                #     e += prompt_all.get_prompt_NPM_package()
                logger.info(e)
            response = chat_session.get_model_response(e, "sql")
            logger.info(chat_session.messages[-1]['content'])
            if response == "Exceeded":
                print(response)
                if os.path.exists(complete_save_path):
                    os.remove(complete_save_path)
                break
            
            elif len(response) > 0:
                response_len = [len(i) for i in response]
                response_index = response_len.index(max(response_len))
                response = response[response_index]
                e = execute_sql_snow(response, complete_save_path)
            itercount += 1
            error_rec.append(e)
            if len(error_rec) > 3:
                if len(set(error_rec[-4:])) == 1 and error_rec[-1] == "No data found for the specified query.\n":
                    print("No data found for the specified query, remove file.\n")                    
                    if os.path.exists(complete_save_path):
                        os.remove(complete_save_path)
                    break

        logger.info(f"Total iteration counts: {itercount}")
        if itercount == args.max_iter and not args.save_all_results:

            if args.model_vote:
                if results_tables:
                    if os.path.exists(complete_save_path):
                        with open(complete_save_path) as f:
                            csv_data = f.readlines()
                            csv_data_str = ''.join(csv_data)
                        results_tables.append(csv_data_str)
                    selected_ans = chat_session.get_model_response(f"Here are some candidate answers. The task is: {task}. Please choose one as the correct answer. Provide the output in ```csv``` format: {results_tables}.", "csv")
                    if selected_ans:
                        try:
                            with open(complete_save_path, "w") as file:
                                file.writelines(selected_ans[0])
                        except Exception as e:
                            print(e)
            else:
                if os.path.exists(complete_save_path):
                    os.remove(complete_save_path)
                print("Max Iter, remove file")


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
    parser.add_argument('--model_vote', action="store_true")
    parser.add_argument('--rerun', action="store_true")
    args = parser.parse_args()
    main(args)