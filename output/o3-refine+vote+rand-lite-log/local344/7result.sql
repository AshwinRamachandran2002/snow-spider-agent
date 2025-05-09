WITH races_with_pit AS (          -- races that contain pit‑stop information
    SELECT race_id
    FROM races_ext
    WHERE is_pit_data_available = 1
),
-- every recorded position (grid = lap 0 + race laps)
positions AS (
    SELECT race_id,
           driver_id,
           lap,
           position
    FROM lap_positions
    WHERE race_id IN (SELECT race_id FROM races_with_pit)
),
-- detect an overtake: driver X was ahead of Y on previous lap,
-- but is now behind on the current lap
raw_overtakes AS (
    SELECT  c1.race_id,
            c1.lap,
            c1.driver_id  AS driver_behind,   -- lost the place
            c2.driver_id  AS driver_ahead,    -- gained the place
            CASE
                WHEN c1.lap = 1                       THEN 'Race Start'
                WHEN ps.driver_id IS NOT NULL         THEN 'Pit‑stop'
                WHEN rt.driver_id IS NOT NULL         THEN 'Retirement'
                ELSE                                       'On‑track'
            END AS overtake_type
    FROM   positions c1
    JOIN   positions c2
           ON  c2.race_id  = c1.race_id
           AND c2.lap      = c1.lap
           AND c2.driver_id <> c1.driver_id
    -- previous‑lap positions
    JOIN   positions p1
           ON  p1.race_id   = c1.race_id
           AND p1.driver_id = c1.driver_id
           AND p1.lap       = c1.lap - 1
    JOIN   positions p2
           ON  p2.race_id   = c2.race_id
           AND p2.driver_id = c2.driver_id
           AND p2.lap       = c2.lap - 1
    -- pit‑stop & retirement checks (must come before WHERE clause)
    LEFT JOIN pit_stops ps
           ON  ps.race_id = c1.race_id
           AND ps.lap     = c1.lap
           AND ps.driver_id IN (c1.driver_id, c2.driver_id)
    LEFT JOIN retirements rt
           ON  rt.race_id = c1.race_id
           AND rt.lap     = c1.lap
           AND rt.driver_id IN (c1.driver_id, c2.driver_id)
    -- order has flipped
    WHERE  p1.position < p2.position        -- previously ahead
       AND c1.position > c2.position        -- now behind
),
-- count each category
overtake_totals AS (
    SELECT overtake_type,
           COUNT(*) AS total_occurrences
    FROM   raw_overtakes
    GROUP BY overtake_type
)
SELECT overtake_type,
       total_occurrences
FROM   overtake_totals
ORDER BY total_occurrences DESC;