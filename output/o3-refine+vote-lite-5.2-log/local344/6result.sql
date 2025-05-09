WITH
/* 1.  Races for which we really have pit‑stop information                 */
races_with_pit AS (
    SELECT race_id
    FROM races_ext
    WHERE is_pit_data_available = 1
),

/* 2.  Position of every driver on every lap in those races                */
driver_positions AS (
    SELECT lp.race_id,
           lp.driver_id,
           lp.lap,
           lp.position
    FROM lap_positions lp
    JOIN races_with_pit r
          ON r.race_id = lp.race_id
    WHERE lp.position IS NOT NULL
),

/* 3.  Pairs of drivers whose order flips between two consecutive laps     */
/*     (i.e. the driver that HAD been ahead is now behind)                 */
order_changes AS (
    SELECT curA.race_id,
           curA.lap,
           curB.driver_id   AS overtaker_id,   -- driver now in front
           curA.driver_id   AS overtaken_id    -- driver now behind
    FROM driver_positions curA
    JOIN driver_positions curB
          ON curB.race_id   = curA.race_id
         AND curB.lap       = curA.lap
         AND curB.driver_id <> curA.driver_id
    JOIN driver_positions prevA
          ON prevA.race_id  = curA.race_id
         AND prevA.driver_id= curA.driver_id
         AND prevA.lap      = curA.lap - 1
    JOIN driver_positions prevB
          ON prevB.race_id  = curB.race_id
         AND prevB.driver_id= curB.driver_id
         AND prevB.lap      = curB.lap - 1
    /*  A was ahead of B, now A is behind B  */
    WHERE prevA.position < prevB.position     -- previous lap order
      AND curA.position  > curB.position      -- current lap order
      /* keep each swap once (avoids A/B vs B/A duplicates) */
      AND curA.driver_id < curB.driver_id
),

/* 4.  Classify every swap                                                 */
classified_overtakes AS (
    SELECT oc.*,
           CASE
               WHEN oc.lap = 1                                                     THEN 'Race Start'
               WHEN EXISTS (SELECT 1
                            FROM retirements r
                            WHERE r.race_id = oc.race_id
                              AND r.driver_id = oc.overtaken_id
                              AND r.lap       = oc.lap)                            THEN 'Retirement'
               WHEN EXISTS (SELECT 1
                            FROM pit_stops ps
                            WHERE ps.race_id = oc.race_id
                              AND ps.driver_id = oc.overtaken_id
                              AND ps.lap       = oc.lap)                           THEN 'Pit‑stop Entry'
               WHEN EXISTS (SELECT 1
                            FROM pit_stops ps
                            WHERE ps.race_id = oc.race_id
                              AND ps.driver_id = oc.overtaker_id
                              AND ps.lap       = oc.lap)                           THEN 'Pit‑stop Exit'
               ELSE 'On‑track'
           END AS overtake_type
    FROM order_changes oc
)

/* 5.  Final count per overtake type                                       */
SELECT   overtake_type,
         COUNT(*) AS total_overtakes
FROM     classified_overtakes
GROUP BY overtake_type
ORDER BY total_overtakes DESC;