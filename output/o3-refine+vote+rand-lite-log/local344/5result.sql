WITH races_with_pit AS (               -- 1. only look at GPs that have pit‑stop data
    SELECT DISTINCT race_id
    FROM   pit_stops
),

all_lap_pos AS (                       -- 2. every classified lap‑position record
    SELECT lp.*
    FROM   lap_positions lp
    JOIN   races_with_pit r USING (race_id)
),

driver_lap_ranks AS (                  -- 3. position of a driver on the current and
                                       --    the immediately preceding lap
    SELECT  race_id,
            driver_id,
            lap,
            position,
            lap_type,
            LAG(position)  OVER (PARTITION BY race_id, driver_id ORDER BY lap)      AS prev_pos,
            LAG(lap_type)  OVER (PARTITION BY race_id, driver_id ORDER BY lap)      AS prev_type
    FROM    all_lap_pos
),

pairs_this_lap AS (                    -- 4. pair each driver with the car directly
                                       --    in front of him on the *same* lap
    SELECT  d1.race_id,
            d1.lap,
            d1.driver_id        AS behind_driver,
            d2.driver_id        AS ahead_driver,          -- the car he is following
            d1.position         AS behind_pos,
            d2.position         AS ahead_pos,
            d1.prev_pos         AS behind_prev_pos,
            d2.prev_pos         AS ahead_prev_pos,
            d1.lap_type,
            d1.prev_type
    FROM    driver_lap_ranks d1
    JOIN    driver_lap_ranks d2
           ON  d2.race_id = d1.race_id
           AND d2.lap     = d1.lap
           AND d2.position = d1.position - 1              -- one place ahead
),

newly_behind AS (                       -- 5. keep *new* situations where the car
                                        --    behind was *not* behind on the lap before
    SELECT *
    FROM   pairs_this_lap
    WHERE  (behind_prev_pos IS NULL          -- no previous lap (e.g. start)  OR
            OR behind_prev_pos > ahead_prev_pos)   -- was *not* right behind before
),

overtake_classified AS (                -- 6. decide *why* the order changed
    SELECT  nb.race_id,
            nb.lap,
            nb.behind_driver,
            nb.ahead_driver,
            CASE
                /* 6a – start‑lap position changes                       */
                WHEN nb.lap = 1 THEN 'Start'

                /* 6b – passes created by someone entering or exiting the pits */
                WHEN EXISTS (SELECT 1 FROM pit_stops ps
                               WHERE ps.race_id = nb.race_id
                                 AND ps.driver_id = nb.ahead_driver
                                 AND ps.lap       = nb.lap)        -- ahead car pitted  NOW
                  OR EXISTS (SELECT 1 FROM pit_stops ps
                               WHERE ps.race_id = nb.race_id
                                 AND ps.driver_id = nb.behind_driver
                                 AND ps.lap       = nb.lap - 1)    -- behind car pitted PREV
                     THEN 'Pit‑stop'

                /* 6c – passes because the car in front retired          */
                WHEN EXISTS (SELECT 1 FROM retirements r
                               WHERE r.race_id  = nb.race_id
                                 AND r.driver_id = nb.ahead_driver
                                 AND r.lap       = nb.lap)          THEN 'Retirement'

                /* 6d – everything else = normal on‑track pass          */
                ELSE 'On‑track'
            END AS overtake_type
    FROM   newly_behind nb
),

unique_overtakes AS (                   -- 7. de‑duplicate (same pass can appear twice)
    SELECT DISTINCT race_id, lap, ahead_driver, behind_driver, overtake_type
    FROM   overtake_classified
)

SELECT   overtake_type,
         COUNT(*) AS overtake_count
FROM     unique_overtakes
GROUP BY overtake_type
ORDER BY overtake_count DESC;