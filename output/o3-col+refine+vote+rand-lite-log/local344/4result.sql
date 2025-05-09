WITH races_with_pits AS (               -- only races that have pit-stop data
    SELECT DISTINCT "race_id"
    FROM   "pit_stops"
),

laps AS (                               -- every recorded lap-position in those races
    SELECT lp."race_id",
           lp."driver_id",
           lp."lap",
           lp."position",
           lp."lap_type"
    FROM   "lap_positions" lp
    WHERE  lp."race_id" IN (SELECT "race_id" FROM races_with_pits)
),

cur_prev AS (                           -- current lap vs. previous lap for same driver
    SELECT cur."race_id",
           cur."driver_id",
           cur."lap"                 AS "cur_lap",
           cur."position"            AS "cur_pos",
           prev."position"           AS "prev_pos",
           cur."lap_type"            AS "cur_type",
           prev."lap_type"           AS "prev_type"
    FROM   laps  cur
    JOIN   laps  prev
           ON  prev."race_id"   = cur."race_id"
           AND prev."driver_id" = cur."driver_id"
           AND prev."lap"       = cur."lap" - 1
),

overtake_events AS (                    -- classify the reason for every position-loss
    SELECT cp.*,
           (cp."cur_pos" - cp."prev_pos")                                AS "pos_delta",
           CASE
               WHEN cp."cur_type" LIKE 'Retirement%'                                              THEN 'Retirement'
               WHEN EXISTS ( SELECT 1 FROM "pit_stops" ps
                             WHERE ps."race_id"  = cp."race_id"
                               AND ps."driver_id"= cp."driver_id"
                               AND ps."lap"      = cp."cur_lap" )                                 THEN 'Pit Stop Entry'
               WHEN EXISTS ( SELECT 1 FROM "pit_stops" ps
                             WHERE ps."race_id"  = cp."race_id"
                               AND ps."driver_id"= cp."driver_id"
                               AND ps."lap"      = cp."cur_lap" - 1 )                             THEN 'Pit Stop Exit'
               WHEN cp."prev_type" LIKE 'Starting Position%'  AND cp."cur_type" = 'Race'          THEN 'Race Start'
               ELSE 'On-Track'
           END                                                                                   AS "overtake_type"
    FROM   cur_prev cp
)

SELECT   "overtake_type",
         SUM("pos_delta") AS "nbr_overtakes"      -- each lost place = one overtake
FROM     overtake_events
WHERE    "pos_delta" > 0                          -- count only laps where driver LOST places
GROUP BY "overtake_type"
ORDER BY "nbr_overtakes" DESC;