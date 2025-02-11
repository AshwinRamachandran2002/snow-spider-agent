from utils import execute_sql_api, hard_cut, get_values_from_table, search_file, get_api_name, get_table_info
from reconstruct_data import remove_digits, compress_ddl
import numpy as np
import pandas as pd
from io import StringIO
import os
import ast
import re
import csv
from tqdm import tqdm

'''
input: sqls
output: results for each sql
'''
def execute_sql(sqls, chat_session, logger, api="snowflake", max_len=0, save_path=None, get_max=False, sqlite_path=None):
    result_dic = {}
    error_rec = []
    while sqls:
        sql = sqls[0]
        sqls = sqls[1:]
        check_again_flag = False
        results = execute_sql_api(sql, save_path, api=api, max_len=max_len, sqlite_path=sqlite_path)
        try:
            if not results.startswith("Too long") and results != "No data found for the specified query.\n":
                df_csv = StringIO(results)
                df_csv = pd.read_csv(df_csv).fillna(0)
                if ((df_csv == 0) | (df_csv == "")).all().any():
                    check_again_flag = True
        except:
            pass
        if isinstance(results, str) and results != "No data found for the specified query.\n" and not check_again_flag:
            # results = hard_cut(results, max_len)
            result_dic[sql] = results
            chat_session.messages.append({"role": "user", "content": f"SQL:\n{sql}\nResults:\n{results}"})
            logger.info(chat_session.messages[-1]['content'])
        else:
            # print(f"Solving err: {results}")
            max_iter = 3
            simplify = False
            corrected_sql = None
            while not isinstance(results, str) or results == "No data found for the specified query.\n" or check_again_flag:
                if max_iter == 0:
                    break
                if results == "No data found for the specified query.\n":
                    simplify = True
                corrected_sql, chat_session = self_correct(sql, results, chat_session, logger, max_len=max_len, simplify=simplify, check_again_flag=check_again_flag)
                check_again_flag = False
                if not isinstance(corrected_sql, list) or corrected_sql == []:
                    results = "Empty. No data found for the specified query.\n"
                    break
                corrected_sql = corrected_sql[0]
                results = execute_sql_api(corrected_sql, api=api, max_len=max_len, sqlite_path=sqlite_path)
                max_iter -= 1
                simplify = False
            if isinstance(results, str) and results != "No data found for the specified query.\n":
                # print("Corrected.\n")
                error_rec.append(1)
                response = chat_session.get_model_response(f"Please correct other sqls if they have similar errors: {sqls}. For each SQL, answer in ```sql``` format.\n", "sql")
                if isinstance(corrected_sql, list) and corrected_sql != []:
                    response_sql = []
                    for s in response:
                        try:
                            queries = [query.strip() for query in s.strip().split(';') if query.strip()]
                            response_sql += queries
                        except:
                            pass
                    if len(response_sql) >= len(sqls):
                        sqls = response_sql
            else:
                # print("Max iter, failed to correct.\n")
                error_rec.append(0)
                results = str(results) if not isinstance(results, str) else results
            if len(error_rec) > 5 and sum(error_rec[-5:]) == 0:
                return result_dic, chat_session
            if not corrected_sql:
                # print(f"Results: {results}")
                # print("No corrected_sql, skip")
                continue
            result_dic[corrected_sql] = results
            chat_session.messages.append({"role": "user", "content": f"SQL:\n{corrected_sql}\nResults:\n{results}"})
            logger.info(chat_session.messages[-1]['content'])
    if get_max:
        return max(result_dic.keys(), key=len)
    return result_dic, chat_session

def self_correct(sql, error, chat_session, logger, max_len=0, simplify=False, check_again_flag=False):
    prompt = f"Input sql:\n{sql}\nThe error information is:\n" + str(error) if not isinstance(error, str) else error + "\nPlease correct it based on previous context and output only one sql query in ```sql``` format. Don't just analyze without SQL or output several SQLs.\n"
    if simplify:
        prompt += "Since the output is empty, please simplify some conditions of the past sql.\n"
    if check_again_flag:
        prompt += "Some columns are empty values. Please check it again.\n"
    response = chat_session.get_model_response(prompt, "sql")
    logger.info(chat_session.messages[-1]['content'])
    return response, chat_session

