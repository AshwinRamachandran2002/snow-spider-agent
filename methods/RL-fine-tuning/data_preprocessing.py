import argparse
from chat import GPTChat
from tqdm import tqdm
from utils import get_api_name, get_table_info, remove_digits, search_file, execute_sql_api
from reconstruct_data import get_sqlite_data
from prompt import Prompts
import ast
import csv
import os
from reconstruct_data import compress_ddl
import json
import random
import sys
csv.field_size_limit(sys.maxsize)
def schema_linking(dictionaries, task_dict, example_path, chat_session_sl, txt_len_threshold):
    # skip_flag = True
    skip_flag = False
    for eg_id in tqdm(dictionaries):
        chat_session_sl.init_messages()
        print(eg_id)
        # if eg_id == "bq151":
        #     skip_flag = False
        api = get_api_name(eg_id)
        task = task_dict[eg_id]
        table_info = get_table_info(example_path, eg_id, api)
        if len(table_info) < txt_len_threshold or skip_flag:
            continue
        print("Doing schema linking")
        table_struct = table_info[table_info.find("The table structure information is "):]

        prompt = f"Table information: {table_info}\nTask: {task}\nConsider which tables are related to the task. Remove unnecessary tables in {table_struct} and answer table names in ```python``` format in a list.\n"
        table_struct_response = chat_session_sl.get_model_response(prompt, "python")
        try:
            table_names_no_digit = [remove_digits(s) for s in ast.literal_eval(table_struct_response[0])]
        except Exception as e:
            print(e)
            continue
        ddl_paths = search_file(os.path.join(example_path, eg_id), "DDL.csv")
        
        for ddl_path in ddl_paths:
            temp_file = ddl_path.replace("DDL.csv", "DDL_tmp.csv")
            with open(ddl_path, "r", newline="", encoding="utf-8", errors="ignore") as infile, \
                open(temp_file, "w", newline="", encoding="utf-8", errors="ignore") as outfile:
                
                reader = csv.reader(infile)
                writer = csv.writer(outfile)

                header = next(reader)
                writer.writerow(header)

                for row in reader:
                    if any(remove_digits(row[0]) in item for item in table_names_no_digit):
                        writer.writerow(row)

            os.replace(temp_file, ddl_path)

    compress_ddl(example_path)

def get_dict(task, pth):
    dictionaries = [entry for entry in os.listdir(pth) if os.path.isdir(os.path.join(pth, entry))]
    json_path = os.path.join(pth, f"spider2-{task}.jsonl")
    task_dict = {}
    with open(json_path) as f:
        for line in f:
            line_js = json.loads(line)
            if task == "snow":
                task_dict[line_js['instance_id']] = line_js['instruction']
            if task == "lite":
                task_dict[line_js['instance_id']] = line_js['question']
    return dictionaries, task_dict

def get_spider2_data_dict(task_dict_snow, task_dict_lite, combined_list, args, task="train"):
    dict_list = []
    for sql_id in tqdm(combined_list):
        # print(sql_id)
        sql_dict = {}
        sqlite_path = None
        if not sql_id.endswith("jsonl"):
            api = get_api_name(sql_id)
            sql_dict["example_id"] = sql_id
            sql_dict["data_source"] = "Spider2.0"
            if sql_id.startswith("sf"):
                sql_dict["question"] = task_dict_snow[sql_id]
                if task == "train":
                    with open(os.path.join(args.snow_gold_sql_path_training, sql_id + ".sql")) as f:
                        sql_dict["answer"] = f.read()

                # if not os.path.exists(args.Spider2_executed_results_path):
                #     os.mkdir(args.Spider2_executed_results_path)
                # Spider2_executed_results_id = os.path.join(args.Spider2_executed_results_path, sql_id)
                # if not os.path.exists(Spider2_executed_results_id):
                #     os.mkdir(Spider2_executed_results_id)
                #     Spider2_executed_results_id_path = os.path.join(Spider2_executed_results_id, "results.csv")
                # # if not os.path.exists(Spider2_executed_results_id_path):
                #     results = execute_sql_api(sql_dict["answer"], Spider2_executed_results_id_path, api, sqlite_path=sqlite_path)
                #     if results != 0:
                #         print(results)
                sql_dict["gold_results_path"] = os.path.join(args.snow_gold_sql_path.replace("sql", "exec_result"), sql_id)
                with open(os.path.join(args.snow_path, sql_id, "prompts.txt")) as f:
                    question = sql_dict["question"]
                    sql_dict["input"] = f.read() + f"\nQuestion: {question}\n"
            else:
                sql_dict["question"] = task_dict_lite[sql_id]
                if task == "train":
                    with open(os.path.join(args.lite_gold_sql_path_training, sql_id + ".sql")) as f:
                        sql_dict["answer"] = f.read()
                if sql_id.startswith("local"):
                    id_path = os.path.join(args.lite_path, sql_id)
                    for file in os.listdir(id_path):
                        if file.endswith(".sqlite"):
                            sql_dict["sqlite_path"] = os.path.join(id_path, file)
                            assert sql_dict["sqlite_path"]
                            sqlite_path = sql_dict["sqlite_path"]
                sql_dict["gold_results_path"] = os.path.join(args.lite_gold_sql_path.replace("sql", "exec_result"), sql_id)
                with open(os.path.join(args.lite_path, sql_id, "prompts.txt")) as f:
                    question = sql_dict["question"]
                    sql_dict["input"] = f.read() + f"\nQuestion: {question}\n"

            dict_list.append(sql_dict)
    return dict_list

