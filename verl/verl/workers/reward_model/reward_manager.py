import os
import torch
import threading
import datetime
from verl import DataProto
from concurrent.futures import ThreadPoolExecutor
os.environ["TOKENIZERS_PARALLELISM"] = "true"

from verl.workers.reward_model.reward_utils import execute_sql_with_timeout, get_api_name
from verl.workers.reward_model.reward_evaluate import evaluate_spider2sql

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

        time_now_formatted = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        self.exec_folder = f"exec_3B_{mode}_{time_now_formatted}"
        if not os.path.exists(self.exec_folder):
            os.mkdir(self.exec_folder)

        self.ground_truths = "deepscaler/rewards/gold/gold_answer"

    def enum_unsuccessful_intermediate_sql(self, response_str):
        num_total = 0
        num_incorrect = 0
        for part in response_str.split("<exec_sql>")[1:]:
            if "<exec_result>" not in part or "</exec_result>" not in part:
                continue
            exec_result_str = part.split("<exec_result>")[1].split("</exec_result>")[0]
            if "Incorrect SQL Syntax" in exec_result_str:
                num_incorrect += 1
            num_total += 1
        return (num_incorrect / num_total) * self.unsuccessful_intermediate_sql_reward if num_total > 0 else 0
    
    def enum_absent_intermediate_thought(self, response_str):
        num_total = 0
        num_absent = 0
        for part in response_str.split("</exec_result>")[1:]:
            intermediate_thought = part.split("<exec_sql>")[0].strip()
            if intermediate_thought == "":
                num_absent += 1
            num_total += 1
        return (num_absent / num_total) * self.absent_intermediate_thought_reward if num_total > 0 else 0

    def enum_absent_final_sql(self, response_str):
        return self.absent_final_sql_reward if "<|im_start|>SQL" not in response_str else 0
    
    def enum_distinct_intermediate_sql(self, response_str):
        num_total = 0
        sql_dict = {}
        for part in response_str.split("<exec_sql>")[1:]:
            exec_sql_str = part.split("</exec_sql>")[0].strip().lower()
            if exec_sql_str not in sql_dict:
                sql_dict[exec_sql_str] = 0
            sql_dict[exec_sql_str] += 1
            num_total += 1
        num_distinct = len(sql_dict)
        return ((num_total - num_distinct) / num_total) * self.undiverse_intermediate_sql_reward if num_total > 0 else 0

    def compute_reward_tensor(self, response_str, response_ids, sqlite_path, example_id):
        print(f"Start Reward {example_id}")

        reward_tensor = torch.zeros_like(response_ids, dtype=torch.float32)
        csv_save_path = os.path.join(self.exec_folder, example_id+f"_{threading.get_ident()}.csv")    
  
        with open(f"{self.exec_folder}/{example_id}_{threading.get_ident()}.log", "a") as f:
            f.write(f"example_id:\n{example_id}\n")
            f.write(f"response:\n{response_str}\n")
            f.write(f"sqlite_path:\n{sqlite_path}\n")
            f.write(f"api:\n{get_api_name(example_id)}\n")
            f.write(f"csv_save_path:\n{csv_save_path}\n")

        # Negative rewards for incorrect intermediate SQLs.
        # Note: Since the token level rewards are any way summed up in the end,
        # we attach negative rewards to positin just before end
        # this is to enable latr metrics calculation
        # hacky method
        if reward_tensor.shape[0] > 4:
            reward_tensor[-2] = self.enum_unsuccessful_intermediate_sql(response_str)
            reward_tensor[-3] = self.enum_absent_intermediate_thought(response_str)
            reward_tensor[-4] = self.enum_distinct_intermediate_sql(response_str)
            reward_tensor[-5] = self.enum_absent_final_sql(response_str)

        # Extract solution.
        if "<|im_start|>SQL" in response_str:
            final_sql = response_str.split("<|im_start|>SQL")[1].split("<|im_end|>")[0]
        else:
            return reward_tensor

        if execute_sql_with_timeout(final_sql, csv_save_path, api=get_api_name(example_id), sqlite_path=sqlite_path) == 0:
            is_correct = evaluate_spider2sql(self.ground_truths, csv_save_path, example_id)
            if is_correct:
                print(f"Correct: {example_id}_{threading.get_ident()}")
                reward_tensor[-1] = self.successful_final_sql_reward

        print(f"End Reward {example_id}")
        return reward_tensor

    def process_item(self, args):
        i, data_item = args

        # recover the prompt
        prompt_ids = data_item.batch['prompts']
        prompt_length = prompt_ids.shape[-1]

        # recover the response
        response_ids = data_item.batch['responses']
        end_index = len(data_item.batch['attention_mask'][prompt_length:]) - 1
        while data_item.batch['attention_mask'][prompt_length:][end_index] == 0:
            end_index -= 1
        response_str = self.tokenizer.decode(response_ids[:end_index + 1])

        sqlite_path = data_item.non_tensor_batch['reward_model']['sqlite_path']
        example_id = data_item.non_tensor_batch['reward_model']['example_id']

        reward_tensor = self.compute_reward_tensor(response_str, response_ids, sqlite_path, example_id)
        return i, reward_tensor

    def __call__(self, data: DataProto):
        """We will expand this function gradually based on the available datasets"""
        reward_tensor = torch.zeros_like(data.batch['responses'], dtype=torch.float32)

        # Process items in parallel using ThreadPoolExecutor
        with ThreadPoolExecutor(max_workers=1) as executor:
            args = [(i, data[i]) for i in range(len(data))]
            results = list(executor.map(self.process_item, args))

        # Fill reward tensor with results
        for i, reward_tensor_item in results:
            reward_tensor[i] = reward_tensor_item

        return reward_tensor

