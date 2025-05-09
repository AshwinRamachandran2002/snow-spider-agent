SELECT CASE WHEN LOWER("L1_model") LIKE '%stack%' THEN 'Stack' ELSE 'Traditional' END AS "model_type",
       COUNT(*) AS "total_count"
FROM "model"
GROUP BY "model_type"
ORDER BY "total_count" DESC
LIMIT 1;