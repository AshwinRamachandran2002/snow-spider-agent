WITH categorized_models AS (
    SELECT
        CASE 
            WHEN LOWER("L1_model") LIKE '%stack%' THEN 'Stack'
            ELSE 'Traditional'
        END AS "model_category"
    FROM STACKING.STACKING.MODEL
)
SELECT 
    "model_category",
    COUNT(*) AS "total_count"
FROM categorized_models
GROUP BY "model_category"
ORDER BY "total_count" DESC NULLS LAST
LIMIT 1;