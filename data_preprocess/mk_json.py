import argparse
from datasets import load_dataset
import json
import sqlite3

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    # parser.add_argument("--local_dir", default="~/data/bird")
    # parser.add_argument("--dataset_type", type=str, choices=["bird", "spider", "gretelai"])
    parser.add_argument("--dataset_mode", type=str, choices=["train", "dev", "test", "train_aug"])
    parser.add_argument("--parquet_data_path", type=str)

    args = parser.parse_args()

    mode = args.dataset_mode
    dataset = load_dataset(
        "parquet", data_files=args.parquet_data_path, split="train"
    )

    json_list = []
    
    for data in dataset:
        if mode == "dev" or (data["extra_info"]["exec_time"] < 5 and data["extra_info"]["empty_result"] == False and "##SQLERROR##" not in data["extra_info"]["answer"]):
            example = {}
            example["data_source"] = "BIRD"
            
            idx = data["extra_info"]["index"]
            example["example_id"] = f"local_BIRD_{mode}_{idx:04d}"

            example["question"] = data["question"]
            example["answer"] = data["ground_truth"]
            db_id = data["db_id"]
            example["sqlite_path"] = f"BIRD/{mode}/{mode}_databases/{db_id}/{db_id}.sqlite"
            example["input"] = data["db_desc"] + "\n<|im_start|>assistent\n"
            json_list.append(example)
    print(len(json_list))
    with open(f"bird_{args.dataset_mode}_data.json", "w") as f:
        json.dump(json_list, f)