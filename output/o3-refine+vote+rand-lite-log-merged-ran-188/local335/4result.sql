WITH season_last_race AS (   -- last Grand Prix of every season since 2001
    SELECT r1.year,
           r1.race_id
    FROM races r1
    WHERE r1.year >= 2001
      AND r1.round = (SELECT MAX(r2.round)
                      FROM races r2
                      WHERE r2.year = r1.year)
),
season_min_points AS (       -- fewest points scored by any point‑scoring driver that season
    SELECT slr.year,
           MIN(ds.points) AS min_points
    FROM season_last_race slr
    JOIN driver_standings ds
         ON ds.race_id = slr.race_id
    WHERE ds.points > 0                -- only drivers who scored
    GROUP BY slr.year
),
lowest_scoring_drivers AS (  -- drivers who had that minimum
    SELECT slr.year,
           ds.driver_id
    FROM season_last_race slr
    JOIN driver_standings ds
         ON ds.race_id = slr.race_id
    JOIN season_min_points smp
         ON smp.year = slr.year
        AND ds.points = smp.min_points
),
driver_constructors AS (     -- constructor for those drivers in the final race
    SELECT lsd.year,
           res.constructor_id
    FROM lowest_scoring_drivers lsd
    JOIN season_last_race slr USING (year)
    JOIN results res
         ON res.race_id = slr.race_id
        AND res.driver_id = lsd.driver_id
),
constructor_counts AS (      -- how many seasons each constructor appears here
    SELECT constructor_id,
           COUNT(DISTINCT year) AS seasons_with_lowest_scoring_driver
    FROM driver_constructors
    GROUP BY constructor_id
)
SELECT c.name  AS constructor_name,
       cc.seasons_with_lowest_scoring_driver
FROM constructor_counts cc
JOIN constructors c USING (constructor_id)
ORDER BY cc.seasons_with_lowest_scoring_driver DESC,
         constructor_name
LIMIT 5;