WITH grid_positions AS (      /* lap “0” = starting grid */
    SELECT 
        "race_id",
        "driver_id",
        0          AS "lap",
        "grid"     AS "position"
    FROM F1.F1.RESULTS
    WHERE "grid" IS NOT NULL
),
race_lap_positions AS (       /* real laps, limited to the first five */
    SELECT 
        "race_id",
        "driver_id",
        "lap",
        "position"
    FROM F1.F1.LAP_POSITIONS
    WHERE "lap_type" = 'Race'
      AND "lap"      <= 5
),
all_positions AS (            /* union grid + first-five-lap positions */
    SELECT * FROM grid_positions
    UNION ALL
    SELECT * FROM race_lap_positions
),
/* ------------------------------------------------------------------ */
/* identify every position swap (= overtake) between consecutive laps */
overtake_pairs AS (
    SELECT
        currA."race_id",
        currA."lap",
        currA."driver_id" AS "overtaker_id",
        currB."driver_id" AS "overtaken_id"
    FROM all_positions currA
    JOIN all_positions prevA
         ON prevA."race_id"   = currA."race_id"
        AND prevA."driver_id" = currA."driver_id"
        AND prevA."lap"       = currA."lap" - 1     /* same driver previous lap */
    JOIN all_positions prevB
         ON prevB."race_id" = currA."race_id"
        AND prevB."lap"     = currA."lap" - 1       /* rival previous lap */
    JOIN all_positions currB
         ON currB."race_id"   = currA."race_id"
        AND currB."driver_id" = prevB."driver_id"
        AND currB."lap"       = currA."lap"         /* rival current lap */
    WHERE currA."lap" BETWEEN 1 AND 5               /* only first 5 laps */
      AND prevB."driver_id" <> currA."driver_id"
      AND prevB."position"   < prevA."position"     /* B ahead of A last lap */
      AND currB."position"   > currA."position"     /* B now behind A  -> pass */
),
/* ------------------------------------------------------------------ */
/* collect data to classify each overtake                              */
support AS (
    SELECT
        o.*,
        r."lap"                AS ret_lap,
        ps_now."stop"          AS pit_same,
        ps_prev."stop"         AS pit_prev,
        resA."grid"            AS grid_a,
        resB."grid"            AS grid_b
    FROM overtake_pairs o
    /* retirement of the overtaken driver on the same lap */
    LEFT JOIN F1.F1.RETIREMENTS r
           ON r."race_id"  = o."race_id"
          AND r."driver_id"= o."overtaken_id"
          AND r."lap"      = o."lap"
    /* pit-stop of the overtaken driver on the same lap */
    LEFT JOIN F1.F1.PIT_STOPS ps_now
           ON ps_now."race_id"  = o."race_id"
          AND ps_now."driver_id"= o."overtaken_id"
          AND ps_now."lap"      = o."lap"
    /* pit-stop on the previous lap */
    LEFT JOIN F1.F1.PIT_STOPS ps_prev
           ON ps_prev."race_id"  = o."race_id"
          AND ps_prev."driver_id"= o."overtaken_id"
          AND ps_prev."lap"      = o."lap" - 1
    /* grid positions (for start-lap check) */
    LEFT JOIN F1.F1.RESULTS resA
           ON resA."race_id"  = o."race_id"
          AND resA."driver_id"= o."overtaker_id"
    LEFT JOIN F1.F1.RESULTS resB
           ON resB."race_id"  = o."race_id"
          AND resB."driver_id"= o."overtaken_id"
),
/* ------------------------------------------------------------------ */
/* classify: hierarchy R → P → S → T                                   */
classified AS (
    SELECT
        CASE
            WHEN ret_lap IS NOT NULL
                 THEN 'R'                          /* Retirement */
            WHEN pit_same IS NOT NULL
                 OR pit_prev IS NOT NULL
                 THEN 'P'                          /* Pit-related */
            WHEN "lap" = 1
                 AND grid_a IS NOT NULL
                 AND grid_b IS NOT NULL
                 AND ABS(grid_a - grid_b) <= 2
                 THEN 'S'                          /* Start */
            ELSE 'T'                               /* Track */
        END AS category
    FROM support
)
/* ------------------------------------------------------------------ */
SELECT
    category,
    COUNT(*) AS overtake_count
FROM classified
GROUP BY category
ORDER BY category;