def format_answer(prompt_class, table_info, task, chat_session):
    format_prompt = "This is an SQL task. Please provide the simplest possible answer format in ```csv``` format like a table and include a brief explanation.\n"
    
    format_prompt += "If there are some records specified in the task, you should follow and capitalize them and note answering in the order. e.g. Task: Give me the number of small, medium and large clothes. Format: ```csv\nSize,Number\nSmall,num1\nMedium,num2\nLarge,num3\n(Attention: answer in this order)```\n If not specified, just fill with the metaname and its data type. e.g. Provide the names and ranks of faculty. Format: ```csv\nName,Rank\nname1:str,rank1:str\nname2:str,rank2:str\n...``` In this case, list 2 rows with '...' if you don't know how many rows will be. Don't fill values like 'Professor', 'AP' that you inferred.\n"
    format_prompt += "For bool type, don't fill true or false. e.g. Please display the drug id, drug type and withdrawal status. Format: ```csv\ndrug_id,drug_type,hasBeenWithdrawn\nid1:int,type1:str,status1:bool\nid2:int,type2:str,status2:bool\n...```\n"

    format_prompt += "Don't ouput extra rows. e.g. When dealing with superlative cases (like highest, maximum, largest, lowest, average total, most), ensure the result is limited to just one row and emphasize it in parentheses. e.g. Get the fourth highest number of the group. Format: ```csv\nFourth-highest-num,group-name\nnum:int,name:str\n(Attention: answer in one row)```\n"
    format_prompt += "e.g. Calculate the value between A and B. You should only focus on the value. e.g. Calculate the chi-squared statistic. Format: ```csv\nchi-squared value\nv1:float\n(Attention: answer in one row)```\n"
    format_prompt += "For superlative cases with limited rows more than 1, also note the number. e.g. Most purchased other products for the three months starting from November 2020. Format: ```csv\nMonth,Product_Name,Quantity\nNov-2020,product1:str,quantity1:int\nDec-2020,product1:str,quantity1:int\nJan-2021,product1:str,quantity1:int\n(Attention: answer in three rows)```\n"

    format_prompt += "For coordinate-related cases, use POINT(longitude latitude). e.g. Including its travel coordinates and the cumulative travel distance at each point. Format: ```csv\ngeom,cumulative_distance\nPOINT(longitude1 latitude1),distance1:int\nPOINT(longitude2 latitude2),distance2:int\n...```\n"
    
    format_prompt += "For task asking percentage or rate values, omit the '%' symbol and retain only the numeric value in [0, 100]. Otherwise, for portion, proportion, answer a float number < 1.\n"
    
    format_prompt += "Columns are for features and rows are for records. e.g. When answering Wages Growth Rate and Inflation, the format should be ```csv\nWage_growth_rate,Inflation_rate\nwage:0<=float<=100,inflation:0<=float<=100```, not ```csv\nMetric,Rate\nGrowth Rate,rate1:0<=float<=100\nInflation,rate2:0<=float<=100```\n"
    format_prompt += "If there are multiple names for one feature, you should split them to different columns, not adding rows. e.g. Get scores of team A vs team B with period and description. Format: ```csv\nscore_a,score_b,period,description\nscore_a:float,score_b:float,period,description:str``` e.g. Number of distinct active and closed bike share stations for each year 2013 and 2014. Format: ```csv\nYear,Number_of_Stations_active,Number_of_Stations_active\n2013,num_active:int,num_closed:int\n2014,num_active:int,num_closed:int```\n"

    format_prompt += "For tasks about distances, no need to convert from meters to miles or km unless requested. In this case, note meters in the format: ```csv\ntotal_distance_meters\ndist:float```\n"

    format_prompt += prompt_class.get_prompt_name()
    
    format_prompt += "For other cases string should be separate, return both 2 strings and don't concatenate them. e.g. Asked team name, there may be team_name and market_name that match: ```csv\nmarket_name,team_name\nstr1,str2```\n When asked for income, don't concatenate income with '$', just output numbers.\n"
    
    format_prompt += "For month cases, form format in both month_num and month: ```csv\nMonth_num,Month\n01,Jan\n02,Feb```.\n"

    format_prompt += "For quantile cases, explicitly list each quantile and convince the object to quantile. e.g. 60 minutes trip durations 10 quantiles: Format: ```csv\ntime_range,distance\n00m to 10m,dis1\n10m to 20m,dis2\n...\n50m to 60m,dis3``` Start from 0.\n"
    
    format_prompt += "If you meet with an ambiguous name in the task that may match 2 columns, feel free to add 2 columns (like name and name_id) of them. e.g. Tell me the tract code. Tract code may mean geo_id or tract_ce, then format: ```csv\geo_id,tract_ce\nid,code``` e.g. Which products were picked for order. Format: ```csv\nproduct_id,product_name,average_units_picked_per_batch\nproduct_id1:int,product_name1:str,average_units1:float\nproduct_id2:int,product_name2:str,average_units2:float\n...```\n"

    format_prompt += "Please output only one format. If there could be 2 tables as the complete answers, return the latter one as format. e.g. Identify the top five states by daily increases. Then, examine the state that ranks fourth overall and identify its top five counties. Format: ```csv\ntop_five_counties,count\ncounty1:str,count1:int\ncounty2:str,count2:int\ncounty3:str,count3:int\ncounty4:str,count4:int\ncounty5:str,count5:int```In this case, return results of the later one table. Also don't concatenate 'county' after county name.\n"
    
    format_prompt += "If the value is nonnegative, emphasize this value. e.g. How much higher the average intrinsic value is. Format: ```csv\higher\nvalue:float > 0``` e.g. What is the difference between A and B. The difference should be nonnegative. Format: ```csv\ndifference\nvalue:float > 0```\n"
    
    format_prompt += "Do not output any SQL queries.\n"
    response_csv = chat_session.get_model_response_txt(table_info + "Task: " + task + format_prompt)
    return response_csv, chat_session

