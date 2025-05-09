WITH pit AS (
    SELECT race_id,
           driver_id,
           lap                 -- lap in which the driver entered the pits
    FROM pit_stops
    UNION ALL
    SELECT race_id,
           driver_id,
           lap + 1             -- very next lap (pit‑exit lap)
    FROM pit_stops
),
filtered AS (
    SELECT lp.race_id,
           lp.driver_id,
           lp.lap,
           lp.position
    FROM lap_positions lp
    LEFT JOIN pit  p
           ON p.race_id  = lp.race_id
          AND p.driver_id = lp.driver_id
          AND p.lap       = lp.lap
    LEFT JOIN retirements r
           ON r.race_id   = lp.race_id
          AND r.driver_id = lp.driver_id
          AND r.lap       = lp.lap
    WHERE lp.lap_type = 'Race'   -- consider only normal race laps
      AND lp.lap > 1             -- ignore first‑lap (start) movements
      AND p.lap IS NULL          -- exclude pit‑entry and pit‑exit laps
      AND r.lap IS NULL          -- exclude laps where a driver retired
),
pos_changes AS (
    SELECT  race_id,
            driver_id,
            lap,
            position,
            LAG(position) OVER (PARTITION BY race_id, driver_id ORDER BY lap) AS prev_pos
    FROM filtered
),
driver_stats AS (
    SELECT  driver_id,
            SUM(CASE WHEN position < prev_pos THEN 1 ELSE 0 END) AS overtakes_made,
            SUM(CASE WHEN position > prev_pos THEN 1 ELSE 0 END) AS overtakes_suffered
    FROM pos_changes
    WHERE prev_pos IS NOT NULL
    GROUP BY driver_id
)
SELECT d.full_name
FROM driver_stats s
JOIN drivers_ext d ON d.driver_id = s.driver_id
WHERE s.overtakes_suffered > s.overtakes_made
ORDER BY d.full_name;