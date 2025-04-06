import os
import torch
import threading
import uuid
import datetime
from verl import DataProto
from concurrent.futures import ThreadPoolExecutor
os.environ["TOKENIZERS_PARALLELISM"] = "true"

from verl.workers.reward_model.reward_utils import get_api_name, SqlEnv, calculate_md5
from verl.workers.reward_model.reward_evaluate import evaluate_spider2sql
from tqdm import tqdm
import shutil
import sys
import re

class RewardManager():
    """
    The reward manager.
    """

    def __init__(self, tokenizer, mode, rewards_config):
        self.tokenizer = tokenizer
        self.mode = mode

        self.successful_final_sql_reward = rewards_config.successful_final_sql_reward
        self.unsuccessful_intermediate_sql_reward = rewards_config.unsuccessful_intermediate_sql_reward
        self.absent_intermediate_thought_reward = rewards_config.absent_intermediate_thought_reward
        self.undiverse_intermediate_sql_reward = rewards_config.undiverse_intermediate_sql_reward
        self.absent_final_sql_reward = rewards_config.absent_final_sql_reward
        self.format_reward = rewards_config.format_reward

        time_now_formatted = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        # self.exec_folder = f"exec_3B_{mode}_{time_now_formatted}"
        # if not os.path.exists(self.exec_folder):
        #     os.mkdir(self.exec_folder)

        self.ground_truths = "data_preprocess/BIRD/gold_results"
        
        self.max_workers = rewards_config.max_workers
        self.val_only = rewards_config.val_only

    def enum_unsuccessful_intermediate_sql(self, response_str, log_path):
        num_total = 0
        num_incorrect = 0
        for part in response_str.split("<exec_sql>")[1:]:
            if "<exec_result>" not in part or "</exec_result>" not in part:
                continue
            exec_result_str = part.split("<exec_result>")[1].split("</exec_result>")[0]
            if "Incorrect SQL Syntax" in exec_result_str:
                num_incorrect += 1
            num_total += 1
        # with open(log_path, "a") as f:
        #     f.write(f"Reward: unsuccessful_intermediate_sql\n")
        #     f.write(f"num_total: {num_total}\n")
        #     f.write(f"num_incorrect: {num_incorrect}\n")
        return (num_incorrect / num_total) * self.unsuccessful_intermediate_sql_reward if num_total > 0 else 0
    
    def enum_absent_intermediate_thought(self, response_str, log_path):
        num_total = 0
        num_absent = 0
        for part in response_str.split("</exec_result>")[1:]:
            intermediate_thought = part.split("<exec_sql>")[0].strip()
            if intermediate_thought == "":
                num_absent += 1
            num_total += 1
        # with open(log_path, "a") as f:
        #     f.write(f"Reward: absent_intermediate_thought\n")
        #     f.write(f"num_total: {num_total}\n")
        #     f.write(f"num_absent: {num_absent}\n")
        return (num_absent / num_total) * self.absent_intermediate_thought_reward if num_total > 0 else 0

    def enum_absent_final_sql(self, response_str, log_path):
        # with open(log_path, "a") as f:
        #     f.write(f"Reward: absent_final_sql\n")
        #     f.write(f"is absent: {1 if '<|im_start|>SQL' not in response_str else 0}\n")
        return self.absent_final_sql_reward if "<|im_start|>SQL" not in response_str else 0

    def enum_distinct_intermediate_sql(self, response_str, log_path):
        num_total = 0
        sql_dict = {}
        for part in response_str.split("<exec_sql>")[1:]:
            exec_sql_str = part.split("</exec_sql>")[0].strip().lower()
            if exec_sql_str not in sql_dict:
                sql_dict[exec_sql_str] = 0
            sql_dict[exec_sql_str] += 1
            num_total += 1
        if num_total == 0:
            return 0
        num_distinct = len(sql_dict)
        # with open(log_path, "a") as f:
        #     f.write(f"Reward: distinct_intermediate_sql\n")
        #     f.write(f"num_total: {num_total}\n")
        #     f.write(f"num_distinct: {num_distinct}\n")
        #     f.write(f"distinct ratio: {num_distinct / num_total}\n")
        return ((num_total - num_distinct) / num_total) * self.undiverse_intermediate_sql_reward if num_total > 0 else 0

    def is_valid_exec_sequence(self, text):
        tag_pattern = re.compile(r'<exec_sql>.*?</exec_sql>|<exec_result>.*?</exec_result>', re.DOTALL)
        tags = tag_pattern.findall(text)

        all_tag_counts = {
            'exec_sql_open': len(re.findall(r'<exec_sql>', text)),
            'exec_sql_close': len(re.findall(r'</exec_sql>', text)),
            'exec_result_open': len(re.findall(r'<exec_result>', text)),
            'exec_result_close': len(re.findall(r'</exec_result>', text)),
        }

        if not (all_tag_counts['exec_sql_open'] == all_tag_counts['exec_sql_close'] ==
                all_tag_counts['exec_result_open'] == all_tag_counts['exec_result_close']):
            return 0

        if not tags:
            return 0

        if len(tags) % 2 != 0:
            return 0

        for i, tag in enumerate(tags):
            if i % 2 == 0 and not tag.startswith('<exec_sql>'):
                return 0
            if i % 2 == 1 and not tag.startswith('<exec_result>'):
                return 0
            if i % 2 == 1 and i > 2 and tag.startswith('<exec_result>'):
                if "No data found for the specified query." in tags[i-2] or "Incorrect SQL Syntax" in tags[i-2]:
                    if "No data found for the specified query." in tags[i] or "Incorrect SQL Syntax" in tags[i]:
                        return self.unsuccessful_intermediate_sql_reward

        return self.format_reward

    def compute_reward_tensor(self, prompt_str, response_str, response_ids, sqlite_path, example_id):
        # print(f"Start Reward {example_id}")

        # reward_tensor = torch.zeros_like(response_ids, dtype=torch.float32)
        # csv_save_path = os.path.join(self.exec_folder, example_id+f"_{threading.get_ident()}.csv")
        
        # log_path = f"{self.exec_folder}/{example_id}_{threading.get_ident()}_{datetime.datetime.now().strftime('%Y-%m-%d_%H-%M-%S')}_{str(uuid.uuid4())}.log"
        # sqlite_path = os.path.join(os.getenv("PATH_TO_SQLITE_PATH"), sqlite_path) if sqlite_path else ''
        # with open(log_path, "a") as f:
        #     f.write(f"starting report for {example_id}\n")
        #     f.write(f"prompt:\n{prompt_str}\n")
        #     f.write(f"response:\n{response_str}\n")
        #     f.write(f"sqlite_path:\n{sqlite_path}\n")
        #     f.write(f"api:\n{get_api_name(example_id)}\n")
        #     f.write(f"csv_save_path:\n{csv_save_path}\n")

        
        # Negative rewards for incorrect intermediate SQLs.
        # Note: Since the token level rewards are any way summed up in the end,
        # we attach negative rewards to positin just before end
        # this is to enable latr metrics calculation
        # hacky method
        # prin = True
        # if prin:
        #     print(f"log_path: {log_path}, response_str: {response_str}, MD5: {calculate_md5(response_str.strip())}")
        # prin = False



        # if self.execute_sql_with_timeout(final_sql, csv_save_path, api=get_api_name(example_id), sqlite_path=sqlite_path) == 0:
        #     is_correct = evaluate_spider2sql(self.ground_truths, csv_save_path, example_id)
        #     if is_correct:
        #         print(f"Correct: {example_id}_{threading.get_ident()}")
        #         with open(log_path, "a") as f:
        #             f.write(f"Reward: successful_final_sql\n")
        #         reward_tensor[-1] = self.successful_final_sql_reward
        response_str = response_str.strip()
        log_folder = os.getenv("EXEC_FOLDER")
        log_path = os.path.join(log_folder, example_id + '_' + calculate_md5(response_str) + ".log")
        csv_path = os.path.join(log_folder, example_id + '_' + calculate_md5(response_str) + ".csv")
        # print(f"log_path: {log_path}")
        
        if not os.path.exists(log_path):
            # print(f"{log_path} doesn't exist, response_str: {response_str}")
            return 0
        if not os.path.exists(csv_path):
            return 0
        # if reward_tensor.shape[0] > 4:
        #     reward_tensor[-2] = self.enum_unsuccessful_intermediate_sql(response_str, log_path)
        #     reward_tensor[-3] = self.enum_absent_intermediate_thought(response_str, log_path)
        #     reward_tensor[-4] = self.enum_distinct_intermediate_sql(response_str, log_path)
        #     reward_tensor[-5] = self.enum_absent_final_sql(response_str, log_path)
        with open(log_path.replace(".log", ".txt")) as f:
            is_correct = int(f.read())
            if is_correct: 
                print(f"Correct: {example_id}")
                # with open(log_path, "a") as f:
                #     f.write(f"Reward: successful_final_sql\n")
                return self.successful_final_sql_reward
        # Format
        return self.is_valid_exec_sequence(response_str)

    def process_item(self, args):
        i, data_item = args

        # recover the prompt
        prompt_ids = data_item.batch['prompts']
        prompt_length = prompt_ids.shape[-1]
        valid_prompt_length = data_item.batch['attention_mask'][:prompt_length].sum()
        valid_prompt_ids = prompt_ids[-valid_prompt_length:]
        prompt_str = self.tokenizer.decode(valid_prompt_ids)

        # recover the response
        response_ids = data_item.batch['responses']
        end_index = len(data_item.batch['attention_mask'][prompt_length:]) - 1
        while data_item.batch['attention_mask'][prompt_length:][end_index] == 0 and -end_index < len(response_ids): 
            end_index -= 1
        response_str = self.tokenizer.decode(response_ids[:end_index + 1])

        # print(f"Attention Mask: {data_item.batch['attention_mask'][prompt_length:].cpu().tolist()}, response_ids: {response_ids.cpu().tolist()}")
        valid_response_length = end_index + 1
        sqlite_path = data_item.non_tensor_batch['reward_model']['sqlite_path']
        example_id = data_item.non_tensor_batch['reward_model']['example_id']

        score = self.compute_reward_tensor(prompt_str, response_str, response_ids, sqlite_path, example_id)
        return i, score, valid_response_length

    def __call__(self, data: DataProto):
        """We will expand this function gradually based on the available datasets"""
        reward_tensor = torch.zeros_like(data.batch['responses'], dtype=torch.float32)
        print(f"CPU num: {os.cpu_count()}")
        # Process items in parallel using ThreadPoolExecutor
        # with ThreadPoolExecutor(max_workers=self.max_workers) as executor:
        #     args = [(i, data[i]) for i in range(len(data))]
        #     results = list(executor.map(self.process_item, args))
        results = []
        for i in range(len(data)):
            result = self.process_item((i, data[i]))
            results.append(result)

        # Fill reward tensor with results
        for i, score, valid_response_length in results:
            reward_tensor[i, valid_response_length - 1] = score
        num_gen = 0
        log_gen = 0
        for i in os.listdir(os.getenv("EXEC_FOLDER")):
            if i.endswith("csv"):
                num_gen += 1
            if i.endswith("log"):
                log_gen += 1
        print(f"Gen results: {num_gen}/{log_gen}, reward_tensor: {reward_tensor.shape}")
        if self.val_only:
            sys.exit(0)
        shutil.rmtree(os.getenv("EXEC_FOLDER"))
        os.mkdir(os.getenv("EXEC_FOLDER"))
        return reward_tensor

