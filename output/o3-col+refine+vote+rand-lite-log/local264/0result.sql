SELECT
        CASE
            WHEN LOWER("L1_model") = 'tree'
                 THEN 'Stack model'
            ELSE     'Traditional model'
        END                      AS model_category,
        COUNT(*)                 AS total_occurrences
FROM    "model"
GROUP BY model_category
ORDER BY total_occurrences DESC
LIMIT 1;