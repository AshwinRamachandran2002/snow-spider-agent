WITH last_race_per_year AS (
    SELECT "year", MAX("round") AS last_round
    FROM "races"
    GROUP BY "year"
),
season_final_races AS (
    SELECT r."race_id", r."year"
    FROM "races" r
    JOIN last_race_per_year l
      ON l."year" = r."year"
     AND l.last_round = r."round"
),
best_driver_points AS (
    SELECT sfr."year",
           res."constructor_id",
           MAX(ds."points") AS best_driver_points
    FROM   season_final_races sfr
    JOIN   "driver_standings" ds
           ON ds."race_id" = sfr."race_id"
    JOIN   "results" res
           ON res."race_id" = ds."race_id"
          AND res."driver_id" = ds."driver_id"
    GROUP BY sfr."year", res."constructor_id"
),
team_points AS (
    SELECT sfr."year",
           cs."constructor_id",
           cs."points" AS team_points
    FROM   season_final_races sfr
    JOIN   "constructor_standings" cs
           ON cs."race_id" = sfr."race_id"
),
combined AS (
    SELECT tp."year",
           tp."constructor_id",
           tp.team_points + bd.best_driver_points AS combined_points
    FROM   team_points tp
    JOIN   best_driver_points bd
           ON bd."year" = tp."year"
          AND bd."constructor_id" = tp."constructor_id"
)
SELECT c."name"                          AS constructor,
       combined."year",
       printf('%.4f', combined.combined_points) AS combined_points
FROM   combined
JOIN   "constructors" c
       ON c."constructor_id" = combined."constructor_id"
ORDER BY combined.combined_points DESC,
         constructor,
         combined."year"
LIMIT 3;