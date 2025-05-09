WITH first_five_laps AS (
    SELECT race_id,
           driver_id,
           lap,
           position
    FROM   lap_positions
    WHERE  race_id = 1               -- ←‑‑ choose the race you want analysed
      AND  lap BETWEEN 0 AND 5
),
lap_pairs AS (                               -- consecutive‑lap position pairs
    SELECT  c.race_id,
            c.driver_id,
            c.lap,                          -- current lap  (1 … 5)
            p.position  AS prev_pos,        -- position on previous lap
            c.position  AS curr_pos,
            p.position - c.position AS delta_pos   -- +ve  → positions gained
    FROM   first_five_laps  c
    JOIN   first_five_laps  p
           ON  c.race_id  = p.race_id
           AND c.driver_id = p.driver_id
           AND c.lap       = p.lap + 1
),
categorised_changes AS (
    SELECT lp.*,
           CASE
               WHEN lp.lap = 1                                          THEN 'start'
               WHEN EXISTS ( SELECT 1
                              FROM   pit_stops ps
                              WHERE  ps.race_id  = lp.race_id
                                AND  ps.driver_id = lp.driver_id
                                AND  ps.lap       = lp.lap )            THEN 'pit stop'
               WHEN EXISTS ( SELECT 1
                              FROM   retirements r
                              WHERE  r.race_id  = lp.race_id
                                AND  r.driver_id = lp.driver_id
                                AND  r.lap       = lp.lap )             THEN 'retirement'
               ELSE                                                        'standard'
           END AS category
    FROM   lap_pairs lp
),
gained_positions AS (                      -- only count drivers that moved forward
    SELECT category,
           SUM(CASE WHEN delta_pos > 0 THEN delta_pos ELSE 0 END) AS gained
    FROM   categorised_changes
    GROUP BY category
)
SELECT category,
       CAST(ROUND(gained / 2.0) AS INT) AS overtakes          -- divide by 2 ⇒ one pass, two drivers
FROM   gained_positions
ORDER BY category;