SELECT
  CASE
      WHEN LOWER("L1_model") LIKE '%stack%' THEN 'Stack model'
      ELSE 'Traditional model'
  END AS model_category,
  COUNT(*) AS total_count
FROM "model"
GROUP BY model_category
ORDER BY total_count DESC
LIMIT 1;