def preparation(prompt, LIMIT, prompt_all, table_struct, logger, chat_session4o, api="snowflake", sqlite_path=None):
    pre_info = ''
    ans_pre = prompt
    while LIMIT > 0:

        ans_pre += f"Consider which tables and columns are relevant to the task. Answer like: `column name`: `potential usage`. And also conditions that may be used. Then write at least 10 {api} SQL queries for simple to complex ones like {prompt_all.get_prompt_dialect_basic(api)} in ```sql``` format to have an understanding of values in related columns.\n"
        ans_pre += "Each query should be different. Don't use CTEs and don't query about any SCHEMA or checking data types. You can write SELECT query only. Try to use DISTINCT. For each SQL LIMIT 100 rows.\n"

        ans_pre += prompt_all.get_prompt_dialect_nested(api)
                
        ans_pre += prompt_all.get_prompt_convert_symbols()
        
        ans_pre += prompt_all.get_prompt_dialect_string_matching(api)
        
        ans_pre += "For time-related queries, given the variety of formats, avoid using time converting functions unless you are certain of the specific format being used.\n"
        
        ans_pre += "When generating SQLs, be aware of quotation matching: 'Vegetarian\"; You sometimes match \' with \" which may cause an error.\n"

        ans_pre += f"You can only use tables in {table_struct}"
        
        ans_pre += prompt_all.get_prompt_knowledge()

        response_pre = chat_session4o.get_model_response(ans_pre, "sql")
        response_pre_txt = chat_session4o.messages[-1]['content']
        if not isinstance(response_pre, list):
            LIMIT -= 5
            continue
        if len(response_pre) == 1:
            response_pre = [query.strip() for query in response_pre[0].strip().split(';') if query.strip()]
        if len(response_pre) < 10:
            ans_pre = prompt
            LIMIT -= 5
            print("Few sqls, retry preparation.")
            continue
        results_pre_dic, chat_session4o = execute_sql(response_pre, chat_session4o, logger, api=api, max_len=5000, sqlite_path=sqlite_path)
        sql_count = 0
        for key, value in results_pre_dic.items():
            pre_info += "Query:\n" + key + "\nAnswer:\n" + str(value)
            if isinstance(value, str):
                sql_count += 1

        if sql_count < len(response_pre) // 2:
            print(f"sql_count: {sql_count}, len(response_pre): {len(response_pre)}. Inadequate preparation, retry preparation.\n")
            pre_info = ''
            LIMIT -= 10
            continue

        if len(pre_info) < 1e5:
            break
        print("Too long, retry preparation.")
        pre_info = ''
        LIMIT -= 5
    return pre_info, response_pre_txt, LIMIT, chat_session4o

