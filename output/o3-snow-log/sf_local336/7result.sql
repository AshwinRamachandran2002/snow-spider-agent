/* ---------------------------------------------------------
   OVERTAKE COUNTS (FIRST FIVE LAPS – ALL RACES)
   ---------------------------------------------------------
   R – Retirement            : overtaken driver retires on the same lap
   P – Pit‐stop related      : overtaken driver pits on the same lap or the
                               previous lap
   S – Start overtake        : lap 1 pass between drivers whose grid slots
                               differed by at most two positions
   T – Normal track overtake : none of the above conditions apply
   --------------------------------------------------------- */
WITH
/* -------------------------------
   Grid positions (lap 0 snapshot)
   ------------------------------- */
grid AS (
    SELECT
        "race_id",
        "driver_id",
        "grid"        AS "position",
        0             AS "lap"
    FROM F1.F1.RESULTS
    WHERE "grid" IS NOT NULL
),
/* -------------------------------------------
   Race positions for laps 1 – 5 (inclusive)
   ------------------------------------------- */
race_laps AS (
    SELECT
        "race_id",
        "driver_id",
        "position",
        "lap"
    FROM F1.F1.LAP_POSITIONS
    WHERE "lap_type" = 'Race'
      AND "lap"      BETWEEN 1 AND 5
),
/* -------------------------------------------------
   Unified position snapshots (lap 0 + laps 1 – 5)
   ------------------------------------------------- */
positions AS (
    SELECT * FROM grid
    UNION ALL
    SELECT * FROM race_laps
),
/* -----------------------------------------------------------------
   Identify every driver-pair (overtaker / overtaken) for which the
   relative order swaps between consecutive laps (0→1, 1→2, …, 4→5)
   ----------------------------------------------------------------- */
overtakes AS (
    SELECT
        prev_a."race_id",
        curr_a."lap",                       -- current lap (1-5)
        curr_a."driver_id"  AS "overtaker_driver_id",
        curr_b."driver_id"  AS "overtaken_driver_id"
    FROM positions prev_a
    JOIN positions curr_a
      ON curr_a."race_id" = prev_a."race_id"
     AND curr_a."driver_id" = prev_a."driver_id"
     AND curr_a."lap"       = prev_a."lap" + 1         -- consecutive laps
    /* the (possible) rival’s positions in the same two laps */
    JOIN positions prev_b
      ON prev_b."race_id" = prev_a."race_id"
     AND prev_b."lap"     = prev_a."lap"
    JOIN positions curr_b
      ON curr_b."race_id" = prev_a."race_id"
     AND curr_b."driver_id" = prev_b."driver_id"
     AND curr_b."lap"       = curr_a."lap"
    /* a was behind b in previous lap but is ahead in current lap  */
    WHERE prev_a."position" > prev_b."position"
      AND curr_a."position" < curr_b."position"
),
/* --------------------------------------------
   Classify each overtake according to the rules
   -------------------------------------------- */
classified AS (
    SELECT
        o."race_id",
        o."lap",
        o."overtaker_driver_id",
        o."overtaken_driver_id",
        CASE
            /* R – Retirement on the same lap */
            WHEN r."driver_id" IS NOT NULL                                THEN 'R'

            /* P – Pit-stop on the same or previous lap                  */
            WHEN ps_same."driver_id" IS NOT NULL
              OR ps_prev."driver_id" IS NOT NULL                          THEN 'P'

            /* S – Start overtake (lap 1, grid difference ≤ 2)            */
            WHEN o."lap" = 1
             AND ABS(g_taker."position" - g_taken."position") <= 2        THEN 'S'

            /* T – Standard on-track pass                                */
            ELSE 'T'
        END AS "category"
    FROM overtakes o
    /* retirement of the overtaken driver on the same lap  */
    LEFT JOIN F1.F1.RETIREMENTS r
      ON r."race_id" = o."race_id"
     AND r."driver_id" = o."overtaken_driver_id"
     AND r."lap"       = o."lap"

    /* pit-stop of the overtaken driver on the same lap     */
    LEFT JOIN F1.F1.PIT_STOPS ps_same
      ON ps_same."race_id" = o."race_id"
     AND ps_same."driver_id" = o."overtaken_driver_id"
     AND ps_same."lap"       = o."lap"

    /* pit-stop of the overtaken driver on the previous lap */
    LEFT JOIN F1.F1.PIT_STOPS ps_prev
      ON ps_prev."race_id" = o."race_id"
     AND ps_prev."driver_id" = o."overtaken_driver_id"
     AND ps_prev."lap"       = o."lap" - 1

    /* grid positions (lap 0) for start-overtake check      */
    LEFT JOIN grid g_taker
      ON g_taker."race_id" = o."race_id"
     AND g_taker."driver_id" = o."overtaker_driver_id"
    LEFT JOIN grid g_taken
      ON g_taken."race_id" = o."race_id"
     AND g_taken."driver_id" = o."overtaken_driver_id"
)
/* ------------------------------
   Final tally by overtake class
   ------------------------------ */
SELECT
    "category",
    COUNT(*) AS "num_overtakes"
FROM classified
GROUP BY "category"
ORDER BY "category";