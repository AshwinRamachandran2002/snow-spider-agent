WITH final_races AS (                          -- last Grand Prix of every season
    SELECT r."year",
           r."race_id"
    FROM   "races" r
    JOIN  (SELECT "year", MAX("round") AS max_round
           FROM   "races"
           GROUP  BY "year") fr
      ON  fr."year" = r."year" AND fr.max_round = r."round"
),
best_driver_points AS (                        -- best-scoring driver per constructor & year
    SELECT fr."year",
           res."constructor_id",
           MAX(ds."points") AS max_driver_pts
    FROM   "driver_standings"  ds
    JOIN   "results"           res ON res."race_id" = ds."race_id"
                                   AND res."driver_id" = ds."driver_id"
    JOIN   final_races         fr  ON fr."race_id"  = ds."race_id"
    GROUP  BY fr."year", res."constructor_id"
),
team_points AS (                               -- constructor (team) points per year
    SELECT fr."year",
           cs."constructor_id",
           cs."points" AS team_pts
    FROM   "constructor_standings" cs
    JOIN   final_races            fr ON fr."race_id" = cs."race_id"
),
combined AS (                                 -- combine best driver + team points
    SELECT b."year",
           b."constructor_id",
           (b.max_driver_pts + t.team_pts) AS combined_pts
    FROM   best_driver_points b
    JOIN   team_points        t
           ON t."year" = b."year" AND t."constructor_id" = b."constructor_id"
)
SELECT c."name"         AS constructor,
       comb."year",
       comb.combined_pts
FROM   combined comb
JOIN   "constructors" c ON c."constructor_id" = comb."constructor_id"
ORDER  BY comb.combined_pts DESC
LIMIT 3;