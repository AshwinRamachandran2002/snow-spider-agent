WITH driver_season_points AS (
    SELECT r.year,
           res.driver_id,
           SUM(res.points) AS total_points
    FROM results res
    JOIN races  r ON r.race_id = res.race_id
    WHERE r.year >= 2001
    GROUP BY r.year, res.driver_id
    HAVING total_points > 0
),
min_points_per_season AS (
    SELECT year,
           MIN(total_points) AS min_points
    FROM driver_season_points
    GROUP BY year
),
lowest_scoring_drivers AS (
    SELECT dsp.year,
           dsp.driver_id
    FROM driver_season_points dsp
    JOIN min_points_per_season mps
      ON mps.year = dsp.year
     AND mps.min_points = dsp.total_points
),
driver_constructor_points AS (
    SELECT r.year,
           res.driver_id,
           res.constructor_id,
           SUM(res.points) AS constructor_points
    FROM results res
    JOIN races  r ON r.race_id = res.race_id
    WHERE r.year >= 2001
    GROUP BY r.year, res.driver_id, res.constructor_id
),
preferred_constructor AS (
    SELECT dcp.*,
           MAX(constructor_points) OVER (PARTITION BY year, driver_id) AS max_points_for_driver
    FROM driver_constructor_points dcp
),
lowest_constructor_per_season AS (
    SELECT lsd.year,
           pc.constructor_id
    FROM lowest_scoring_drivers lsd
    JOIN preferred_constructor pc
      ON pc.year      = lsd.year
     AND pc.driver_id = lsd.driver_id
     AND pc.constructor_points = pc.max_points_for_driver
)
SELECT c.name AS constructor,
       COUNT(DISTINCT lcps.year) AS seasons_with_lowest_point_scorer
FROM lowest_constructor_per_season lcps
JOIN constructors c ON c.constructor_id = lcps.constructor_id
GROUP BY lcps.constructor_id
ORDER BY seasons_with_lowest_point_scorer DESC,
         constructor
LIMIT 5;