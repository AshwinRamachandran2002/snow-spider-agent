WITH participation AS (
    SELECT
        r."driver_id",
        ra."year",
        ra."round",
        r."constructor_id"
    FROM F1.F1."RESULTS"           r
    JOIN F1.F1."RACES"             ra  ON ra."race_id" = r."race_id"
    WHERE ra."year" BETWEEN 1950 AND 1959
), first_last_stats AS (
    SELECT
        p."driver_id",
        p."year",
        /* constructor used in the driver’s first race of the season */
        FIRST_VALUE(p."constructor_id") OVER (
            PARTITION BY p."driver_id", p."year"
            ORDER BY p."round" ASC
        ) AS "first_constructor_id",
        /* constructor used in the driver’s last race of the season */
        FIRST_VALUE(p."constructor_id") OVER (
            PARTITION BY p."driver_id", p."year"
            ORDER BY p."round" DESC
        ) AS "last_constructor_id",
        /* number of different race rounds the driver entered that season */
        COUNT(DISTINCT p."round") OVER (
            PARTITION BY p."driver_id", p."year"
        ) AS "race_rounds_cnt"
    FROM participation p
)
SELECT DISTINCT
    d."full_name"         AS "driver_name",
    fls."year",
    c."name"              AS "constructor_name"
FROM first_last_stats fls
JOIN F1.F1."DRIVERS"      d ON d."driver_id"       = fls."driver_id"
JOIN F1.F1."CONSTRUCTORS" c ON c."constructor_id"  = fls."first_constructor_id"
WHERE fls."first_constructor_id" = fls."last_constructor_id"  -- same constructor in first & last race
  AND fls."race_rounds_cnt"      >= 2                          -- at least two different rounds
ORDER BY fls."year", d."full_name";