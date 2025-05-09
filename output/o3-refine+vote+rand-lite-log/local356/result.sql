WITH race_lap_positions AS (
    -- keep only normal race–lap position samples
    SELECT  lp.race_id ,
            lp.driver_id ,
            lp.lap ,
            lp.position
    FROM    lap_positions AS lp
    WHERE   lp.lap_type = 'Race'
),
lap_deltas AS (
    -- compare every lap with the previous one for the same driver‑race
    SELECT  race_id ,
            driver_id ,
            lap ,
            position ,
            LAG(position) OVER (PARTITION BY race_id , driver_id
                                ORDER BY lap)               AS prev_position
    FROM    race_lap_positions
),
lap_changes AS (
    -- convert the positional difference into a signed “delta”
    --   positive  = positions gained  (overtakes made)
    --   negative  = positions lost    (got overtaken)
    SELECT  race_id ,
            driver_id ,
            lap ,
            (prev_position - position) AS delta
    FROM    lap_deltas
    WHERE   prev_position IS NOT NULL      -- ignore the very first sample
      AND   lap > 1                        -- exclude start‑lap movements
),
excluded_laps AS (
    -- laps affected by pit stops or retirements
    SELECT DISTINCT race_id , lap FROM pit_stops
    UNION
    SELECT DISTINCT race_id , lap FROM retirements
),
clean_changes AS (
    -- keep only genuine on‑track position changes
    SELECT  lc.*
    FROM    lap_changes AS lc
    LEFT JOIN excluded_laps AS el
           ON  lc.race_id = el.race_id
           AND lc.lap     = el.lap
    WHERE   el.lap IS NULL                 -- drop laps to be ignored
),
driver_totals AS (
    -- aggregate gains and losses for each driver
    SELECT  driver_id,
            SUM(CASE WHEN delta > 0 THEN  delta ELSE 0 END)   AS overtakes_made,
            SUM(CASE WHEN delta < 0 THEN -delta ELSE 0 END)   AS times_overtaken
    FROM    clean_changes
    GROUP BY driver_id
)
-- drivers who got passed more than they passed others
SELECT  de.full_name
FROM    driver_totals AS dt
JOIN    drivers_ext  AS de
       USING (driver_id)
WHERE   dt.times_overtaken > dt.overtakes_made
ORDER BY de.full_name;