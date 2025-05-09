/*  Count every instance in which a driver was ahead of another car on 
    lap n-1 but is behind on lap n, for all races that contain pit-stop
    data.  The reason for the position loss is categorised as

        • Start          – changes between the grid (lap 0) and lap 1
        • Retirement     – driver’s current-lap record is a retirement
        • Pit Stop Entry – driver came into the pits on the previous lap
        • Pit Stop Exit  – driver left the pits on the current lap
        • On Track       – none of the above (normal racing overtake)

    Each position lost counts as one overtake.                               */
WITH races_with_pit AS (                 -- only study races that have pit data
    SELECT DISTINCT "race_id"
    FROM "pit_stops"
),
lap_pairs AS (                           -- previous-lap vs current-lap records
    SELECT
        cur."race_id",
        cur."driver_id",
        prev."lap"         AS "prev_lap",
        prev."position"    AS "prev_pos",
        cur."lap"          AS "cur_lap",
        cur."position"     AS "cur_pos",
        prev."lap_type"    AS "prev_lap_type",
        cur."lap_type"     AS "cur_lap_type"
    FROM   "lap_positions" prev
    JOIN   "lap_positions" cur
           ON cur."race_id"  = prev."race_id"
          AND cur."driver_id"= prev."driver_id"
          AND cur."lap"      = prev."lap" + 1
    WHERE  cur."race_id" IN (SELECT "race_id" FROM races_with_pit)
      AND  cur."position"  > prev."position"          -- driver was overtaken
),
classify AS (                            -- assign a cause to every overtake
    SELECT
        lp.*,
        CASE
            WHEN lp."prev_lap" = 0
                 THEN 'Start'
            WHEN lp."cur_lap_type" LIKE 'Retirement%'
                 THEN 'Retirement'
            WHEN EXISTS (                       -- stopped on previous lap
                     SELECT 1
                     FROM   "pit_stops" ps
                     WHERE  ps."race_id"  = lp."race_id"
                       AND  ps."driver_id"= lp."driver_id"
                       AND  ps."lap"      = lp."prev_lap")
                 THEN 'Pit Stop Entry'
            WHEN EXISTS (                       -- stopped on current lap
                     SELECT 1
                     FROM   "pit_stops" ps
                     WHERE  ps."race_id"  = lp."race_id"
                       AND  ps."driver_id"= lp."driver_id"
                       AND  ps."lap"      = lp."cur_lap")
                 THEN 'Pit Stop Exit'
            ELSE 'On Track'
        END                                 AS "overtake_type",
        (lp."cur_pos" - lp."prev_pos")      AS "overtakes"   -- positions lost
    FROM lap_pairs lp
)
SELECT
    "overtake_type",
    SUM("overtakes") AS "total_overtakes"
FROM   classify
GROUP  BY "overtake_type"
ORDER  BY "total_overtakes" DESC;