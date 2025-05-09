WITH pass_events AS (
    /* only races that contain full pit‑stop information            */
    SELECT
           r."race_id",
           cur."lap",
           cur."driver_id"  AS behind_driver_id,      -- driver that is now behind
           oth_cur."driver_id" AS ahead_driver_id,    -- driver now ahead
           cur."lap_type"    AS cur_lap_type,
           prev."lap_type"   AS prev_lap_type,
           prev."lap"        AS prev_lap_number,
           CASE
                /* position‑changes that happen between the grid (lap 0) and lap 1 */
                WHEN prev."lap" = 0 THEN 'Race start'
                
                /* driver that loses the place is entering the pit lane             */
                WHEN cur."lap_type" LIKE '%Pit In%'  THEN 'Pit‑stop entry'
                
                /* driver that loses the place has just exited the pit lane         */
                WHEN cur."lap_type" LIKE '%Pit Out%' THEN 'Pit‑stop exit'
                
                /* place change caused by a retirement / DNF                        */
                WHEN cur."lap_type" LIKE '%Retire%'  OR cur."lap_type" LIKE '%DNF%' 
                     THEN 'Retirement'
                
                /* anything else is treated as an on‑track overtake                 */
                ELSE 'On‑track'
           END                                     AS overtake_type
    FROM     "races_ext"     AS r
    JOIN     "lap_positions" AS cur
           ON cur."race_id" = r."race_id"
    JOIN     "lap_positions" AS prev
           ON prev."race_id"  = cur."race_id"
          AND prev."driver_id"= cur."driver_id"
          AND prev."lap"      = cur."lap" - 1
    /* the driver that is now ahead (and potentially being passed / passing)        */
    JOIN     "lap_positions" AS oth_cur
           ON oth_cur."race_id" = cur."race_id"
          AND oth_cur."lap"     = cur."lap"
          AND oth_cur."driver_id" <> cur."driver_id"
    JOIN     "lap_positions" AS oth_prev
           ON oth_prev."race_id"  = oth_cur."race_id"
          AND oth_prev."driver_id"= oth_cur."driver_id"
          AND oth_prev."lap"      = oth_cur."lap" - 1
    WHERE    r."is_pit_data_available" = 1              -- use only races with pit data
          /* driver was NOT behind the other car on the previous lap                */
      AND   prev."position" <= oth_prev."position"
          /* …but IS behind on the current lap                                      */
      AND   cur."position"  >  oth_cur."position"
),
/* each overtake (pair of drivers, lap, race) should be counted only once           */
unique_passes AS (
    SELECT DISTINCT
           "race_id", "lap", behind_driver_id, ahead_driver_id, overtake_type
    FROM   pass_events
)
SELECT   overtake_type,
         COUNT(*) AS total_overtakes
FROM     unique_passes
GROUP BY overtake_type
ORDER BY total_overtakes DESC;