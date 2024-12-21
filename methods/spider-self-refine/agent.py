from utils import execute_sql_snow, hard_cut
'''
input: sqls
output: results for each sql
'''
def execute_sql(sqls, chat_session, api="snow", max_len=0, save_path=None, get_max=False):
    result_dic = {}
    for sql in sqls:
        if api == "snow":
            results = execute_sql_snow(sql, save_path)
            if isinstance(results, str):
                results = hard_cut(results, max_len)
                result_dic[sql] = results
            # multiple queries
            elif "0A000" in results.msg:
                queries = [query.strip() for query in sqls.strip().split(';') if query.strip()]
                
                for q in queries:
                    result_dic[sql] = execute_sql(q, chat_session)
            else:
                if hasattr(results, 'msg'):
                    corrected_sql, corrected_table, chat_session = self_correct(sql, results, chat_session, max_len=max_len)
                    result_dic[corrected_sql] = corrected_table
        else:
            raise NotImplementedError("Support Snowflake API only.")
    if get_max:
        return max(result_dic.keys(), key=len)
    return result_dic, chat_session
                
def self_correct(sql, error, chat_session, max_len=0):
    while hasattr(error, 'msg'):
        prompt = f"Input sql:\n{sql}\nThe error information is:\n" + error.msg + "\nPlease correct it and output the sql query in ```sql``` format."
        error = chat_session.get_model_response(prompt)[0]
        response_refine_sql, chat_session = self_correct(response_refine_sql, error.msg, chat_session)
        error = execute_sql(response_refine_sql, max_len=max_len, get_max=True)
    corrected_sql, corrected_table = response_refine_sql, error
    return corrected_sql, corrected_table, chat_session

def self_check(sql, table, chat_session, format_restrict=None):
    iter_count = 0
    max_len = 1000

    while iter_count > 5:
        prompt = "Query:\n" + sql + "Result:\n" + table
        if format_restrict:
            prompt += "Format:\n" + format_restrict
        table = hard_cut(table, max_len)
        prompt += "Do you think the result is: A. Reasonable or B. Unreasonable? Please respond with either A or B.\n"
        response_look_results = chat_session.get_model_response(prompt)[0]
        if format_restrict:
            return response_look_results
        if response_look_results == 'A':
            return sql, table, chat_session
        elif response_look_results == 'B':
            prompt += "Your answer is B. Please write a sql query in ```sql``` format to refine it.\n"
            response_refine_sql = chat_session.get_model_response(prompt, "sql")[0]
            response_refine_results = execute_sql(response_refine_sql, api="snow", max_len=max_len, get_max=True)
            sql, table, chat_session = self_correct(sql, response_refine_results, chat_session, max_len=max_len)
        iter_count += 1
    return sql, table, chat_session

