WITH driver_season_points AS (   -- total points per driver per year (only seasons ≥ 2001)
    SELECT
        r."year",
        res."driver_id",
        SUM(res."points") AS total_points
    FROM "F1"."F1"."RESULTS"  res
    JOIN "F1"."F1"."RACES"    r
      ON r."race_id" = res."race_id"
    WHERE r."year" >= 2001
    GROUP BY r."year", res."driver_id"
    HAVING SUM(res."points") > 0                   -- keep only point-scoring drivers
),
min_points_per_year AS (          -- minimum driver points per year
    SELECT
        "year",
        MIN(total_points) AS min_points
    FROM driver_season_points
    GROUP BY "year"
),
lowest_point_drivers AS (         -- drivers with the yearly minimum
    SELECT
        dsp."year",
        dsp."driver_id"
    FROM driver_season_points dsp
    JOIN min_points_per_year mp
      ON mp."year" = dsp."year"
     AND mp.min_points = dsp.total_points
),
driver_constructor_map AS (       -- driver ↔ constructor mapping per year
    SELECT DISTINCT "year", "driver_id", "constructor_id"
    FROM (
        SELECT "year", "driver_id", "constructor_id" FROM "F1"."F1"."DRIVES"
        UNION ALL
        SELECT "year", "driver_id", "constructor_id" FROM "F1"."F1"."TEAM_DRIVER_RANKS"
    )
),
constructor_lowest_count AS (     -- seasons where constructor had a lowest-scoring driver
    SELECT
        dcm."constructor_id",
        COUNT(DISTINCT lpd."year") AS seasons_with_lowest_scoring_driver
    FROM lowest_point_drivers  lpd
    JOIN driver_constructor_map dcm
      ON dcm."year"      = lpd."year"
     AND dcm."driver_id" = lpd."driver_id"
    GROUP BY dcm."constructor_id"
),
ranked AS (                       -- add constructor names
    SELECT
        c."constructor_ref"                         AS constructor_ref,
        COALESCE(ce."short_name", c."name")         AS constructor_name,
        clc.seasons_with_lowest_scoring_driver
    FROM constructor_lowest_count        clc
    JOIN "F1"."F1"."CONSTRUCTORS"        c   ON c."constructor_id" = clc."constructor_id"
    LEFT JOIN "F1"."F1"."CONSTRUCTORS_EXT" ce ON ce."constructor_id" = clc."constructor_id"
)
SELECT
    constructor_name,
    constructor_ref,
    seasons_with_lowest_scoring_driver
FROM ranked
ORDER BY seasons_with_lowest_scoring_driver DESC NULLS LAST,
         constructor_name
LIMIT 5;