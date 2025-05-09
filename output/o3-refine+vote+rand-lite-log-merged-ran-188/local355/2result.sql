WITH driver_results AS (
    SELECT DISTINCT
           res.driver_id,
           ra.year,
           ra.round,
           res.constructor_id
    FROM results AS res
    JOIN races   AS ra ON ra.race_id = res.race_id
),
gaps AS (
    /* locate every hiatus of 1‑2 consecutive races,
       sandwiched by two participations with different constructors */
    SELECT
           prev.driver_id,
           prev.year,
           prev.round                       AS prev_round,
           nxt.round                        AS next_round,
           nxt.round - prev.round - 1       AS gap_size
    FROM driver_results AS prev
    JOIN driver_results AS nxt
         ON nxt.driver_id = prev.driver_id
        AND nxt.year      = prev.year
        AND nxt.round     > prev.round
        AND nxt.round - prev.round - 1 BETWEEN 1 AND 2      -- missed < 3 races
        AND nxt.constructor_id <> prev.constructor_id       -- team switch
    /* be sure the driver really missed those rounds */
    WHERE NOT EXISTS (
              SELECT 1
              FROM races   AS mid_ra
              JOIN results AS mid_re
                   ON mid_re.race_id  = mid_ra.race_id
                  AND mid_re.driver_id = prev.driver_id
              WHERE mid_ra.year  = prev.year
                AND mid_ra.round > prev.round
                AND mid_ra.round < nxt.round
          )
)
SELECT
       AVG(prev_round + 1) AS avg_first_missed_round,
       AVG(next_round - 1) AS avg_last_missed_round
FROM gaps;