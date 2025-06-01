prompt = """
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

Do not generate <exec_result></exec_result> tags yourself. If any syntax error or empty result occurs, revise your query accordingly before proceeding. All 'SELECT' should be in <exec_sql></exec_sql> block.

You should reason in <think></think> tags and anwer in <answer></answer> tags.

The SQL dialect must be SQLite. Use the format SELECT "column_name" FROM "table_name" WHERE ..., replacing "table_name" and "column_name" with actual names. Always enclose table and column names in double quotation marks.

Here's an example:
{DB Info}
Question: Who is the director that made the most movies? Give the director's id. director that made the most movies refers to MAX(COUNT(movie_id))
Your answer:
<think>
Okay, let's tackle the question: "Who is the director that made the most movies? Give the director's id." The user mentioned that the director with the most movies refers to MAX(COUNT(movie_id)). 

First, I need to identify the relevant tables and columns. The question involves directors and the movies they directed. Looking at the provided schemas, the tables involved are:

- **movies**: Contains movie details, including movie_id and director_id (since each movie has a director).
- **directors**: The director's full name and ID are here. But the question asks for the director's ID, so maybe we don't need to join with directors unless the answer requires the name. However, the user's instruction says to give the director's id, so perhaps the answer is just the director_id from the movies table.

Wait, but the movies table's director_id is linked to the directors table's user_id. So to get the director's ID, we might need to join movies and directors. But the question doesn't mention the director's name, so maybe we can just use the director_id from the movies table. Let me check the sample data.

Looking at the movies table's director_id sample rows: 131, 73, 82. These correspond to directors in the directors table. For example, director_id 131 is Esteban Sapir. So each movie in the movies table is associated with a director_id, which is a primary key in the directors table. Therefore, the director's ID is stored in the movies table's director_id column. 

So the plan is to count the number of movies each director has directed by grouping on director_id and then selecting the director_id with the highest count. 

Step 1: Schema linking. The relevant tables are movies and directors. But since we only need the director's ID and the count, maybe we can just use the movies table. However, to ensure correctness, we should join movies and directors to get the director's ID for each movie.

<schema_linking>
{
  "movies": ["movie_id", "director_id"],
  "directors": ["user_id", "director_id", "director_name"]
}
</schema_linking>

Step 2: Check if the director_id in movies is valid. Let's write a SQL query to count the movies per director_id.

<exec_sql>
SELECT "director_id", COUNT(*) AS movie_count
FROM "movies"
GROUP BY "director_id"
ORDER BY movie_count DESC
LIMIT 5;
</exec_sql>
<exec_result>
director_id,movie_count
524073,746
18991,253
35368,188
34989,179
47738,166

</exec_result>

The result shows that director_id 524073 has the highest count of 746 movies. Therefore, the director with the most movies is the one with ID 524073. 

Step 3: Final schema remains the same since we only needed the movies table. The final SQL should select the director_id with the maximum count.

<exec_sql>
SELECT "director_id" 
FROM "movies" 
GROUP BY "director_id" 
ORDER BY COUNT(*) DESC 
LIMIT 1;
</exec_sql>
<exec_result>
director_id
524073

</exec_result>

This query returns the director_id 524073 as the director who made the most movies. 
</think>

<answer>
SELECT "director_id" 
FROM "movies" 
GROUP BY "director_id" 
ORDER BY COUNT(*) DESC 
LIMIT 1;
</answer>

Now it's time for you to answer by following the format of the example.
"""

import os
import json
from tqdm import tqdm
with open("/mbz/bruce/exec-fb/data_preprocess/data/train/bird.json") as f:
    bird_data = json.load(f)
log_dir = "/mbz/bruce/logs"
gen_data = []
id_rec = []

for step in os.listdir(log_dir):
    step_pth = os.path.join(log_dir, step)
    for example in tqdm(os.listdir(step_pth)):
        example_dir = os.path.join(step_pth, example)
        example_id = example[len("local_BIRD_train_"):len("local_BIRD_train_")+4]
        if example.endswith(".txt") and example_id not in id_rec:
            with open(example_dir) as f:
                data = f.read().strip()
            if data == "1":
                with open(example_dir.replace(".txt", ".log")) as f:
                    l = f.read()
                    
                for i in bird_data:
                    if i["example_id"] == f"local_BIRD_train_{example_id}":
                        db_info = i["input"]
                        question = i["question"]
                gen_dict = {
                    "messages": [
                        {"role": "user", "content": prompt + "DB Info: " + db_info + "\n" + "Question: " + question + "\n"},
                        {"role": "assistant", "content": "<think>\n"+l}
                    ],
                    "format": "chatml"
                }
                
                gen_data.append(gen_dict)
                id_rec.append(example_id)
            else:
                assert data == "0", example_dir
print(gen_data[0])
print("Length", len(gen_data))

with open("raw/bird_trajectory_log.jsonl", "w") as f:
    for i in gen_data:
        f.write(json.dumps(i) + "\n")
