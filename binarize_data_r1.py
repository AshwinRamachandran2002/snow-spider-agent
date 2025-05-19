import os, json, tqdm, itertools, argparse
import numpy as np
from typing import Dict
from transformers import AutoTokenizer
from utils import utils

IGNORE_INDEX = -100

# ✅ 添加额外特殊符号（保持不被切分）
SPEC_TOKENS = [
    "<answer>", "</answer>", "<think>", "</think>",
    "<exec_sql>", "</exec_sql>", "<exec_result>", "</exec_result>",
    "<schema_linking>", "</schema_linking>"
]

def setup_tokenizer(tokenizer):
    tokenizer.add_special_tokens({"additional_special_tokens": SPEC_TOKENS})
    for token in SPEC_TOKENS:
        token_id = tokenizer.convert_tokens_to_ids(token)
        print(f"Special Token: {token} \t=> ID: {token_id}")
    return tokenizer

def decode_with_ignore_index(tokenizer, label_ids, ignore_index=IGNORE_INDEX, placeholder="<IGNORE>"):
    decoded_tokens = []
    for token_id in label_ids:
        if token_id == ignore_index:
            decoded_tokens.append(placeholder)
        else:
            # Convert single token_id to string using tokenizer
            token_str = tokenizer.decode([token_id], clean_up_tokenization_spaces=False)
            decoded_tokens.append(token_str)
    return ''.join(decoded_tokens)


def chat_template_format_preprocess(
    sources, tokenizer, max_len: int, only_last_turn_loss: bool = False, return_test_input_ids: bool = False
) -> Dict:
    BOS = tokenizer.bos_token or ""
    EOS = tokenizer.eos_token or ""
    IGNORE_INDEX = -100

    word_exec_result = "<exec_result>"
    end_exec_result = "</exec_result>"

    input_ids, labels = [], []

    text = BOS
    label_mask = [BOS]

    for message in sources:
        role = message["role"]
        content = message.get("content", "")

        if role == "system":
            text += content
        elif role == "user":
            text += f"<｜User｜>{content}"
            label_mask += [IGNORE_INDEX] * len(tokenizer(f"<｜User｜>{content}", add_special_tokens=False).input_ids)
        elif role == "assistant":
            assert content is not None
            text += f"<｜Assistant｜>"
            prefix = f"<｜Assistant｜>"
            label_mask += [IGNORE_INDEX] * len(tokenizer(prefix, add_special_tokens=False).input_ids)

            # ✅ exec_result aware masking
            split_parts = content.split(word_exec_result)
            if len(split_parts) == 1:
                # 没有 exec_result，直接处理整段为可训练内容
                text += content + EOS
                content_ids = tokenizer(content, add_special_tokens=False).input_ids
                label_mask += content_ids + tokenizer(EOS, add_special_tokens=False).input_ids
            else:
                processed = ""
                for i, part in enumerate(split_parts):
                    if i == 0:
                        processed += part
                        # print("-"*20)
                        # print(part)
                        part_ids = tokenizer(part, add_special_tokens=False).input_ids
                        label_mask += part_ids
                    else:
                        assert end_exec_result in part
                        exec_content, rest = part.split(end_exec_result, 1)
                        processed += word_exec_result + exec_content + end_exec_result + rest
                        # print("-"*20)
                        # print(word_exec_result + exec_content + end_exec_result + rest)
                        exec_ids = tokenizer(exec_content, add_special_tokens=False).input_ids
                        rest_ids = tokenizer(rest, add_special_tokens=False).input_ids

                        label_mask += tokenizer(word_exec_result, add_special_tokens=False).input_ids
                        label_mask += [IGNORE_INDEX] * len(exec_ids)
                        label_mask += tokenizer(end_exec_result, add_special_tokens=False).input_ids
                        label_mask += rest_ids

                        # print("-"*20)
                        # print(label_mask)
                    
                text += processed + EOS
                label_mask += tokenizer(EOS, add_special_tokens=False).input_ids
            # else:
            #     text += "<｜Assistant｜>"
            #     label_mask += [IGNORE_INDEX] * len(tokenizer("<｜Assistant｜>", add_special_tokens=False).input_ids)

        elif role == "tool":
            text += f"<｜tool▁outputs▁begin｜><｜tool▁output▁begin｜>{content}<｜tool▁output▁end｜>"
            label_mask += tokenizer(
                f"<｜tool▁outputs▁begin｜><｜tool▁output▁begin｜>{content}<｜tool▁output▁end｜>",
                add_special_tokens=False).input_ids
        else:
            raise ValueError(f"Unknown role: {role}")

    input_ids = tokenizer(text, add_special_tokens=False).input_ids
    labels = list(label_mask)
    # assert len(input_ids) == len(labels), f"input_ids:{decode_with_ignore_index(tokenizer, input_ids)}\nlabels:\n{decode_with_ignore_index(tokenizer, labels)}"
    # assert len(input_ids) == len(labels), f"{len(input_ids)}, {len(labels)}"
    # print(decode_with_ignore_index(tokenizer, label_mask))
    if only_last_turn_loss:
        last_idx = text.rfind("<｜Assistant｜>")
        assert last_idx != -1
        prefix_ids = tokenizer(text[:last_idx], add_special_tokens=False).input_ids
        labels[:len(prefix_ids)] = [IGNORE_INDEX] * len(prefix_ids)
    # print(decode_with_ignore_index(tokenizer, labels))
    assert len(input_ids) == len(labels), f"{len(input_ids)}, {len(labels)}"
    if len(input_ids) > max_len:
        print(f"{len(input_ids)} > {max_len}")
        # print(text)
        return None

    if return_test_input_ids:
        return dict(test_input_ids=input_ids, input_ids=input_ids, label=labels)
    else:
        return dict(input_ids=input_ids, label=labels, length=[len(input_ids)])



