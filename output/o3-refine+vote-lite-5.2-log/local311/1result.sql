WITH final_races AS (
    -- round with the highest number in every season = last GP of the year
    SELECT year, MAX(round) AS max_round
    FROM races
    GROUP BY year
),
final_race_ids AS (
    SELECT r.year, r.race_id
    FROM races r
    JOIN final_races fr
      ON r.year = fr.year
     AND r.round = fr.max_round
),
-- points the constructor finished the season with
constructor_points AS (
    SELECT fr.year,
           cs.constructor_id,
           cs.points AS constructor_points
    FROM constructor_standings cs
    JOIN final_race_ids fr
      ON cs.race_id = fr.race_id
),
-- associate every driver’s final‑standing points with the constructor
-- they were driving for in that last race of the season
driver_points AS (
    SELECT fr.year,
           res.constructor_id,
           ds.points AS driver_points
    FROM driver_standings ds
    JOIN final_race_ids fr
      ON ds.race_id = fr.race_id
    JOIN results res
      ON res.race_id = ds.race_id
     AND res.driver_id = ds.driver_id
),
-- best (highest‑scoring) driver per constructor in each season
best_driver_per_constructor AS (
    SELECT year,
           constructor_id,
           MAX(driver_points) AS best_driver_points
    FROM driver_points
    GROUP BY year, constructor_id
),
-- add constructor points and best‑driver points
combined AS (
    SELECT cp.year,
           cp.constructor_id,
           (cp.constructor_points + COALESCE(bd.best_driver_points,0)) AS combined_points
    FROM constructor_points cp
    LEFT JOIN best_driver_per_constructor bd
      ON bd.year = cp.year
     AND bd.constructor_id = cp.constructor_id
)
-- top‑3 constructor‑season combinations by that combined total
SELECT c.name        AS constructor,
       combined.year AS season_year,
       combined.combined_points
FROM combined
JOIN constructors c
  ON c.constructor_id = combined.constructor_id
ORDER BY combined.combined_points DESC,
         c.name
LIMIT 3;