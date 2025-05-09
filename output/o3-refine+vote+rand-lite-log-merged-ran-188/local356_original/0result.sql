WITH race_lap_positions AS (
    /* keep only race‑lap positions */
    SELECT
        race_id,
        driver_id,
        lap,
        position
    FROM lap_positions
    WHERE lap_type = 'Race'
),
transitions AS (
    /* compare every driver’s successive laps (from lap‑2 onwards)         */
    SELECT
        curr.race_id,
        curr.driver_id,
        curr.lap,
        curr.position          AS curr_pos,
        prev.position          AS prev_pos,
        curr.position - prev.position AS delta        -- (+) = lost places, (‑) = gained places
    FROM race_lap_positions  AS curr
    JOIN race_lap_positions  AS prev
          ON curr.race_id  = prev.race_id
         AND curr.driver_id = prev.driver_id
         AND curr.lap       = prev.lap + 1
    /* ignore start movements (lap‑1 changes) */
    WHERE curr.lap > 1
      /* discard laps that involve a pit‑stop for this driver
         (either on the current or the previous lap)                      */
      AND NOT EXISTS (
            SELECT 1
            FROM pit_stops p
            WHERE p.race_id  = curr.race_id
              AND p.driver_id = curr.driver_id
              AND p.lap IN (curr.lap, curr.lap - 1)
      )
      /* discard laps on which any retirement happened (position shake‑up) */
      AND NOT EXISTS (
            SELECT 1
            FROM retirements r
            WHERE r.race_id = curr.race_id
              AND r.lap     = curr.lap
      )
),
driver_overtake_stats AS (
    /* count on‑track passes for every driver */
    SELECT
        driver_id,
        SUM(CASE WHEN delta < 0 THEN 1 ELSE 0 END) AS overtakes_made,
        SUM(CASE WHEN delta > 0 THEN 1 ELSE 0 END) AS overtakes_suffered
    FROM transitions
    WHERE delta <> 0                   -- ignore laps with no place change
    GROUP BY driver_id
)
SELECT DISTINCT d.full_name
FROM driver_overtake_stats s
JOIN drivers_ext           d ON d.driver_id = s.driver_id
WHERE s.overtakes_suffered > s.overtakes_made
ORDER BY d.full_name;