SELECT
    ROUND(
        100.0 * SUM(CASE WHEN "health" = 'Good' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),
        4
    ) AS "PERCENTAGE_GOOD"
FROM MODERN_DATA.MODERN_DATA.TREES
WHERE "boroname" = 'Bronx'
  AND "health" IS NOT NULL;