WITH final_races AS (                               -- last Grand Prix of each season
    SELECT r."year",
           r."race_id"
    FROM   "races" r
    JOIN  (
        SELECT "year", MAX("round") AS max_round
        FROM   "races"
        WHERE  "year" >= 2001
        GROUP  BY "year"
    ) t
      ON  t."year"    = r."year"
     AND  t.max_round = r."round"
),
min_points AS (                                     -- fewest positive points each season
    SELECT fr."year",
           MIN(ds."points") AS min_pts
    FROM   final_races fr
    JOIN   "driver_standings" ds ON ds."race_id" = fr."race_id"
    WHERE  ds."points" > 0
    GROUP  BY fr."year"
),
lowest_drivers AS (                                 -- drivers with that minimum
    SELECT fr."year",
           ds."driver_id"
    FROM   final_races  fr
    JOIN   "driver_standings" ds ON ds."race_id" = fr."race_id"
    JOIN   min_points    mp ON mp."year" = fr."year"
                           AND mp.min_pts = ds."points"
),
driver_constructors AS (                            -- constructor in the final race
    SELECT ld."year",
           res."constructor_id"
    FROM   lowest_drivers ld
    JOIN   final_races fr ON fr."year" = ld."year"
    JOIN   "results"  res ON res."race_id"  = fr."race_id"
                         AND res."driver_id" = ld."driver_id"
)
SELECT c."name"                       AS constructor_name,
       COUNT(DISTINCT dc."year")      AS seasons_with_lowest_scorer
FROM   driver_constructors dc
JOIN   "constructors" c ON c."constructor_id" = dc."constructor_id"
GROUP  BY c."name"
ORDER  BY seasons_with_lowest_scorer DESC,
         c."name"
LIMIT 5;