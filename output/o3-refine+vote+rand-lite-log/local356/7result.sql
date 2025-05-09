WITH race_laps AS (
    /* keep only normal race‑lap position records (ignore grid, pits, etc.)
       and skip the first racing lap (lap = 1) because that reflects the start */
    SELECT
        lp.race_id,
        lp.driver_id,
        lp.lap,
        lp.position
    FROM lap_positions lp
    WHERE lp.lap_type = 'Race'
      AND lp.lap > 1
),
lap_deltas AS (
    /* compare each lap with the immediately previous racing lap
       (both laps must be of type 'Race')                                   */
    SELECT
        cur.driver_id,
        cur.race_id,
        cur.lap,
        prev.position  AS prev_pos,
        cur.position   AS cur_pos
    FROM race_laps  cur
    JOIN lap_positions prev
         ON prev.race_id  = cur.race_id
        AND prev.driver_id = cur.driver_id
        AND prev.lap       = cur.lap - 1
        AND prev.lap_type  = 'Race'
    /* discard laps in which a retirement happened (position changes caused
       by a retirement are not counted as on‑track overtakes)               */
    LEFT JOIN retirements r
           ON r.race_id = cur.race_id
          AND r.lap     = cur.lap
    WHERE r.race_id IS NULL
),
driver_overtake_totals AS (
    /* classify every delta as an ‘overtake’ (position number goes down)
       or ‘being overtaken’ (position number goes up) and total them        */
    SELECT
        driver_id,
        SUM(CASE WHEN prev_pos  > cur_pos THEN 1 ELSE 0 END) AS overtakes,
        SUM(CASE WHEN prev_pos  < cur_pos THEN 1 ELSE 0 END) AS overtaken
    FROM lap_deltas
    GROUP BY driver_id
)
SELECT
    COALESCE(de.full_name,
             d.forename || ' ' || d.surname) AS full_name
FROM driver_overtake_totals tot
LEFT JOIN drivers_ext de ON de.driver_id = tot.driver_id
LEFT JOIN drivers     d  ON d.driver_id  = tot.driver_id
WHERE tot.overtaken > tot.overtakes          -- net negative on‑track passes
ORDER BY full_name;