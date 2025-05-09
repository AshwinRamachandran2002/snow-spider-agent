WITH first_cv AS (                       -- 1) first /detail or /complete timestamp per session
    SELECT  "session",
            MIN("stamp") AS "first_cv_stamp"
    FROM    "activity_log"
    WHERE   "path" LIKE '%/detail%'       -- click to a detail page
       OR   "path" LIKE '%/complete%'     -- or a conversion page
    GROUP BY "session"
),
pre_events AS (                           -- 2) events with non-empty search_type BEFORE that click
    SELECT  a."session",
            a."stamp",
            a."path",
            a."search_type"
    FROM    "activity_log" AS a
    JOIN    first_cv      AS f
           ON a."session" = f."session"
    WHERE   a."search_type" <> ''         -- only count rows whose search_type is not empty
      AND   a."stamp" <  f."first_cv_stamp"
),
pre_counts AS (                           -- 3) how many such events per session
    SELECT  "session",
            COUNT(*) AS cnt
    FROM    pre_events
    GROUP BY "session"
),
min_cnt AS (                              -- 4) the minimum of those counts
    SELECT MIN(cnt) AS min_cnt
    FROM   pre_counts
)
-- 5) return every qualifying session together with the corresponding
--    path and search_type for each counted pre-event
SELECT  p."session",
        p."path",
        p."search_type"
FROM    pre_events  AS p
JOIN    pre_counts  AS pc ON p."session" = pc."session"
JOIN    min_cnt     AS m  ON pc.cnt      = m.min_cnt
ORDER BY p."session",
         p."stamp";