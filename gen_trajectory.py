from openai import OpenAI
import os
import re
import argparse
import json
import concurrent
import threading
import random

import re

def extract_tag_content(text: str, tag: str) -> str:
    pattern = fr"<{tag}>\s*(.*?)\s*</{tag}>"
    match = re.search(pattern, text, re.DOTALL)
    return match.group(1).strip() if match else ""

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
        return "<think>\n" + reasoning_content + "\n</think>\n" + "\n<answer>\n" + extract_tag_content(main_content, "answer") + "\n</answer>"

original_prompt = """
You are a data scientist proficient in Text-to-SQL tasks.

Given a task, you should reason step by step using execution feedback to arrive at the final answer.

Step 1: Identify all relevant schemas (which may include more than just the gold schema) and enclose them within <schema_linking></schema_linking> tags. The schema should be represented in JSON format:
<schema_linking>
{Table name: [column name1, column name2]}.
</schema_linking>

Step 2: Write SQL queries to examine the values of each column in the JSON to assess their validity. Use <exec_sql></exec_sql> tags to execute SQL queries. The results will be returned in <exec_result></exec_result> tags. You should reason based on results.

Step 3: After reviewing all relevant schemas and values from the database, decide on the final schema to use by removing useless parts in the previous JSON. 
Then, generate the final SQL query inside <exec_sql></exec_sql> tags and verify its correctness based on the feedback provided in <exec_result></exec_result> tags.

Step 4: Write the final SQL in <answer></answer> tags.

Note: 

Do not generate <exec_result></exec_result> tags yourself. If any syntax error or empty result occurs, revise your query accordingly before proceeding. All 'SELECT' should be in <exec_sql></exec_sql> block. <schema_linking> and </schema_linking> should appear twice: in Step 1 and Step 3.

The SQL dialect must be SQLite. Use the format SELECT "column_name" FROM "table_name" WHERE ..., replacing "table_name" and "column_name" with actual names. Always enclose table and column names in double quotation marks.
"""

