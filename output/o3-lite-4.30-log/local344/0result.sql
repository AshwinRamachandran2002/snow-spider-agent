WITH races_with_pits AS (
    SELECT race_id
    FROM races_ext
    WHERE is_pit_data_available = 1
),
running AS (                     -- drivers still classified on a given lap
    SELECT lp.race_id,
           lp.driver_id,
           lp.lap
    FROM   lap_positions lp
    JOIN   races_with_pits rw USING (race_id)
    LEFT   JOIN retirements r
           ON  r.race_id   = lp.race_id
           AND r.driver_id = lp.driver_id
           AND r.lap      <= lp.lap
    WHERE  r.driver_id IS NULL
),
overtakes AS (                   -- new “follower‑behind‑leader” situations
    SELECT CASE
               WHEN cur.lap = 1                        THEN 'Race Start'
               WHEN prev_follower.lap_type LIKE 'Pit%' THEN 'Pit Exit'
               WHEN cur.lap_type        LIKE 'Pit%'    THEN 'Pit Entry'
               ELSE                                        'On‑Track'
           END AS overtake_type
    FROM   lap_positions AS cur
    JOIN   races_with_pits rw            ON rw.race_id = cur.race_id
    JOIN   running        run_cur        ON run_cur.race_id   = cur.race_id
                                         AND run_cur.driver_id = cur.driver_id
                                         AND run_cur.lap       = cur.lap
    JOIN   lap_positions  AS lead        ON lead.race_id  = cur.race_id
                                         AND lead.lap    = cur.lap
                                         AND lead.position = cur.position - 1
    JOIN   running        run_lead       ON run_lead.race_id  = lead.race_id
                                         AND run_lead.driver_id = lead.driver_id
                                         AND run_lead.lap       = lead.lap
    LEFT  JOIN lap_positions AS prev_follower
           ON prev_follower.race_id   = cur.race_id
           AND prev_follower.driver_id = cur.driver_id
           AND prev_follower.lap       = cur.lap - 1
    LEFT  JOIN lap_positions AS prev_lead
           ON prev_lead.race_id   = prev_follower.race_id
           AND prev_lead.lap      = prev_follower.lap
           AND prev_lead.position = prev_follower.position - 1
    WHERE  prev_follower.driver_id IS NOT NULL
       AND (prev_lead.driver_id IS NULL
            OR prev_lead.driver_id <> lead.driver_id)
),
agg AS (                         -- aggregate counts
    SELECT overtake_type,
           COUNT(*) AS count
    FROM   overtakes
    GROUP  BY overtake_type
),
types AS (                       -- guarantee all four labels appear
    SELECT 'On‑Track'   AS overtake_type UNION ALL
    SELECT 'Race Start' UNION ALL
    SELECT 'Pit Entry'  UNION ALL
    SELECT 'Pit Exit'
)
SELECT t.overtake_type,
       COALESCE(a.count, 0) AS count
FROM   types t
LEFT   JOIN agg a USING (overtake_type)
ORDER  BY count DESC, overtake_type;