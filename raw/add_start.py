import json
file_path = 'bird_sft.jsonl'

data = []
str1 = "<formatting>\n"
str2 = "First, I'll decide the expected answer format.\n"
with open(file_path, 'r', encoding='utf-8') as f:
    for line in f:
        if line.strip():
            obj = json.loads(line)
            org_str = obj["messages"][2]["content"]
            obj["messages"][2]["content"] = "\n<|im_start|>think\n" + org_str[len(str1):len(str1)+len(str2)] + org_str[:len(str1)] + org_str[len(str1)+len(str2):]
            data.append(obj)

with open('bird_sft_new.jsonl', 'w', encoding='utf-8') as f:
    for obj in data:
        json_str = json.dumps(obj, ensure_ascii=False)
        f.write(json_str + '\n')
