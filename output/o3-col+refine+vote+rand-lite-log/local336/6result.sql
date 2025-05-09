WITH
-- 1) Start-related position changes (grid vs end of lap 1)
grid AS (
    SELECT race_id,
           driver_id,
           position AS grid_pos
    FROM   lap_positions
    WHERE  lap = 0
),
lap1 AS (
    SELECT race_id,
           driver_id,
           position AS lap1_pos
    FROM   lap_positions
    WHERE  lap = 1
),
start_changes AS (
    SELECT g.race_id,
           g.driver_id
    FROM   grid  AS g
    JOIN   lap1  AS l
      ON   l.race_id   = g.race_id
     AND   l.driver_id = g.driver_id
    WHERE  g.grid_pos <> l.lap1_pos           -- position actually changed
),

-- 2) Position changes triggered by pit-stops in laps 1-5
pit_changes AS (
    SELECT ps.race_id,
           ps.driver_id
    FROM   pit_stops      AS ps
    LEFT   JOIN lap_positions AS lp_before
           ON lp_before.race_id   = ps.race_id
          AND lp_before.driver_id = ps.driver_id
          AND lp_before.lap       = ps.lap - 1
    LEFT   JOIN lap_positions AS lp_after
           ON lp_after.race_id    = ps.race_id
          AND lp_after.driver_id  = ps.driver_id
          AND lp_after.lap        = ps.lap + 1
    WHERE  ps.lap BETWEEN 1 AND 5
      AND  lp_before.position IS NOT NULL
      AND  lp_after.position  IS NOT NULL
      AND  lp_before.position <> lp_after.position   -- position changed
),

-- 3) Retirements within the first five laps
retire_changes AS (
    SELECT race_id,
           driver_id
    FROM   retirements
    WHERE  lap BETWEEN 1 AND 5
),

-- 4) Normal on-track passes (laps 1-5, excluding pit-stops & retirements)
early_pits AS (
    SELECT DISTINCT race_id, driver_id
    FROM   pit_stops
    WHERE  lap BETWEEN 1 AND 5
),
early_rets AS (
    SELECT DISTINCT race_id, driver_id
    FROM   retirements
    WHERE  lap BETWEEN 1 AND 5
),
pos_change AS (
    SELECT lp.race_id,
           lp.driver_id
    FROM  (
        SELECT race_id,
               driver_id,
               lap,
               position,
               LAG(position) OVER (PARTITION BY race_id, driver_id
                                   ORDER BY lap) AS prev_pos
        FROM   lap_positions
        WHERE  lap BETWEEN 1 AND 5
    ) AS lp
    LEFT  JOIN early_pits AS ep
           ON ep.race_id   = lp.race_id
          AND ep.driver_id = lp.driver_id
    LEFT  JOIN early_rets AS er
           ON er.race_id   = lp.race_id
          AND er.driver_id = lp.driver_id
    WHERE lp.prev_pos IS NOT NULL
      AND lp.prev_pos <> lp.position          -- position changed
      AND ep.driver_id IS NULL                -- not a pit-stop lap
      AND er.driver_id IS NULL                -- not a retirement lap
),

-- 5) Gather counts for each overtake category
counts AS (
    SELECT 'Retirements'  AS category, COUNT(*) AS overtakes FROM retire_changes
    UNION ALL
    SELECT 'Pit Stops'    , COUNT(*)              FROM pit_changes
    UNION ALL
    SELECT 'Start-Related', COUNT(*)              FROM start_changes
    UNION ALL
    SELECT 'On-Track'     , COUNT(*)              FROM pos_change
)

SELECT category,
       overtakes
FROM   counts;