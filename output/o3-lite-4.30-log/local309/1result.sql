WITH final_races AS (                      -- last race of every season
    SELECT  r."year",
            r."race_id"
    FROM    "races" r
    JOIN   (SELECT "year", MAX("round") AS max_round
            FROM   "races"
            GROUP  BY "year") mr
           ON  r."year" = mr."year"
           AND r."round" = mr.max_round
),
driver_champ AS (                          -- champion driver per season
    SELECT  fr."year",
            d."full_name" AS driver_name,
            ROW_NUMBER() OVER (PARTITION BY fr."year"
                               ORDER BY ds."points" DESC, ds."driver_id") AS rn
    FROM    final_races fr
    JOIN    "driver_standings" ds ON ds."race_id" = fr."race_id"
    JOIN    "drivers"          d  ON d."driver_id" = ds."driver_id"
),
constructor_champ AS (                     -- champion constructor per season
    SELECT  fr."year",
            c."name" AS constructor_name,
            ROW_NUMBER() OVER (PARTITION BY fr."year"
                               ORDER BY cs."points" DESC, cs."constructor_id") AS rn
    FROM    final_races fr
    JOIN    "constructor_standings" cs ON cs."race_id" = fr."race_id"
    JOIN    "constructors"          c  ON c."constructor_id" = cs."constructor_id"
)
SELECT  dc."year",
        dc.driver_name,
        cc.constructor_name
FROM    driver_champ      dc
JOIN    constructor_champ cc ON cc."year" = dc."year"
WHERE   dc.rn = 1
  AND   cc.rn = 1
ORDER BY dc."year";