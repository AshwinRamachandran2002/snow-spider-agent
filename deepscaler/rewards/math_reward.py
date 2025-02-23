"""
This module contains the RewardMathFn class, which evaluates mathematical answers
and assigns rewards based on their correctness. It utilizes a language model to 
validate answers when necessary.
"""
from typing import List, Union

from deepscaler.globals import THOUGHT_DELIMITER_START, THOUGHT_DELIMITER_END, OAI_RM_MODEL
from deepscaler.rewards import RewardConfig, RewardFn, RewardInput, RewardOutput, RewardType
from deepscaler.rewards.math_utils.utils import extract_answer, grade_answer_sympy, grade_answer_mathd, execute_sql_with_timeout, get_api_name, extract_all_blocks
from deepscaler.system_prompts import ORM_PROMPT
from deepscaler.utils import call_gemini_llm, call_oai_rm_llm
from deepscaler.rewards.evaluate import evaluate_spider2sql
import os
import threading
import torch

ORM_USER_TEMPLATE = """
Problem: {problem}
Answer 1: {answer_1}
Answer 2: {answer_2}
"""

class RewardMathFn(RewardFn):
    """
    Reward function for evaluating mathematical answers.

    This class implements the __call__ method to process the input and determine
    the reward based on the correctness of the provided answer compared to the ground truth.
    """

    def __call__(self, input: RewardInput) -> RewardOutput:
        assert input.problem_type == RewardType.MATH, \
            "Invalid problem type: expected 'MATH', but got '{}'".format(input.problem_type)
        
        problem = input.problem
        response = input.model_response
        
        # Extract solution.
        if THOUGHT_DELIMITER_START in response and THOUGHT_DELIMITER_END in response:
            response = response.split(THOUGHT_DELIMITER_END)[1]
        else:
            return RewardOutput(reward=self.config.format_error_reward, is_correct=False)
        
        model_answer = extract_all_blocks(response, "sql")
        if model_answer is None or model_answer == []:
            return RewardOutput(reward=self.config.format_error_reward, is_correct=False)
        model_answer = model_answer[-1]
        # Process the ground truth(s)
        ground_truths = "deepscaler/rewards/gold/gold_answer"
        # print(f"input.sqlite_path: {input.sqlite_path}")
        # print(f"input.example_id: {input.example_id}")
        # print(f"model_answer: {model_answer}")


        sqlite_path = input.sqlite_path.get("sqlite_path", None)
        example_id = input.example_id.get("ex_id", None)
        csv_save_path = os.path.join("exec", example_id+f"_{threading.get_ident()}.csv")
        print(f"Start Reward {example_id}")
        if not os.path.exists("exec"):
            os.mkdir("exec")

        with open(f"exec/{example_id}_{threading.get_ident()}.log", "a") as f:
            f.write(response)

        if execute_sql_with_timeout(model_answer, csv_save_path, api=get_api_name(example_id), sqlite_path=sqlite_path) == 0:
            is_correct = evaluate_spider2sql(ground_truths, csv_save_path, example_id)
            if is_correct:
                print(f"Correct: {example_id}_{threading.get_ident()}")
                return RewardOutput(reward=self.config.correct_reward, is_correct=True)

        # If latex heuristics fail and ORM is enabled, use LLM as ORM to evaluate correctness
        # if self.config.use_math_orm:
        #     for ground_truth in processed_ground_truths:
        #         try:
        #             orm_response = call_gemini_llm(
        #                 system_prompt=ORM_PROMPT,
        #                 prompt=ORM_USER_TEMPLATE.format(problem=problem, answer_1=model_answer, answer_2=ground_truth),
        #                 temperature=0.0,
        #             )

        #             if "[[YES]]" in orm_response:
        #                 return RewardOutput(reward=self.config.correct_reward, is_correct=True)
        #         except Exception as e:
        #             print ("Error calling Gemini ORM, trying OAI RM")
        #             orm_response = call_oai_rm_llm(
        #                 system_prompt=ORM_PROMPT,
        #                 prompt=ORM_USER_TEMPLATE.format(problem=problem, answer_1=model_answer, answer_2=ground_truth),
        #                 temperature=0.0,
        #                 model_id=OAI_RM_MODEL,
        #             )
                    
        #             if "[[YES]]" in orm_response:
        #                 return RewardOutput(reward=self.config.correct_reward, is_correct=True)
        #             continue
        print(f"End Reward {example_id}")
        return RewardOutput(reward=self.config.incorrect_reward, is_correct=False)

def deepscaler_reward_fn(solution_str: str, sqlite_path: Union[str, List[str]], example_id: Union[str, List[str]], enable_llm = False):
    reward_config = RewardConfig()
    reward_config.use_math_orm = enable_llm
    reward_fn = RewardMathFn(reward_config)
    reward_response = reward_fn(RewardInput(problem=solution_str, problem_type=RewardType.MATH, model_response=solution_str, sqlite_path={"sqlite_path": sqlite_path}, example_id={"ex_id": example_id}))
    return reward_response.is_correct

if __name__ == "__main__":
    reward = RewardMathFn(RewardConfig)
    input = RewardInput(problem="Let $P(x)=x^{4}+2 x^{3}-13 x^{2}-14 x+24$ be a polynomial with roots $r_{1}, r_{2}, r_{3}, r_{4}$. Let $Q$ be the quartic polynomial with roots $r_{1}^{2}, r_{2}^{2}, r_{3}^{2}, r_{4}^{2}$, such that the coefficient of the $x^{4}$ term of $Q$ is 1. Simplify the quotient $Q\\left(x^{2}\\right) / P(x)$, leaving your answer in terms of $x$. (You may assume that $x$ is not equal to any of $\\left.r_{1}, r_{2}, r_{3}, r_{4}\\right)$.", problem_type=RewardType.MATH, model_response="<think> I am omniscient. </think> The answer is \\boxed{24 + 14*x + (-13)*x^2 - 2*x^3 + x^4}.", ground_truth={"answer": ["10", "$x^{4}-2 x^{3}-13 x^{2}+14 x+24$"]})
    output = reward(input)
    print(output)
