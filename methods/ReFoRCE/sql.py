import sqlite3
import time
import io
import csv
from utils import hard_cut
from google.cloud import bigquery
from google.oauth2 import service_account
import snowflake.connector
import json
import pandas as pd

class SqlEnv:
    def __init__(self):
        self.conns = {}

    def get_rows(self, cursor, max_len):
        rows = []
        current_len = 0
        for row in cursor:
            row_str = str(row)
            if current_len + len(row_str) > max_len:
                break
            rows.append(row)
            current_len += len(row_str)
        return rows

    def get_csv(self, columns, rows):
        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerow(columns)
        writer.writerows(rows)
        csv_content = output.getvalue()
        output.close()
        return csv_content

    def start_db_sqlite(self, sqlite_path):
        if sqlite_path not in self.conns:
            uri = f"file:{sqlite_path}?mode=ro"
            conn = sqlite3.connect(uri, uri=True, check_same_thread=False)
            #     # TODO: locking protocol in backup for multi nodes
            # def backup_with_retry(conn, sqlite_path, meta_time_out):
            #     """
            #     Attempts to backup the database to memory within a given total timeout (meta_time_out seconds).
            #     If a "database is locked" error occurs, it will retry until the timeout is exceeded or maximum attempts are reached.
            #     """
            #     start_time = time.time()
            #     max_attempts = 3  # Adjust this value as needed
            #     attempts = 0

            #     while time.time() - start_time < meta_time_out and attempts < max_attempts:
            #         try:
            #             # Create a memory connection with a timeout to wait for the lock to be released.
            #             memory_conn = sqlite3.connect(
            #                 f"file:{sqlite_path.split('/')[-1]}?mode=memory&cache=shared",
            #                 uri=True, 
            #                 check_same_thread=False,
            #                 timeout=5.0  # Wait up to 5 seconds for a lock release
            #             )
            #             conn.backup(memory_conn)
            #             return memory_conn  # Return the memory connection if backup succeeds
            #         except sqlite3.OperationalError as e:
            #             attempts += 1
            #             elapsed = time.time() - start_time
            #             remaining = meta_time_out - elapsed
            #             print(f"Attempt {attempts}. Remaining time: {remaining:.2f} seconds. Error: {str(e)}")
            #             # If there's still time remaining, wait a short while before retrying.
            #             if remaining > 0.5:
            #                 time.sleep(0.5)
            #     # If the backup wasn't successful within the timeout or max attempts, return None.
            #     return None
            # try:
            #     memory_conn = backup_with_retry(conn, sqlite_path, 5)
            #     if memory_conn:
            #         self.conns[sqlite_path] = memory_conn
            #         conn.close()
            #         print(f"Backup succeeded, self.conns.keys(): {self.conns.keys()}")
            #     else:
            #         print("Backup failed after multiple attempts, using the original connection.")
            #         self.conns[sqlite_path] = conn
            # except Exception as e:
            # print(f"Exception during backup: {str(e)}. Using the original connection.")
            self.conns[sqlite_path] = conn
            # print(f"sqlite_path: {sqlite_path}, (self.conns): {self.conns.keys()}")

    def start_db_sf(self, ex_id):
        if ex_id not in self.conns.keys():
            snowflake_credential = json.load(open("./snowflake_credential.json"))
            self.conns[ex_id] = snowflake.connector.connect(**snowflake_credential)

    def close_db(self):
        # print("Close DB")
        for key, conn in list(self.conns.items()):
            try:
                if conn:
                    conn.close()
                    # print(f"Connection {key} closed.")
                    del self.conns[key]
            except Exception as e:
                print(f"When closing DB for {key}: {e}")

    def exec_sql_sqlite(self, sql_query, save_path=None, max_len=30000, sqlite_path=None):
        cursor = self.conns[sqlite_path].cursor()
        try:
            cursor.execute(sql_query)
            column_info = cursor.description
            rows = self.get_rows(cursor, max_len)
            columns = [desc[0] for desc in column_info]
        except Exception as e:
            return e
        finally:
            try:
                cursor.close()
            except Exception as e:
                print("Failed to close cursor:", e)

        if not rows:
            return "No data found for the specified query.\n"
        else:
            csv_content = self.get_csv(columns, rows)
            if save_path:
                with open(save_path, 'w', newline='') as f:
                    f.write(csv_content)
                return 0
            else:
                return hard_cut(csv_content, max_len)
            
    def exec_sql_sf(self, sql_query, save_path, max_len, ex_id):
        with self.conns[ex_id].cursor() as cursor:
            try:
                cursor.execute(sql_query)
                column_info = cursor.description
                rows = self.get_rows(cursor, max_len)
                columns = [desc[0] for desc in column_info]
            except Exception as e:
                return e

        if not rows:
            return "No data found for the specified query.\n"
        else:
            csv_content = self.get_csv(columns, rows)
            if save_path:
                with open(save_path, 'w', newline='') as f:
                    f.write(csv_content)
                return 0
            else:
                return hard_cut(csv_content, max_len)

    def exec_sql_bq(self, sql_query, save_path, max_len):
        bigquery_credential = service_account.Credentials.from_service_account_file("./bigquery_credential.json")
        client = bigquery.Client(credentials=bigquery_credential, project=bigquery_credential.project_id)
        query_job = client.query(sql_query)
        try:
            result_iterator = query_job.result()
        except Exception as e:
            return e
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

    def execute_sql_api(self, sql_query, ex_id, save_path=None, api="sqlite", max_len=30000, sqlite_path=None):
        if api == "bigquery":
            return self.exec_sql_bq(sql_query, save_path, max_len)
        elif api == "snowflake":
            if ex_id not in self.conns.keys():
                self.start_db_sf(ex_id)
            return self.exec_sql_sf(sql_query, save_path, max_len, ex_id)
        elif api == "sqlite":
            if sqlite_path not in self.conns.keys():
                self.start_db_sqlite(sqlite_path)
            return self.exec_sql_sqlite(sql_query, save_path, max_len, sqlite_path)