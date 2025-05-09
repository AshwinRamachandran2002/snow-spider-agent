WITH final_races AS (   -- identify the last race of every season
    SELECT
        "year",
        MAX("round") AS "final_round"
    FROM F1.F1.RACES
    GROUP BY "year"
),
final_race_ids AS (     -- fetch the race_id for those final rounds
    SELECT
        r."year",
        r."race_id"
    FROM F1.F1.RACES r
    JOIN final_races fr
      ON r."year" = fr."year"
     AND r."round" = fr."final_round"
),
constructor_final AS (  -- constructor points in the final standings of each year
    SELECT
        fr."year",
        cs."constructor_id",
        cs."points"                         AS "constructor_points"
    FROM F1.F1.CONSTRUCTOR_STANDINGS cs
    JOIN final_race_ids fr
      ON cs."race_id" = fr."race_id"
),
driver_final AS (       -- driver points plus the constructor they drove for in that final race
    SELECT
        fr."year",
        res."constructor_id",
        ds."driver_id",
        ds."points"                         AS "driver_points"
    FROM F1.F1.DRIVER_STANDINGS ds
    JOIN final_race_ids fr
      ON ds."race_id" = fr."race_id"
    JOIN F1.F1.RESULTS res                 -- map driver to constructor in that race
      ON res."race_id"  = ds."race_id"
     AND res."driver_id" = ds."driver_id"
),
best_driver_points AS ( -- best-scoring driver per constructor & year
    SELECT
        "year",
        "constructor_id",
        MAX("driver_points")                AS "best_driver_points"
    FROM driver_final
    GROUP BY "year", "constructor_id"
),
combined AS (           -- combine team points with best driver points
    SELECT
        cf."year",
        cf."constructor_id",
        cf."constructor_points",
        bd."best_driver_points",
        (cf."constructor_points" + bd."best_driver_points") AS "combined_points"
    FROM constructor_final cf
    JOIN best_driver_points bd
      ON cf."year"          = bd."year"
     AND cf."constructor_id" = bd."constructor_id"
)
SELECT
    c."name"               AS "constructor_name",
    cm."year",
    cm."combined_points"
FROM combined cm
JOIN F1.F1.CONSTRUCTORS c
  ON c."constructor_id" = cm."constructor_id"
ORDER BY cm."combined_points" DESC NULLS LAST
LIMIT 3;