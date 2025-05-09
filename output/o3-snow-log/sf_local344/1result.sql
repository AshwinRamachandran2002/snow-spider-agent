WITH races_with_pit AS (          -- only races that have reliable pit-stop data
    SELECT "race_id"
    FROM   "F1"."F1"."RACES_EXT"
    WHERE  "is_pit_data_available" = 1
),

-- all race-laps for those events
lap_pos AS (
    SELECT lp."race_id",
           lp."lap",
           lp."driver_id",
           lp."position"
    FROM   "F1"."F1"."LAP_POSITIONS" lp
    JOIN   races_with_pit r
           ON r."race_id" = lp."race_id"
    WHERE  lp."lap_type" = 'Race'
),

-- same information split into “current” and “previous” lap views
curr_lap AS (
    SELECT "race_id",
           "lap",
           "driver_id",
           "position"           AS "pos_curr"
    FROM   lap_pos
),
prev_lap AS (
    SELECT "race_id",
           "lap" + 1            AS "lap",         -- align with following lap
           "driver_id",
           "position"           AS "pos_prev"
    FROM   lap_pos
),

-- merge current and previous lap for every driver
lap_change AS (
    SELECT c."race_id",
           c."lap",
           c."driver_id",
           p."pos_prev",
           c."pos_curr"
    FROM   curr_lap c
    JOIN   prev_lap p
           ON  p."race_id"   = c."race_id"
           AND p."lap"       = c."lap"
           AND p."driver_id" = c."driver_id"
),

/* driver A overtakes driver B when
   – A was behind B on the previous lap,
   – A is ahead of B on the current lap                      */
overtake_pairs AS (
    SELECT a."race_id",
           a."lap",
           a."driver_id"  AS "overtaker_id",
           b."driver_id"  AS "overtaken_id"
    FROM   lap_change a
    JOIN   lap_change b
           ON  b."race_id" = a."race_id"
           AND b."lap"     = a."lap"
           AND b."driver_id" <> a."driver_id"
    WHERE  a."pos_prev"  > b."pos_prev"    -- A was behind B
      AND  a."pos_curr"  < b."pos_curr"    -- A is now ahead
),

/* add information needed for the four labels
   R – same-lap retirement of the overtaken driver
   P – pit entry on same lap OR pit exit (pitted previous lap)
   S – first-lap pass where grid slots differed by ≤ 2
   T – everything else                                             */
classified AS (
    SELECT op.*,

           CASE
               WHEN r."driver_id" IS NOT NULL
                    THEN 'R'                                           -- Retirement
               WHEN (pe."driver_id" IS NOT NULL
                     OR px."driver_id" IS NOT NULL)
                    THEN 'P'                                           -- Pit entry/exit
               WHEN op."lap" = 1
                    AND ABS(ra."grid" - rb."grid") <= 2
                    THEN 'S'                                           -- Start
               ELSE 'T'                                                -- Track (normal)
           END AS "overtake_type"

    FROM   overtake_pairs                   op
    /* retirement on the same lap                                        */
    LEFT  JOIN "F1"."F1"."RETIREMENTS"   r
           ON  r."race_id"   = op."race_id"
           AND r."driver_id" = op."overtaken_id"
           AND r."lap"       = op."lap"

    /* pit entry (same lap)                                               */
    LEFT  JOIN "F1"."F1"."PIT_STOPS"     pe
           ON  pe."race_id"   = op."race_id"
           AND pe."driver_id" = op."overtaken_id"
           AND pe."lap"       = op."lap"

    /* pit exit (pitted the previous lap)                                 */
    LEFT  JOIN "F1"."F1"."PIT_STOPS"     px
           ON  px."race_id"   = op."race_id"
           AND px."driver_id" = op."overtaken_id"
           AND px."lap"       = op."lap" - 1

    /* grid positions for start-lap classification                        */
    LEFT  JOIN "F1"."F1"."RESULTS"       ra
           ON  ra."race_id"   = op."race_id"
           AND ra."driver_id" = op."overtaker_id"
    LEFT  JOIN "F1"."F1"."RESULTS"       rb
           ON  rb."race_id"   = op."race_id"
           AND rb."driver_id" = op."overtaken_id"
)

SELECT   "overtake_type",
         COUNT(*) AS "num_overtakes"
FROM     classified
GROUP BY "overtake_type"
ORDER BY "overtake_type";