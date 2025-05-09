WITH last_races AS (
    SELECT "year",
           MAX("round") AS max_round
    FROM   "races"
    GROUP  BY "year"
),
final_races AS (
    SELECT r."race_id",
           r."year"
    FROM   "races" r
    JOIN   last_races lr
           ON  lr."year"      = r."year"
           AND lr.max_round   = r."round"
),
driver_champ AS (
    SELECT fr."year",
           ds."driver_id",
           ds."points",
           RANK() OVER (PARTITION BY fr."year"
                        ORDER BY ds."points" DESC) AS rk
    FROM   "driver_standings" ds
    JOIN   final_races        fr ON fr."race_id" = ds."race_id"
),
constructor_champ AS (
    SELECT fr."year",
           cs."constructor_id",
           cs."points",
           RANK() OVER (PARTITION BY fr."year"
                        ORDER BY cs."points" DESC) AS rk
    FROM   "constructor_standings" cs
    JOIN   final_races             fr ON fr."race_id" = cs."race_id"
)
SELECT dc."year",
       drv."forename" || ' ' || drv."surname" AS driver_full_name,
       cons."name"                            AS constructor_name,
       dc."points"                            AS driver_points,
       cc."points"                            AS constructor_points
FROM   driver_champ      dc
JOIN   "drivers"         drv  ON drv."driver_id"      = dc."driver_id"
JOIN   constructor_champ cc   ON cc."year"            = dc."year"  AND cc.rk = 1
JOIN   "constructors"    cons ON cons."constructor_id" = cc."constructor_id"
WHERE  dc.rk = 1
ORDER  BY dc."year";