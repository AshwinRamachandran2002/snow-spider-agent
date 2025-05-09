WITH races_with_pit AS (
    SELECT race_id
    FROM races_ext
    WHERE is_pit_data_available = 1
),
pos AS (
    /* include grid (lap 0) plus every race lap for eligible grands prix */
    SELECT lp.race_id,
           lp.lap,
           lp.driver_id,
           lp.position
    FROM   lap_positions lp
    JOIN   races_with_pit rwp
           ON rwp.race_id = lp.race_id
    WHERE  lp.lap_type = 'Race'
       OR  lp.lap_type LIKE 'Starting%'
),
candidate AS (
    /* order between two cars is reversed from lap‑1 to lap */
    SELECT  pA.race_id,
            pA.lap + 1         AS lap,
            pA.driver_id       AS driver_a,   -- was ahead, now behind
            pB.driver_id       AS driver_b    -- was behind, now ahead
    FROM    pos pA
    JOIN    pos pB
           ON pB.race_id  = pA.race_id
          AND pB.lap      = pA.lap
          AND pB.position > pA.position        -- A ahead of B on lap‑1
    JOIN    pos cA
           ON cA.race_id  = pA.race_id
          AND cA.lap      = pA.lap + 1
          AND cA.driver_id= pA.driver_id
    JOIN    pos cB
           ON cB.race_id  = pB.race_id
          AND cB.lap      = pB.lap + 1
          AND cB.driver_id= pB.driver_id
    WHERE   cB.position < cA.position          -- B ahead of A on current lap
),
classified AS (
    SELECT
        CASE
            WHEN c.lap = 1                                   THEN 'Race Start'
            WHEN ps_exit.driver_id  IS NOT NULL              THEN 'Pit Exit'
            WHEN ps_entry.driver_id IS NOT NULL              THEN 'Pit Entry'
            WHEN ret_prev.driver_id IS NOT NULL
              OR ret_curr.driver_id IS NOT NULL              THEN 'Post‑Retirement'
            ELSE                                                'On‑Track'
        END                              AS overtake_type
    FROM   candidate c
    /* gaining driver exited pits on previous lap */
    LEFT JOIN pit_stops ps_exit
           ON ps_exit.race_id   = c.race_id
          AND ps_exit.driver_id = c.driver_b
          AND ps_exit.lap       = c.lap - 1
    /* losing driver enters pits this lap */
    LEFT JOIN pit_stops ps_entry
           ON ps_entry.race_id   = c.race_id
          AND ps_entry.driver_id = c.driver_a
          AND ps_entry.lap       = c.lap
    /* retirements on previous or current lap */
    LEFT JOIN retirements ret_prev
           ON ret_prev.race_id = c.race_id
          AND ret_prev.lap     = c.lap - 1
          AND ret_prev.driver_id IN (c.driver_a, c.driver_b)
    LEFT JOIN retirements ret_curr
           ON ret_curr.race_id = c.race_id
          AND ret_curr.lap     = c.lap
          AND ret_curr.driver_id IN (c.driver_a, c.driver_b)
),
categories AS (
    SELECT 'Race Start'        AS overtake_type UNION ALL
    SELECT 'Pit Entry'                           UNION ALL
    SELECT 'Pit Exit'                            UNION ALL
    SELECT 'Post‑Retirement'                     UNION ALL
    SELECT 'On‑Track'
),
counts AS (
    SELECT overtake_type, COUNT(*) AS cnt
    FROM   classified
    GROUP BY overtake_type
)
SELECT  cat.overtake_type,
        COALESCE(cnt.cnt,0) AS overtake_count
FROM    categories cat
LEFT JOIN counts cnt USING (overtake_type)
ORDER BY cat.overtake_type;