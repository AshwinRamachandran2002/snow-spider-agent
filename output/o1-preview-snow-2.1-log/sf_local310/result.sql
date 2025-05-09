SELECT D."year", ROUND(D."max_driver_points" + C."max_constructor_points", 4) AS "sum_points"
FROM
(
    SELECT driver_totals."year", MAX(driver_totals."total_points") AS "max_driver_points"
    FROM (
        SELECT RA."year", R."driver_id", SUM(R."points") AS "total_points"
        FROM "F1"."F1"."RESULTS" R
        JOIN "F1"."F1"."RACES" RA ON R."race_id" = RA."race_id"
        GROUP BY RA."year", R."driver_id"
    ) AS driver_totals
    GROUP BY driver_totals."year"
) D
JOIN
(
    SELECT constructor_totals."year", MAX(constructor_totals."total_points") AS "max_constructor_points"
    FROM (
        SELECT RA."year", CR."constructor_id", SUM(CR."points") AS "total_points"
        FROM "F1"."F1"."CONSTRUCTOR_RESULTS" CR
        JOIN "F1"."F1"."RACES" RA ON CR."race_id" = RA."race_id"
        GROUP BY RA."year", CR."constructor_id"
    ) AS constructor_totals
    GROUP BY constructor_totals."year"
) C ON D."year" = C."year"
ORDER BY "sum_points" ASC
LIMIT 3;