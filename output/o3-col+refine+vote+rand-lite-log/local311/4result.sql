/*  Top-3 constructor-seasons by the sum of
    – constructor points (season total)      and
    – the points of that team’s highest-scoring driver */
WITH last_round_per_year AS (
    SELECT "year",
           MAX("round") AS last_round
    FROM "races"
    GROUP BY "year"
),
season_end_races AS (
    SELECT r."race_id",
           r."year"
    FROM "races" AS r
    JOIN last_round_per_year AS lr
         ON lr."year"      = r."year"
        AND lr.last_round  = r."round"
),
-- constructor points at the end of each season
constructor_points AS (
    SELECT ser."year",
           cs."constructor_id",
           cs."points" AS constructor_points
    FROM "constructor_standings" AS cs
    JOIN season_end_races AS ser
         ON ser."race_id" = cs."race_id"
),
-- driver points at the end of each season
driver_points AS (
    SELECT ser."year",
           ds."driver_id",
           ds."points" AS driver_points
    FROM "driver_standings" AS ds
    JOIN season_end_races AS ser
         ON ser."race_id" = ds."race_id"
),
-- attach each driver to the constructor they raced for that season
driver_constructor AS (
    SELECT dp."year",
           tdr."constructor_id",
           dp.driver_points
    FROM driver_points AS dp
    JOIN "team_driver_ranks" AS tdr
         ON tdr."year"      = dp."year"
        AND tdr."driver_id" = dp."driver_id"
),
-- keep every constructor’s best (highest-scoring) driver for the season
best_driver_points AS (
    SELECT "year",
           "constructor_id",
           MAX(driver_points) AS best_driver_points
    FROM driver_constructor
    GROUP BY "year", "constructor_id"
),
-- combine best-driver points with constructor points
combined_points AS (
    SELECT cp."year",
           cp."constructor_id",
           cp.constructor_points + bdp.best_driver_points AS combined_points
    FROM constructor_points  AS cp
    JOIN best_driver_points AS bdp
         ON bdp."year"          = cp."year"
        AND bdp."constructor_id" = cp."constructor_id"
)
SELECT c."name"           AS constructor_name,
       cb."year",
       cb.combined_points
FROM combined_points AS cb
JOIN "constructors"  AS c
     ON c."constructor_id" = cb."constructor_id"
ORDER BY cb.combined_points DESC
LIMIT 3;