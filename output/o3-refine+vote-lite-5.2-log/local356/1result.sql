WITH race_laps AS (
    /*  Every lap position together with the previous lap (for the same driver & race)  */
    SELECT
        lp.race_id,
        lp.driver_id,
        lp.lap,
        lp.position,
        lp.lap_type,
        LAG(lp.position)  OVER (PARTITION BY lp.race_id, lp.driver_id ORDER BY lp.lap) AS prev_position,
        LAG(lp.lap_type)  OVER (PARTITION BY lp.race_id, lp.driver_id ORDER BY lp.lap) AS prev_lap_type
    FROM lap_positions lp
),
position_changes AS (
    /*  Keep only pure race‑lap movements (exclude grid, pit‑in/out, retirement, etc.)  */
    SELECT
        driver_id,
        position - prev_position AS diff        --  >0 = lost places, <0 = gained places
    FROM race_laps
    WHERE lap_type      = 'Race'              -- current lap is a race lap
      AND prev_lap_type = 'Race'              -- previous recorded lap is also a race lap
      AND prev_position IS NOT NULL           -- need a comparison value
),
overtake_totals AS (
    /*  Aggregate gains vs. losses for every driver                         */
    SELECT
        driver_id,
        SUM(CASE WHEN diff < 0 THEN -diff ELSE 0 END) AS overtakes_made,
        SUM(CASE WHEN diff > 0 THEN  diff ELSE 0 END) AS times_overtaken
    FROM position_changes
    GROUP BY driver_id
),
drivers_beaten_more_often AS (
    /*  Drivers who’ve been overtaken more times than they have overtaken   */
    SELECT driver_id
    FROM overtake_totals
    WHERE times_overtaken > overtakes_made
)
SELECT
    COALESCE(de.full_name, d.forename || ' ' || d.surname) AS full_name
FROM drivers_beaten_more_often db
JOIN drivers      d  ON d.driver_id  = db.driver_id
LEFT JOIN drivers_ext de ON de.driver_id = db.driver_id
ORDER BY full_name;