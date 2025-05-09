WITH final_races AS (
    SELECT r.year,
           r.race_id
    FROM races r
    JOIN (
        SELECT year, MAX(round) AS max_round
        FROM races
        GROUP BY year
    ) f
      ON f.year = r.year
     AND f.max_round = r.round
),
team_points AS (
    SELECT fr.year,
           cs.constructor_id,
           cs.points AS team_pts
    FROM final_races fr
    JOIN constructor_standings cs
      ON cs.race_id = fr.race_id
),
best_driver_points AS (
    SELECT fr.year,
           res.constructor_id,
           MAX(ds.points) AS driver_pts
    FROM final_races fr
    JOIN results res
      ON res.race_id = fr.race_id
    JOIN driver_standings ds
      ON ds.race_id  = fr.race_id
     AND ds.driver_id = res.driver_id
    GROUP BY fr.year, res.constructor_id
),
combined AS (
    SELECT tp.year,
           tp.constructor_id,
           tp.team_pts + bdp.driver_pts AS combined_pts
    FROM team_points tp
    JOIN best_driver_points bdp
      ON bdp.year = tp.year
     AND bdp.constructor_id = tp.constructor_id
)
SELECT c.name AS constructor_name,
       combined.year,
       combined.combined_pts
FROM combined
JOIN constructors c
  ON c.constructor_id = combined.constructor_id
ORDER BY combined.combined_pts DESC
LIMIT 3;