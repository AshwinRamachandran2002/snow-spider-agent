WITH
--------------------------------------------------------------------
-- 1.  start‑related overtakes (gains between grid‑lap (0) and lap 1)
--------------------------------------------------------------------
start_overtakes AS (
    SELECT COUNT(*) AS cnt
    FROM (
        SELECT lp0.race_id, lp0.driver_id
        FROM lap_positions lp0
        JOIN lap_positions lp1
              ON lp1.race_id  = lp0.race_id
             AND lp1.driver_id = lp0.driver_id
             AND lp0.lap       = 0              -- grid / formation‑lap
             AND lp1.lap       = 1              -- first racing lap
        WHERE lp0.position  > lp1.position      -- driver gained places
    )
),
--------------------------------------------------------------------
-- 2.  pit‑stop related “overtakes” (any pit stop in laps 1‑5)
--------------------------------------------------------------------
pit_overtakes AS (
    SELECT COUNT(*) AS cnt
    FROM pit_stops
    WHERE lap BETWEEN 1 AND 5
),
--------------------------------------------------------------------
-- 3.  retirements in the first five laps
--------------------------------------------------------------------
retire_overtakes AS (
    SELECT COUNT(*) AS cnt
    FROM retirements
    WHERE lap BETWEEN 1 AND 5
),
--------------------------------------------------------------------
-- 4.  every position gain between consecutive race laps 1‑5
--------------------------------------------------------------------
total_position_gains AS (
    SELECT COUNT(*) AS cnt
    FROM (
        SELECT lp_curr.race_id,
               lp_curr.driver_id
        FROM   lap_positions lp_curr
        JOIN   lap_positions lp_prev
               ON lp_prev.race_id  = lp_curr.race_id
              AND lp_prev.driver_id = lp_curr.driver_id
              AND lp_prev.lap      = lp_curr.lap - 1          -- consecutive laps
        WHERE  lp_curr.lap BETWEEN 1 AND 5                    -- laps of interest
          AND  lp_curr.position   < lp_prev.position          -- position improved
    )
),
--------------------------------------------------------------------
-- 5.  standard on‑track passes =      all gains
--                                  –  start gains
--                                  –  pit‑stop gains
--                                  –  retirement gains
--------------------------------------------------------------------
standard_overtakes AS (
    SELECT  total_position_gains.cnt
           -COALESCE(start_overtakes.cnt ,0)
           -COALESCE(pit_overtakes.cnt  ,0)
           -COALESCE(retire_overtakes.cnt,0)   AS cnt
    FROM total_position_gains, start_overtakes, pit_overtakes, retire_overtakes
)
--------------------------------------------------------------------
-- 6.  final answer
--------------------------------------------------------------------
SELECT 
    (SELECT cnt FROM retire_overtakes)        AS retirements,
    (SELECT cnt FROM pit_overtakes)           AS pit_stops,
    (SELECT cnt FROM start_overtakes)         AS start_related_overtakes,
    (SELECT cnt FROM standard_overtakes)      AS standard_on_track_passes;