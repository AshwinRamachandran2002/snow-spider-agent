from deepscaler.rewards.evaluate import evaluate_spider2sql
import os
from deepscaler.rewards.math_utils.utils import execute_sql_with_timeout, get_api_name
ground_truths = "deepscaler/rewards/gold/gold_answer"
model_answer = """
SELECT name FROM Dish WHERE id IN (
    SELECT dish_id FROM MenuItem WHERE menu_page_id IN (
        SELECT id FROM MenuPage WHERE image_id IN (
            SELECT image_id FROM MenuItem WHERE price > 0 AND high_price > 0 ORDER BY price DESC LIMIT 1
        )
    )
)
"""
sqlite_path = "data/BIRD/train/train_databases/menu/menu.sqlite"
example_id = "local_BIRD_train_207"
csv_save_path = os.path.join("exec", example_id+"_140314056566336.csv")

if execute_sql_with_timeout(model_answer, csv_save_path, api=get_api_name(example_id), sqlite_path=sqlite_path) == 0:
    is_correct = evaluate_spider2sql(ground_truths, csv_save_path, example_id)
    if is_correct:
        print(f"Correct: {example_id}")