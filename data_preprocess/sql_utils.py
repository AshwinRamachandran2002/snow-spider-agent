import json
import os
import sqlite3
from pathlib import Path
from typing import Any
from typing import Dict
from typing import List
from typing import Optional
from typing import Set
from typing import Union
import signal 
import sqlglot
from datasets import load_dataset, Dataset
import multiprocessing
from functools import partial
import pandas as pd

class SqlEnv:
    def __init__(self, db_path: str):
        self.db_path = db_path
        self.conn = None

    def started(self):
        return self.conn is not None

    def start_db(self, readonly=True):
        if readonly:
            readonly_path = "file:" + self.db_path + "?mode=ro"
            self.conn = sqlite3.connect(readonly_path, uri=True)
        else:
            self.conn = sqlite3.connect(self.db_path)

    def close_db(self):
        if self.conn:
            self.conn.close()
            self.conn = None

    def _clean_sql(self, sql_command: str) -> str:
        cleaned = sql_command.replace("`", '"').rstrip(";")
        return cleaned

    def _execute_sql_worker(self, sql_command: str, queue: multiprocessing.Queue):
        try:
            conn = sqlite3.connect(self.db_path)
            cur = conn.cursor()
            sql_command = self._clean_sql(sql_command)
            try:
                statements = sqlglot.parse(sql_command)
                if len(statements) > 1:
                    queue.put(["##SQLERROR##: You can only execute one statement at a time"])
                    return
            except Exception as e:
                queue.put([f"##SQLERROR##: {e}\n"])
                return

            cur.execute(sql_command)
            queue.put(cur.fetchall())
        except sqlite3.Error as e:
            queue.put(["##SQLERROR##: " + str(e)])
        finally:
            cur.close()
            conn.close()

    def exec_sql(self, sql_command: str, timeout: int = 60) -> Union[str, List]:
        # we select all training data, whose golden sql can be done in 5s, we give 1 more second for the timeout
        # get timeout from env

        timeout = int(os.getenv("SQL_TIMEOUT", timeout))

        queue = multiprocessing.Queue()
        process = multiprocessing.Process(target=self._execute_sql_worker, args=(sql_command, queue))
        process.start()
        process.join(timeout)

        if process.is_alive():
            process.terminate()
            return ["##SQLERROR##: Time limit exceeded!"]

        return queue.get() if not queue.empty() else ["##SQLERROR##: Unknown error!"]

    def __del__(self):
        self.close_db()

class SqlTask:
    """Wrapper for SQL environment, and ground truth"""

    def __init__(self, ground_truth: str, db_path: str):
        self.ground_truth = ground_truth
        self.db_path = db_path
        self.sql_env: Optional[SqlEnv] = None
        self.answer: Set[Any] = None

    def launch_env(self):
        # print('dev' in self.db_path)
        # if 'dev' in self.db_path:
        #     self.sql_env = SqlEnvEVAL(self.db_path)
        # else:
        self.sql_env = SqlEnv(self.db_path)
        self.sql_env.start_db()
        self.answer = self.exec_sql(self.ground_truth)

    def exec_sql(self, sql: str):
        return self.sql_env.exec_sql(sql.strip())

def _gen_data_fetch(col_name: str, table_name: str):
    col_name = col_name.replace('"', '""')
    table_name = table_name.replace('"', '""')

    query = f'SELECT "{col_name}" FROM "{table_name}" LIMIT 3'
    return query


def get_row_info_filtered(df, original_col_name, table_name):
    df['original_column_name'] = df['original_column_name'].str.strip()

    row = df[df['original_column_name'] == original_col_name]
    assert not row.empty, table_name
    row_data = row.iloc[0]
    return ', '.join([
        f"{col}: {row_data[col]}"
        for col in df.columns
        if pd.notna(row_data[col]) and str(row_data[col]).strip() != ''
    ]).replace("column_name", "full_column_name")

