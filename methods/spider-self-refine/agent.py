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
    for sql in sqls:
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
            # elif hasattr(results, 'msg') and "0A000" in results.msg:
            #     queries = [query.strip() for query in sql.strip().split(';') if query.strip()]
                
            #     for q in queries:
            #         result_dic[q] = execute_sql(q, chat_session, max_len=max_len)
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
    prompt = f"Input sql:\n{sql}\nThe error information is:\n" + error.msg if hasattr(error, 'msg') else error + "\nPlease correct it and output only one sql query in ```sql``` format. Don't just analyze without SQL.\n"
    if simplify:
        prompt += "Since output is empty, please simplify some conditions of the past sql.\n"
    if check_again_flag:
        prompt += "Some columns are empty values. Please check it again.\n"
    response = chat_session.get_model_response(prompt, "sql")
    logger.info(chat_session.messages[-1]['content'])
    return response, chat_session

# def self_check(sql, table, chat_session, format_restrict=None):
#     iter_count = 0
#     max_len = 1000

#     while iter_count > 5:
#         prompt = "Query:\n" + sql + "Result:\n" + table
#         if format_restrict:
#             prompt += "Format:\n" + format_restrict
#         table = hard_cut(table, max_len)
#         prompt += "Do you think the result is: A. Reasonable or B. Unreasonable? Please respond with either A or B.\n"
#         response_look_results = chat_session.get_model_response(prompt)[0]
#         if format_restrict:
#             return response_look_results
#         if response_look_results == 'A':
#             return sql, table, chat_session
#         elif response_look_results == 'B':
#             prompt += "Your answer is B. Please write a sql query in ```sql``` format to refine it.\n"
#             response_refine_sql = chat_session.get_model_response(prompt, "sql")[0]
#             response_refine_results = execute_sql(response_refine_sql, api="snow", max_len=max_len, get_max=True)
#             sql, table, chat_session = self_correct(sql, response_refine_results, chat_session, max_len=max_len)
#         iter_count += 1
#     return sql, table, chat_session

def format_answer(prompt_class, table_info, task, chat_session):
    format_prompt = "This is an SQL task. Please provide the simplest possible answer in ```csv``` format like a table and include a brief explanation. Fill the table according to the task description rather than the actual database. For values that cannot be inferred from the task description, use metanames with potential types and conditions, rather than real values.\n"
    format_prompt += "For bool type, just write bool, don't fill with true or false. e.g. Please display the drug id, drug type and withdrawal status. Format: ```csv\ndrug_id,drug_type,hasBeenWithdrawn\npremarin_id,known_drug_type,bool\nhumira_id,known_drug_type,bool```\n"
    format_prompt += prompt_class.get_prompt_decimal_places()
    format_prompt += "Don't ouput extra rows. e.g. When dealing with superlative cases (like highest, maximum, largest, lowest, average total), ensure the result is limited to just one row. Get the fourth highest number of the group. Format: ```csv\nFourth-highest-num,group-name\nxx:int,name:str``` And emphasize only one row.\n"
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
    format_prompt += prompt_class.get_prompt_name()
    format_prompt += "For other cases string should be separate, return both 2 strings. e.g. Ask team name: ```csv\nmarket,name\nstr1,str2```\n When asked for income, don't concatenate income with '$', just output number." # local056
    format_prompt += "If there are some records specified in the task, you should follow and capitalize them. e.g. Task: Give me the number of small, medium and large clothes. Format: ```csv\nSize,Number\nSmall,num1\nMedium,num2\nLarge,num3```\n" # local008
    format_prompt += "For month cases, form format in both month_num and month: ```csv\nMonth_num,Month\n01,Jan\n02,Feb```.\n" # local028
    format_prompt += "For quantile cases, explicitly list each quantile and convince the object to quantile. e.g. 60 minutes trip durations 10 quantiles: Format: ```csv\ntime_range,distance\n00m to 10m,dis1\n10m to 20m,dis2\n...\n50m to 60m,dis3``` Start from 0.\n"
    format_prompt += "If you meet with an ambiguous name in the task that may match 2 columns, feel free to add 2 columns of them. e.g. Tell me the tract code. Tract code may mean geo_id or tract_ce, then format: ```csv\geo_id,tract_ce\nid,code```\n"
    format_prompt += "You can also add a column related to the task. e.g. The month with the highest number. Format: ```csv\nmonth,month_num,number\nstr,int,int```\n"
    format_prompt += "Please output only one format. If there could be 2 tables as the complete answers, return the latter one as format. e.g. Identify the top five states by daily increases. Then, examine the state that ranks fourth overall and identify its top five counties. Format: ```csv\ntop_five_counties,count\ncounty1,count1\ncounty2,count2\ncounty3,count3\ncounty4,count4\ncounty5,count5```In this case, return results of the later one table.\n"
    format_prompt += "If there is any math relationship between columns, you should note it. e.g. Get a number added to the cart, without being purchased in the cart and count of actual purchases. Format: ```csv\nnumber added to the cart, without being purchased in the cart and count of actual purchases,num1,num2,num3``` Note: num1=num2+num3\n"
    format_prompt += "If the value is nonnegative, emphasize this value. e.g. How much higher the average intrinsic value is. Format: ```csv\ndifference\nvalue:float > 0```\n e.g. What is the different between A and B. The different should be nonnegative.\n"
    format_prompt += "Do not output any SQL queries.\n"
    response_csv = chat_session.get_model_response_txt(table_info + "Task: " + task + format_prompt)
    return response_csv, chat_session

