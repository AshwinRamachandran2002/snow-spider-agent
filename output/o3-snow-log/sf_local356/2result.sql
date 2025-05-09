WITH "LAP_CHANGES" AS (          -- position change for every driver between consecutive laps
    SELECT
        lp."race_id",
        lp."driver_id",
        lp."lap",
        LAG(lp."position") OVER (PARTITION BY lp."race_id",
                                              lp."driver_id"
                                 ORDER BY     lp."lap")       AS "prev_position",
        lp."position"                                          AS "curr_position"
    FROM F1.F1."LAP_POSITIONS" lp
    WHERE lp."lap_type" = 'Race'
),
"VALID_CHANGES" AS (             -- keep only on-track position changes
    SELECT
        lc."driver_id",
        (lc."prev_position" - lc."curr_position") AS "delta"   -- +ve  = overtakes
    FROM "LAP_CHANGES" lc
    WHERE lc."prev_position" IS NOT NULL           -- skip first-lap record for each driver
      AND lc."lap" > 1                             -- ignore start movements
      -- exclude laps where THIS driver pitted (entry or exit)
      AND NOT EXISTS (
            SELECT 1
            FROM F1.F1."PIT_STOPS" ps
            WHERE ps."race_id"  = lc."race_id"
              AND ps."driver_id" = lc."driver_id"
              AND ps."lap"      IN (lc."lap", lc."lap" - 1)
      )
      -- exclude laps in which ANY retirement occurred
      AND NOT EXISTS (
            SELECT 1
            FROM F1.F1."RETIREMENTS" r
            WHERE r."race_id" = lc."race_id"
              AND r."lap"     = lc."lap"
      )
),
"DRIVER_NET" AS (                -- aggregate overtakes vs. being overtaken
    SELECT
        vc."driver_id",
        SUM(CASE WHEN vc."delta" > 0 THEN  vc."delta" ELSE 0 END)          AS "overtakes",
        SUM(CASE WHEN vc."delta" < 0 THEN ABS(vc."delta") ELSE 0 END)      AS "overtaken"
    FROM "VALID_CHANGES" vc
    GROUP BY vc."driver_id"
)
SELECT
    de."full_name"
FROM "DRIVER_NET" dn
JOIN F1.F1."DRIVERS_EXT" de
  ON de."driver_id" = dn."driver_id"
WHERE dn."overtaken" > dn."overtakes"          -- more passed than passes made
ORDER BY de."full_name" ASC NULLS LAST;