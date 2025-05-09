WITH raced_50s AS (
    SELECT r.year,
           r.round,
           res.driver_id,
           res.constructor_id
    FROM results AS res
    JOIN races   AS r  ON r.race_id = res.race_id
    WHERE r.year BETWEEN 1950 AND 1959
),
season_stats AS (
    SELECT year,
           driver_id,
           MIN(round) AS first_round,
           MAX(round) AS last_round,
           COUNT(DISTINCT round) AS rounds_cnt
    FROM raced_50s
    GROUP BY year, driver_id
),
first_constructor AS (
    SELECT s.year,
           s.driver_id,
           rf.constructor_id AS first_constructor_id
    FROM season_stats AS s
    JOIN raced_50s   AS rf
         ON rf.year = s.year
        AND rf.driver_id = s.driver_id
        AND rf.round = s.first_round
),
last_constructor AS (
    SELECT s.year,
           s.driver_id,
           rl.constructor_id AS last_constructor_id
    FROM season_stats AS s
    JOIN raced_50s   AS rl
         ON rl.year = s.year
        AND rl.driver_id = s.driver_id
        AND rl.round = s.last_round
),
qualified_seasons AS (
    SELECT s.year,
           s.driver_id
    FROM season_stats      AS s
    JOIN first_constructor AS fc
         ON fc.year = s.year AND fc.driver_id = s.driver_id
    JOIN last_constructor  AS lc
         ON lc.year = s.year AND lc.driver_id = s.driver_id
    WHERE s.rounds_cnt >= 2
      AND fc.first_constructor_id = lc.last_constructor_id
)
SELECT DISTINCT d.driver_id,
       d.full_name
FROM qualified_seasons AS qs
JOIN drivers_ext      AS d  ON d.driver_id = qs.driver_id
ORDER BY d.full_name;