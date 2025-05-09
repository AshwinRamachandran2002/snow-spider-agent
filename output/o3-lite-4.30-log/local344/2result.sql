WITH
pit_races AS (                               -- races that have pit‑stop data
    SELECT DISTINCT race_id
    FROM pit_stops
),

/* detect every swap of order between two consecutive laps
   (driver b.passed_driver was ahead of the passer on the previous lap
    but is now behind on the current lap)                          */
base AS (
    SELECT
        cur.race_id,
        cur.lap,
        prev.lap_type                    AS prev_lap_type,
        cur.driver_id                    AS passer_driver,
        prev_ahead.driver_id             AS passed_driver
    FROM lap_positions AS cur            -- position of the eventual passer, current lap
    JOIN lap_positions AS prev           -- same driver, previous lap
      ON prev.race_id   = cur.race_id
     AND prev.driver_id = cur.driver_id
     AND prev.lap       = cur.lap - 1
    JOIN lap_positions AS prev_ahead     -- the driver who was directly ahead previously
      ON prev_ahead.race_id = prev.race_id
     AND prev_ahead.lap     = prev.lap
     AND prev_ahead.position = prev.position - 1
    JOIN lap_positions AS cur_ahead      -- that same driver on the current lap
      ON cur_ahead.race_id   = prev_ahead.race_id
     AND cur_ahead.driver_id = prev_ahead.driver_id
     AND cur_ahead.lap       = cur.lap
    WHERE cur.lap_type = 'Race'          -- only race‑lap records
      AND cur_ahead.position > cur.position      -- order has swapped
      AND cur.race_id IN (SELECT race_id FROM pit_races)
),

/* classify each swap */
classified AS (
    SELECT
        b.*,
        CASE
            WHEN b.lap = 1
              OR b.prev_lap_type LIKE 'Starting Position%'         -- race start
                 THEN 'Race Start Pass'

            WHEN EXISTS (                                         -- passed car pits this lap
                     SELECT 1 FROM pit_stops ps
                     WHERE ps.race_id  = b.race_id
                       AND ps.driver_id = b.passed_driver
                       AND ps.lap       = b.lap
                 ) THEN 'Pit-Entry Pass'

            WHEN EXISTS (                                         -- passed car exited pits
                     SELECT 1 FROM pit_stops ps
                     WHERE ps.race_id  = b.race_id
                       AND ps.driver_id = b.passed_driver
                       AND ps.lap       = b.lap - 1
                 ) THEN 'Pit-Exit Pass'

            WHEN EXISTS (                                         -- passed car retires
                     SELECT 1 FROM retirements r
                     WHERE r.race_id   = b.race_id
                       AND r.driver_id = b.passed_driver
                       AND r.lap       = b.lap
                 ) THEN 'Retirement Pass'

            ELSE 'On-Track Pass'                                  -- all other cases
        END AS overtake_type
    FROM base b
)

SELECT
    overtake_type,
    COUNT(*) AS count
FROM classified
GROUP BY overtake_type
ORDER BY count DESC;