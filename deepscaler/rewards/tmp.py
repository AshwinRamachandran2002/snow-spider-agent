from deepscaler.rewards.evaluate import evaluate_spider2sql
import os
from deepscaler.rewards.math_utils.utils import execute_sql_with_timeout, get_api_name
ground_truths = "deepscaler/rewards/gold/gold_answer"
model_answer = """
SELECT CAST(COUNT(s.units) AS REAL) * 100 / SUM(s.units) FROM sales_in_weather s JOIN (SELECT date FROM weather WHERE station_nbr IN (SELECT station_nbr FROM relation WHERE store_nbr = 3) AND year(date) = 2012 ORDER BY tmax DESC LIMIT 1) f ON s.date = f.date WHERE s.item_nbr = 5

"""
sqlite_path = "data/BIRD/train/train_databases/sales_in_weather/sales_in_weather.sqlite"
example_id = "local_BIRD_train_238"
csv_save_path = os.path.join("exec", example_id+"_139605143705152.csv")

if execute_sql_with_timeout(model_answer, csv_save_path, api=get_api_name(example_id), sqlite_path=sqlite_path) == 0:
    is_correct = evaluate_spider2sql(ground_truths, csv_save_path, example_id)
    if is_correct:
        print(f"Correct: {example_id}")