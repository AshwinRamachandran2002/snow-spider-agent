WITH final_races AS (                 -- last (final) race of every season
    SELECT year, MAX(round) AS final_round
    FROM races
    GROUP BY year
),
final_race_ids AS (                   -- race_id of every season’s final race
    SELECT r.year,
           r.race_id
    FROM races r
    JOIN final_races f
         ON f.year = r.year
        AND f.final_round = r.round
),
-- champion driver of each season
driver_rank AS (
    SELECT fri.year,
           ds.driver_id,
           ds.points,
           ROW_NUMBER() OVER (PARTITION BY fri.year
                              ORDER BY ds.points DESC, ds.driver_id) AS rn
    FROM driver_standings ds
    JOIN final_race_ids fri
         ON fri.race_id = ds.race_id
),
-- champion constructor of each season
constructor_rank AS (
    SELECT fri.year,
           cs.constructor_id,
           cs.points,
           ROW_NUMBER() OVER (PARTITION BY fri.year
                              ORDER BY cs.points DESC, cs.constructor_id) AS rn
    FROM constructor_standings cs
    JOIN final_race_ids fri
         ON fri.race_id = cs.race_id
)
SELECT dr.year,
       de.full_name  AS driver_full_name,
       dr.points     AS driver_points,
       c.name        AS constructor_name,
       cr.points     AS constructor_points
FROM driver_rank      dr
JOIN drivers_ext      de ON de.driver_id      = dr.driver_id
JOIN constructor_rank cr ON cr.year           = dr.year
JOIN constructors     c  ON c.constructor_id  = cr.constructor_id
WHERE dr.rn = 1                -- top‑ranked driver
  AND cr.rn = 1                -- top‑ranked constructor
ORDER BY dr.year;