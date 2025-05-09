WITH driver_points AS (
    -- total points each driver scored in every season since 2001
    SELECT  r.year,
            res.driver_id,
            SUM(res.points) AS total_points
    FROM    results   res
    JOIN    races     r   ON r.race_id = res.race_id
    WHERE   r.year >= 2001
    GROUP BY r.year,
             res.driver_id
),
point_drivers AS (
    -- keep only drivers that actually scored points
    SELECT *
    FROM   driver_points
    WHERE  total_points > 0
),
per_year_min AS (
    -- minimum points scored by any point‑scoring driver each season
    SELECT  year,
            MIN(total_points) AS min_points
    FROM    point_drivers
    GROUP BY year
),
lowest_scoring_drivers AS (
    -- drivers whose season‑total equals that minimum
    SELECT  pd.year,
            pd.driver_id
    FROM    point_drivers  pd
    JOIN    per_year_min   pm
           ON pm.year = pd.year
          AND pm.min_points = pd.total_points
),
driver_constructors AS (
    -- every constructor that any driver raced for in a season
    SELECT  r.year,
            res.driver_id,
            res.constructor_id
    FROM    results  res
    JOIN    races    r  ON r.race_id = res.race_id
    WHERE   r.year >= 2001
    GROUP BY r.year,
             res.driver_id,
             res.constructor_id
),
lowest_driver_constructors AS (
    -- constructors that had at least one lowest‑scoring driver in a season
    SELECT  lsd.year,
            dc.constructor_id
    FROM    lowest_scoring_drivers lsd
    JOIN    driver_constructors dc
           ON dc.year      = lsd.year
          AND dc.driver_id = lsd.driver_id
    GROUP BY lsd.year,
             dc.constructor_id
),
constructor_season_counts AS (
    -- how many such seasons each constructor has had
    SELECT  constructor_id,
            COUNT(*) AS seasons_with_lowest
    FROM    lowest_driver_constructors
    GROUP BY constructor_id
)
SELECT  c.name  AS constructor_name,
        cs.seasons_with_lowest
FROM    constructor_season_counts cs
JOIN    constructors c
       ON c.constructor_id = cs.constructor_id
ORDER BY cs.seasons_with_lowest DESC,
         constructor_name
LIMIT 5;