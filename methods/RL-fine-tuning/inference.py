from chat import modelChat
import argparse
import json
from transformers import AutoModelForCausalLM, AutoTokenizer
from utils import get_api_name, execute_sql_api, extract_all_blocks, hard_cut, extract_all_boxes
from prompt import Prompts
import os

def load_jsonl(file_path):
    data_list = []
    with open(file_path, 'r', encoding='utf-8') as f:
        for line in f:
            sample = json.loads(line.strip())
            data_list.append(sample)
    return data_list

def main(args):
    model = AutoModelForCausalLM.from_pretrained(
        args.model_path,
        torch_dtype="auto",
        device_map="auto"
    )
    tokenizer = AutoTokenizer.from_pretrained(args.model_path)
    chat_session = modelChat(model, tokenizer, model.device)
    inputs = load_jsonl(args.test_data_path)
    sql_prompt = Prompts()
    sys_prompt = "Please reason step by step. This is a Text-to-SQL task where you are given database information and a question, and your goal is to generate a SQL query as the answer. You can only generate SQL within specific formats: use ```sql``` for intermediate queries and \\boxed{```sql```} for the final answer. After executing an intermediate query, you will receive feedback in the form of error messages or sampled results if the output is too long. You should generate mutiple intermediate SQL queries per chat round, according to the step thoughts. You should write intermediate SQLs for each step before generating the final SQL. Please start with simple, non-nested queries.\n"
    for example in inputs:
        example_id = example["example_id"]
        out_path_csv = os.path.join(args.output_dir, example_id + ".csv")
        out_path_sql = os.path.join(args.output_dir, example_id + ".sql")
        api = get_api_name(example_id)
        iter_count = 0
        final_ans = None
        sqlite_path = None
        if api == "sqlite":
            sqlite_path = example["sqlite_path"]

        prompt_input = sys_prompt
        prompt_input += "Table info:\n" + example["input"]
        prompt_input += f"The SQL dialect is {api}. Basic usage: " + sql_prompt.get_prompt_dialect_basic(api)
        while iter_count < args.max_iter:
            response = chat_session.get_model_response_txt(prompt_input)
            intermediate_sqls = extract_all_blocks(response, "sql")
            final_sqls = extract_all_boxes(response)
            if intermediate_sqls:
                count_sql = 0
                prompt_input = ""
                for intermediate_sql in intermediate_sqls:
                    count_sql += 1
                    results = execute_sql_api(intermediate_sql, api=api, sqlite_path=sqlite_path)
                    if isinstance(results, str):
                        intermediate_csv = hard_cut(results, 1000)
                        prompt_input += f"Intermediate SQL {count_sql}: {intermediate_sql}\nSQL {count_sql} Executed Results: {intermediate_csv}\n"
                    else:
                        prompt_input += f"Intermediate SQL {count_sql}: {intermediate_sql}\nSQL {count_sql} Error Information: {results}\n"
                prompt_input += "Please continue to answer based on these results.\n"
            elif final_sqls:
                if len(final_sqls) == 1:
                    results = execute_sql_api(final_sqls[0], out_path_csv, api, sqlite_path=sqlite_path)
                    if results == 0:
                        final_ans = final_sqls[0]
                        with open(out_path_sql, "w") as f:
                            f.write(final_ans)
                        break
                    else:
                        prompt_input = f"Error information: {results}\n" 
                else:
                    prompt_input = "You should generate only one final SQL query.\n"
            else:
                prompt_input = "You can only generate SQL within specific formats: use ```sql``` for intermediate queries and \\boxed{} for the final answer.\n"               
            iter_count += 1
        if not final_ans:
            if os.path.exists(out_path_csv):
                os.remove(out_path_csv)
            if os.path.exists(out_path_sql):
                os.remove(out_path_sql)                

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--model_path', type=str, default=None)
    parser.add_argument('--test_data_path', type=str, default="data/training_data.jsonl")
    parser.add_argument('--output_dir', type=str, default="output")
    parser.add_argument('--overwrite_results', action="store_true")
    parser.add_argument('--max_iter', type=int, default=20)
    parser.add_argument('--temperature', type=float, default=1)
    args = parser.parse_args()
    main(args)