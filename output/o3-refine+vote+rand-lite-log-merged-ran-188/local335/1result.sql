WITH final_races AS (          -- last GP of every season since 2001
    SELECT  year,
            MAX(round) AS max_round
    FROM    races
    WHERE   year >= 2001
    GROUP BY year
),
final_race_ids AS (            -- race_id of that last GP
    SELECT  r.year,
            r.race_id
    FROM    races r
    JOIN    final_races f
           ON f.year = r.year
          AND f.max_round = r.round
),
season_driver_points AS (      -- season‑ending points for every driver who scored
    SELECT  fr.year,
            ds.driver_id,
            ds.points
    FROM    final_race_ids fr
    JOIN    driver_standings ds
           ON ds.race_id = fr.race_id
    WHERE   ds.points > 0
),
min_points_per_year AS (       -- smallest positive points total each season
    SELECT  year,
            MIN(points) AS min_points
    FROM    season_driver_points
    GROUP BY year
),
lowest_scoring_drivers AS (    -- drivers with that minimum
    SELECT  s.year,
            s.driver_id
    FROM    season_driver_points s
    JOIN    min_points_per_year m
           ON m.year = s.year
          AND m.min_points = s.points
),
driver_constructor AS (        -- constructor those drivers raced for in final GP
    SELECT  l.year,
            r.constructor_id
    FROM    lowest_scoring_drivers l
    JOIN    final_race_ids fr
           ON fr.year = l.year
    JOIN    results r
           ON r.race_id = fr.race_id
          AND r.driver_id = l.driver_id
),
constructor_counts AS (        -- how many seasons each constructor appears
    SELECT  constructor_id,
            COUNT(DISTINCT year) AS seasons_count
    FROM    driver_constructor
    GROUP BY constructor_id
)
SELECT      c.name   AS constructor,
            cc.seasons_count
FROM        constructor_counts cc
JOIN        constructors c
           ON c.constructor_id = cc.constructor_id
ORDER BY    cc.seasons_count DESC,
            constructor
LIMIT 5;