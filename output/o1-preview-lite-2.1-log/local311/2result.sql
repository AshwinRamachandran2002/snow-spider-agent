SELECT
    constructors."name" AS Constructor_Name,
    combined_points."year" AS Year,
    (combined_points."constructor_points" + combined_points."driver_points") AS Combined_Points
FROM (
    SELECT
        c_points."constructor_id",
        c_points."year",
        c_points."constructor_points",
        d_points."driver_points"
    FROM
        (SELECT races."year", results."constructor_id", SUM(results."points") AS constructor_points
         FROM "results"
         JOIN "races" ON results."race_id" = races."race_id"
         GROUP BY races."year", results."constructor_id") AS c_points
    JOIN
        (SELECT sub."year", sub."constructor_id", MAX(sub."driver_points") AS driver_points
         FROM (
             SELECT races."year", results."constructor_id", results."driver_id", SUM(results."points") AS driver_points
             FROM "results"
             JOIN "races" ON results."race_id" = races."race_id"
             GROUP BY races."year", results."constructor_id", results."driver_id"
         ) AS sub
         GROUP BY sub."year", sub."constructor_id") AS d_points
    ON c_points."constructor_id" = d_points."constructor_id" AND c_points."year" = d_points."year"
) AS combined_points
JOIN "constructors" ON combined_points."constructor_id" = "constructors"."constructor_id"
ORDER BY Combined_Points DESC
LIMIT 3;