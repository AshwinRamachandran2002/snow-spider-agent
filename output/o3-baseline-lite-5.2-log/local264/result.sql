WITH categorized AS (
    SELECT 
        CASE 
            WHEN LOWER("L1_model") LIKE '%stack%' THEN 'Stack'
            ELSE 'Traditional'
        END AS model_category
    FROM "model"
)
SELECT 
    model_category,
    COUNT(*) AS total_count
FROM categorized
GROUP BY model_category
ORDER BY total_count DESC
LIMIT 1;