def preparation(prompt, LIMIT, prompt_all, table_struct, logger, chat_session4o):
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
        ans_pre += prompt_all.get_prompt_knowledge()
        # logger.info(ans_pre)
        
        response_pre = chat_session4o.get_model_response(ans_pre, "sql")
        response_pre_txt = chat_session4o.messages[-1]['content'][:chat_session4o.messages[-1]['content'].find("```sql")]
        if len(response_pre) == 1:
            response_pre = [query.strip() for query in response_pre[0].strip().split(';') if query.strip()]
        if len(response_pre) < 10:
            ans_pre = ''
            LIMIT -= 5
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
    if "and others" in task:
        e += prompt_all.get_prompt_examples()
    e += "When handling TO_TIMESTAMP_NTZ conversions, use query like: SELECT CASE WHEN \"date\" >= 1e15 THEN TO_TIMESTAMP_NTZ(\"date\" / 1000000) WHEN \"date\" >= 1e12 THEN TO_TIMESTAMP_NTZ(\"date\" / 1000) ELSE TO_TIMESTAMP_NTZ(\"date\") END AS parsed_timestamp FROM my_table;\n"
    e += "Be careful of information in nested JSON columns. e.g.1. When it comes to active users, it refers to has engagement_time_msec parameter rather than directly counting users. So the right query is: SELECT DISTINCT USER_PSEUDO_ID FROM all_user_activity, LATERAL FLATTEN(input => event_params) AS flattened_params WHERE flattened_params.value:key = 'engagement_time_msec'\n"
    e += "e.g. When it comes to top-selling product, you should pay attention to hits2.value:\"eCommerceAction\":\"action_type\"::INTEGER = 6 where 6 means sold product.\n"
    e += "When using ORDER BY xxx DESC, add NULLS LAST to exclude null records: ORDER BY xxx DESC NULLS LAST.\n"
    # e += prompt_all.get_prompt_filter_null()
    e += "When counting for rows of a column, ensure they are distinct: SELECT COUNT(DISTINCT col_name) FROM table;\n"
    # e += "When the condition is superlative, use ROW_NUMBER() to rank first and get rn=1.\n"
    e += prompt_all.get_prompt_decimal_places()
    # e += "For complex tasks, use CTEs to think step by step.\n"
    if "duration" in task and "quantile" in task:
        e += prompt_all.get_prompt_quantile_duration()
    if "’" in task:
        e += prompt_all.get_prompt_convert_symbols()
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
            # e += "Remember the task is :" + task
            
            # if response.startswith("WITH"):
            #     e += get_cte_info(response)
            csv_buffer = StringIO(csv_data_str)
            df_csv = pd.read_csv(csv_buffer).fillna(0)
            df_csv_copy = df_csv.copy()
            for col in df_csv.select_dtypes(include=['float']):
                df_csv_copy[col] = df_csv[col].round(2)
            df_csv_copy_sorted = df_csv_copy.sort_values(by=df_csv_copy.columns[0])
            csv_data_str_round2 = df_csv_copy_sorted.to_string()
            if get_values_from_table(csv_data_str_round2) not in results_values:
                if not ((df_csv == 0) | (df_csv == "")).all().any():
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
            if any(keyword in response for keyword in prompt_all.get_condition_onmit_tables()):
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
            if "and others" in task:
                e += prompt_all.get_prompt_examples()
            if any(keyword in task for keyword in ["start", "end", "time"]):
                e += prompt_all.get_prompt_combine_time_range()
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