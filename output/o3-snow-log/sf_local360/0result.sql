/* ------------------------------------------------------------
   1.  first_cv        : first '/detail' or '/complete' time per session
   2.  pre_events      : #events having a non-empty search_type before that time
   3.  min_cnt         : global minimum of those counts
   4.  target_sessions : sessions that share that minimum
   5.  final SELECT    : rows that were actually counted for those sessions
-------------------------------------------------------------*/
WITH first_cv AS (
    SELECT
        "session",
        MIN("stamp") AS "cv_stamp"
    FROM LOG.LOG.ACTIVITY_LOG
    WHERE "path" ILIKE '%/detail%'
       OR "path" ILIKE '%/complete%'
    GROUP BY "session"
),
pre_events AS (
    SELECT
        a."session",
        COUNT(*) AS "pre_event_cnt"
    FROM LOG.LOG.ACTIVITY_LOG a
    JOIN first_cv f
      ON a."session" = f."session"
    WHERE a."search_type" <> ''
      AND a."stamp" < f."cv_stamp"
    GROUP BY a."session"
),
min_cnt AS (
    SELECT MIN("pre_event_cnt") AS "min_cnt"
    FROM pre_events
),
target_sessions AS (
    SELECT "session"
    FROM pre_events
    WHERE "pre_event_cnt" = (SELECT "min_cnt" FROM min_cnt)
)
SELECT
    a."session",
    a."path",
    a."search_type"
FROM LOG.LOG.ACTIVITY_LOG a
JOIN first_cv          f  ON a."session" = f."session"
JOIN target_sessions   t  ON a."session" = t."session"
WHERE a."search_type" <> ''
  AND a."stamp" < f."cv_stamp"
ORDER BY a."session",
         a."stamp";