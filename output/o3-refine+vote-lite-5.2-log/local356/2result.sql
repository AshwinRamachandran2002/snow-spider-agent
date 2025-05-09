WITH race_laps AS (
    /* positions on consecutive “Race” laps, ignoring the first lap */
    SELECT
        lp."race_id",
        lp."driver_id",
        lp."lap",
        lp."position",
        LAG(lp."position") OVER (
            PARTITION BY lp."race_id", lp."driver_id"
            ORDER BY lp."lap"
        ) AS prev_position
    FROM "lap_positions" lp
    WHERE lp."lap_type" = 'Race'
      AND lp."lap" > 1
),
clean_laps AS (
    /* throw away laps affected by any pit‑stop or retirement */
    SELECT rl.*
    FROM race_laps rl
    WHERE rl.prev_position IS NOT NULL
      AND NOT EXISTS (          -- any pit‑stop on this lap
            SELECT 1
            FROM "pit_stops" ps
            WHERE ps."race_id" = rl."race_id"
              AND ps."lap"     = rl."lap"
      )
      AND NOT EXISTS (          -- any retirement on this lap
            SELECT 1
            FROM "retirements" r
            WHERE r."race_id" = rl."race_id"
              AND r."lap"     = rl."lap"
      )
),
driver_overtake_stats AS (
    /* count gains (overtakes) and losses (being overtaken) */
    SELECT
        driver_id,
        SUM(CASE WHEN prev_position  > position THEN 1 ELSE 0 END) AS overtakes_made,
        SUM(CASE WHEN prev_position  < position THEN 1 ELSE 0 END) AS overtaken_on_track
    FROM clean_laps
    GROUP BY driver_id
)
SELECT
    de."full_name"
FROM driver_overtake_stats dos
JOIN "drivers_ext" de USING (driver_id)
WHERE dos.overtaken_on_track > dos.overtakes_made
ORDER BY de."full_name";