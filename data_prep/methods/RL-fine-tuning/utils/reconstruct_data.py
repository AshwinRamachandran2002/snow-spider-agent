import os
import pandas as pd
import re
from tqdm import tqdm
import argparse
import shutil
import sqlite3
from utils.utils import remove_digits, is_file, matching_at_same_position
pd.set_option('display.max_colwidth', None)

def process_ddl(ddl_file):
    table_names = ddl_file['table_name'].to_list()
    # table_names_remove_digits = set([remove_digits(s) for s in table_names])
    representatives = {}
    for i in range(len(ddl_file)):
        if remove_digits(table_names[i]) in representatives.keys():
            representatives[remove_digits(table_names[i])] += [table_names[i]]
            ddl_file = ddl_file.drop(index=i)
        else:
            representatives[remove_digits(table_names[i])] = [table_names[i]]
    return ddl_file, representatives

def check_table_names(ddl_path):
    # print(ddl_path)
    ddl_file = pd.read_csv(ddl_path)
    temp_path = ddl_path.replace("DDL.csv", "DDL_tmp.csv")
    ddl_file['table_name'] = ddl_file['table_name'].str.split('.').str[-1]
    ddl_file.to_csv(temp_path, index=False)
    os.replace(temp_path, ddl_path)

def make_folder(args):
    print("Make folders for some examples.")
    example_folder = args.example_folder
    for entry in tqdm(os.listdir(example_folder)):
        entry1_path = os.path.join(example_folder, entry)
        if os.path.isdir(entry1_path):
            for project_name in os.listdir(entry1_path):
                project_name_path = os.path.join(entry1_path, project_name)
                if os.path.isdir(project_name_path):
                    for db_name in os.listdir(project_name_path):
                        db_name_path = os.path.join(project_name_path, db_name)
                        if db_name == "json":
                            os.remove(os.path.join(project_name_path, "json"))
                        elif (entry.startswith("sf") and db_name.endswith(".json")) or (entry.startswith("bq")) or (entry.startswith("ga")):
                            assert '.' in db_name.strip(".json")
                            folder_name = db_name.split(".")[0]
                            file_name = '.'.join(db_name.split(".")[1:])
                            folder_path = os.path.join(project_name_path, folder_name)
                            if not os.path.exists(folder_path):
                                os.mkdir(folder_path)
                            if entry.startswith("bq") or entry.startswith("ga"):
                                shutil.copytree(db_name_path, os.path.join(folder_path, file_name))
                                shutil.rmtree(db_name_path)
                            elif entry.startswith("sf"):
                                shutil.copy(db_name_path, os.path.join(folder_path, file_name))
                                os.remove(db_name_path)                                
                    if entry.startswith("sf") and "DDL.csv" in os.listdir(project_name_path):
                        ddl_path = os.path.join(project_name_path, "DDL.csv")
                        shutil.copy(ddl_path, os.path.join(folder_path, "DDL.csv"))
                        os.remove(ddl_path)
                    if entry.startswith("bq") or entry.startswith("ga"):
                        shutil.copytree(folder_path, os.path.join(entry1_path, folder_name))
                        shutil.rmtree(project_name_path)

