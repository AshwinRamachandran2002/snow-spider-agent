WITH driver_totals AS (
    SELECT r.year,
           res.driver_id,
           SUM(res.points) AS points
    FROM results AS res
    JOIN races   AS r ON r.race_id = res.race_id
    GROUP BY r.year, res.driver_id
),
top_driver AS (
    SELECT year,
           MAX(points) AS top_driver_points
    FROM driver_totals
    GROUP BY year
),
constructor_totals AS (
    SELECT r.year,
           res.constructor_id,
           SUM(res.points) AS points
    FROM results AS res
    JOIN races   AS r ON r.race_id = res.race_id
    GROUP BY r.year, res.constructor_id
),
top_constructor AS (
    SELECT year,
           MAX(points) AS top_constructor_points
    FROM constructor_totals
    GROUP BY year
)
SELECT d.year
FROM   top_driver      AS d
JOIN   top_constructor AS c USING (year)
ORDER  BY (d.top_driver_points + c.top_constructor_points) ASC,
          d.year ASC
LIMIT 3;