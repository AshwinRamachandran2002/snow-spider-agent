import json
import os

def make_jsonl(output_file, file1=None, file2=None):
    seen_instance_ids = set()
    merged_data = []

    if file1:
        # Read the first file and store unique instance_ids
        with open(file1, "r", encoding="utf-8") as f1:
            for line in f1:
                entry = json.loads(line)
                instance_id = entry.get("instance_id")
                if instance_id and instance_id not in seen_instance_ids:
                    seen_instance_ids.add(instance_id)
                    merged_data.append(entry)
    if file2:
        # Read the second file and skip duplicate instance_ids
        with open(file2, "r", encoding="utf-8") as f2:
            for line in f2:
                entry = json.loads(line)
                instance_id = entry.get("instance_id")
                if instance_id and instance_id not in seen_instance_ids:
                    seen_instance_ids.add(instance_id)
                    merged_data.append(entry)

    for csv_file in os.listdir("gold_answer"):
        if csv_file.endswith(".csv"):
            ex_id = csv_file.replace(".csv", "")
            dic = {"instance_id": "", "condition_cols": [], "ignore_order": True, "toks": None}
            if "aug" in ex_id or "BIRD" in ex_id or "Spider" in ex_id:
                dic["instance_id"] = ex_id
                
                if "aug0" in ex_id:
                    for line in merged_data:
                        if line["instance_id"] == ex_id.replace("_aug0", "") and len(line["condition_cols"]) <= 1:
                            dic["condition_cols"] = line["condition_cols"]
                            dic["ignore_order"] = line["ignore_order"]

                merged_data.append(dic)
    # Write the merged unique data back to a new JSONL file
    with open(output_file, "w", encoding="utf-8") as out:
        for entry in merged_data:
            json.dump(entry, out, ensure_ascii=False)
            out.write("\n")

if __name__ == "__main__":
    make_jsonl("eval.jsonl", "spider2lite_eval.jsonl", "spider2snow_eval.jsonl")