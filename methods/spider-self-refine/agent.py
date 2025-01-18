from utils import execute_sql_snow, hard_cut, get_longest, get_values_from_table
import numpy as np
import pandas as pd
from io import StringIO
import os

'''
input: sqls
output: results for each sql
'''
def execute_sql(sqls, chat_session, logger, api="snow", max_len=0, save_path=None, get_max=False):
    result_dic = {}
    error_rec = []
    while sqls:
        sql = sqls[0]
        sqls = sqls[1:]
        check_again_flag = False
        if api == "snow":
            results = execute_sql_snow(sql, save_path, max_len=max_len)
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
            # multiple queries
            elif hasattr(results, 'msg') and "0A000" in results.msg:
                queries = [query.strip() for query in sql.strip().split(';') if query.strip()]
                sqls += queries
                continue
            else:
                # print(f"Solving err: {results}")
                max_iter = 3
                simplify = False
                corrected_sql = None
                while hasattr(results, 'msg') or results == "No data found for the specified query.\n" or check_again_flag:
                    if max_iter == 0:
                        break
                    if results == "No data found for the specified query.\n":
                        simplify = True
                    corrected_sql, chat_session = self_correct(sql, results, chat_session, logger, max_len=max_len, simplify=simplify, check_again_flag=check_again_flag)
                    check_again_flag = False
                    if not corrected_sql:
                        results = "Empty. No data found for the specified query.\n"
                        break
                    corrected_sql = get_longest(corrected_sql)
                    results = execute_sql_snow(corrected_sql, max_len=max_len)
                    max_iter -= 1
                    simplify = False
                if not hasattr(results, 'msg') and results != "No data found for the specified query.\n":
                    # print("Corrected.\n")
                    error_rec.append(1)
                    pass
                else:
                    # print("Max iter, failed to correct.\n")
                    error_rec.append(0)
                    results = results.msg if hasattr(results, 'msg') else results
                if len(error_rec) > 5 and sum(error_rec[-5:]) == 0:
                    return result_dic, chat_session
                if not corrected_sql:
                    # print(f"Results: {results}")
                    # print("No corrected_sql, skip")
                    continue
                result_dic[corrected_sql] = results
                chat_session.messages.append({"role": "user", "content": f"SQL:\n{corrected_sql}\nResults:\n{results}"})
                logger.info(chat_session.messages[-1]['content'])
        else:
            raise NotImplementedError("Support Snowflake API only.")
    if get_max:
        return max(result_dic.keys(), key=len)
    return result_dic, chat_session

def execute_sql_step(sqls, chat_session, logger, api="snow", max_len=0, save_path=None, get_max=False):
    result_dic = {}
    error_rec = []
    while sqls:
        sql = sqls[0]
        sqls = sqls[1:]
        check_again_flag = False
        if api == "snow":
            results = execute_sql_snow(sql, save_path, max_len=max_len)
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
            # multiple queries
            elif hasattr(results, 'msg') and "0A000" in results.msg:
                queries = [query.strip() for query in sql.strip().split(';') if query.strip()]
                sqls += queries
                continue
            else:
                # print(f"Solving err: {results}")
                max_iter = 3
                simplify = False
                corrected_sql = None
                while hasattr(results, 'msg') or results == "No data found for the specified query.\n" or check_again_flag:
                    if max_iter == 0:
                        break
                    if results == "No data found for the specified query.\n":
                        simplify = True
                    corrected_sql, chat_session = self_correct(sql, results, chat_session, logger, max_len=max_len, simplify=simplify, check_again_flag=check_again_flag)
                    check_again_flag = False
                    if not corrected_sql:
                        results = "Empty. No data found for the specified query.\n"
                        break
                    corrected_sql = get_longest(corrected_sql)
                    results = execute_sql_snow(corrected_sql, max_len=max_len)
                    max_iter -= 1
                    simplify = False
                if not hasattr(results, 'msg') and results != "No data found for the specified query.\n":
                    # print("Corrected.\n")
                    error_rec.append(1)
                    pass
                else:
                    # print("Max iter, failed to correct.\n")
                    error_rec.append(0)
                    results = results.msg if hasattr(results, 'msg') else results
                if len(error_rec) > 5 and sum(error_rec[-5:]) == 0:
                    return result_dic, chat_session
                if not corrected_sql:
                    # print(f"Results: {results}")
                    # print("No corrected_sql, skip")
                    continue
                result_dic[corrected_sql] = results
                chat_session.messages.append({"role": "user", "content": f"SQL:\n{corrected_sql}\nResults:\n{results}"})
                logger.info(chat_session.messages[-1]['content'])
        else:
            raise NotImplementedError("Support Snowflake API only.")
    if get_max:
        return max(result_dic.keys(), key=len)
    return result_dic, chat_session

