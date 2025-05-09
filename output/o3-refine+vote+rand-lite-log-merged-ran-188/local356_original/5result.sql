WITH lap_pairs AS (
    /* Compare every driver’s successive laps (skip grid‑to‑lap‑1 ‘start’ movement) */
    SELECT
        l1.race_id,
        l1.driver_id,
        l1.lap  AS lap_prev,
        l2.lap  AS lap_curr,
        l1.position AS pos_prev,
        l2.position AS pos_curr
    FROM lap_positions l1
    JOIN lap_positions l2
      ON l2.race_id   = l1.race_id
     AND l2.driver_id = l1.driver_id
     AND l2.lap       = l1.lap + 1
    WHERE l1.lap > 0                -- ignore start movement (lap‑0 → lap‑1)
),
clean_pairs AS (
    /* Remove laps affected by any pit stop or retirement */
    SELECT
        lp.*,
        (lp.pos_curr - lp.pos_prev) AS delta
    FROM lap_pairs lp
    LEFT JOIN (
        SELECT DISTINCT race_id, lap
        FROM pit_stops
    ) ps
      ON ps.race_id = lp.race_id
     AND ps.lap     = lp.lap_curr
    LEFT JOIN (
        SELECT DISTINCT race_id, lap
        FROM retirements
    ) rt
      ON rt.race_id = lp.race_id
     AND rt.lap     = lp.lap_curr
    WHERE ps.race_id IS NULL        -- no pit stop on that finishing lap
      AND rt.race_id IS NULL        -- no retirement on that finishing lap
),
driver_totals AS (
    /* Count overtakes made vs. times being overtaken */
    SELECT
        driver_id,
        SUM(CASE WHEN delta < 0 THEN -delta ELSE 0 END) AS overtakes_made,
        SUM(CASE WHEN delta > 0 THEN  delta ELSE 0 END) AS times_overtaken
    FROM clean_pairs
    GROUP BY driver_id
),
overtaken_more AS (
    /* Drivers who lost more positions than they gained on‑track */
    SELECT driver_id
    FROM driver_totals
    WHERE times_overtaken > overtakes_made
)
SELECT d.full_name
FROM drivers_ext d
JOIN overtaken_more om USING (driver_id)
ORDER BY d.full_name;