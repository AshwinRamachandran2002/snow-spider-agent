SELECT 
    "L1_model" AS model_category,
    COUNT(*)  AS total_occurrences
FROM STACKING.STACKING.MODEL
GROUP BY "L1_model"
ORDER BY total_occurrences DESC NULLS LAST
LIMIT 1;