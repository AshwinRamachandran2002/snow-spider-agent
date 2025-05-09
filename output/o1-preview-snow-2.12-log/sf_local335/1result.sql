WITH driver_season_points AS (
    SELECT
        rac."year",
        res."driver_id",
        SUM(COALESCE(res."points", 0)) AS "driver_total_points"
    FROM
        "F1"."F1"."RESULTS" res
        JOIN "F1"."F1"."RACES" rac ON res."race_id" = rac."race_id"
    WHERE
        rac."year" >= 2001
    GROUP BY
        rac."year",
        res."driver_id"
),
min_points_per_season AS (
    SELECT
        dsp."year",
        MIN(dsp."driver_total_points") AS "min_points"
    FROM
        driver_season_points dsp
    GROUP BY
        dsp."year"
),
drivers_with_min_points AS (
    SELECT
        dsp."year",
        dsp."driver_id"
    FROM
        driver_season_points dsp
        JOIN min_points_per_season mps ON dsp."year" = mps."year" AND dsp."driver_total_points" = mps."min_points"
),
driver_constructors AS (
    SELECT DISTINCT
        rac."year",
        res."driver_id",
        res."constructor_id"
    FROM
        "F1"."F1"."RESULTS" res
        JOIN "F1"."F1"."RACES" rac ON res."race_id" = rac."race_id"
    WHERE
        rac."year" >= 2001
),
constructors_with_min_drivers AS (
    SELECT DISTINCT
        dmp."year",
        dc."constructor_id"
    FROM
        drivers_with_min_points dmp
        JOIN driver_constructors dc ON dmp."year" = dc."year" AND dmp."driver_id" = dc."driver_id"
)
SELECT
    c."name" AS "Constructor",
    COUNT(*) AS "Number_of_Seasons_With_Fewest_Points"
FROM
    constructors_with_min_drivers cmd
    JOIN "F1"."F1"."CONSTRUCTORS" c ON cmd."constructor_id" = c."constructor_id"
GROUP BY
    c."name"
ORDER BY
    "Number_of_Seasons_With_Fewest_Points" DESC
LIMIT 5;