WITH final_races AS (                 -- round-number of each season’s last GP (2001-present)
    SELECT year,
           MAX(round) AS final_round
    FROM races
    WHERE year >= 2001
    GROUP BY year
),
season_finale AS (                    -- race_id of every season-ending Grand Prix
    SELECT r.year,
           r.race_id
    FROM races AS r
    JOIN final_races AS f
      ON f.year = r.year
     AND f.final_round = r.round
),
min_points AS (                       -- lowest positive points scored by any driver each year
    SELECT sf.year,
           MIN(ds.points) AS min_pts
    FROM season_finale AS sf
    JOIN driver_standings AS ds
      ON ds.race_id = sf.race_id
    WHERE ds.points > 0
    GROUP BY sf.year
),
lowest_constructors AS (              -- constructors owning those minimum-point drivers
    SELECT sf.year,
           c.constructor_id,
           c.name
    FROM season_finale       AS sf
    JOIN driver_standings    AS ds
      ON ds.race_id = sf.race_id
    JOIN min_points          AS mp
      ON mp.year = sf.year
     AND mp.min_pts = ds.points
    JOIN results             AS res
      ON res.race_id  = ds.race_id
     AND res.driver_id = ds.driver_id
    JOIN constructors        AS c
      ON c.constructor_id = res.constructor_id
    GROUP BY sf.year, c.constructor_id, c.name
)
SELECT lc.name  AS constructor_name,
       COUNT(*) AS seasons_with_lowest_point_scorer
FROM lowest_constructors AS lc
GROUP BY lc.constructor_id, lc.name
ORDER BY seasons_with_lowest_point_scorer DESC
LIMIT 5;