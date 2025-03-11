"""
This file contains utility functions for the math_utils module.
"""
import snowflake.connector
import json
from google.cloud import bigquery
from google.oauth2 import service_account
import sqlite3
import pandas as pd
from concurrent.futures import ThreadPoolExecutor
import time
def hard_cut(str_e, length=0):
    if length:
        if len(str_e) > length and not str_e.startswith("Too long, hard cut"):
            str_e = "Too long, hard cut:\n" + str_e[:int(length)]+"\n"
    return str_e

def execute_sql_api(sql_query, save_path=None, api="snowflake", max_len=30000, LIMIT=None, sqlite_path=None):
    def get_rows(cursor):
        rows = []
        current_len = 0
        for row in cursor:
            rows.append(row)
            row_str = str(row)
            if current_len + len(row_str) > max_len:
                break
            current_len += len(row_str)
        return rows
    if LIMIT is not None and "LIMIT" not in sql_query.upper():
        sql_query = sql_query.rstrip('\n;') + " LIMIT 100;\n"
    if api == "snowflake":
        # Load Snowflake credentials
        with open("./snowflake_credential.json") as f:
            snowflake_credential = json.load(f)
        # Execute the SQL query
        try:
            conn = snowflake.connector.connect(
                **snowflake_credential
            )
            cursor = conn.cursor()
            try:
                cursor.execute(sql_query)
                rows = get_rows(cursor)
                columns = [desc[0] for desc in cursor.description]
                df = pd.DataFrame(rows, columns=columns)
                # Check if the result is empty
                if df.empty:
                    return "No data found for the specified query.\n"
                else:
                    # Save or print the results based on the is_save flag
                    if save_path:
                        try:
                            df.to_csv(f"{save_path}", index=False)
                            return 0
                        except Exception as e:
                            print(e)
                    else:
                        return hard_cut(df.to_csv(index=False), max_len)
            except Exception as e:
                # in snowflake, syntax errors, wrong table, column come here in exception
                return "Incorrect SQL Syntax:\n" + str(e)
        except Exception as e:
            print(f"Failed to connect: {str(e)}\n")
            return {str(e)}
        finally:
            if cursor:
                cursor.close()  # Close the cursor manually
            if conn:
                conn.close() 
    elif api == "bigquery":
        bigquery_credential = service_account.Credentials.from_service_account_file("./bigquery_credential.json")
        client = bigquery.Client(credentials=bigquery_credential, project=bigquery_credential.project_id)
        try:
            query_job = client.query(sql_query)
            result_iterator = query_job.result()
            rows = []
            current_len = 0
            for row in result_iterator:
                rows.append(dict(row))
                if current_len > max_len:
                    break
                current_len += len(str(dict(row)))
            df = pd.DataFrame(rows)
            # Check if the result is empty
            if df.empty:
                return "No data found for the specified query.\n"
            else:
                # Save or print the results based on the is_save flag
                if save_path:
                    df.to_csv(f"{save_path}", index=False)
                    return 0
                else:
                    return hard_cut(df.to_csv(index=False), max_len)
        except Exception as e:
            # in bigquery, syntax errors, wrong table, column come here in exception
            return "Incorrect SQL Syntax:\n" + str(e)

    elif api == "sqlite":
        conn = None
        cursor = None
        memory_conn = None
        try:
            uri = f"file:{sqlite_path}?mode=ro"
            conn = sqlite3.connect(uri, uri=True, check_same_thread=False)
            memory_conn = sqlite3.connect(":memory:", check_same_thread=False)
            conn.backup(memory_conn)
            conn.close()
            cursor = memory_conn.cursor()
            cursor.execute(sql_query)
            # Fetch the results
            rows = get_rows(cursor)
            columns = [desc[0] for desc in cursor.description]
            df = pd.DataFrame(rows, columns=columns)

            # Check if the result is empty
            if df.empty:
                return "No data found for the specified query.\n"
            else:
                # Save or print the results based on the is_save flag
                if save_path:
                    try:
                        df.to_csv(f"{save_path}", index=False)
                        return 0
                    except Exception as e:
                        print(e)
                else:
                    return hard_cut(df.to_csv(index=False), max_len)
        except Exception as e:
            # in sqlite, syntax errors, wrong table, column come here in exception
            return "Incorrect SQL Syntax:\n" + str(e)
        finally:
            if cursor:
                cursor.close()  # Close the cursor manually
            if memory_conn:
                memory_conn.close()    # Close the connection manually
    else:
        raise NotImplementedError("Unsupported API\n")
executor = ThreadPoolExecutor(max_workers=200)
def execute_sql_with_timeout(sql_query, save_path=None, api="snowflake", max_len=30000, LIMIT=None, sqlite_path=None, timeout=90):
    future = executor.submit(execute_sql_api, sql_query, save_path, api, max_len, LIMIT, sqlite_path)
    try:
        result = future.result(timeout=timeout)
        return result
    except TimeoutError:
        print(f"{sql_query} Timed out\n")
        return f"{sql_query} Timed out\n"
executor_sf = ThreadPoolExecutor(max_workers=200)
def execute_sql_with_timeout_sf(sql_query, save_path=None, api="snowflake", max_len=30000, LIMIT=None, sqlite_path=None, timeout=30):
    future = executor_sf.submit(execute_sql_api, sql_query, save_path, api, max_len, LIMIT, sqlite_path)
    try:
        result = future.result(timeout=timeout)
        return result
    except TimeoutError:
        print(f"{sql_query} sfTimed out\n")
        return f"{sql_query} sfTimed out\n"


def get_api_name(sql_data):
    if sql_data.startswith("sf"):
        return "snowflake"
    elif sql_data.startswith("local"):
        return "sqlite"
    elif sql_data.startswith("bq") or sql_data.startswith("ga"):
        return "bigquery"
    else:
        raise NotImplementedError("Invalid file name.")

