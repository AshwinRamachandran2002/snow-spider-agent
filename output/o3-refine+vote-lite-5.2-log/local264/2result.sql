SELECT
    L1_model,
    COUNT(*) AS total_occurrences
FROM
    model
GROUP BY
    L1_model
ORDER BY
    total_occurrences DESC
LIMIT 1;