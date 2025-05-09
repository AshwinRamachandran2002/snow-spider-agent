SELECT 
       CASE
           WHEN LOWER("L1_model") LIKE '%stack%' THEN 'stack'
           ELSE 'traditional'
       END AS model_category,
       COUNT(*) AS total_occurrences
FROM   "model"
GROUP  BY model_category
ORDER  BY total_occurrences DESC
LIMIT 1;