WITH pit_laps AS (                -- laps influenced by any pit stop (entry & exit)
    SELECT DISTINCT race_id, lap         FROM pit_stops
    UNION ALL
    SELECT DISTINCT race_id, lap + 1     FROM pit_stops
),
retire_laps AS (                     -- laps on which a retirement occurred
    SELECT DISTINCT race_id, lap
    FROM retirements
),
deltas AS (                          -- lap‑to‑lap position changes after filtering
    SELECT  cur.race_id,
            cur.driver_id,
            (prev.position - cur.position) AS delta_pos
    FROM    lap_positions  AS cur
    JOIN    lap_positions  AS prev
           ON prev.race_id   = cur.race_id
          AND prev.driver_id = cur.driver_id
          AND prev.lap       = cur.lap - 1
          AND prev.lap_type  = 'Race'
    WHERE   cur.lap_type = 'Race'
      AND   cur.lap      > 1               -- ignore first‑lap movements
      AND   NOT EXISTS (                   -- exclude laps affected by any pit stop
              SELECT 1
              FROM   pit_laps p
              WHERE  p.race_id = cur.race_id
                AND  p.lap     = cur.lap
            )
      AND   NOT EXISTS (                   -- exclude laps with retirements
              SELECT 1
              FROM   retire_laps r
              WHERE  r.race_id = cur.race_id
                AND  r.lap     = cur.lap
            )
),
stats AS (                            -- count overtakes vs. times overtaken
    SELECT  driver_id,
            SUM(CASE WHEN delta_pos > 0 THEN 1 ELSE 0 END) AS overtakes_made,
            SUM(CASE WHEN delta_pos < 0 THEN 1 ELSE 0 END) AS times_overtaken
    FROM    deltas
    GROUP BY driver_id
)
SELECT d.full_name
FROM   stats        s
JOIN   drivers_ext  d ON d.driver_id = s.driver_id
WHERE  s.times_overtaken > s.overtakes_made
ORDER  BY d.full_name;