def create_db_schema_des(db_metadata: Dict[str, Any], db_path: str) -> str:
    table_names = db_metadata["table_names_original"]
    column_names = db_metadata["column_names_original"]
    full_table_names = db_metadata["table_names"]
    full_column_names = db_metadata["column_names"]
    column_types = db_metadata["column_types"]
    primary_keys = db_metadata["primary_keys"]
    foreign_keys = db_metadata["foreign_keys"]

    # Create table columns and primary key set
    table_columns = [[] for _ in range(len(table_names))]
    full_table_columns = [[] for _ in range(len(full_table_names))]
    for idx, (table_idx, col_name) in enumerate(column_names):
        if table_idx != -1:  # Ignore the '*' wildcard
            table_columns[table_idx].append((idx, col_name))
            full_table_columns[table_idx].append((idx, full_column_names[idx][-1]))

    flattened_pks = []
    for pk in primary_keys:
        if isinstance(pk, list):
            flattened_pks.extend(pk)
        else:
            flattened_pks.append(pk)

    primary_key_set = set(flattened_pks)

    # Create a foreign key mapping for quick lookup
    foreign_key_map = {}
    for fk_idx, ref_idx in foreign_keys:
        foreign_key_map[fk_idx] = ref_idx

    # Open database connection
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    output = []
    tb_struct = {}
    for table_idx, table_name in enumerate(table_names):
        output.append(f"Table Name: {table_name} (Full Table Name: {full_table_names[table_idx]}):")
        columns = table_columns[table_idx]
        full_columns = full_table_columns[table_idx]
        tb_struct[table_name] = []

        database_description_path = os.path.join("/".join(db_path.split("/")[:-1]), "database_description")
        for csv_file in os.listdir(database_description_path):
            if db_metadata["db_id"] == "app_store":
                if table_name == "playstore":
                    csv_file_path = os.path.join(database_description_path, "googleplaystore.csv")
                elif table_name == "user_reviews":
                    csv_file_path = os.path.join(database_description_path, "googleplaystore_user_reviews.csv")
            if csv_file.replace(".csv", "").upper() == table_name.upper():
                csv_file_path = os.path.join(database_description_path, csv_file)
        try:
            df = pd.read_csv(csv_file_path, encoding_errors='ignore')
        except Exception as e:
            print(e, database_description_path)
        for col_idx, col_name in columns:
            col_type = column_types[col_idx]
            tb_struct[table_name] += [col_name]
            # Fetch sample data
            cursor.execute(_gen_data_fetch(col_name, table_name))
            sample_data = [str(row[0]) for row in cursor.fetchall()]
            if sample_data and len(sample_data[0]) > 128:
                # too long sampled values, just use empty string
                sample_data = ["", "", ""]

            # Format the sample data as string
            sample_str = ", ".join(f'"{value}"' for value in sample_data)

            # Check if the column is a primary key
            is_primary_key = col_idx in primary_key_set
            primary_key_text = "primary_key" if is_primary_key else ""

            # Check if the column references another table
            ref_text = ""
            if col_idx in foreign_key_map:
                ref_idx = foreign_key_map[col_idx]
                ref_table_idx, ref_col_name = column_names[ref_idx]
                ref_table_name = table_names[ref_table_idx]
                ref_text = (
                    f"{table_name}.{col_name}={ref_table_name}.{ref_col_name}"
                )

            
            # Append formatted column description
            column_desc = get_row_info_filtered(df, col_name, table_name)
            if primary_key_text or ref_text:
                column_desc += f", primary_key or foreign_key info: {primary_key_text} {ref_text}"
            output.append(column_desc.strip())

        output.append("")  # Add a blank line between tables
    output.append("Table structure: " + str(tb_struct))
    conn.close()
    return "\n".join(output).strip()

def create_db_schema(db_metadata: Dict[str, Any], db_path: str, skip_key: bool = False) -> str:
    table_names = db_metadata["table_names_original"]
    column_names = db_metadata["column_names_original"]
    full_table_names = db_metadata["table_names"]
    full_column_names = db_metadata["column_names"]
    column_types = db_metadata["column_types"]
    primary_keys = db_metadata["primary_keys"]
    foreign_keys = db_metadata["foreign_keys"]

    # print(foreign_keys)

    # Create table columns and primary key set
    table_columns = [[] for _ in range(len(table_names))]
    full_table_columns = [[] for _ in range(len(full_table_names))]
    for idx, (table_idx, col_name) in enumerate(column_names):
        if table_idx != -1:  # Ignore the '*' wildcard
            table_columns[table_idx].append((idx, col_name))
            full_table_columns[table_idx].append((idx, full_column_names[idx][-1]))

    flattened_pks = []
    for pk in primary_keys:
        if isinstance(pk, list):
            flattened_pks.extend(pk)
        else:
            flattened_pks.append(pk)

    primary_key_set = set(flattened_pks)

    # Create a foreign key mapping for quick lookup
    foreign_key_map = {}
    if not skip_key:
        for fk_idx, ref_idx in foreign_keys:
            foreign_key_map[fk_idx] = ref_idx

    # Open database connection

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    output = []
    tb_struct = {}
    table_join = []
    for table_idx, table_name in enumerate(table_names):
        output.append(f"Table Name: {table_name} (full table name: {full_table_names[table_idx]}):")
        columns = table_columns[table_idx]
        full_columns = full_table_columns[table_idx]
        tb_struct[table_name] = []

        for col_idx, col_name in columns:
            col_type = column_types[col_idx]
            tb_struct[table_name] += [col_name]
            # Fetch sample data
            cursor.execute(_gen_data_fetch(col_name, table_name))
            sample_data = [str(row[0]) for row in cursor.fetchall()]
            if sample_data and len(sample_data[0]) > 128:
                # too long sampled values, just use empty string
                sample_data = ["", "", ""]

            # Format the sample data as string
            sample_str = ", ".join(f'"{value}"' for value in sample_data)

            # Check if the column is a primary key
            is_primary_key = col_idx in primary_key_set
            primary_key_text = "primary_key" if is_primary_key else ""

            # Check if the column references another table
            ref_text = ""
            if col_idx in foreign_key_map:
                ref_idx = foreign_key_map[col_idx]
                ref_table_idx, ref_col_name = column_names[ref_idx]
                ref_table_name = table_names[ref_table_idx]
                ref_text = (
                    f"{table_name}.{col_name}={ref_table_name}.{ref_col_name}"
                )
                table_join.append(ref_text)
            full_column = full_columns[columns.index((col_idx, col_name))]
            # Append formatted column description
            column_desc = f"Column Name: {col_name} (full column name: {full_column[-1]}) Data Type: [ {col_type.upper()} ] Sample Rows: ( {sample_str} ) {primary_key_text} {ref_text}"
            output.append(column_desc.strip())

        output.append("")  # Add a blank line between tables
    output.append("Table structure: " + str(tb_struct))
    output.append("Table join: " + str(table_join))
    conn.close()
    return "\n".join(output).strip()

