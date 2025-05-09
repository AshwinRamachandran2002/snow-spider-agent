WITH last_race_per_year AS (          -- final race of every season
    SELECT 
        year, 
        MAX(race_id) AS last_race_id
    FROM races
    GROUP BY year
),
constructor_points AS (              -- constructor’s final season points
    SELECT 
        r.year,
        cs.constructor_id,
        cs.points AS constructor_points
    FROM constructor_standings cs
    JOIN last_race_per_year lr
          ON cs.race_id = lr.last_race_id
    JOIN races r
          ON r.race_id = cs.race_id
),
driver_points AS (                   -- points each driver scored for each constructor in a season
    SELECT
        r.year,
        res.constructor_id,
        res.driver_id,
        SUM(res.points) AS driver_points
    FROM results res
    JOIN races r
         ON r.race_id = res.race_id
    GROUP BY
        r.year,
        res.constructor_id,
        res.driver_id
),
best_driver_points AS (              -- best‑scoring driver per constructor & season
    SELECT
        year,
        constructor_id,
        MAX(driver_points) AS best_driver_points
    FROM driver_points
    GROUP BY
        year,
        constructor_id
),
combined AS (                        -- sum of best‑driver + team points
    SELECT
        cp.year,
        cp.constructor_id,
        cp.constructor_points + bd.best_driver_points AS combined_points
    FROM constructor_points cp
    JOIN best_driver_points bd
      ON cp.year = bd.year
     AND cp.constructor_id = bd.constructor_id
)
SELECT
    c.name  AS constructor,
    combined.year,
    combined.combined_points
FROM combined
JOIN constructors c
  ON c.constructor_id = combined.constructor_id
ORDER BY
    combined.combined_points DESC,
    c.name
LIMIT 3;