def schema_linking(dictionaries, task_dict, example_path, chat_session_sl):
    for eg_id in tqdm(dictionaries):
        api = get_api_name(eg_id)
        if api == "snowflake":
            task = task_dict[eg_id]
            table_info = get_table_info(example_path, eg_id, api)
            table_struct = table_info[table_info.find("The table structure information is "):]

            prompt = f"Table information: {table_info}\nTask: {task}\nConsider which tables are related to the task. Remove unnecessary tables in {table_struct} and answer table names in ```python``` format in a list.\n"
            table_struct_response = chat_session_sl.get_model_response(prompt, "python")
            table_names_no_digit = [remove_digits(s) for s in ast.literal_eval(table_struct_response[0])]
            ddl_paths = search_file(os.path.join(example_path, eg_id), "DDL.csv")
            
            for ddl_path in ddl_paths:
                temp_file = ddl_path.replace("DDL.csv", "DDL_tmp.csv")
                with open(ddl_path, "r", newline="", encoding="utf-8", errors="ignore") as infile, \
                    open(temp_file, "w", newline="", encoding="utf-8", errors="ignore") as outfile:
                    
                    reader = csv.reader(infile)
                    writer = csv.writer(outfile)

                    header = next(reader)
                    writer.writerow(header)

                    for row in reader:
                        if remove_digits(row[0]) in table_names_no_digit:
                            writer.writerow(row)

                os.replace(temp_file, ddl_path)
        else:
            raise NotImplementedError()

    compress_ddl(example_path)

