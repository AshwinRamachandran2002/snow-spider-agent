/* -----------------------------------------------------------
   1.  Identify races that have complete pit-stop information
   2.  Detect every pairwise position swap that happens from one
       lap to the next (i.e. a true “overtake” event)
   3.  Classify each overtake as
          R – Retirement  (overtaken driver retires that lap)
          P – Pit         (overtaken driver pits this lap OR pitted
                           the previous lap → pit–lane exit)
          S – Start       (lap-1 pass, grid positions ≤ 2 apart)
          T – Track       (all remaining on-track passes)
   4.  Aggregate the total number of overtakes by class
----------------------------------------------------------- */
WITH races_with_pit AS (            -- races that have pit data
    SELECT  "race_id"
    FROM    F1.F1.RACES_EXT
    WHERE   "is_pit_data_available" = 1
),

lap_pos AS (                        -- lap-by-lap running order
    SELECT  lp."race_id",
            lp."lap",
            lp."driver_id",
            lp."position"
    FROM    F1.F1.LAP_POSITIONS lp
    JOIN    races_with_pit r
           ON r."race_id" = lp."race_id"
    WHERE   lp."lap_type" = 'Race'
),

/* Every position swap from lap-1 → lap                                     
   A driver B is an “overtaker” if:
        – previous lap : B   was behind  A   (pos higher number)
        – current  lap : B   is   ahead  A   (pos lower number)
*/
overtake_pairs AS (
    SELECT
        cur1."race_id",
        cur1."lap",
        cur1."driver_id"   AS "overtaker_id",
        cur2."driver_id"   AS "overtaken_id"
    FROM        lap_pos cur1
    JOIN        lap_pos cur2
           ON   cur1."race_id" = cur2."race_id"
          AND   cur1."lap"     = cur2."lap"
          AND   cur1."driver_id" <> cur2."driver_id"

    /* previous-lap rows for both drivers */
    JOIN        lap_pos prev1
           ON   prev1."race_id"  = cur1."race_id"
          AND   prev1."driver_id"= cur1."driver_id"
          AND   prev1."lap"      = cur1."lap" - 1
    JOIN        lap_pos prev2
           ON   prev2."race_id"  = cur2."race_id"
          AND   prev2."driver_id"= cur2."driver_id"
          AND   prev2."lap"      = cur2."lap" - 1

    /* swap condition: order reversed from prev-lap to current */
    WHERE prev1."position" > prev2."position"      -- B was behind A
      AND cur1."position"  < cur2."position"       -- B now ahead
),

/*  Add all data needed for classification  */
overtake_enriched AS (
    SELECT  o.*,

            /*  Retirement on the same lap (R)  */
            CASE 
                 WHEN  ret."driver_id" IS NOT NULL THEN 1
                 ELSE 0
            END       AS is_retirement,

            /*  Pit stop same lap or previous lap (P)  */
            CASE
                 WHEN  ps_same."driver_id" IS NOT NULL 
                    OR ps_prev."driver_id" IS NOT NULL THEN 1
                 ELSE 0
            END       AS is_pit_related,

            /*  Grid positions to evaluate start-lap passes (S) */
            res_ovt."grid"       AS grid_overtaker,
            res_ovk."grid"       AS grid_overtaken
    FROM        overtake_pairs o

    /*  --- Retirement join (overtaken driver) ---------------- */
    LEFT JOIN   F1.F1.RETIREMENTS      ret
           ON   ret."race_id"  = o."race_id"
          AND   ret."driver_id"= o."overtaken_id"
          AND   ret."lap"      = o."lap"

    /*  --- Pit-stop joins (overtaken driver) ----------------- */
    LEFT JOIN   F1.F1.PIT_STOPS        ps_same   -- pit entry
           ON   ps_same."race_id"  = o."race_id"
          AND   ps_same."driver_id"= o."overtaken_id"
          AND   ps_same."lap"      = o."lap"

    LEFT JOIN   F1.F1.PIT_STOPS        ps_prev   -- pit-lane exit
           ON   ps_prev."race_id"  = o."race_id"
          AND   ps_prev."driver_id"= o."overtaken_id"
          AND   ps_prev."lap"      = o."lap" - 1

    /*  --- Grid positions from RESULTS ----------------------- */
    LEFT JOIN   F1.F1.RESULTS          res_ovt     -- overtaker
           ON   res_ovt."race_id"  = o."race_id"
          AND   res_ovt."driver_id"= o."overtaker_id"

    LEFT JOIN   F1.F1.RESULTS          res_ovk     -- overtaken
           ON   res_ovk."race_id"  = o."race_id"
          AND   res_ovk."driver_id"= o."overtaken_id"
),

/* Final classification for every individual overtake */
classified AS (
    SELECT
        o."race_id",
        o."lap",
        o."overtaker_id",
        o."overtaken_id",

        CASE
             WHEN o.is_retirement = 1                         THEN 'R'          -- Retirement
             WHEN o.is_pit_related = 1                        THEN 'P'          -- Pit-stop
             WHEN o."lap" = 1 
                  AND ABS(o.grid_overtaker - o.grid_overtaken) <= 2             THEN 'S'  -- Start
             ELSE 'T'                                                         -- Track
        END AS "overtake_type"
    FROM   overtake_enriched o
)

/*  -----------------------------------------------------------
    Return the total number of overtakes of each category
----------------------------------------------------------- */
SELECT   "overtake_type",
         COUNT(*) AS "num_overtakes"
FROM     classified
GROUP BY "overtake_type"
ORDER BY "overtake_type";