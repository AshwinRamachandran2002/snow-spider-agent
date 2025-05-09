/*  Five constructors with the most seasons (≥ 2001) in which one of their
    drivers finished the season with the fewest points among all point-scoring
    drivers of that season                                                */

WITH driver_year_constructor_points AS (   -- points per driver/season/constructor
    SELECT
        r."driver_id",
        ra."year",
        r."constructor_id",
        SUM(r."points") AS "points"
    FROM "F1"."F1"."RESULTS"  r
    JOIN "F1"."F1"."RACES"    ra ON ra."race_id" = r."race_id"
    WHERE ra."year" >= 2001
    GROUP BY r."driver_id", ra."year", r."constructor_id"
),

driver_year_primary_constructor AS (       -- pick constructor that scored most
    SELECT *
    FROM (
        SELECT
            d.*,
            ROW_NUMBER() OVER (PARTITION BY d."driver_id", d."year"
                               ORDER BY d."points" DESC) AS rn
        FROM driver_year_constructor_points d
        WHERE d."points" > 0
    )
    WHERE rn = 1
),

driver_year_points AS (                    -- total season points per driver
    SELECT
        "driver_id",
        "year",
        SUM("points") AS total_points
    FROM driver_year_constructor_points
    WHERE "points" > 0
    GROUP BY "driver_id", "year"
),

driver_year_min AS (                       -- attach primary constructor
    SELECT
        p."driver_id",
        p."year",
        p.total_points,
        pc."constructor_id"
    FROM driver_year_points            p
    JOIN driver_year_primary_constructor pc
      ON  p."driver_id" = pc."driver_id"
      AND p."year"      = pc."year"
),

min_points_per_year AS (                   -- fewest positive points each year
    SELECT
        "year",
        MIN(total_points) AS min_points
    FROM driver_year_min
    GROUP BY "year"
),

driver_min_each_year AS (                  -- drivers who had those fewest pts
    SELECT d.*
    FROM driver_year_min d
    JOIN min_points_per_year m
      ON d."year" = m."year"
     AND d.total_points = m.min_points
),

constructor_min_counts AS (                -- seasons per constructor
    SELECT
        "constructor_id",
        COUNT(DISTINCT "year") AS seasons_with_least_point_drivers
    FROM driver_min_each_year
    GROUP BY "constructor_id"
),

constructor_names AS (                     -- readable constructor names
    SELECT
        c."constructor_id",
        COALESCE(cx."short_name", c."name") AS constructor_name
    FROM "F1"."F1"."CONSTRUCTORS"      c
    LEFT JOIN "F1"."F1"."CONSTRUCTORS_EXT" cx
           ON cx."constructor_id" = c."constructor_id"
)

SELECT
    n.constructor_name,
    c.seasons_with_least_point_drivers
FROM constructor_min_counts            c
JOIN constructor_names                 n
  ON n."constructor_id" = c."constructor_id"
ORDER BY c.seasons_with_least_point_drivers DESC NULLS LAST,
         n.constructor_name
LIMIT 5;