WITH driver_points AS (
    SELECT r.year,
           res.driver_id,
           SUM(res.points) AS driver_points
    FROM results AS res
    JOIN races   AS r ON r.race_id = res.race_id
    WHERE r.year >= 2001
    GROUP BY r.year, res.driver_id
    HAVING driver_points > 0                          -- only point-scorers
),
season_min AS (                                         -- fewest points per season
    SELECT year,
           MIN(driver_points) AS min_points
    FROM driver_points
    GROUP BY year
),
fewest_drivers AS (                                     -- drivers with that minimum
    SELECT dp.year,
           dp.driver_id
    FROM driver_points dp
    JOIN season_min  sm
      ON sm.year = dp.year
     AND sm.min_points = dp.driver_points
),
driver_primary_constructor AS (                         -- driver’s main constructor
    SELECT r.year,
           res.driver_id,
           res.constructor_id,
           ROW_NUMBER() OVER (PARTITION BY r.year, res.driver_id
                              ORDER BY SUM(res.points) DESC) AS rn
    FROM results res
    JOIN races   r ON r.race_id = res.race_id
    WHERE r.year >= 2001
    GROUP BY r.year, res.driver_id, res.constructor_id
)
SELECT c.name  AS constructor_name,
       COUNT(*) AS seasons_with_fewest_pts_driver
FROM   fewest_drivers             fd
JOIN   driver_primary_constructor dpc
  ON   dpc.year      = fd.year
 AND   dpc.driver_id = fd.driver_id
 AND   dpc.rn        = 1
JOIN   constructors  c  ON c.constructor_id = dpc.constructor_id
GROUP  BY c.constructor_id, c.name
ORDER  BY seasons_with_fewest_pts_driver DESC,
         constructor_name
LIMIT 5;