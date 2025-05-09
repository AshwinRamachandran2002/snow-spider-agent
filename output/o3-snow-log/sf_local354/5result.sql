WITH driver_results_50s AS (
    SELECT
        R."year",
        RES."driver_id",
        RES."constructor_id",
        R."round"
    FROM F1.F1."RACES"   R
    JOIN F1.F1."RESULTS" RES
          ON RES."race_id" = R."race_id"
    WHERE R."year" BETWEEN 1950 AND 1959
),
round_stats AS (
    SELECT
        "year",
        "driver_id",
        MIN("round") AS first_round,
        MAX("round") AS last_round,
        COUNT(DISTINCT "round") AS round_cnt
    FROM driver_results_50s
    GROUP BY "year", "driver_id"
    HAVING COUNT(DISTINCT "round") >= 2          -- took part in ≥ 2 different rounds
),
first_constructors AS (
    SELECT
        rs."year",
        rs."driver_id",
        drf."constructor_id" AS first_constructor_id
    FROM round_stats        rs
    JOIN driver_results_50s drf
          ON drf."year"      = rs."year"
         AND drf."driver_id" = rs."driver_id"
         AND drf."round"     = rs.first_round
),
last_constructors AS (
    SELECT
        rs."year",
        rs."driver_id",
        drl."constructor_id" AS last_constructor_id
    FROM round_stats        rs
    JOIN driver_results_50s drl
          ON drl."year"      = rs."year"
         AND drl."driver_id" = rs."driver_id"
         AND drl."round"     = rs.last_round
),
qualified_driver_seasons AS (
    SELECT
        fc."year",
        fc."driver_id"
    FROM first_constructors fc
    JOIN last_constructors  lc
          ON fc."year"      = lc."year"
         AND fc."driver_id" = lc."driver_id"
    WHERE fc.first_constructor_id = lc.last_constructor_id   -- same constructor in first & last race
)
SELECT DISTINCT
       d."full_name" AS "driver_name"
FROM qualified_driver_seasons qds
JOIN F1.F1."DRIVERS" d
     ON d."driver_id" = qds."driver_id"
ORDER BY "driver_name";