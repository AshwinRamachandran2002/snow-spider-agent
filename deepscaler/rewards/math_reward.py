"""
This module contains the RewardMathFn class, which evaluates mathematical answers
and assigns rewards based on their correctness. It utilizes a language model to 
validate answers when necessary.
"""
from typing import List, Union

from deepscaler.rewards import RewardConfig, RewardFn, RewardInput, RewardOutput, RewardType
from deepscaler.rewards.math_utils.utils import execute_sql_with_timeout, get_api_name, extract_all_blocks
from deepscaler.rewards.evaluate import evaluate_spider2sql
import os
import threading


class RewardMathFn(RewardFn):
    """
    Reward function for evaluating mathematical answers.

    This class implements the __call__ method to process the input and determine
    the reward based on the correctness of the provided answer compared to the ground truth.
    """

    def __call__(self, input: RewardInput) -> RewardOutput:
        assert input.problem_type == RewardType.MATH, \
            "Invalid problem type: expected 'MATH', but got '{}'".format(input.problem_type)

        response = input.model_response
        sqlite_path = input.sqlite_path.get("sqlite_path", None)
        example_id = input.example_id.get("ex_id", None)

        print(f"Start Reward {example_id}")
        print("math reward response", response)
        print("math reward sqlite_path", sqlite_path)
        print("math reward example_id", example_id)

        exec_folder = "exec_3B"
        csv_save_path = os.path.join(exec_folder, example_id+f"_{threading.get_ident()}.csv")
        if not os.path.exists(exec_folder):
            os.mkdir(exec_folder)

        with open(f"{exec_folder}/{example_id}_{threading.get_ident()}.log", "a") as f:
            f.write(response)

        # Extract solution.
        if "<|im_start|>SQL" in response:
            response = response.split("<|im_start|>SQL")[1].split("<|im_end|>")[0]
        else:
            return RewardOutput(reward=self.config.format_error_reward, is_correct=False)

        ground_truths = "deepscaler/rewards/gold/gold_answer"
        
        print("math reward model answer", response)
        print("math reward model csv path", csv_save_path)
        print("math reward model api", get_api_name(example_id))

        if execute_sql_with_timeout(response, csv_save_path, api=get_api_name(example_id), sqlite_path=sqlite_path) == 0:
            is_correct = evaluate_spider2sql(ground_truths, csv_save_path, example_id)
            if is_correct:
                print(f"Correct: {example_id}_{threading.get_ident()}")
                return RewardOutput(reward=self.config.correct_reward, is_correct=True)
        print(f"End Reward {example_id}")
        return RewardOutput(reward=self.config.incorrect_reward, is_correct=False)

def deepscaler_reward_fn(solution_str: str, sqlite_path: Union[str, List[str]], example_id: Union[str, List[str]], enable_llm = False):
    reward_config = RewardConfig()
    reward_config.use_math_orm = enable_llm
    reward_fn = RewardMathFn(reward_config)
    reward_response = reward_fn(RewardInput(problem=solution_str, problem_type=RewardType.MATH, model_response=solution_str, sqlite_path={"sqlite_path": sqlite_path}, example_id={"ex_id": example_id}))
    return reward_response.is_correct
