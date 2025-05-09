WITH ordered_drives AS (
    SELECT
        year,
        driver_id,
        constructor_id,
        first_round,
        last_round,
        ROW_NUMBER() OVER (PARTITION BY year, driver_id ORDER BY first_round) AS rn
    FROM drives
),
hiatuses AS (
    /* consecutive stints separated by 1‑2 missed races and a constructor change */
    SELECT
        d1.last_round + 1 AS first_missed_round,
        d2.first_round - 1 AS last_missed_round
    FROM ordered_drives d1
    JOIN ordered_drives d2
      ON d1.year      = d2.year
     AND d1.driver_id = d2.driver_id
     AND d2.rn        = d1.rn + 1          -- next stint in the same season
    WHERE (d2.first_round - d1.last_round - 1) BETWEEN 1 AND 2  -- < 3 races missed
      AND d1.constructor_id <> d2.constructor_id               -- team switch
)
SELECT
    AVG(first_missed_round) AS avg_first_round_missed,
    AVG(last_missed_round)  AS avg_last_round_missed
FROM hiatuses;