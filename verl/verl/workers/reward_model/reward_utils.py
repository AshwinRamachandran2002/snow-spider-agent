"""
This file contains utility functions for the math_utils module.
"""
import snowflake.connector
import json
from google.cloud import bigquery
from google.oauth2 import service_account
import sqlite3
import pandas as pd
from concurrent.futures import ThreadPoolExecutor, ProcessPoolExecutor
import threading
import hashlib
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
# executor = ThreadPoolExecutor(max_workers=2048)
# def execute_sql_with_timeout(sql_query, save_path=None, api="snowflake", max_len=30000, LIMIT=None, sqlite_path=None, timeout=300):
#     future = executor.submit(execute_sql_api, sql_query, save_path, api, max_len, LIMIT, sqlite_path)
#     try:
#         result = future.result(timeout=timeout)
#         return result
#     except TimeoutError:
#         print(f"{sql_query} Timed out\n")
#         return f"{sql_query} Timed out\n"

class SqlEnv:
    def __init__(self):
        self.conns = {}
        self.db_lock = threading.Lock()
        self.executor = ThreadPoolExecutor()

    def start_db(self, sqlite_path):
        if sqlite_path not in self.conns:
            uri = f"file:{sqlite_path}?mode=ro"
            conn = sqlite3.connect(uri, uri=True, check_same_thread=False)
                # TODO: locking protocol in backup for multi nodes
            def backup_with_retry(conn, sqlite_path, meta_time_out):
                """
                Attempts to backup the database to memory within a given total timeout (meta_time_out seconds).
                If a "database is locked" error occurs, it will retry until the timeout is exceeded or maximum attempts are reached.
                """
                start_time = time.time()
                max_attempts = 3  # Adjust this value as needed
                attempts = 0

                while time.time() - start_time < meta_time_out and attempts < max_attempts:
                    try:
                        # Create a memory connection with a timeout to wait for the lock to be released.
                        memory_conn = sqlite3.connect(
                            f"file:{sqlite_path.split('/')[-1]}?mode=memory&cache=shared",
                            uri=True, 
                            check_same_thread=False,
                            timeout=5.0  # Wait up to 5 seconds for a lock release
                        )
                        conn.backup(memory_conn)
                        return memory_conn  # Return the memory connection if backup succeeds
                    except sqlite3.OperationalError as e:
                        attempts += 1
                        elapsed = time.time() - start_time
                        remaining = meta_time_out - elapsed
                        print(f"Attempt {attempts}. Remaining time: {remaining:.2f} seconds. Error: {str(e)}")
                        # If there's still time remaining, wait a short while before retrying.
                        if remaining > 0.5:
                            time.sleep(0.5)
                # If the backup wasn't successful within the timeout or max attempts, return None.
                return None
            try:
                memory_conn = backup_with_retry(conn, sqlite_path, 5)
                if memory_conn:
                    self.conns[sqlite_path] = memory_conn
                    conn.close()
                    print(f"Backup succeeded, self.conns.keys(): {self.conns.keys()}")
                else:
                    print("Backup failed after multiple attempts, using the original connection.")
                    self.conns[sqlite_path] = conn
            except Exception as e:
                print(f"Exception during backup: {str(e)}. Using the original connection.")
                self.conns[sqlite_path] = conn

    def close_db(self):
        for conn in self.conns.values():
            conn.close()
        self.conns = {}

    def exec_sql(self, sql_query, save_path=None, api="snowflake", max_len=30000, LIMIT=None, sqlite_path=None):
        cursor = self.conns[sqlite_path].cursor()
        try:
            cursor.execute(sql_query)
        except Exception as e:
            # in sqlite, syntax errors, wrong table, column come here in exception
            return "Incorrect SQL Syntax:\n" + str(e)
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
        try:
            rows = get_rows(cursor)
            columns = [desc[0] for desc in cursor.description]
            df = pd.DataFrame(rows, columns=columns)
        except Exception as e:
            # TODO: bugs here
            print(f"sqlite_path: {sqlite_path}, len(self.conns): {len(self.conns)}, {str(e)}")
            return str(e)

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
        cursor.close()
            
    def execute_sql_with_timeout(self, sql_query, save_path=None, api="sqlite", max_len=30000, LIMIT=None, sqlite_path=None, timeout=5, example_id=None):
        if save_path not in self.conns.keys():
            self.start_db(sqlite_path)
        future = self.executor.submit(self.exec_sql, sql_query, save_path, api, max_len, LIMIT, sqlite_path)
        try:
            result = future.result(timeout=timeout)
            return result
        except TimeoutError:
            print(f"{sql_query} Timed out\n")
            return f"{sql_query} Timed out\n"

    def __del__(self):
        self.close_db()

# executor_sf = ThreadPoolExecutor(max_workers=200)
# def execute_sql_with_timeout_sf(sql_query, save_path=None, api="snowflake", max_len=30000, LIMIT=None, sqlite_path=None, timeout=30):
#     future = executor_sf.submit(execute_sql_api, sql_query, save_path, api, max_len, LIMIT, sqlite_path)
#     try:
#         result = future.result(timeout=timeout)
#         return result
#     except TimeoutError:
#         print(f"{sql_query} sfTimed out\n")
#         return f"{sql_query} sfTimed out\n"


def get_api_name(sql_data):
    if sql_data.startswith("sf"):
        return "snowflake"
    elif sql_data.startswith("local"):
        return "sqlite"
    elif sql_data.startswith("bq") or sql_data.startswith("ga"):
        return "bigquery"
    else:
        raise NotImplementedError("Invalid file name.")

def calculate_md5(input_string):
    md5_obj = hashlib.md5()
    md5_obj.update(input_string.encode('utf-8'))
    return md5_obj.hexdigest()