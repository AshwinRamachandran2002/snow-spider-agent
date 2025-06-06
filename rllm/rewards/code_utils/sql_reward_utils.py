import sqlite3
import hashlib
import traceback
import io
import csv
from multiprocessing import Process, Queue, Pool
import time
import os
import multiprocessing
from typing import Optional, Union, List, Set, Any
import sqlglot
import threading
from func_timeout import func_timeout, FunctionTimedOut
import json

def hard_cut(str_e, length=0):
    if length:
        if len(str_e) > length and not str_e.startswith("Too long"):
            str_e = f"Too long, show first {length} chars:\n" + str_e[:int(length)]+"\n"
    return str_e

def warn_if_literal_column_from_result(csv_text: str):
    reader = csv.reader(io.StringIO(csv_text))
    rows = list(reader)

    if not rows or len(rows) < 2:
        return csv_text

    header = [h.strip('"') for h in rows[0]]  # strip triple quotes if present
    data_rows = rows[1:]

    num_cols = len(header)

    for col_idx in range(num_cols):
        col_name = header[col_idx]
        col_values = [row[col_idx].strip('"') for row in data_rows if len(row) > col_idx]

        if all(val == col_name for val in col_values):
            csv_text += (
                f"##Warning##: Column \"\"\"{col_name}\"\"\" contains only '{col_name}'. "
                f"You may have used a missing column name as a string literal."
            )
    return csv_text

def schema_check(schema_json, sqlite_path):
    db_id = sqlite_path.split("/")[-2]
    table_pths = os.path.join("/".join(sqlite_path.split("/")[:-3]), "schema")

    err_rec = []
    candiates = []
    for db in os.listdir(table_pths):
        db_pth = os.path.join(table_pths, db)
        if db.split(".")[0] == db_id:
            with open(db_pth) as f:
                schema_ori = json.load(f)
            for sl_tb in schema_json:
                if sl_tb in schema_ori:
                    for sl_col in schema_json[sl_tb]:
                        if sl_col not in schema_ori[sl_tb]:
                            err_rec.append(f'"{sl_tb}"."{sl_col}"')
                else:
                    err_rec.append(sl_tb)

            for tb in schema_ori:
                for col in schema_ori[tb]:
                    for err in err_rec:
                        if "." in err and col == err.split(".")[-1].strip("\""):
                            candiates.append(f'"{tb}"."{col}"')

    response = ""
    err_rec_str = ", ".join(err_rec)
    cand_str = ", ".join(candiates)
    if err_rec:
        response += f"##Warning## These tables or \"table\".\"column\" do not exist: {err_rec_str}."
        if candiates:
            response += f"\nConsider these candidates: {cand_str}."
    else:
        response += "Schema check passed. All columns exist."

    return response