def split_Spider2(task_dict_snow, task_dict_lite, args):
    snow_gold_sql_ids = [i.replace(".sql", "") for i in os.listdir(args.snow_gold_sql_path)]
    snow_all_ids = [i for i in os.listdir(args.snow_path)]
    lite_gold_sql_ids = [i.replace(".sql", "") for i in os.listdir(args.lite_gold_sql_path)]
    lite_all_ids = [i for i in os.listdir(args.lite_path)]
    gold_list = list(set(snow_gold_sql_ids) | set(lite_gold_sql_ids))
    gold_sampled = random.sample(gold_list, 199)

    snow_easier_ids = ['sf014', 'sf044', 'sf_bq005', 'sf_bq006', 'sf_bq010', 'sf_bq017', 'sf_bq018', 'sf_bq021', 'sf_bq025', 'sf_bq032', 'sf_bq033', 'sf_bq034', 'sf_bq035', 'sf_bq042', 'sf_bq056', 'sf_bq059', 'sf_bq060', 'sf_bq061', 'sf_bq066', 'sf_bq076', 'sf_bq077', 'sf_bq078', 'sf_bq081', 'sf_bq085', 'sf_bq088', 'sf_bq090', 'sf_bq091', 'sf_bq096', 'sf_bq097', 'sf_bq103', 'sf_bq109', 'sf_bq113', 'sf_bq115', 'sf_bq121', 'sf_bq126', 'sf_bq130', 'sf_bq143', 'sf_bq151', 'sf_bq158', 'sf_bq161', 'sf_bq171', 'sf_bq172', 'sf_bq176', 'sf_bq210', 'sf_bq211', 'sf_bq213', 'sf_bq214', 'sf_bq216', 'sf_bq218', 'sf_bq219', 'sf_bq223', 'sf_bq224', 'sf_bq227', 'sf_bq228', 'sf_bq232', 'sf_bq252', 'sf_bq255', 'sf_bq264', 'sf_bq270', 'sf_bq279', 'sf_bq280', 'sf_bq281', 'sf_bq282', 'sf_bq284', 'sf_bq285', 'sf_bq286', 'sf_bq289', 'sf_bq300', 'sf_bq302', 'sf_bq303', 'sf_bq308', 'sf_bq309', 'sf_bq310', 'sf_bq321', 'sf_bq327', 'sf_bq328', 'sf_bq330', 'sf_bq334', 'sf_bq341', 'sf_bq345', 'sf_bq349', 'sf_bq350', 'sf_bq352', 'sf_bq355', 'sf_bq357', 'sf_bq359', 'sf_bq361', 'sf_bq362', 'sf_bq375', 'sf_bq377', 'sf_bq379', 'sf_bq389', 'sf_bq392', 'sf_bq394', 'sf_bq396', 'sf_bq399', 'sf_bq407', 'sf_bq414', 'sf_bq419', 'sf_bq444', 'sf_ga001', 'sf_ga002', 'sf_ga003', 'sf_ga004', 'sf_ga010', 'sf_ga020', 'sf_local008', 'sf_local009', 'sf_local019', 'sf_local021', 'sf_local022', 'sf_local023', 'sf_local029', 'sf_local031', 'sf_local038', 'sf_local039', 'sf_local041', 'sf_local054', 'sf_local056', 'sf_local058', 'sf_local065', 'sf_local067', 'sf_local071', 'sf_local072', 'sf_local074', 'sf_local075', 'sf_local078', 'sf_local097', 'sf_local099', 'sf_local141', 'sf_local163', 'sf_local197', 'sf_local198', 'sf_local199', 'sf_local201', 'sf_local202', 'sf_local210', 'sf_local218', 'sf_local221', 'sf_local244', 'sf_local274', 'sf_local284', 'sf_local309', 'sf_local311', 'sf_local329']
    lite_easier_ids = ['bq002', 'bq009', 'bq010', 'bq018', 'bq021', 'bq025', 'bq032', 'bq034', 'bq035', 'bq042', 'bq060', 'bq061', 'bq066', 'bq076', 'bq077', 'bq078', 'bq085', 'bq090', 'bq097', 'bq105', 'bq109', 'bq113', 'bq115', 'bq123', 'bq126', 'bq130', 'bq161', 'bq172', 'bq204', 'bq228', 'bq232', 'bq235', 'bq279', 'bq280', 'bq281', 'bq282', 'bq284', 'bq285', 'bq286', 'bq300', 'bq301', 'bq302', 'bq303', 'bq310', 'bq327', 'bq328', 'bq330', 'bq352', 'bq355', 'bq357', 'bq362', 'bq374', 'bq389', 'bq392', 'bq394', 'bq396', 'bq414', 'ga001', 'ga002', 'ga003', 'ga004', 'ga007', 'ga010', 'ga011', 'ga017', 'ga025', 'local004', 'local017', 'local019', 'local022', 'local023', 'local029', 'local031', 'local038', 'local039', 'local041', 'local054', 'local056', 'local058', 'local059', 'local065', 'local071', 'local072', 'local074', 'local075', 'local078', 'local097', 'local099', 'local141', 'local152', 'local163', 'local195', 'local198', 'local199', 'local202', 'local210', 'local218', 'local221', 'local229', 'local284', 'local301', 'local309', 'local311', 'local329', 'sf001', 'sf014', 'sf044', 'sf_bq005', 'sf_bq017', 'sf_bq033', 'sf_bq056', 'sf_bq091', 'sf_bq158', 'sf_bq171', 'sf_bq176', 'sf_bq210', 'sf_bq211', 'sf_bq213', 'sf_bq214', 'sf_bq216', 'sf_bq219', 'sf_bq223', 'sf_bq224', 'sf_bq252', 'sf_bq255', 'sf_bq264', 'sf_bq289', 'sf_bq321', 'sf_bq334', 'sf_bq341', 'sf_bq345', 'sf_bq349', 'sf_bq359', 'sf_bq361', 'sf_bq375', 'sf_bq377', 'sf_bq444']
    easier_list = list(set(snow_easier_ids) | set(lite_easier_ids))
    easier_sampled = random.sample(easier_list, 199)

    combined_list = list(set(gold_sampled) | set(easier_sampled))
    print(f"Spider2.0 training data number: {len(combined_list)}")
    snow_test_list = list(set(snow_all_ids) - set(combined_list))
    snow_test_all_list = snow_all_ids
    lite_test_list = list(set(lite_all_ids) - set(combined_list))
    lite_test_all_list = lite_all_ids

    spider2_train_data = get_spider2_data_dict(task_dict_snow, task_dict_lite, combined_list, args, task="train")
    snow_test_data = get_spider2_data_dict(task_dict_snow, task_dict_lite, snow_test_list, args, task="test")
    snow_test_all_data = get_spider2_data_dict(task_dict_snow, task_dict_lite, snow_test_all_list, args, task="test")
    lite_test_data = get_spider2_data_dict(task_dict_snow, task_dict_lite, lite_test_list, args, task="test")
    lite_test_all_data = get_spider2_data_dict(task_dict_snow, task_dict_lite, lite_test_all_list, args, task="test")
    return spider2_train_data, snow_test_data, snow_test_all_data, lite_test_data, lite_test_all_data

