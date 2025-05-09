/* -----------------------------------------------------------
   OVERTAKE COUNTS (R = Retirement, P = Pit, S = Start, T = Track)
   ----------------------------------------------------------- */
WITH 

/* 1. Races that have pit-stop information                           */
races_with_pit AS (
    SELECT "race_id"
    FROM   F1.F1."RACES_EXT"
    WHERE  "is_pit_data_available" = 1
),

/* 2. “Virtual” lap-0 built from the starting grid                   */
grid_positions AS (
    SELECT  r."race_id",
            res."driver_id",
            0              AS "lap",
            res."grid"     AS "position"
    FROM   races_with_pit  r
    JOIN   F1.F1."RESULTS" res
           ON res."race_id" = r."race_id"
),

/* 3. Real race-lap positions                                        */
race_lap_positions AS (
    SELECT  lp."race_id",
            lp."driver_id",
            lp."lap",
            lp."position"
    FROM    F1.F1."LAP_POSITIONS" lp
    JOIN    races_with_pit r
           ON r."race_id" = lp."race_id"
    WHERE   lp."lap_type" = 'Race'
),

/* 4. Combine grid (lap-0) with real laps                            */
all_positions AS (
    SELECT * FROM grid_positions
    UNION ALL
    SELECT * FROM race_lap_positions
),

/* 5. Position change for every driver lap-by-lap                    */
position_changes AS (
    SELECT  "race_id",
            "driver_id",
            "lap",
            "position",
            LAG("position") OVER (PARTITION BY "race_id",
                                             "driver_id"
                                  ORDER BY    "lap") AS "prev_position"
    FROM    all_positions
),

/* 6. Keep only laps where the driver LOST places                    */
lost_places AS (
    SELECT  pc."race_id",
            pc."driver_id",
            pc."lap",
            (pc."position" - pc."prev_position") AS "lost_places"
    FROM    position_changes pc
    WHERE   pc."prev_position" IS NOT NULL
      AND   pc."position" > pc."prev_position"            -- now BEHIND
),

/* 7. Classify each loss according to R / P / S / T rules            */
classified_overtakes AS (
    SELECT  lp."race_id",
            lp."driver_id",
            lp."lap",
            lp."lost_places",
            CASE
                /* R : overtaken driver retires on that lap          */
                WHEN ret."driver_id" IS NOT NULL
                     THEN 'R'

                /* P : pit-stop same lap (entry) or previous lap (exit) */
                WHEN ps_now."driver_id"  IS NOT NULL
                  OR ps_prev."driver_id" IS NOT NULL
                     THEN 'P'

                /* S : first-lap position losses                     */
                WHEN lp."lap" = 1
                     THEN 'S'

                /* T : normal on-track overtake                      */
                ELSE 'T'
            END AS "overtake_type"
    FROM   lost_places lp

    /* Retirement check                                              */
    LEFT  JOIN F1.F1."RETIREMENTS" ret
           ON ret."race_id"  = lp."race_id"
          AND ret."driver_id" = lp."driver_id"
          AND ret."lap"       = lp."lap"

    /* Pit-stop on the same lap (entry)                              */
    LEFT  JOIN F1.F1."PIT_STOPS" ps_now
           ON ps_now."race_id"  = lp."race_id"
          AND ps_now."driver_id" = lp."driver_id"
          AND ps_now."lap"       = lp."lap"

    /* Pit-stop on the previous lap (exit)                           */
    LEFT  JOIN F1.F1."PIT_STOPS" ps_prev
           ON ps_prev."race_id"  = lp."race_id"
          AND ps_prev."driver_id" = lp."driver_id"
          AND ps_prev."lap"       = lp."lap" - 1
)

/* 8. Final aggregation                                              */
SELECT   "overtake_type",
         SUM("lost_places") AS "overtake_count"
FROM     classified_overtakes
GROUP BY "overtake_type"
ORDER BY "overtake_count" DESC NULLS LAST;