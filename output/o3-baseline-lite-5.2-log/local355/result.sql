WITH driver_year_results AS (
    /* every race a driver started, together with its year/round and the team used */
    SELECT
        r."driver_id",
        ra."year",
        ra."round",
        r."constructor_id"
    FROM "results" r
    JOIN "races"  ra ON ra."race_id" = r."race_id"
),
gaps AS (
    /* look at consecutive starts inside each (driver,year) and measure the gap */
    SELECT
        driver_id,
        year,
        round,
        constructor_id,
        LEAD(round)          OVER (PARTITION BY driver_id, year ORDER BY round) AS next_round,
        LEAD(constructor_id) OVER (PARTITION BY driver_id, year ORDER BY round) AS next_constructor_id
    FROM driver_year_results
),
filtered_hiatuses AS (
    /* keep only hiatuses of 1‑2 races and where the driver switched teams */
    SELECT
        driver_id,
        year,
        (round + 1)       AS first_missed_round,
        (next_round - 1)  AS last_missed_round
    FROM gaps
    WHERE next_round IS NOT NULL
      AND (next_round - round - 1) BETWEEN 1 AND 2          -- missed < 3 races
      AND constructor_id <> next_constructor_id             -- team switch
)
SELECT
    AVG(first_missed_round) AS avg_first_round_missed,
    AVG(last_missed_round)  AS avg_last_round_missed
FROM filtered_hiatuses;