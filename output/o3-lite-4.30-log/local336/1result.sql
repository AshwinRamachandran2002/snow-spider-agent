WITH
    race_id_val AS (SELECT 1 AS race_id),               -- change this to analyse another race
    /* 1. Overtakes created by retirements (simply count retirements ≤ lap 5) */
    retirement_ct AS (
        SELECT COUNT(*) AS cnt
        FROM retirements
        WHERE race_id = (SELECT race_id FROM race_id_val)
          AND lap BETWEEN 1 AND 5
    ),
    /* 2. Overtakes created by pit‑stops (count pit‑stops ≤ lap 5) */
    pit_ct AS (
        SELECT COUNT(*) AS cnt
        FROM pit_stops
        WHERE race_id = (SELECT race_id FROM race_id_val)
          AND lap BETWEEN 1 AND 5
    ),
    /* 3. Start‑phase overtakes: sum of positions gained from grid ➜ lap 1 */
    start_ct AS (
        SELECT COALESCE(SUM(r.grid - p.position),0) AS cnt
        FROM results        r
        JOIN lap_positions  p
          ON p.race_id   = r.race_id
         AND p.driver_id = r.driver_id
        WHERE r.race_id = (SELECT race_id FROM race_id_val)
          AND p.lap = 1
          AND p.position < r.grid                  -- only drivers who moved forward
    ),
    /* 4. Standard on‑track passes between laps 1‑5 (exclude starts/pits/retirements) */
    ontrack_ct AS (
        WITH
            pos_chg AS (          -- all lap‑to‑lap changes (laps 1‑5)
                SELECT lp1.driver_id,
                       lp1.lap
                FROM lap_positions lp1
                JOIN lap_positions lp0
                  ON lp1.race_id   = lp0.race_id
                 AND lp1.driver_id = lp0.driver_id
                 AND lp1.lap       = lp0.lap + 1
                WHERE lp1.race_id = (SELECT race_id FROM race_id_val)
                  AND lp1.lap BETWEEN 1 AND 5
                  AND lp1.position <> lp0.position
            ),
            pit_evt AS (
                SELECT driver_id, lap
                FROM pit_stops
                WHERE race_id = (SELECT race_id FROM race_id_val)
                  AND lap BETWEEN 1 AND 5
            ),
            dnf_evt AS (
                SELECT driver_id, lap
                FROM retirements
                WHERE race_id = (SELECT race_id FROM race_id_val)
                  AND lap BETWEEN 1 AND 5
            )
        SELECT COUNT(*) AS cnt
        FROM pos_chg pc
        LEFT JOIN pit_evt USING (driver_id, lap)
        LEFT JOIN dnf_evt USING (driver_id, lap)
        WHERE pit_evt.driver_id IS NULL
          AND dnf_evt.driver_id IS NULL
    )
SELECT 'Retirements'        AS overtake_type, (SELECT cnt FROM retirement_ct) AS overtake_count
UNION ALL
SELECT 'Pit stops',          (SELECT cnt FROM pit_ct)
UNION ALL
SELECT 'Start-related',      (SELECT cnt FROM start_ct)
UNION ALL
SELECT 'Standard on-track',  (SELECT cnt FROM ontrack_ct);