def _load_db_metadata(db_metadata_path: Path) -> Dict[str, Any]:
    if not os.path.exists(db_metadata_path):
        raise FileNotFoundError(f"tables.json not found in {db_metadata_path}")
    with open(db_metadata_path, "r", encoding="utf-8") as f:
        raw_metadata = json.load(f)
    db_metadata = {r["db_id"]: r for r in raw_metadata}
    return db_metadata


def get_db_path(db_folder: Path, db_name: str) -> str:
    db_dir = db_folder / db_name
    db_path = db_dir / (db_name + ".sqlite")
    return db_path.as_posix()


def prepare_fn_longcot(sample, db_desc_str, dataset_type, tokenizer, template_type="base"):
    db_id = sample["db_id"]
    sample["ground_truth"] = sample.pop("SQL")
    # sample["data_path"] = str(train_db_folder) 
    db_desc = db_desc_str[db_id]
    sample["db_desc"] = db_desc.strip()

    if dataset_type == "bird":
        question = sample["question"] + " " + sample.pop("evidence", "")
    elif dataset_type == "spider":
        question = sample["question"]
    else:
        raise ValueError(f"Unsupported dataset type`{dataset_type}`")

    if template_type == "prepare":
        messages = [
            {
                'role': 'system',
                'content': "You are a SQL expert to help solve users' Text2SQL problems based on the provided database scheme. Please think step by step and write your answer in the form of ```sql ...```.",
            },
            {
                'role': 'user',
                'content': f"Database Schema: {db_desc.strip()}\n\nQuestion: {question}",
            }
            ]
        # sample["messages"] = messages
        sample["question"] = question
        
        

    elif template_type == "qwen-instruct":
        messages = [
                {
                    "role": "system",
                    "content": 'You are a SQL analyst who writes great SQL code. You should think step-by-step and write your final sql in the format ```sql ...```.',
                },
                {
                    "role": "user",
                    "content": f"""
Database info: {db_desc.strip()}

Question: {question}
""".strip()
                }
            ]
        sample["question"] = question
        # GS: test qwen-instruct and deepseek-distilled-qwen
        sample["prompt"] = tokenizer.apply_chat_template(messages, add_generation_prompt=True, tokenize=False)

        # for qwen-instruct, 
        # Question: Please list the codes of the schools with a total enrollment of over 500. Total enrollment can be represented by `Enrollment (K-12)` + `Enrollment (Ages 5-17)`<|im_end|>
        # <|im_start|>assistant
        # Let me solve this step by step. 
        # <think>

        # for qwen-deepseek distilled
        # Question: Please list the codes of the schools with a total enrollment of over 500. Total enrollment can be represented by `Enrollment (K-12)` + `Enrollment (Ages 5-17)`<｜Assistant｜><think>


    return sample

