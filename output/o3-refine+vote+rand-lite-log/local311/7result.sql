WITH last_race_per_year AS (
    SELECT year,
           MAX(round) AS max_round
    FROM races
    GROUP BY year
),
-- final driver standings for each year (take the standings at the last GP)
driver_final AS (
    SELECT ds.driver_id,
           ds.points,
           r.year,
           res.constructor_id
    FROM driver_standings   ds
    JOIN races              r   ON r.race_id   = ds.race_id
    JOIN last_race_per_year lr  ON lr.year      = r.year
                               AND lr.max_round = r.round
    JOIN results            res ON res.race_id  = ds.race_id
                               AND res.driver_id = ds.driver_id
),
-- best (highest‑scoring) driver for every constructor & year
best_driver_points AS (
    SELECT year,
           constructor_id,
           MAX(points) AS driver_points
    FROM driver_final
    GROUP BY year, constructor_id
),
-- final constructor standings for each year (points after last GP)
constructor_final AS (
    SELECT cs.constructor_id,
           cs.points            AS constructor_points,
           r.year
    FROM constructor_standings cs
    JOIN races               r   ON r.race_id  = cs.race_id
    JOIN last_race_per_year  lr  ON lr.year     = r.year
                                AND lr.max_round = r.round
),
-- add the constructor points to its best driver's points
combined_points AS (
    SELECT cf.year,
           cf.constructor_id,
           cf.constructor_points + COALESCE(bd.driver_points,0) AS combined_points
    FROM constructor_final  cf
    LEFT JOIN best_driver_points bd
           ON bd.year = cf.year
          AND bd.constructor_id = cf.constructor_id
)
-- pick the three largest combined totals
SELECT c.name   AS constructor,
       cp.year,
       cp.combined_points
FROM combined_points cp
JOIN constructors c ON c.constructor_id = cp.constructor_id
ORDER BY cp.combined_points DESC,
         c.name,
         cp.year
LIMIT 3;