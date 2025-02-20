from deepscaler.rewards.evaluate import evaluate_spider2sql
import os

ground_truths = "deepscaler/rewards/gold/gold_answer"
model_answer = "SELECT DISTINCT T1.item_nbr FROM sales_in_weather AS T1 INNER JOIN relation AS T2 ON T1.store_nbr = T2.store_nbr INNER JOIN weather AS T3 ON T2.station_nbr = T3.station_nbr WHERE T2.store_nbr = 3 AND T3.date BETWEEN '2012-01-01' AND '2012-12-31' GROUP BY T1.item_nbr, T3.date ORDER BY SUM(T1.units) DESC LIMIT 1"
sqlite_path = "data/BIRD/train/train_databases/sales_in_weather/sales_in_weather.sqlite"
example_id = "bq362"
csv_save_path = os.path.join("exec", example_id+"_132191551997504.csv")

# if execute_sql_api(model_answer, csv_save_path, api=get_api_name(example_id), sqlite_path=sqlite_path) == 0:
is_correct = evaluate_spider2sql(ground_truths, csv_save_path, example_id)
if is_correct:
    print(f"Correct: {example_id}")