WITH final_races AS (
    -- last (highest-round) race of every season
    SELECT r.year, r.race_id
    FROM races AS r
    JOIN (
        SELECT year, MAX(round) AS max_round
        FROM races
        GROUP BY year
    ) AS fr
      ON r.year = fr.year
     AND r.round = fr.max_round
),
team_points AS (
    -- constructors’ points at the season-ending race
    SELECT fr.year,
           cs.constructor_id,
           cs.points AS constructor_points
    FROM final_races AS fr
    JOIN constructor_standings AS cs
      ON cs.race_id = fr.race_id
),
driver_points AS (
    -- drivers’ points (linked to their constructor) at the same race
    SELECT fr.year,
           res.constructor_id,
           ds.points
    FROM final_races AS fr
    JOIN driver_standings AS ds
      ON ds.race_id = fr.race_id
    JOIN results AS res
      ON res.race_id = ds.race_id
     AND res.driver_id = ds.driver_id
),
best_driver_points AS (
    -- best (maximum) driver points per constructor & season
    SELECT year,
           constructor_id,
           MAX(points) AS best_driver_points
    FROM driver_points
    GROUP BY year, constructor_id
),
combined AS (
    -- add constructor points and best driver points
    SELECT tp.year,
           tp.constructor_id,
           tp.constructor_points + bdp.best_driver_points AS combined_points
    FROM team_points AS tp
    JOIN best_driver_points AS bdp
      ON bdp.year = tp.year
     AND bdp.constructor_id = tp.constructor_id
)
-- top-3 combined totals with constructor names & season
SELECT cstr.name       AS constructor,
       cmb.year,
       cmb.combined_points
FROM combined AS cmb
JOIN constructors AS cstr
  ON cstr.constructor_id = cmb.constructor_id
ORDER BY cmb.combined_points DESC
LIMIT 3;