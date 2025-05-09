WITH moves AS (
    /* position improvements (overtakes) between consecutive laps 0‑5 */
    SELECT
        lp0.race_id,
        lp0.driver_id,
        lp0.lap  AS prev_lap,          -- 0‑4
        lp1.lap  AS curr_lap,          -- 1‑5
        lp0.position AS prev_pos,
        lp1.position AS curr_pos
    FROM lap_positions lp0
    JOIN lap_positions lp1
         ON lp1.race_id   = lp0.race_id
        AND lp1.driver_id = lp0.driver_id
        AND lp1.lap       = lp0.lap + 1
    WHERE lp0.lap BETWEEN 0 AND 4
      AND lp0.position  > lp1.position            -- gained places → an overtake
), classified AS (
    /* assign each overtake to one of the four categories */
    SELECT
        CASE
            WHEN m.prev_lap = 0
                 THEN 'start_overtakes'                                   -- grid → lap 1
            WHEN EXISTS (SELECT 1
                         FROM retirements r
                         WHERE r.race_id = m.race_id
                           AND r.lap     = m.curr_lap)
                 THEN 'retirement_overtakes'                              -- rival retired this lap
            WHEN EXISTS (SELECT 1
                         FROM pit_stops ps
                         WHERE ps.race_id  = m.race_id
                           AND ps.lap      = m.curr_lap
                           AND ps.driver_id <> m.driver_id)
                 THEN 'pitstop_overtakes'                                 -- rival pitted this lap
            ELSE 'standard_ontrack_overtakes'                             -- pure racing pass
        END AS overtake_type
    FROM moves m
)
SELECT
    overtake_type,
    COUNT(*) AS overtake_count
FROM classified
GROUP BY overtake_type
ORDER BY overtake_type;