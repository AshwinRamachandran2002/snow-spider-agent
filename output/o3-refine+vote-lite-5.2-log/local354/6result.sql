WITH results_50s AS (          -- all race results in the 1950‑1959 decade
    SELECT ra.year,
           ra.round,
           res.driver_id,
           res.constructor_id
    FROM results   res
    JOIN races     ra ON ra.race_id = res.race_id
    WHERE ra.year BETWEEN 1950 AND 1959
),
per_driver_year AS (           -- summary of every driver‑season in the decade
    SELECT year,
           driver_id,
           MIN(round) AS first_round,
           MAX(round) AS last_round,
           COUNT(DISTINCT round) AS race_count
    FROM results_50s
    GROUP BY year, driver_id
),
first_constructor AS (         -- constructor in driver’s first race of the season
    SELECT p.year,
           p.driver_id,
           r.constructor_id AS first_constructor_id
    FROM per_driver_year p
    JOIN results_50s   r
         ON r.year = p.year
        AND r.driver_id = p.driver_id
        AND r.round = p.first_round
),
last_constructor AS (          -- constructor in driver’s last race of the season
    SELECT p.year,
           p.driver_id,
           r.constructor_id AS last_constructor_id
    FROM per_driver_year p
    JOIN results_50s   r
         ON r.year = p.year
        AND r.driver_id = p.driver_id
        AND r.round = p.last_round
),
qualified_seasons AS (         -- seasons that meet all requested conditions
    SELECT p.year,
           p.driver_id
    FROM per_driver_year  p
    JOIN first_constructor fc ON fc.year = p.year AND fc.driver_id = p.driver_id
    JOIN last_constructor  lc ON lc.year = p.year AND lc.driver_id = p.driver_id
    WHERE p.race_count >= 2
      AND fc.first_constructor_id = lc.last_constructor_id
)
SELECT DISTINCT d.driver_id,
       d.forename || ' ' || d.surname AS driver_name
FROM qualified_seasons qs
JOIN drivers d ON d.driver_id = qs.driver_id
ORDER BY driver_name;