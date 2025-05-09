WITH driver_totals AS (
    /*  total points per driver & season */
    SELECT
        r."year",
        ds."driver_id",
        MAX(ds."points")      AS "driver_points"
    FROM F1.F1."DRIVER_STANDINGS" ds
    JOIN F1.F1."RACES"       r  ON r."race_id" = ds."race_id"
    GROUP BY r."year", ds."driver_id"
),
top_driver_per_year AS (
    /*  pick the single best-scoring driver each season */
    SELECT
        dt.*,
        ROW_NUMBER() OVER (PARTITION BY dt."year"
                           ORDER BY dt."driver_points" DESC NULLS LAST) AS rn
    FROM driver_totals dt
    QUALIFY rn = 1
),
constructor_totals AS (
    /*  total points per constructor & season */
    SELECT
        r."year",
        cs."constructor_id",
        MAX(cs."points")      AS "constructor_points"
    FROM F1.F1."CONSTRUCTOR_STANDINGS" cs
    JOIN F1.F1."RACES"       r  ON r."race_id" = cs."race_id"
    GROUP BY r."year", cs."constructor_id"
),
top_constructor_per_year AS (
    /*  pick the single best-scoring constructor each season */
    SELECT
        ct.*,
        ROW_NUMBER() OVER (PARTITION BY ct."year"
                           ORDER BY ct."constructor_points" DESC NULLS LAST) AS rn
    FROM constructor_totals ct
    QUALIFY rn = 1
)
SELECT
    td."year",
    d."full_name"                 AS "driver_full_name",
    td."driver_points",
    c."name"                      AS "constructor_name",
    tc."constructor_points"
FROM top_driver_per_year      td
JOIN F1.F1."DRIVERS"          d   ON d."driver_id"      = td."driver_id"
JOIN top_constructor_per_year tc  ON tc."year"          = td."year"
JOIN F1.F1."CONSTRUCTORS"     c   ON c."constructor_id" = tc."constructor_id"
ORDER BY td."year" DESC NULLS LAST;