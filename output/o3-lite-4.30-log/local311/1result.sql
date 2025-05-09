WITH final_races AS (
    SELECT year,
           MAX(round) AS final_round
    FROM races
    GROUP BY year
),
constructor_points AS (
    SELECT r.year,
           cs.constructor_id,
           cs.points AS constructor_pts
    FROM races r
    JOIN final_races fr
         ON fr.year = r.year
        AND fr.final_round = r.round
    JOIN constructor_standings cs
         ON cs.race_id = r.race_id
),
best_driver_points AS (
    SELECT r.year,
           res.constructor_id,
           MAX(ds.points) AS driver_pts
    FROM races r
    JOIN final_races fr
         ON fr.year = r.year
        AND fr.final_round = r.round
    JOIN driver_standings ds
         ON ds.race_id = r.race_id
    JOIN results res
         ON res.race_id   = ds.race_id
        AND res.driver_id = ds.driver_id
    GROUP BY r.year, res.constructor_id
),
combined AS (
    SELECT cp.year,
           cp.constructor_id,
           cp.constructor_pts + COALESCE(bd.driver_pts,0) AS combined_points
    FROM constructor_points cp
    LEFT JOIN best_driver_points bd
           ON bd.year = cp.year
          AND bd.constructor_id = cp.constructor_id
)
SELECT c.name AS constructor,
       combined.year,
       printf('%.4f', combined.combined_points) AS combined_points
FROM combined
JOIN constructors c ON c.constructor_id = combined.constructor_id
ORDER BY combined.combined_points DESC,
         c.name,
         combined.year
LIMIT 3;