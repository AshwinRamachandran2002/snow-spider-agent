# import json
# with open("/mbz/bruce/sft/raw/bird_trajectory_log.jsonl") as f:
#     data = [json.loads(i) for i in f]

# print(data[0]["messages"][0]["content"])
# print(data[0]["messages"][1]["content"])

import numpy as np
from transformers import AutoTokenizer
tokenizer = AutoTokenizer.from_pretrained("/mbz/bruce/exec-fb/models/Qwen3-8B-sft")
file_path = "/mbz/bruce/sft/processed/bird_trajectory_log.jsonl.npy"
data = np.load(file_path, allow_pickle=True)

IGNORE_INDEX = -100
def decode_with_ignore_index(label_ids, ignore_index=IGNORE_INDEX, placeholder="<IGNORE>"):
    decoded_tokens = []
    for token_id in label_ids:
        if token_id == ignore_index:
            decoded_tokens.append(placeholder)
        else:
            # Convert single token_id to string using tokenizer
            token_str = tokenizer.decode([token_id], clean_up_tokenization_spaces=False)
            decoded_tokens.append(token_str)
    return ''.join(decoded_tokens)

# 查看前几条数据
for i, item in enumerate(data[:1]):
    print(f"Entry {i}")
    print(decode_with_ignore_index(item["input_ids"]))
    print(decode_with_ignore_index(item["label"]))
