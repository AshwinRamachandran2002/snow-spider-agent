WITH bronx_counts AS (
    SELECT
        COUNT(*)                                            AS "total_trees",
        SUM(CASE WHEN "health" = 'Good' THEN 1 ELSE 0 END) AS "good_trees"
    FROM MODERN_DATA.MODERN_DATA.TREES
    WHERE "boroname" = 'Bronx'
)
SELECT
    ROUND("good_trees" * 100.0 / "total_trees", 4) AS "percentage_good_health_bronx"
FROM bronx_counts;