def self_correct(sql, error, chat_session, logger, max_len=0, simplify=False, check_again_flag=False):
    # while hasattr(error, 'msg'):
    prompt = f"Input sql:\n{sql}\nThe error information is:\n" + error.msg if hasattr(error, 'msg') else error + "\nPlease correct it based on previous context and output only one sql query in ```sql``` format. Don't just analyze without SQL.\n"
    if simplify:
        prompt += "Since output is empty, please simplify some conditions of the past sql.\n"
    if check_again_flag:
        prompt += "Some columns are empty values. Please check it again.\n"
    response = chat_session.get_model_response(prompt, "sql")
    logger.info(chat_session.messages[-1]['content'])
    return response, chat_session

def format_answer(prompt_class, table_info, task, chat_session):
    format_prompt = "This is an SQL task. Please provide the simplest possible answer format in ```csv``` format like a table and include a brief explanation.\n"
    
    format_prompt += "If there are some records specified in the task, you should follow and capitalize them and note answering in the order. e.g. Task: Give me the number of small, medium and large clothes. Format: ```csv\nSize,Number\nSmall,num1\nMedium,num2\nLarge,num3(Attention: answer in this order)```\n If not specified, just fill with the metaname and its data type. e.g. Provide the names and ranks of faculty. Format: ```csv\nName,Rank\nname1:str,rank1:str\nname2:str,rank2:str\n...``` In this case, list 2 rows with '...' if you don't know how many rows will be. Don't fill values like 'Professor', 'AP' that you inferred.\n"
    format_prompt += "For bool type, just write bool, don't fill true or false. e.g. Please display the drug id, drug type and withdrawal status. Format: ```csv\ndrug_id,drug_type,hasBeenWithdrawn\nid1:int,type1:str,status1:bool\nid2:int,type2:str,status2:bool\n...```\n"

    format_prompt += "Don't ouput extra rows. e.g. When dealing with superlative cases (like highest, maximum, largest, lowest, average total, most), ensure the result is limited to just one row and emphasize it in parentheses. e.g. Get the fourth highest number of the group. Format: ```csv\nFourth-highest-num,group-name\nnum:int,name:str(Attention: answer in one row)```\n"
    format_prompt += "e.g. Calculate the value between A and B. You should only focus on the value. Format: ```csv\nvalue\nv1:float\n(Attention: answer in one row)```\n"

    format_prompt += "For coordinate-related cases, use POINT(longitude latitude). e.g. Including its travel coordinates and the cumulative travel distance at each point. Format: ```csv\ngeom,cumulative_distance\nPOINT(longitude1 latitude1),distance1:int\nPOINT(longitude2 latitude2),distance2:int\n...```\n"
    
    format_prompt += "For task asking percentage or rate values, omit the '%' symbol and retain only the numeric format as xx.xx. Otherwise, for portion, proportion, answer a float number < 1.\n"
    
    format_prompt += "Columns are for features and rows are for records. e.g. When answering Wages Growth Rate and Inflation, the format should be ```csv\nWage_growth_rate,Inflation_rate\nrate:float:xx.xx,rate:float:xx.xx```, not ```csv\nMetric,Rate\nrate1:xx.xx\nrate2:xx.xx```\n"

    format_prompt += "For the Magnificent 7 tech companies, their ticker names are: META, GOOGL (not GOOG), AMZN, MSFT, AAPL, TSLA, NVDA\n"

    format_prompt += "For tasks about distances, no need to convert from meters to miles unless requested.\n"

    format_prompt += prompt_class.get_prompt_name()
    
    format_prompt += "For other cases string should be separate, return both 2 strings and don't concatenate them. e.g. Ask team name: ```csv\nmarket,name\nstr1,str2```\n When asked for income, don't concatenate income with '$', just output numbers.\n"
    
    format_prompt += "For month cases, form format in both month_num and month: ```csv\nMonth_num,Month\n01,Jan\n02,Feb```.\n"

    format_prompt += "For quantile cases, explicitly list each quantile and convince the object to quantile. e.g. 60 minutes trip durations 10 quantiles: Format: ```csv\ntime_range,distance\n00m to 10m,dis1\n10m to 20m,dis2\n...\n50m to 60m,dis3``` Start from 0.\n"
    
    format_prompt += "If you meet with an ambiguous name in the task that may match 2 columns, feel free to add 2 columns of them. e.g. Tell me the tract code. Tract code may mean geo_id or tract_ce, then format: ```csv\geo_id,tract_ce\nid,code```\n"

    format_prompt += "Please output only one format. If there could be 2 tables as the complete answers, return the latter one as format. e.g. Identify the top five states by daily increases. Then, examine the state that ranks fourth overall and identify its top five counties. Format: ```csv\ntop_five_counties,count\ncounty1,count1\ncounty2,count2\ncounty3,count3\ncounty4,count4\ncounty5,count5```In this case, return results of the later one table.\n"
    
    format_prompt += "If the value is nonnegative, emphasize this value. e.g. How much higher the average intrinsic value is. Format: ```csv\higher\nvalue:float > 0``` e.g. What is the difference between A and B. The difference should be nonnegative. Format: ```csv\ndifference\nvalue:float > 0```\n"
    
    format_prompt += "Do not output any SQL queries.\n"
    response_csv = chat_session.get_model_response_txt(table_info + "Task: " + task + format_prompt)
    return response_csv, chat_session

