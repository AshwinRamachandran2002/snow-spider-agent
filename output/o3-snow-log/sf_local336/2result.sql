WITH
/* -------------------------------------------------
   Starting-grid positions (virtual lap 0)
--------------------------------------------------*/
grid AS (
    SELECT
        "race_id",
        "driver_id",
        COALESCE(NULLIF("grid",0), 999)      AS "grid"   -- treat grid 0 (pit-lane start) as very far back
    FROM F1.F1.RESULTS
),

/* -------------------------------------------------
   Driver positions for laps 0-5
--------------------------------------------------*/
positions AS (
    /* lap 0 = grid */
    SELECT
        "race_id",
        0                         AS "lap",
        "driver_id",
        "grid"                    AS "position"
    FROM grid

    UNION ALL

    /* real race laps */
    SELECT
        "race_id",
        "lap",
        "driver_id",
        "position"
    FROM F1.F1.LAP_POSITIONS
    WHERE "lap_type" = 'Race'
      AND "lap"     BETWEEN 1 AND 5
),

/* -------------------------------------------------
   All position-crossings between consecutive laps
--------------------------------------------------*/
crossings AS (
    /*  p_curr : position on lap L      (1-5)
        p_prev : position on lap L - 1 */
    SELECT
        p_curr."race_id",
        p_curr."lap",                             -- the lap on which the overtake happened
        p_curr."driver_id"         AS "overtaker_id",
        p_other_prev."driver_id"   AS "overtaken_id"
    FROM positions            p_curr
    JOIN positions            p_prev
         ON p_curr."race_id"   = p_prev."race_id"
        AND p_curr."driver_id" = p_prev."driver_id"
        AND p_curr."lap"       = p_prev."lap" + 1               -- consecutive laps

    /* driver that was ahead on the previous lap … */
    JOIN positions            p_other_prev
         ON p_prev."race_id"  = p_other_prev."race_id"
        AND p_prev."lap"      = p_other_prev."lap"

    /* … and is now behind on the current lap                */
    JOIN positions            p_other_curr
         ON p_curr."race_id"   = p_other_curr."race_id"
        AND p_curr."lap"       = p_other_curr."lap"
        AND p_other_prev."driver_id" = p_other_curr."driver_id"

    WHERE p_prev."position"  >  p_other_prev."position"         -- was behind
      AND p_curr."position"  <  p_other_curr."position"         -- is now ahead
),

/* -------------------------------------------------
   Classify every overtake
--------------------------------------------------*/
classified AS (
    SELECT
        c."race_id",
        c."lap",
        c."overtaker_id",
        c."overtaken_id",

        CASE
            /* 1. Retirement on the same lap                             */
            WHEN EXISTS (
                     SELECT 1
                     FROM F1.F1.RETIREMENTS r
                     WHERE r."race_id" = c."race_id"
                       AND r."driver_id" = c."overtaken_id"
                       AND r."lap"       = c."lap"
                 )
            THEN 'R'

            /* 2. Pit-stop by the overtaken driver (same or previous lap) */
            WHEN EXISTS (
                     SELECT 1
                     FROM F1.F1.PIT_STOPS p
                     WHERE p."race_id"   = c."race_id"
                       AND p."driver_id" = c."overtaken_id"
                       AND p."lap" IN (c."lap", c."lap" - 1)
                 )
            THEN 'P'

            /* 3. Start-lap overtake (lap 1, grid positions ≤ 2 apart)   */
            WHEN c."lap" = 1
             AND ABS(g1."grid" - g2."grid") <= 2
            THEN 'S'

            /* 4. Standard on-track pass                                 */
            ELSE 'T'
        END AS "category"
    FROM crossings c
    JOIN grid g1  ON g1."race_id" = c."race_id" AND g1."driver_id" = c."overtaker_id"
    JOIN grid g2  ON g2."race_id" = c."race_id" AND g2."driver_id" = c."overtaken_id"
)

/* -------------------------------------------------
   Count overtakes in the first five laps by category
--------------------------------------------------*/
SELECT
    "category",
    COUNT(*) AS "overtake_count_first_5_laps"
FROM classified
GROUP BY "category"
ORDER BY "category";