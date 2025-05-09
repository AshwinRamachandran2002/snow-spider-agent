WITH races_with_pit AS (
    /* Only keep races for which we actually have pit–stop information */
    SELECT race_id
    FROM   races_ext
    WHERE  is_pit_data_available = 1
),

/* Every driver’s classified race‑lap position           */
race_laps AS (
    SELECT lp.race_id,
           lp.driver_id,
           lp.lap,
           lp.position
    FROM   lap_positions lp
           INNER JOIN races_with_pit r
                       ON r.race_id = lp.race_id
    WHERE  lp.lap_type = 'Race'
),

/* Laps in which the driver’s position worsened
   (i.e. he is now BEHIND somebody he was not behind
   on the previous lap)                                    */
lost_places AS (
    SELECT cur.race_id,
           cur.driver_id,
           cur.lap,
           prev.position AS prev_pos,
           cur.position  AS cur_pos
    FROM   race_laps cur
           JOIN race_laps prev
                 ON  prev.race_id  = cur.race_id
                 AND prev.driver_id = cur.driver_id
                 AND prev.lap       = cur.lap - 1
    WHERE  cur.position > prev.position      -- position number increased
),

/* Classify the reason for the place‑loss  */
classified AS (
    SELECT lp.*,
           CASE
               WHEN lp.lap = 1 THEN                               'Race Start'
               WHEN EXISTS (SELECT 1
                            FROM   pit_stops ps
                            WHERE  ps.race_id  = lp.race_id
                            AND    ps.driver_id = lp.driver_id
                            AND    ps.lap       = lp.lap)        THEN 'Pit Stop Entry/Exit'
               WHEN EXISTS (SELECT 1
                            FROM   retirements rt
                            WHERE  rt.race_id  = lp.race_id
                            AND    rt.driver_id = lp.driver_id
                            AND    rt.lap       = lp.lap)        THEN 'Retirement'
               ELSE                                               'On‑Track'
           END AS overtake_type
    FROM   lost_places lp
)

/* Count how many times every kind of over‑take happened. */
SELECT   overtake_type,
         COUNT(*) AS occurrences
FROM     classified
GROUP BY overtake_type
ORDER BY occurrences DESC;