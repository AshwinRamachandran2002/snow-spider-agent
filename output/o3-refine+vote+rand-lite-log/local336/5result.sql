WITH first_five_laps AS (          -- positions for laps 0‑5
    SELECT race_id,
           driver_id,
           CAST(lap AS INT)  AS lap,
           CAST(position AS INT) AS position
    FROM   lap_positions
    WHERE  CAST(lap AS INT) BETWEEN 0 AND 5
),
position_changes AS (              -- gain (= overtakes) from lap‑1→lap
    SELECT cur.race_id,
           cur.driver_id,
           cur.lap,
           prev.position  AS prev_pos,
           cur.position   AS cur_pos,
           (prev.position - cur.position) AS gained_places
    FROM   first_five_laps cur
    JOIN   first_five_laps prev
           ON  prev.race_id  = cur.race_id
           AND prev.driver_id = cur.driver_id
           AND prev.lap + 1  = cur.lap            -- previous lap
    WHERE  cur.lap BETWEEN 1 AND 5               -- first 5 racing laps
           AND (prev.position - cur.position) > 0 -- only real gains
),
retirements_lap AS (               -- laps with a retirement
    SELECT DISTINCT race_id, CAST(lap AS INT) AS lap
    FROM   retirements
    WHERE  CAST(lap AS INT) BETWEEN 1 AND 5
),
pitstops_lap AS (                  -- laps with a pit‑stop
    SELECT DISTINCT race_id, CAST(lap AS INT) AS lap
    FROM   pit_stops
    WHERE  CAST(lap AS INT) BETWEEN 1 AND 5
),
classified AS (                    -- classify every gain
    SELECT pc.gained_places,
           CASE
               WHEN rl.race_id IS NOT NULL THEN 'retirements'
               WHEN pl.race_id IS NOT NULL THEN 'pit stops'
               WHEN pc.lap = 1               THEN 'start-related overtakes'
               ELSE                              'standard on-track passes'
           END AS category
    FROM   position_changes pc
    LEFT   JOIN retirements_lap rl
           ON  rl.race_id = pc.race_id
           AND rl.lap     = pc.lap
    LEFT   JOIN pitstops_lap pl
           ON  pl.race_id = pc.race_id
           AND pl.lap     = pc.lap
)
SELECT category,
       SUM(gained_places) AS overtakes
FROM   classified
GROUP  BY category
ORDER  BY category;