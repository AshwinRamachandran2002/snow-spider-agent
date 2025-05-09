SELECT
    'Good' AS health_status,
    ROUND(
        100.0 * SUM(CASE WHEN "health" = 'Good' THEN 1 ELSE 0 END) / COUNT(*),
        4
    ) AS percentage
FROM "trees"
WHERE "boroname" = 'Bronx';