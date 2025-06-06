import json
import os
from collections import defaultdict

def spider_to_table_column(table_json):
    """
    将 Spider 格式的 table json 转为 {table: [column1, column2, ...]} 映射，仅使用 original 名称。
    """
    table_names = table_json["table_names_original"]
    column_names = table_json["column_names_original"]

    table_column_map = defaultdict(list)
    for table_idx, column_name in column_names:
        if table_idx == -1:
            continue  # 忽略 *
        table = table_names[table_idx]
        table_column_map[table].append(column_name)
    
    return dict(table_column_map)

def process_all_tables(input_path, output_dir):
    # 加载 tables.json 文件
    with open(input_path, "r") as f:
        table_data = json.load(f)

    os.makedirs(output_dir, exist_ok=True)

    # 处理每个数据库 schema
    for db in table_data:
        db_id = db["db_id"]
        table_column_map = spider_to_table_column(db)

        output_path = os.path.join(output_dir, f"{db_id}.table_column.json")
        with open(output_path, "w") as f_out:
            json.dump(table_column_map, f_out, indent=2)

        print(f"Saved: {output_path}")

# 示例用法
mode = "dev"
input_tables_json = f"{mode}/{mode}_tables.json"
output_directory = f"{mode}/schema"

process_all_tables(input_tables_json, output_directory)
