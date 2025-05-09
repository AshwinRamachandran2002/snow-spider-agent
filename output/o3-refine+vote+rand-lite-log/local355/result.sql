WITH consecutive_stints AS (
    /* consecutive pairs of stints for the same driver & season           */
    /* (the “next” stint is the first one that starts after the current)  */
    SELECT
        d1.year,
        d1.driver_id,
        d1.constructor_id               AS prev_constructor_id,
        d1.last_round,
        d2.constructor_id               AS next_constructor_id,
        d2.first_round,
        (d2.first_round - d1.last_round - 1)          AS missed_races,
        (d1.last_round + 1)                           AS first_missed_round,
        (d2.first_round - 1)                          AS last_missed_round
    FROM drives d1
    JOIN drives d2
          ON d2.driver_id = d1.driver_id
         AND d2.year      = d1.year
         AND d2.first_round > d1.last_round
    /* keep only the immediately‑following stint */
    WHERE d2.first_round = (
            SELECT MIN(d3.first_round)
            FROM drives d3
            WHERE d3.driver_id = d1.driver_id
              AND d3.year      = d1.year
              AND d3.first_round > d1.last_round
          )
)
SELECT
    AVG(first_missed_round) AS avg_first_missed_round,
    AVG(last_missed_round)  AS avg_last_missed_round
FROM consecutive_stints
WHERE missed_races BETWEEN 1 AND 2          -- missed < 3 races
  AND prev_constructor_id <> next_constructor_id;  -- team switched