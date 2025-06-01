"""
This module contains the RewardMathFn class, which evaluates mathematical answers
and assigns rewards based on their correctness. It utilizes a language model to 
validate answers when necessary.
"""
from typing import List, Dict, Union

from rllm.globals import THOUGHT_DELIMITER_START, THOUGHT_DELIMITER_END, OAI_RM_MODEL
from rllm.rewards import RewardConfig, RewardFn, RewardInput, RewardOutput, RewardType
from rllm.rewards.math_utils.utils import extract_answer, grade_answer_sympy, grade_answer_mathd

from rllm.system_prompts import ORM_PROMPT
from rllm.utils import calculate_md5, call_oai_rm_llm
import os 
import re
ORM_USER_TEMPLATE = """
Problem: {problem}
Answer 1: {answer_1}
Answer 2: {answer_2}
"""

class RewardSQLFn(RewardFn):
    """
    Reward function for evaluating mathematical answers.

    This class implements the __call__ method to process the input and determine
    the reward based on the correctness of the provided answer compared to the ground truth.
    """

    def is_valid_exec_sequence(self, text):
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

        if text.count("<schema_linking>") != text.count("</schema_linking>") or text.count("<schema_linking>") < 1:
            return False

        if not check_once("<answer>", "</answer>", text):
            return False

        text = text[:text.find("</think>")]
        
        if len(re.findall(r'<exec_sql>\nSELECT', text)) != len(re.findall(r'\nSELECT', text)):
            return False

        tag_pattern = re.compile(r'<exec_sql>.*?</exec_sql>|<exec_result>.*?</exec_result>', re.DOTALL)
        tags = tag_pattern.findall(text)

        all_tag_counts = {
            'exec_sql_open': len(re.findall(r'<exec_sql>', text)),
            'exec_sql_close': len(re.findall(r'</exec_sql>', text)),
            'exec_result_open': len(re.findall(r'<exec_result>', text)),
            'exec_result_close': len(re.findall(r'</exec_result>', text)),
            'SELECT': len(re.findall(r'<exec_sql>\nSELECT', text)),
            ';\n': len(re.findall(r';\n</exec_sql>', text)),
        }

        if not (all_tag_counts['exec_sql_open'] == all_tag_counts['exec_sql_close'] ==
                all_tag_counts['exec_result_open'] == all_tag_counts['exec_result_close'] == 
                all_tag_counts["SELECT"] == all_tag_counts[";\n"]):
            return False

        if not tags:
            return False

        if len(tags) % 2 != 0 or len(tags) < 2:
            return False

        for i, tag in enumerate(tags):
            if i % 2 == 0 and not tag.startswith('<exec_sql>'):
                return False
            if i % 2 == 1 and not tag.startswith('<exec_result>'):
                return False
            # if i % 2 == 1 and i > 2 and tag.startswith('<exec_result>'):
            #     if "No data found for the specified query." in tags[i-2] or "##ERROR##" in tags[i-2]:
            #         if "No data found for the specified query." in tags[i] or "##ERROR##" in tags[i]:
            #             return False

        return True

    def __call__(self, input: RewardInput) -> RewardOutput:
        assert input.problem_type == RewardType.CODE, \
            "Invalid problem type: expected 'CODE', but got '{}'".format(input.problem_type)
        # print(f"input.metadata: {input.metadata}")
        example_id = input.metadata["example_id"]
        model_response = input.model_response
        
        response_str = model_response[model_response.rfind("<think>"):]
        if response_str.count("</answer>") != 1:
            return RewardOutput(reward=self.config.format_error_reward, is_correct=False)
        filename = calculate_md5(response_str[response_str.find("<exec_sql>"):response_str.find("</answer>")])
        # response_str = response_str[response_str.find("<answer>")+len("<answer>"):response_str.find("</answer>")]
        log_folder = os.getenv("EXEC_FOLDER")
        log_path = os.path.join(log_folder, example_id + '_' + filename + ".log")
        csv_path = os.path.join(log_folder, example_id + '_' + filename + ".csv")
        # print(f"log_path: {log_path}")
        
        if not os.path.exists(log_path):
            # with open(os.path.join("log", example_id + '_' + filename + ".log"), "w") as f:
            #     f.write(input.model_response) 
            return RewardOutput(reward=self.config.format_error_reward, is_correct=False)
        if not os.path.exists(csv_path):
            return RewardOutput(reward=self.config.format_error_reward, is_correct=False)

        with open(log_path.replace(".log", ".txt")) as f:
            is_correct = int(f.read())
            if is_correct: 
                print(f"Correct: {example_id}")
                if self.is_valid_exec_sequence(response_str):
                    return RewardOutput(reward=self.config.correct_reward, is_correct=True)
                # return RewardOutput(reward=self.config.half_correct_reward, is_correct=True)
        # Format
        if self.is_valid_exec_sequence(response_str):
            return RewardOutput(reward=self.config.format_reward, is_correct=False)
        return RewardOutput(reward=self.config.format_error_reward, is_correct=False)



