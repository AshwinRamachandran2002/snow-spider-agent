import os
import torch
import threading
from verl import DataProto
from concurrent.futures import ThreadPoolExecutor
os.environ["TOKENIZERS_PARALLELISM"] = "true"

from deepscaler.rewards.math_utils.utils import execute_sql_with_timeout, get_api_name
from deepscaler.rewards.evaluate import evaluate_spider2sql

class RewardManager():
    """
    The reward manager.
    """

    def __init__(self, tokenizer, mode) -> None:
        self.tokenizer = tokenizer
        self.mode = mode

        self.exec_folder = f"exec_3B_{mode}"
        # TODO unique id for each run
        if not os.path.exists(self.exec_folder):
            os.mkdir(self.exec_folder)

        self.ground_truths = "deepscaler/rewards/gold/gold_answer"

    def compute_reward_tensor(self, response_ids, sqlite_path, example_id):
        print(f"Start Reward {example_id}")

        response_str = self.tokenizer.decode(response_ids)
        reward_tensor = torch.zeros_like(response_ids, dtype=torch.float32)
        csv_save_path = os.path.join(self.exec_folder, example_id+f"_{threading.get_ident()}.csv")    
  
        with open(f"{self.exec_folder}/{example_id}_{threading.get_ident()}.log", "a") as f:
            f.write(f"example_id: {example_id}\n")
            f.write(f"response: {response_str}\n")
            f.write(f"sqlite_path: {sqlite_path}\n")
            f.write(f"api: {get_api_name(example_id)}\n")
            f.write(f"csv_save_path: {csv_save_path}\n")

        # Negative rewards for incorrect intermediate SQLs.
        # TODO


        # Extract solution.
        if "<|im_start|>SQL" in response_str:
            final_sql = response_str.split("<|im_start|>SQL")[1].split("<|im_end|>")[0]
        else:
            return reward_tensor

        if execute_sql_with_timeout(final_sql, csv_save_path, api=get_api_name(example_id), sqlite_path=sqlite_path) == 0:
            is_correct = evaluate_spider2sql(self.ground_truths, csv_save_path, example_id)
            if is_correct:
                print(f"Correct: {example_id}_{threading.get_ident()}")
                reward_tensor[-1] = 1.0
                return reward_tensor
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
        valid_response_ids = response_ids[:end_index + 1]

        sqlite_path = data_item.non_tensor_batch['reward_model']['sqlite_path']
        example_id = data_item.non_tensor_batch['reward_model']['example_id']

        reward_tensor = self.compute_reward_tensor(valid_response_ids, sqlite_path, example_id)
        return i, reward_tensor

    def __call__(self, data: DataProto):
        """We will expand this function gradually based on the available datasets"""
        reward_tensor = torch.zeros_like(data.batch['responses'], dtype=torch.float32)

        # If there is rm score, we directly return rm score. Otherwise, we compute via rm_score_fn
        if 'rm_scores' in data.batch.keys():
            return data.batch['rm_scores']

        # Process items in parallel using ThreadPoolExecutor
        with ThreadPoolExecutor(max_workers=1) as executor:
            args = [(i, data[i]) for i in range(len(data))]
            results = list(executor.map(self.process_item, args))

        # Fill reward tensor with results
        for i, reward_tensor_item in results:
            reward_tensor[i] = reward_tensor_item

        return reward_tensor