def compress_ddl(example_folder):
    print("Compress DDL files.")
    for entry in tqdm(os.listdir(example_folder)):
        external_knowledge = None
        prompts = ''
        entry1_path = os.path.join(example_folder, entry)
        if os.path.isdir(entry1_path):
            if not entry.startswith("local"):
                table_dict = {}
                for project_name in os.listdir(entry1_path):
                    
                    if project_name == "spider":
                        continue
                    project_name_path = os.path.join(entry1_path, project_name)
                    if os.path.isdir(os.path.join(project_name_path)):
                        for db_name in os.listdir(project_name_path):
                            if project_name not in table_dict:
                                table_dict[project_name] = {db_name: []}
                            else:
                                table_dict[project_name][db_name] = []
                            db_name_path = os.path.join(project_name_path, db_name)
                            assert os.path.isdir(db_name_path) == True and "DDL.csv" in os.listdir(db_name_path)
                            for schema_name in os.listdir(db_name_path):
                                schema_name_path = os.path.join(db_name_path, schema_name)
                                if schema_name == "DDL.csv":
                                    if entry.startswith("sf0"):
                                        check_table_names(schema_name_path)
                                    # prompts += "DDL describes table information.\n"
                                    df = pd.read_csv(schema_name_path)
                                    ddl_file, representatives = process_ddl(df)
                                    table_name_list = ddl_file['table_name'].to_list()
                                    ddl_file.reset_index(drop=True, inplace=True)
                                    # count = 0
                                    for i in range(len(table_name_list)):
                                        # prompts += f"Database Name: {project_name}\n"
                                        # prompts += f"Schema Name: {db_name}\n"
                                        table_dict[project_name][db_name] += [table_name_list[i]]
                                        table_name_past = ddl_file.loc[i]["table_name"]
                                        table_name_complete = f"{project_name}.{db_name}.{table_name_past}"
                                        table_name_sf = f"{project_name}.{db_name}.{db_name}.{table_name_past}"
                                        ddl_file.loc[i, "table_name"] = table_name_complete
                                        table_name_past_with_tb = "TABLE " + table_name_past
                                        table_name_complete_with_tb = "TABLE " + table_name_complete
                                        table_name_sf_with_tb = "TABLE " + table_name_sf
                                        table_info = ddl_file.loc[i].to_csv().replace(table_name_past_with_tb, table_name_complete_with_tb) if entry.startswith("sf_") else ddl_file.loc[i].to_csv().replace(table_name_sf_with_tb, table_name_complete_with_tb)
                                        prompts += f"{table_info}\n"
                                        if len(representatives[remove_digits(table_name_list[i])]) > 1:
                                            prompts += f"Some other tables have the similar structure: {representatives[remove_digits(table_name_list[i])]}\n"
                                            table_dict[project_name][db_name] += representatives[remove_digits(table_name_list[i])]
                                elif schema_name == "json":
                                    with open(schema_name_path) as f:
                                        prompts += f.read()  
                                # else:
                                #     assert schema_name.lower().endswith("json")
                                #     table_dict[project_name][db_name] += [schema_name.split('.')[-2]]

                    elif is_file(project_name_path, "md"):
                        with open(project_name_path) as f:
                            external_knowledge = f.read()                
            else:
                for sqlite in os.listdir(entry1_path):
                    if sqlite.endswith(".sqlite"):
                        sqlite_path = os.path.join(entry1_path, sqlite)
                table_names, prompts = get_sqlite_data(sqlite_path)
            with open(os.path.join(entry1_path, "prompts.txt"), "w") as f:
                prompts += f"External knowledge that might be helpful: \n{external_knowledge}\n"
                if not entry.startswith("local"):
                    prompts += "The table structure information is ({database name: {schema name: [table name]}}): \n" + str(table_dict) + "\n"
                else:
                    prompts += "The table structure information is (table names): \n" + str(table_names) + "\n"
                f.writelines(prompts)

def get_sqlite_data_spider(path):
    connection = sqlite3.connect(path)
    cursor = connection.cursor()

    cursor.execute("SELECT name, sql FROM sqlite_master WHERE type='table'")
    tables = cursor.fetchall()
    table_names = []
    observation = "Information about the database:\n"
    for table in tables:
        observation += "\n" + "-"*50
        observation += "\nTable: " + table[0] + "\n"
        for row in table[1].split("\n")[1:-1]:
            if row.startswith('"'):
                col, type = row.split(" ")

                observation += '\nColumn:"' + col
                observation += '", (' + type + '), '
            else:
                observation += "\n" + row + ", "
        observation += "\n" + "-"*50

        table_names.append(table[0])
    observation = observation + "\nExternal knowledge that might be helpful:\nNone\n"
    connection.close()
    return table_names, observation



def get_sqlite_data_bird(path):
    connection = sqlite3.connect(path)
    cursor = connection.cursor()

    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")
    tables = [row[0] for row in cursor.fetchall()]

    observation = "Information about the database:\n"
    for table in tables:
        observation += "\n" + "-"*50
        observation += "\nTable: " + table + "\n"

        # Get column info
        cursor.execute(f'PRAGMA table_info("{table}")')
        for _, col_name, col_type, not_null, _, _ in cursor.fetchall():
            nullable_str = "NULL" if not not_null else "NOT NULL"
            observation += '\nColumn:"' + col_name
            observation += '", (' + col_type + '[' + nullable_str + ']), '

        # Get foreign keys
        cursor.execute(f'PRAGMA foreign_key_list("{table}")')
        for row in cursor.fetchall():
            observation += f"\nForeign key: ({row[3]}) references {row[2]}({row[4]}), "

        observation += "\n" + "-"*50

    observation = observation
    connection.close()
    return tables, observation


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--example_folder', type=str, default="output/test")
    args = parser.parse_args()
    make_folder(args)
    compress_ddl(args.example_folder)