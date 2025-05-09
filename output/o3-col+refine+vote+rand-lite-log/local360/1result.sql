WITH first_cv AS (                       -- 1. first '/detail' or '/complete' time per session
    SELECT  "session",
            MIN("stamp") AS first_cv_time
    FROM    "activity_log"
    WHERE   "path" LIKE '%/detail%' 
       OR   "path" LIKE '%/complete%'
    GROUP BY "session"
),
pre_events AS (                          -- 2. events **before** that time whose search_type is not blank
    SELECT  a."session",
            a."path",
            a."search_type",
            a."stamp"
    FROM    "activity_log" a
    JOIN    first_cv f
           ON a."session" = f."session"
    WHERE   a."stamp" < f.first_cv_time
      AND   a."search_type" <> ''
),
cnt AS (                                 -- 3. count such events per session
    SELECT  "session",
            COUNT(*) AS pre_event_cnt
    FROM    pre_events
    GROUP BY "session"
),
min_cnt AS (                             -- 4. global minimum of those counts
    SELECT  MIN(pre_event_cnt) AS min_cnt
    FROM    cnt
)
-- 5. output every qualifying pre-event for the sessions that have that minimum count
SELECT  p."session",
        p."path",
        p."search_type"
FROM    pre_events p
JOIN    cnt        c ON p."session" = c."session"
JOIN    min_cnt    m ON c.pre_event_cnt = m.min_cnt
ORDER BY p."session", p."stamp";