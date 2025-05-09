/* ------------------------------------------------------------
   How many times each kind of over-take ( R – retirement,
   P – pit entry/exit, S – start, T – normal track ) has been
   recorded in all races that actually have pit-stop data
------------------------------------------------------------ */

WITH races_with_pit AS (        -- only analyse races that contain pit data
    SELECT  "race_id"
    FROM    F1.F1.RACES_EXT
    WHERE   "is_pit_data_available" = 1
),

/* ------------------------------------------------------------
   LAP POSITIONS – take the running order on every lap
------------------------------------------------------------ */
lap_positions AS (
    SELECT  lp."race_id",
            lp."lap",
            lp."driver_id",
            lp."position",
            ROW_NUMBER() OVER (PARTITION BY lp."race_id",
                                          lp."lap"
                               ORDER BY   lp."position")          AS "rank"
    FROM    F1.F1.LAP_POSITIONS lp
    JOIN    races_with_pit r
      ON    r."race_id" = lp."race_id"
    WHERE   lp."lap_type" = 'Race'
),

/* ------------------------------------------------------------
   add the rank from the previous lap for every driver
------------------------------------------------------------ */
driver_rank_history AS (
    SELECT  lp."race_id",
            lp."driver_id",
            lp."lap",
            lp."rank"                                                        AS "curr_rank",
            LAG(lp."rank") OVER (PARTITION BY lp."race_id", lp."driver_id"
                                 ORDER BY     lp."lap")                      AS "prev_rank"
    FROM    lap_positions lp
),

/* ------------------------------------------------------------
   RAW_OVERTAKES  –
   An over-take is logged when two drivers were in consecutive
   positions on the previous lap (A just behind B) and have their
   order reversed – i.e. A moves ahead of B – on the current lap.
------------------------------------------------------------ */
raw_overtakes AS (
    SELECT  a."race_id",
            a."lap",
            a."driver_id"   AS "overtaker_id",
            b."driver_id"   AS "overtaken_id"
    FROM    driver_rank_history a
    JOIN    driver_rank_history b
           ON  a."race_id" = b."race_id"
          AND a."lap"      = b."lap"
          AND a."driver_id"<> b."driver_id"
          /*  on the previous lap A was directly behind B         */
          AND a."prev_rank" = b."prev_rank" + 1
          /*  …and now A is directly ahead of B                   */
          AND a."curr_rank" + 1 = b."curr_rank"
),

overtakes AS (                  -- remove any accidental duplicates
    SELECT DISTINCT
           "race_id", "lap", "overtaker_id", "overtaken_id"
    FROM   raw_overtakes
),

/* ------------------------------------------------------------
   Auxiliary data needed for the four labels
------------------------------------------------------------ */
retirements AS (
    SELECT  "race_id", "driver_id", "lap"
    FROM    F1.F1.RETIREMENTS
),
pits AS (                        -- every pit-stop ( entry lap )
    SELECT  "race_id", "driver_id", "lap"
    FROM    F1.F1.PIT_STOPS
),
grid AS (                        -- starting grid for the race
    SELECT  "race_id",
            "driver_id",
            MIN("grid") AS "grid_pos"
    FROM    F1.F1.RESULTS
    GROUP BY "race_id", "driver_id"
)

/* ------------------------------------------------------------
   Label every over-take, then count them
------------------------------------------------------------ */
SELECT
       "overtake_type",
       COUNT(*)            AS "total_overtakes"
FROM (
        SELECT  o."race_id",
                o."lap",
                CASE
                    /* R – overtaken driver retires on the same lap -------- */
                    WHEN  r."driver_id" IS NOT NULL
                    THEN 'R'

                    /* P – pit entry on same lap OR pit exit (previous lap) */
                    WHEN  p_now ."driver_id" IS NOT NULL
                       OR p_prev."driver_id" IS NOT NULL
                    THEN 'P'

                    /* S – first-lap move between cars starting ≤2 places apart */
                    WHEN  o."lap" = 1
                      AND ABS( g_t."grid_pos" - g_k."grid_pos" ) <= 2
                    THEN 'S'

                    /* T – normal track over-take -------------------------- */
                    ELSE 'T'
                END                                      AS "overtake_type"
        FROM    overtakes o
        /*  retirements ---------------------------------------------------- */
        LEFT JOIN retirements r
               ON r."race_id" = o."race_id"
              AND r."driver_id" = o."overtaken_id"
              AND r."lap"      = o."lap"
        /*  pit stops ( same lap / previous lap ) -------------------------- */
        LEFT JOIN pits p_now
               ON p_now."race_id" = o."race_id"
              AND p_now."driver_id" = o."overtaken_id"
              AND p_now."lap"       = o."lap"
        LEFT JOIN pits p_prev
               ON p_prev."race_id" = o."race_id"
              AND p_prev."driver_id" = o."overtaken_id"
              AND p_prev."lap"       = o."lap" - 1
        /*  grid positions ------------------------------------------------- */
        LEFT JOIN grid g_t          -- overtaker
               ON g_t."race_id"  = o."race_id"
              AND g_t."driver_id"= o."overtaker_id"
        LEFT JOIN grid g_k          -- overtaken
               ON g_k."race_id"  = o."race_id"
              AND g_k."driver_id"= o."overtaken_id"
     ) labelled
GROUP BY "overtake_type"
ORDER BY "overtake_type";