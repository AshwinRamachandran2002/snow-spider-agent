WITH bronx_trees AS (
    SELECT "health"
    FROM MODERN_DATA.MODERN_DATA.TREES
    WHERE "boroname" = 'Bronx'
)
SELECT
    ROUND(
        (COUNT(CASE WHEN "health" = 'Good' THEN 1 END) * 100.0)
        / NULLIF(COUNT(*), 0),
        4
    ) AS "percent_good_health"
FROM bronx_trees;