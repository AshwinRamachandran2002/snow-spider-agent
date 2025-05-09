/* ------------------------------------------------------------
   Count overtakes by label (R = Retirement, P = Pit, S = Start,
   T = normal Track) in all races that have pit-stop data
-------------------------------------------------------------*/
WITH races_with_pit AS (          /* 1. races where pit data exists */
    SELECT "race_id"
    FROM   F1.F1.RACES_EXT
    WHERE  "is_pit_data_available" = 1
),

laps AS (                         /* 2. lap-by-lap positions          */
    SELECT  lp."race_id",
            lp."lap",
            lp."driver_id",
            lp."position"
    FROM    F1.F1.LAP_POSITIONS lp
            JOIN races_with_pit r
                 ON r."race_id" = lp."race_id"
    WHERE   lp."lap_type" = 'Race'
),

overtakes AS (                    /* 3. order swaps from lap-to-lap   */
    SELECT  a."race_id",
            a."lap",
            a."driver_id"   AS "overtaker_id",
            b."driver_id"   AS "overtaken_id"
    FROM    laps a
            JOIN laps b
                  ON  b."race_id" = a."race_id"
                  AND b."lap"     = a."lap"
                  AND a."position" <  b."position"          -- a ahead this lap
            JOIN laps a_prev
                  ON  a_prev."race_id"   = a."race_id"
                  AND a_prev."driver_id" = a."driver_id"
                  AND a_prev."lap"       = a."lap" - 1
            JOIN laps b_prev
                  ON  b_prev."race_id"   = b."race_id"
                  AND b_prev."driver_id" = b."driver_id"
                  AND b_prev."lap"       = b."lap" - 1
    WHERE   a_prev."position" > b_prev."position"           -- a behind last lap
),

/* 4. contextual information --------------------------------*/
grids AS (
    SELECT "race_id", "driver_id", "grid"
    FROM   F1.F1.RESULTS
),
rets  AS (
    SELECT "race_id", "driver_id", "lap"
    FROM   F1.F1.RETIREMENTS
),
pits  AS (
    SELECT "race_id", "driver_id", "lap"
    FROM   F1.F1.PIT_STOPS
),

/* 5. classify each overtake --------------------------------*/
labelled AS (
    SELECT  o."race_id",
            o."lap",
            o."overtaker_id",
            o."overtaken_id",

            /* flags */
            CASE WHEN r."driver_id" IS NOT NULL THEN 1 ELSE 0 END                                            AS is_retire,
            CASE WHEN p_same."driver_id" IS NOT NULL
                      OR p_prev."driver_id" IS NOT NULL THEN 1 ELSE 0 END                                    AS is_pit,
            CASE WHEN o."lap" = 1
                      AND ABS( COALESCE(g1."grid", 999) - COALESCE(g2."grid", 999) ) <= 2 THEN 1 ELSE 0 END  AS is_start
    FROM    overtakes o
            LEFT JOIN rets r
                   ON r."race_id"   = o."race_id"
                  AND r."driver_id" = o."overtaken_id"
                  AND r."lap"       = o."lap"                     /* same-lap retirement           */
            /* pit entry (same lap) */
            LEFT JOIN pits p_same
                   ON p_same."race_id"   = o."race_id"
                  AND p_same."driver_id" = o."overtaken_id"
                  AND p_same."lap"       = o."lap"
            /* pit exit (stopped previous lap) */
            LEFT JOIN pits p_prev
                   ON p_prev."race_id"   = o."race_id"
                  AND p_prev."driver_id" = o."overtaken_id"
                  AND p_prev."lap"       = o."lap" - 1
            /* grid positions for start-lap classification */
            LEFT JOIN grids g1
                   ON g1."race_id"   = o."race_id"
                  AND g1."driver_id" = o."overtaker_id"
            LEFT JOIN grids g2
                   ON g2."race_id"   = o."race_id"
                  AND g2."driver_id" = o."overtaken_id"
),

overtake_types AS (               /* 6. determine single letter code  */
    SELECT CASE
               WHEN is_retire = 1 THEN 'R'
               WHEN is_pit    = 1 THEN 'P'
               WHEN is_start  = 1 THEN 'S'
               ELSE                 'T'
           END AS overtake_type
    FROM   labelled
)

/* 7. final tally -------------------------------------------*/
SELECT   overtake_type,
         COUNT(*) AS overtake_count
FROM     overtake_types
GROUP BY overtake_type
ORDER BY overtake_type;