def preparation(prompt, LIMIT, prompt_all, table_struct, logger, chat_session4o, pre_step):
    pre_info = ''
    ans_pre = prompt
    ans_pre = ''
    while LIMIT > 0:

        ans_pre += f"Consider which tables and columns are relevant to the task. Answer like: `column name`: `potential usage`. And also conditions that may be used. Then write at least 10 simple, short, non-nested SQL queries like ```sql\nSELECT DISTINCT \"COLUMN_NAME\" FROM DATABASE.SCHEMA.TABLE WHERE ... ``` (Adjust \"DATABASE\", \"SCHEMA\", and \"TABLE\" to match actual names) in ```sql``` format to have an understanding of values in related columns.\n"
        ans_pre += "Each query should be different. For columns in json nested format: e.g. SELECT t.\"column_name\", f.value::VARIANT:\"key_name\"::STRING AS \"abstract_text\" FROM PATENTS.PATENTS.PUBLICATIONS t, LATERAL FLATTEN(input => t.\"json_column_name\") f; DO NOT directly answer the task and ensure all column names are enclosed in double quotations.\n"
        ans_pre += "For nested columns like event_params, when you don't know the structure of it, first watch the whole column: SELECT f.value FROM table, LATERAL FLATTEN(input => t.\"event_params\") f;\n"
        
        ans_pre += f"Don't use CTEs and don't query about any SCHEMA or checking data types. You can write SELECT query only. For each SQL LIMIT 1000 rows.\n"
        
        ans_pre += prompt_all.get_prompt_convert_symbols()
        
        ans_pre += "Don't directly match strings if you are not convinced. Use fuzzy query first: WHERE str ILIKE \"%target_str%\", and avoid using REGEXP.\n"
        ans_pre += "For string matching, e.g. meat lovers, you should use % to replace space. e.g. ILKIE %meat%lovers%.\n" 
        
        ans_pre += "When using TO_DATE() function, use TRY_TO_DATE: WHERE TRY_TO_DATE(filing_date, 'YYYYMMDD') IS NOT NULL;\n"
        ans_pre += "For time-related queries, given the variety of formats such as UNIX timestamp, ISO 8601, and DATETIME, avoid using time functions unless you are certain of the specific format being used.\n"
        
        ans_pre += "When generating SQLs, be aware of quotation matching: 'Vegetarian\"; You sometimes match \' with \" which may cause an error.\n"

        ans_pre += f"You can only use tables in {table_struct}"
        
        ans_pre += prompt_all.get_prompt_knowledge()

        response_pre = chat_session4o.get_model_response(ans_pre, "sql")
        response_pre_txt = chat_session4o.messages[-1]['content']
        if len(response_pre) == 1:
            response_pre = [query.strip() for query in response_pre[0].strip().split(';') if query.strip()]
        if len(response_pre) < 10:
            ans_pre = ''
            LIMIT -= 5
            print("Few sqls, retry preparation.")
            continue
        if pre_step:
            results_pre_dic, chat_session4o = execute_sql_step(response_pre, chat_session4o, logger, max_len=5000)
        else:
            results_pre_dic, chat_session4o = execute_sql(response_pre, chat_session4o, logger, max_len=5000)
        sql_count = 0
        for key, value in results_pre_dic.items():
            pre_info += "Query:\n" + key + "\nAnswer:\n" + value
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

