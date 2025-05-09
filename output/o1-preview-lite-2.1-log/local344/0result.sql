WITH on_track_overtakes AS (
    SELECT COUNT(*) AS num
    FROM (
        SELECT lp_current."race_id", lp_current."driver_id", lp_current."lap"
        FROM "lap_positions" lp_current
        JOIN "lap_positions" lp_previous
          ON lp_current."race_id" = lp_previous."race_id"
          AND lp_current."driver_id" = lp_previous."driver_id"
          AND lp_current."lap" = lp_previous."lap" + 1
        LEFT JOIN "pit_stops" ps_current
          ON lp_current."race_id" = ps_current."race_id"
          AND lp_current."driver_id" = ps_current."driver_id"
          AND lp_current."lap" = ps_current."lap"
        LEFT JOIN "pit_stops" ps_previous
          ON lp_previous."race_id" = ps_previous."race_id"
          AND lp_previous."driver_id" = ps_previous."driver_id"
          AND lp_previous."lap" = ps_previous."lap"
        WHERE lp_current."position" < lp_previous."position"
          AND ps_current."stop" IS NULL
          AND ps_previous."stop" IS NULL
          AND NOT EXISTS (
              SELECT 1 FROM "retirements" r
              WHERE r."race_id" = lp_current."race_id"
                AND r."lap" = lp_current."lap"
          )
    )
),
pit_stop_overtakes AS (
    SELECT COUNT(*) AS num
    FROM (
        SELECT lp_current."race_id", lp_current."driver_id", lp_current."lap"
        FROM "lap_positions" lp_current
        JOIN "lap_positions" lp_previous
          ON lp_current."race_id" = lp_previous."race_id"
          AND lp_current."driver_id" = lp_previous."driver_id"
          AND lp_current."lap" = lp_previous."lap" + 1
        WHERE lp_current."position" < lp_previous."position"
          AND EXISTS (
              SELECT 1 FROM "pit_stops" ps
              WHERE ps."race_id" = lp_current."race_id"
                AND ps."lap" = lp_current."lap"
                AND ps."driver_id" = lp_current."driver_id"
          )
    )
),
overtakes_due_to_retirements AS (
    SELECT COUNT(*) AS num
    FROM (
        SELECT lp_current."race_id", lp_current."driver_id", lp_current."lap"
        FROM "lap_positions" lp_current
        JOIN "lap_positions" lp_previous
          ON lp_current."race_id" = lp_previous."race_id"
          AND lp_current."driver_id" = lp_previous."driver_id"
          AND lp_current."lap" = lp_previous."lap" + 1
        WHERE lp_current."position" < lp_previous."position"
          AND EXISTS (
              SELECT 1 FROM "retirements" r
              WHERE r."race_id" = lp_current."race_id"
                AND r."lap" = lp_current."lap"
          )
    )
),
overtakes_due_to_penalties AS (
    SELECT 0 AS num -- Exact counts require detailed data analysis and are not readily available
)
SELECT 'On-track overtakes' AS "Overtake_Type", num AS "Number_of_Times" FROM on_track_overtakes
UNION ALL
SELECT 'Pit stop overtakes', num FROM pit_stop_overtakes
UNION ALL
SELECT 'Overtakes due to retirements', num FROM overtakes_due_to_retirements
UNION ALL
SELECT 'Overtakes due to penalties', num FROM overtakes_due_to_penalties;