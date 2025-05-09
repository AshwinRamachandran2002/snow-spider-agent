WITH best_driver AS (
    SELECT 
        r.year,
        res.constructor_id,
        MAX(ds.points) AS best_driver_pts
    FROM driver_standings AS ds
    JOIN results AS res
      ON res.race_id = ds.race_id
     AND res.driver_id = ds.driver_id
    JOIN races AS r
      ON r.race_id = ds.race_id
    GROUP BY r.year, res.constructor_id
),
team_points AS (
    SELECT
        r.year,
        cs.constructor_id,
        MAX(cs.points) AS team_pts
    FROM constructor_standings AS cs
    JOIN races AS r
      ON r.race_id = cs.race_id
    GROUP BY r.year, cs.constructor_id
),
combined AS (
    SELECT 
        bd.year,
        bd.constructor_id,
        bd.best_driver_pts + tp.team_pts AS combined_points
    FROM best_driver AS bd
    JOIN team_points AS tp
      ON tp.year = bd.year
     AND tp.constructor_id = bd.constructor_id
)
SELECT 
    c.name AS constructor,
    comb.year,
    ROUND(comb.combined_points, 4) AS combined_points
FROM combined AS comb
JOIN constructors AS c 
  ON c.constructor_id = comb.constructor_id
ORDER BY comb.combined_points DESC,
         comb.year DESC,
         constructor
LIMIT 3;