def self_refine(args, logger, task, prompt_all, response_csv, search_directory, save_path, sql_save_path, table_struct, table_info, response_pre_txt, pre_info, chat_session):
    itercount = 0
    e = table_info + "Begin Exploring Related Columns\n" + response_pre_txt + pre_info + "End Exploring Related Columns\n"
    results_values = []
    results_tables = []
    complete_save_path = search_directory + "/" + save_path
    complete_save_path_sql = search_directory + "/" + sql_save_path
    e += "Task: " + task + "\n"+'\nPlease answer only one complete SQL in snowflake dialect in ```sql``` format.\nUsage example: SELECT S."Column_Name" FROM {Database Name}.{Schema Name}.{Table_name} (ensure all column names are enclosed in double quotations)\n'
    e += f"Follow the answer format like: {response_csv}.\n"
    e += "Here are some useful tips for answering:\n"
    
    e += prompt_all.get_prompt_list_all_tables(table_struct)
    e += prompt_all.get_prompt_fuzzy_query()

    e += "When using ORDER BY xxx DESC, add NULLS LAST to exclude null records: ORDER BY xxx DESC NULLS LAST.\n"

    e += prompt_all.get_prompt_decimal_places()

    if "> 0" in response_csv:
        e += "You need to follow the format's positive and negative signs.\n"
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
        if hasattr(e, 'msg'):
            e = f"Input sql:\n{response}\nThe error information is:\n" + e.msg + "\nPlease correct it and output only 1 complete SQL query."
        if e == "No data found for the specified query.\n":
            e = f"Input sql:\n{response}\nThe error information is:\n No data found for the specified query.\n"
        if itercount > 0:
            if "ST_GEOGPOINT" in response or "ST_MAKEGEOGRAPHYPOINT" in response or "2 * 6371000 * ASIN" in response:
                e += "When calculating distances between two geometries, use `ST_MakePoint(x, y)` to make a point and `ST_Distance(geometry1 GEOMETRY, geometry2 GEOMETRY)` to compute. No need to convert from meters to miles unless requested. Don't use Haversine like 2 * 6371000 * ASIN(...), use ST_DISTANCE for more precise results.\n"
            if "ORDER BY" in response and "DESC" in response:
                e += "When using ORDER BY xxx DESC, add NULLS LAST to exclude null records: ORDER BY xxx DESC NULLS LAST.\n"
            if 'day_of_week' in response:
                e += "For day_of_week, 1=Sunday and 7=Saturday.\n"
            if any(keyword in response for keyword in prompt_all.get_condition_onmit_tables()):
                e += prompt_all.get_prompt_list_all_tables(table_struct)
            if any(keyword in response for keyword in ["ST_INTERSECTS", "ARRAY_", "ST_OVERLAPS", "CARDINALITY", "OBJECT_AGG"]):
                e += prompt_all.get_prompt_ST_INTERSECTS_FUNC()
            if 'contains the word' in task:
                e += prompt_all.get_prompt_no_fuzzy_query()
            if "The percentage should be shown with %" in task:
                e += prompt_all.get_prompt_percentage_shown()
            logger.info(e)
        response = chat_session.get_model_response(e, "sql")
        logger.info(chat_session.messages[-1]['content'])
        if response == "Exceeded":
            logger.info(response)
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
                logger.info("No data found for the specified query, remove file.\n")                    
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