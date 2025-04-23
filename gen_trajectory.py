from openai import OpenAI
import os
import re
import argparse
import json
import concurrent
import threading

class DSChat:
    def __init__(self, model="deepseek-reasoner") -> None:
        self.client = OpenAI(
            api_key=os.environ.get("DS_API_KEY"),
            base_url="https://api.deepseek.com"
        )

        self.messages = []
        self.model = model

    def get_model_response_txt(self, prompt):
        self.messages.append({"role": "user", "content": prompt})
        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=self.messages
            )
        except Exception as e:
            print(e)
            return e
        choices = response.choices
        if choices:
            # print(choices)
            reasoning_content = choices[0].message.reasoning_content
            main_content = choices[0].message.content

        self.messages.append({"role": "assistant", "content": main_content})
        return "<think>\n"+reasoning_content+"\n</think>\n"+main_content

original_prompt = """
You are a data scientist proficient in Text-to-SQL tasks. 
Given a task, you should reason step by step to generate at least 3 SQL queries from simple to complex to undersatnd DB schema, execute them step by step, and provide a final answer after reviewing the results. 
You should use the <exec_sql></exec_sql> tags to execute SQLs and you will get result feedback in <exec_result></exec_result> tags. You should continue to reason based on results.
If there is any syntax error or empty result, you should fix it. For most questions, there's no gold answer with empty results. 
Write final answer in <|im_start|>SQL\n<|im_end|> tags. The SQL dialect must be SQLite. 
Basic usage: SELECT \"column_name\" FROM \"table_name\" WHERE ... (Replace \"table_name\" with the actual table name. Enclose table and column names with double quotations.)
"""

gen_prompt = """
Now given a task, you should simulate execution feedback reasoning process in reasoning_content and put final answer in main_content. 
e.g.

Okay, so the schema makes sense. Now, to calculate total sales per category in 2023, need to join orders, products, and categories. Sales would be sum(quantity * price) grouped by category. Also, filter orders where order_date is in 2023.

First, maybe check if there are orders in 2023.

<exec_sql>
SELECT COUNT(*) FROM "orders" WHERE strftime('%Y', "order_date") = '2023';
</exec_sql>
<exec_result>
COUNT(*)
150
</exec_result>

Good, there are records. Now, let's join the tables. Start with a simple join between orders and products to get product details and calculate sales per product.

<exec_sql>
SELECT p."category_id", SUM(o."quantity" * p."price") AS total_sales
FROM "orders" o
JOIN "products" p ON o."product_id" = p."product_id"
WHERE strftime('%Y', o."order_date") = '2023'
GROUP BY p."category_id";
</exec_sql>
<exec_result>
category_id | total_sales
1           | 5000.00
2           | 3000.00
3           | 4500.00
</exec_result>

But we need category names. So join with categories table.

Next query:

<exec_sql>
SELECT c."category_name", SUM(o."quantity" * p."price") AS total_sales
FROM "orders" o
JOIN "products" p ON o."product_id" = p."product_id"
JOIN "categories" c ON p."category_id" = c."category_id"
WHERE strftime('%Y', o."order_date") = '2023'
GROUP BY c."category_name"
ORDER BY total_sales DESC;
</exec_sql>
<exec_result>
category_name | total_sales
Electronics   | 5000.00
Clothing      | 4500.00
Books         | 3000.00
</exec_result>

That looks good. Let me check if there's any possible error, like nulls or incorrect joins. Also, ensure that the date format is correct. Using strftime with '%Y' should extract the year properly. 

If the order_date is stored as a text in 'YYYY-MM-DD' format, this should work. Assuming the dates are stored correctly.

Final answer would be the last query, which gives the total sales per category in 2023.

<|im_start|>SQL
SELECT 
  c."category_name", 
  SUM(o."quantity" * p."price") AS total_sales
FROM 
  "orders" o
  JOIN "products" p ON o."product_id" = p."product_id"
  JOIN "categories" c ON p."category_id" = c."category_id"
WHERE 
  strftime('%Y', o."order_date") = '2023'
GROUP BY 
  c."category_name"
ORDER BY 
  total_sales DESC;
<|im_end|>
"""

def is_valid_exec_sequence(text):
    def check_once(start, end, text):
        start_count = text.count(start)
        end_count = text.count(end)
        if start_count == 1 and end_count == 1:
            return True
        return False

    if not check_once("<|im_start|>SQL", "<|im_end|>", text):
        return 0
    
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

    return 1

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--bird_train_pth", type=str, required=True)
    args = parser.parse_args()

    with open(args.bird_train_pth) as f:
        data = json.load(f)

    

    # gen_data = []
    # for ex in data:
    #     if len(gen_data) > 10:
    #         break
    #     gen_dict = {"messages": [{"role": "user", "content": ex["input"]}, {"role": "assistant", "content": ""}], "format": "chatml"}
        
    #     db_info = "DB Info: " + ex["input"] + "\n" + "Task: "+ex["question"]
    #     response = chat.get_model_response_txt(original_prompt+gen_prompt+db_info)
    #     if is_valid_exec_sequence(response):
    #         print(response)
    #         gen_dict["messages"][-1]["content"] = response
    #         gen_data.append(gen_dict)
    gen_data = []
    lock = threading.Lock()

    def process_example(ex):
        chat = DSChat()
        gen_dict = {
            "messages": [
                {"role": "user", "content": ex["input"]},
                {"role": "assistant", "content": ""}
            ],
            "format": "chatml"
        }

        db_info = "DB Info: " + ex["input"] + "\n" + "Task: " + ex["question"]
        response = chat.get_model_response_txt(original_prompt + gen_prompt + db_info)

        if is_valid_exec_sequence(response):
            # print(response)
            gen_dict["messages"][-1]["content"] = response
            with lock:
                if len(gen_data) < 300:
                    gen_data.append(gen_dict)

                print(f"len(gen_data): {len(gen_data)}")

    with concurrent.futures.ThreadPoolExecutor(max_workers=64) as executor:
        futures = [executor.submit(process_example, ex) for ex in data]

    with open("raw/ds_bird.jsonl", "a") as f:
        for row in gen_data:
            f.write(json.dumps(row)+"\n")