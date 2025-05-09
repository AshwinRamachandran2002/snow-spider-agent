/* -------------------------------------------------------------
   Find, per session, the number of events (search_type <> '')
   that happened BEFORE the first “/detail” or “/complete” page.
   Return every event belonging to the session(s) that exhibit
   the minimum such pre-click / pre-conversion count.
--------------------------------------------------------------*/
WITH first_cv AS (            /* 1. first /detail or /complete per session */
    SELECT
        "session",
        MIN(TO_TIMESTAMP_NTZ("stamp")) AS first_cv_stamp
    FROM LOG.LOG.ACTIVITY_LOG
    WHERE "path" ILIKE '%/detail%' 
       OR "path" ILIKE '%/complete%'
    GROUP BY "session"
), pre_counts AS (            /* 2. count valid search events before that time */
    SELECT
        a."session",
        COUNT(*) AS pre_event_cnt
    FROM LOG.LOG.ACTIVITY_LOG a
    JOIN first_cv f
      ON a."session" = f."session"
    WHERE a."search_type" IS NOT NULL
      AND a."search_type" <> ''
      AND TO_TIMESTAMP_NTZ(a."stamp") < f.first_cv_stamp
    GROUP BY a."session"
), min_cnt AS (               /* 3. global minimum of those counts */
    SELECT MIN(pre_event_cnt) AS min_cnt FROM pre_counts
), target_sessions AS (       /* 4. sessions whose count equals that minimum */
    SELECT p."session"
    FROM pre_counts  p
    JOIN min_cnt     m ON p.pre_event_cnt = m.min_cnt
)
/* 5. return every qualifying pre-click / pre-conversion event */
SELECT
    a."session",
    a."path",
    a."search_type"
FROM LOG.LOG.ACTIVITY_LOG a
JOIN target_sessions ts
  ON a."session" = ts."session"
JOIN first_cv f
  ON a."session" = f."session"
WHERE a."search_type" IS NOT NULL
  AND a."search_type" <> ''
  AND TO_TIMESTAMP_NTZ(a."stamp") < f.first_cv_stamp
ORDER BY
    a."session",
    TO_TIMESTAMP_NTZ(a."stamp");