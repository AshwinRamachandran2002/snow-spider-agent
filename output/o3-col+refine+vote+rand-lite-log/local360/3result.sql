WITH first_conv AS (
    /* ① first /detail or /complete time-stamp per session */
    SELECT
        "session",
        MIN("stamp") AS first_stamp
    FROM   "activity_log"
    WHERE  "path" LIKE '%/detail%' OR "path" LIKE '%/complete%'
    GROUP  BY "session"
),
pre_cnt AS (
    /* ② how many non-empty-search_type events happened *before* that time */
    SELECT  a."session",
            COUNT(*) AS pre_events
    FROM    "activity_log" a
    JOIN    first_conv      f
           ON a."session" = f."session"
          AND a."stamp"   < f.first_stamp
    WHERE   COALESCE(a."search_type",'') <> ''
    GROUP   BY a."session"
),
min_val AS (
    /* ③ the minimum of those counts */
    SELECT MIN(pre_events) AS min_pre_events
    FROM   pre_cnt
),
first_row AS (
    /* ④ row that holds the first /detail or /complete for every session */
    SELECT  b."session",
            b."path",
            b."search_type"
    FROM    "activity_log" b
    JOIN    first_conv     f
           ON b."session" = f."session"
          AND b."stamp"   = f.first_stamp
)
SELECT DISTINCT
       p."session",
       r."path",
       r."search_type"
FROM   pre_cnt  p
JOIN   min_val  m  ON p.pre_events = m.min_pre_events
JOIN   first_row r ON p."session"  = r."session";