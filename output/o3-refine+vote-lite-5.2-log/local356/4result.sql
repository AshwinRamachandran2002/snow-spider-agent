WITH
/* 1.  laps where any pit‑stop happened (entry/exit are recorded with the same lap number) */
pit_laps AS (
    SELECT DISTINCT race_id, lap
    FROM pit_stops
),
/* 2. laps in which a retirement happened */
retire_laps AS (
    SELECT DISTINCT race_id, lap
    FROM retirements
),
/* 3. every consecutive‑lap position change for a driver,
      ignoring the first lap (grid/start movements)          */
lap_changes AS (
    SELECT
        lp.race_id,
        lp.driver_id,
        lp.lap,
        lp.position                                    AS pos_curr,
        LAG(lp.position) OVER (
            PARTITION BY lp.race_id, lp.driver_id
            ORDER BY lp.lap
        )                                              AS pos_prev
    FROM lap_positions lp
    WHERE lp.lap_type = 'Race'      -- on‑track race laps only
      AND lp.lap     > 1            -- skip the first lap (start movements)
),
/* 4. keep only genuine on‑track position changes:
         – drop laps influenced by any pit‑stop (current or previous lap)
         – drop laps in which a retirement occurred                      */
filtered_changes AS (
    SELECT
        lc.*,
        lc.pos_curr - lc.pos_prev AS delta                -- +ve = lost places, –ve = gained places
    FROM lap_changes lc
    WHERE lc.pos_prev IS NOT NULL
      AND NOT EXISTS (        -- exclude laps affected by pit‑stops
            SELECT 1
            FROM pit_laps pl
            WHERE pl.race_id = lc.race_id
              AND (pl.lap = lc.lap OR pl.lap = lc.lap - 1)
      )
      AND NOT EXISTS (        -- exclude laps with retirements
            SELECT 1
            FROM retire_laps rl
            WHERE rl.race_id = lc.race_id
              AND rl.lap     = lc.lap
      )
),
/* 5. accumulate overtakes made vs. being overtaken for every driver */
driver_totals AS (
    SELECT
        driver_id,
        SUM(CASE WHEN delta < 0 THEN -delta ELSE 0 END) AS overtakes_made,
        SUM(CASE WHEN delta > 0 THEN  delta ELSE 0 END) AS overtaken
    FROM filtered_changes
    GROUP BY driver_id
)
/* 6. drivers who were overtaken more times than they overtook others */
SELECT DISTINCT d.full_name
FROM driver_totals dt
JOIN drivers_ext  d ON d.driver_id = dt.driver_id
WHERE dt.overtaken > dt.overtakes_made
ORDER BY d.full_name;