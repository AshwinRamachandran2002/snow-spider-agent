WITH team_totals AS (
    SELECT
        r."constructor_id",
        ra."year",
        SUM(r."points") AS "team_points"
    FROM
        "F1"."F1"."RESULTS" r
    JOIN
        "F1"."F1"."RACES" ra ON r."race_id" = ra."race_id"
    GROUP BY
        r."constructor_id", ra."year"
),
driver_totals AS (
    SELECT
        r."constructor_id",
        ra."year",
        r."driver_id",
        SUM(r."points") AS "driver_points"
    FROM
        "F1"."F1"."RESULTS" r
    JOIN
        "F1"."F1"."RACES" ra ON r."race_id" = ra."race_id"
    GROUP BY
        r."constructor_id", r."driver_id", ra."year"
),
best_driver_per_team AS (
    SELECT
        dt."constructor_id",
        dt."year",
        dt."driver_id",
        dt."driver_points",
        ROW_NUMBER() OVER (PARTITION BY dt."constructor_id", dt."year" ORDER BY dt."driver_points" DESC) AS rn
    FROM
        driver_totals dt
),
best_drivers AS (
    SELECT
        "constructor_id",
        "year",
        "driver_id",
        "driver_points"
    FROM
        best_driver_per_team
    WHERE rn = 1
)
SELECT
    c."name" AS "Constructor",
    tt."year" AS "Year",
    ROUND((tt."team_points" + bd."driver_points"), 4) AS "Combined_Points"
FROM
    team_totals tt
JOIN
    best_drivers bd ON tt."constructor_id" = bd."constructor_id" AND tt."year" = bd."year"
JOIN
    "F1"."F1"."CONSTRUCTORS" c ON tt."constructor_id" = c."constructor_id"
ORDER BY
    "Combined_Points" DESC
LIMIT 3;