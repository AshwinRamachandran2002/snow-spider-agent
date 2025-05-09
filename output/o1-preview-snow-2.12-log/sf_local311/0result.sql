SELECT
    c."name" AS "Constructor",
    t."year" AS "Year",
    ROUND(t."total_constructor_points", 4) AS "Combined_Points"
FROM (
    SELECT
        res."constructor_id",
        r."year",
        SUM(res."points") AS "total_constructor_points"
    FROM F1.F1.RESULTS res
    INNER JOIN F1.F1.RACES r ON res."race_id" = r."race_id"
    GROUP BY res."constructor_id", r."year"
) t
INNER JOIN F1.F1.CONSTRUCTORS c ON t."constructor_id" = c."constructor_id"
ORDER BY t."total_constructor_points" DESC NULLS LAST
LIMIT 3;