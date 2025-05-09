WITH driver_points AS (   -- total points per driver per season (since 2001)
    SELECT 
        r."driver_id",
        ra."year",
        SUM(r."points")          AS total_points
    FROM F1.F1."RESULTS" r
    JOIN F1.F1."RACES"  ra  ON ra."race_id" = r."race_id"
    WHERE ra."year" >= 2001
    GROUP BY r."driver_id", ra."year"
),
point_scorers AS (        -- keep only drivers who scored >0 points
    SELECT *
    FROM driver_points
    WHERE total_points > 0
),
min_points_per_year AS (  -- minimum points scored by any point-scoring driver each season
    SELECT 
        "year",
        MIN(total_points) AS min_points
    FROM point_scorers
    GROUP BY "year"
),
lowest_scoring_drivers AS (   -- drivers who had that minimum
    SELECT p."driver_id",
           p."year"
    FROM point_scorers        p
    JOIN min_points_per_year  m
      ON p."year" = m."year"
     AND p.total_points = m.min_points
),
driver_constructors AS (      -- constructors each driver raced for that season
    SELECT 
        d."driver_id",
        d."year",
        d."constructor_id"
    FROM F1.F1."DRIVES" d
    WHERE d."year" >= 2001
),
lowest_constructors AS (      -- constructors that had at least one lowest-scoring driver that season
    SELECT DISTINCT 
        l."year",
        dc."constructor_id"
    FROM lowest_scoring_drivers l
    JOIN driver_constructors  dc
      ON l."driver_id" = dc."driver_id"
     AND l."year"      = dc."year"
),
constructor_counts AS (       -- how many such seasons for each constructor
    SELECT 
        "constructor_id",
        COUNT(DISTINCT "year") AS seasons_as_lowest
    FROM lowest_constructors
    GROUP BY "constructor_id"
),
named_counts AS (             -- attach a readable constructor name
    SELECT 
        COALESCE(ce."short_name", c."name") AS constructor_name,
        cc.seasons_as_lowest
    FROM constructor_counts cc
    JOIN F1.F1."CONSTRUCTORS"      c  ON c."constructor_id" = cc."constructor_id"
    LEFT JOIN F1.F1."CONSTRUCTORS_EXT" ce ON ce."constructor_id" = cc."constructor_id"
)
SELECT 
    constructor_name,
    seasons_as_lowest
FROM named_counts
ORDER BY seasons_as_lowest DESC NULLS LAST,
         constructor_name
LIMIT 5;