class SqlEnv:
    def __init__(self):
        self.conns = {}

    def start_db(self, sqlite_path, exe_id, example_id):
        try:
            if sqlite_path not in self.conns:
                # print(f"Start db for {sqlite_path}, current conns: {len(self.conns)}")
                uri = f"file:{sqlite_path}?mode=ro"
                conn = sqlite3.connect(uri, uri=True, check_same_thread=False)
                memory_conn = None
                try:
                    start = time.time()
                    # Create a memory connection
                    memory_conn = sqlite3.connect(
                        f"file:{sqlite_path}?mode=memory&cache=shared",
                        uri=True, 
                        check_same_thread=False
                    )
                    memory_conn.execute("PRAGMA shared_cache = ON;")
                    mid = time.time()
                    conn.backup(memory_conn)
                    end = time.time()
                    self.conns[sqlite_path] = memory_conn
                    conn.close()
                    print(f"Time for create mem db: {mid - start}, time for backup: {end - mid}, sqlite_path: {sqlite_path}, size: {os.path.getsize(sqlite_path)}")
                    
                except Exception as e:
                    print(f"Exception during backup: {str(e)}. sqlite_path: {sqlite_path}. Using the original connection.")
                    # if memory_conn:
                    #     memory_conn.close()
                    # conn.execute("PRAGMA shared_cache = ON;")
                    # self.conns[example_id+exe_id] = conn
            # else:
            #     print("Connect to", example_id+exe_id)
            #     self.conns[example_id+exe_id] = sqlite3.connect(
            #         f"file:{example_id}?mode=memory&cache=shared",
            #         uri=True, 
            #         check_same_thread=False,
            #         timeout=1.0
            #     )

        except Exception as e:
            print("##ERROR## Failed to start DB", e)

    def close_db(self):
        # print("Close DB")
        for key, conn in list(self.conns.items()):
            try:
                if conn:
                    conn.close()
                    # print(f"Connection {key} closed.")
                    del self.conns[key]
            except Exception as e:
                print(f"##ERROR## When closing DB for {key}: {e}")

    def new_con(self, example_id, exe_id, sqlite_path):
        self.conns[example_id+exe_id] = sqlite3.connect(
            f"file:{sqlite_path}?mode=memory&cache=shared",
            uri=True, 
            check_same_thread=False
        )
        # print("Start conn", example_id+exe_id)

    def exec_sql(self, sql_query, exe_id, save_path=None, api="snowflake", max_len=30000, LIMIT=None, sqlite_path=None, example_id=None):
        cursor = self.conns[example_id+exe_id].cursor()
        # Don't add LIMIT
        try:
            cursor.execute(sql_query)
        except Exception as e:
            cursor.close()
            return "##ERROR## Incorrect SQL Syntax: " + str(e) + "\n"
        
        def get_rows(cursor):
            rows = []
            current_len = 0
            for row in cursor:
                row_str = str(row)
                rows.append(row)
                current_len += len(row_str)
                if current_len > max_len:
                    break
            return rows
        
        try:
            rows = get_rows(cursor)
            if cursor.description is None:
                err = f"##ERROR## Not a valid SELECT SQL: {sql_query}\n"
                print(err)
                return err
            columns = [desc[0] for desc in cursor.description]
        except Exception as e:
            print(f"##ERROR## sqlite_path: {sqlite_path}, len(self.conns): {len(self.conns)}, {str(e)}.")
            return "##ERROR## " + str(e) + "\n"
        finally:
            try:
                cursor.close()
            except Exception as e:
                print("##ERROR## Failed to close cursor:", e)

        if not rows:
            return "No data found for the specified query.\n"
        else:
            output = io.StringIO()
            writer = csv.writer(output)
            writer.writerow(columns)
            writer.writerows(rows)
            csv_content = output.getvalue()
            output.close()
            if save_path:
                try:
                    if "##Warning##" not in warn_if_literal_column_from_result(csv_content):
                        with open(save_path, 'w', newline='') as f:
                            f.write(csv_content)
                    return 0
                except Exception as e:
                    print("##ERROR## ", str(e))
                    return str(e) + "\n"
            else:
                return warn_if_literal_column_from_result(hard_cut(csv_content, max_len))
            
    # def execute_sql_with_timeout(self, sql_query, exe_id, save_path=None, api="sqlite", max_len=30000, LIMIT=None, sqlite_path=None, timeout=3, example_id=None):
    #     # print_cpu_status(self.conns.keys())
    #     if sqlite_path not in self.conns:
    #         self.start_db(sqlite_path, exe_id, example_id)
    #     if example_id+exe_id not in self.conns:
    #         self.new_con(example_id, exe_id, sqlite_path)
    #     def target(q):
    #         try:
    #             result = self.exec_sql(sql_query, exe_id, save_path, api, max_len, LIMIT, sqlite_path, example_id)
    #             q.put(str(result))
    #         except Exception as e:
    #             traceback.print_exc()
    #             print("Exception in process", str(e))
    #             q.put(str(e))
    #         # finally:
    #         #     self.conns[example_id+exe_id].close()
    #         #     print(f"Close conn {example_id+exe_id}, current num: {len(self.conns)}")
    #     q = Queue()
    #     p = Process(target=target, args=(q,))
    #     p.start()

    #     p.join(timeout)
    #     if p.is_alive():
    #         try:
    #             p.terminate()
    #             p.join(timeout=2)
    #             if p.is_alive():
    #                 print("Terminate failed, forcing kill.")
    #                 p.kill()
    #                 p.join()
    #         except Exception as e:
    #             print(f"Error stopping process: {e}")
    #         print(f"##ERROR## {sql_query} Timed out, p.exitcode: {p.exitcode}\n")
    #         return f"##ERROR## {sql_query} Timed out\n"
    #     else:
    #         if not q.empty():
    #             result = q.get()
    #             return result
    #         else:
    #             return "##ERROR## Process p dead"

    def execute_sql_with_timeout(self, sql_query, exe_id, save_path=None, api="sqlite", max_len=30000,
                                LIMIT=None, sqlite_path=None, timeout=3, example_id=None):
        # Ensure the database and connection are initialized
        if sqlite_path not in self.conns:
            self.start_db(sqlite_path, exe_id, example_id)
        if example_id + exe_id not in self.conns:
            self.new_con(example_id, exe_id, sqlite_path)

        conn = self.conns[example_id + exe_id]
        should_interrupt = threading.Event()

        # SQL execution logic
        def run_sql():
            return self.exec_sql(sql_query, exe_id, save_path, api, max_len, LIMIT, sqlite_path, example_id)

        # Interrupt thread in case func_timeout fails to stop a stuck SQLite query
        def delayed_interrupt():
            if not should_interrupt.wait(timeout):
                try:
                    conn.interrupt()
                    # print(f"[INFO] Called conn.interrupt() after timeout for: {sql_query}")
                except Exception as e:
                    print(f"[WARN] Failed to call conn.interrupt(): {e}")

        try:
            # Start the interrupt fallback thread
            interrupt_thread = threading.Thread(target=delayed_interrupt, daemon=True)
            interrupt_thread.start()

            # Attempt to execute SQL with timeout
            result = func_timeout(timeout, run_sql)
            return str(result)
        except FunctionTimedOut:
            print(f"##ERROR## {sql_query} Timed out after {timeout} seconds")
            return f"##ERROR## Timed out\n"
        except Exception as e:
            traceback.print_exc()
            print(f"##ERROR## SQL execution failed: {e}")
            return f"##ERROR## {str(e)}\n"

    # def __del__(self):
    #     self.close_db()

