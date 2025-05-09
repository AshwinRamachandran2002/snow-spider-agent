WITH
/* 1. every lap where at least one car entered the pits                */
"pit_laps"        AS (
    SELECT DISTINCT
           "race_id",
           "lap"
    FROM   F1.F1."PIT_STOPS"
),
/* 2. every lap where at least one car retired                          */
"retire_laps"     AS (
    SELECT DISTINCT
           "race_id",
           "lap"
    FROM   F1.F1."RETIREMENTS"
),
/* 3. position change for each driver between consecutive race laps     */
"lap_changes"     AS (
    SELECT
        lp."race_id",
        lp."driver_id",
        lp."lap",
        lp."position",
        LAG(lp."position")
          OVER (PARTITION BY lp."race_id", lp."driver_id"
                ORDER BY      lp."lap")                 AS "prev_position"
    FROM   F1.F1."LAP_POSITIONS" lp
    WHERE  lp."lap_type" = 'Race'                       -- only race laps
),
/* 4. keep only pure on-track changes (no lap-1, no pit, no retirement) */
"filtered_changes" AS (
    SELECT
        lc."driver_id",
        CASE WHEN lc."position" < lc."prev_position" THEN 1 ELSE 0 END AS "overtakes",
        CASE WHEN lc."position" > lc."prev_position" THEN 1 ELSE 0 END AS "overtaken_by"
    FROM   "lap_changes" lc
           LEFT JOIN "pit_laps"    p ON p."race_id" = lc."race_id"
                                    AND p."lap"      = lc."lap"
           LEFT JOIN "retire_laps" r ON r."race_id" = lc."race_id"
                                    AND r."lap"      = lc."lap"
    WHERE  lc."prev_position" IS NOT NULL             -- need a previous lap
      AND  lc."lap"            > 1                    -- exclude start moves
      AND  p."lap"            IS NULL                -- exclude pit-stop laps
      AND  r."lap"            IS NULL                -- exclude retirement laps
),
/* 5. aggregate per driver                                              */
"driver_totals" AS (
    SELECT
        "driver_id",
        SUM("overtakes")     AS "overtakes",
        SUM("overtaken_by")  AS "overtaken_by"
    FROM   "filtered_changes"
    GROUP  BY "driver_id"
)
/* 6. drivers overtaken more than they overtook                         */
SELECT
    de."full_name"
FROM   "driver_totals" dt
       JOIN F1.F1."DRIVERS_EXT" de
         ON de."driver_id" = dt."driver_id"
WHERE  dt."overtaken_by" > dt."overtakes"
ORDER  BY de."full_name";