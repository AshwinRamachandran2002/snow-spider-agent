WITH ordered_drives AS (
    SELECT
        "year",
        driver_id,
        constructor_id,
        first_round,
        last_round,
        LEAD(first_round)     OVER (PARTITION BY "year", driver_id ORDER BY first_round) AS next_first_round,
        LEAD(constructor_id)  OVER (PARTITION BY "year", driver_id ORDER BY first_round) AS next_constructor_id
    FROM drives
),
gaps AS (
    SELECT
        (last_round + 1)                     AS gap_start_round,
        (next_first_round - 1)               AS gap_end_round
    FROM ordered_drives
    WHERE next_first_round IS NOT NULL
      AND (next_first_round - last_round - 1) BETWEEN 1 AND 2     -- missed < 3 races
      AND constructor_id <> next_constructor_id                   -- switched teams
)
SELECT
    AVG(gap_start_round) AS avg_first_round_missed,
    AVG(gap_end_round)   AS avg_last_round_missed
FROM gaps;