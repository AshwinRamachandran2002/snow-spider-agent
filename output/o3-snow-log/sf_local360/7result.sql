/* --------------------------------------------------------
   1. first_click        : first “/detail/” or “/complete/” time-stamp per session
   2. pre_event_counts   : number of events (with non-empty search_type) that
                           occurred BEFORE that first click/conversion
   3. minimum_cnt        : smallest such count found
   4. target_sessions    : sessions whose count equals the minimum
   -------------------------------------------------------- */
WITH first_click AS (
    SELECT
        "session",
        MIN("stamp") AS "first_click_stamp"
    FROM   LOG.LOG.ACTIVITY_LOG
    WHERE  "path" IN ('/detail/', '/complete/')
    GROUP  BY "session"
),
pre_event_counts AS (
    SELECT
        a."session",
        COUNT(*) AS "pre_event_cnt"
    FROM   LOG.LOG.ACTIVITY_LOG a
           JOIN first_click f
             ON a."session" = f."session"
    WHERE  a."stamp" < f."first_click_stamp"
      AND  COALESCE(a."search_type",'') <> ''
    GROUP  BY a."session"
),
minimum_cnt AS (
    SELECT MIN("pre_event_cnt") AS "min_cnt"
    FROM   pre_event_counts
),
target_sessions AS (
    SELECT p."session"
    FROM   pre_event_counts p
           JOIN minimum_cnt m
             ON p."pre_event_cnt" = m."min_cnt"
)

SELECT
    a."session",
    a."path",
    a."search_type"
FROM   LOG.LOG.ACTIVITY_LOG a
       JOIN first_click      f  ON a."session" = f."session"
       JOIN target_sessions ts  ON a."session" = ts."session"
WHERE  a."stamp" < f."first_click_stamp"
  AND  COALESCE(a."search_type",'') <> ''
ORDER BY
    a."session",
    a."stamp";