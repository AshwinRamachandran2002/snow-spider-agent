WITH driver_year_participations AS (
    SELECT 
        r.driver_id,
        ra.year,
        ra.round,
        r.constructor_id
    FROM results r
    JOIN races ra ON ra.race_id = r.race_id
),
gaps AS (
    SELECT
        driver_id,
        year,
        round                                            AS prev_round,
        constructor_id                                   AS prev_constructor_id,
        LEAD(round)          OVER (PARTITION BY driver_id, year ORDER BY round) AS next_round,
        LEAD(constructor_id) OVER (PARTITION BY driver_id, year ORDER BY round) AS next_constructor_id
    FROM driver_year_participations
),
qualified_gaps AS (
    SELECT
        driver_id,
        year,
        prev_round + 1 AS first_missed_round,
        next_round - 1 AS last_missed_round
    FROM gaps
    WHERE next_round IS NOT NULL
      AND (next_round - prev_round - 1) BETWEEN 1 AND 2      -- missed < 3 races
      AND prev_constructor_id <> next_constructor_id         -- switched teams
)
SELECT 
    AVG(first_missed_round) AS avg_first_missed_round,
    AVG(last_missed_round)  AS avg_last_missed_round
FROM qualified_gaps;