def get_spider1_data_dict(args, min_token_len=50):
    json_paths = ["data/Spider/spider_data/train_spider.json", "data/Spider/spider_data/train_others.json", "data/Spider/spider_data/test.json", "data/Spider/spider_data/dev.json"]
    eg_count = 0
    dict_list = []
    if not os.path.exists(args.Spider_executed_results_path):
        os.mkdir(args.Spider_executed_results_path)
    for json_path in json_paths:
        data_type = json_path.split('.')[0].split('/')[-1]
        if data_type == "test":
            db_path = "data/Spider/spider_data/test_database"
        else:
            db_path = "data/Spider/spider_data/database"
        print(f"Processing Spider {data_type}")
        with open(json_path) as f:
            examples = json.load(f)
        for ex in tqdm(examples):
            sql_dict = {}
            tokens = len(ex["query_toks"])
            if tokens > min_token_len:
                id_name = f"local_Spider_{eg_count:03d}" if eg_count < 1000 else f"local_Spider_{eg_count}"
                sqlite_path = os.path.join(db_path, ex["db_id"], ex["db_id"] + ".sqlite")
                assert os.path.exists(sqlite_path)
                sql_dict["data_source"] = "Spider1.0"
                sql_dict["example_id"] = id_name
                sql_dict["question"] = ex["question"]
                sql_dict["answer"] = ex["query"]
                sql_dict["sqlite_path"] = sqlite_path
                # with open(os.path.join(spider_example_pth, f"Spider_{data_type}.jsonl"), "a") as f:
                #     f.write(json.dumps(ex, ensure_ascii=False) + "\n")
                table_names, prompts = get_sqlite_data(sqlite_path)
                prompts += "The table structure information is (table names): \n" + str(table_names) + "\n"
                question = sql_dict["question"]
                sql_dict["input"] = prompts + f"\nQuestion: {question}\n"
                Spider_executed_results_id_path = os.path.join(args.Spider_executed_results_path, id_name + ".csv")
                results = execute_sql_api(sql_dict["answer"], Spider_executed_results_id_path, "sqlite", sqlite_path=sqlite_path)
                if results != 0:
                    if results == "No data found for the specified query.\n":
                        continue
                    print(results)
                sql_dict["gold_results_path"] = os.path.join(Spider_executed_results_id_path)
                eg_count += 1
                dict_list.append(sql_dict)
    return dict_list

