WITH final_races AS (            -- last round of every season (≥2001)
    SELECT "year",
           MAX("round") AS final_round
    FROM   races
    WHERE  "year" >= 2001
    GROUP  BY "year"
),
min_points_per_season AS (       -- fewest points scored by any points-scoring driver
    SELECT fr."year",
           MIN(ds.points) AS min_pts
    FROM   final_races fr
    JOIN   races            r  ON r."year" = fr."year" AND r."round" = fr.final_round
    JOIN   driver_standings ds ON ds.race_id = r.race_id
    WHERE  ds.points > 0                          -- only point-scorers
    GROUP  BY fr."year"
),
drivers_with_min_pts AS (        -- drivers who had that fewest-points total (and their constructor in the final race)
    SELECT mp."year",
           res.constructor_id
    FROM   min_points_per_season mp
    JOIN   final_races fr     ON fr."year" = mp."year"
    JOIN   races         r    ON r."year" = fr."year" AND r."round" = fr.final_round
    JOIN   driver_standings ds ON ds.race_id = r.race_id AND ds.points = mp.min_pts
    JOIN   results        res  ON res.race_id = ds.race_id
                               AND res.driver_id = ds.driver_id
),
constructor_season_counts AS (   -- how many seasons each constructor appears here
    SELECT constructor_id,
           COUNT(DISTINCT "year") AS seasons_with_min_points_driver
    FROM   drivers_with_min_pts
    GROUP  BY constructor_id
)
SELECT c.name AS constructor_name,
       csc.seasons_with_min_points_driver
FROM   constructor_season_counts csc
JOIN   constructors c ON c.constructor_id = csc.constructor_id
ORDER  BY csc.seasons_with_min_points_driver DESC,
          c.name
LIMIT 5;