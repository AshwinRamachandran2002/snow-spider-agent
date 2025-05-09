WITH
/* 0.  Starting‑grid vs first‑lap positions ------------------------------*/
grid AS (                       -- lap 0 = grid (may include grid‑drops)
    SELECT race_id,
           driver_id,
           position AS grid_pos
    FROM   lap_positions
    WHERE  lap = 0
),
lap1 AS (                        -- position at the end of lap‑1
    SELECT race_id,
           driver_id,
           position AS lap1_pos
    FROM   lap_positions
    WHERE  lap_type = 'Race'
      AND  lap       = 1
),
start_overtakes AS (            -- gains made before the end of lap‑1
    SELECT g.race_id,
           SUM(
               CASE
                   WHEN g.grid_pos > l.lap1_pos
                   THEN g.grid_pos - l.lap1_pos
                   ELSE 0
               END
           ) AS start_related_overtakes
    FROM   grid g
    JOIN   lap1 l
           ON  l.race_id  = g.race_id
           AND l.driver_id = g.driver_id
    GROUP  BY g.race_id
),

/* 1.  Position changes during laps 1‑5 ----------------------------------*/
race_laps AS (
    SELECT race_id,
           driver_id,
           lap,
           position,
           LAG(position) OVER (PARTITION BY race_id, driver_id
                               ORDER BY lap) AS prev_pos
    FROM   lap_positions
    WHERE  lap_type = 'Race'
      AND  lap BETWEEN 1 AND 5
),
lap_overtakes AS (
    SELECT race_id,
           SUM(
               CASE
                   WHEN prev_pos IS NOT NULL
                    AND prev_pos > position
                   THEN prev_pos - position
                   ELSE 0
               END
           ) AS total_position_gains         -- raw overtakes (all reasons)
    FROM   race_laps
    GROUP  BY race_id
),

/* 2.  Events that usually trigger “free” passes -------------------------*/
pit_counts AS (
    SELECT race_id,
           COUNT(*) AS pit_stops
    FROM   pit_stops
    WHERE  lap BETWEEN 1 AND 5
    GROUP  BY race_id
),
retire_counts AS (
    SELECT race_id,
           COUNT(*) AS retirements
    FROM   retirements
    WHERE  lap BETWEEN 1 AND 5
    GROUP  BY race_id
)

/* 3.  Assemble the required categories ----------------------------------*/
SELECT r.race_id,
       COALESCE(ret.retirements,          0)                           AS retirements,
       COALESCE(pit.pit_stops,            0)                           AS pit_stops,
       COALESCE(st.start_related_overtakes,0)                           AS start_related_overtakes,
       MAX(                                                               -- never show negative
           COALESCE(lap.total_position_gains,0)
           - COALESCE(pit.pit_stops,            0)
           - COALESCE(ret.retirements,          0)
           - COALESCE(st.start_related_overtakes,0), 
           0
       )                                                               AS standard_on_track_passes
FROM   races             r
LEFT   JOIN start_overtakes st  ON st.race_id  = r.race_id
LEFT   JOIN lap_overtakes   lap ON lap.race_id = r.race_id
LEFT   JOIN pit_counts      pit ON pit.race_id = r.race_id
LEFT   JOIN retire_counts   ret ON ret.race_id = r.race_id
/* comment the next WHERE clause if you want EVERY race in the database   */
/* WHERE  r.race_id = :desired_race_id                                    */
WHERE  r.race_id IN (SELECT DISTINCT race_id
                     FROM   lap_positions
                     WHERE  lap BETWEEN 0 AND 5)
GROUP  BY r.race_id
ORDER  BY r.race_id;