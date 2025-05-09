WITH final_races AS (
    SELECT
        year,
        MAX(round) AS max_round
    FROM races
    GROUP BY year
),
final_race_ids AS (
    SELECT
        r.year,
        r.race_id
    FROM races r
    JOIN final_races fr
      ON fr.year = r.year
     AND fr.max_round = r.round
),
constructor_points AS (
    SELECT
        fr.year,
        cs.constructor_id,
        cs.points AS constructor_points
    FROM constructor_standings cs
    JOIN final_race_ids fr
      ON fr.race_id = cs.race_id
),
driver_points AS (
    SELECT
        fr.year,
        res.constructor_id,
        ds.driver_id,
        ds.points AS driver_points
    FROM driver_standings ds
    JOIN final_race_ids fr
      ON fr.race_id = ds.race_id
    JOIN results res
      ON res.race_id = ds.race_id
     AND res.driver_id = ds.driver_id
),
best_driver_points AS (
    SELECT
        year,
        constructor_id,
        MAX(driver_points) AS best_driver_points
    FROM driver_points
    GROUP BY year, constructor_id
),
combined AS (
    SELECT
        cp.year,
        cp.constructor_id,
        cp.constructor_points + COALESCE(bdp.best_driver_points, 0) AS combined_points
    FROM constructor_points cp
    LEFT JOIN best_driver_points bdp
           ON bdp.year = cp.year
          AND bdp.constructor_id = cp.constructor_id
)
SELECT
    c.name  AS constructor,
    combined.year,
    combined.combined_points
FROM combined
JOIN constructors c
  ON c.constructor_id = combined.constructor_id
ORDER BY combined.combined_points DESC,
         c.name
LIMIT 3;