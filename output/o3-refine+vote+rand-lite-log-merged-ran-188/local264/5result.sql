SELECT
    category,
    COUNT(*) AS total_count
FROM (
    SELECT
        CASE
            WHEN LOWER("L1_model") LIKE '%stack%' THEN 'Stack'
            ELSE 'Traditional'
        END AS category
    FROM "model"
) AS categorized_models
GROUP BY category
ORDER BY total_count DESC
LIMIT 1;