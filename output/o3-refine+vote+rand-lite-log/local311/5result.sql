WITH last_race_per_year AS (               -- last GP of every season
    SELECT year,
           MAX(round) AS last_round
    FROM races
    GROUP BY year
),
final_races AS (                            -- race_id of those last GPs
    SELECT r.race_id,
           r.year
    FROM races r
    JOIN last_race_per_year l
      ON r.year  = l.year
     AND r.round = l.last_round
),
constructor_points AS (                     -- constructors’ season totals
    SELECT cs.constructor_id,
           fr.year,
           cs.points AS constructor_points
    FROM constructor_standings cs
    JOIN final_races fr
      ON cs.race_id = fr.race_id
),
driver_points AS (                          -- drivers’ season totals with team
    SELECT ds.driver_id,
           res.constructor_id,
           fr.year,
           ds.points AS driver_points
    FROM driver_standings ds
    JOIN final_races fr
      ON ds.race_id = fr.race_id
    JOIN results res
      ON res.race_id = ds.race_id
     AND res.driver_id = ds.driver_id
),
best_driver_per_constructor AS (            -- best driver for each team/year
    SELECT constructor_id,
           year,
           MAX(driver_points) AS best_driver_points
    FROM driver_points
    GROUP BY constructor_id, year
),
combined_points AS (                        -- combine team & best‑driver pts
    SELECT cp.constructor_id,
           cp.year,
           cp.constructor_points + bd.best_driver_points AS combined_points
    FROM constructor_points cp
    JOIN best_driver_per_constructor bd
      ON cp.constructor_id = bd.constructor_id
     AND cp.year          = bd.year
),
ranked AS (                                 -- rank by combined points
    SELECT constructor_id,
           year,
           combined_points,
           RANK() OVER (ORDER BY combined_points DESC) AS rk
    FROM combined_points
)
SELECT c.name  AS constructor_name,
       r.year,
       ROUND(r.combined_points,4) AS combined_points
FROM ranked r
JOIN constructors c ON c.constructor_id = r.constructor_id
WHERE r.rk <= 3                               -- top 3
ORDER BY r.combined_points DESC, constructor_name;