from deepscaler.rewards.evaluate import evaluate_spider2sql
import os
from deepscaler.rewards.math_utils.utils import execute_sql_with_timeout, get_api_name
ground_truths = "deepscaler/rewards/gold/gold_answer"
model_answer = """
SELECT DISTINCT T1.item_nbr
FROM sales_in_weather AS T1
JOIN weather AS T2 ON T1.date = T2.date AND T1.store_nbr = T2.station_nbr
WHERE T2.tmax = (SELECT MAX(tmax) FROM weather WHERE T2.date = (SELECT max(date) FROM sales_in_weather WHERE store_nbr = 3 AND strftime('%Y', date) = '2012'))
ORDER BY T1.units DESC
LIMIT 1
"""
sqlite_path = "data/BIRD/train/train_databases/sales_in_weather/sales_in_weather.sqlite"
example_id = "local_BIRD_train_238"
csv_save_path = os.path.join("exec", example_id+"_139605143705152.csv")

if execute_sql_with_timeout(model_answer, csv_save_path, api=get_api_name(example_id), sqlite_path=sqlite_path) == 0:
    is_correct = evaluate_spider2sql(ground_truths, csv_save_path, example_id)
    if is_correct:
        print(f"Correct: {example_id}")