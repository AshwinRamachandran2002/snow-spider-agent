from utils import execute_sql_snow, hard_cut, get_longest
'''
input: sqls
output: results for each sql
'''
def execute_sql(sqls, chat_session, api="snow", max_len=0, save_path=None, get_max=False):
    result_dic = {}
    for sql in sqls:
        if api == "snow":
            results = execute_sql_snow(sql, save_path)
            if isinstance(results, str) and results != "No data found for the specified query.\n":
                results = hard_cut(results, max_len)
                result_dic[sql] = results
            # multiple queries
            # elif hasattr(results, 'msg') and "0A000" in results.msg:
            #     queries = [query.strip() for query in sql.strip().split(';') if query.strip()]
                
            #     for q in queries:
            #         result_dic[q] = execute_sql(q, chat_session, max_len=max_len)
            else:
                print(f"Solving err: {results}")
                max_iter = 3
                simplify = False
                while hasattr(results, 'msg') or results == "No data found for the specified query.\n":
                    if max_iter == 0:
                        break
                    if results == "No data found for the specified query.\n":
                        simplify = True
                    corrected_sql, chat_session = self_correct(sql, results, chat_session, max_len=max_len, simplify=simplify)
                    if not corrected_sql:
                        results = "No data found for the specified query.\n"
                        break
                    corrected_sql = get_longest(corrected_sql)
                    results = execute_sql_snow(corrected_sql)
                    max_iter -= 1
                    simplify = False
                if not hasattr(results, 'msg') and results != "No data found for the specified query.\n":
                    print("Corrected.")
                else:
                    print("Max iter, failed to correct.")
                    results = results.msg if hasattr(results, 'msg') else results
                result_dic[corrected_sql] = hard_cut(results, max_len)
        else:
            raise NotImplementedError("Support Snowflake API only.")
    if get_max:
        return max(result_dic.keys(), key=len)
    return result_dic, chat_session
                
def self_correct(sql, error, chat_session, max_len=0, simplify=False):
    # while hasattr(error, 'msg'):
    prompt = f"Input sql:\n{sql}\nThe error information is:\n" + error.msg if hasattr(error, 'msg') else error + "\nPlease correct it and output one sql query in ```sql``` format."
    if simplify:
        prompt += "Since output is empty, please write a simpler sql query.\n"
    response = chat_session.get_model_response(prompt, "sql")
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

