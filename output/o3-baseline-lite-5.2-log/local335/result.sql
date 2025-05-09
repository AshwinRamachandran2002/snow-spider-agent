WITH driver_season_points AS (
    /* total points per driver per season (only seasons >= 2001, and only if the driver scored) */
    SELECT 
        ra.year,
        re.driver_id,
        SUM(re.points) AS total_points
    FROM results          re
    JOIN races            ra ON ra.race_id = re.race_id
    WHERE ra.year >= 2001
    GROUP BY ra.year, re.driver_id
    HAVING total_points > 0
),
min_points_per_season AS (
    /* the fewest points scored by any point‑scoring driver in each season */
    SELECT 
        year,
        MIN(total_points) AS min_points
    FROM driver_season_points
    GROUP BY year
),
min_point_drivers AS (
    /* drivers who had that season‑low total */
    SELECT 
        dps.year,
        dps.driver_id
    FROM driver_season_points dps
    JOIN min_points_per_season mps
          ON mps.year = dps.year 
         AND mps.min_points = dps.total_points
),
constructor_seasons AS (
    /* constructors for whom those lowest‑scoring drivers earned points in that season */
    SELECT DISTINCT
        ra.year,
        re.constructor_id
    FROM results re
    JOIN races   ra ON ra.race_id = re.race_id
    JOIN min_point_drivers mpd
          ON mpd.year      = ra.year
         AND mpd.driver_id = re.driver_id
    WHERE re.points > 0          -- ensure it was a point‑scoring result
),
constructor_counts AS (
    /* how many such seasons per constructor */
    SELECT 
        constructor_id,
        COUNT(DISTINCT year) AS seasons_with_lowest_scoring_driver
    FROM constructor_seasons
    GROUP BY constructor_id
)
SELECT 
    c.name                         AS constructor,
    cc.seasons_with_lowest_scoring_driver
FROM constructor_counts cc
JOIN constructors       c  ON c.constructor_id = cc.constructor_id
ORDER BY cc.seasons_with_lowest_scoring_driver DESC,
         c.name
LIMIT 5;