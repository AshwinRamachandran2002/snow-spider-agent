WITH final_races AS (
    SELECT r1."year",
           r1."race_id"
    FROM   "races" AS r1
    JOIN  (
            SELECT "year",
                   MAX("round") AS max_round
            FROM   "races"
            GROUP  BY "year"
          ) AS m
          ON m."year"      = r1."year"
         AND m.max_round   = r1."round"
),
best_driver_pts AS (
    /* best (higher‑scoring) driver for each team in the season’s final race */
    SELECT fr."year",
           res."constructor_id",
           MAX(ds."points") AS best_driver_points
    FROM   final_races      AS fr
    JOIN   "driver_standings" AS ds
           ON ds."race_id" = fr."race_id"
    JOIN   "results"          AS res
           ON res."race_id"   = ds."race_id"
          AND res."driver_id" = ds."driver_id"
    GROUP  BY fr."year",
             res."constructor_id"
),
team_pts AS (
    /* team’s (constructor) points in the season’s final race */
    SELECT fr."year",
           cs."constructor_id",
           cs."points" AS team_points
    FROM   final_races            AS fr
    JOIN   "constructor_standings" AS cs
           ON cs."race_id" = fr."race_id"
),
combined AS (
    SELECT bp."year",
           bp."constructor_id",
           bp.best_driver_points + tp.team_points AS combined_points
    FROM   best_driver_pts AS bp
    JOIN   team_pts        AS tp
           ON tp."year"           = bp."year"
          AND tp."constructor_id" = bp."constructor_id"
)
SELECT c."name"  AS constructor_name,
       comb."year",
       comb."combined_points"
FROM   combined      AS comb
JOIN   "constructors" AS c
       ON c."constructor_id" = comb."constructor_id"
ORDER  BY comb."combined_points" DESC,
         comb."year"           DESC
LIMIT  3;