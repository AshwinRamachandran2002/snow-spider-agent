WITH pit_races AS (                     -- 1.  only races that have reliable pit‑stop data
    SELECT race_id
    FROM races_ext
    WHERE is_pit_data_available = 1
),

race_laps AS (                          -- 2. every driver’s position on every lap
    SELECT lp.race_id ,
           lp.driver_id ,
           lp.lap ,
           lp.position
    FROM   lap_positions lp
    JOIN   pit_races      pr  ON pr.race_id = lp.race_id
    WHERE  lp.lap_type = 'Race'         -- ignore installation / grid‑drop rows
),

cur_rel AS (                            -- 3. driver directly in front of every driver per lap
    SELECT rl.race_id ,
           rl.lap ,
           rl.driver_id              AS driver_behind ,
           rl.position               AS behind_pos ,
           fr.driver_id              AS driver_front
    FROM   race_laps rl
    LEFT JOIN race_laps fr
           ON fr.race_id = rl.race_id
          AND fr.lap     = rl.lap
          AND fr.position = rl.position - 1          -- car immediately ahead
),

rel_with_history AS (                   -- 4. who was ahead on the previous lap?
    SELECT cr.* ,
           LAG(cr.driver_front) OVER (PARTITION BY cr.race_id ,
                                                  cr.driver_behind
                                       ORDER BY   cr.lap)    AS prev_driver_front
    FROM   cur_rel cr
),

overtake_raw AS (                       -- 5. new “ahead” car → a position change happened
    SELECT *
    FROM   rel_with_history
    WHERE  driver_front IS NOT NULL
      AND (prev_driver_front IS NULL OR prev_driver_front <> driver_front)
),

classified AS (                         -- 6. classify the reason for the position change
    SELECT  oraw.* ,
            CASE
                 WHEN oraw.lap = 1
                      THEN 'race_start'

                 WHEN EXISTS ( SELECT 1
                                FROM   pit_stops ps
                                WHERE  ps.race_id  = oraw.race_id
                                  AND  ps.driver_id = oraw.driver_behind
                                  AND  ps.lap       = oraw.lap )
                      THEN 'pit_entry'            -- driver losing the place has pitted

                 WHEN EXISTS ( SELECT 1
                                FROM   pit_stops ps
                                WHERE  ps.race_id  = oraw.race_id
                                  AND  ps.driver_id = oraw.driver_front
                                  AND  ps.lap       = oraw.lap )
                      THEN 'pit_exit'             -- driver gaining the place leaves pit

                 WHEN EXISTS ( SELECT 1
                                FROM   retirements r
                                WHERE  r.race_id  = oraw.race_id
                                  AND  r.driver_id = oraw.driver_front
                                  AND  r.lap       = oraw.lap )
                      THEN 'retirement'           -- new car in front retires on this lap

                 ELSE 'on_track'                  -- ordinary racing overtake
            END  AS overtake_type
    FROM   overtake_raw oraw
)

-- 7. final answer: how many times each type of overtake happened
SELECT   overtake_type ,
         COUNT(*) AS total_overtakes
FROM     classified
GROUP BY overtake_type
ORDER BY total_overtakes DESC;