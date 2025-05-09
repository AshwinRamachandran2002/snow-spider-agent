SELECT
    CASE
        WHEN age BETWEEN 20 AND 29 THEN '20s'
        WHEN age BETWEEN 30 AND 39 THEN '30s'
        WHEN age BETWEEN 40 AND 49 THEN '40s'
        WHEN age BETWEEN 50 AND 59 THEN '50s'
        ELSE 'others'
    END AS age_category,
    COUNT(*) AS user_count
FROM (
    SELECT
        user_id,
        (CAST(strftime('%Y','now') AS INTEGER) - CAST(substr(birth_date, 1, 4) AS INTEGER)) AS age
    FROM mst_users
) AS derived
GROUP BY age_category
ORDER BY age_category;