def get_bird_data_dict(args, min_token_len=50):
    json_paths = ["data/BIRD/dev/dev.json", "data/BIRD/train/train.json"]
    eg_count = 0
    dict_list = []
    if not os.path.exists(args.BIRD_executed_results_path):
        os.mkdir(args.BIRD_executed_results_path)
    for json_path in json_paths:
        data_type = json_path.split('.')[0].split('/')[-1]
        db_path = f"data/BIRD/{data_type}/{data_type}_databases"
        print(f"Processing BIRD {data_type}")
        with open(json_path) as f:
            examples = json.load(f)
        for ex in tqdm(examples):
            sql_dict = {}
            tokens = ex["SQL"].split()
            if len(tokens) > min_token_len:
                id_name = f"local_BIRD_{data_type}_{eg_count:03d}" if eg_count < 1000 else f"local_BIRD_{data_type}_{eg_count}"
                sqlite_path = os.path.join(db_path, ex["db_id"], ex["db_id"] + ".sqlite")
                assert os.path.exists(sqlite_path)
                sql_dict["data_source"] = "BIRD"
                sql_dict["example_id"] = id_name
                sql_dict["question"] = ex["question"]
                sql_dict["answer"] = ex["SQL"]
                sql_dict["sqlite_path"] = sqlite_path

                external = ''
                if os.path.exists(os.path.join(db_path, "database_description")):
                    external = 'Column description:\n'
                    for table_name in os.listdir(os.path.join(db_path, "database_description")):
                        with open(os.path.join(db_path, "database_description", table_name), errors="ignore") as f:
                            table_name = table_name.removesuffix(".csv")
                            external += f"Table name: {table_name}\n"
                            external += f.read()
                    external += f"\nEvidence of the task: {ex['evidence']}"

                table_names, prompts = get_sqlite_data(sqlite_path)
                prompts += "The table structure information is (table names): \n" + str(table_names) + "\n"
                question = sql_dict["question"]
                sql_dict["input"] = prompts + external + f"\nQuestion: {question}\n"
                BIRD_executed_results_id_path = os.path.join(args.BIRD_executed_results_path, id_name + ".csv")
                results = execute_sql_api(sql_dict["answer"], BIRD_executed_results_id_path, "sqlite", sqlite_path=sqlite_path)
                if results != 0:
                    # if results == "No data found for the specified query.\n":
                    #     continue
                    # print(results)
                    continue
                sql_dict["gold_results_path"] = os.path.join(BIRD_executed_results_id_path)
                eg_count += 1
                dict_list.append(sql_dict)
    return dict_list

