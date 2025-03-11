import os
import json
import pickle
import time

from tqdm import tqdm

def exec_run(cmd, workdir=None):
    import subprocess
    exit_code = None
    output = None
    try:
        process = subprocess.run(
            cmd,
            cwd=workdir,  # Set the working directory
            shell=False,    # Use the shell to execute the command
            stdout=subprocess.PIPE,  # Capture standard output
            stderr=subprocess.PIPE   # Capture standard error
        )

        exit_code = process.returncode
        output = process.stdout.decode() if exit_code == 0 else process.stderr.decode()
        
    except Exception as e:
        print(f"An error occurred: {e}")
    
    return exit_code, output

def execute_command(command: str, work_dir):
    cmd = ["bash", "-c", command]
    exit_code, output = exec_run(cmd, workdir=work_dir)
    return output.strip()

def execute_python_file(file_path: str, content: str, work_dir):
    escaped_content = content.replace('"', '\\"').replace('`', '\\`').replace('$', '\\$')
    if not file_path.startswith('/'):
        file_path = os.path.join(work_dir, file_path)
    dir_path = os.path.dirname(file_path)
    mkdir_command = f"mkdir -p {dir_path}"
    execute_command(mkdir_command, work_dir)
    create_command = f'echo "{escaped_content}" > {file_path} && python3 {file_path}'
    create_command = create_command.replace("New Volume", "New\ Volume")
    return execute_command(create_command, work_dir)


def execute_sf_exec_sql_query_special3(column_name, table_name, work_dir):

    sql_query = 'SELECT DISTINCT "' + column_name + '" FROM ' + table_name + ' LIMIT 20;'
    script_content = SF_EXEC_SQL_QUERY_TEMPLATE.format(
        sql_query=sql_query, is_save=False, save_path="")
    temp_file_path = "temp_sql_script.py" 
    observation = execute_python_file(temp_file_path, script_content, work_dir)
    execute_command(f"rm {temp_file_path}", work_dir)
    return observation.split("\n")


def get_file(file_path: str, work_dir):
    real_file_path = os.path.join(work_dir, file_path.replace("/workspace/",""))
    try:
        with open(real_file_path, 'r') as file:
            file_content = file.read()
    except FileNotFoundError:
        print("File not found:", file_path)
    except Exception as e:
        print("An error occurred:", str(e))
    return file_content

def get_real_file_path(file_path: str, work_dir):
    if not file_path.startswith(work_dir): # if the filepath is not absolute path, then it is a relative path
        if file_path.startswith("./"): file_path = file_path[2:]
        file_path = os.path.join(work_dir.rstrip('/'), file_path)
    real_file_path = os.path.join(work_dir, file_path.replace("/workspace/",""))   
      
    return real_file_path

def get_directory_tree(work_dir):

    import shutil
    # first copy the tree_function.py file to the work_dir
    shutil.copy("tree_function.py", work_dir)
    output = execute_command("python tree_function.py", work_dir)
    output_contents = output.split("<DELIMITER>")

    # Markdown Content
    md_files_list = output_contents[1].split("\n")
    md_files = []
    for md_file in md_files_list:
        if md_file:
            md_files.append(md_file)
    md_files_content = ""
    for md_file in md_files:
        md_file = os.path.join(work_dir, md_file)
        content = open(md_file, "r").read()
        md_files_content += f"\n\n{md_file}:\n{content}\n\n"

    # JSON Files
    json_files = output_contents[2].split("\n")
    json_files = [json_file for json_file in json_files if json_file and not json_file.endswith("credential.json")]
    return md_files_content, json_files

def execute_sf_inspect_table_json(json_file_path, work_dir):
    content = json.loads(get_file(json_file_path, work_dir))
    info = {}
    column_names = []
    info["table_fullname"] = content["table_fullname"]
    for i, column in enumerate(content["column_names"]):
        type = content["column_types"][i]
        description = content["description"][i]
        if description is None:
            description = ""
        info[column] = {"type": type, "description": description}
        column_names.append(column)
    return info, column_names

def fetch_table_metadata(sql_id, main_dir):

    work_dir = os.path.join(main_dir, "Spider2.0_snow", sql_id)

    table_structure = {}

    md_files_content, json_files = get_directory_tree(work_dir)


    for json_file in json_files:
        
        json_file = json_file[2:].split(".json")[0]
        json_file = json_file.replace(".", "/")
        database = json_file.split("/")[0]
        schema = json_file.split("/")[1]
        table = json_file.split("/")[2]
        if database not in table_structure:
            table_structure[database] = {}
        if schema not in table_structure[database]:
            table_structure[database][schema] = []
        table_structure[database][schema].append(table)


    if len(json_files) >= 100:
        return "TOO_LONG"

    if md_files_content == "":
        md_files_content = "None"

    observation = ""
    for json_file in json_files:
        info, column_names = execute_sf_inspect_table_json(json_file, work_dir)
        table_name = info["table_fullname"]
        observation += "\n" + "-"*50
        observation += "\nTable: " + table_name + "\n"
        for col in column_names:
            row = info[col]

            observation += '\nColumn:"' + col
            observation += '", (' + row["type"] + '), '
            if row["description"]:
                observation += " with description, " + row["description"]
        observation += "\n" + "-"*50
    observation = observation + "\nExternal knowledge that might be helpful:\n" + md_files_content + "\n"
    return observation, str(table_structure)

if __name__ == "__main__":
    sql_id = "sf001"
    observation = fetch_table_metadata(sql_id)
    print(observation)