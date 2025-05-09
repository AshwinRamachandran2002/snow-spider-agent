WITH final_races AS (          -- last Grand Prix of every season
    SELECT year,
           MAX(race_id) AS last_race_id
    FROM   races
    GROUP  BY year
),
team_points AS (               -- constructor-championship points in that race
    SELECT r.year,
           cs.constructor_id,
           cs.points AS team_points
    FROM   final_races        f
    JOIN   races              r  ON r.race_id = f.last_race_id
    JOIN   constructor_standings cs ON cs.race_id = r.race_id
),
best_driver AS (               -- highest-scoring driver for each team that year
    SELECT r.year,
           res.constructor_id,
           MAX(ds.points) AS best_driver_pts
    FROM   final_races  f
    JOIN   races         r   ON r.race_id = f.last_race_id
    JOIN   driver_standings ds ON ds.race_id = r.race_id
    JOIN   results       res ON res.race_id = ds.race_id
                              AND res.driver_id = ds.driver_id
    GROUP  BY r.year, res.constructor_id
),
combined AS (                  -- add the two point totals together
    SELECT tp.year,
           tp.constructor_id,
           tp.team_points + bd.best_driver_pts AS combined_pts
    FROM   team_points tp
    JOIN   best_driver bd USING (year, constructor_id)
)
SELECT c.name  AS constructor_name,
       cb.year,
       cb.combined_pts
FROM   combined     cb
JOIN   constructors c  ON c.constructor_id = cb.constructor_id
ORDER  BY cb.combined_pts DESC
LIMIT 3;