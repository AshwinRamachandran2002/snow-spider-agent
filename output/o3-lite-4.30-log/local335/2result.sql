WITH driver_totals AS (
    SELECT r.year,
           res.driver_id,
           SUM(res.points) AS driver_pts
    FROM results AS res
    JOIN races  AS r ON r.race_id = res.race_id
    WHERE r.year >= 2001
    GROUP BY r.year, res.driver_id
    HAVING SUM(res.points) > 0
),
year_mins AS (
    SELECT year,
           MIN(driver_pts) AS min_pts
    FROM driver_totals
    GROUP BY year
),
min_drivers AS (
    SELECT dt.year,
           dt.driver_id
    FROM driver_totals dt
    JOIN year_mins ym
      ON dt.year = ym.year
     AND dt.driver_pts = ym.min_pts
),
main_team AS (
    SELECT r.year,
           res.driver_id,
           res.constructor_id,
           ROW_NUMBER() OVER (
               PARTITION BY r.year, res.driver_id
               ORDER BY SUM(res.points) DESC
           ) AS rn
    FROM results AS res
    JOIN races  AS r ON r.race_id = res.race_id
    WHERE r.year >= 2001
    GROUP BY r.year, res.driver_id, res.constructor_id
)
SELECT c.name AS constructor,
       COUNT(*) AS seasons_with_lowest_point_scorer
FROM min_drivers md
JOIN main_team   mt ON mt.year = md.year
                   AND mt.driver_id = md.driver_id
                   AND mt.rn = 1
JOIN constructors c ON c.constructor_id = mt.constructor_id
GROUP BY c.name
ORDER BY seasons_with_lowest_point_scorer DESC,
         constructor
LIMIT 5;