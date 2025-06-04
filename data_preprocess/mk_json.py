import argparse
from datasets import load_dataset
import json
from transformers import AutoTokenizer

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    # parser.add_argument("--local_dir", default="~/data/bird")
    # parser.add_argument("--dataset_type", type=str, choices=["bird", "spider", "gretelai"])
    parser.add_argument("--dataset_mode", type=str, choices=["train", "dev"])
    parser.add_argument("--parquet_data_path", type=str)

    args = parser.parse_args()

    mode = args.dataset_mode
    dataset = load_dataset(
        "parquet", data_files=args.parquet_data_path, split="train"
    )
    tokenizer = AutoTokenizer.from_pretrained("Qwen/Qwen2.5-1.5B-instruct")
    json_list = []
    token_count = []
    for data in dataset:
        if mode == "dev" or ("##SQLERROR##" not in data["extra_info"]["answer"] and "No data found for the specified query.\n" not in data["extra_info"]["answer"]):
            example = {}
            example["data_source"] = "BIRD"
            
            idx = data["extra_info"]["index"]
            example["example_id"] = f"local_BIRD_{mode}_{idx:04d}"

            example["question"] = data["question"]
            example["answer"] = data["ground_truth"]
            db_id = data["db_id"]
            example["sqlite_path"] = f"BIRD/{mode}/{mode}_databases/{db_id}/{db_id}.sqlite"
            example["input"] = data["db_desc"]
            json_list.append(example)
            token_count.append(tokenizer(data["db_desc"], return_tensors="pt").input_ids.shape[1])
    print(len(json_list))
    print(f"Max tokens: {max(token_count)}, mean: {sum(token_count)/len(token_count)}, > 8k: {sum([i > 8192 for i in token_count])}")
    with open(f"data/{args.dataset_mode}/bird.json", "w") as f:
        json.dump(json_list, f)