gen_prompt = """
Now, given a question, db info, you should simulate the execution-feedback-based reasoning process (generate execution results through your hallucination).
You can generate some syntax error or empty results.
The <exec_result> tag must appear immediately after the corresponding </exec_sql> tag, following this format: <exec_sql>\n...\n</exec_sql>\n<exec_result>\n...\n</exec_result>.

e.g.:
Okay, let's tackle this question: "What is the medium through which most complaints are registered in Florida? Medium refers to 'Submitted via'; most complaints refers to MAX(Complaint ID); Florida refers to state = 'Florida'."

First, I need to understand the tables involved. The user mentioned the answer involves joining callcenterlogs, client, and events tables. Let me check the schemas provided.

The tables relevant here are:
- callcenterlogs: Contains Complaint ID and links to client via rand client.
- client: Has state information (like 'FL' for Florida) and links to district.
- events: Contains Submitted via and links to Complaint ID.

Wait, the user's answer uses T2.state = 'FL', but the client table's state column has values like 'NM', 'NY', etc. So 'FL' is the correct abbreviation for Florida. The state table maps StateCode (e.g., 'FL') to State ('Florida'). But since the client table's state column already uses the abbreviation, maybe we don't need the state table. Let me verify.

The client table's state column sample rows are 'NM', 'NY', which are state abbreviations. So filtering client.state = 'FL' would correctly identify clients from Florida. Therefore, joining client to callcenterlogs via rand client = client_id, then joining events on Complaint ID should get the Submitted via field.

But wait, the answer provided by the user groups by T1.Complaint ID and orders by the count of Complaint IDs. But the question asks for the medium (Submitted via) with the most complaints. Grouping by Complaint ID doesn't make sense here because each Complaint ID is unique. Instead, we should group by Submitted via and count the number of complaints per medium.

Wait, the user's answer might have an error. Let me think. The user's answer groups by T1.Complaint ID, which is a primary key, so each group would have one entry. Then ordering by the count of Complaint IDs (which would be 1 each) and taking the first one. That's incorrect. The correct approach is to group by Submitted via, count the Complaint IDs, and select the one with the highest count.

So the initial answer might be wrong. But in this simulation, I need to follow the user's process, including possible errors. Let's proceed.

Step 1: Identify relevant schemas. The tables involved are callcenterlogs, client, events. The columns needed are client.state (to filter Florida), events.Submitted via, and the join keys.

<schema_linking>
{
  "callcenterlogs": ["Complaint ID", "rand client"],
  "client": ["client_id", "state"],
  "events": ["Complaint ID", "Submitted via", "Client_ID"]
}
</schema_linking>

Step 2: Validate values. Check if there are clients in Florida (state = 'FL').

<exec_sql>
SELECT "client_id" FROM "client" WHERE "state" = 'FL' LIMIT 5;
</exec_sql>
<exec_result>
[{"client_id": "C00004587"}, {"client_id": "C00003328"}, {"client_id": "C00001685"}]
</exec_result>

There are clients from FL. Next, check the Submitted via values in events.

<exec_sql>
SELECT DISTINCT "Submitted via" FROM "events";
</exec_sql>
<exec_result>
[{"Submitted via": "Email"}, {"Submitted via": "Web"}, {"Submitted via": "Phone"}]
</exec_result>

Possible mediums are Email, Web, Phone. Now, check the join between callcenterlogs and events on Complaint ID. Since Complaint ID is a primary key in both, but in callcenterlogs, the sample rows have "None", which might be a problem. Wait, the sample rows for callcenterlogs.Complaint ID are ("None", "None", "None"), but events.Complaint ID has actual values like "CR0000072". This indicates that the join might not work if callcenterlogs.Complaint ID is "None". But according to the DB info, callcenterlogs.Complaint ID is a primary key, but the sample rows are "None". That's conflicting. Maybe the sample data is incorrect, or there's a mistake in the schema.

Wait, the user's answer uses T1.Complaint ID = T3.Complaint ID. If callcenterlogs.Complaint ID is "None", then joining with events.Complaint ID (which has values like "CR0000072") would not match. This suggests that the initial answer is incorrect because the join would result in no rows. Therefore, there's an error in the schema or the sample data. But assuming that the actual data has valid Complaint IDs in callcenterlogs, perhaps the sample rows are misleading.

Alternatively, maybe the events table's Complaint ID is linked correctly. Let's check if there are any matching Complaint IDs between callcenterlogs and events.

<exec_sql>
SELECT COUNT(*) FROM callcenterlogs AS T1 INNER JOIN events AS T3 ON T1."Complaint ID" = T3."Complaint ID";
</exec_sql>
<exec_result>
[{"COUNT(*)": 150}]
</exec_result>

Assuming this returns some count, indicating that there are matching rows. Then proceed.

Now, to find the medium (Submitted via) with the most complaints in Florida. The correct approach is to filter clients from Florida, join with callcenterlogs and events, group by Submitted via, count the complaints, and pick the highest count.

But the user's answer groups by T1.Complaint ID, which is incorrect. However, in the simulation, we need to follow the process, including possible errors and corrections.

Step 3: After reviewing, the final schema would still involve those three tables. 

The error in grouping would lead to an empty result or incorrect count. So the correct SQL should group by Submitted via.

But according to the problem statement, the user's answer is given as:

SELECT T3.`Submitted via` FROM callcenterlogs AS T1 INNER JOIN client AS T2 ON T1.`rand client` = T2.client_id INNER JOIN events AS T3 ON T1.`Complaint ID` = T3.`Complaint ID` WHERE T2.state = 'FL' GROUP BY T1.`Complaint ID` ORDER BY COUNT(T1.`Complaint ID`) DESC LIMIT 1

But grouping by Complaint ID (which is unique) would result in each group having a count of 1, so ordering by count DESC and LIMIT 1 would just pick a random row. This is incorrect. The correct query should group by Submitted via and count the number of Complaint IDs.

However, the user's answer is provided, so in the simulation, we need to generate the execution results as if the query ran, even if it's logically incorrect.

Executing the user's SQL:

<exec_sql>
SELECT T3."Submitted via" FROM callcenterlogs AS T1 INNER JOIN client AS T2 ON T1."rand client" = T2.client_id INNER JOIN events AS T3 ON T1."Complaint ID" = T3."Complaint ID" WHERE T2.state = 'FL' GROUP BY T1."Complaint ID" ORDER BY COUNT(T1."Complaint ID") DESC LIMIT 1;
</exec_sql>
<exec_result>
[{"Submitted via": "Email"}]
</exec_result>

Even though the grouping is incorrect, the execution result might return "Email" as the most common medium, assuming that each group has count 1, but the first row's Submitted via is Email. However, this is a flawed approach. The correct result should come from grouping by Submitted via and counting.

But since the user's answer is given, the simulation should reflect that the query returns "Email" as the result, even if the method is flawed. Therefore, the final answer is as provided.

<answer>
SELECT T3."Submitted via" 
FROM callcenterlogs AS T1 
INNER JOIN client AS T2 ON T1."rand client" = T2.client_id 
INNER JOIN events AS T3 ON T1."Complaint ID" = T3."Complaint ID" 
WHERE T2.state = 'FL' 
GROUP BY T1."Complaint ID" 
ORDER BY COUNT(T1."Complaint ID") DESC 
LIMIT 1;
</answer>
"""

