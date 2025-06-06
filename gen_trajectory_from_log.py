import re
def is_valid_exec_sequence(text):
    def check_once(start, end, text):
        start_count = text.count(start)
        end_count = text.count(end)
        if start_count == 1 and end_count == 1:
            return True
        return False

    # if not check_once("<think>", "</think>", text):
    #     return 0
    if text.count("</think>") != 1:
        return False
    
    if not check_once("<answer>", "</answer>", text):
        return False

    text = text[:text.find("</think>")]
    
    if len(re.findall(r'<exec_sql>\nSELECT', text)) != len(re.findall(r'\nSELECT', text)):
        return False

    all_tag_counts = {
        'exec_sql_open': len(re.findall(r'<exec_sql>', text)),
        'exec_sql_close': len(re.findall(r'</exec_sql>', text)),
        'exec_result_open': len(re.findall(r'<exec_result>', text)),
        'exec_result_close': len(re.findall(r'</exec_result>', text)),
        'SELECT': len(re.findall(r'<exec_sql>\nSELECT', text)),
        ';\n': len(re.findall(r';\n</exec_sql>', text)),
        'schema_linking_open': len(re.findall(r'<schema_linking>', text)),
        'schema_linking_close': len(re.findall(r'</schema_linking>', text)),
    }

    if not (all_tag_counts['exec_sql_open'] == all_tag_counts['exec_sql_close'] ==
            # all_tag_counts['exec_result_open'] == all_tag_counts['exec_result_close'] == 
            all_tag_counts["SELECT"] == all_tag_counts[";\n"]) or all_tag_counts['exec_sql_open'] < 1:
        return False

    if not (all_tag_counts['schema_linking_open'] == all_tag_counts['schema_linking_close']) or all_tag_counts['schema_linking_open'] < 1:
        return False

    return True

def replace_quotes_in_exec_sql_blocks(text):
    def replacer(match):
        content = match.group(1)
        replaced_content = content.replace('"', '`')
        return f"<exec_sql>{replaced_content}</exec_sql>"

    pattern = r"<exec_sql>(.*?)</exec_sql>"
    return re.sub(pattern, replacer, text, flags=re.DOTALL)

def replace_quotes_in_answer_blocks(text):
    def replacer(match):
        content = match.group(1)
        replaced_content = content.replace('"', '`')
        return f"<answer>{replaced_content}</answer>"

    pattern = r"<answer>(.*?)</answer>"
    return re.sub(pattern, replacer, text, flags=re.DOTALL)

import os
import json
from tqdm import tqdm
import pandas as pd
# with open("/mbz/bruce/exec-fb/data_preprocess/data/train/bird.json") as f:
#     bird_data = json.load(f)
file_path = '/mbz/bruce/exec-fb/data_preprocess/data/processed/train.parquet'
bird_data = pd.read_parquet(file_path)

log_dir = "/mbz/bruce/exec-fb/log_all"
gen_data = []
id_rec = []

for step in os.listdir(log_dir):
    step_pth = os.path.join(log_dir, step)
    for example in tqdm(os.listdir(step_pth)):
        example_dir = os.path.join(step_pth, example)
        example_id = example[len("local_BIRD_train_"):len("local_BIRD_train_")+4]
        if example.endswith(".log") and example_id not in id_rec:
            with open(example_dir) as f:
                l = f.read()
            assert l.count("<|im_start|>assistant\n<think>\n") == 1
            l = l[l.find("<|im_start|>assistant\n<think>\n")+len("<|im_start|>assistant\n<think>\n"):]
            if is_valid_exec_sequence(l):
                # l = replace_quotes_in_exec_sql_blocks(l)
                # l = replace_quotes_in_answer_blocks(l)
                user_prompt = None
                for index, row in bird_data.iterrows():
                    if row["reward_model"]["ground_truth"]["example_id"] == f"local_BIRD_train_{example_id}":
                        sys_prompt = row["prompt"][0]["content"]
                        user_prompt = row["prompt"][1]["content"]
                if user_prompt:
                    gen_dict = {
                        "messages": [
                            {"role": "system", "content": sys_prompt},
                            {"role": "user", "content": user_prompt},
                            {"role": "assistant", "content": "<think>\n"+l}
                        ],
                        "format": "chatml"
                    }
                else:
                    print(example_dir)
                    continue
                
                gen_data.append(gen_dict)
                # id_rec.append(example_id)
print(gen_data[0]["messages"][-1]["content"])
print("Length", len(gen_data))

with open("raw/bird_trajectory_log.jsonl", "w") as f:
    for i in gen_data:
        f.write(json.dumps(i) + "\n")