def save_jsonl(file_name, data):
    with open(f"data/{file_name}.jsonl", "w", encoding="utf-8") as f:
        for entry in data:
            json.dump(entry, f, ensure_ascii=False)
            f.write("\n")

def data_augmentation(args, training_data, aug_prompt, aug_index):
    if not os.path.exists(args.Spider2_aug_results_path):
        os.mkdir(args.Spider2_aug_results_path)
    chat_session_ag = GPTChat(args.azure, args.model_api)
    prompt = f"This data point comes from a text-to-SQL task. Please perform one data augmentation based on the given task description and its corresponding gold SQL: {aug_prompt}\n"
    prompt += "The answer format should be:\n```sql\n-- Task: Task Description\nSQL here\n```\nThe answer should be in one ```sql\n``` blocks with code comments like '-- Task: ' to describe the task.\n"
    prompt += "SQL query should be an 'SELECT' query that can be executed. For CTEs without 'SELECT', you should add one to make it complete.\n"
    augmented_data = []
    sql_prompt = Prompts()
    for ex in tqdm(training_data):
        chat_session_ag.init_messages()
        if ex["data_source"] == "Spider2.0":
            api = get_api_name(ex["example_id"])
            table_struct = ex['input'][ex['input'].find("The table structure information is "):]
            table_struct = table_struct[:table_struct.find("Question")]
            prompt += "The table structure is: " + table_struct
            prompt += f"The SQL dialect is {api}. Basic usage: " + sql_prompt.get_prompt_dialect_basic(api)
            prompt += "Task: " + ex['question'] + "\nGold SQL: " + ex['answer']
            response = []
            if os.path.exists(os.path.join(args.Spider2_aug_results_path, ex["example_id"]+ f"_aug{aug_index}"+".csv")):
                continue
            inputs = prompt
            success_flag = False
            while not success_flag:
                response = chat_session_ag.get_model_response(inputs, "sql")
                if all("-- Task" in i for i in response):
                    response = [response[0]]
                    for i in range(len(response)):
                        ex_copy = ex.copy()
                        ex_copy["example_id"] = ex["example_id"] + f"_aug{i}"
                        ex_copy["question"] = response[i].split("\n")[0]
                        ex_copy["answer"] = response[i]

                        sqlite_path = None
                        if "sqlite_path" in ex.keys():
                            ex_copy["sqlite_path"] = ex["sqlite_path"]
                            sqlite_path = ex["sqlite_path"]
                        gold_results_path = os.path.join(args.Spider2_aug_results_path, ex_copy["example_id"]+".csv")
                        if not os.path.exists(gold_results_path):
                            results = execute_sql_api(ex_copy["answer"], gold_results_path, api, sqlite_path=sqlite_path)
                            if results != 0:
                                print(ex["example_id"])
                                print(results)
                                inputs = f"Input SQL: {response[0]}"
                                inputs += "The error information is: " + str(results) + "\nPlease correct it.\n"
                                if "002003" in str(results):
                                    inputs += f"The SQL dialect is {api}. Basic usage: " + sql_prompt.get_prompt_dialect_basic(api)
                                    inputs += f"You can get database name, schema name in {table_struct}.\n"
                                    # inputs += f"You should follow names of database.schema.table in: " + ex["answer"]
                                break
                            with open(gold_results_path.replace(".csv", ".txt"), "w") as f:
                                f.write(ex_copy["question"])
                            with open(gold_results_path.replace(".csv", ".sql"), "w") as f:
                                f.write(ex_copy["answer"])
                        else:
                            with open(gold_results_path.replace(".csv", ".txt")) as f:
                                ex_copy["question"] = f.read()
                            with open(gold_results_path.replace(".csv", ".sql")) as f:
                                ex_copy["answer"] = f.read()
                        ex_copy["gold_results_path"] = gold_results_path
                        augmented_data.append(ex_copy)
                        success_flag = True
                else:
                    inputs = "The answer should be in one ```sql\n``` block with code comments like '-- Task: ' to describe the task.\n"
                    inputs += f"The SQL dialect is {api}. Basic usage: " + sql_prompt.get_prompt_dialect_basic(api)
    training_data_aug = training_data + augmented_data
    save_jsonl("training_data_aug", training_data_aug)

