WITH season_final AS (
    SELECT r."year",
           r."race_id"
    FROM   "races" AS r
    JOIN  (SELECT "year", MAX("round") AS final_round
           FROM   "races"
           GROUP  BY "year") AS f
      ON  r."year"  = f."year"
     AND  r."round" = f."final_round"
),
season_combined AS (
    SELECT sf."year",
           c."name"                        AS "constructor",
           cs."points"                     AS "team_pts",
           MAX(ds."points")                AS "best_driver_pts",
           cs."points" + MAX(ds."points")  AS "combined_pts"
    FROM   season_final           AS sf
    JOIN   "constructor_standings" AS cs ON cs."race_id" = sf."race_id"
    JOIN   "constructors"          AS c  USING ("constructor_id")
    JOIN   "results"               AS r  ON r."race_id"      = cs."race_id"
                                        AND r."constructor_id" = cs."constructor_id"
    JOIN   "driver_standings"      AS ds ON ds."race_id" = r."race_id"
                                        AND ds."driver_id" = r."driver_id"
    GROUP  BY sf."year", cs."constructor_id"
)
SELECT "constructor",
       "year",
       "combined_pts"
FROM   season_combined
ORDER  BY "combined_pts" DESC
LIMIT 3;