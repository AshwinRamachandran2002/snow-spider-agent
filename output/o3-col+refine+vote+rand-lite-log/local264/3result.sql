SELECT
    CASE WHEN "L1_model" = 'Stack' THEN 'Stack' ELSE 'Traditional' END AS model_category,
    COUNT(*) AS cnt
FROM "model"
GROUP BY model_category
ORDER BY cnt DESC
LIMIT 1;