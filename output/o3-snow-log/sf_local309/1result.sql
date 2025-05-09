WITH driver_totals AS (
    SELECT
        r."year",
        ds."driver_id",
        SUM(ds."points") AS "driver_points"
    FROM F1.F1."DRIVER_STANDINGS_EXT" ds
    JOIN F1.F1."RACES" r
      ON ds."race_id" = r."race_id"
    GROUP BY r."year", ds."driver_id"
),
driver_ranked AS (
    SELECT
        dt.*,
        ROW_NUMBER() OVER (
            PARTITION BY dt."year"
            ORDER BY dt."driver_points" DESC NULLS LAST, dt."driver_id"
        ) AS "rn"
    FROM driver_totals dt
),
constructor_totals AS (
    SELECT
        r."year",
        cs."constructor_id",
        SUM(cs."points") AS "constructor_points"
    FROM F1.F1."CONSTRUCTOR_STANDINGS" cs
    JOIN F1.F1."RACES" r
      ON cs."race_id" = r."race_id"
    GROUP BY r."year", cs."constructor_id"
),
constructor_ranked AS (
    SELECT
        ct.*,
        ROW_NUMBER() OVER (
            PARTITION BY ct."year"
            ORDER BY ct."constructor_points" DESC NULLS LAST, ct."constructor_id"
        ) AS "rn"
    FROM constructor_totals ct
)
SELECT
    dr."year",
    drv."full_name"           AS "top_driver",
    dr."driver_points",
    con."name"                AS "top_constructor",
    cr."constructor_points"
FROM driver_ranked dr
JOIN F1.F1."DRIVERS"      drv  ON dr."driver_id"      = drv."driver_id"
JOIN constructor_ranked   cr   ON dr."year"           = cr."year"
JOIN F1.F1."CONSTRUCTORS" con  ON cr."constructor_id" = con."constructor_id"
WHERE dr."rn" = 1
  AND cr."rn" = 1
ORDER BY dr."year";