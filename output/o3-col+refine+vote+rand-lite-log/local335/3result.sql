WITH last_rounds AS (
    SELECT year,
           MAX(round) AS last_round
    FROM races
    WHERE year >= 2001
    GROUP BY year
),
season_points AS (           -- points totals of every point-scoring driver
    SELECT ds.driver_id,
           r.year,
           ds.points
    FROM driver_standings AS ds
    JOIN races            AS r
      ON r.race_id = ds.race_id
    JOIN last_rounds      AS lr
      ON lr.year = r.year
     AND lr.last_round = r.round
    WHERE ds.points > 0                     -- only drivers who scored
),
min_points AS (             -- fewest points scored in each season
    SELECT year,
           MIN(points) AS min_pts
    FROM season_points
    GROUP BY year
),
bottom_drivers AS (         -- drivers with that minimum total
    SELECT sp.year,
           sp.driver_id
    FROM season_points AS sp
    JOIN min_points    AS mp
      ON mp.year = sp.year
     AND mp.min_pts = sp.points
),
bottom_constructors AS (    -- constructors those drivers raced for that year
    SELECT DISTINCT r.year,
           res.constructor_id
    FROM bottom_drivers AS bd
    JOIN results        AS res ON res.driver_id = bd.driver_id
    JOIN races          AS r   ON r.race_id   = res.race_id
    WHERE r.year = bd.year
)
SELECT ce.short_name,
       COUNT(DISTINCT bc.year) AS seasons_with_least_points_driver
FROM bottom_constructors AS bc
JOIN constructors_ext    AS ce ON ce.constructor_id = bc.constructor_id
GROUP BY ce.constructor_id
ORDER BY seasons_with_least_points_driver DESC,
         ce.short_name
LIMIT 5;