def prepare_fn_func(sample, db_desc_str, dataset_type, tokenizer, template_type="base"):
    db_id = sample["db_id"]
    sample["ground_truth"] = sample.pop("SQL")
    # sample["data_path"] = str(train_db_folder) 
    db_desc = db_desc_str[db_id]
    sample["db_desc"] = db_desc.strip()

    if dataset_type == "bird":
        question = sample["question"] + " " + sample.pop("evidence", "")
    elif dataset_type == "spider":
        question = sample["question"]
    else:
        raise ValueError(f"Unsupported dataset type`{dataset_type}`")

    if template_type == "qwen-instruct":
        messages = [
            {
                "role": "system",
                "content": "You are a data scientist proficient in databases, SQL, and DBT projects. Given a task, you should determine the answer format, generate multiple SQL queries from simple to complex, execute them step by step, and provide a final answer after reviewing the results. You may use the <exec_sql> and </exec_sql> tags to execute SQL functions and you will get result feedback. If there is syntax error or empty results, you should fix it. The SQL dialect must be SQLite.\n",
            },
            {
                "role": "user",
                "content": f"""
                    Database info: {db_desc.strip()}

                    Question: {question}
                    """.strip()
            }
        ]
        sample["question"] = question
        # GS: test qwen-instruct and deepseek-distilled-qwen
        # sample["prompt"] = tokenizer.apply_chat_template(messages, add_generation_prompt=True, tokenize=False)
    return sample

def load_bird_dataset_util(data_path: str, mode: str, cache_dir: str, tokenizer):
    if mode == "train":
        db_folder = Path(os.path.join(data_path, "train_databases"))
        tables_json_path = Path(os.path.join(data_path, "train_tables.json"))
        question_set_path = Path(os.path.join(data_path, "train.json"))
    elif mode == "dev":
        db_folder = Path(os.path.join(data_path, "dev_databases"))
        tables_json_path = Path(os.path.join(data_path, "dev_tables.json"))
        question_set_path = Path(os.path.join(data_path, "dev.json"))
    elif mode == "test":
        db_folder = Path(os.path.join(data_path, "dev_databases"))
        tables_json_path = Path(os.path.join(data_path, "dev_tables.json"))
        question_set_path = Path(os.path.join(data_path, "dev.json"))
    elif mode == "train_aug":
        db_folder = Path(os.path.join(data_path, "train_databases"))
        tables_json_path = Path(os.path.join(data_path, "train_tables.json"))
        question_set_path = Path(os.path.join(data_path, "train_aug.json"))
    else:
        raise ValueError(f"Invalid mode: {mode}")
    
    raw_metadata = _load_db_metadata(tables_json_path)

    questions = load_dataset(
        "json",
        data_files=question_set_path.as_posix(),
        cache_dir=cache_dir,
        split="train",
    )

    # def add_db_path_to_dataset(example):
    #     example["db_path"] = get_db_path(db_folder, example['db_id'])
    #     return example
    
    # questions = questions.map(add_db_path_to_dataset)

    db_schema_generator = create_db_schema
    db_desc_str = {
        db_id: db_schema_generator(
            raw_metadata[db_id], get_db_path(db_folder, db_id)
        )
        for db_id in raw_metadata
    }
    print(questions)
    dataset = questions.map(
        partial(prepare_fn_func, db_desc_str=db_desc_str, tokenizer=tokenizer, dataset_type="bird", template_type="qwen-instruct")
    )
    print(dataset)
    return dataset

# GS: spider
def load_spider_dataset_util(data_path: str, mode: str, cache_dir: str, tokenizer): # `cache_dir` is not be used
    if mode == "train":
        db_folder = Path(os.path.join(data_path, "database"))
        tables_json_path = Path(os.path.join(data_path, "tables.json"))
        question_set_path = Path(os.path.join(data_path, "train_spider.json"))
        question_other_path = Path(os.path.join(data_path, "train_others.json"))
    elif mode == "dev":
        db_folder = Path(os.path.join(data_path, "database"))
        tables_json_path = Path(os.path.join(data_path, "tables.json"))
        question_set_path = Path(os.path.join(data_path, "dev.json"))
    elif mode == "test":
        db_folder = Path(os.path.join(data_path, "test_database"))
        tables_json_path = Path(os.path.join(data_path, "test_tables.json"))
        question_set_path = Path(os.path.join(data_path, "test.json")) # why test_data/dev.json? there exists test.json in the folder
    else:
        raise ValueError(f"Invalid mode: {mode}")

    raw_metadata = _load_db_metadata(tables_json_path)
    with open(question_set_path, "r") as f:
        questions = json.load(f)
    if mode == "train":
        with open(question_other_path, "r") as f:
            questions_other = json.load(f)
        questions += questions_other

    questions = [
        {"db_id": q["db_id"], "question": q["question"], "SQL": q["query"]}
        for q in questions
    ]

    db_schema_generator = create_db_schema
    db_desc_str = {
        db_id: db_schema_generator(raw_metadata[db_id], get_db_path(db_folder, db_id))
        for db_id in raw_metadata
    }

    dataset = Dataset.from_list(questions)
    dataset = dataset.map(
        partial(prepare_fn_longcot, db_desc_str=db_desc_str, tokenizer=tokenizer, dataset_type="spider", template_type="qwen-instruct")
    )
    print(dataset)

    return dataset
