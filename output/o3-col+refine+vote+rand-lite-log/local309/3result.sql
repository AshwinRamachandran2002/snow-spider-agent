WITH driver_totals AS (       -- total points every driver scored each season
    SELECT r."year"                 AS year,
           ds."driver_id"           AS driver_id,
           SUM(ds."points")         AS total_points
    FROM   "driver_standings" ds
    JOIN   "races"            r  ON r."race_id" = ds."race_id"
    GROUP  BY r."year", ds."driver_id"
),
driver_ranked AS (           -- rank drivers per season (highest points first, tie-breaker on id)
    SELECT dt.*,
           ROW_NUMBER() OVER (PARTITION BY dt.year
                              ORDER BY dt.total_points DESC, dt.driver_id) AS rn
    FROM   driver_totals dt
),
driver_winners AS (          -- 1 row per season: top-scoring driver
    SELECT dr.year,
           d."full_name"
    FROM   driver_ranked dr
    JOIN   "drivers_ext" d ON d."driver_id" = dr."driver_id"
    WHERE  dr.rn = 1
),
constructor_totals AS (      -- total points every constructor scored each season
    SELECT r."year"                 AS year,
           cs."constructor_id"      AS constructor_id,
           SUM(cs."points")         AS total_points
    FROM   "constructor_standings" cs
    JOIN   "races"             r ON r."race_id" = cs."race_id"
    GROUP  BY r."year", cs."constructor_id"
),
constructor_ranked AS (      -- rank constructors per season
    SELECT ct.*,
           ROW_NUMBER() OVER (PARTITION BY ct.year
                              ORDER BY ct.total_points DESC, ct.constructor_id) AS rn
    FROM   constructor_totals ct
),
constructor_winners AS (     -- 1 row per season: top-scoring constructor
    SELECT cr.year,
           c."name" AS constructor_name
    FROM   constructor_ranked cr
    JOIN   "constructors" c ON c."constructor_id" = cr."constructor_id"
    WHERE  cr.rn = 1
)

SELECT dw.year,
       dw.full_name  AS driver_full_name,
       cw.constructor_name
FROM   driver_winners      dw
JOIN   constructor_winners cw ON cw.year = dw.year
ORDER  BY dw.year;