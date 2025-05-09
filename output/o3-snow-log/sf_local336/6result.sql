/*  Count overtakes (first five laps) by category:
      R – Retirement
      P – Pit-stop
      S – Start lap
      T – Normal track pass                                          */

WITH
/* starting grid is treated as lap 0                                 */
"GRID_POS" AS (
    SELECT  "race_id",
            "driver_id",
            0                AS "lap",
            "grid"           AS "position"
    FROM    F1.F1.RESULTS
    WHERE   "grid" IS NOT NULL
),
/* race‐lap positions we need (laps 1-5 only)                        */
"LAP_POS" AS (
    SELECT  "race_id",
            "driver_id",
            "lap",
            "position"
    FROM    F1.F1.LAP_POSITIONS
    WHERE   "lap_type" = 'Race'
      AND   "lap" BETWEEN 1 AND 5
),
/* complete ordered position history for the first five laps         */
"ALL_POS" AS (
    SELECT * FROM "GRID_POS"
    UNION ALL
    SELECT * FROM "LAP_POS"
),
/* positions lost between consecutive laps (one lost place = 1 pass) */
"LOSSES" AS (
    SELECT  c."race_id",
            c."driver_id",
            c."lap",                              -- current lap (where loss happened)
            c."position" - p."position" AS "loss_positions"
    FROM    "ALL_POS"       c
    JOIN    "ALL_POS"       p
           ON p."race_id"   = c."race_id"
          AND p."driver_id" = c."driver_id"
          AND p."lap"       = c."lap" - 1        -- previous lap
    WHERE   c."lap" <= 5                         -- limit to first five completed laps
      AND   c."position"  > p."position"         -- driver dropped places
),
/* classify every lost place                                              */
"LOSSES_WITH_CAT" AS (
    SELECT  l."loss_positions",
            CASE
                /* retirement on the same lap                               */
                WHEN EXISTS (
                       SELECT 1
                       FROM   F1.F1.RETIREMENTS r
                       WHERE  r."race_id"   = l."race_id"
                         AND  r."driver_id" = l."driver_id"
                         AND  r."lap"       = l."lap"
                ) THEN 'R'
                /* pit-stop on the same lap                                  */
                WHEN EXISTS (
                       SELECT 1
                       FROM   F1.F1.PIT_STOPS p
                       WHERE  p."race_id"   = l."race_id"
                         AND  p."driver_id" = l."driver_id"
                         AND  p."lap"       = l."lap"
                ) THEN 'P'
                /* first-lap (grid->lap1) losses                             */
                WHEN l."lap" = 1 THEN 'S'
                /* normal on-track pass                                      */
                ELSE 'T'
            END AS "category"
    FROM   "LOSSES" l
),
/* sum lost places (each = one overtake) per category                       */
"SUMMARY" AS (
    SELECT  "category",
            SUM("loss_positions") AS "overtakes"
    FROM    "LOSSES_WITH_CAT"
    GROUP BY "category"
)
/* ensure all four categories appear, even if zero                          */
SELECT  ca."category",
        COALESCE(s."overtakes", 0) AS "overtakes"
FROM   (SELECT 'R' AS "category"
        UNION ALL SELECT 'P'
        UNION ALL SELECT 'S'
        UNION ALL SELECT 'T') ca
LEFT  JOIN "SUMMARY" s
       ON s."category" = ca."category"
ORDER BY ca."category";