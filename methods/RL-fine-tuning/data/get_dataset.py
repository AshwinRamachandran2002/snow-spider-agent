import json
import sqlite3
import os
import shutil
from tqdm import tqdm

def process_BIRD(file_path):
    data_type = file_path.split('.')[0].split('/')[-1]
    print(f"Processing BIRD {data_type}")
    with open(file_path) as f:
        examples = json.load(f)

    BIRD_example_pth = f"BIRD/examples_{data_type}"
    if os.path.exists(BIRD_example_pth):
        shutil.rmtree(BIRD_example_pth)
    os.mkdir(BIRD_example_pth)
    eg_count = 1
    for ex in tqdm(examples):
        tokens = ex["SQL"].split()
        if len(tokens) > min_token_len:
            folder_name = f"local_BIRD_{data_type}_{eg_count:03d}" if eg_count < 1000 else f"local_BIRD_{data_type}_{eg_count}"
            target_path = os.path.join(BIRD_example_pth, folder_name)
            os.mkdir(target_path)
            DB_path = os.path.join("BIRD", data_type, data_type + "_databases", ex['db_id'])
            
            # shutil.copy(os.path.join(DB_path, ex['db_id'] + ".sqlite"), target_path)
            
            external = 'Column description:\n'
            for table_name in os.listdir(os.path.join(DB_path, "database_description")):
                with open(os.path.join(DB_path, "database_description", table_name), errors="ignore") as f:
                    table_name = table_name.removesuffix(".csv")
                    external += f"Table name: {table_name}\n"
                    external += f.read()
            external += f"Evidence: {ex['evidence']}"

            with open(os.path.join(target_path, "external_knowledge.md"), "w") as f:
                f.write(external)

            ex["instance_id"] = folder_name
            ex['external_knowledge'] = "external_knowledge.md"
            ex.pop("evidence")
            # ex.pop("SQL")
            with open(os.path.join(BIRD_example_pth, f"BIRD_{data_type}.jsonl"), "a") as f:
                f.write(json.dumps(ex, ensure_ascii=False) + "\n")
            eg_count += 1


def process_spider(file_path):
    data_type = file_path.split('.')[0].split('/')[-1]
    print(f"Processing Spider {data_type}")
    with open(file_path) as f:
        examples = json.load(f)

    spider_example_pth = f"Spider/examples_{data_type}"
    if os.path.exists(spider_example_pth):
        shutil.rmtree(spider_example_pth)
    os.mkdir(spider_example_pth)
    eg_count = 1
    for ex in tqdm(examples):
        tokens = len(ex["query_toks"])
        if tokens > min_token_len:
            folder_name = f"local_Spider_{eg_count:03d}" if eg_count < 1000 else f"local_Spider_{eg_count}"
            target_path = os.path.join(spider_example_pth, folder_name)
            os.mkdir(target_path)

            ex["instance_id"] = folder_name
            ex['external_knowledge'] = None
            ex.pop("query_toks")
            ex.pop("query_toks_no_value")
            ex.pop("question_toks")
            ex.pop("sql")
            with open(os.path.join(spider_example_pth, f"Spider_{data_type}.jsonl"), "a") as f:
                f.write(json.dumps(ex, ensure_ascii=False) + "\n")
            eg_count += 1

def read_SQLite(file_path):

    conn = sqlite3.connect(file_path)
    cursor = conn.cursor()

    cursor.execute("SELECT name, sql FROM sqlite_master WHERE type='table';")

    for name, ddl in cursor.fetchall():
        print(f"Table: {name}\nDDL:\n{ddl}\n")

    conn.close()

if __name__ == '__main__':
    BIRD_train_json = "BIRD/train/train.json"
    BIRD_dev_json = "BIRD/dev/dev.json"
    spider_train_json = "Spider/spider_data/train_spider.json"
    spider_train_others_json = "Spider/spider_data/train_others.json"
    spider_test_json = "Spider/spider_data/test.json"
    spider_dev_json = "Spider/spider_data/dev.json"
    min_token_len = 50
    # read_SQLite("BIRD/train/train_databases/retail_world/retail_world.sqlite")
    process_BIRD(BIRD_train_json)
    process_BIRD(BIRD_dev_json)
    process_spider(spider_train_json)
    process_spider(spider_train_others_json)
    process_spider(spider_test_json)
    process_spider(spider_dev_json)