def main(args):
    dictionaries_snow, task_dict_snow = get_dict("snow", args.snow_path)
    dictionaries_lite, task_dict_lite = get_dict("lite", args.lite_path)
    if args.schema_linking:
        chat_session_sl = GPTChat(args.azure, args.model_api)
        schema_linking(dictionaries_snow, task_dict_snow, args.snow_path, chat_session_sl, args.txt_len_threshold)
        schema_linking(dictionaries_lite, task_dict_lite, args.lite_path, chat_session_sl, args.txt_len_threshold)
    if args.load_data:
        with open(args.load_data, "r", encoding="utf-8") as f:
            training_data = [json.loads(line) for line in f]
    else:
        spider2_train_data, snow_test_data, snow_test_all_data, lite_test_data, lite_test_all_data = split_Spider2(task_dict_snow, task_dict_lite, args)
        spider1_data = get_spider1_data_dict(args)
        bird_data = get_bird_data_dict(args)
        training_data = spider2_train_data + spider1_data + bird_data
        save_jsonl("training_data", training_data)
        save_jsonl("snow_test_data", snow_test_data)
        save_jsonl("snow_test_all_data", snow_test_all_data)
        save_jsonl("lite_test_data", lite_test_data)
        save_jsonl("lite_test_all_data", lite_test_all_data)
    if args.data_augmentaion:
        aug0_prompt = "\nRefine the task description to make it more precise and accurate while keeping the original SQL unchanged.\n"
        aug1_prompt = "\nSimplify the task by selecting an intermediate step from the gold SQL and generating an easier task accordingly. (You can only use tables and columns from the original SQL. If the answer could be very long, add LIMIT 100 at end and modify the task description accordingly.)\n"
        data_augmentation(args, training_data, aug0_prompt, 0)
        data_augmentation(args, training_data, aug1_prompt, 1)

if __name__ == '__main__':
    random.seed(42)
    parser = argparse.ArgumentParser()
    parser.add_argument('--snow_path', type=str, default="data/Spider2.0_snow")
    parser.add_argument('--lite_path', type=str, default="data/Spider2.0_lite")
    parser.add_argument('--snow_gold_sql_path', type=str, default="../../spider2-snow/evaluation_suite/gold/sql")
    parser.add_argument('--snow_gold_sql_path_training', type=str, default="data/Spider2.0_snow_gold_sql")
    parser.add_argument('--lite_gold_sql_path', type=str, default="../../spider2-lite/evaluation_suite/gold/sql")
    parser.add_argument('--lite_gold_sql_path_training', type=str, default="data/Spider2.0_lite_gold_sql")
    parser.add_argument('--Spider_executed_results_path', type=str, default="data/Spider_exec_results")
    parser.add_argument('--Spider2_aug_results_path', type=str, default="data/Spider2_aug_results")
    parser.add_argument('--BIRD_executed_results_path', type=str, default="data/BIRD_exec_results")
    parser.add_argument('--model_api', type=str, default="o1-preview")
    parser.add_argument('--azure', action="store_true")
    parser.add_argument('--temperature', type=float, default=0)
    parser.add_argument('--txt_len_threshold', type=float, default=50000)
    parser.add_argument('--data_augmentaion', action="store_true")
    parser.add_argument('--schema_linking', action="store_true")
    parser.add_argument('--load_data', type=str, default=None)
    args = parser.parse_args()
    main(args)
