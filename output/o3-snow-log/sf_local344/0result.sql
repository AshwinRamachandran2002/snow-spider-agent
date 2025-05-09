/*  Count how many times each type of over-take ( R , P , S , T ) has
    happened in races that have pit-stop data                                    */

WITH races_with_pit AS (          -- only look at races that contain pit data
    SELECT  "race_id"
    FROM    F1.F1.RACES_EXT
    WHERE   "is_pit_data_available" = 1
),

/* ------------------------------------------------------------------------- */
/* Every driver’s position on every lap of those races                       */
lap_pos AS (                       
    SELECT  lp."race_id",
            lp."lap",
            lp."driver_id",
            lp."position"
    FROM    F1.F1.LAP_POSITIONS lp
    JOIN    races_with_pit r
      ON    r."race_id" = lp."race_id"
    WHERE   lp."lap_type" = 'Race'
),

/* ------------------------------------------------------------------------- */
/* Grid positions act as “lap-0” so we can detect start-lap overtakes        */
start_grid AS (
    SELECT  res."race_id",
            res."driver_id",
            res."grid" AS "position"
    FROM    F1.F1.RESULTS res
    JOIN    races_with_pit rw
      ON    rw."race_id" = res."race_id"
    WHERE   res."grid" > 0                      -- ignore pit-lane starts (=0)
),

/* ------------------------------------------------------------------------- */
/* Build a ‘previous-lap’ table that lines up with the current-lap rows.     */
/* For lap=1 the “previous” positions come from the grid.                    */
prev_positions AS (
    /* previous lap => shift each lap forward by one so it lines up           */
    SELECT  lp."race_id",
            lp."lap" + 1        AS "lap",
            lp."driver_id",
            lp."position"
    FROM    lap_pos lp
    UNION ALL
    /* grid positions for lap-1 comparisons                                  */
    SELECT  sg."race_id",
            1                    AS "lap",
            sg."driver_id",
            sg."position"
    FROM    start_grid sg
),

current_positions AS (
    SELECT * FROM lap_pos        -- just a clearer alias
),

/* ------------------------------------------------------------------------- */
/* Identify every individual over-take event (who passed whom, where & when) */
overtake_events AS (
    /*  Driver A is ahead of Driver B on the current lap
        … but was behind Driver B on the previous lap  */
    SELECT
        cur1."race_id",
        cur1."lap",
        cur1."driver_id"  AS "overtaker_id",
        cur2."driver_id"  AS "overtaken_id"
    FROM  current_positions cur1
    JOIN  current_positions cur2
          ON  cur1."race_id" = cur2."race_id"
          AND cur1."lap"     = cur2."lap"
          AND cur1."position" < cur2."position"                -- A ahead now
    JOIN  prev_positions prev1
          ON  prev1."race_id"  = cur1."race_id"
          AND prev1."lap"      = cur1."lap"
          AND prev1."driver_id"= cur1."driver_id"
    JOIN  prev_positions prev2
          ON  prev2."race_id"  = cur2."race_id"
          AND prev2."lap"      = cur2."lap"
          AND prev2."driver_id"= cur2."driver_id"
    WHERE prev1."position" > prev2."position"                  -- A behind before
),

/* ------------------------------------------------------------------------- */
/* Label every event:  R = retirement, P = pit, S = start, T = normal track  */
overtakes_labeled AS (
    SELECT
        oe."race_id",
        oe."lap",
        oe."overtaker_id",
        oe."overtaken_id",

        CASE
            /* 1. Retirement : overtaken driver quits on that very lap        */
            WHEN rt."driver_id" IS NOT NULL
                 THEN 'R'

            /* 2. Pit : overtaken driver in pits this lap or previous lap     */
            WHEN ps."driver_id" IS NOT NULL
                 THEN 'P'

            /* 3. Start : lap-1 and the two drivers started within 2 grid rows */
            WHEN oe."lap" = 1
                 AND ABS( COALESCE(g1."position",99) - COALESCE(g2."position",99) ) <= 2
                 THEN 'S'

            /* 4. Everything else                                             */
            ELSE 'T'
        END AS "overtake_type"
    FROM  overtake_events oe

    /*  retirement of the overtaken driver on the same lap                    */
    LEFT JOIN F1.F1.RETIREMENTS rt
           ON rt."race_id"  = oe."race_id"
          AND rt."driver_id"= oe."overtaken_id"
          AND rt."lap"      = oe."lap"

    /*  pit stop of the overtaken driver ( same lap OR lap-1 )                */
    LEFT JOIN F1.F1.PIT_STOPS ps
           ON ps."race_id"  = oe."race_id"
          AND ps."driver_id"= oe."overtaken_id"
          AND ps."lap" IN (oe."lap", oe."lap" - 1)

    /*  grid positions for the “Start” rule                                   */
    LEFT JOIN start_grid g1
           ON g1."race_id"  = oe."race_id"
          AND g1."driver_id"= oe."overtaker_id"
    LEFT JOIN start_grid g2
           ON g2."race_id"  = oe."race_id"
          AND g2."driver_id"= oe."overtaken_id"
)

/* ------------------------------------------------------------------------- */
/* Final answer : total count for each over-take type                         */
SELECT   "overtake_type",
         COUNT(*) AS "num_overtakes"
FROM     overtakes_labeled
GROUP BY "overtake_type"
ORDER BY "overtake_type";