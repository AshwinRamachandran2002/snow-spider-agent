"""
This file contains utility functions for the math_utils module.
"""
import snowflake.connector
import json
from google.cloud import bigquery
from google.oauth2 import service_account
import sqlite3
import pandas as pd
import multiprocessing

def hard_cut(str_e, length=0):
    if length:
        if len(str_e) > length and not str_e.startswith("Too long, hard cut"):
            str_e = "Too long, hard cut:\n" + str_e[:int(length)]+"\n"
    return str_e

def execute_sql_api(sql_query, save_path=None, api="snowflake", max_len=30000, sqlite_path=None):

    if api == "snowflake":
        # Load Snowflake credentials
        with open("./snowflake_credential.json") as f:
            snowflake_credential = json.load(f)
        # Execute the SQL query
        with snowflake.connector.connect(**snowflake_credential) as conn:
            with conn.cursor() as cursor:
                try:
                    cursor.execute(sql_query)
                    # Fetch the results
                    results = cursor.fetchall()
                    results = results[:max_len] if len(results) > max_len else results
                    columns = [desc[0] for desc in cursor.description]
                    df = pd.DataFrame(results, columns=columns)

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

    elif api == "bigquery":
        bigquery_credential = service_account.Credentials.from_service_account_file("./bigquery_credential.json")
        client = bigquery.Client(credentials=bigquery_credential, project=bigquery_credential.project_id)
        try:
            query_job = client.query(sql_query)
            result_iterator = query_job.result()
            rows = []
            current_len = 0
            for row in result_iterator:
                if current_len > max_len:
                    break
                current_len += len(str(dict(row)))
                rows.append(dict(row))
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
        try:
            uri = f"file:{sqlite_path}?mode=ro"
            conn = sqlite3.connect(uri, uri=True, timeout=60)
            cursor = conn.cursor()
            cursor.execute("PRAGMA read_uncommitted = true;")
            # TODO: parameter for cache_size
            cursor.execute("PRAGMA cache_size = -422656000;")
            cursor.execute("PRAGMA temp_store = MEMORY;")
            cursor.execute(sql_query)
            # Fetch the results
            results = cursor.fetchall()
            results = results[:max_len] if len(results) > max_len else results
            columns = [desc[0] for desc in cursor.description]
            df = pd.DataFrame(results, columns=columns)

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
            if conn:
                conn.close()    # Close the connection manually
    else:
        raise NotImplementedError("Unsupported API\n")

def execute_sql_with_timeout(sql_query, save_path=None, api="snowflake", max_len=30000, sqlite_path=None, timeout=180):
    def target(result_dict):
        result_dict["output"] = execute_sql_api(sql_query, save_path, api, max_len, sqlite_path)

    manager = multiprocessing.Manager()
    result_dict = manager.dict()
    process = multiprocessing.Process(target=target, args=(result_dict,))
    process.start()
    process.join(timeout)

    if process.is_alive():
        process.kill()
        process.join()
        print(f"{sql_query} Query timed out")
        return "Query timed out"

    return result_dict.get("output", "Query execution failed")

def get_api_name(sql_data):
    if sql_data.startswith("sf"):
        return "snowflake"
    elif sql_data.startswith("local"):
        return "sqlite"
    elif sql_data.startswith("bq") or sql_data.startswith("ga"):
        return "bigquery"
    else:
        raise NotImplementedError("Invalid file name.")

