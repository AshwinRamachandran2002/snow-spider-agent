WITH driver_years AS (            -- every season in which a driver actually raced
    SELECT DISTINCT r.year,
           res.driver_id
    FROM results AS res
    JOIN races   AS r ON r.race_id = res.race_id
),
calendar AS (                     -- all rounds of those seasons for every driver
    SELECT dy.driver_id,
           r.year,
           r.round,
           res.constructor_id      -- NULL when the driver did not start the race
    FROM driver_years AS dy
    JOIN races        AS r   ON r.year = dy.year
    LEFT JOIN results AS res ON res.race_id  = r.race_id
                            AND res.driver_id = dy.driver_id
),
seq AS (                          -- key to identify contiguous blocks
    SELECT *,
           (round
            - ROW_NUMBER() OVER (PARTITION BY driver_id, year ORDER BY round)
           ) AS grp
    FROM calendar
),
missed AS (                       -- blocks of <3 consecutive missed races
    SELECT driver_id,
           year,
           MIN(round) AS first_round,
           MAX(round) AS last_round,
           COUNT(*)   AS gap_len
    FROM seq
    WHERE constructor_id IS NULL
    GROUP BY driver_id, year, grp
    HAVING gap_len < 3
),
with_constructors AS (            -- constructors immediately before & after gap
    SELECT m.*,
           (SELECT c.constructor_id
            FROM calendar c
            WHERE c.driver_id = m.driver_id
              AND c.year      = m.year
              AND c.round     = m.first_round - 1
           ) AS constructor_before,
           (SELECT c.constructor_id
            FROM calendar c
            WHERE c.driver_id = m.driver_id
              AND c.year      = m.year
              AND c.round     = m.last_round + 1
           ) AS constructor_after
    FROM missed m
),
filtered AS (                     -- keep only gaps with a team switch
    SELECT *
    FROM with_constructors
    WHERE constructor_before IS NOT NULL
      AND constructor_after  IS NOT NULL
      AND constructor_before <> constructor_after
)
SELECT ROUND(AVG(first_round),4) AS average_first_round,
       ROUND(AVG(last_round),4)  AS average_last_round
FROM filtered;