WITH race_positions AS (
    /*  Only the “pure” race laps – no pit entry / exit or grid records  */
    SELECT
        lp.race_id,
        lp.driver_id,
        lp.lap,
        lp.position,
        LAG(lp.lap)      OVER (PARTITION BY lp.race_id, lp.driver_id ORDER BY lp.lap)     AS prev_lap,
        LAG(lp.position) OVER (PARTITION BY lp.race_id, lp.driver_id ORDER BY lp.lap)     AS prev_position
    FROM lap_positions lp
    WHERE lp.lap_type = 'Race'
),
position_changes AS (
    /*  Keep only consecutive‑lap position deltas after the start lap  */
    SELECT
        rp.*
    FROM race_positions rp
    WHERE rp.prev_position IS NOT NULL
      AND rp.prev_lap = rp.lap - 1          -- consecutive race laps
      AND rp.lap > 1                        -- ignore start‑lap movements
),
no_pit_changes AS (
    /*  Throw away changes that coincide with a pit entry / exit lap   */
    SELECT pc.*
    FROM position_changes pc
    LEFT JOIN pit_stops ps
           ON ps.race_id  = pc.race_id
          AND ps.driver_id = pc.driver_id
          AND ps.lap IN (pc.lap-1, pc.lap)  -- pit in previous or current lap
    WHERE ps.driver_id IS NULL
),
no_retirement_changes AS (
    /*  Throw away changes that coincide with a retirement lap         */
    SELECT npc.*
    FROM no_pit_changes npc
    LEFT JOIN retirements rt
           ON rt.race_id  = npc.race_id
          AND rt.driver_id = npc.driver_id
          AND rt.lap IN (npc.lap-1, npc.lap)
    WHERE rt.driver_id IS NULL
),
driver_totals AS (
    /*  Aggregate gains (overtakes) and losses (being overtaken)       */
    SELECT
        driver_id,
        SUM(CASE WHEN prev_position - position > 0
                 THEN  prev_position - position ELSE 0 END) AS overtakes,
        SUM(CASE WHEN position - prev_position > 0
                 THEN  position - prev_position ELSE 0 END) AS overtaken
    FROM no_retirement_changes
    GROUP BY driver_id
)
SELECT d.full_name
FROM driver_totals dt
JOIN drivers_ext d ON d.driver_id = dt.driver_id
WHERE dt.overtaken > dt.overtakes       -- lost more places than gained
ORDER BY d.full_name;