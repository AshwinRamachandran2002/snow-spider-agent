WITH team_points AS (
    SELECT 
        ra.year,
        r.constructor_id,
        SUM(r.points) AS team_points
    FROM results r
    JOIN races ra ON ra.race_id = r.race_id
    GROUP BY ra.year, r.constructor_id
),
driver_points AS (
    SELECT
        ra.year,
        r.constructor_id,
        r.driver_id,
        SUM(r.points) AS driver_points
    FROM results r
    JOIN races ra ON ra.race_id = r.race_id
    GROUP BY ra.year, r.constructor_id, r.driver_id
),
best_driver AS (
    SELECT
        year,
        constructor_id,
        MAX(driver_points) AS best_driver_points
    FROM driver_points
    GROUP BY year, constructor_id
),
combined AS (
    SELECT
        tp.year,
        tp.constructor_id,
        tp.team_points,
        bd.best_driver_points,
        (tp.team_points + bd.best_driver_points) AS combined_points
    FROM team_points tp
    JOIN best_driver bd
      ON tp.year = bd.year 
     AND tp.constructor_id = bd.constructor_id
)
SELECT
    c.name  AS constructor_name,
    combined.year,
    ROUND(combined.combined_points,4) AS combined_points
FROM combined
JOIN constructors c ON c.constructor_id = combined.constructor_id
ORDER BY combined.combined_points DESC, constructor_name
LIMIT 3;