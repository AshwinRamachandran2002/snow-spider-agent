WITH categorized AS (
    SELECT
        CASE 
            WHEN LOWER("L1_model") IN ('stack', 'stacking', 'stack_model') 
                 THEN 'Stack'
            ELSE 'Traditional'
        END AS model_category
    FROM STACKING.STACKING.MODEL
)
SELECT
    model_category,
    COUNT(*) AS total_count
FROM categorized
GROUP BY model_category
ORDER BY total_count DESC NULLS LAST
LIMIT 1;