WITH driver_totals AS (
    SELECT
        r."year",
        d."full_name"                AS "top_driver",
        SUM(ds."points")             AS "driver_points",
        ROW_NUMBER() OVER (
            PARTITION BY r."year"
            ORDER BY SUM(ds."points") DESC, d."full_name"
        )                            AS "rn"
    FROM "driver_standings" AS ds
    JOIN "races"            AS r ON r."race_id"  = ds."race_id"
    JOIN "drivers_ext"      AS d ON d."driver_id" = ds."driver_id"
    GROUP BY r."year", ds."driver_id"
),
constructor_totals AS (
    SELECT
        r."year",
        c."name"                     AS "top_constructor",
        SUM(cs."points")             AS "constructor_points",
        ROW_NUMBER() OVER (
            PARTITION BY r."year"
            ORDER BY SUM(cs."points") DESC, c."name"
        )                            AS "rn"
    FROM "constructor_standings" AS cs
    JOIN "races"                 AS r ON r."race_id"       = cs."race_id"
    JOIN "constructors"          AS c ON c."constructor_id" = cs."constructor_id"
    GROUP BY r."year", cs."constructor_id"
)
SELECT
    dt."year",
    dt."top_driver",
    ct."top_constructor"
FROM   driver_totals      AS dt
JOIN   constructor_totals AS ct ON ct."year" = dt."year"
WHERE  dt."rn" = 1
  AND  ct."rn" = 1
ORDER  BY dt."year";