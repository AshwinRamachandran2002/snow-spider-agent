WITH gaps AS (
    SELECT 
        res.driver_id,
        r.year,
        LAG(r.round)  OVER (PARTITION BY res.driver_id, r.year ORDER BY r.round)        AS prev_round,
        r.round                                                                       AS next_round,
        LAG(res.constructor_id) OVER (PARTITION BY res.driver_id, r.year ORDER BY r.round) AS constructor_before,
        res.constructor_id                                                            AS constructor_after,
        r.round - LAG(r.round) OVER (PARTITION BY res.driver_id, r.year ORDER BY r.round) - 1 AS missed_races
    FROM results AS res
    JOIN races   AS r ON r.race_id = res.race_id
),
hiatuses AS (
    SELECT 
        prev_round + 1 AS first_missed_round,
        next_round - 1 AS last_missed_round
    FROM gaps
    WHERE missed_races BETWEEN 1 AND 2
      AND constructor_before IS NOT NULL
      AND constructor_after  IS NOT NULL
      AND constructor_before <> constructor_after
)
SELECT 
    ROUND(AVG(first_missed_round), 4) AS avg_first_missed_round,
    ROUND(AVG(last_missed_round), 4)  AS avg_last_missed_round
FROM hiatuses;