import psutil
import datetime
import os

def print_cpu_status(keys):
    l = []
    l.append("\n" + "=" * 40 + " CPU Usage " + "=" * 40)
    
    # Show total and per-core CPU usage
    l.append(f"Total usage: {psutil.cpu_percent(interval=1)}%")
    l.append("Per-core usage:")
    for i, perc in enumerate(psutil.cpu_percent(percpu=True, interval=1)):
        l.append(f" - Core {i}: {perc}%")

    l.append("\n" + "=" * 40 + " Memory Usage " + "=" * 40)
    
    # Display memory usage stats
    mem = psutil.virtual_memory()
    l.append(f"Total memory: {mem.total / (1024**3):.2f} GB")
    l.append(f"Used: {mem.used / (1024**3):.2f} GB ({mem.percent}%)")
    l.append(f"Available: {mem.available / (1024**3):.2f} GB")

    l.append("=" * 92)
    l.append(f"len(keys): {len(keys)}\n{keys}")
    with open(f"log/cpu_state_{datetime.datetime.now().strftime('%Y-%m-%d_%H-%M-%S')}.log", "w") as f:
        f.write("\n".join(l))


# class SqlEnv:
#     def __init__(self, db_path: str):
#         self.db_path = db_path
#         self.conn = None

#     def started(self):
#         return self.conn is not None

#     def start_db(self, readonly=True):
#         if readonly:
#             file_uri = f"file:{self.db_path}?mode=ro"
#             disk_conn = sqlite3.connect(file_uri, uri=True)
#             start = time.time()
#             mem_conn = sqlite3.connect(f"file:{self.db_path}?mode=memory&cache=shared", uri=True)
#             mid = time.time()
#             disk_conn.backup(mem_conn)
#             end = time.time()
#             print(f"Time for create mem db: {mid - start}, time for backup: {end - mid}, sqlite_path: {self.db_path}, size: {os.path.getsize(self.db_path)}")
#             print_cpu_status()
#             self.conn = mem_conn
#             disk_conn.close()
#         else:
#             self.conn = sqlite3.connect(self.db_path)

#     def close_db(self):
#         if self.conn:
#             self.conn.close()
#             self.conn = None

#     def _clean_sql(self, sql_command: str) -> str:
#         cleaned = sql_command.replace("`", '"').rstrip(";")
#         return cleaned

#     def _execute_sql_worker(self, sql_command: str, queue: multiprocessing.Queue):
        
#         # sql_command = self._clean_sql(sql_command)
#         try:
#             statements = sqlglot.parse(sql_command)
#             if len(statements) > 1:
#                 queue.put("##SQLERROR##: You can only execute one statement at a time")
#                 return
#         except Exception as e:
#             queue.put(f"##SQLERROR##: {e}")
#             return
#         try:
#             conn = sqlite3.connect(self.db_path)
#             cur = conn.cursor()
#             cur.execute(sql_command)
#             column_names = [desc[0] for desc in cur.description]
#             output = io.StringIO()
#             writer = csv.writer(output)
#             writer.writerow(column_names)
#             writer.writerows(cur.fetchall())
#             csv_str = output.getvalue()
#             queue.put(csv_str)
#         except sqlite3.Error as e:
#             queue.put("##SQLERROR##: " + str(e))
#         finally:
#             cur.close()
#             conn.close()

#     def exec_sql(self, sql_command: str, timeout: int = 6) -> Union[str, List]:
#         # we select all training data, whose golden sql can be done in 5s, we give 1 more second for the timeout
#         # get timeout from env

#         # timeout = int(os.getenv("SQL_TIMEOUT", timeout))

#         queue = multiprocessing.Queue()
#         process = multiprocessing.Process(target=self._execute_sql_worker, args=(sql_command, queue))
#         process.start()
#         process.join(timeout)

#         if process.is_alive():
#             process.terminate()
#             return "##SQLERROR##: Time limit exceeded!"

#         return queue.get() if not queue.empty() else "##SQLERROR##: Unknown error!"

#     def __del__(self):
#         self.close_db()

# class SqlTask:
#     """Wrapper for SQL environment, and ground truth"""

#     def __init__(self, ground_truth: str, db_path: str, timeout=6):
#         self.ground_truth = ground_truth
#         self.db_path = db_path
#         self.timeout = timeout
#         self.sql_env: Optional[SqlEnv] = None
#         self.answer: str = None

#     def launch_env(self):
#         # print('dev' in self.db_path)
#         # if 'dev' in self.db_path:
#         #     self.sql_env = SqlEnvEVAL(self.db_path)
#         # else:
#         self.sql_env = SqlEnv(self.db_path)
#         self.sql_env.start_db()
#         self.answer = self.exec_sql(self.ground_truth)

#     def exec_sql(self, sql: str):
#         return self.sql_env.exec_sql(sql.strip(), self.timeout)

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