def read_file_chunk_with_template(args):
    filename, start_position, end_position, worker_id, args = args
    tokenizer = args["tokenizer"]
    max_len = args["max_len"]

    objs = []
    with open(filename, 'r', encoding='utf-8', errors='replace') as f:
        current_position = utils.find_next_line(f, start_position)
        f.seek(current_position)
        if current_position >= end_position:
            return objs

        for _ in tqdm.tqdm(itertools.count(), desc=f"worker {worker_id}", position=worker_id):
            line = f.readline()
            if not line or f.tell() >= end_position:
                break
            # try:
            data = json.loads(line)
            obj = chat_template_format_preprocess(
                data["messages"], tokenizer, max_len=max_len,
                only_last_turn_loss=data.get("only_last_turn_loss", True)
            )
            if obj is not None:
                objs.append(obj)
            # except:
            #     continue
    return objs


def convert_to_uint32(x): return np.array(x, dtype=np.uint32)
def convert_to_int32(x): return np.array(x, dtype=np.int32)

def save_mmap(objs, key, output_path, padding_value):
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    data = [obj[key] for obj in objs]
    max_length = max(len(d) for d in data)
    utils.save_json({"n_samples": len(data), "max_len": max_length}, output_path + ".shape.json")

    mmap = np.memmap(output_path, dtype=np.int32, mode='w+', shape=(len(data), max_length))
    for i, vec in enumerate(data):
        mmap[i] = vec + [padding_value] * (max_length - len(vec))
    mmap.flush()


def tokenize_file(input_path, output_path, tokenizer, max_len, workers=1, chunk_size=1e8, save_format=".npy"):
    output_objs = utils.multi_tasks_from_file(
        input_path, workers=workers, task=read_file_chunk_with_template,
        chunk_size=chunk_size, args={"tokenizer": tokenizer, "max_len": max_len}
    )

    if save_format == ".jsonl":
        utils.write_jsonl_file(output_objs, output_path)
    elif save_format == ".npy":
        for obj in output_objs:
            obj["input_ids"] = convert_to_uint32(obj["input_ids"])
            obj["label"] = convert_to_int32(obj["label"])
            if "test_input_ids" in obj:
                obj["test_input_ids"] = convert_to_uint32(obj["test_input_ids"])
        np.save(output_path + ".npy", output_objs, allow_pickle=True)
    elif save_format == ".mmap":
        save_mmap(output_objs, "input_ids", output_path + ".input_ids.mmap", tokenizer.pad_token_id)
        save_mmap(output_objs, "label", output_path + ".labels.mmap", IGNORE_INDEX)
        save_mmap(output_objs, "length", output_path + ".lengths.mmap", IGNORE_INDEX)


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--input_path', type=str, default="./raw/sft.jsonl")
    parser.add_argument('--output_path', type=str, default="./processed/sft")
    parser.add_argument('--workers', type=int, default=1)
    parser.add_argument('--chunk_size', type=float, default=0.1 * 2 ** 30)
    parser.add_argument('--max_len', type=int, default=32768)
    parser.add_argument('--tokenizer_path', type=str, required=True)
    parser.add_argument('--save_format', type=str, default=".npy", choices=[".npy", ".jsonl", ".mmap"])
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()

    tokenizer = AutoTokenizer.from_pretrained(
        args.tokenizer_path,
        trust_remote_code=True,
        model_max_length=args.max_len * 5,
        padding_side="right",
        add_bos_token=False,
        add_eos_token=False,
        pad_token="<｜end▁of▁sentence｜>",
        eos_token="<｜end▁of▁sentence｜>"
    )

    tokenizer = setup_tokenizer(tokenizer)

    tokenize_file(
        input_path=args.input_path,
        output_path=args.output_path,
        tokenizer=tokenizer,
        max_len=args.max_len,
        workers=args.workers,
        chunk_size=args.chunk_size,
        save_format=args.save_format
    )
