WITH driver_year_points AS (    -- total points each driver scored in a season (since 2001)
    SELECT 
        r."year"                     AS "season_year",
        res."driver_id",
        SUM(res."points")            AS "total_points"
    FROM F1.F1.RESULTS            res
    JOIN F1.F1.RACES              r
          ON res."race_id" = r."race_id"
    WHERE r."year" >= 2001
    GROUP BY r."year", res."driver_id"
),

point_scoring_drivers AS (       -- keep only drivers that actually scored points (>0)
    SELECT *
    FROM driver_year_points
    WHERE "total_points" > 0
),

min_points_per_year AS (         -- minimum points total among point-scoring drivers each season
    SELECT 
        "season_year",
        MIN("total_points") AS "min_points"
    FROM point_scoring_drivers
    GROUP BY "season_year"
),

lowest_point_drivers AS (        -- drivers who had that minimum total in their season
    SELECT 
        d."season_year",
        d."driver_id"
    FROM point_scoring_drivers d
    JOIN min_points_per_year m
          ON  d."season_year"  = m."season_year"
         AND d."total_points"  = m."min_points"
),

driver_constructors AS (         -- constructors those lowest-point drivers raced for that season
    SELECT DISTINCT
        l."season_year",
        res."constructor_id"
    FROM lowest_point_drivers l
    JOIN F1.F1.RESULTS        res   ON l."driver_id" = res."driver_id"
    JOIN F1.F1.RACES          r     ON res."race_id" = r."race_id"
                                   AND r."year"      = l."season_year"
),

constructor_season_counts AS (   -- how many seasons each constructor supplied a lowest-point driver
    SELECT
        "constructor_id",
        COUNT(DISTINCT "season_year") AS "seasons_with_lowest_point_driver"
    FROM driver_constructors
    GROUP BY "constructor_id"
),

top5 AS (                        -- five constructors with the most such seasons
    SELECT *
    FROM constructor_season_counts
    ORDER BY "seasons_with_lowest_point_driver" DESC NULLS LAST, "constructor_id"
    LIMIT 5
)

SELECT 
    COALESCE(ce."short_name", c."name") AS "constructor_name",
    c."constructor_ref",
    t."seasons_with_lowest_point_driver" AS "seasons_as_lowest_point_team"
FROM top5                       t
JOIN F1.F1.CONSTRUCTORS        c  ON t."constructor_id" = c."constructor_id"
LEFT JOIN F1.F1.CONSTRUCTORS_EXT ce ON t."constructor_id" = ce."constructor_id"
ORDER BY t."seasons_with_lowest_point_driver" DESC NULLS LAST, "constructor_name";