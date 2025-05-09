SELECT
    CASE
        WHEN LOWER("L1_model") LIKE '%stack%' THEN 'Stack model'
        ELSE 'Traditional model'
    END AS most_frequent_category,
    COUNT(*) AS total_occurrences
FROM "model"
GROUP BY most_frequent_category
ORDER BY total_occurrences DESC
LIMIT 1;