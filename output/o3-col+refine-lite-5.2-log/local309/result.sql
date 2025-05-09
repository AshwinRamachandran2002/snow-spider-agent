WITH final_rounds AS (
    SELECT "year",
           MAX("round") AS max_round
    FROM   "races"
    GROUP  BY "year"
),
-- driver totals after the final round of each season
driver_totals AS (
    SELECT r."year",
           ds."driver_id",
           ds."points"
    FROM   "races"            r
    JOIN   final_rounds       fr  ON fr."year" = r."year"
                                 AND fr.max_round = r."round"
    JOIN   "driver_standings" ds  ON ds."race_id" = r."race_id"
),
-- pick the driver with most points per year
driver_champs AS (
    SELECT "year",
           "driver_id",
           "points" AS driver_points
    FROM (
        SELECT dt.*,
               RANK() OVER (PARTITION BY dt."year" ORDER BY dt."points" DESC) AS rk
        FROM   driver_totals dt
    )
    WHERE rk = 1
),
-- constructor totals after the final round of each season
constructor_totals AS (
    SELECT r."year",
           cs."constructor_id",
           cs."points"
    FROM   "races"                 r
    JOIN   final_rounds            fr  ON fr."year" = r."year"
                                      AND fr.max_round = r."round"
    JOIN   "constructor_standings" cs  ON cs."race_id" = r."race_id"
),
-- pick the constructor with most points per year
constructor_champs AS (
    SELECT "year",
           "constructor_id",
           "points" AS constructor_points
    FROM (
        SELECT ct.*,
               RANK() OVER (PARTITION BY ct."year" ORDER BY ct."points" DESC) AS rk
        FROM   constructor_totals ct
    )
    WHERE rk = 1
)
SELECT dc."year",
       drv."full_name"     AS driver,
       dc.driver_points,
       cons."name"         AS constructor,
       cc.constructor_points
FROM   driver_champs      dc
JOIN   constructor_champs cc   ON cc."year" = dc."year"
JOIN   "drivers_ext"      drv  ON drv."driver_id"       = dc."driver_id"
JOIN   "constructors_ext" cons ON cons."constructor_id" = cc."constructor_id"
ORDER  BY dc."year";