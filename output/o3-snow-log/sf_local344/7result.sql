/* -------------------------------------------------------------
   OVERTAKE-TYPE COUNTS  (R / P / S / T)
   ------------------------------------------------------------- */
WITH races_with_pit AS (                     -- 1  races that have pit-stop data
    SELECT "race_id"
    FROM   F1.F1.RACES_EXT
    WHERE  "is_pit_data_available" = 1
),
laps AS (                                    -- 2  every driver position per lap
    SELECT lp."race_id",
           lp."lap",
           lp."driver_id",
           lp."position"
    FROM   F1.F1.LAP_POSITIONS lp
           JOIN races_with_pit r
                 ON r."race_id" = lp."race_id"
    WHERE  lp."lap_type" = 'Race'
),
laps_with_prev AS (                          -- previous-lap position & lap
    SELECT l.*,
           LAG(l."position") OVER (PARTITION BY l."race_id", l."driver_id"
                                   ORDER BY l."lap") AS prev_position,
           LAG(l."lap")      OVER (PARTITION BY l."race_id", l."driver_id"
                                   ORDER BY l."lap") AS prev_lap
    FROM   laps l
),
simple_overtakes AS (                        -- 3  one-place gains
    SELECT  l."race_id",
            l.prev_lap                 AS "lap",         -- lap of overtake
            l."driver_id"              AS overtaker_id,
            p."driver_id"              AS overtaken_id
    FROM    laps_with_prev l
            JOIN laps p                                   -- driver who held place
              ON p."race_id"  = l."race_id"
             AND p."lap"      = l.prev_lap
             AND p."position" = l."position"
    WHERE   l.prev_position = l."position" + 1            -- improved by 1 place
),
/* reference data for labelling */
grids AS (
    SELECT "race_id", "driver_id", "grid"
    FROM   F1.F1.RESULTS
),
pit_stops AS (
    SELECT DISTINCT "race_id", "driver_id", "lap"
    FROM   F1.F1.PIT_STOPS
),
retirements AS (
    SELECT DISTINCT "race_id", "driver_id", "lap"
    FROM   F1.F1.RETIREMENTS
),
classified AS (                               -- 4  apply precedence R > P > S > T
    SELECT  o.*,
            CASE
                WHEN r."driver_id" IS NOT NULL                                  THEN 'R'
                WHEN ps_same."driver_id" IS NOT NULL
                     OR ps_prev."driver_id" IS NOT NULL                         THEN 'P'
                WHEN o."lap" = 1
                     AND ABS(g_otk."grid" - g_otn."grid") <= 2                  THEN 'S'
                ELSE 'T'
            END AS overtake_type
    FROM   simple_overtakes o
           LEFT JOIN retirements r
                  ON r."race_id"   = o."race_id"
                 AND r."driver_id" = o.overtaken_id
                 AND r."lap"       = o."lap"
           LEFT JOIN pit_stops ps_same          -- pit on same lap (entry)
                  ON ps_same."race_id"   = o."race_id"
                 AND ps_same."driver_id" = o.overtaken_id
                 AND ps_same."lap"       = o."lap"
           LEFT JOIN pit_stops ps_prev          -- pit previous lap (exit)
                  ON ps_prev."race_id"   = o."race_id"
                 AND ps_prev."driver_id" = o.overtaken_id
                 AND ps_prev."lap"       = o."lap" - 1
           LEFT JOIN grids g_otk                -- grid positions (overtaker)
                  ON g_otk."race_id"   = o."race_id"
                 AND g_otk."driver_id" = o.overtaker_id
           LEFT JOIN grids g_otn                -- grid positions (overtaken)
                  ON g_otn."race_id"   = o."race_id"
                 AND g_otn."driver_id" = o.overtaken_id
)
/* 5. final counts */
SELECT   overtake_type,
         COUNT(*) AS overtake_count
FROM     classified
GROUP BY overtake_type
ORDER BY overtake_type;