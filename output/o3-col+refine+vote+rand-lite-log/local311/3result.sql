WITH last_races AS (
    SELECT year,
           MAX(round) AS last_round
    FROM   races
    GROUP  BY year
),
constructor_points AS (
    SELECT r.year,
           cs.constructor_id,
           cs.points AS constructor_points
    FROM   constructor_standings cs
    JOIN   races r      ON r.race_id = cs.race_id
    JOIN   last_races lr ON lr.year = r.year
                        AND lr.last_round = r.round
),
driver_points AS (
    SELECT r.year,
           ds.driver_id,
           ds.points AS driver_points,
           ds.race_id
    FROM   driver_standings ds
    JOIN   races r      ON r.race_id = ds.race_id
    JOIN   last_races lr ON lr.year = r.year
                        AND lr.last_round = r.round
),
best_driver AS (
    SELECT dp.year,
           res.constructor_id,
           MAX(dp.driver_points) AS best_driver_points
    FROM   driver_points dp
    JOIN   results res
           ON  res.race_id  = dp.race_id
           AND res.driver_id = dp.driver_id
    GROUP  BY dp.year, res.constructor_id
),
combined AS (
    SELECT cp.year,
           cp.constructor_id,
           cp.constructor_points + bd.best_driver_points AS combined_points
    FROM   constructor_points cp
    JOIN   best_driver bd
           ON  bd.year = cp.year
           AND bd.constructor_id = cp.constructor_id
)
SELECT c.name AS constructor_name,
       cmb.year,
       cmb.combined_points
FROM   combined cmb
JOIN   constructors c ON c.constructor_id = cmb.constructor_id
ORDER  BY cmb.combined_points DESC
LIMIT 3;