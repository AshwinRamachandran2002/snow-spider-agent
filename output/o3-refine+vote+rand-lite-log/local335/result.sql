WITH final_race_per_season AS (
    SELECT year,
           MAX(round) AS max_round
    FROM races
    WHERE year >= 2001
    GROUP BY year
),
final_driver_standings AS (
    SELECT r.year,
           ds.driver_id,
           ds.points
    FROM final_race_per_season fr
    JOIN races r
         ON r.year  = fr.year
        AND r.round = fr.max_round
    JOIN driver_standings ds
         ON ds.race_id = r.race_id
),
min_points_per_season AS (
    SELECT year,
           MIN(points) AS min_points
    FROM final_driver_standings
    WHERE points > 0
    GROUP BY year
),
worst_point_drivers AS (
    SELECT fds.year,
           fds.driver_id,
           fds.points
    FROM final_driver_standings fds
    JOIN min_points_per_season mp
      ON mp.year = fds.year
     AND mp.min_points = fds.points
),
driver_constructor_points AS (
    SELECT r.year,
           res.driver_id,
           res.constructor_id,
           SUM(res.points) AS points_for_constructor
    FROM results res
    JOIN races r
      ON r.race_id = res.race_id
    WHERE r.year >= 2001
    GROUP BY r.year,
             res.driver_id,
             res.constructor_id
),
primary_constructor AS (
    SELECT year,
           driver_id,
           constructor_id
    FROM (
        SELECT dcp.*,
               ROW_NUMBER() OVER (
                   PARTITION BY year, driver_id
                   ORDER BY points_for_constructor DESC, constructor_id
               ) AS rn
        FROM driver_constructor_points dcp
    )
    WHERE rn = 1
),
worst_constructors_per_season AS (
    -- deduplicate in case several of their drivers share the minimum
    SELECT DISTINCT wpd.year,
           pc.constructor_id
    FROM worst_point_drivers wpd
    JOIN primary_constructor pc
      ON pc.year      = wpd.year
     AND pc.driver_id = wpd.driver_id
),
constructor_counts AS (
    SELECT constructor_id,
           COUNT(*) AS seasons_with_fewest_points_driver
    FROM worst_constructors_per_season
    GROUP BY constructor_id
)
SELECT c.name  AS constructor_name,
       constructor_counts.seasons_with_fewest_points_driver
FROM constructor_counts
JOIN constructors c
  ON c.constructor_id = constructor_counts.constructor_id
ORDER BY constructor_counts.seasons_with_fewest_points_driver DESC,
         c.name
LIMIT 5;