def self_refine(args, logger, task, prompt_all, response_csv, search_directory, save_path, sql_save_path, table_struct, table_info, response_pre_txt, pre_info, chat_session, api="snowflake", sqlite_path=None):
    itercount = 0
    e = table_info + "Begin Exploring Related Columns\n" + response_pre_txt + pre_info + "End Exploring Related Columns\n"
    results_values = []
    results_tables = []
    complete_save_path = search_directory + "/" + save_path
    complete_save_path_sql = search_directory + "/" + sql_save_path
    e += "Task: " + task + "\n"+f'\nPlease answer only one complete SQL in {api} dialect in ```sql``` format.\n'
    e += f'Usage example: {prompt_all.get_prompt_dialect_basic(api)}\n'
    e += f"Follow the answer format like: {response_csv}.\n"
    e += "Here are some useful tips for answering:\n"
    
    e += prompt_all.get_prompt_dialect_list_all_tables(table_struct, api)
    e += prompt_all.get_prompt_fuzzy_query()

    if api == "snowflake":
        e += "When using ORDER BY xxx DESC, add NULLS LAST to exclude null records: ORDER BY xxx DESC NULLS LAST.\n"
    e += "When using ORDER BY, if there are duplicate values in the primary sort column, sort by an additional column as a secondary criterion."

    e += prompt_all.get_prompt_decimal_places()

    if "> 0" in response_csv:
        e += "You need to follow the format's positive signs.\n"

    # Specific prompts
    e += "Be careful of information in nested columns. e.g. When it comes to completed purchase, `hits.eCommerceAction.action_type` Indicates the type of ecommerce action and '6' represents completed purchases.\n"
    e += "Be careful one country may have different country_name and country_region in different columns in a database.\n"
    e += "Don't be misled by examples. For instance, a question related to Android development on StackOverflow might include tags like 'android-layout,' 'android-activity,' or 'android-intent.' However, you should not limit your analysis to just these three tags; instead, consider all tags related to Android: \"tags\" LIKE '%android%'.\n"
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
                e += 'Please remove """ in results. Use CAST: CAST(column_name AS STRING).\n'

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
                    e += f"Values {nested_val} are nested. Please correct them. e.g. Transfer '[\nA,\n B\n]' to 'A, B'.\n"
                elif not ((df_csv == 0) | (df_csv == "")).all().any():
                    # if len(format_csv.split('\n')) == len(csv_data_str.split('\n')):
                        results_values.append(get_values_from_table(csv_data_str_round2))
                        results_tables.append(csv_data_str)
                else:
                    empty_columns = df_csv.columns[((df_csv == 0) | (df_csv == "")).all()].to_list()
                    e += f"Empty results in Column {empty_columns}. Please correct them.\n"
            else:
                with open(complete_save_path_sql, "w") as f:
                    f.write(response)
                break
            logger.info(f"results: \n{csv_data_str}\n")
            if args.save_all_results:
                save_path = save_path[:-4] + str(itercount) + save_path[-4:]
        if not isinstance(e, str):
            e = f"Input sql:\n{response}\nThe error information is:\n" + str(e) + "\nPlease correct it and output only 1 complete SQL query."
        if e == "No data found for the specified query.\n":
            e = f"Input sql:\n{response}\nThe error information is:\n No data found for the specified query.\n"
        if itercount > 0:
            if api == "snowflake" and "ST_GEOGPOINT" in response or "ST_MAKEGEOGRAPHYPOINT" in response or ("2" in response and "6371" in response and "ASIN" in response):
                e += "When calculating distances between two geometries, use `ST_MakePoint(x, y)` to make a point and `ST_Distance(geometry1 GEOMETRY, geometry2 GEOMETRY)` to compute. No need to convert from meters to miles unless requested. Don't use Haversine like 2 * 6371000 * ASIN(...), use ST_DISTANCE for more precise results.\n"
            if "ORDER BY" in response and "DESC" in response and "DESC NULLS LAST" not in response and api == "snowflake":
                e += "When using ORDER BY xxx DESC, add NULLS LAST to exclude null records: ORDER BY xxx DESC NULLS LAST.\n"
            if 'day_of_week' in response:
                e += "For day_of_week, 1=Sunday and 7=Saturday.\n"
            if any(keyword in response for keyword in prompt_all.get_condition_onmit_tables()):
                e += prompt_all.get_prompt_dialect_list_all_tables(table_struct, api)
            if any(keyword in response for keyword in ["ST_INTERSECTS", "ST_OVERLAPS", "CARDINALITY"]):
                e += prompt_all.get_prompt_ST_INTERSECTS_FUNC()
            if 'contains the word' in task:
                e += prompt_all.get_prompt_no_fuzzy_query()
            if "The percentage should be shown with %" in task:
                e += prompt_all.get_prompt_percentage_shown()
            if "GENERATOR" in response and api == "snowflake":
                e += prompt_all.get_prompt_generator()
            if "> 0" in response_csv:
                e += "You need to follow the format's positive signs.\n"
            logger.info(e)
        response = chat_session.get_model_response(e, "sql")
        logger.info(chat_session.messages[-1]['content'])
        if not isinstance(response, list) or response == []:
            logger.info(response)
            logger.info(chat_session.messages[-1]['content'])
            if os.path.exists(complete_save_path):
                os.remove(complete_save_path)
            break
        
        elif len(response) > 0:
            response_len = [len(i) for i in response]
            response_index = response_len.index(max(response_len))
            response = response[response_index]
            e = execute_sql_api(response, complete_save_path, api=api, max_len=1000000, sqlite_path=sqlite_path)
        itercount += 1
        error_rec.append(e)
        if len(error_rec) > 3:
            if len(set(error_rec[-4:])) == 1 and error_rec[-1] == "No data found for the specified query.\n":
                logger.info("No data found for the specified query, remove file.\n")                    
                if os.path.exists(complete_save_path):
                    os.remove(complete_save_path)
                break

    logger.info(f"Total iteration counts: {itercount}")
    if itercount == args.max_iter and not args.save_all_results:
        if os.path.exists(complete_save_path):
            os.remove(complete_save_path)
        print("Max Iter, remove file")