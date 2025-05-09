WITH position_changes AS (
    /* 1. Every instance where a driver was ahead on lap n
          but is now behind on lap n+1, restricted to races
          that contain pit-stop data                                */
    SELECT
        l1."race_id",
        l1."driver_id",
        l1."lap"        AS "prev_lap",
        l2."lap"        AS "curr_lap"
    FROM   "lap_positions" AS l1
    JOIN   "lap_positions" AS l2
           ON  l2."race_id"   = l1."race_id"
           AND l2."driver_id" = l1."driver_id"
           AND l2."lap"       = l1."lap" + 1
    JOIN   "races_ext"  AS re
           ON  re."race_id"              = l1."race_id"
           AND re."is_pit_data_available" = 1
    WHERE  l1."position" < l2."position"          -- lost positions
), classified AS (
    /* 2. Classify each position-loss event                        */
    SELECT
        CASE
            WHEN pc."prev_lap" = 0                                             THEN 'Race Start'
            WHEN EXISTS ( SELECT 1
                           FROM "pit_stops" ps
                          WHERE ps."race_id"   = pc."race_id"
                            AND ps."driver_id" = pc."driver_id"
                            AND ps."lap"       = pc."curr_lap")                THEN 'Pit Entry'
            WHEN EXISTS ( SELECT 1
                           FROM "pit_stops" ps
                          WHERE ps."race_id"   = pc."race_id"
                            AND ps."driver_id" = pc."driver_id"
                            AND ps."lap"       = pc."prev_lap")                THEN 'Pit Exit'
            WHEN EXISTS ( SELECT 1
                           FROM "retirements" r
                          WHERE r."race_id"   = pc."race_id"
                            AND r."driver_id" = pc."driver_id"
                            AND r."lap"       = pc."curr_lap")                 THEN 'Retirement'
            ELSE                                                                   'On Track'
        END AS "overtake_type"
    FROM position_changes pc
)
SELECT
    "overtake_type",
    COUNT(*) AS "num_overtakes"
FROM   classified
GROUP  BY "overtake_type"
ORDER  BY "num_overtakes" DESC;