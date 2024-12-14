import os
import pandas as pd
import re
from tqdm import tqdm
import argparse

pd.set_option('display.max_colwidth', None)

def remove_digits(s):
    return re.sub(r'\d', '', s)

def is_file(filepath, suffix):
    return os.path.isfile(filepath) and filepath.lower().endswith(suffix)

def matching_at_same_position(s1, s2):
    min_length = min(len(s1), len(s2))
    matches = [s1[i] for i in range(min_length) if s1[i] == s2[i]]
    return "".join(matches)

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


def compress_all(args):
    example_folder = args.example_folder
    for entry in tqdm(os.listdir(example_folder)):
        external_knowledge = None
        prompts = ''
        entry1_path = os.path.join(example_folder, entry)
        if os.path.isdir(entry1_path):
            table_dict = {}
            for project_name in os.listdir(entry1_path):
                
                if project_name == "spider":
                    continue
                project_name_path = os.path.join(entry1_path, project_name)
                if os.path.isdir(os.path.join(project_name_path)):
                    for db_name in os.listdir(project_name_path):
                        prompts += f"Project Name: {project_name}\n"
                        prompts += f"Database Name: {db_name}\n"
                        if project_name not in table_dict:
                            table_dict[project_name] = {db_name: []}
                        else:
                            table_dict[project_name][db_name] = []
                        db_name_path = os.path.join(project_name_path, db_name)
                        assert os.path.isdir(db_name_path) == True and "DDL.csv" in os.listdir(db_name_path)
                        for schema_name in os.listdir(db_name_path):
                            schema_name_path = os.path.join(db_name_path, schema_name)
                            if schema_name == "DDL.csv":
                                prompts += "DDL describes table information.\n"
                                df = pd.read_csv(schema_name_path)
                                ddl_file, representatives = process_ddl(df)
                                table_name_list = ddl_file['table_name'].to_list()
                                ddl_file.reset_index(drop=True, inplace=True)
                                count = 0
                                for i in range(len(table_name_list)):
                                    prompts += f"{ddl_file.loc[i].to_string()}\n"
                                    if len(representatives[remove_digits(table_name_list[i])]) > 1:
                                        prompts += f"Some other tables have the similar structure: {representatives[remove_digits(table_name_list[i])]}\n"
                                    table_name = representatives[remove_digits(table_name_list[i])][0].split(".")[-1]
                                    if os.path.exists(os.path.join(db_name_path, table_name+".json")):
                                        with open(os.path.join(db_name_path, table_name+".json")) as f:
                                            sample_table = f.read()                                    
                                            if len(sample_table) < 1e5:
                                                prompts += f"Sample rows of Table {table_name}:\n{sample_table}\n"
                                                count += 1
                                            else:
                                                print(f"Too long, skip: db_name_path: {db_name_path}, len: {len(sample_table)}")
                            elif schema_name == "json":
                                with open(schema_name_path) as f:
                                    prompts += f.read()  
                            else:
                                assert schema_name.lower().endswith("json")
                                table_dict[project_name][db_name] += [schema_name.split('.')[-2]]

                elif is_file(project_name_path, "md"):
                    with open(project_name_path) as f:
                        external_knowledge = f.read()                
        
            with open(os.path.join(entry1_path, "prompts.txt"), "w") as f:
                prompts += f"External knowledge that might be helpful: \n{external_knowledge}\n"
                prompts += "In conclusion, the table inforation is ({project name: {database name: {table name}}}): \n" + str(table_dict) + "\n"
                f.writelines(prompts)
        

def compress_ddl(args):
    example_folder = args.example_folder
    for entry in tqdm(os.listdir(example_folder)):
        external_knowledge = None
        prompts = ''
        entry1_path = os.path.join(example_folder, entry)
        if os.path.isdir(entry1_path):
            table_dict = {}
            for project_name in os.listdir(entry1_path):
                
                if project_name == "spider":
                    continue
                project_name_path = os.path.join(entry1_path, project_name)
                if os.path.isdir(os.path.join(project_name_path)):
                    for db_name in os.listdir(project_name_path):
                        prompts += f"Project Name: {project_name}\n"
                        prompts += f"Database Name: {db_name}\n"
                        if project_name not in table_dict:
                            table_dict[project_name] = {db_name: []}
                        else:
                            table_dict[project_name][db_name] = []
                        db_name_path = os.path.join(project_name_path, db_name)
                        assert os.path.isdir(db_name_path) == True and "DDL.csv" in os.listdir(db_name_path)
                        for schema_name in os.listdir(db_name_path):
                            schema_name_path = os.path.join(db_name_path, schema_name)
                            if schema_name == "DDL.csv":
                                prompts += "DDL describes table information.\n"
                                df = pd.read_csv(schema_name_path)
                                ddl_file, representatives = process_ddl(df)
                                table_name_list = ddl_file['table_name'].to_list()
                                ddl_file.reset_index(drop=True, inplace=True)
                                # count = 0
                                for i in range(len(table_name_list)):
                                    prompts += f"{ddl_file.loc[i].to_csv()}\n"
                                    if len(representatives[remove_digits(table_name_list[i])]) > 1:
                                        prompts += f"Some other tables have the similar structure: {representatives[remove_digits(table_name_list[i])]}\n"
                                    # table_name = representatives[remove_digits(table_name_list[i])][0].split(".")[-1]
                                    # if os.path.exists(os.path.join(db_name_path, table_name+".json")):
                                    #     with open(os.path.join(db_name_path, table_name+".json")) as f:
                                    #         sample_table = f.read()                                    
                                    #         if len(sample_table) < 1e5:
                                    #             prompts += f"Sample rows of Table {table_name}:\n{sample_table}\n"
                                    #             count += 1
                                    #         else:
                                    #             print(f"Too long, skip: db_name_path: {db_name_path}, len: {len(sample_table)}")
                            elif schema_name == "json":
                                with open(schema_name_path) as f:
                                    prompts += f.read()  
                            else:
                                assert schema_name.lower().endswith("json")
                                table_dict[project_name][db_name] += [schema_name.split('.')[-2]]

                elif is_file(project_name_path, "md"):
                    with open(project_name_path) as f:
                        external_knowledge = f.read()                
        
            with open(os.path.join(entry1_path, "prompts.txt"), "w") as f:
                prompts += f"External knowledge that might be helpful: \n{external_knowledge}\n"
                prompts += "In conclusion, the table inforation is ({project name: {database name: {table name}}}): \n" + str(table_dict) + "\n"
                f.writelines(prompts)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    # example_folder = "./output/o1-preview-test1"
    # example_folder = "./output/test"
    # example_folder = "./output/test_with_sql"
    parser.add_argument('--example_folder', type=str, default="output/test")
    args = parser.parse_args()
    # compress_all(args)
    compress_ddl(args)