def rllm_reward_fn_sql(data_source: str, llm_solution: str, ground_truth: Dict, **kwargs):
    """Evaluate code solutions against ground truth ansters
    
    This function creates a reward function to evaluate code solutions by pass the test_case from groun_truth. It can optionally use a language model
    for more sophisticated answer validation.

    Args:
        data_source: The source/dataset the problem comes from
        llm_solution: The solution string provided by the language model to evaluate
        ground_truth: some tests for this llm_solution
        enable_llm: Whether to enable language model validation for complex cases (default: False)

    Returns:
        bool: True if the solution passes all the test_case, False otherwise

    Example:
            model_response = '''
import sys
from itertools import permutations
def main():
    n,m=map(int, input().split()) 
    a=sum(list(map(int, input().split()))) 
    if a+(n-1)*10<=m: 
        print(5) 
    else: 
        print(5)
if __name__ == "__main__":
    main()
'''
    
    print(f"test the code_forces")
    # tests = [ { "input": "3 30\n2 2 1", "output": "5" }, { "input": "3 10\n3 2 1", "output": "5" } ] 
    metadata = {
         "tests": tests,
    }
    True
    """
    reward_config = RewardConfig()
    reward_fn = RewardSQLFn(reward_config)
    reward_response = reward_fn(
        RewardInput(
            problem=None,
            problem_type=RewardType.CODE,
            data_source=data_source,
            model_response=llm_solution,
            metadata=ground_truth
        ))
    return reward_response.reward


if __name__ == "__main__":
    reward = RewardSQLFn(RewardConfig)
    test_input = RewardInput(
        data_source="",
        problem=(
            "Let $P(x)=x^{4}+2 x^{3}-13 x^{2}-14 x+24$ be a polynomial with roots "
            "$r_{1}, r_{2}, r_{3}, r_{4}$. Let $Q$ be the quartic polynomial with roots "
            "$r_{1}^{2}, r_{2}^{2}, r_{3}^{2}, r_{4}^{2}$, such that the coefficient "
            "of the $x^{4}$ term of $Q$ is 1. Simplify the quotient $Q\\left(x^{2}\\right) / P(x)$, "
            "leaving your answer in terms of $x$. (You may assume that $x$ is not equal to "
            "any of $\\left.r_{1}, r_{2}, r_{3}, r_{4}\\right)$."
        ),
        problem_type=RewardType.MATH,
        model_response=(
            "<think>...</think>\nThe answer is \\boxed{24 + 14*x + (-13)*x^2 - 2*x^3 + x^4}."
        ),
        metadata={"answer": ["10", "$x^{4}-2 x^{3}-13 x^{2}+14 x+24$"], "has_toolcall": True}
    )
    output = reward(test_input)
    print(output)
