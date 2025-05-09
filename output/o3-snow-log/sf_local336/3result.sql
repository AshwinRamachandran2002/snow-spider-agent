WITH start_positions AS (      /* grid = virtual lap-0 positions                          */
    SELECT  "race_id",
            "driver_id",
            0            AS "lap",
            "grid"       AS "position"
    FROM    F1.F1.RESULTS
    WHERE   "grid" > 0
),                   
race_positions AS (            /* real lap positions for laps 1-5                        */
    SELECT  "race_id",
            "driver_id",
            "lap",
            "position"
    FROM    F1.F1.LAP_POSITIONS
    WHERE   "lap_type" = 'Race'
      AND   "lap"      <= 5
),                   
all_positions AS (             /* combine grid and real laps                             */
    SELECT * FROM start_positions
    UNION ALL
    SELECT * FROM race_positions
),                   
overtakes AS (                 /* detect every order flip between consecutive laps       */
    SELECT DISTINCT
           cur."race_id",
           cur."lap",
           cur."driver_id"  AS "overtaker_driver_id",
           oth."driver_id"  AS "overtaken_driver_id"
    FROM   all_positions          cur
    JOIN   all_positions          oth
           ON  cur."race_id" = oth."race_id"
           AND cur."lap"     = oth."lap"
           AND cur."driver_id" <> oth."driver_id"
    JOIN   all_positions          prev_cur
           ON  prev_cur."race_id"  = cur."race_id"
           AND prev_cur."driver_id"= cur."driver_id"
           AND prev_cur."lap"      = cur."lap" - 1
    JOIN   all_positions          prev_oth
           ON  prev_oth."race_id"  = oth."race_id"
           AND prev_oth."driver_id"= oth."driver_id"
           AND prev_oth."lap"      = oth."lap" - 1
    WHERE  cur."lap" BETWEEN 1 AND 5
      AND  prev_cur."position"  > prev_oth."position"   -- was behind
      AND  cur."position"       < oth."position"        -- now ahead
),                   
ret_flags AS (                 /* retirements on the same lap                            */
    SELECT DISTINCT "race_id", "driver_id", "lap"
    FROM   F1.F1.RETIREMENTS
    WHERE  "lap" BETWEEN 1 AND 5
),                   
pit_flags AS (                 /* pit-stop on same lap or previous lap                   */
    SELECT DISTINCT "race_id", "driver_id", "lap"
    FROM   F1.F1.PIT_STOPS
    WHERE  "lap" BETWEEN 0 AND 5
),                   
overtakes_categorised AS (     /* assign category with precedence R > P > S > T          */
    SELECT  o."race_id",
            o."lap",
            o."overtaker_driver_id",
            o."overtaken_driver_id",
            CASE
                WHEN r."driver_id" IS NOT NULL                                           THEN 'R'  -- Retirement
                WHEN p."driver_id" IS NOT NULL                                           THEN 'P'  -- Pit
                WHEN o."lap" = 1 
                     AND ABS(ro."grid" - rd."grid") <= 2                                  THEN 'S'  -- Start
                ELSE 'T'                                                                  -- Track
            END AS "category"
    FROM   overtakes o
    LEFT   JOIN ret_flags    r  ON r."race_id" = o."race_id"
                               AND r."driver_id" = o."overtaken_driver_id"
                               AND r."lap" = o."lap"
    LEFT   JOIN pit_flags    p  ON p."race_id" = o."race_id"
                               AND p."driver_id" = o."overtaken_driver_id"
                               AND p."lap" IN (o."lap", o."lap" - 1)
    LEFT   JOIN F1.F1.RESULTS ro ON ro."race_id" = o."race_id"
                                AND ro."driver_id" = o."overtaker_driver_id"
    LEFT   JOIN F1.F1.RESULTS rd ON rd."race_id" = o."race_id"
                                AND rd."driver_id" = o."overtaken_driver_id"
)                   
SELECT  "category",
        COUNT(*) AS "overtake_count"
FROM    overtakes_categorised
GROUP BY "category"
ORDER BY CASE "category"
            WHEN 'R' THEN 1
            WHEN 'P' THEN 2
            WHEN 'S' THEN 3
            WHEN 'T' THEN 4
         END;