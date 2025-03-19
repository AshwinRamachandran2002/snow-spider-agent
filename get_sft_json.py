import os
import json

def get_api_name(sql_data):
    if sql_data.startswith("sf"):
        return "snowflake"
    elif sql_data.startswith("local"):
        return "sqlite"
    elif sql_data.startswith("bq") or sql_data.startswith("ga"):
        return "bigquery"
    else:
        raise NotImplementedError("Invalid file name.")

class Prompts:
    def __init__(self):
        pass
    def get_prompt_dialect_basic(self, api):
        if api == "snowflake":
            return "```sql\nSELECT \"COLUMN_NAME\" FROM DATABASE.SCHEMA.TABLE WHERE ... ``` (Adjust \"DATABASE\", \"SCHEMA\", and \"TABLE\" to match actual names, ensure all column names are enclosed in double quotations. Don't miss the database name and schema name.)\n"
        elif api == "bigquery":
            return "```sql\nSELECT `column_name` FROM `database.schema.table` WHERE ... ``` (Replace `database`, `schema`, and `table` with actual names. Enclose column names and table identifiers with backticks. Don't miss the database name and schema name.)\n"
        elif api == "sqlite":
            return "```sql\nSELECT \"column_name\" FROM \"table_name\" WHERE ... ``` (Replace \"table_name\" with the actual table name. Enclose table and column names with double quotations if they contain special characters or match reserved keywords.)\n"
        else:
            return "Unsupported API. Please provide a valid API name ('snowflake', 'bigquery', 'sqlite')."
    def get_prompt_dialect_basic_eg(self, api, table_struct):
        if api == "snowflake" or api == "bigquery":
            json_str = table_struct.replace("'", '"')
            json_obj = json.loads(json_str)
            
            for db_name, schemas in json_obj.items():
                for schema_name, tables in schemas.items():
                    for table in tables:
                        if table:
                            whole_table_name = f"{db_name}.{schema_name}.{table}"
                            if api == "snowflake":
                                return f"Example Usage: SELECT T.\"col_name\" FROM {whole_table_name} T WHERE ...; Add double quotations to each column name: T.\"col_name\".\n"
                            if api == "bigquery":
                                return f"Example Usage: SELECT `col_name` FROM `{whole_table_name}` WHERE ...;\n"

def extract_between(content, start_str, end_str):
    results = []
    start_index = 0

    while True:
        start_index = content.find(start_str, start_index)
        if start_index == -1:
            break
        start_index += len(start_str)
        end_index = content.find(end_str, start_index)
        if end_index == -1:
            break
        results.append(content[start_index:end_index].strip())
        start_index = end_index + len(end_str)
    
    return results

def get_tb_prompt(tb_info, example_id, question):
    instruction = "This is a Text-to-SQL task where you are given database information and a question, and your goal is to generate only one SQL query as the answer. Let's think step by step. First, use <formatting></formatting> to define a CSV table that illustrates the expected answer format. Then, use <reasoning></reasoning> to analyze relevant tables and columns, outline key conditions, and construct SQL queries progressively from simple to complex. Finally, enclose the final SQL query within <answer></answer> using a ```sql\n``` code block.\n"
    instruction += "Table info:\n" + tb_info

    api = get_api_name(example_id)
    sql_prompt = Prompts()
    tb_str = "The table structure information is ({database name: {schema name: [table name]}}): \n"
    table_struct = tb_info[tb_info.find(tb_str)+len(tb_str):].replace("\n", "")
    instruction += f"The SQL dialect is {api}. Basic usage: " + sql_prompt.get_prompt_dialect_basic(api)
    if sql_prompt.get_prompt_dialect_basic_eg(api, table_struct):
        instruction += sql_prompt.get_prompt_dialect_basic_eg(api, table_struct)
    instruction += f"Question: {question}\n"
    return instruction, table_struct

def extract_info(log_str, question, answer, tb_info, ex_dict, example_id):
    col_explore = extract_between(log_str, "Begin Exploring Related Columns\n", "End Exploring Related Columns\n")
    assert len(col_explore) == 1
    col_explore = col_explore[0]
    col_explore = col_explore[:col_explore.find("Query:\n")]
    col_explore = "Then, I will reason step by step to get the answer.\n<reasoning>\n" + col_explore + "</reasoning>\n"

    format_ans = extract_between(log_str, "Follow the answer format like:", "Here are some useful tips for answering:")
    assert len(format_ans) == 1
    format_ans = format_ans[0]
    format_ans = "First, I will decide what the output should look like.\n<formatting>\n" + format_ans + "</formatting>\n"

    answer = "The final answer is:\n<answer>\n```sql\n" + answer + "```\n</answer>\n"

    table_prompt, table_struct = get_tb_prompt(tb_info, example_id, question)
    if len(table_prompt + col_explore + format_ans + answer) > 96000:
        print(f"{example_id} length {len(table_prompt + col_explore + format_ans + answer)} Exceeded, cut to {len(table_struct + col_explore + format_ans + answer)}")
    #     table_prompt = table_struct
    ex_dict["messages"] += [{"role": "user", "content": table_prompt}]
    ex_dict["messages"] += [{"role": "assistant", "content": format_ans+col_explore+answer}]

    return ex_dict

TRAIN_PATH = "../../../snow-spider-agent/deepscaler/data/train/training_data.json"
RESULTS_LOG_PATH_SNOW = "../../results-log/output/o1-preview-snow-2.12-log"
RESULTS_LOG_PATH_LITE = "../../results-log/output/o1-preview-lite-2.12-log"
with open(TRAIN_PATH) as f:
    train_json = json.load(f)

sft_json = []

for i in range(len(train_json)):
    ex_id = train_json[i]["example_id"]
    data_source = train_json[i]["data_source"]
    question = train_json[i]["question"]
    answer = train_json[i]["answer"]
    tb_info = train_json[i]["input"]
    if data_source == "Spider2.0":
        api = get_api_name(ex_id)
        LOG_PATH = RESULTS_LOG_PATH_SNOW if api == "snowflake" else RESULTS_LOG_PATH_LITE
        for j in range(3):
            ex_dict = {}
            ex_dict["messages"] = []
            try:
                with open(os.path.join(LOG_PATH, ex_id, f"{j}log.log")) as f:
                    ex_log = f.read()
                
                ex_dict = extract_info(ex_log, question, answer, tb_info, ex_dict, ex_id)
                ex_dict["format"] = "chatml"
                sft_json.append(ex_dict)
            except Exception as e:
                print(ex_id, j, e)

with open('sft.jsonl', 'w', encoding='utf-8') as outfile:
    for entry in sft_json:
        json.dump(entry, outfile, ensure_ascii=False)
        outfile.write('\n')