def is_valid_exec_sequence(text):
    def check_times(start, end, text, times=1):
        start_count = text.count(start)
        end_count = text.count(end)
        if start_count == times and end_count == times:
            return True
        return False

    if not check_times("<schema_linking>", "</schema_linking>", text):
        return "<schema_linking> and </schema_linking> should appear once. "

    if not check_times("<answer>", "</answer>", text):
        return "<answer> and </answer> should appear once. "

    # if len(re.findall(r'<exec_sql>\nSELECT', text)) != len(re.findall(r'\nSELECT', text)) - 1:
    #     return "All 'SELECT' should be in <exec_sql></exec_sql> block. "
    
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
        return "Number of <exec_sql></exec_sql> tags should match <exec_result></exec_result> tags. "

    if not tags:
        return "You should use <exec_sql></exec_sql> tags and <exec_result></exec_result> tags. "

    for i, tag in enumerate(tags):
        if i % 2 == 0 and not tag.startswith('<exec_sql>'):
            return "<exec_result> should be after </exec_sql> like <exec_sql>\n...\n</exec_sql>\n<exec_result>\n...\n</exec_result>. "
        if i % 2 == 1 and not tag.startswith('<exec_result>'):
            return "<exec_result> should be after </exec_sql> like <exec_sql>\n...\n</exec_sql>\n<exec_result>\n...\n</exec_result>. "

    return "Successfully Generated. "

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--bird_train_pth", type=str, required=True)
    args = parser.parse_args()

    with open(args.bird_train_pth) as f:
        data = json.load(f)
    # random.seed(42)
    # random.shuffle(data)
    gen_data = []
    lock = threading.Lock()

    def process_example(ex):
        chat = DSChat()


        db_info = "DB Info: " + ex["input"] + "\n" + "Question: " + ex["question"] + "\n"
        prompt = original_prompt + db_info + gen_prompt
        
        max_try = 3

        while max_try:
            gen_dict = {
                "messages": [
                    {"role": "user", "content": original_prompt + db_info},
                    {"role": "assistant", "content": ""}
                ],
                "format": "chatml"
            }
            response = chat.get_model_response_txt(prompt)
            # print("Question: "+ex["question"])
            # print(response)
            # print(ex["example_id"], is_valid_exec_sequence(response))
            # return
            if is_valid_exec_sequence(response) == "Successfully Generated. ":
                # print(response)
                gen_dict["messages"][-1]["content"] = response
                with lock:
                    gen_data.append(gen_dict)

                    print(f"len(gen_data): {len(gen_data)}, ex_id: ", ex["example_id"])
                    with open("raw/ds_bird_trajectory.jsonl", "a", encoding="utf-8") as f:
                        f.write(json.dumps(gen_dict, ensure_ascii=False) + "\n")
                break
            
            prompt = is_valid_exec_sequence(response) + "Please generate again. "
            max_try -= 1

    data_long = [ex for ex in data if 35 < len(ex["answer"].split(" ")) <= 40]
    print("Len", len(data_long))
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as executor:
        futures = [executor.submit(process_example, ex) for ex in data_long]