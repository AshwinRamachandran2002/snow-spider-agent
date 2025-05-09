WITH driver_points AS (
    -- total points per driver in a season (only seasons ≥ 2001 and drivers who scored)
    SELECT ra.year,
           r.driver_id,
           SUM(r.points) AS total_points
    FROM results r
    JOIN races  ra ON ra.race_id = r.race_id
    WHERE ra.year >= 2001
    GROUP BY ra.year, r.driver_id
    HAVING total_points > 0
),
year_min AS (
    -- minimum positive points scored by any driver in each season
    SELECT year,
           MIN(total_points) AS min_points
    FROM driver_points
    GROUP BY year
),
min_drivers AS (
    -- drivers who had that seasonal minimum
    SELECT dp.year,
           dp.driver_id
    FROM driver_points dp
    JOIN year_min ym
      ON ym.year = dp.year
     AND ym.min_points = dp.total_points
),
driver_constructor_points AS (
    -- points a driver scored with each constructor in a season
    SELECT ra.year,
           r.driver_id,
           r.constructor_id,
           SUM(r.points) AS points_with_constructor
    FROM results r
    JOIN races ra ON ra.race_id = r.race_id
    WHERE ra.year >= 2001
    GROUP BY ra.year, r.driver_id, r.constructor_id
),
best_constructor AS (
    -- for each (year, driver) pick the constructor they scored most points with
    SELECT dcp.year,
           dcp.driver_id,
           dcp.constructor_id
    FROM driver_constructor_points dcp
    JOIN (
        SELECT year,
               driver_id,
               MAX(points_with_constructor) AS max_pts
        FROM driver_constructor_points
        GROUP BY year, driver_id
    ) mx
      ON mx.year      = dcp.year
     AND mx.driver_id = dcp.driver_id
     AND mx.max_pts   = dcp.points_with_constructor
),
min_driver_constructors AS (
    -- constructors that had at least one “lowest‑scoring” driver in the season
    SELECT DISTINCT md.year,
           bc.constructor_id
    FROM min_drivers      md
    JOIN best_constructor bc
      ON bc.year      = md.year
     AND bc.driver_id = md.driver_id
)
SELECT c.name AS constructor_name,
       COUNT(DISTINCT mdc.year) AS seasons_with_least_scoring_driver
FROM min_driver_constructors mdc
JOIN constructors c
  ON c.constructor_id = mdc.constructor_id
GROUP BY c.constructor_id, c.name
ORDER BY seasons_with_least_scoring_driver DESC,
         constructor_name
LIMIT 5;