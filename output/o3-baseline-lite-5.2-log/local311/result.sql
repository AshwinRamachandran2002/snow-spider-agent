WITH final_races AS (
    -- find the last (final‑round) race of every season
    SELECT r1.race_id,
           r1.year
    FROM races r1
    JOIN (
        SELECT year, MAX(round) AS final_round
        FROM races
        GROUP BY year
    ) r2
      ON r1.year  = r2.year
     AND r1.round = r2.final_round
),
team_points AS (
    -- constructor (team) points after the final race of each season
    SELECT fr.year,
           cs.constructor_id,
           cs.points AS team_points
    FROM constructor_standings cs
    JOIN final_races fr
      ON fr.race_id = cs.race_id
),
driver_points AS (
    -- driver points after the final race + the constructor they drove for in that race
    SELECT fr.year,
           r.constructor_id,
           ds.driver_id,
           ds.points AS driver_points
    FROM driver_standings ds
    JOIN final_races fr
      ON fr.race_id = ds.race_id
    JOIN results r
      ON r.race_id  = ds.race_id
     AND r.driver_id = ds.driver_id
),
best_driver AS (
    -- best (highest‑scoring) driver for each constructor in each season
    SELECT year,
           constructor_id,
           MAX(driver_points) AS best_driver_points
    FROM driver_points
    GROUP BY year, constructor_id
),
combined AS (
    -- combine team points with best‑driver points
    SELECT tp.year,
           tp.constructor_id,
           tp.team_points,
           COALESCE(bd.best_driver_points, 0) AS best_driver_points,
           tp.team_points + COALESCE(bd.best_driver_points, 0) AS combined_points
    FROM team_points tp
    LEFT JOIN best_driver bd
      ON bd.year = tp.year
     AND bd.constructor_id = tp.constructor_id
),
top3 AS (
    -- keep the three highest combined totals
    SELECT *
    FROM combined
    ORDER BY combined_points DESC,
             year ASC,
             constructor_id ASC
    LIMIT 3
)
SELECT c.name        AS constructor,
       t.year,
       ROUND(t.combined_points, 4) AS combined_points
FROM top3 t
JOIN constructors c
  ON c.constructor_id = t.constructor_id
ORDER BY t.combined_points DESC,
         t.year ASC;