WITH driver_totals AS (   -- total points per driver & season
    SELECT
        r."year",
        ds."driver_id",
        SUM(ds."points") AS "driver_points"
    FROM F1.F1.DRIVER_STANDINGS ds
    JOIN F1.F1.RACES            r ON r."race_id" = ds."race_id"
    GROUP BY r."year", ds."driver_id"
),
top_driver AS (            -- pick the best-scoring driver each season
    SELECT
        dt.*,
        ROW_NUMBER() OVER (PARTITION BY dt."year"
                           ORDER BY dt."driver_points" DESC NULLS LAST) AS "rn"
    FROM driver_totals dt
),
driver_champion AS (
    SELECT
        td."year",
        d."full_name"        AS "driver_full_name",
        td."driver_points"
    FROM top_driver td
    JOIN F1.F1.DRIVERS d ON d."driver_id" = td."driver_id"
    WHERE td."rn" = 1
),
constructor_totals AS (    -- total points per constructor & season
    SELECT
        r."year",
        cs."constructor_id",
        SUM(cs."points") AS "constructor_points"
    FROM F1.F1.CONSTRUCTOR_STANDINGS cs
    JOIN F1.F1.RACES                 r ON r."race_id" = cs."race_id"
    GROUP BY r."year", cs."constructor_id"
),
top_constructor AS (       -- pick the best constructor each season
    SELECT
        ct.*,
        ROW_NUMBER() OVER (PARTITION BY ct."year"
                           ORDER BY ct."constructor_points" DESC NULLS LAST) AS "rn"
    FROM constructor_totals ct
),
constructor_champion AS (
    SELECT
        tc."year",
        c."name"             AS "constructor_name",
        tc."constructor_points"
    FROM top_constructor tc
    JOIN F1.F1.CONSTRUCTORS c ON c."constructor_id" = tc."constructor_id"
    WHERE tc."rn" = 1
)
SELECT
    dch."year",
    dch."driver_full_name",
    dch."driver_points",
    cch."constructor_name",
    cch."constructor_points"
FROM driver_champion      dch
JOIN constructor_champion cch  ON dch."year" = cch."year"
ORDER BY dch."year";