SELECT
    'Traditional' AS L1_model,
    COUNT(*) AS total_count
FROM "model"
WHERE LOWER("L1_model") NOT LIKE '%stack%';