WITH final_races_per_year AS (
    SELECT "year",
           MAX("race_id") AS race_id              -- last GP of every season
    FROM   races
    WHERE  "year" >= 2001
    GROUP  BY "year"
),
season_driver_points AS (                         -- points of every driver (who scored)
    SELECT fr."year",
           ds.driver_id,
           ds.points
    FROM   driver_standings   ds
    JOIN   final_races_per_year fr
           ON fr.race_id = ds.race_id
    WHERE  ds.points > 0
),
min_points_per_year AS (                          -- minimum points scored by any point‑scorer
    SELECT "year",
           MIN(points) AS min_pts
    FROM   season_driver_points
    GROUP  BY "year"
),
drivers_with_min AS (                             -- drivers who had that minimum
    SELECT sdp."year",
           sdp.driver_id
    FROM   season_driver_points sdp
    JOIN   min_points_per_year mp
           ON mp."year" = sdp."year"
          AND mp.min_pts = sdp.points
),
driver_constructor AS (                           -- constructor for those drivers
    SELECT DISTINCT
           d."year",
           COALESCE(dr.constructor_id,
                    r.constructor_id) AS constructor_id
    FROM   drivers_with_min d
    LEFT   JOIN drives dr                          -- first registered drive for that season
           ON dr."year" = d."year"
          AND dr.driver_id = d.driver_id
          AND dr.is_first_drive_of_season = 1
    LEFT   JOIN final_races_per_year fr
           ON fr."year" = d."year"
    LEFT   JOIN results r                          -- fallback: constructor in last race
           ON r.race_id  = fr.race_id
          AND r.driver_id = d.driver_id
    WHERE  COALESCE(dr.constructor_id, r.constructor_id) IS NOT NULL
),
constructor_season_counts AS (                    -- how many such seasons per constructor
    SELECT constructor_id,
           COUNT(DISTINCT "year") AS season_count
    FROM   driver_constructor
    GROUP  BY constructor_id
)
SELECT c.name        AS constructor,
       csc.season_count
FROM   constructor_season_counts csc
JOIN   constructors c
       ON c.constructor_id = csc.constructor_id
ORDER  BY csc.season_count DESC,
          c.name
LIMIT  5;