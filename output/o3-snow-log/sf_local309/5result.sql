WITH driver_totals AS (         -- total points per driver & year
    SELECT
        r."year",
        ds."driver_id",
        SUM(ds."points") AS "driver_points"
    FROM F1.F1.DRIVER_STANDINGS ds
    JOIN F1.F1.RACES            r ON r."race_id" = ds."race_id"
    GROUP BY r."year", ds."driver_id"
),
driver_ranks AS (               -- keep highest-scoring driver(s) each year
    SELECT
        dt.*,
        RANK() OVER (PARTITION BY dt."year"
                     ORDER BY dt."driver_points" DESC) AS "driver_rank"
    FROM driver_totals dt
),
constructor_totals AS (         -- total points per constructor & year
    SELECT
        r."year",
        cs."constructor_id",
        SUM(cs."points") AS "constructor_points"
    FROM F1.F1.CONSTRUCTOR_STANDINGS cs
    JOIN F1.F1.RACES                r ON r."race_id" = cs."race_id"
    GROUP BY r."year", cs."constructor_id"
),
constructor_ranks AS (          -- keep highest-scoring constructor(s) each year
    SELECT
        ct.*,
        RANK() OVER (PARTITION BY ct."year"
                     ORDER BY ct."constructor_points" DESC) AS "constructor_rank"
    FROM constructor_totals ct
)
SELECT
    dr."year",
    dv."full_name"        AS "top_driver",
    dr."driver_points",
    cn."name"             AS "top_constructor",
    cr."constructor_points"
FROM driver_ranks      dr
JOIN F1.F1.DRIVERS     dv  ON dv."driver_id"       = dr."driver_id"
JOIN constructor_ranks cr  ON cr."year"            = dr."year"
                           AND cr."constructor_rank" = 1
JOIN F1.F1.CONSTRUCTORS cn ON cn."constructor_id"  = cr."constructor_id"
WHERE dr."driver_rank" = 1
ORDER BY dr."year";