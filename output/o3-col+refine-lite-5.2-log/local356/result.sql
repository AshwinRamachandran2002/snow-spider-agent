WITH lap_deltas AS (
    -- keep consecutive race‑lap position pairs for every driver
    SELECT
        cur."driver_id",
        cur."race_id",
        cur."lap",
        cur."position"          AS curr_pos,
        prev."position"         AS prev_pos,
        (cur."position" - prev."position") AS delta
    FROM   "lap_positions" AS cur
    JOIN   "lap_positions" AS prev
           ON  prev."race_id"   = cur."race_id"
           AND prev."driver_id" = cur."driver_id"
           AND prev."lap"       = cur."lap" - 1
    WHERE  cur."lap_type"  = 'Race'      -- ignore pit‑in/out & retirements
      AND  prev."lap_type" = 'Race'
      AND  cur."lap"       > 1           -- exclude start‑lap movements
),
driver_moves AS (
    -- count gained / lost places (absolute positions) per driver
    SELECT
        "driver_id",
        SUM(CASE WHEN delta < 0 THEN -delta ELSE 0 END) AS overtakes,
        SUM(CASE WHEN delta > 0 THEN  delta ELSE 0 END) AS overtaken
    FROM   lap_deltas
    WHERE  delta <> 0                              -- no change → ignore
    GROUP  BY "driver_id"
),
more_overtaken_than_overtake AS (
    SELECT "driver_id"
    FROM   driver_moves
    WHERE  overtaken > overtakes
)
SELECT DISTINCT
       d."forename" || ' ' || d."surname" AS full_name
FROM   more_overtaken_than_overtake m
JOIN   "drivers" d
       ON d."driver_id" = m."driver_id"
ORDER  BY full_name;